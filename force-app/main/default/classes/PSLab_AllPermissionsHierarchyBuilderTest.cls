/**
 * @author       : Oumaima ARBANI
 * @date         : 22/8/2025
 * @description  : Test class for PSLab_AllPermissionsHierarchyBuilder.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_AllPermissionsHierarchyBuilderTest {

    @TestSetup
    static void makeData() {
        // Create a test user to establish a running context
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'allperms.test.user@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert psLabUser;

        // Create one permission set that will be part of a group
        PermissionSet groupedPS = new PermissionSet(
                Name = 'Test_Grouped_Permission_Set',
                Label = 'Test Grouped Permission Set'
        );

        // Create one permission set that will stand alone
        PermissionSet standalonePS = new PermissionSet(
                Name = 'Test_Standalone_Permission_Set',
                Label = 'Test Standalone Permission Set'
        );

        // Create a permission set group
        PermissionSetGroup testPSG = new PermissionSetGroup(
                DeveloperName = 'Test_All_Perms_PSG',
                MasterLabel = 'Test All Perms PSG'
        );

        // Bulk insert parent records
        insert new List<SObject>{groupedPS, standalonePS, testPSG};

        // Recalculate the PSG status after creation
        Test.calculatePermissionSetGroup(testPSG.Id);

        // Link the "grouped" permission set to the group
        insert new PermissionSetGroupComponent(
                PermissionSetGroupId = testPSG.Id,
                PermissionSetId = groupedPS.Id
        );
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Username = 'allperms.test.user@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Verifies that the build method correctly constructs a full hierarchy
     * with both a Permission Set Group branch and a Standalone Permission Set branch.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testBuildHierarchyWithGroupsAndStandalone() {
        User psLabUser = getTestUser();
        PSLab_HierarchyNode rootNode;

        System.runAs(psLabUser) {
            Test.startTest();
            {
                PSLab_AllPermissionsHierarchyBuilder builder = new PSLab_AllPermissionsHierarchyBuilder();
                rootNode = builder.build();
            }
            Test.stopTest();
        }

        // --- Assertions ---
        Assert.isNotNull(rootNode, 'The root node should not be null.');
        Assert.areEqual(UserInfo.getOrganizationName(), rootNode.name, 'Root node name should be the Org Name.');
        Assert.areEqual(2, rootNode.children.size(), 'Root node should have two children: Groups and Standalone branches.');

        // Find the specific branches to make the test independent of order
        PSLab_HierarchyNode groupsBranch;
        PSLab_HierarchyNode standaloneBranch;
        for(PSLab_HierarchyNode branch : rootNode.children) {
            if (branch.name == 'Permission Set Groups') {
                groupsBranch = branch;
            } else if (branch.name == 'Standalone Permission Sets') {
                standaloneBranch = branch;
            }
        }

        // Verify the groups branch is correctly structured
        Assert.isNotNull(groupsBranch, 'The Permission Set Groups branch should exist.');
        Assert.isTrue(groupsBranch.children.size() >= 1, 'The Groups branch should contain our test PSG.');

        PSLab_HierarchyNode psgNode;
        for (PSLab_HierarchyNode node : groupsBranch.children) {
            if (node.name == 'Test_All_Perms_PSG') {
                psgNode = node;
                break;
            }
        }
        Assert.isNotNull(psgNode, 'The test PSG node was not found.');
        Assert.areEqual(1, psgNode.children.size(), 'The PSG node should have one child permission set.');
        Assert.areEqual('Test_Grouped_Permission_Set', psgNode.children[0].name, 'The child of the PSG should be the grouped permission set.');

        // Verify the standalone branch is correctly structured
        Assert.isNotNull(standaloneBranch, 'The Standalone Permission Sets branch should exist.');
        Assert.isTrue(standaloneBranch.children.size() >= 1, 'The Standalone branch should contain our test PS.');

        Boolean isStandalonePSFound = false;
        for (PSLab_HierarchyNode node : standaloneBranch.children) {
            if (node.name == 'Test_Standalone_Permission_Set') {
                isStandalonePSFound = true;
                break;
            }
        }
        Assert.isTrue(isStandalonePSFound, 'The standalone permission set was not found in its branch.');
    }
}