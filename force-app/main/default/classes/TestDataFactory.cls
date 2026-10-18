@IsTest
public class TestDataFactory {

    private static Integer counter = 0;

    public static Contact createContact(Boolean doInsert) {
        counter++;
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Customer' + counter,
            Email = 'test.customer' + counter + '.' + Math.abs(Crypto.getRandomInteger()) + '@example.com'
        );
        if (doInsert) {
            insert c;
        }
        return c;
    }

    public static List<Enquiry__c> createEnquiries(Integer count, String status, Decimal budget, Boolean doInsert) {
        Contact c = createContact(true);
        List<Enquiry__c> enquiries = new List<Enquiry__c>();
        for (Integer i = 0; i < count; i++) {
            Enquiry__c e = new Enquiry__c(
                Enquiry_Type__c = 'Product Enquiry',
                Contact__c = c.Id,
                Status__c = status,
                Customer_Budget__c = budget
            );
            e.put(EnquiryService.SUBJECT_FIELD, 'Test Enquiry ' + i);
            enquiries.add(e);
        }
        if (doInsert) {
            insert enquiries;
        }
        return enquiries;
    }
}