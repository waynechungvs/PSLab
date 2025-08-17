/**
 * @author       : Oumaima ARBANI
 * @date         : 16/8/2025
 * @description  : 
 * @group        : PSLab
 **/
public with sharing class PSLab_SetupEntityAccessTransformer{

    /**
     * @description A simple data structure to link a Permission Set (ParentId) to a
     * specific component's name or API name (referenceFieldValue).
     */
    public class PermissionLink {
        public Id parentId;
        public String referenceFieldValue;

        public PermissionLink(Id parentId, String referenceFieldValue) {
            this.parentId = parentId;
            this.referenceFieldValue = referenceFieldValue;
        }
    }

    /**
     * @description Transforms a list of SObjects (like ApexClass, ApexPage) into a flat
     * list of PermissionLink objects, extracting the nested permission set assignments.
     * @param records The list of SObjects to process.
     * @param referenceField The API name of the field to use as the reference value (e.g., 'Name').
     * @return A list of PermissionLink objects.
     */
    public static List<PermissionLink> transform(List<SObject> records, String referenceField) {
        List<PermissionLink> links = new List<PermissionLink>();

        for (SObject record : records) {
            List<SetupEntityAccess> setupEntityAccesses = new List<SetupEntityAccess>();

            if (record instanceof ApexClass) {
                setupEntityAccesses = ((ApexClass) record).SetupEntityAccessItems;
            } else if (record instanceof ApexPage) {
                setupEntityAccesses = ((ApexPage) record).SetupEntityAccessItems;
            } else if (record instanceof CustomPermission) {
                setupEntityAccesses = ((CustomPermission) record).SetupEntityAccessItems;
            }

            // Continue only if there are permissions to process
            if (setupEntityAccesses.isEmpty()) {
                continue;
            }

            String referenceValue = (String) record.get(referenceField);

            for (SetupEntityAccess item : setupEntityAccesses) {
                links.add(new PermissionLink(item.ParentId, referenceValue));
            }
        }
        return links;
    }

}