trigger AlteracaoDataEntrega on AlteracaoDataEntrega__c (before update) {
    if (AlteracaoDataEntregaHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                AlteracaoDataEntregaHelper.markOrderItemsAsBlocked(Trigger.newMap, Trigger.oldMap);
                AlteracaoDataEntregaHelper.cancelRelatedDeliveryItems(Trigger.oldMap, Trigger.newMap);
            }
        }
    } 
}