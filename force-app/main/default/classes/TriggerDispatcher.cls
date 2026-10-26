/**
 * Routes each trigger context to the matching handler method.
 * Triggers stay one line: TriggerDispatcher.run(new XHandler());
 */
public with sharing class TriggerDispatcher {

    public static void run(ITriggerHandler handler) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            } else if (Trigger.isDelete) {
                handler.beforeDelete(Trigger.old);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handler.afterInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                handler.afterUpdate(Trigger.new, Trigger.oldMap);
            } else if (Trigger.isDelete) {
                handler.afterDelete(Trigger.old);
            } else if (Trigger.isUndelete) {
                handler.afterUndelete(Trigger.new);
            }
        }
    }
}