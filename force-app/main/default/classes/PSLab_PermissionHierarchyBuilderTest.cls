/**
 * @author       : Oumaima ARBANI
 * @date         : 22/8/2025
 * @description  : Test class for PSLab_PermissionHierarchyBuilder.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_PermissionHierarchyBuilderTest {

    @TestSetup
    static void makeData() {
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'user.perms.test@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert psLabUser;

        PermissionSet groupedPS = new PermissionSet(
                Name = 'User_Grouped_PS',
                Label = 'User Grouped PS'
        );

        insert groupedPS;

        Map<String, PermissionSet> permissionSetNameToPermissionSet = new Map<String, PermissionSet>();
        for (PermissionSet ps : [
                SELECT Id, Name, PermissionSetGroupId
                FROM PermissionSet
                WHERE Name IN ('PSLab_PermissionSetGroup', 'PSLabUser')
        ]) {
            permissionSetNameToPermissionSet.put(ps.Name, ps);
        }
        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        List<PermissionSetGroupComponent> componentsToInsert = new List<PermissionSetGroupComponent>();
        if (permissionSetNameToPermissionSet.containsKey('PSLabUser') && permissionSetNameToPermissionSet.containsKey('PSLab_PermissionSetGroup')) {
            assignmentsToInsert.add(
                    new PermissionSetAssignment(
                            AssigneeId = psLabUser.Id,
                            PermissionSetId = permissionSetNameToPermissionSet.get('PSLabUser').Id
                    )
            );

            assignmentsToInsert.add(
                    new PermissionSetAssignment(
                            AssigneeId = psLabUser.Id,
                            PermissionSetGroupId = permissionSetNameToPermissionSet.get('PSLab_PermissionSetGroup').PermissionSetGroupId
                    )
            );
        }


        insert assignmentsToInsert;

        insert new PermissionSetGroupComponent(
                PermissionSetGroupId = permissionSetNameToPermissionSet.get('PSLab_PermissionSetGroup').PermissionSetGroupId,
                PermissionSetId = groupedPS.Id
        );
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id, Name, Username FROM User WHERE Username = 'user.perms.test@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Verifies the hierarchy construction for a user with both standalone and group assignments.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testBuildHierarchyWithMixedAssignments() {
        User testAssignee = getTestUser();
        PSLab_HierarchyNode rootNode;

        // Query for the assignments created in the setup
        List<PermissionSetAssignment> userAssignments = [
                SELECT PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.Description,
                        PermissionSet.CreatedBy.Name, PermissionSet.LastModifiedBy.Name, PermissionSet.LastModifiedDate,
                        PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel,
                        PermissionSetGroup.Description, PermissionSetGroup.CreatedBy.Name, PermissionSetGroup.Status,
                        PermissionSetGroup.LastModifiedBy.Name, PermissionSetGroup.LastModifiedDate,
                        Assignee.Name, Assignee.Username
                FROM PermissionSetAssignment
                WHERE AssigneeId = :testAssignee.Id
        ];

        System.runAs(testAssignee) {
            Test.startTest();
            {
                PSLab_PermissionHierarchyBuilder builder = new PSLab_PermissionHierarchyBuilder(userAssignments);
                rootNode = builder.build();
            }
            Test.stopTest();
        }

        // --- Assertions ---
        Assert.isNotNull(rootNode, 'The root node should not be null.');
        Assert.areEqual(testAssignee.Name + '\n(' + testAssignee.Username + ')', rootNode.name, 'Root node name should be the assignee name and username.');
        Assert.areEqual(2, rootNode.children.size(), 'Root node should have two children: Groups and Standalone branches.');

        // Find the specific branches
        PSLab_HierarchyNode groupsBranch;
        PSLab_HierarchyNode standaloneBranch;
        for(PSLab_HierarchyNode branch : rootNode.children) {
            if (branch.name == 'Permission Set Groups') {
                groupsBranch = branch;
            } else if (branch.name == 'Standalone Permission Sets') {
                standaloneBranch = branch;
            }
        }

        // Verify the groups branch
        Assert.isNotNull(groupsBranch, 'The Permission Set Groups branch should exist.');
        Assert.areEqual(1, groupsBranch.children.size(), 'Groups branch should contain one PSG.');
        PSLab_HierarchyNode psgNode = groupsBranch.children[0];
        Assert.areEqual('PSLab_PermissionSetGroup', psgNode.name, 'The correct PSG should be listed.');
        Assert.areEqual(1, psgNode.children.size(), 'The PSG node should have one child permission set.');
        Assert.areEqual('User_Grouped_PS', psgNode.children[0].name, 'The child of the PSG should be the grouped PS.');

        // Verify the standalone branch
        Assert.isNotNull(standaloneBranch, 'The Standalone Permission Sets branch should exist.');
        Assert.areEqual(2, standaloneBranch.children.size(), 'Standalone branch should contain one PS.');
    }

    /**
     * @description  : Verifies that the builder handles an empty list of assignments gracefully.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testBuildWithNoAssignments() {
        User testAssignee = getTestUser();
        PSLab_HierarchyNode rootNode;

        System.runAs(testAssignee) {
            Test.startTest();
            {
                // Pass an empty list to the constructor
                PSLab_PermissionHierarchyBuilder builder = new PSLab_PermissionHierarchyBuilder(new List<PermissionSetAssignment>());
                rootNode = builder.build();
            }
            Test.stopTest();
        }

        Assert.isNotNull(rootNode, 'The root node should not be null even with no assignments.');
        Assert.isNull(rootNode.name, 'Root node should have no name if there is no assignee.');
        Assert.isTrue(rootNode.children.isEmpty(), 'Root node should have no children.');
    }
}