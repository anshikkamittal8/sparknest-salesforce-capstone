trigger EnquiryProductTrigger on Enquiry_Product__c (after insert, after update, after delete, after undelete) {
    EnquiryProductService.recalculate(Trigger.new, Trigger.oldMap);
}