trigger AssociacaoPedidoReclamacao on AssociacaoPedidoReclamacao__c (before insert, before update) {
    if (AssociacaoPedidoReclamacaoHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                AssociacaoPedidoReclamacaoHelper.fillApprovers(Trigger.new);
            }
            when BEFORE_INSERT {
                AssociacaoPedidoReclamacaoHelper.fillApprovers(Trigger.new);
            }
        }
    }
}