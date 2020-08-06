public with sharing class BatchExpiredOpportunity implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        String opportunityStageNames = [SELECT StageName__c FROM OpportunityStageName__mdt WHERE DeveloperName = 'StandardOptions'].StageName__c;

        List<String> stageNameOptionsList = new List<String>(opportunityStageNames.split(';'));
        String stageNameOptions = '(\'' + String.join(stageNameOptionsList, '\',\'') + '\')';
        // System.debug('stageNameOptions => ' + stageNameOptions);

        String query = 'SELECT Id, StageName FROM Opportunity WHERE DataValidade__c < ' + String.valueOf(Date.today()) + ' AND StageName IN ';

        try {

            return Database.getQueryLocator(query + stageNameOptions);

        } catch (Exception e) {

            stageNameOptions = '(\'Iniciado\',\'Reprovado Marketing\',\'Reprovado Comercial\',\'Reprovado Cliente\')';

            return Database.getQueryLocator(query + stageNameOptions);

        }
        
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities) {
        
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Cancelado';
            opp.DontChangeStageName__c = true;
        }
        OpportunityHelper.disableTrigger();
        Database.update(opportunities);
        OpportunityHelper.enableTrigger();

    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {

        Database.executeBatch(new BatchExpiredOpportunity(), 10000);
        
    }

    public void execute(SchedulableContext ctx) {

        run();

    }

    public static Id setSchedule() {

        return System.schedule('Expired Opportunity Canceling', '0 0 0 * * ? *', new BatchExpiredOpportunity());

    }    
}