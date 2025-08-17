/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : NovAi
 **/
public with sharing class PSLab_AllPermissionsHierarchyBuilder{
    public class HierarchyNode {
        @AuraEnabled public String permissionSetId;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String description;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String lastModifiedBy;
        @AuraEnabled public String lastModifiedDate;
        @AuraEnabled public String status; // For Permission Set Groups
        @AuraEnabled public List<HierarchyNode> children = new List<HierarchyNode>();
    }

    private Map<Id, List<PermissionSet>> groupToChildren;
    private Set<Id> groupedPermissionSetIds;

    public HierarchyNode build() {
        this.initializeGroupData();

        // Build the two main branches of the hierarchy
        HierarchyNode groupsBranch = this.buildGroupsBranch();
        HierarchyNode standaloneSetsBranch = this.buildStandaloneSetsBranch();

        HierarchyNode rootNode = new HierarchyNode();
        rootNode.name = UserInfo.getOrganizationName();
        rootNode.type = 'parentNode';
        if (groupsBranch != null) {
            rootNode.children.add(groupsBranch);
        }
        if (standaloneSetsBranch != null) {
            rootNode.children.add(standaloneSetsBranch);
        }

        return rootNode;
    }

    private void initializeGroupData() {
        this.groupToChildren = new Map<Id, List<PermissionSet>>();
        this.groupedPermissionSetIds = new Set<Id>();

        for (PermissionSetGroupComponent permissionSetGroupComponent : [
                SELECT PermissionSetGroupId,
                        PermissionSet.Id, PermissionSet.Name, PermissionSet.Description,
                        PermissionSet.CreatedBy.Name, PermissionSet.LastModifiedBy.Name,
                        PermissionSet.LastModifiedDate
                FROM PermissionSetGroupComponent
                WITH SYSTEM_MODE
                ORDER BY PermissionSet.Name
        ]) {
            this.groupedPermissionSetIds.add(permissionSetGroupComponent.PermissionSetId);
            if (!this.groupToChildren.containsKey(permissionSetGroupComponent.PermissionSetGroupId)) {
                this.groupToChildren.put(permissionSetGroupComponent.PermissionSetGroupId, new List<PermissionSet>());
            }
            this.groupToChildren.get(permissionSetGroupComponent.PermissionSetGroupId).add(permissionSetGroupComponent.PermissionSet);
        }
    }

    private HierarchyNode buildGroupsBranch() {
        List<PermissionSetGroup> allGroups = [
                SELECT Id, MasterLabel, DeveloperName, Description, Status,
                        CreatedBy.Name, LastModifiedBy.Name, LastModifiedDate
                FROM PermissionSetGroup
                WITH SYSTEM_MODE
                ORDER BY DeveloperName
        ];

        if (allGroups.isEmpty()) {
            return null;
        }

        List<HierarchyNode> groupNodes = new List<HierarchyNode>();
        for (PermissionSetGroup permissionSetGroup : allGroups) {
            HierarchyNode groupNode = createNodeFromGroup(permissionSetGroup);
            if (this.groupToChildren.containsKey(permissionSetGroup.Id)) {
                for (PermissionSet permissionSet : this.groupToChildren.get(permissionSetGroup.Id)) {
                    groupNode.children.add(createNodeFromPermissionSet(permissionSet));
                }
            }
            groupNodes.add(groupNode);
        }

        HierarchyNode groupsBranch = new HierarchyNode();
        groupsBranch.name = 'Permission Set Groups';
        groupsBranch.type = 'PSG';
        groupsBranch.children = groupNodes;
        return groupsBranch;
    }

    private HierarchyNode buildStandaloneSetsBranch() {
        List<PermissionSet> standaloneSets = [
                SELECT Id, Name, Description, CreatedBy.Name,
                        LastModifiedBy.Name, LastModifiedDate
                FROM PermissionSet
                WHERE Id NOT IN :this.groupedPermissionSetIds
                        AND IsOwnedByProfile = FALSE
                WITH SYSTEM_MODE
                ORDER BY Name
        ];

        if (standaloneSets.isEmpty()) {
            return null;
        }

        List<HierarchyNode> standaloneSetNodes = new List<HierarchyNode>();
        for (PermissionSet permissionSet : standaloneSets) {
            standaloneSetNodes.add(createNodeFromPermissionSet(permissionSet));
        }

        HierarchyNode standaloneBranch = new HierarchyNode();
        standaloneBranch.name = 'Standalone Permission Sets';
        standaloneBranch.type = 'PS';
        standaloneBranch.children = standaloneSetNodes;
        return standaloneBranch;
    }

    private HierarchyNode createNodeFromPermissionSet(PermissionSet permissionSet) {
        HierarchyNode node = new HierarchyNode();
        node.permissionSetId = permissionSet.Id;
        node.name = permissionSet.Name;
        node.description = permissionSet.Description;
        node.createdBy = permissionSet.CreatedBy?.Name;
        node.lastModifiedBy = permissionSet.LastModifiedBy?.Name;
        node.lastModifiedDate = permissionSet.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        return node;
    }

    private HierarchyNode createNodeFromGroup(PermissionSetGroup permissionSetGroup) {
        HierarchyNode node = new HierarchyNode();
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