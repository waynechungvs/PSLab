/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : Builds a permission hierarchy for a specific user based on their direct and group-based assignments.
 * @group        : PSLab
 **/
public without sharing class PSLab_PermissionHierarchyBuilder {
    private final List<PermissionSetAssignment> assignments;
    private final User assignee;

    /**
     * @description  : Constructor for the builder. Initializes with a user's assignments and sets the assignee.
     * @author Oumaima Arbani | 2025-08-22
     * @param assignments A list of PermissionSetAssignment records for a single user.
     **/
    public PSLab_PermissionHierarchyBuilder(List<PermissionSetAssignment> assignments) {
        this.assignments = assignments;
        this.assignee = (assignments.isEmpty()) ? null : assignments[0].Assignee;
    }

    /**
     * @description Main method to construct the entire hierarchy.
     * @return The root node of the hierarchy.
     */
    public PSLab_HierarchyNode build() {
        if (assignee == null) {
            return new PSLab_HierarchyNode();
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

        List<PSLab_HierarchyNode> rootChildren = new List<PSLab_HierarchyNode>();
        if (!groupAssignments.isEmpty()) {
            rootChildren.add(buildGroupsBranch(groupAssignments));
        }
        if (!standaloneAssignments.isEmpty()) {
            rootChildren.add(buildStandaloneBranch(standaloneAssignments));
        }

        PSLab_HierarchyNode rootNode = new PSLab_HierarchyNode();
        rootNode.name = this.assignee.Name + '\n(' + this.assignee.Username + ')';
        rootNode.children = rootChildren;

        return rootNode;
    }

    /**
     * @description Builds the "Permission Set Groups" branch of the hierarchy.
     * @param groupAssignments the permissionsets and PSGs Assignments
     * @return PSLab_HierarchyNode
     */
    private PSLab_HierarchyNode buildGroupsBranch(Map<Id, PermissionSetAssignment> groupAssignments) {
        Map<Id, List<PermissionSet>> groupToPermissionSetsMap = getGroupToPermissionSetsMap(groupAssignments.keySet());

        List<PSLab_HierarchyNode> groupNodes = new List<PSLab_HierarchyNode>();
        for (Id groupId : groupAssignments.keySet()) {
            PermissionSetAssignment assignment = groupAssignments.get(groupId);

            PSLab_HierarchyNode groupNode = createNodeFromGroup(assignment.PermissionSetGroup);

            if (groupToPermissionSetsMap.containsKey(groupId)) {
                for (PermissionSet ps : groupToPermissionSetsMap.get(groupId)) {
                    groupNode.children.add(createNodeFromPermissionSet(ps));
                }
            }
            groupNodes.add(groupNode);
        }

        PSLab_HierarchyNode groupsBranch = new PSLab_HierarchyNode();
        groupsBranch.name = 'Permission Set Groups';
        groupsBranch.children = groupNodes;
        return groupsBranch;
    }

    /**
     * @description Builds the "Standalone Permission Sets" branch of the hierarchy.
     * @param standaloneAssignments
     * @return PSLab_HierarchyNode
     */
    private PSLab_HierarchyNode buildStandaloneBranch(List<PermissionSetAssignment> standaloneAssignments) {
        List<PSLab_HierarchyNode> standaloneNodes = new List<PSLab_HierarchyNode>();
        for (PermissionSetAssignment assignment : standaloneAssignments) {
            standaloneNodes.add(createNodeFromPermissionSet(assignment.PermissionSet));
        }

        PSLab_HierarchyNode standaloneBranch = new PSLab_HierarchyNode();
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
                SELECT
                        PermissionSetGroupId,
                        PermissionSet.Id,
                        PermissionSet.Name,
                        PermissionSet.Label,
                        PermissionSet.Description,
                        PermissionSet.CreatedBy.Name,
                        PermissionSet.LastModifiedBy.Name,
                        PermissionSet.LastModifiedDate
                FROM PermissionSetGroupComponent
                WHERE PermissionSetGroupId IN :groupIds
        ];

        for (PermissionSetGroupComponent comp : components) {
            if (!groupToPermissionSetsMap.containsKey(comp.PermissionSetGroupId)) {
                groupToPermissionSetsMap.put(comp.PermissionSetGroupId, new List<PermissionSet>());
            }
            groupToPermissionSetsMap.get(comp.PermissionSetGroupId).add(comp.PermissionSet);
        }
        return groupToPermissionSetsMap;
    }

    /**
     * @description  : Helper method to convert a PermissionSet SObject into a standardized PSLab_HierarchyNode.
     * @author Oumaima Arbani | 2025-08-22
     * @param ps The PermissionSet record to convert.
     * @return A populated PSLab_HierarchyNode.
     **/
    private PSLab_HierarchyNode createNodeFromPermissionSet(PermissionSet ps) {
        PSLab_HierarchyNode node = new PSLab_HierarchyNode();
        node.permissionSetId = ps.Id;
        node.name = ps.Name;
        node.label = ps.Label;
        node.description = ps.Description;
        node.createdBy = ps.CreatedBy?.Name;
        node.lastModifiedBy = ps.LastModifiedBy?.Name;
        node.lastModifiedDate = ps.LastModifiedDate?.formatGmt('yyyy-MM-dd');
        return node;
    }

    /**
     * @description  : Helper method to convert a PermissionSetGroup SObject into a standardized PSLab_HierarchyNode.
     * @author Oumaima Arbani | 2025-08-22
     * @param psg The PermissionSetGroup record to convert.
     * @return A populated PSLab_HierarchyNode.
     **/
    private PSLab_HierarchyNode createNodeFromGroup(PermissionSetGroup psg) {
        PSLab_HierarchyNode node = new PSLab_HierarchyNode();
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