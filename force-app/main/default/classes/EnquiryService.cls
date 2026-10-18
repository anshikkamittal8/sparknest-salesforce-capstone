public with sharing class EnquiryService {

    public static final String SUBJECT_FIELD = 'Name';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_CLOSED = 'Closed';
    public static final Decimal MIN_BUDGET = 1000;
    public static final Integer FOLLOW_UP_DAYS = 3;
    public static final String BUDGET_ERROR = 'Customer budget must be at least \u20B91,000';

    public static void setDefaultStatus(List<Enquiry__c> enquiries) {
        for (Enquiry__c e : enquiries) {
            if (String.isBlank(e.Status__c)) {
                e.Status__c = STATUS_NEW;
            }
        }
    }

    public static void validateBudget(List<Enquiry__c> enquiries) {
        for (Enquiry__c e : enquiries) {
            if (e.Customer_Budget__c != null && e.Customer_Budget__c < MIN_BUDGET) {
                e.Customer_Budget__c.addError(BUDGET_ERROR);
            }
        }
    }

    public static void createFollowUpTasks(List<Enquiry__c> enquiries) {
        List<Task> tasks = new List<Task>();
        for (Enquiry__c e : enquiries) {
            tasks.add(new Task(
                Subject = 'Follow up: ' + (String) e.get(SUBJECT_FIELD),
                WhatId = e.Id,
                OwnerId = resolveTaskOwner(e.OwnerId),
                ActivityDate = Date.today().addDays(FOLLOW_UP_DAYS)
            ));
        }
        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    public static void stampClosedDate(List<Enquiry__c> newList, Map<Id, Enquiry__c> oldMap) {
        for (Enquiry__c e : newList) {
            Enquiry__c old = oldMap.get(e.Id);
            if (old != null && e.Status__c == STATUS_CLOSED && old.Status__c != STATUS_CLOSED) {
                e.Closed_Date__c = Date.today();
            }
        }
    }
    @TestVisible
    private static Id resolveTaskOwner(Id enquiryOwnerId) {
        if (enquiryOwnerId != null && String.valueOf(enquiryOwnerId).startsWith('005')) {
            return enquiryOwnerId;
        }
        return UserInfo.getUserId();
    }
}