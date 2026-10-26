@IsTest
private class SparkNestEnquiryAPITest {

    private static Map<String, Object> call(String body) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/SparkNestEnquiryAPI';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        SparkNestEnquiryAPI.createEnquiry();
        return (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
    }

    @IsTest
    static void newCustomerCreatesContactAndEnquiry() {
        Map<String, Object> res = call('{"email":"new.customer@example.com","firstName":"New","lastName":"Customer","subject":"Interested in Pulse","enquiryType":"Product Enquiry","customerBudget":5000}');
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, res.get('success'));
        System.assertEquals(true, res.get('contactCreated'));
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Email = 'new.customer@example.com']);
        System.assertEquals(1, [SELECT COUNT() FROM Enquiry__c]);
    }

    @IsTest
    static void existingCustomerIsReused() {
        Contact c = TestDataFactory.createContact(true);
        Map<String, Object> res = call('{"email":"' + c.Email + '","subject":"Care plan question","enquiryType":"Care Plan Enquiry"}');
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(false, res.get('contactCreated'));
        System.assertEquals(c.Id, (Id) res.get('contactId'));
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Email = :c.Email], 'No duplicate Contact');
    }

    @IsTest
    static void missingEmailReturns400() {
        Map<String, Object> res = call('{"lastName":"NoEmail","subject":"Hello"}');
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.get('success'));
        System.assertEquals('Email is required', res.get('error'));
    }

    @IsTest
    static void invalidJsonReturns400() {
        call('not json');
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void failedEnquiryRollsBackNewContact() {
        Map<String, Object> res = call('{"email":"rollback@example.com","lastName":"Rollback","subject":"Low budget","customerBudget":500}');
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.get('success'));
        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Email = 'rollback@example.com'], 'Contact rolled back');
    }
}