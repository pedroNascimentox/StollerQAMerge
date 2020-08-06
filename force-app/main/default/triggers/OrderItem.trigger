trigger OrderItem on OrderItem (before insert, before update, after update, after insert) {
    if (OrderItemHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_UPDATE {
                OrderItemHelper.sendEmailCreditBlock(Trigger.newMap, Trigger.oldMap);
                OrderItemHelper.updatePlanoIncentivo(Trigger.new);
                OrderItemHelper.updateDeliveryRecord(Trigger.oldMap, Trigger.newMap);
                // OrderItemHelper.insertNewDeliveryRecords(Trigger.oldMap, Trigger.newMap);
            }
            when AFTER_UPDATE{
                OrderItemHelper.changeNumSche(Trigger.newMap, Trigger.oldMap, Trigger.isInsert);
                // OrderItemHelper.sendCancelling(Trigger.newMap, Trigger.oldMap);
                OrderItemHelper.updateApWallet(Trigger.newMap, Trigger.oldMap);
                OrderItemHelper.updtIntegrationCheck(Trigger.newMap);
                OrderItemHelper.updateUSDValues(Trigger.new, Trigger.oldMap);
            }
            when AFTER_INSERT{
                OrderItemHelper.changeNumSche(Trigger.newMap, Trigger.oldMap, Trigger.isInsert);
                OrderItemHelper.updateUSDValues(Trigger.new);
            }
        }
    } 
}