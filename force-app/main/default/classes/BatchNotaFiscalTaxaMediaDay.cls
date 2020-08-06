public with sharing class BatchNotaFiscalTaxaMediaDay implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 

        return Database.getQueryLocator('SELECT Id, ValorTotalUSD__c, ValorTotalItem__c, NotaFiscal__c, NotaFiscal__r.DataNF__c FROM NotaFiscalItem__c WHERE ' + 
                                        'CALENDAR_MONTH(NotaFiscal__r.DataNF__c) = ' + Date.today().month());
        
    }

    public void execute(Database.BatchableContext bc, List<NotaFiscalItem__c> notasFiscais) {

        if (Date.today().day() != 1) {
            CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, Taxa__c, TaxaMedia__c, Data__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
            if (cotacoesMoeda.size() != 0) {
                for (NotaFiscalItem__c nf : notasFiscais) {
                    if (nf.ValorTotalItem__c != null && nf.NotaFiscal__r.DataNF__c.month() == cotacoesMoeda[0].Data__c.month()) {
                        nf.ValorTotalUSD__c = nf.ValorTotalItem__c / cotacoesMoeda[0].TaxaMedia__c;
                    }
                }
                Database.update(notasFiscais, false);
            }
        }

    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {

        Database.executeBatch(new BatchNotaFiscalTaxaMediaDay(), 10000);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        return System.schedule('Update Nota Fiscal Taxa Média Daily', '0 0 0 * * ? *', new BatchNotaFiscalTaxaMediaDay());

    }
}