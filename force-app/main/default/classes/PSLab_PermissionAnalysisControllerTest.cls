/**
 * @author       : Oumaima ARBANI
 * @date         : 22/8/2025
 * @description  : Test class for PSLab_PermissionAnalysisController.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_PermissionAnalysisControllerTest {

    @TestSetup
    static void makeData(){
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'controller.test.user@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert psLabUser;

        PermissionSet psLabPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'PSLabUser'];
        insert new PermissionSetAssignment(
                AssigneeId = psLabUser.Id,
                PermissionSetId = psLabPermissionSet.Id
        );

        PermissionSet ps = new PermissionSet(
                Name = 'Test_Controller_PS',
                Label = 'Test Controller PS'
        );
        insert ps;

        insert new PermissionSetAssignment(
                AssigneeId = psLabUser.Id,
                PermissionSetId = ps.Id
        );

        insert new ObjectPermissions(
                ParentId = ps.Id,
                SobjectType = 'Contact',
                PermissionsRead = true
        );

        insert new ObjectPermissions(
                ParentId = ps.Id,
                SobjectType = 'Account',
                PermissionsRead = true
        );
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author Oumaima Arbani | 2025-08-22
     * @return User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id, Name, Username FROM User WHERE Username = 'controller.test.user@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Retrieves the test permission set created during the test setup.
     * @author Oumaima Arbani | 2025-08-22
     * @return PermissionSet record for testing purposes.
     **/
    private static PermissionSet getTestPermissionSet() {
        return [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Controller_PS' LIMIT 1];
    }


    /**
     * @description  : Verifies that the getPermissionsOrUsersList method successfully returns a list of users.
     * @author Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionsOrUsersList() {
        User psLabUser= getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser){
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisController.getPermissionsOrUsersList('User');
            }
            Test.stopTest();
        }
        Assert.isNotNull(results, 'The result list should not be null.');
    }

    /**
     * @description  : Verifies that the getPermissionSetHierarchy method returns a valid, non-null hierarchy structure.
     * @author Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSetHierarchy() {
        User psLabUser= getTestUser();
        PSLab_HierarchyNode result = new PSLab_HierarchyNode();
        System.runAs(psLabUser){
            Test.startTest();
            {
                result = PSLab_PermissionAnalysisController.getPermissionSetHierarchy();
            }
            Test.stopTest();
        }
        Assert.isNotNull(result, 'The result list should not be null.');
    }

    /**
     * @description  : Verifies that the getOptionsBySelectedPermission method returns a list of metadata options for a given permission type.
     * @author Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetOptionsBySelectedPermission() {
        User psLabUser= getTestUser();
        List<Object> results = new List<Object>();
        System.runAs(psLabUser){
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisController.getOptionsBySelectedPermission('ObjectPermissions', 'Account');
            }
            Test.stopTest();
        }

        Assert.isNotNull(results, 'The result list should not be null.');
    }

    /**
     * @description  : Verifies that the getPermissionSetHierarchyByUserId method returns a correct permission hierarchy for a specific user.
     * @author Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSetHierarchyByUserId() {
        User psLabUser = getTestUser();
        PSLab_HierarchyNode result = new PSLab_HierarchyNode();
        System.runAs(psLabUser){
            Test.startTest();
            {
                result = PSLab_PermissionAnalysisController.getPermissionSetHierarchyByUserId(psLabUser.Id);
            }
            Test.stopTest();
        }

        Assert.isNotNull(result, 'The hierarchy node for the user should not be null.');
        Assert.areEqual(psLabUser.Name + '\n(' + psLabUser.Username + ')', result.name, 'The root node should be the user name.');
    }

    /**
     * @description  : Verifies that the getDetectedPermissions method correctly identifies and returns permissions based on a specified payload.
     * @author Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetDetectedPermissions() {
        User psLabUser = getTestUser();
        PermissionSet permissionSet = getTestPermissionSet();
        Map<String, Object> payload = new Map<String, Object>{
                'permission' => 'ObjectPermissions',
                'permissionType' => 'PS',
                'permissionsAPINames' => permissionSet.Name,
                'metadataNames' => 'Account',
                'securityPermissions' => 'PermissionsRead',
                'condition' => 'OR'
        };

        List<PSLab_DetectedPermission> results = new List<PSLab_DetectedPermission>();
        System.runAs(psLabUser){
            Test.startTest();
            {
                results = PSLab_PermissionAnalysisController.getDetectedPermissions(payload);
            }
            Test.stopTest();
        }
        Assert.areEqual(1, results.size(), 'Should have found exactly one detected permission.');
        Assert.areEqual(permissionSet.Id, results[0].permissionSetId, 'The detected permission should belong to the correct Permission Set.');
    }
}