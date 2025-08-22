/**
 * @author       : Oumaima ARBANI
 * @date         : 22/08/2025
 * @description  : Test class for the PSLab_SetupEntityAccessTransformer utility.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_SetupEntityAccessTransformerTest {

    @TestSetup
    static void makeData() {
        // Create a test user to establish a running context for the tests
        User psLabUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                LastName = 'testlastname',
                Email = 'test@test.com',
                Username = 'transformer.test.user@testpslab.com',
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

    }

    /**
     * @description  : Retrieves the test permission set created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : PermissionSet record for testing purposes.
     **/
    private static PermissionSet getTestPermissionSet() {
        return [SELECT Id, Name FROM PermissionSet WHERE Name = 'PSLabUser' LIMIT 1];
    }

    /**
     * @description  : Retrieves the test user created during the test setup.
     * @author       : Oumaima Arbani | 2025-08-22
     * @return       : User record for testing purposes.
     **/
    private static User getTestUser() {
        return [SELECT Id, Name, Username FROM User WHERE Username = 'transformer.test.user@testpslab.com' LIMIT 1];
    }

    /**
     * @description  : Verifies the transformation of an ApexClass record that has a Permission Set assignment.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testTransformWithApexClass() {
        User psLabUser = getTestUser();
        System.runAs(psLabUser) {
            PermissionSet testPS = getTestPermissionSet();

            // The subquery for SetupEntityAccessItems is required to simulate the data structure
            // that the transform method expects to receive.
            List<ApexClass> classesToTransform = [
                    SELECT Name, (SELECT ParentId FROM SetupEntityAccessItems)
                    FROM ApexClass
                    WHERE Name = 'PSLab_PermissionAnalysisController'
            ];

            List<PSLab_SetupEntityAccessTransformer.PermissionLink> results;
            Test.startTest();
            {
                results = PSLab_SetupEntityAccessTransformer.transform(classesToTransform, 'Name');
            }
            Test.stopTest();

            Assert.isTrue(results.size() > 0, 'Should create one PermissionLink for the assignment.');
            Assert.areEqual(testPS.Id, results[0].parentId, 'The ParentId should be the Permission Set Id.');
            Assert.areEqual('PSLab_PermissionAnalysisController', results[0].referenceFieldValue, 'The reference value should be the class name.');
        }
    }

    /**
     * @description  : Verifies the transformation of a CustomPermission record that has a Permission Set assignment.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testTransformWithCustomPermission() {
        User psLabUser = getTestUser();
        System.runAs(psLabUser) {
            PermissionSet testPS = getTestPermissionSet();

            List<CustomPermission> permsToTransform = [
                    SELECT DeveloperName, (SELECT ParentId FROM SetupEntityAccessItems)
                    FROM CustomPermission
                    WHERE DeveloperName = 'PSLab_CustomPermission'
            ];

            List<PSLab_SetupEntityAccessTransformer.PermissionLink> results;
            Test.startTest();
            {
                results = PSLab_SetupEntityAccessTransformer.transform(permsToTransform, 'DeveloperName');
            }
            Test.stopTest();

            Assert.areEqual(1, results.size(), 'Should create one PermissionLink for the assignment.');
            Assert.areEqual(testPS.Id, results[0].parentId, 'The ParentId should be the Permission Set Id.');
            Assert.areEqual('PSLab_CustomPermission', results[0].referenceFieldValue, 'The reference value should be the custom permission name.');
        }
    }

    /**
     * @description  : Verifies that the transform method returns an empty list for an SObject with no assignments.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testTransformWithNoAssignments() {
        User psLabUser = getTestUser();
        System.runAs(psLabUser) {


            List<ApexClass> classesToTransform = [
                    SELECT Name, (SELECT ParentId FROM SetupEntityAccessItems)
                    FROM ApexClass
                    WHERE Name = 'Test_ApexClass_PSLab'
            ];

            List<PSLab_SetupEntityAccessTransformer.PermissionLink> results;
            Test.startTest();
            {
                results = PSLab_SetupEntityAccessTransformer.transform(classesToTransform, 'Name');
            }
            Test.stopTest();

            Assert.isTrue(results.isEmpty(), 'The result list should be empty for a component with no assignments.');
        }
    }

    /**
     * @description  : Verifies that the PermissionLink inner class constructor works correctly.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testPermissionLinkConstructor() {
        User psLabUser = getTestUser();
        System.runAs(psLabUser) {
            Id fakeParentId = '0PS000000000001EAA';
            String fakeReference = 'TestReference';

            PSLab_SetupEntityAccessTransformer.PermissionLink link;
            Test.startTest();
            {
                link = new PSLab_SetupEntityAccessTransformer.PermissionLink(fakeParentId, fakeReference);
            }
            Test.stopTest();

            Assert.areEqual(fakeParentId, link.parentId, 'ParentId should be set by the constructor.');
            Assert.areEqual(fakeReference, link.referenceFieldValue, 'ReferenceFieldValue should be set by the constructor.');
        }
    }
}