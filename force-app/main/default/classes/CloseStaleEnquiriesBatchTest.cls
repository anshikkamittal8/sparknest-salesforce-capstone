@IsTest
private class CloseStaleEnquiriesBatchTest {

    @IsTest
    static void closesOnlyStaleEnquiriesWithNoRecentActivity() {
        List<Enquiry__c> inProgress = TestDataFactory.createEnquiries(2, 'In Progress', 5000, true);
        Enquiry__c noActivity = inProgress[0];
        Enquiry__c withActivity = inProgress[1];
        Enquiry__c notInProgress = TestDataFactory.createEnquiries(1, 'New', 5000, true)[0];

        // The insert trigger creates a follow-up Task for every Enquiry.
        // Remove it for the "no activity" Enquiry; keep it for the other.
        delete [SELECT Id FROM Task WHERE WhatId = :noActivity.Id];

        Test.startTest();
        // staleDays = -1 treats every Enquiry as older than the cutoff (LastModifiedDate cannot be backdated)
        Database.executeBatch(new CloseStaleEnquiriesBatch(-1, 30), 200);
        Test.stopTest();

        Map<Id, Enquiry__c> result = new Map<Id, Enquiry__c>([
            SELECT Status__c, Closed_Date__c FROM Enquiry__c
        ]);
        System.assertEquals('Closed', result.get(noActivity.Id).Status__c, 'Stale Enquiry with no activity should close');
        System.assertEquals(Date.today(), result.get(noActivity.Id).Closed_Date__c, 'Closed Date stamped by trigger');
        System.assertEquals('In Progress', result.get(withActivity.Id).Status__c, 'Recent activity keeps it open');
        System.assertEquals('New', result.get(notInProgress.Id).Status__c, 'Only In Progress Enquiries are touched');
    }

    @IsTest
    static void recentlyModifiedEnquiriesAreNotClosedWithDefaultWindow() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, 'In Progress', 5000, true)[0];
        delete [SELECT Id FROM Task WHERE WhatId = :e.Id];
        Test.startTest();
        Database.executeBatch(new CloseStaleEnquiriesBatch(), 200);
        Test.stopTest();
        System.assertEquals('In Progress', [SELECT Status__c FROM Enquiry__c WHERE Id = :e.Id].Status__c,
            'Enquiry modified today is not 30 days stale');
    }

    @IsTest
    static void schedulerIsScheduled() {
        String cron = '0 0 1 * * ?';
        Test.startTest();
        Id jobId = System.schedule('Test Close Stale Enquiries', cron, new CloseStaleEnquiriesScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cron, ct.CronExpression, 'Cron expression should match');
    }
}