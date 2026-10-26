/**
 * All business logic for Enquiry__c. Bulk-safe: no SOQL or DML inside loops.
 *
 * SUBJECT_FIELD: the brief's "Subject" is assumed to be the standard Name field
 * (converted from Auto Number to Text). If you create a separate Subject__c
 * field instead, change this one constant to 'Subject__c'.
 */
public with sharing class EnquiryService {

    public static final String SUBJECT_FIELD = 'Name';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_CLOSED = 'Closed';
    public static final Decimal MIN_BUDGET = 1000;
    public static final Integer FOLLOW_UP_DAYS = 3;
    // \u20B9 is the rupee sign
    public static final String BUDGET_ERROR = 'Customer budget must be at least \u20B91,000';

    // Before Insert: blank Status becomes New
    public static void setDefaultStatus(List<Enquiry__c> enquiries) {
        for (Enquiry__c e : enquiries) {
            if (String.isBlank(e.Status__c)) {
                e.Status__c = STATUS_NEW;
            }
        }
    }

    // Before Insert: budget below 1,000 is rejected with a field error
    public static void validateBudget(List<Enquiry__c> enquiries) {
        for (Enquiry__c e : enquiries) {
            if (e.Customer_Budget__c != null && e.Customer_Budget__c < MIN_BUDGET) {
                e.Customer_Budget__c.addError(BUDGET_ERROR);
            }
        }
    }

    // After Insert: one follow-up Task per Enquiry, due in 3 days, owned by the Enquiry owner
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

    // Before Update: Status changes to Closed, so Closed Date becomes today
    public static void stampClosedDate(List<Enquiry__c> newList, Map<Id, Enquiry__c> oldMap) {
        for (Enquiry__c e : newList) {
            Enquiry__c old = oldMap.get(e.Id);
            if (old != null && e.Status__c == STATUS_CLOSED && old.Status__c != STATUS_CLOSED) {
                e.Closed_Date__c = Date.today();
            }
        }
    }

    // Tasks cannot be owned by a queue; fall back to the running user
    @TestVisible
    private static Id resolveTaskOwner(Id enquiryOwnerId) {
        if (enquiryOwnerId != null && String.valueOf(enquiryOwnerId).startsWith('005')) {
            return enquiryOwnerId;
        }
        return UserInfo.getUserId();
    }
}