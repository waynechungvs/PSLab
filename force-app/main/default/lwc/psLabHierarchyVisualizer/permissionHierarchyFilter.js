import {deepClone} from "c/psLabCoreUtils";

export class PermissionHierarchyFilter {
    filter(hierarchyData, detectedPermissions, payload) {
        const highlightedIds = new Set();
        if (!hierarchyData || !detectedPermissions || detectedPermissions.length === 0) {
            return {filteredData: null, highlightedIds};
        }

        const filteredRoot = this._filterHierarchy(
            hierarchyData,
            detectedPermissions,
            payload,
            highlightedIds
        );

        return {filteredData: filteredRoot, highlightedIds};
    }

    _filterHierarchy(hierarchyData, detectedPermissions, payload, highlightedIds) {
        const filteredRoot = deepClone(hierarchyData);
        filteredRoot.children = [];
        const originalRootChildren = hierarchyData.children || [];

        originalRootChildren.forEach(branch => {
            const originalBranchCopy = deepClone(branch);
            if (branch.name === 'Permission Set Groups') {
                const filteredBranch = this._filterGroupsBranch(originalBranchCopy, detectedPermissions, payload, highlightedIds);
                if (filteredBranch) {
                    filteredRoot.children.push(filteredBranch);
                }
            } else if (branch.name === 'Standalone Permission Sets') {
                const filteredBranch = this._filterStandaloneBranch(originalBranchCopy, detectedPermissions, payload, highlightedIds);
                if (filteredBranch) {
                    filteredRoot.children.push(filteredBranch);
                }
            }
        });

        return (filteredRoot.children.length > 0) ? filteredRoot : null;
    }

    _filterGroupsBranch(branch, detectedPermissions, payload, highlightedIds) {
        const originalGroups = branch.children || [];
        const filteredGroups = [];
        const allDetectedPsIds = this.collectIds(detectedPermissions);
        for (const group of originalGroups) {
            let groupToAdd;
            // Case 1: User searched for a specific PSG by name.
            if (payload?.permissionType === 'PSG' && payload.permissionsAPINames) {
                if (group.name === payload.permissionsAPINames) {
                    groupToAdd = group; // This is our target group
                } else {
                    continue; // Skip all other groups
                }
            }
            // Case 2: Broad PSG search OR any other search type that might involve groups
            else {
                groupToAdd = group; // Consider every group
            }

            const matchingPsChildren = [];
            for (const ps of (groupToAdd.children || [])) {
                if (allDetectedPsIds.has(ps.permissionSetId)) {
                    matchingPsChildren.push(deepClone(ps));
                    highlightedIds.add(ps.permissionSetId);
                }
            }

            // If the group contains any matching children after all filters, add it to the results.
            if (matchingPsChildren.length > 0) {
                const filteredGroup = deepClone(groupToAdd);
                filteredGroup.children = matchingPsChildren;
                filteredGroups.push(filteredGroup);
                highlightedIds.add(groupToAdd.permissionSetId);
            }
        }

        if (filteredGroups.length > 0) {
            branch.children = filteredGroups;
            return branch;
        }
        return null;
    }

    _filterStandaloneBranch(branch, detectedPermissions, payload, highlightedIds) {
        const originalStandaloneSets = branch.children || [];
        const filteredStandaloneSets = [];
        const allDetectedIds = this.collectIds(detectedPermissions);
        if (payload?.permissionType === 'PS' && payload.permissionsAPINames) {
            const targetPsName = payload.permissionsAPINames;

            const targetPsInHierarchy = originalStandaloneSets.find(ps => ps.name === targetPsName);

            if (targetPsInHierarchy) {
                const detectedInfo = detectedPermissions.find(p => p.permissionSetId === targetPsInHierarchy.permissionSetId);

                if (detectedInfo && (!detectedInfo.includedIn || detectedInfo.includedIn.length === 0)) {
                    filteredStandaloneSets.push(deepClone(targetPsInHierarchy));
                    highlightedIds.add(targetPsInHierarchy.permissionSetId);
                }
            }
        }else if (!payload || (payload?.permissionType === 'PS' && !payload.permissionsAPINames) || (payload?.permissionType !== 'PS' && payload?.permissionType !== 'PSG')){
            for (const ps of originalStandaloneSets) {
                if (allDetectedIds.has(ps.permissionSetId)) {
                    const detectedInfo = this.findDetectedInfo(detectedPermissions, ps.permissionSetId);

                    if (detectedInfo && (!detectedInfo?.includedIn || detectedInfo?.includedIn?.length === 0)) {
                        filteredStandaloneSets.push(deepClone(ps));
                        highlightedIds.add(ps.permissionSetId);
                    }
                    filteredStandaloneSets.push(deepClone(ps));
                    highlightedIds.add(ps.permissionSetId);
                }
            }

        }
        if (filteredStandaloneSets.length > 0) {
            branch.children = filteredStandaloneSets;
            return branch;
        }

        return null;
    }

    collectIds(nodeOrArray, ids = new Set()) {
        if (Array.isArray(nodeOrArray)) {
            for (const item of nodeOrArray) {
                this.collectIds(item, ids);
            }
        } else if (nodeOrArray && typeof nodeOrArray === 'object') {
            if (nodeOrArray.permissionSetId) {
                ids.add(nodeOrArray.permissionSetId);
            }

            if (nodeOrArray.children && Array.isArray(nodeOrArray.children)) {
                for (const child of nodeOrArray.children) {
                    this.collectIds(child, ids);
                }
            }
        }
        return ids;
    }

    findDetectedInfo(node, id) {
        if (node.permissionSetId === id) {
            return node;
        }
        if (node.children && Array.isArray(node.children)) {
            for (const child of node.children) {
                const found = this.findDetectedInfo(child, id);
                if (found) {
                    return found;
                }
            }
        }
        return null;
    }
}