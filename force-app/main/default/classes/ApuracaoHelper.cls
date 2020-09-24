public class ApuracaoHelper extends TriggerContext {

    public static void changeApuracaoOwner(List<Apuracao__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Apuracao__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(Apuracao__c counting : newRecordsList){
            if(counting.territorio__c != null && territories.containsKey(counting.territorio__c) && counting.ownerId != territories.get(counting.territorio__c).rtv__c){
                counting.ownerId = territories.get(counting.territorio__c).rtv__c;
            }
        }
    }
    public static void changeTipoApuracao(List<Apuracao__c> recordList){
        for(apuracao__c apu: recordList){
            if(apu.tipoApuracao1__c != 'Escoamento'){
                apu.tipoApuracao1__c = 'Faturamento';
            }
        }
    }
}