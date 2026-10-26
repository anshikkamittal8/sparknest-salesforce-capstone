/**
 * Implements the handler interface for Enquiry__c.
 * Only delegates to EnquiryService; no business logic lives here.
 */
public with sharing class EnquiryTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newRecords) {
        List<Enquiry__c> enquiries = (List<Enquiry__c>) newRecords;
        EnquiryService.setDefaultStatus(enquiries);
        EnquiryService.validateBudget(enquiries);
    }

    public void afterInsert(List<SObject> newRecords) {
        EnquiryService.createFollowUpTasks((List<Enquiry__c>) newRecords);
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        EnquiryService.stampClosedDate(
            (List<Enquiry__c>) newRecords,
            (Map<Id, Enquiry__c>) oldMap
        );
    }

    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {}
    public void beforeDelete(List<SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}