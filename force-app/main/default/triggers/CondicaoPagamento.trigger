trigger CondicaoPagamento on CondicaoPagamento__c (before insert, before update) {
    if (CondicaoPagamentoHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT, BEFORE_UPDATE {
                CondicaoPagamentoHelper.setType(Trigger.new);
            }
        }
    }
}