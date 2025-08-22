/**
 * @author       : Oumaima Arbani
 * @date         : 08-17-2025
 * @description  : A data model class that holds the detailed results of a permission analysis, designed to be passed from Apex to LWC.
 * @group        : PSLab
 **/
public class PSLab_DetectedPermission {

    @AuraEnabled public String permissionType { get; set; }

    @AuraEnabled public Id permissionSetId { get; set; }

    @AuraEnabled public String permissionSetLabel { get; set; }

    @AuraEnabled public String permissionSetDeveloperName { get; set; }

    @AuraEnabled
    public List<String> includedIn { get; set; }

    @AuraEnabled public ObjectPermissionDetails objectPermissionDetails;
    @AuraEnabled public FieldPermissionDetails fieldPermissionDetails;
    @AuraEnabled public ApexClassPermissionDetails apexClassPermissionDetails;
    @AuraEnabled public ApexPagePermissionDetails apexPagePermissionDetails;
    @AuraEnabled public CustomPermissionDetails customPermissionDetails;
    @AuraEnabled public TabSettingDetails tabSettingDetails;
    @AuraEnabled public SetupEntityAccessDetails setupEntityAccessDetails;
    @AuraEnabled public GenericPermissionSetDetails genericPermissionSetDetails;

    // Object Permissions
    public class ObjectPermissionDetails {
        @AuraEnabled public String sObjectType { get; set; }
        @AuraEnabled public Boolean permissionsCreate { get; set; }
        @AuraEnabled public Boolean permissionsRead { get; set; }
        @AuraEnabled public Boolean permissionsEdit { get; set; }
        @AuraEnabled public Boolean permissionsDelete { get; set; }
        @AuraEnabled public Boolean permissionsViewAllRecords { get; set; }
        @AuraEnabled public Boolean permissionsModifyAllRecords { get; set; }
        @AuraEnabled public Boolean permissionsViewAllFields { get; set; }
    }

    // Field Permissions
    public class FieldPermissionDetails {
        @AuraEnabled public String sObjectType { get; set; }
        @AuraEnabled public String field { get; set; }
        @AuraEnabled public Boolean permissionsRead { get; set; }
        @AuraEnabled public Boolean permissionsEdit { get; set; }
    }

    // Apex Class Access
    public class ApexClassPermissionDetails {
        @AuraEnabled public String name { get; set; }
    }

    // Apex Page Access
    public class ApexPagePermissionDetails {
        @AuraEnabled public String name { get; set; }
    }

    // Custom Permission Access
    public class CustomPermissionDetails {
        @AuraEnabled public String developerName { get; set; }
    }

    // Tab Settings
    public class TabSettingDetails {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String visibility { get; set; }
    }

    // Setup Entity Access (TabSet, FlowDefinition, CustomMetadataType, CustomSetting)
    public class SetupEntityAccessDetails {
        @AuraEnabled public String setupEntityId { get; set; }
    }

    // PermissionSet (boolean flags)
    public class GenericPermissionSetDetails {
        @AuraEnabled public Map<String, Boolean> permissions { get; set; }
    }
}