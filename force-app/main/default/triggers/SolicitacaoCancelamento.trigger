trigger SolicitacaoCancelamento on SolicitacaoCancelamento__c (before insert, before update, after update) {
    if (CancelamentoHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                System.debug(Trigger.newMap);
                System.debug(Trigger.oldMap);
                //SolicitacaoCancelamentoHelper.sendApprovalProcess(Trigger.oldMap, Trigger.newMap);
                SolicitacaoCancelamentoHelper.markOrderItemsAsBlocked(Trigger.newMap, Trigger.oldMap);
            }  
             when BEFORE_INSERT {
                System.debug(Trigger.newMap);
                System.debug(Trigger.oldMap);
                SolicitacaoCancelamentoHelper.setTaxe(Trigger.new);
            }  
            when AFTER_UPDATE {
                SolicitacaoCancelamentoHelper.sendApprovalProcess(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}