public with sharing class BatchEscoamentoTaxaMediaDay implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, DataApuracao__c FROM Escoamento__c WHERE ' + 
                                        'CALENDAR_MONTH(DataApuracao__c) = ' + Date.today().month());
        
    }

    public void execute(Database.BatchableContext bc, List<Escoamento__c> escoamentos) {

        if (Date.today().day() != 1) {
            CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c, Data__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
            if (cotacoesMoeda.size() != 0) {
                for (Escoamento__c escoamento : escoamentos) {
                    if (escoamento.DataApuracao__c.month() == cotacoesMoeda[0].Data__c.month()) {
                        escoamento.ValorBrutoDolar__c = cotacoesMoeda[0].TaxaMedia__c;
                    }
                }
                EscoamentoHelper.disableTrigger();
                Database.update(escoamentos);
                EscoamentoHelper.enableTrigger();
            }
        }

    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {

        Database.executeBatch(new BatchEscoamentoTaxaMediaDay(), 10000);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        return System.schedule('Update Escoamento Taxa Média Daily', '0 0 0 * * ? *', new BatchEscoamentoTaxaMediaDay());

    }
}