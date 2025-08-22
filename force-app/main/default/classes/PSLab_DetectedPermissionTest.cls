/**
 * @author       : Oumaima ARBANI
 * @date         : 22-08-2025
 * @description  : Test class for the PSLab_DetectedPermission data model.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_DetectedPermissionTest {

    /**
     * @description  : Verifies that the data model and its inner classes can be instantiated
     * and that their properties can be set and retrieved correctly.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testModelProperties() {
        // --- 1. Instantiate and populate the main class ---
        PSLab_DetectedPermission detectedPerm = new PSLab_DetectedPermission();
        detectedPerm.permissionType = 'PSG';
        detectedPerm.permissionSetId = '0PS000000000001EAA';
        detectedPerm.permissionSetLabel = 'Test Permission Set';
        detectedPerm.permissionSetDeveloperName = 'Test_Permission_Set';
        detectedPerm.includedIn = new List<String>{'Test_PSG'};

        // --- 2. Instantiate and populate each inner class ---

        // ObjectPermissionDetails
        PSLab_DetectedPermission.ObjectPermissionDetails objDetails = new PSLab_DetectedPermission.ObjectPermissionDetails();
        objDetails.sObjectType = 'Account';
        objDetails.permissionsRead = true;
        objDetails.permissionsCreate = false;
        detectedPerm.objectPermissionDetails = objDetails;

        // FieldPermissionDetails
        PSLab_DetectedPermission.FieldPermissionDetails fieldDetails = new PSLab_DetectedPermission.FieldPermissionDetails();
        fieldDetails.sObjectType = 'Account';
        fieldDetails.field = 'Account.Name';
        fieldDetails.permissionsEdit = true;
        detectedPerm.fieldPermissionDetails = fieldDetails;

        // ApexClassPermissionDetails
        PSLab_DetectedPermission.ApexClassPermissionDetails apexClassDetails = new PSLab_DetectedPermission.ApexClassPermissionDetails();
        apexClassDetails.name = 'MyTestClass';
        detectedPerm.apexClassPermissionDetails = apexClassDetails;

        // ApexPagePermissionDetails
        PSLab_DetectedPermission.ApexPagePermissionDetails apexPageDetails = new PSLab_DetectedPermission.ApexPagePermissionDetails();
        apexPageDetails.name = 'MyTestPage';
        detectedPerm.apexPagePermissionDetails = apexPageDetails;

        // CustomPermissionDetails
        PSLab_DetectedPermission.CustomPermissionDetails customPermDetails = new PSLab_DetectedPermission.CustomPermissionDetails();
        customPermDetails.developerName = 'My_Custom_Permission';
        detectedPerm.customPermissionDetails = customPermDetails;

        // TabSettingDetails
        PSLab_DetectedPermission.TabSettingDetails tabDetails = new PSLab_DetectedPermission.TabSettingDetails();
        tabDetails.name = 'Account';
        tabDetails.visibility = 'Visible';
        detectedPerm.tabSettingDetails = tabDetails;

        // SetupEntityAccessDetails
        PSLab_DetectedPermission.SetupEntityAccessDetails setupDetails = new PSLab_DetectedPermission.SetupEntityAccessDetails();
        setupDetails.setupEntityId = '00N000000000001EAA';
        detectedPerm.setupEntityAccessDetails = setupDetails;

        // GenericPermissionSetDetails
        PSLab_DetectedPermission.GenericPermissionSetDetails genericDetails = new PSLab_DetectedPermission.GenericPermissionSetDetails();
        genericDetails.permissions = new Map<String, Boolean>{'PermissionsApiUserOnly' => true};
        detectedPerm.genericPermissionSetDetails = genericDetails;

        Test.startTest();
        // No logic to execute, but good practice for structure
        Test.stopTest();

        // --- 3. Assert that all values were stored correctly ---
        Assert.areEqual('PSG', detectedPerm.permissionType);
        Assert.areEqual('Test Permission Set', detectedPerm.permissionSetLabel);
        Assert.isNotNull(detectedPerm.includedIn);

        Assert.isNotNull(detectedPerm.objectPermissionDetails);
        Assert.areEqual('Account', detectedPerm.objectPermissionDetails.sObjectType);
        Assert.isTrue(detectedPerm.objectPermissionDetails.permissionsRead);

        Assert.isNotNull(detectedPerm.fieldPermissionDetails);
        Assert.areEqual('Account.Name', detectedPerm.fieldPermissionDetails.field);
        Assert.isTrue(detectedPerm.fieldPermissionDetails.permissionsEdit);

        Assert.isNotNull(detectedPerm.apexClassPermissionDetails);
        Assert.areEqual('MyTestClass', detectedPerm.apexClassPermissionDetails.name);

        Assert.isNotNull(detectedPerm.apexPagePermissionDetails);
        Assert.areEqual('MyTestPage', detectedPerm.apexPagePermissionDetails.name);

        Assert.isNotNull(detectedPerm.customPermissionDetails);
        Assert.areEqual('My_Custom_Permission', detectedPerm.customPermissionDetails.developerName);

        Assert.isNotNull(detectedPerm.tabSettingDetails);
        Assert.areEqual('Visible', detectedPerm.tabSettingDetails.visibility);

        Assert.isNotNull(detectedPerm.setupEntityAccessDetails);
        Assert.areEqual('00N000000000001EAA', detectedPerm.setupEntityAccessDetails.setupEntityId);

        Assert.isNotNull(detectedPerm.genericPermissionSetDetails);
        Assert.isTrue(detectedPerm.genericPermissionSetDetails.permissions.get('PermissionsApiUserOnly'));
    }
}