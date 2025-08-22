/**
 * @author       : Oumaima ARBANI
 * @date         : 22/08/2025
 * @description  : A reusable data structure for representing a node in a permission set hierarchy.
 * @group        : PSLab
 **/
public class PSLab_HierarchyNode {
    @AuraEnabled public String permissionSetId;
    @AuraEnabled public String name;
    @AuraEnabled public String label;
    @AuraEnabled public String type;
    @AuraEnabled public String description;
    @AuraEnabled public String createdBy;
    @AuraEnabled public String lastModifiedBy;
    @AuraEnabled public String lastModifiedDate;
    @AuraEnabled public String status;
    @AuraEnabled public List<PSLab_HierarchyNode> children = new List<PSLab_HierarchyNode>();
}