trigger CotacaoMoeda on CotacaoMoeda__c (after insert, after update) {
    if (CotacaoMoedaHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_UPDATE, AFTER_INSERT {
                CotacaoMoedaHelper.updateAverageQuote(Trigger.new);
            }
        }
    } 
}