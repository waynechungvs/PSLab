/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public without sharing class PSLab_AllPermissionsHierarchyBuilder{
    private Map<Id, List<PermissionSet>> groupToChildren;
    private Set<Id> groupedPermissionSetIds;

    public PSLab_HierarchyNode build(){
        this.initializeGroupData();
        PSLab_HierarchyNode groupsBranch = this.buildGroupsBranch();
        PSLab_HierarchyNode standaloneSetsBranch = this.buildStandaloneSetsBranch();

        PSLab_HierarchyNode rootNode = new PSLab_HierarchyNode();
        rootNode.name = UserInfo.getOrganizationName();
        rootNode.type = 'parentNode';
        if(groupsBranch != null){
            rootNode.children.add(groupsBranch);
        }
        if(standaloneSetsBranch != null){
            rootNode.children.add(standaloneSetsBranch);
        }

        return rootNode;
    }

    private void initializeGroupData(){
        this.groupToChildren = new Map<Id, List<PermissionSet>>();
        this.groupedPermissionSetIds = new Set<Id>();

        for(PermissionSetGroupComponent permissionSetGroupComponent : [
                SELECT PermissionSetGroupId, PermissionSet.Id, PermissionSet.Name, PermissionSet.Label, PermissionSet.Description, PermissionSet.CreatedBy.Name, PermissionSet.LastModifiedBy.Name, PermissionSet.LastModifiedDate
                FROM PermissionSetGroupComponent
                WHERE PermissionSet.Id != NULL
                WITH SYSTEM_MODE

        ]) {
            this.groupedPermissionSetIds.add(permissionSetGroupComponent.PermissionSetId);
            if(!this.groupToChildren.containsKey(permissionSetGroupComponent.PermissionSetGroupId)){
                this.groupToChildren.put(permissionSetGroupComponent.PermissionSetGroupId, new List<PermissionSet>());
            }
            this.groupToChildren.get(permissionSetGroupComponent.PermissionSetGroupId).add(permissionSetGroupComponent.PermissionSet);
        }
    }

    private PSLab_HierarchyNode buildGroupsBranch(){
        List<PermissionSetGroup> allGroups = [
                SELECT Id, MasterLabel, DeveloperName, Description, Status, CreatedBy.Name, LastModifiedBy.Name, LastModifiedDate
                FROM PermissionSetGroup
                WITH SYSTEM_MODE
                ORDER BY DeveloperName
        ];

        if(allGroups.isEmpty()){
            return null;
        }

        List<PSLab_HierarchyNode> groupNodes = new List<PSLab_HierarchyNode>();
        for(PermissionSetGroup permissionSetGroup : allGroups) {
            PSLab_HierarchyNode groupNode = createNodeFromGroup(permissionSetGroup);
            if(this.groupToChildren.containsKey(permissionSetGroup.Id)){
                for(PermissionSet permissionSet : this.groupToChildren.get(permissionSetGroup.Id)) {
                    groupNode.children.add(createNodeFromPermissionSet(permissionSet));
                }
            }
            groupNodes.add(groupNode);
        }

        PSLab_HierarchyNode groupsBranch = new PSLab_HierarchyNode();
        groupsBranch.name = 'Permission Set Groups';
        groupsBranch.type = 'PSG';
        groupsBranch.children = groupNodes;
        return groupsBranch;
    }

    private PSLab_HierarchyNode buildStandaloneSetsBranch(){
        List<PermissionSet> standaloneSets = [
                SELECT Id, Name, Label, Description, CreatedBy.Name, LastModifiedBy.Name, LastModifiedDate
                FROM PermissionSet
                WHERE Id NOT IN :this.groupedPermissionSetIds
                        AND IsOwnedByProfile = FALSE
                        AND Type != 'Group'
                WITH SYSTEM_MODE
                ORDER BY Name
        ];

        if(standaloneSets.isEmpty()){
            return null;
        }

        List<PSLab_HierarchyNode> standaloneSetNodes = new List<PSLab_HierarchyNode>();
        for(PermissionSet permissionSet : standaloneSets) {
            standaloneSetNodes.add(createNodeFromPermissionSet(permissionSet));
        }

        PSLab_HierarchyNode standaloneBranch = new PSLab_HierarchyNode();
        standaloneBranch.name = 'Standalone Permission Sets';
        standaloneBranch.type = 'PS';
        standaloneBranch.children = standaloneSetNodes;
        return standaloneBranch;
    }

    private PSLab_HierarchyNode createNodeFromPermissionSet(PermissionSet permissionSet){
        PSLab_HierarchyNode node = new PSLab_HierarchyNode();
        node.permissionSetId = permissionSet.Id;
        node.name = permissionSet.Name;
        node.label = permissionSet.Label;
        node.description = permissionSet.Description;
        node.createdBy = permissionSet.CreatedBy?.Name;
        node.lastModifiedBy = permissionSet.LastModifiedBy?.Name;
        node.lastModifiedDate = permissionSet.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        return node;
    }

    private PSLab_HierarchyNode createNodeFromGroup(PermissionSetGroup permissionSetGroup){
        PSLab_HierarchyNode node = new PSLab_HierarchyNode();
        node.permissionSetId = permissionSetGroup.Id;
        node.label = permissionSetGroup.MasterLabel;
        node.name = permissionSetGroup.DeveloperName;
        node.description = permissionSetGroup.Description;
        node.status = permissionSetGroup.Status;
        node.createdBy = permissionSetGroup.CreatedBy?.Name;
        node.lastModifiedBy = permissionSetGroup.LastModifiedBy?.Name;
        node.lastModifiedDate = permissionSetGroup.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        return node;
    }

}