trigger AlteracaoDataEntregaItem on AlteracaoDataEntregaItem__c (after insert) {
    if (AlteracaoDataEntregaItemHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                AlteracaoDataEntregaItemHelper.markOrderItemsAsBlocked(Trigger.newMap);
            }
        }
    } 
}