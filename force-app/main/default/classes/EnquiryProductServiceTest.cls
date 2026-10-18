@IsTest
private class EnquiryProductServiceTest {

    private static Decimal total(Id enquiryId) {
        return [SELECT Total_Products_Interested__c FROM Enquiry__c WHERE Id = :enquiryId].Total_Products_Interested__c;
    }

    private static Enquiry_Product__c junction(Id enquiryId, Id productId) {
        return new Enquiry_Product__c(Enquiry__c = enquiryId, Product__c = productId, QuantityInterested__c = 1);
    }

    @IsTest
    static void countFollowsInsertDeleteUndeleteAndReparent() {
        List<Enquiry__c> enquiries = TestDataFactory.createEnquiries(2, 'New', 5000, true);
        Enquiry__c a = enquiries[0];
        Enquiry__c b = enquiries[1];
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;

        // insert 3
        List<Enquiry_Product__c> items = new List<Enquiry_Product__c>{
            junction(a.Id, p.Id), junction(a.Id, p.Id), junction(a.Id, p.Id)
        };
        insert items;
        System.assertEquals(3, total(a.Id), 'Count after inserting 3');

        // delete 1
        delete items[2];
        System.assertEquals(2, total(a.Id), 'Count after deleting 1');

        // undelete
        undelete items[2];
        System.assertEquals(3, total(a.Id), 'Count after undelete');

        // move one record to another Enquiry: both parents recalculate
        items[0].Enquiry__c = b.Id;
        update items[0];
        System.assertEquals(2, total(a.Id), 'Old parent count drops');
        System.assertEquals(1, total(b.Id), 'New parent count rises');

        // delete all remaining under A: count returns to 0
        delete [SELECT Id FROM Enquiry_Product__c WHERE Enquiry__c = :a.Id];
        System.assertEquals(0, total(a.Id), 'Count returns to zero');
    }

    @IsTest
    static void bulkInsert200() {
        Enquiry__c a = TestDataFactory.createEnquiries(1, 'New', 5000, true)[0];
        Product2 p = new Product2(Name = 'Bulk Product', IsActive = true);
        insert p;
        List<Enquiry_Product__c> items = new List<Enquiry_Product__c>();
        for (Integer i = 0; i < 200; i++) {
            items.add(junction(a.Id, p.Id));
        }
        Test.startTest();
        insert items;
        Test.stopTest();
        System.assertEquals(200, total(a.Id), 'Bulk count');
    }
}