public class BatchEscoamentoPricing implements Database.Batchable<SObject>, Schedulable, Database.StateFul {

    public Map<String, Decimal> criterioValorMap;
    public Map<String, Decimal> criterioQuantidadeMap;

    public Database.QueryLocator start(Database.BatchableContext bc) {

        criterioValorMap = new Map<String, Decimal>();
        criterioQuantidadeMap = new Map<String, Decimal>();

        return Database.getQueryLocator('SELECT Id, ValorTotalItem__c, CriterioPrecificacao__c, Escoamento__c, NotaFiscal__c, NotaFiscal__r.DataNF__c ' + 
                                        'FROM NotaFiscalItem__c WHERE NotaFiscal__r.DataNF__c >= ' + String.valueOf(Date.today().addMonths(-12)));
                                        // '(SELECT Id ' + 
                                        // 'FROM Escoamento__c WHERE ' + 
                                        // 'CALENDAR_MONTH(Escoamento__c.DataApuracao__c) >= ' + (Date.today().addMonths(-12).month()) + ')');
        
    }

    public void execute(Database.BatchableContext bc, List<NotaFiscalItem__c> notaFiscalItens) {

        Map<String, List<NotaFiscalItem__c>> criterioKeyToNotaItemList = new Map<String, List<NotaFiscalItem__c>>();
        for (NotaFiscalItem__c notaFiscalItem : notaFiscalItens) {
            if (!criterioKeyToNotaItemList.containsKey(notaFiscalItem.CriterioPrecificacao__c)) {
                criterioKeyToNotaItemList.put(notaFiscalItem.CriterioPrecificacao__c, new List<NotaFiscalItem__c>());
            }
            criterioKeyToNotaItemList.get(notaFiscalItem.CriterioPrecificacao__c).add(notaFiscalItem);
        }

        List<Escoamento__c> escoamentoList = [SELECT Id, CriterioPrecificacao__c 
                                FROM Escoamento__c WHERE CriterioPrecificacao__c IN :criterioKeyToNotaItemList.keySet()];

        for (Escoamento__c escoamento : escoamentoList) {

            Decimal itemSum = 0;
            List<NotaFiscalItem__c> itemList = criterioKeyToNotaItemList.get(escoamento.CriterioPrecificacao__c);

            for (NotaFiscalItem__c item : itemList) {
                itemSum += item.ValorTotalItem__c;
            }

            if(!criterioValorMap.containsKey(escoamento.CriterioPrecificacao__c)){
                criterioValorMap.put(escoamento.CriterioPrecificacao__c, 0);
                criterioQuantidadeMap.put(escoamento.CriterioPrecificacao__c, 0);
            }

            Decimal oldValue = criterioValorMap.get(escoamento.CriterioPrecificacao__c);
            Decimal oldQtd = criterioQuantidadeMap.get(escoamento.CriterioPrecificacao__c);

            criterioValorMap.put(escoamento.CriterioPrecificacao__c, oldValue + itemSum);
            criterioQuantidadeMap.put(escoamento.CriterioPrecificacao__c, oldQtd + itemList.size());
            
        }
    }

    public void finish(Database.BatchableContext bc) {

        BatchEscoamentoAverage batch = new BatchEscoamentoAverage(criterioValorMap, criterioQuantidadeMap);
        batch.run();

    }

    public static void run() {
        
        Database.executeBatch(new BatchEscoamentoPricing(), 500);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    // public static Id setSchedule() {

    //     return System.schedule('Update Escoamento Pricing', '0 0 0 * * ? *', new BatchEscoamentoPricing());

    // }
}