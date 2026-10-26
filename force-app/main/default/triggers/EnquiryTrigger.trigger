trigger EnquiryTrigger on Enquiry__c (before insert, before update, after insert) {
    TriggerDispatcher.run(new EnquiryTriggerHandler());
}