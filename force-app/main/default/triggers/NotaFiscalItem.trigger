trigger NotaFiscalItem on NotaFiscalItem__c (before insert, after insert, after update, before delete) {
    if (NotaFiscalItemHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                NotaFiscalItemHelper.setSaldoLitrosEscoamento(Trigger.new);
            }
            when AFTER_INSERT {
                NotaFiscalItemHelper.updateApuracaoRelation(Trigger.newMap);
                NotaFiscalItemHelper.setValorTotalOnUpsert(Trigger.new);
                NotaFiscalItemHelper.calculateBalance(Trigger.newMap);
            }
            when AFTER_UPDATE {
                NotaFiscalItemHelper.updateApuracaoRelation(Trigger.newMap);
                NotaFiscalItemHelper.setValorTotalOnUpsert(Trigger.new);
                NotaFiscalItemHelper.updateApWallet(Trigger.newMap, Trigger.oldMap);
                // NotaFiscalItemHelper.calculateBalance(Trigger.newMap);
            }
            when BEFORE_DELETE {
                NotaFiscalItemHelper.setValorTotalOnDelete(Trigger.old);
                NotaFiscalItemHelper.withdrawBalance(Trigger.oldMap);
            }
        }
    } 
}