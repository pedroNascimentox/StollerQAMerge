@isTest
public with sharing class BatchIncentivePlanTest {
    @isTest
    public static void incentivePlanTest() {
        List<PlanoIncentivo__c> planIncentivoList = new List<PlanoIncentivo__c>();

        PlanoIncentivo__c planIncentivo = new PlanoIncentivo__c();
        planIncentivo.Name = 'Teste';
        planIncentivo.Status__c = 'Novo';
        planIncentivo.Atualizado__c = false;

        planIncentivoList.add(planIncentivo);
        
        insert planIncentivo;        

        BatchIncentivePlan.run();
    }

    @isTest
    public static void testSchedule() {

        Test.startTest();

        BatchIncentivePlanSchedulable schedule = new BatchIncentivePlanSchedulable();
        schedule.execute(null);

        Test.stopTest();

    }
}