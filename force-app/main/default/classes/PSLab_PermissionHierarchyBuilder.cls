/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public with sharing class PSLab_PermissionHierarchyBuilder{
    public class HierarchyNode {
        @AuraEnabled public String permissionSetId;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String description;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String lastModifiedBy;
        @AuraEnabled public String lastModifiedDate;
        @AuraEnabled public String status;
        @AuraEnabled public List<HierarchyNode> children = new List<HierarchyNode>();
    }

    private final List<PermissionSetAssignment> assignments;
    private final User assignee;

    public PSLab_PermissionHierarchyBuilder(List<PermissionSetAssignment> assignments) {
        this.assignments = assignments;
        this.assignee = (assignments.isEmpty()) ? null : assignments[0].Assignee;
    }

    /**
     * @description Main method to construct the entire hierarchy.
     * @return The root node of the hierarchy.
     */
    public HierarchyNode build() {
        if (assignee == null) {
            return new HierarchyNode();
        }

        Map<Id, PermissionSetAssignment> groupAssignments = new Map<Id, PermissionSetAssignment>();
        List<PermissionSetAssignment> standaloneAssignments = new List<PermissionSetAssignment>();
        for (PermissionSetAssignment permissionSetAssignments : this.assignments) {
            if (permissionSetAssignments.PermissionSetGroupId != null) {
                groupAssignments.put(permissionSetAssignments.PermissionSetGroupId, permissionSetAssignments);
            } else {
                standaloneAssignments.add(permissionSetAssignments);
            }
        }

        List<HierarchyNode> rootChildren = new List<HierarchyNode>();
        if (!groupAssignments.isEmpty()) {
            rootChildren.add(buildGroupsBranch(groupAssignments));
        }
        if (!standaloneAssignments.isEmpty()) {
            rootChildren.add(buildStandaloneBranch(standaloneAssignments));
        }

        HierarchyNode rootNode = new HierarchyNode();
        rootNode.name = this.assignee.Name + '\n(' + this.assignee.Username + ')';
        rootNode.children = rootChildren;

        return rootNode;
    }

    /**
     * @description Builds the "Permission Set Groups" branch of the hierarchy.
     * @param groupAssignments
     * @return HierarchyNode
     */
    private HierarchyNode buildGroupsBranch(Map<Id, PermissionSetAssignment> groupAssignments) {
        Map<Id, List<PermissionSet>> groupToPermissionSetsMap = getGroupToPermissionSetsMap(groupAssignments.keySet());

        List<HierarchyNode> groupNodes = new List<HierarchyNode>();
        for (Id groupId : groupAssignments.keySet()) {
            PermissionSetAssignment assignment = groupAssignments.get(groupId);

            HierarchyNode groupNode = createNodeFromGroup(assignment.PermissionSetGroup);

            if (groupToPermissionSetsMap.containsKey(groupId)) {
                for (PermissionSet ps : groupToPermissionSetsMap.get(groupId)) {
                    groupNode.children.add(createNodeFromPermissionSet(ps));
                }
            }
            groupNodes.add(groupNode);
        }

        HierarchyNode groupsBranch = new HierarchyNode();
        groupsBranch.name = 'Permission Set Groups';
        groupsBranch.children = groupNodes;
        return groupsBranch;
    }

    /**
     * @description Builds the "Standalone Permission Sets" branch of the hierarchy.
     * @param standaloneAssignments
     * @return HierarchyNode
     */
    private HierarchyNode buildStandaloneBranch(List<PermissionSetAssignment> standaloneAssignments) {
        List<HierarchyNode> standaloneNodes = new List<HierarchyNode>();
        for (PermissionSetAssignment assignment : standaloneAssignments) {
            standaloneNodes.add(createNodeFromPermissionSet(assignment.PermissionSet));
        }

        HierarchyNode standaloneBranch = new HierarchyNode();
        standaloneBranch.name = 'Standalone Permission Sets';
        standaloneBranch.children = standaloneNodes;
        return standaloneBranch;
    }

    /**
     * @description Queries and maps Permission Sets to their parent Group ID.
     * @param groupIds
     * @return  Map<Id, List<PermissionSet>>
     */
    private Map<Id, List<PermissionSet>> getGroupToPermissionSetsMap(Set<Id> groupIds) {
        Map<Id, List<PermissionSet>> groupToPermissionSetsMap = new Map<Id, List<PermissionSet>>();

        List<PermissionSetGroupComponent> components = [
                SELECT PermissionSetGroupId,
                        PermissionSet.Id, PermissionSet.Name, PermissionSet.Label, PermissionSet.Description,
                        PermissionSet.CreatedBy.Name, PermissionSet.LastModifiedBy.Name, PermissionSet.LastModifiedDate
                FROM PermissionSetGroupComponent
                WHERE PermissionSetGroupId IN :groupIds
        ];

        for(PermissionSetGroupComponent comp : components) {
            if (!groupToPermissionSetsMap.containsKey(comp.PermissionSetGroupId)) {
                groupToPermissionSetsMap.put(comp.PermissionSetGroupId, new List<PermissionSet>());
            }
            groupToPermissionSetsMap.get(comp.PermissionSetGroupId).add(comp.PermissionSet);
        }
        return groupToPermissionSetsMap;
    }

    private HierarchyNode createNodeFromPermissionSet(PermissionSet ps) {
        HierarchyNode node = new HierarchyNode();
        node.permissionSetId = ps.Id;
        node.name = ps.Name;
        node.label = ps.Label;
        node.description = ps.Description;
        node.createdBy = ps.CreatedBy?.Name;
        node.lastModifiedBy = ps.LastModifiedBy?.Name;
        node.lastModifiedDate = ps.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        return node;
    }

    private HierarchyNode createNodeFromGroup(PermissionSetGroup psg) {
        HierarchyNode node = new HierarchyNode();
        node.permissionSetId = psg.Id;
        node.name = psg.DeveloperName;
        node.label = psg.MasterLabel;
        node.description = psg.Description;
        node.createdBy = psg.CreatedBy?.Name;
        node.lastModifiedBy = psg.LastModifiedBy?.Name;
        node.lastModifiedDate = psg.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        node.status = psg.Status;
        return node;
    }

}