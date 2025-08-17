/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public with sharing class PSLab_PermissionAnalysisHelper{

    public static List<Object> getOptionsBySelectedPermissionHelper(String selectedPermission, String objectName) {
        switch on selectedPermission {
            when 'TabSet' {
                return getApplications();
            }
            when 'ObjectPermissions' {
                return getOrgAvailableObjectsByObjectAPIName();
            }
            when 'FieldPermissions' {
                return getFieldDefinitionByObjectAPIName(objectName);
            }
            when 'PermissionSetTabSetting' {
                return getTabsDefinition();
            }
            when 'ApexClass' {
                return getApexClasses();
            }
            when 'ApexPage' {
                return getVisualforcePages();
            }
            when 'FlowDefinition' {
                return getFlows();
            }
            when 'CustomPermission' {
                return getCustomPermissions();
            }
            when 'CustomMetadataType' {
                return getOrgCustomMetadata();
            }
            when 'CustomSetting' {
                return getOrgCustomSettings();
            }
            when 'PermissionSet' {
                return getSystemPermissions();
            }
            when else {
                return new List<Object>();
            }
        }
    }

    public static PSLab_PermissionHierarchyBuilder.HierarchyNode getPermissionSetHierarchyByUserId(String userId){
        List<PermissionSetAssignment> assignments = [
                SELECT PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.Description,
                        PermissionSet.CreatedBy.Name, PermissionSet.LastModifiedBy.Name, PermissionSet.LastModifiedDate,
                        PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel,
                        PermissionSetGroup.Description, PermissionSetGroup.CreatedBy.Name, PermissionSetGroup.Status,
                        PermissionSetGroup.LastModifiedBy.Name, PermissionSetGroup.LastModifiedDate,
                        Assignee.Name, Assignee.Username
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
        ];
        PSLab_PermissionHierarchyBuilder builder = new PSLab_PermissionHierarchyBuilder(assignments);
        return builder.build();
    }

    public static PSLab_AllPermissionsHierarchyBuilder.HierarchyNode getPermissionSetHierarchy() {
        PSLab_AllPermissionsHierarchyBuilder builder = new PSLab_AllPermissionsHierarchyBuilder();
        return builder.build();
    }

    public static List<Object> getPermissionsOrUsersList(String searchType) {
        switch on searchType {
            when 'PS' {
                return getPermissionSets();
            }
            when 'PSG' {
                return getPermissionSetGroups();
            }
            when 'User' {
                return getOrgUsers();
            }
            when else {
                return new List<Object>();
            }
        }
    }

    public static List<PSLab_DetectedPermission> getDetectedPermissions(Map<String, Object> payload) {
        String query = PSLab_PermissionDetectorHelper.getPermissionDetectionQuery(payload);
        List<SObject> rawRecords = Database.query(query);
        List<Object> preparedRecords = preparePermissionsWrapper(rawRecords, (String)payload.get('permission'));
        List<PermissionRecord> wrappedRecords = wrapRecords(preparedRecords, (String) payload.get('permission'));
        Set<Id> permissionSetIds = getPermissionSetIdsFromWrappers(wrappedRecords);
        Map<Id, PermissionSet> permissionSetById = fetchPermissionSets(permissionSetIds);
        Map<Id, List<String>> permissionSetToGroups = fetchPermissionSetGroups(permissionSetIds);
        return buildDetectedPermissionsList(wrappedRecords, payload, permissionSetById, permissionSetToGroups);


    }

    private static List<Object> getPermissionSets(){
        List<PermissionSet> permissionSetsList = [SELECT Id, Name, Label FROM PermissionSet WITH SYSTEM_MODE ORDER BY Label ASC];

        List<Object>  permissionSets = new List<Object>();
        for(PermissionSet permissionSet : permissionSetsList){
            permissionSets.add(new Map<String, Object>{
                    'Id' => permissionSet.Id,
                    'label' => permissionSet.Label + ' (' + permissionSet.Name + ')',
                    'value' => permissionSet.Name
            });
        }
        return permissionSets;
    }

    private static List<Object> getPermissionSetGroups(){
        List<PermissionSetGroup> permissionSetsList = [SELECT Id, MasterLabel, DeveloperName FROM PermissionSetGroup WITH SYSTEM_MODE ORDER BY MasterLabel ASC];

        List<Object>  permissionSetGroups = new List<Object>();
        for(PermissionSetGroup permissionSetGroup : permissionSetsList){
            permissionSetGroups.add(new Map<String, Object>{
                    'Id' => permissionSetGroup.Id,
                    'label' => permissionSetGroup.MasterLabel + ' (' + permissionSetGroup.DeveloperName + ')',
                    'value' => permissionSetGroup.DeveloperName
            });
        }
        return permissionSetGroups;
    }

    private static List<Object> getOrgUsers(){
        List<User> usersList = [SELECT Id, Name, Username FROM User WITH SYSTEM_MODE ORDER BY Name ASC];

        List<Object>  users = new List<Object>();
        for(User user : usersList){
            users.add(new Map<String, Object>{
                    'Id' => user.Id,
                    'label' => user.Name + ' (' + user.Username + ')',
                    'value' => user.Id
            });
        }
        return users;
    }

    private static List<Object> getApplications(){
        List<Object> applicationsList = new List<Object>();
        List<AppMenuItem> appDefinitions = [SELECT Id, Label, Name, ApplicationId FROM AppMenuItem WITH SYSTEM_MODE ORDER BY Label ASC];
        for(AppMenuItem appDefinition : appDefinitions){
            applicationsList.add(new Map<String, Object>{
                    'Id' => appDefinition.ApplicationId,
                    'label' => appDefinition.Label+ ' (' + appDefinition.Name + ')' ,
                    'value' => appDefinition.Name
            });
        }
        return applicationsList;
    }

    private static List<Object> getOrgAvailableObjectsByObjectAPIName(){
        List<Object> objectList = new List<Object>();
        String lastEntityQueried;

        do {
            EntityDefinition[] definitions = [
                    SELECT MasterLabel, QualifiedApiName
                    FROM EntityDefinition
                    WHERE QualifiedApiName > :lastEntityQueried
                    ORDER BY QualifiedApiName ASC
                    LIMIT 2000
            ];

            if(definitions.isEmpty()){
                break;
            }

            for(EntityDefinition definition : definitions) {
                objectList.add(new Map<String, Object>{
                        'label' => definition.MasterLabel + ' (' + definition.QualifiedApiName + ')',
                        'value' => definition.QualifiedApiName
                });
            }

            if(!definitions.isEmpty()){
                lastEntityQueried = definitions[definitions.size() - 1].QualifiedApiName;
            }

            if(definitions.size() < 2000){
                break;
            }
        }
        while(true);

        return objectList;
    }

    private static List<Object> getFieldDefinitionByObjectAPIName(String objectAPIName) {
        List<Object> fieldsList = new List<Object>();

        try {
            SObjectType r = ((SObject)Type.forName('Schema.' + objectAPIName).newInstance()).getSObjectType();
            DescribeSObjectResult describeResult = r.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();

                if (fieldDescribe.isPermissionable()) {
                    fieldsList.add(new Map<String, Object>{
                            'label' => fieldDescribe.getLabel() + ' (' + fieldDescribe.getName() + ')',
                            'value' => fieldDescribe.getName()
                    });
                }
            }
        } catch (Exception e) {
            System.debug('Error in getFieldDefinitionByObjectAPIName: ' + e.getMessage());
        }

        return fieldsList;
    }

    private static List<Object> getTabsDefinition(){
        List<Object> tabsList = new List<Object>();
        List<TabDefinition> tabDefinitions = [SELECT Name, Label FROM TabDefinition WITH SYSTEM_MODE ORDER BY Label ASC];
        for(TabDefinition tabDefinition : tabDefinitions){
            tabsList.add(new Map<String, Object>{
                    'label' => tabDefinition.Label + ' (' + tabDefinition.Name + ')',
                    'value' => tabDefinition.Name
            });
        }
        return tabsList;
    }

    private static List<Object> getApexClasses(){
        List<Object> apexClassesList = new List<Object>();
        List<ApexClass> apexClasses = [SELECT Name FROM ApexClass WITH SYSTEM_MODE ORDER BY Name ASC ];
        for(ApexClass apexClass : apexClasses){
            apexClassesList.add(new Map<String, Object>{
                    'label' => apexClass.Name,
                    'value' => apexClass.Name
            });
        }
        return apexClassesList;
    }

    private static List<Object> getVisualforcePages(){
        List<Object> visualforcePagesList = new List<Object>();
        List<ApexPage> visualforcePages = [SELECT Name FROM ApexPage WITH SYSTEM_MODE ORDER BY Name ASC];
        for(ApexPage visualforcePage : visualforcePages){
            visualforcePagesList.add(new Map<String, Object>{
                    'label' => visualforcePage.Name,
                    'value' => visualforcePage.Name
            });
        }
        return visualforcePagesList;
    }

    private static List<Object> getFlows(){
        List<Object> flowsList = new List<Object>();
        List<FlowDefinitionView> flows = [SELECT Id, DurableId,ApiName, Label FROM FlowDefinitionView WHERE ActiveVersionId != NULL WITH SYSTEM_MODE ORDER BY Label ASC];
        for(FlowDefinitionView flow : flows){
            flowsList.add(new Map<String, Object>{
                    'Id' => flow.Id,
                    'label' => flow.Label + ' (' + flow.ApiName + ')',
                    'value' => flow.DurableId
            });
        }
        return flowsList;
    }

    private static List<Object> getCustomPermissions(){
        List<Object> customPermissionsList = new List<Object>();
        List<CustomPermission> customPermissions = [SELECT DeveloperName, MasterLabel FROM CustomPermission WITH SYSTEM_MODE ORDER BY MasterLabel ASC];
        for(CustomPermission customPermission : customPermissions){
            customPermissionsList.add(new Map<String, Object>{
                    'label' => customPermission.MasterLabel + ' (' + customPermission.DeveloperName + ')',
                    'value' => customPermission.DeveloperName
            });
        }
        return customPermissionsList;
    }

    private static List<Object> getOrgCustomMetadata() {
        List<Object> customMetadataTypesList = new List<Object>();

        List<EntityDefinition> customMetadataTypes = [
                SELECT Id, DeveloperName, Label, DurableId
                FROM EntityDefinition
                WHERE
                        IsCustomizable = TRUE
                                AND EntityDefinition.QualifiedApiName LIKE '%__mdt'
        ];

        for (EntityDefinition customMetadataType : customMetadataTypes) {
            customMetadataTypesList.add(new Map<String, Object>{
                    'Id' => customMetadataType.DurableId,
                    'label' => customMetadataType.Label + ' (' + customMetadataType.DeveloperName + ')',
                    'value' => customMetadataType.DeveloperName
            });
        }

        return customMetadataTypesList;
    }

    private static List<Object> getOrgCustomSettings() {
        List<Object> customSettingsList = new List<Object>();
        List<EntityDefinition> customSettings = [SELECT Id, DurableId, DeveloperName, Label
        FROM EntityDefinition
        WHERE IsCustomSetting = TRUE] ;
        for(EntityDefinition customSetting : customSettings){
            customSettingsList.add(new Map<String, Object>{
                    'Id' => customSetting.DurableId,
                    'label' => customSetting.Label + ' (' + customSetting.DeveloperName + ')',
                    'value' => customSetting.DeveloperName
            });
        }
        return customSettingsList;
    }

    private static List<Object> getSystemPermissions(){
        List<Object> systemPermissionsList = new List<Object>();
        List<PSLab_SP__mdt> systemPermissionsMetaData = [SELECT SystemPermissionAPIName__c, SystemPermissionLabel__c FROM PSLab_SP__mdt WITH SYSTEM_MODE ORDER BY SystemPermissionLabel__c ASC];
        for(PSLab_SP__mdt systemPermission : systemPermissionsMetaData){
            systemPermissionsList.add(new Map<String, Object>{
                    'label' => systemPermission.SystemPermissionLabel__c,
                    'value' => systemPermission.SystemPermissionAPIName__c
            });
        }
        return systemPermissionsList;
    }

    private static List<Object> preparePermissionsWrapper(List<SObject> records, String permissionToCheck) {
        List<Object> permissionsData = new List<Object>();

        switch on permissionToCheck {
            when 'ApexClass', 'ApexPage', 'CustomPermission' {
                String referenceField = (permissionToCheck == 'CustomPermission') ? 'DeveloperName' : 'Name';
                permissionsData.addAll(PSLab_SetupEntityAccessTransformer.transform(records, referenceField));
            }
            when else {
                permissionsData.addAll(records);
            }
        }

        return permissionsData;
    }

    /**
 * @description Converts the raw list of queried objects into a list of standardized PermissionRecord wrappers.
 * @param records
 * @param permissionToCheck
 * @return List<PermissionRecord>
 */
    private static List<PermissionRecord> wrapRecords(List<Object> records, String permissionToCheck) {
        List<PermissionRecord> wrappers = new List<PermissionRecord>();
        for (Object record : records) {
            wrappers.add(new PermissionRecord(record, permissionToCheck));
        }
        return wrappers;
    }

    /**
 * @description Extracts a unique set of Permission Set IDs from the wrapped records.
 * @param wrappedRecords
 * @return Set<Id>
 */
    private static Set<Id> getPermissionSetIdsFromWrappers(List<PermissionRecord> wrappedRecords) {
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionRecord wrapper : wrappedRecords) {
            permissionSetIds.add(wrapper.permissionSetId);
        }
        return permissionSetIds;
    }

    private static Map<Id, PermissionSet> fetchPermissionSets(Set<Id> permissionSetIds) {
        return new Map<Id, PermissionSet>([
                SELECT Id, Label, Name FROM PermissionSet WHERE Id IN :permissionSetIds
        ]);
    }

    private static Map<Id, List<String>> fetchPermissionSetGroups(Set<Id> permissionSetIds) {
        Map<Id, List<String>> permissionSetToGroupsMap = new Map<Id, List<String>>();
        List<PermissionSetGroupComponent> permissionSetGroupComponents = [
                SELECT PermissionSetId, PermissionSetGroup.DeveloperName
                FROM PermissionSetGroupComponent
                WHERE PermissionSetId IN :permissionSetIds
        ];

        for(PermissionSetGroupComponent component : permissionSetGroupComponents) {
            Id permissionSetId = component.PermissionSetId;
            String groupDeveloperName = component.PermissionSetGroup.DeveloperName;

            if(!permissionSetToGroupsMap.containsKey(permissionSetId)){
                permissionSetToGroupsMap.put(permissionSetId, new List<String>());
            }
            permissionSetToGroupsMap.get(permissionSetId).add(groupDeveloperName);
        }
        return permissionSetToGroupsMap;
    }

    private static List<PSLab_DetectedPermission> buildDetectedPermissionsList(
            List<PermissionRecord> wrappedRecords,
            Map<String, Object> payload,
            Map<Id, PermissionSet> permissionSetById,
            Map<Id, List<String>> permissionSetToGroups
    ) {

        List<PSLab_DetectedPermission> detectedPermissions = new List<PSLab_DetectedPermission>();
        String permissionType = (String) payload.get('permissionType');
        for (PermissionRecord wrapper : wrappedRecords) {
            PermissionSet ps = permissionSetById.get(wrapper.permissionSetId);
            if (ps == null) continue;

            PSLab_DetectedPermission detected = new PSLab_DetectedPermission();
            detected.permissionType = permissionType;
            detected.permissionSetId = wrapper.permissionSetId;
            detected.permissionSetLabel = ps.Label;
            detected.permissionSetDeveloperName = ps.Name;
            detected.includedIn = permissionSetToGroups.get(wrapper.permissionSetId) != null
                    ? permissionSetToGroups.get(wrapper.permissionSetId)
                    : new List<String>();

            populatePermissionDetails(detected, wrapper, payload);

            detectedPermissions.add(detected);
        }
        return detectedPermissions;

    }

    private static void populatePermissionDetails(
            PSLab_DetectedPermission detected,
            PermissionRecord wrapper,
            Map<String, Object> payload
    ) {

        String permissionToCheck = (String) payload.get('permission');
        switch on permissionToCheck {
            when 'ObjectPermissions' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.ObjectPermissionDetails details = new PSLab_DetectedPermission.ObjectPermissionDetails();
                details.sObjectType = (String) sobj.get('SobjectType');
                details.permissionsCreate = (Boolean) sobj.get('PermissionsCreate');
                details.permissionsRead = (Boolean) sobj.get('PermissionsRead');
                details.permissionsEdit = (Boolean) sobj.get('PermissionsEdit');
                details.permissionsDelete = (Boolean) sobj.get('PermissionsDelete');
                details.permissionsViewAllRecords = (Boolean) sobj.get('PermissionsViewAllRecords');
                details.permissionsModifyAllRecords = (Boolean) sobj.get('PermissionsModifyAllRecords');
                details.permissionsViewAllFields = (Boolean) sobj.get('PermissionsViewAllFields');
                detected.objectPermissionDetails = details;
            }
            when 'FieldPermissions' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.FieldPermissionDetails details = new PSLab_DetectedPermission.FieldPermissionDetails();
                details.sObjectType = (String) sobj.get('SObjectType');
                details.field = (String) sobj.get('Field');
                details.permissionsRead = (Boolean) sobj.get('PermissionsRead');
                details.permissionsEdit = (Boolean) sobj.get('PermissionsEdit');
                detected.fieldPermissionDetails = details;
            }
            when 'ApexClass' {
                PSLab_DetectedPermission.ApexClassPermissionDetails details = new PSLab_DetectedPermission.ApexClassPermissionDetails();
                details.name = wrapper.referenceValue;
                detected.apexClassPermissionDetails = details;
            }
            when 'ApexPage' {
                PSLab_DetectedPermission.ApexPagePermissionDetails details = new PSLab_DetectedPermission.ApexPagePermissionDetails();
                details.name = wrapper.referenceValue;
                detected.apexPagePermissionDetails = details;
            }
            when 'CustomPermission' {
                PSLab_DetectedPermission.CustomPermissionDetails details = new PSLab_DetectedPermission.CustomPermissionDetails();
                details.developerName = wrapper.referenceValue;
                detected.customPermissionDetails = details;
            }
            when 'PermissionSetTabSetting' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.TabSettingDetails details = new PSLab_DetectedPermission.TabSettingDetails();
                details.name = (String) sobj.get('Name');
                details.visibility = (String) sobj.get('Visibility');
                detected.tabSettingDetails = details;
            }
            when 'TabSet', 'FlowDefinition', 'CustomMetadataType', 'CustomSetting' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.SetupEntityAccessDetails details = new PSLab_DetectedPermission.SetupEntityAccessDetails();
                details.setupEntityId = (String) sobj.get('SetupEntityId');
                detected.setupEntityAccessDetails = details;
            }
            when 'PermissionSet' {
                SObject sobj = (SObject) wrapper.sourceRecord;
                PSLab_DetectedPermission.GenericPermissionSetDetails details = new PSLab_DetectedPermission.GenericPermissionSetDetails();
                Map<String, Boolean> permissionsMap = new Map<String, Boolean>();
                for (String permission : ((String) payload.get('metadataNames')).split(',')) {
                    String trimmedPermission = permission.trim();
                    if (String.isNotBlank(trimmedPermission)) {
                        permissionsMap.put(trimmedPermission, (Boolean) sobj.get(trimmedPermission));
                    }
                }
                details.permissions = permissionsMap;
                detected.genericPermissionSetDetails = details;
                detected.includedIn = new List<String>();
            }
            when else {
                System.debug('Unexpected permission type: ' + permissionToCheck);
            }
        }
    }

    private class PermissionRecord {
        Id permissionSetId;
        String referenceValue; // Used for Apex Class, VF Page, Custom Permission names
        Object sourceRecord;

        PermissionRecord(Object record, String permissionToCheck) {
            this.sourceRecord = record;
            if (record instanceof PSLab_SetupEntityAccessTransformer.PermissionLink) {
                PSLab_SetupEntityAccessTransformer.PermissionLink link =
                        (PSLab_SetupEntityAccessTransformer.PermissionLink) record;

                this.permissionSetId = link.parentId;
                this.referenceValue = link.referenceFieldValue;
            } else {
                SObject sobj = (SObject) record;
                this.permissionSetId = (permissionToCheck == 'PermissionSet')
                        ? (Id) sobj.get('Id')
                        : (Id) sobj.get('ParentId');
            }
        }
    }


}