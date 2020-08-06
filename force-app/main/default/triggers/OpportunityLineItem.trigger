trigger OpportunityLineItem on OpportunityLineItem (before update, after update, before delete) {
    if (OpportunityLineItemHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_UPDATE {
                OpportunityLineItemHelper.sendEmailForApprovedItemsWithDateChange(Trigger.new);
            }
            when BEFORE_UPDATE {
                OpportunityLineItemHelper.removeConfirmedFields(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                OpportunityLineItemHelper.blockDelete(Trigger.old);
            }
        }
    } 
}