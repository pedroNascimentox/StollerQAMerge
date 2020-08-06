public with sharing class BatchEscoamentoTaxaMediaMonth implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, DataApuracao__c FROM Escoamento__c WHERE ' + 
                                        'CALENDAR_MONTH(DataApuracao__c) = ' + (Date.today().month() - 1));
        
    }

    public void execute(Database.BatchableContext bc, List<Escoamento__c> escoamentos) {

        Integer month = (Date.today().addMonths(-1)).month();

        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c, Data__c FROM CotacaoMoeda__c WHERE CALENDAR_MONTH(Data__c) = :month ORDER BY Data__c DESC LIMIT 1];
        if (cotacoesMoeda.size() != 0) {
            for (Escoamento__c escoamento : escoamentos) {
                escoamento.ValorBrutoDolar__c = cotacoesMoeda[0].TaxaMedia__c;
            }
            EscoamentoHelper.disableTrigger();
            Database.update(escoamentos);
            EscoamentoHelper.enableTrigger();
        }

    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {

        Database.executeBatch(new BatchEscoamentoTaxaMediaMonth(), 10000);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        return System.schedule('Update Escoamento Taxa Média Monthly', '0 0 0 1 * ? *', new BatchEscoamentoTaxaMediaMonth());

    }
}