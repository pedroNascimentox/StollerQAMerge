trigger Cancelamento on Cancelamento__c (after insert, before update, before insert) {
    if (CancelamentoHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                // CancelamentoHelper.callApprovalProcess(Trigger.new);
                CancelamentoHelper.updateRelatedDeliveryItems(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_UPDATE {
                CancelamentoHelper.updateRelatedDeliveryItems(Trigger.oldMap, Trigger.newMap);
            }   
            when BEFORE_INSERT{
                CancelamentoHelper.groupItems(Trigger.new);
            }
        }
    } 
}