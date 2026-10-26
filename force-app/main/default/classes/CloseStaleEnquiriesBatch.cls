/**
 * Nightly job: close Enquiries In Progress with LastModifiedDate older than 30 days
 * AND no Task/Event activity modified in the last 30 days.
 * Assumption: "activity" = any related Task or Event modified within the window.
 * The constructor with arguments exists so tests can control the windows.
 */
public class CloseStaleEnquiriesBatch implements Database.Batchable<SObject> {

    private Integer staleDays;
    private Integer activityDays;

    public CloseStaleEnquiriesBatch() {
        this(30, 30);
    }

    public CloseStaleEnquiriesBatch(Integer staleDays, Integer activityDays) {
        this.staleDays = staleDays;
        this.activityDays = activityDays;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime staleCutoff = Datetime.now().addDays(-staleDays);
        return Database.getQueryLocator([
            SELECT Id, Status__c
            FROM Enquiry__c
            WHERE Status__c = 'In Progress'
            AND LastModifiedDate < :staleCutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Enquiry__c> scope) {
        Datetime activityCutoff = Datetime.now().addDays(-activityDays);
        Set<Id> enquiryIds = new Map<Id, Enquiry__c>(scope).keySet();
        Set<Id> withActivity = new Set<Id>();

        for (Task t : [SELECT WhatId FROM Task WHERE WhatId IN :enquiryIds AND LastModifiedDate >= :activityCutoff]) {
            withActivity.add(t.WhatId);
        }
        for (Event ev : [SELECT WhatId FROM Event WHERE WhatId IN :enquiryIds AND LastModifiedDate >= :activityCutoff]) {
            withActivity.add(ev.WhatId);
        }

        List<Enquiry__c> toClose = new List<Enquiry__c>();
        for (Enquiry__c e : scope) {
            if (!withActivity.contains(e.Id)) {
                e.Status__c = 'Closed';
                toClose.add(e);
            }
        }
        if (!toClose.isEmpty()) {
            update toClose;
        }
    }

    public void finish(Database.BatchableContext bc) {}
}