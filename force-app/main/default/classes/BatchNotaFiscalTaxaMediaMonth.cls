public with sharing class BatchNotaFiscalTaxaMediaMonth implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, ValorTotalUSD__c, ValorTotalItem__c, NotaFiscal__c, NotaFiscal__r.DataNF__c, NotaFiscal__r.ValorTotalNota__c FROM NotaFiscalItem__c WHERE ' + 
                                        'CALENDAR_MONTH(NotaFiscal__r.DataNF__c) = ' + (Date.today().month() - 1));
        
    }

    public void execute(Database.BatchableContext bc, List<NotaFiscalItem__c> notasFiscais) {

        Integer month = (Date.today().addMonths(-1)).month();
        Map<Id, NotaFiscal__c> updtNotaMap = new Map<Id, NotaFiscal__c>();

        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c, Data__c FROM CotacaoMoeda__c WHERE CALENDAR_MONTH(Data__c) = :month ORDER BY Data__c DESC LIMIT 1];
        if (cotacoesMoeda.size() != 0) {
            for (NotaFiscalItem__c nf : notasFiscais) {
               // updtNotaMap.put(nf.NotaFiscal__C, new NotaFiscal__C(Id = nf.NotaFiscal__c, ValorTotalUSD__c = nf.NotaFiscal__r.ValorTotalNota__c / cotacoesMoeda[0].TaxaMedia__c));
                
                nf.ValorTotalUSD__c = nf.ValorTotalItem__c / cotacoesMoeda[0].TaxaMedia__c;
            }
            Database.update(notasFiscais, false);
        }

    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {

        Database.executeBatch(new BatchNotaFiscalTaxaMediaMonth(), 10000);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        return System.schedule('Update Nota Fiscal Taxa Média Monthly', '0 0 0 1 * ? *', new BatchNotaFiscalTaxaMediaMonth());

    }
}