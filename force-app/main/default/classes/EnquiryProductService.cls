public class EnquiryProductService {
    public static void recalculate(List<Enquiry_Product__c> newRecords, Map<Id, Enquiry_Product__c> oldMap) {
        Set<Id> enquiryIds = new Set<Id>();

        // insert, update, undelete: the (new) parent
        if (newRecords != null) {
            for (Enquiry_Product__c r : newRecords) {
                if (r.Enquiry__c != null) {
                    enquiryIds.add(r.Enquiry__c);
                }
            }
        }
        // update, delete: the old parent (covers the Enquiry lookup being changed)
        if (oldMap != null) {
            for (Enquiry_Product__c r : oldMap.values()) {
                if (r.Enquiry__c != null) {
                    enquiryIds.add(r.Enquiry__c);
                }
            }
        }
        if (enquiryIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Enquiry__c eid, COUNT(Id) total
            FROM Enquiry_Product__c
            WHERE Enquiry__c IN :enquiryIds
            GROUP BY Enquiry__c
        ]) {
            counts.put((Id) ar.get('eid'), (Integer) ar.get('total'));
        }

        List<Enquiry__c> toUpdate = new List<Enquiry__c>();
        for (Id enquiryId : enquiryIds) {
            toUpdate.add(new Enquiry__c(
                Id = enquiryId,
                Total_Products_Interested__c = counts.containsKey(enquiryId) ? counts.get(enquiryId) : 0
            ));
        }
        update toUpdate;
    }
}