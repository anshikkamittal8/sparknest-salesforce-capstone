trigger EnquiryProductTrigger on Enquiry_Product__c (after insert, after update, after delete, after undelete) {
    // Trigger.new is null on delete; Trigger.oldMap is null on insert and undelete
    EnquiryProductService.recalculate(Trigger.new, Trigger.oldMap);
}