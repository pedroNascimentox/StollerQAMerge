public without sharing class CampanhaHelper  extends TriggerContext {
    public static void changeRecordType(List<Campanha__c> context){
        for(Campanha__c campaign : context){
            if(campaign.LiberadoUsoOportunidades__c){
                campaign.RecordTypeId = Schema.SObjectType.Campanha__c.getRecordTypeInfosByDeveloperName().get('ReadOnly').getRecordTypeId();
            }
        }
    }
}