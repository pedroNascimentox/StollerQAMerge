trigger NotaFiscal on NotaFiscal__c (after insert, after update, before insert, before update) {
    if (NotaFiscalHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                NotaFiscalHelper.updatePlanoIncentivo(Trigger.new);
                NotaFiscalHelper.fillOpportunityLookup(Trigger.new);
                NotaFiscalHelper.changeNotaFiscalOwner(Trigger.new);
            }
            when BEFORE_INSERT {
                NotaFiscalHelper.addTaxToNotaFiscal(Trigger.new);
                NotaFiscalHelper.fillOpportunityLookup(Trigger.new);
                NotaFiscalHelper.changeNotaFiscalOwner(Trigger.new);
            }
            when AFTER_INSERT {
                NotaFiscalHelper.addDateToFields(Trigger.newMap);
            }
            when AFTER_UPDATE {
                NotaFiscalHelper.updateCliPlanoIncentivo(Trigger.newMap, Trigger.oldMap);
                NotaFiscalHelper.withdrawBalance(Trigger.newMap, Trigger.oldMap);
            }
        }
    } 
}