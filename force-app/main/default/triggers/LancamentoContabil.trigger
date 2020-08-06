trigger LancamentoContabil on LancamentoContabil__c (after insert, after update, after delete) {
    if (LancamentoContabilHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                LancamentoContabilHelper.updateApuracaoRelation(Trigger.newMap);
            }
            when AFTER_UPDATE {
                LancamentoContabilHelper.updateApuracaoRelation(Trigger.newMap);
            }
        }
    } 
}