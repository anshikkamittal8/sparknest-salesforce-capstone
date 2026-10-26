/**
 * POST /services/apexrest/SparkNestEnquiryAPI
 * Finds a Contact by email (creates one if none exists), then creates an Enquiry.
 * Contact + Enquiry are created together: if the Enquiry fails, the Contact is rolled back.
 */
@RestResource(urlMapping='/SparkNestEnquiryAPI/*')
global with sharing class SparkNestEnquiryAPI {

    public class EnquiryRequest {
        public String email;
        public String firstName;
        public String lastName;
        public String phone;
        public String city;
        public String subject;
        public String enquiryType;
        public Decimal customerBudget;
        public String source;
        public String planDuration;
        public String priority;
    }

    @HttpPost
    global static void createEnquiry() {
        RestContext.response.addHeader('Content-Type', 'application/json');

        EnquiryRequest req;
        try {
            String body = RestContext.request.requestBody == null ? '' : RestContext.request.requestBody.toString();
            if (String.isBlank(body)) {
                respond(400, false, 'Request body is required');
                return;
            }
            req = (EnquiryRequest) JSON.deserialize(body, EnquiryRequest.class);
        } catch (Exception ex) {
            respond(400, false, 'Invalid JSON body: ' + ex.getMessage());
            return;
        }

        // ---- Validation ----
        if (String.isBlank(req.email)) {
            respond(400, false, 'Email is required');
            return;
        }
        String email = req.email.trim();
        if (!email.contains('@')) {
            respond(400, false, 'Email is not valid');
            return;
        }
        if (String.isBlank(req.subject)) {
            respond(400, false, 'Subject is required');
            return;
        }

        // ---- Find or create Contact ----
        List<Contact> existing = [
            SELECT Id FROM Contact WHERE Email = :email ORDER BY CreatedDate ASC LIMIT 1
        ];
        Boolean contactCreated = existing.isEmpty();
        if (contactCreated && String.isBlank(req.lastName)) {
            respond(400, false, 'lastName is required when the email is not already a Contact');
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            Contact con;
            if (contactCreated) {
                con = new Contact(
                    FirstName = req.firstName,
                    LastName = req.lastName,
                    Email = email,
                    Phone = req.phone,
                    MailingCity = req.city
                );
                insert con;
            } else {
                con = existing[0];
            }

            Enquiry__c enq = new Enquiry__c(
                Contact__c = con.Id,
                Enquiry_Type__c = String.isBlank(req.enquiryType) ? 'Product Enquiry' : req.enquiryType,
                Customer_Budget__c = req.customerBudget
            );
            enq.put(EnquiryService.SUBJECT_FIELD, req.subject);
            if (!String.isBlank(req.source)) { enq.Enquiry_Source__c = req.source; }
            if (!String.isBlank(req.planDuration)) { enq.Plan_Duration__c = req.planDuration; }
            if (!String.isBlank(req.priority)) { enq.Priority__c = req.priority; }
            insert enq;

            Map<String, Object> payload = new Map<String, Object>{
                'success' => true,
                'contactId' => con.Id,
                'enquiryId' => enq.Id,
                'contactCreated' => contactCreated,
                'message' => contactCreated ? 'New contact and enquiry created' : 'Existing contact found; enquiry created'
            };
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(payload));
        } catch (DmlException dex) {
            Database.rollback(sp);
            respond(400, false, dex.getDmlMessage(0));
        } catch (Exception ex) {
            Database.rollback(sp);
            respond(500, false, ex.getMessage());
        }
    }

    private static void respond(Integer statusCode, Boolean success, String message) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(
            new Map<String, Object>{ 'success' => success, 'error' => message }
        ));
    }
}