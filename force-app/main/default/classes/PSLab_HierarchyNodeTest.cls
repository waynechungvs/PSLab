/**
 * @author       : Oumaima ARBANI
 * @date         : 22/08/2025
 * @description  : Test class for the PSLab_HierarchyNode data model.
 * @group        : PSLab
 **/
@IsTest
private class PSLab_HierarchyNodeTest {

    /**
     * @description  : Verifies that the PSLab_HierarchyNode data model can be instantiated and all its properties can be set and retrieved correctly.
     * @author       : Oumaima Arbani | 2025-08-22
     **/
    @IsTest
    private static void testNodeProperties() {
        PSLab_HierarchyNode childNode = new PSLab_HierarchyNode();
        childNode.name = 'Test_Child_Permission_Set';
        childNode.label = 'Test Child Permission Set';

        PSLab_HierarchyNode parentNode = new PSLab_HierarchyNode();
        parentNode.permissionSetId = '0PS000000000001EAA';
        parentNode.name = 'Test_Parent_Permission_Set_Group';
        parentNode.label = 'Test Parent Permission Set Group';
        parentNode.type = 'PSG';
        parentNode.description = 'A test description for the parent node.';
        parentNode.createdBy = 'Test User';
        parentNode.lastModifiedBy = 'Test User';
        parentNode.lastModifiedDate = '2025-08-22';
        parentNode.status = 'Updated';
        parentNode.children.add(childNode);


        Assert.areEqual('0PS000000000001EAA', parentNode.permissionSetId, 'permissionSetId should be set correctly.');
        Assert.areEqual('Test_Parent_Permission_Set_Group', parentNode.name, 'name should be set correctly.');
        Assert.areEqual('Test Parent Permission Set Group', parentNode.label, 'label should be set correctly.');
        Assert.areEqual('PSG', parentNode.type, 'type should be set correctly.');
        Assert.areEqual('A test description for the parent node.', parentNode.description, 'description should be set correctly.');
        Assert.areEqual('Test User', parentNode.createdBy, 'createdBy should be set correctly.');
        Assert.areEqual('Test User', parentNode.lastModifiedBy, 'lastModifiedBy should be set correctly.');
        Assert.areEqual('2025-08-22', parentNode.lastModifiedDate, 'lastModifiedDate should be set correctly.');
        Assert.areEqual('Updated', parentNode.status, 'status should be set correctly.');

        Assert.isNotNull(parentNode.children, 'The children list should be initialized.');
        Assert.areEqual(1, parentNode.children.size(), 'The children list should contain one node.');
        Assert.areEqual('Test_Child_Permission_Set', parentNode.children[0].name, 'The child node name should be correct.');
    }
}