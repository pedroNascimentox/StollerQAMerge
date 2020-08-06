public class ReviewHelper extends TriggerContext {

    public static void changeDepoimentoOwner(List<Depoimento__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Depoimento__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(Depoimento__c review : newRecordsList){
            if(review.territorio__c != null && territories.containsKey(review.territorio__c) && review.ownerId != territories.get(review.territorio__c).rtv__c){
                review.ownerId = territories.get(review.territorio__c).rtv__c;
            }
        }
    }

}