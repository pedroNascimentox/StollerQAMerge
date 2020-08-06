public with sharing class BatchProgramacaoEntregaTaxaMedia implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, ValorTotalUSD__c, ValorTotal__c, IdOportunidade__c, IdOportunidade__r.Moeda__c FROM ProgramacaoEntrega__c WHERE ' + 
                                        'Status__c = \'Liberado\' AND ' +
                                        'StatusSAP__c = \'Não Confirmado\' AND ' +
                                        'IdOportunidade__r.Moeda__c = \'BRL\'');
        
    }

    public void execute(Database.BatchableContext bc, List<ProgramacaoEntrega__c> programacoesEntrega) {

        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
        if (cotacoesMoeda.size() != 0) {
            for (ProgramacaoEntrega__c pe : programacoesEntrega) {
                if (pe.ValorTotal__c != null) {
                    pe.ValorTotalUSD__c = pe.ValorTotal__c / cotacoesMoeda[0].TaxaMedia__c;
                }
            }
            ProgramacaoEntregaHelper.disableTrigger();
            Database.update(programacoesEntrega);
            ProgramacaoEntregaHelper.enableTrigger();
        }

    }

    public void finish(Database.BatchableContext bc) {

        BatchGoalsUpdate.run();

    }

    public static void run(){

        Database.executeBatch(new BatchProgramacaoEntregaTaxaMedia(), 10000);

    }
}