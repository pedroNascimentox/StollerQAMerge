public class TerritorioHelper extends TriggerContext{ 
    
    public static void updateAccountSharingRules(Map<Id, Territorio__c> oldTerritories, Map<Id, Territorio__c> newTerritories){

        List<Territorio__c> territories = new List<Territorio__c>();
        
        for(Territorio__c territory : newTerritories.values()){
            if(territory.rtv__c != oldTerritories.get(territory.id).rtv__c){
                territories.add(territory);
            }
        }

        if(!territories.isEmpty()){

            Map<Id, Territorio__c> territoryMap = new Map<Id, Territorio__c>(territories);

            // update [SELECT id, territorio__c, territorio__r.rtv__c, conta__c FROM TerritorioCliente__c WHERE territorio__c IN :territoryMap.keySet()];

            List<TerritorioCliente__c> customerTerritories = [SELECT id, territorio__c, territorio__r.rtv__c, conta__c FROM TerritorioCliente__c WHERE territorio__c IN :territoryMap.keySet()];

            //delete routine
            Set<String> accountSharingsToDeleteKeys = new Set<String>();

            Collection customerTerritoriesCollection = Collection.of(customerTerritories);

            Map<Id, Id> territoryIdToRTVId = new Map<Id, Id>();
            Map<Id, Id> territoryIdToRTVIdOld = new Map<Id, Id>();

            for(Territorio__c territory : territories){
                territoryIdToRTVId.put(territory.id, territory.rtv__c);
                territoryIdToRTVIdOld.put(territory.id, oldTerritories.get(territory.id).rtv__c);
            }

            for(TerritorioCliente__c customerTerritory : customerTerritories){
                accountSharingsToDeleteKeys.add(customerTerritory.conta__c + '_' + territoryIdToRTVIdOld.get(customerTerritory.territorio__c));
            }

            List<AccountShare> accountSharingsToVerify = [SELECT id, userOrGroupId, accountId, rowCause FROM AccountShare WHERE accountId IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Conta__c) AND rowCause = 'Manual'];

            List<AccountShare> accountSharingsToDelete = new List<AccountShare>();

            for(AccountShare accShare : accountSharingsToVerify){
                if(accountSharingsToDeleteKeys.contains(accShare.accountId + '_' + accShare.userOrGroupId)){
                    accountSharingsToDelete.add(accShare);
                }
            }

            if(!accountSharingsToDelete.isEmpty()){
                delete accountSharingsToDelete;
            }

            //insert routine
            List<AccountShare> accSharingsToInsert = new List<AccountShare>();
            
            List<AccountShare> existentAccountSharings = [SELECT id, userOrGroupId, accountId, rowCause FROM AccountShare WHERE accountId IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Conta__c)];
            
            System.debug('existentAccountSharings =>  ' + existentAccountSharings);
            System.debug('territoryIdToRTVId => ' + territoryIdToRTVId);
            
            Map<Id, Set<Id>> accountIdToUsersAlreadyWithAccess = new Map<Id, Set<Id>>();
            
            for(AccountShare accShare : existentAccountSharings){
                if(!accountIdToUsersAlreadyWithAccess.containsKey(accShare.accountId)){
                    accountIdToUsersAlreadyWithAccess.put(accShare.accountId, new Set<Id>());
                }
                   
                accountIdToUsersAlreadyWithAccess.get(accShare.accountId).add(accShare.userOrGroupId);
            }
        
            for(TerritorioCliente__c customerTerritory : customerTerritories){
                if(!accountIdToUsersAlreadyWithAccess.get(customerTerritory.conta__c).contains(territoryIdToRTVId.get(customerTerritory.territorio__c))){
                    AccountShare accShare = new AccountShare(
                        accountAccessLevel = 'Read',
                        accountId = customerTerritory.conta__c,
                        opportunityAccessLevel = 'None',
                        userOrGroupId = territoryIdToRTVId.get(customerTerritory.territorio__c)
                    );
                    accSharingsToInsert.add(accShare);
                }
            }

            if(!accSharingsToInsert.isEmpty()){
                System.debug('accSharingsToInsert => ' + JSON.serializePretty(accSharingsToInsert));
                insert accSharingsToInsert;
            }
        
        }
    }
}