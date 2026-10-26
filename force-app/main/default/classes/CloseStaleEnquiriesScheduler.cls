public class CloseStaleEnquiriesScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CloseStaleEnquiriesBatch(), 200);
    }
}
// Run once in Execute Anonymous (nightly at 1:00 AM):
// System.schedule('Close Stale Enquiries Nightly', '0 0 1 * * ?', new CloseStaleEnquiriesScheduler());