public class TerritorioClienteHelper extends TriggerContext {
    public static void updateTerritoriosConcatenadosField(List<TerritorioCliente__c> territoriosCliente, TriggerOperation type) {

        Collection auxTerritoriosClienteCollection = Collection.of(territoriosCliente);
        Set<Id> accountIdsToQuery = new Set<Id>(auxTerritoriosClienteCollection.pluckIds(TerritorioCliente__c.Conta__c));

        Map<Id, Account> localAccountMap = new Map<Id, Account>([SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id IN :accountIdsToQuery]);

        List<TerritorioCliente__c> localTerritoriosCliente;

        switch on type {
            when BEFORE_DELETE {
                Set<Id> idsToIgnore = new Set<Id>(auxTerritoriosClienteCollection.pluckIds(TerritorioCliente__c.Id));
                localTerritoriosCliente = [SELECT Id, Territorio__c, Conta__c FROM TerritorioCliente__c WHERE Conta__c IN :accountIdsToQuery AND id NOT IN :idsToIgnore];
            }
            when else {
                localTerritoriosCliente = [SELECT Id, Territorio__c, Conta__c FROM TerritorioCliente__c WHERE Conta__c IN :accountIdsToQuery];
                localTerritoriosCliente.addAll(territoriosCliente);
            }
        }

        Collection localTerritoriosClienteCollection = Collection.of(localTerritoriosCliente);
        
        Set<Id> territorioIds = new Set<Id>(localTerritoriosClienteCollection.pluckIds(TerritorioCliente__c.Territorio__c));

        Map<String, String> territorioIdToExternalId = new Map<String, String>();
        for (Territorio__c territorio : [SELECT Id, ExternalId__c FROM Territorio__c WHERE Id IN :territorioIds]) {
            territorioIdToExternalId.put(territorio.Id, territorio.ExternalId__c);
        }
        
        Set<Id> accountIds = new Set<Id>(localTerritoriosClienteCollection.pluckIds(TerritorioCliente__c.Conta__c));
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id IN :accountIds]);

        Map<Id, List<TerritorioCliente__c>> accountIdToTerritorioListMap = localTerritoriosClienteCollection.groupByIds(TerritorioCliente__c.Conta__c);

        for (Id key : localAccountMap.keySet()) {

            if (!accountMap.containsKey(key)) {
                localAccountMap.get(key).TerritoriosConcatenados__c = '';
            } else {

                List<String> territorioExternalIds = new List<String>();
                if (accountIdToTerritorioListMap.containsKey(localAccountMap.get(key).id)){
                    for (TerritorioCliente__c tc : accountIdToTerritorioListMap.get(localAccountMap.get(key).Id)) {
                        territorioExternalIds.add(territorioIdToExternalId.get(tc.Territorio__c));
                    }
                }

                localAccountMap.get(key).TerritoriosConcatenados__c = String.join(territorioExternalIds, ';');
            }
        }
        update localAccountMap.values();
    }

    public static void deleteAccountSharingRules(List<TerritorioCliente__c> customerTerritories){

        Set<String> undeletableRowCauses        = new Set<String>{'ImplicitParent', 'Owner'};

        Set<String> accountSharingsToDeleteKeys = new Set<String>();

        Collection customerTerritoriesCollection = Collection.of(customerTerritories);

        List<Territorio__c> territories = [SELECT id, rtv__c FROM Territorio__c WHERE id IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Territorio__c)];

        Map<Id, Id> territoryIdToRTVId = new Map<Id, Id>();

        for(Territorio__c territory : territories){
            territoryIdToRTVId.put(territory.id, territory.rtv__c);
        }

        for(TerritorioCliente__c customerTerritory : customerTerritories){
            accountSharingsToDeleteKeys.add(customerTerritory.conta__c + '_' + territoryIdToRTVId.get(customerTerritory.territorio__c));
        }

        List<AccountShare> accountSharingsToVerify = [SELECT id, userOrGroupId, accountId FROM AccountShare WHERE accountId IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Conta__c) AND rowCause NOT IN :undeletableRowCauses];

        List<AccountShare> accountSharingsToDelete = new List<AccountShare>();

        for(AccountShare accShare : accountSharingsToVerify){
            if(accountSharingsToDeleteKeys.contains(accShare.accountId + '_' + accShare.userOrGroupId)){
                accountSharingsToDelete.add(accShare);
            }
        }

        if(!accountSharingsToDelete.isEmpty() && !Test.isRunningTest()){
            delete accountSharingsToDelete;
        }

    }

    public static void insertAccountSharingRules(List<TerritorioCliente__c> customerTerritories){

        Collection customerTerritoriesCollection = Collection.of(customerTerritories);

        List<Territorio__c> territories = [SELECT id, rtv__c FROM Territorio__c WHERE id IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Territorio__c)];

        Map<Id, Id> territoryIdToRTVId = new Map<Id, Id>();

        if(!territories.isEmpty()){

            for(Territorio__c territory : territories){
                territoryIdToRTVId.put(territory.id, territory.rtv__c);
            }

            List<AccountShare> accSharingsToInsert = new List<AccountShare>();

            List<AccountShare> existentAccountSharings = [SELECT id, userOrGroupId, accountId FROM AccountShare WHERE accountId IN :customerTerritoriesCollection.pluckIds(TerritorioCliente__c.Conta__c)];

            Set<String> accShareKeys = new Set<String>();

            for(AccountShare accShare : existentAccountSharings){
                accShareKeys.add(accShare.accountId + '_' + accShare.UserOrGroupId);
            }
            
            for(TerritorioCliente__c customerTerritory : customerTerritories){
                if(!accShareKeys.contains(customerTerritory.conta__c + '_' + territoryIdToRTVId.get(customerTerritory.territorio__c))){
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
                insert accSharingsToInsert;
            }
            
        }
    }

    public static void updateAccountSharingRules(Map<Id, TerritorioCliente__c> oldCustomerTerritories, Map<Id, TerritorioCliente__c> newCustomerTerritories){

        List<TerritorioCliente__c> customerTerritories = new List<TerritorioCliente__c>();
        List<TerritorioCliente__c> customerTerritoriesToDeleteAccountShare = new List<TerritorioCliente__c>();
        
        for(TerritorioCliente__c customerTerritory : newCustomerTerritories.values()){
            customerTerritories.add(customerTerritory);
            customerTerritoriesToDeleteAccountShare.add(oldCustomerTerritories.get(customerTerritory.id));
        }

        if(!customerTerritories.isEmpty()){
            deleteAccountSharingRules(customerTerritoriesToDeleteAccountShare);
            insertAccountSharingRules(customerTerritories);
        }

    }

}