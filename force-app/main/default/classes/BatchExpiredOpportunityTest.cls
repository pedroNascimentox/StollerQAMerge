@isTest
public with sharing class BatchExpiredOpportunityTest {

    @TestSetup
    static void setup() {
        
        Opportunity expiredOpportunity = (Opportunity)TestFactory.createSObject(new Opportunity());
        expiredOpportunity.DataValidade__c = Date.today() - 1;
        insert expiredOpportunity;

        List<Opportunity> opportunityList = new List<Opportunity>();
        for (Integer i = 0; i < 100; i++) {
            Opportunity opp = (Opportunity)TestFactory.createSObject(new Opportunity());
            opp.DataValidade__c = Date.today();
            opportunityList.add(opp);
        }
        insert opportunityList;

    }

    @isTest
    public static void testBatchExpiredOpportunity() {

        Test.startTest();
        BatchExpiredOpportunity batch = new BatchExpiredOpportunity();
        batch.execute(null, Database.query(batch.start(null).getQuery()));
        batch.finish(null);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE StageName = 'Cancelado']);
        System.assertEquals(100, [SELECT COUNT() FROM Opportunity WHERE StageName = 'Iniciado']);

    }

    @isTest
    public static void testSchedule() {

        Test.startTest();
        
        List<CronTrigger> schedule = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                        FROM CronTrigger 
                                       WHERE CronJobDetail.Name = 'Expired Opportunity Canceling'];
        
        String jobId;
        if (schedule.size() == 0){
            jobId = BatchExpiredOpportunity.setSchedule();
        } else {
            System.abortJob(schedule[0].Id);
            jobId = BatchExpiredOpportunity.setSchedule();
        }
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                            FROM CronTrigger 
                           WHERE Id = :jobId];

        Test.stopTest();

        System.assertEquals('0 0 0 * * ? *', ct.CronExpression);
        System.assertEquals(Datetime.now().addDays(1).day(), ct.NextFireTime.day());
    }
}