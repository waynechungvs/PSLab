/**
 * @author       : Oumaima ARBANI
 * @date         : 22/08/2025
 * @description  : Test class for PSLab_PermissionSetExporterHelper.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_PermissionSetExporterHelperTest{

    @TestSetup
    static void makeData(){
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'exporter.helper.user@testpslab.com',
                CompanyName = 'Test Inc.',
                Title = 'Tester',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert psLabUser;

        PermissionSet testPS = new PermissionSet(
                Name = 'Exporter_Helper_Test_PS',
                Label = 'Exporter Helper Test PS'
        );
        PermissionSet emptyPS = new PermissionSet(
                Name = 'Exporter_Helper_Empty_PS',
                Label = 'Exporter Helper Empty PS'
        );
        insert new List<PermissionSet>{
                testPS, emptyPS
        };

        PermissionSetGroup testPSG = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PSLab_PermissionSetGroup' LIMIT 1];
        Test.calculatePermissionSetGroup(testPSG.Id);
        insert new PermissionSetGroupComponent(
                PermissionSetGroupId = testPSG.Id,
                PermissionSetId = testPS.Id
        );

        ApexClass apexClassTest = [SELECT Id FROM ApexClass WHERE Name = 'PSLab_PermissionSetExporterController' LIMIT 1];

        insert new ObjectPermissions(ParentId = testPS.Id, SobjectType = 'Contact', PermissionsRead = true, PermissionsCreate = true);
        insert new ObjectPermissions(ParentId = testPS.Id, SobjectType = 'Account', PermissionsRead = true, PermissionsCreate = true);
        insert new FieldPermissions(ParentId = testPS.Id, SobjectType = 'Account', Field = 'Account.Type', PermissionsRead = true, PermissionsEdit = true);
        insert new SetupEntityAccess(ParentId = testPS.Id, SetupEntityId = apexClassTest.Id);
    }

    private static User getTestUser(){
        return [SELECT Id FROM User WHERE Username = 'exporter.helper.user@testpslab.com' LIMIT 1];
    }

    private static PermissionSet getTestPermissionSet(){
        return [SELECT Id FROM PermissionSet WHERE Name = 'Exporter_Helper_Test_PS' LIMIT 1];
    }

    private static PermissionSet getEmptyPermissionSet(){
        return [SELECT Id FROM PermissionSet WHERE Name = 'Exporter_Helper_Empty_PS' LIMIT 1];
    }

    /**
     * @description  : Verifies that getPermissionSets correctly retrieves and formats PermissionSetInfo wrappers.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGetPermissionSets(){
        User psLabUser = getTestUser();
        PermissionSet testPermissionSet = getTestPermissionSet();
        List<PSLab_PermissionSetExporterHelper.PermissionSetInfo> results;
        System.runAs(psLabUser){
            Test.startTest();
            {
                results = PSLab_PermissionSetExporterHelper.getPermissionSets();
            }
            Test.stopTest();
        }

        Assert.isFalse(results.isEmpty(), 'The result list should not be empty.');

        PSLab_PermissionSetExporterHelper.PermissionSetInfo testInfo;
        for(PSLab_PermissionSetExporterHelper.PermissionSetInfo info : results) {
            if(info.Id == testPermissionSet.Id){
                testInfo = info;
                break;
            }
        }

        Assert.isNotNull(testInfo, 'The test permission set should be found in the results.');
        Assert.areEqual('Exporter Helper Test PS (Exporter_Helper_Test_PS)', testInfo.label);
        Assert.areEqual('PSLab_PermissionSetGroup', testInfo.includedIn, 'Should correctly show the PSG it is included in.');
    }

    /**
     * @description  : Verifies that generateCSVHelper correctly calls all providers and assembles a comprehensive CSV.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGenerateCSVHelper_AllPermissions(){
        User psLabUser = getTestUser();
        String csvResult;

        List<String> allPermissions = new List<String>{
                'ObjectPermissions',
                'FieldPermissions',
                'TabSet',
                'FlowDefinition',
                'CustomMetadataType',
                'CustomSetting',
                'ApexClass',
                'ApexPage',
                'CustomPermission',
                'PermissionSetTabSetting'
        };


        System.runAs(psLabUser){
            Test.startTest();
            {
                PermissionSet testPS = [SELECT Id, Name FROM PermissionSet WHERE Name = 'PSLabUser' LIMIT 1];
                csvResult = PSLab_PermissionSetExporterHelper.generateCSVHelper(testPS.Id, allPermissions);
            }
            Test.stopTest();
        }

        Assert.isTrue(String.isNotBlank(csvResult), 'The CSV string should not be blank.');

        // Verify that the output from each provider is present in the final CSV
        Assert.isTrue(csvResult.contains('Apex Class,PSLab_PermissionSetExporterController,'), 'CSV should contain Apex Class data.');
        Assert.isTrue(csvResult.contains('Visualforce Page,PSLab_ApexPage,'), 'CSV should contain Apex Page data.');
        Assert.isTrue(csvResult.contains('Custom Permission,PSLab_CustomPermission,'), 'CSV should contain Custom Permission data.');
        Assert.isTrue(csvResult.contains('Assigned Application,PSLab,'), 'CSV should contain App/TabSet data.');
    }

    /**
     * @description  : Verifies that generateCSVHelper works correctly for an empty permission set.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testGenerateCSVHelper_EmptyPermissionSet(){
        User psLabUser = getTestUser();
        String csvResult;

        List<String> allPermissions = new List<String>{
                'ObjectPermissions', 'FieldPermissions'
        };

        System.runAs(psLabUser){
            PermissionSet emptyPS = getEmptyPermissionSet();
            Test.startTest();
            {
                csvResult = PSLab_PermissionSetExporterHelper.generateCSVHelper(emptyPS.Id, allPermissions);
            }
            Test.stopTest();
        }

        // The result should only contain the header row
        String expectedHeader = 'PermissionType,Metadata,Details';
        Assert.areEqual(expectedHeader, csvResult, 'CSV for an empty PS should only contain the header.');
    }
}