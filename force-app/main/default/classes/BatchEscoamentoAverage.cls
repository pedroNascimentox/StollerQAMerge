public with sharing class BatchEscoamentoAverage implements Database.Batchable<SObject>, Database.StateFul {

    public Map<String, Decimal> criterioValorMap;
    public Map<String, Decimal> criterioQuantidadeMap;

    public BatchEscoamentoAverage(Map<String, Decimal> oldCriterioValorMap, Map<String, Decimal> oldCriterioQuantidadeMap) {

        criterioValorMap = new Map<String, Decimal>(oldCriterioValorMap);
        criterioQuantidadeMap = new Map<String, Decimal>(oldCriterioQuantidadeMap);

    }

    public void run() { // this method must be called only by BatchEscoamentoPricing finish method
        
        Database.executeBatch(new BatchEscoamentoAverage(criterioValorMap, criterioQuantidadeMap), 1000);

    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Set<String> criterioSet = criterioValorMap.keySet();

        return Database.getQueryLocator('SELECT Id, CriterioPrecificacao__c, DataPrecificacao__c, DataApuracao__c ' + 
                                        'FROM Escoamento__c WHERE CriterioPrecificacao__c IN :criterioSet');
                                        // '(SELECT Id ' + 
                                        // 'FROM Escoamento__c WHERE ' + 
                                        // 'CALENDAR_MONTH(Escoamento__c.DataApuracao__c) >= ' + (Date.today().addMonths(-12).month()) + ')');
        
    }

    public void execute(Database.BatchableContext bc, List<Escoamento__c> escoamentoList) {

        Map<String, Date> criterioToSmallestDate = new Map<String, Date>();

        for (Escoamento__c escoamento : escoamentoList) {

            String criterio = escoamento.CriterioPrecificacao__c;
            Date dataApuracao = escoamento.DataApuracao__c;

            if (!criterioToSmallestDate.containsKey(criterio)) {
                criterioToSmallestDate.put(criterio, dataApuracao);
            } else if (criterioToSmallestDate.get(criterio) > dataApuracao) {
                criterioToSmallestDate.put(criterio, dataApuracao);
            }

        }

        for (Escoamento__c escoamento : escoamentoList) {

            String criterio = escoamento.CriterioPrecificacao__c;

            escoamento.PrecificacaoEscoamento__c = criterioValorMap.get(criterio) / criterioQuantidadeMap.get(criterio);
            escoamento.DataPrecificacao__c = criterioToSmallestDate.get(criterio);

        }

        EscoamentoHelper.disableTrigger();
        update escoamentoList;
        EscoamentoHelper.enableTrigger();
    }

    public void finish(Database.BatchableContext bc) {
    }
}