@IsTest
private class EnquiryServiceTest {

    @IsTest
    static void blankStatusDefaultsToNew_service() {
        List<Enquiry__c> list1 = new List<Enquiry__c>{ new Enquiry__c() };
        EnquiryService.setDefaultStatus(list1);
        System.assertEquals('New', list1[0].Status__c, 'Blank Status should become New');
    }

    @IsTest
    static void blankStatusDefaultsToNew_insert() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, null, 5000, false)[0];
        insert e;
        e = [SELECT Status__c FROM Enquiry__c WHERE Id = :e.Id];
        System.assertEquals('New', e.Status__c, 'Inserted Enquiry with blank Status should be New');
    }

    @IsTest
    static void budgetBelowMinimumFails() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, 'New', 500, false)[0];
        Database.SaveResult sr = Database.insert(e, false);
        System.assertEquals(false, sr.isSuccess(), 'Insert should fail for budget below 1,000');
        String msg = sr.getErrors()[0].getMessage();
        System.assert(msg.contains('Customer budget must be at least'), 'Unexpected error: ' + msg);
        System.assertEquals(0, [SELECT COUNT() FROM Enquiry__c], 'No Enquiry should be saved');
    }

    @IsTest
    static void budgetAtMinimumSucceeds() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, 'New', 1000, false)[0];
        Database.SaveResult sr = Database.insert(e, false);
        System.assert(sr.isSuccess(), 'Budget of exactly 1,000 should be accepted');
    }

    @IsTest
    static void insertCreatesFollowUpTask() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, 'New', 5000, true)[0];
        e = [SELECT Id, OwnerId FROM Enquiry__c WHERE Id = :e.Id];
        List<Task> tasks = [SELECT Subject, OwnerId, ActivityDate, WhatId FROM Task WHERE WhatId = :e.Id];
        System.assertEquals(1, tasks.size(), 'Exactly one follow-up Task expected');
        System.assertEquals('Follow up: Test Enquiry 0', tasks[0].Subject, 'Task subject');
        System.assertEquals(e.OwnerId, tasks[0].OwnerId, 'Task owner should be the Enquiry owner');
        System.assertEquals(Date.today().addDays(3), tasks[0].ActivityDate, 'Task due in 3 days');
    }

    @IsTest
    static void updateToClosedStampsClosedDate() {
        Enquiry__c e = TestDataFactory.createEnquiries(1, 'In Progress', 5000, true)[0];
        System.assertEquals(null, [SELECT Closed_Date__c FROM Enquiry__c WHERE Id = :e.Id].Closed_Date__c,
            'Closed Date should be empty before closing');
        e.Status__c = 'Closed';
        update e;
        System.assertEquals(Date.today(), [SELECT Closed_Date__c FROM Enquiry__c WHERE Id = :e.Id].Closed_Date__c,
            'Closed Date should be today');
    }

    @IsTest
    static void bulkInsertAndClose200() {
        List<Enquiry__c> enquiries = TestDataFactory.createEnquiries(200, null, 5000, false);
        Test.startTest();
        insert enquiries;
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Enquiry__c WHERE Status__c = 'New'], '200 Enquiries default to New');
        System.assertEquals(200, [SELECT COUNT() FROM Task WHERE Subject LIKE 'Follow up: %'], '200 follow-up Tasks');

        for (Enquiry__c e : enquiries) {
            e.Status__c = 'Closed';
        }
        update enquiries;
        System.assertEquals(200, [SELECT COUNT() FROM Enquiry__c WHERE Closed_Date__c = :Date.today()], '200 Closed Dates stamped');
    }
}