/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public with sharing class PSLab_PermissionSetExporterController{
    @AuraEnabled(Cacheable=true)
    public static List<PSLab_PermissionSetExporterHelper.PermissionSetInfo> getPermissionSets(){
        return PSLab_PermissionSetExporterHelper.getPermissionSets();
    }

    @AuraEnabled(Cacheable=true)
    public static String exportPermissionSetAsCSV(Id permissionSetId, List<String> permissions) {
        return PSLab_PermissionSetExporterHelper.generateCSVHelper(permissionSetId, permissions);
    }

}