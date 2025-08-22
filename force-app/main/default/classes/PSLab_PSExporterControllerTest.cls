/**
 * @author       : Oumaima ARBANI
 * @date         : 22/08/2025
 * @description  : Test class for PSLab_PermissionSetExporterController.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_PSExporterControllerTest {

    @TestSetup
    static void makeData() {
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'exporter.test.user@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive = true
        );
        insert psLabUser;


        PermissionSet testPermissionSet = new PermissionSet(
                Name = 'Exporter_Test_Permission_Set',
                Label = 'Exporter Test Permission Set'
        );
        insert testPermissionSet;

        insert new ObjectPermissions(
                ParentId = testPermissionSet.Id,
                SobjectType = 'Contact',
                PermissionsRead = true,
                PermissionsCreate = true,
                PermissionsEdit = false,
                PermissionsDelete = false
        );

        insert new ObjectPermissions(
                ParentId = testPermissionSet.Id,
                SobjectType = 'Account',
                PermissionsRead = true,
                PermissionsCreate = true,
                PermissionsEdit = false,
                PermissionsDelete = false
        );
    }

    /**
     * @description  : Retrieves the test permission set created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : PermissionSet record for testing purposes.
     **/
    private static PermissionSet getTestPermissionSet() {
        return [SELECT Id, Name FROM PermissionSet WHERE Name = 'Exporter_Test_Permission_Set' LIMIT 1];
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id, Name, Username FROM User WHERE Username = 'exporter.test.user@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Verifies that the getPermissionSets method successfully returns a list of permission sets.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSets() {
        User psLabUser = getTestUser();
        List<PSLab_PermissionSetExporterHelper.PermissionSetInfo> results;
        System.runAs(psLabUser) {
            Test.startTest();
            {
                results = PSLab_PermissionSetExporterController.getPermissionSets();
            }
            Test.stopTest();
        }

        Assert.isFalse(results.isEmpty(), 'The result list should not be empty.');

        Boolean isTestPSFound = false;
        for (PSLab_PermissionSetExporterHelper.PermissionSetInfo info : results) {
            System.debug(info.label);
            if (info.label == 'Exporter Test Permission Set (Exporter_Test_Permission_Set)') {
                isTestPSFound = true;
                break;
            }
        }
        Assert.isTrue(isTestPSFound, 'The test permission set should be in the returned list.');

    }

    /**
     * @description  : Verifies that the exportPermissionSetAsCSV method returns a correctly formatted CSV string.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testExportPermissionSetAsCSV() {
        User psLabUser = getTestUser();
        String csvResult;
        System.runAs(psLabUser) {
            PermissionSet testPS = getTestPermissionSet();
            List<String> permissionsToExport = new List<String>{'ObjectPermissions'};

            Test.startTest();
            {
                csvResult = PSLab_PermissionSetExporterController.exportPermissionSetAsCSV(testPS.Id, permissionsToExport);
            }
            Test.stopTest();
        }

        Assert.isTrue(String.isNotBlank(csvResult), 'The CSV string should not be null or empty.');

        String expectedHeader = 'PermissionType,Metadata,Details';
        String expectedRow = 'Object,Account,Create|Read';

        Assert.isTrue(csvResult.contains(expectedHeader), 'The CSV should contain the correct header.');
        Assert.isTrue(csvResult.contains(expectedRow), 'The CSV should contain the correct data row for Account permissions.');
    }
}