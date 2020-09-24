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

        
        System.debug('query: ' + 'SELECT Id, NomeCliente__c, Produto__c, CriterioPrecificacao__c, DataApuracao__c, PrecificacaoEscoamento__c ' + 
        'FROM Escoamento__c WHERE ' + 
        'DataApuracao__c <= ' + date.today());
        return Database.getQueryLocator('SELECT Id, NomeCliente__c, Produto__c, CriterioPrecificacao__c, DataApuracao__c, PrecificacaoEscoamento__c FROM Escoamento__c WHERE DataApuracao__c <= TODAY');
                                        // 'SELECT Id, CriterioPrecificacao__c, DataPrecificacao__c, DataApuracao__c ' + 
                                        // 'FROM Escoamento__c WHERE CriterioPrecificacao__c IN :criterioSet');
        
    }

    public void execute(Database.BatchableContext bc, List<Escoamento__c> escoamentoList) {
        Map<Id, Escoamento__c> escoamentoMap = new Map<Id, Escoamento__c>(escoamentoList);
        Set<String> criterioSet = criterioValorMap.keySet();
        Map<String, Date> criterioToSmallestDate = new Map<String, Date>();
        //Gets all Escoamento Records since 12 months ago. If there are NotaFiscalItems with the same criteria as Escoamento__c Record, sum the NotaItems values and divide by the quantity.
        
        for (Escoamento__c escoamento : escoamentoMap.values()) {
            if(criterioValorMap.containsKey(escoamento.CriterioPrecificacao__c)){
                String criterio = escoamento.CriterioPrecificacao__c;
                Date dataApuracao = escoamento.DataApuracao__c;
                if (!criterioToSmallestDate.containsKey(criterio)) {
                    criterioToSmallestDate.put(criterio, dataApuracao);
                } else if (criterioToSmallestDate.get(criterio) > dataApuracao) {
                    criterioToSmallestDate.put(criterio, dataApuracao);
                }
            }
        }
        //If there is no NotaFiscalItems criteria for that Escoamento__c record, add the record to escoamentoWithoutNota list
        List<Escoamento__c> escoamentoWithoutNota = new List<Escoamento__c>();

        for (Escoamento__c escoamento : escoamentoMap.values()) {
            if(criterioValorMap.containsKey(escoamento.CriterioPrecificacao__c)){
                String criterio = escoamento.CriterioPrecificacao__c;

                escoamento.PrecificacaoEscoamento__c = criterioValorMap.get(criterio) / criterioQuantidadeMap.get(criterio);
                escoamento.DataPrecificacao__c = criterioToSmallestDate.get(criterio);
            }
            else{
                escoamentoWithoutNota.add(escoamento);
            }
        }

        //If there's Escoamento__c without NotaFiscalItems, querys for TabelaPreco__c
        if(escoamentoWithoutNota.size() > 0){
            List<Id> clientList = Collection.of(escoamentoWithoutNota).pluckIds(Escoamento__c.NomeCliente__c);
            List<Id> productList = Collection.of(escoamentoWithoutNota).pluckIds(Escoamento__c.Produto__c);
            List<TabelaPreco__c> tabelaPrecoList = new List<TabelaPreco__c>([   SELECT Id,
                                                                                Produto__c,
                                                                                Cliente__c,
                                                                                Valor__c
                                                                            FROM TabelaPreco__c
                                                                            WHERE Cliente__c IN :clientList
                                                                            AND Produto__c IN :productList]);

            //Verifies if there is TabelaPreco with same Product and Account as Escoamento__c records without NotaFiscalItems or with same Regional__c and Product
            //If there is not, uses the last purchase value from Client Account
            for(Escoamento__c escoamento : escoamentoWithoutNota){
                for(TabelaPreco__c tabelaPreco : tabelaPrecoList){
                    if((escoamento.Produto__c == tabelaPreco.Produto__c && escoamento.NomeCliente__c == tabelaPreco.Cliente__c) 
                            || (escoamento.Territorio__r.Regional__c == tabelaPreco.Regional__c && escoamento.Produto__c == tabelaPreco.Produto__c)){
                        escoamento.PrecificacaoEscoamento__c = tabelaPreco.Valor__c;
                    }else{
                        escoamento.PrecificacaoEscoamento__c = escoamento.NomeCliente__r.ValorUltimaCompra__c;
                    }
                }
            }

            //Iterates over Map and list to prepare for update
            for(Escoamento__c escoamentoL : escoamentoWithoutNota){
                for(Escoamento__c escoamentoM : escoamentoMap.values()){
                    if(escoamentoL.Id == escoamentoM.Id){
                        escoamentoM.PrecificacaoEscoamento__c = escoamentoL.PrecificacaoEscoamento__c;
                        escoamentoM.DataPrecificacao__c = date.today();
                    }
                }
            }
        }

        EscoamentoHelper.disableTrigger();
        update escoamentoMap.values();
        EscoamentoHelper.enableTrigger();
    }

    public void finish(Database.BatchableContext bc) {
    }
}