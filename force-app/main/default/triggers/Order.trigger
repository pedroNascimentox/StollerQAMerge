trigger Order on Order (after insert, before update, after update, before delete, before insert) {
    if (OrderHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                OrderHelper.countOrdByOpp(Trigger.newMap, Trigger.isInsert);
                OrderHelper.fillItinerarioLookup(Trigger.newMap);
            }
            when BEFORE_INSERT{
                OrderHelper.integrateNewOrder(Trigger.new);
                OrderHelper.changeOrderOwner(Trigger.new);
            }
            when BEFORE_UPDATE{
                OrderHelper.changeOrderOwner(Trigger.new);
            }
            when AFTER_UPDATE{
                OrderHelper.sendIntegratedOVsEmail(Trigger.oldMap, Trigger.newMap);
                OrderHelper.refreshOVSapCountFields(Trigger.oldMap, Trigger.newMap);
                OrderHelper.sendIntegrationEmailError(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE{
                OrderHelper.countOrdByOpp(Trigger.oldMap, Trigger.isInsert);
            }
        }
    } 
}