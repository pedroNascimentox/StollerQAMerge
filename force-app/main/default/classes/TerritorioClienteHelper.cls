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

    public static void managerialTerritoryChange(Map<Id, TerritorioCliente__c> newCustomerTerritories){

        Map<String,Id> mapCustomerTerritory = new Map<String,Id>();
        Set<Id> territoriesIds = new Set<Id>();

        List<NotaFiscal__c> updateNotaFiscal = new List<NotaFiscal__c>();
        List<Escoamento__c> updateEscoamento = new List<Escoamento__c>();
        List<HistoricoNota__c> updateHistoricoNota = new List<HistoricoNota__c>();

        for(TerritorioCliente__c customerTerritory : newCustomerTerritories.values()){
            mapCustomerTerritory.put(customerTerritory.territorio__c + '-' + customerTerritory.conta__c, customerTerritory.TerritorioGerencial__c);
            territoriesIds.add(customerTerritory.territorio__c);
        }

        for(NotaFiscal__c nota : [SELECT Id, Territorio__c, TerritorioGerencial__c, CodigoCliente__c FROM NotaFiscal__c WHERE Territorio__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(nota.territorio__c + '-' + nota.CodigoCliente__c)){
                nota.TerritorioGerencial__c =  mapCustomerTerritory.get(nota.territorio__c + '-' + nota.CodigoCliente__c);
                updateNotaFiscal.add(nota);
            }
        }

        for(Escoamento__c escoamento : [SELECT Id, Territorio__c, TerritorioGerencial__c, NomeCliente__c FROM Escoamento__c WHERE Territorio__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(escoamento.Territorio__c + '-' + escoamento.NomeCliente__c)){
                escoamento.TerritorioGerencial__c =  mapCustomerTerritory.get(escoamento.Territorio__c + '-' + escoamento.NomeCliente__c);
                updateEscoamento.add(escoamento);
            }
        }

        for(HistoricoNota__c historicoNota : [SELECT Id, IdTerritorioSF__c, TerritorioGerencial__c, IdContaSF__c FROM HistoricoNota__c WHERE IdTerritorioSF__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(historicoNota.IdTerritorioSF__c + '-' + historicoNota.IdContaSF__c)){
                historicoNota.TerritorioGerencial__c =  mapCustomerTerritory.get(historicoNota.IdTerritorioSF__c + '-' + historicoNota.IdContaSF__c);
                updateHistoricoNota.add(historicoNota);
            }
        }

        System.debug('updateNotaFiscal ' + updateNotaFiscal);
        System.debug('updateEscoamento  ' + updateEscoamento);

        if(!updateNotaFiscal.isEmpty()){
            update updateNotaFiscal;
        }

        if(!updateEscoamento.isEmpty()){
            update updateEscoamento;
        }

        if(!updateHistoricoNota.isEmpty()){
            update updateHistoricoNota;
        }
    } 

    public static void managerialTerritoryChange(Map<Id, TerritorioCliente__c> oldCustomerTerritories, Map<Id, TerritorioCliente__c> newCustomerTerritories){

        Map<Id,NotaFiscal__c> updateNotaFiscal = new Map<Id,NotaFiscal__c>();
        List<Escoamento__c> updateEscoamento = new List<Escoamento__c>();
        List<HistoricoNota__c> updateHistoricoNota = new List<HistoricoNota__c>();
     
        Map<String,Id> mapCustomerTerritory = new Map<String,Id>();
        Set<Id> territoriesIds = new Set<Id>();
        Set<Id> notasIds = new Set<Id>();

        for(TerritorioCliente__c customerTerritory : newCustomerTerritories.values()){
            if(customerTerritory.TerritorioGerencial__c != oldCustomerTerritories.get(customerTerritory.id).TerritorioGerencial__c){
                mapCustomerTerritory.put(customerTerritory.territorio__c + '-' + customerTerritory.conta__c, customerTerritory.TerritorioGerencial__c);
                territoriesIds.add(customerTerritory.territorio__c);
            }
        }

        
        for(NotaFiscal__c nota : [SELECT Id, Territorio__c, TerritorioGerencial__c, CodigoCliente__c FROM NotaFiscal__c WHERE Territorio__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(nota.territorio__c + '-' + nota.CodigoCliente__c)){
                nota.TerritorioGerencial__c =  mapCustomerTerritory.get(nota.territorio__c + '-' + nota.CodigoCliente__c);
                updateNotaFiscal.put(nota.Id,nota);
            }
        }

        for(Escoamento__c escoamento : [SELECT Id, Territorio__c, TerritorioGerencial__c, NomeCliente__c FROM Escoamento__c WHERE Territorio__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(escoamento.Territorio__c + '-' + escoamento.NomeCliente__c)){
                escoamento.TerritorioGerencial__c =  mapCustomerTerritory.get(escoamento.Territorio__c + '-' + escoamento.NomeCliente__c);
                updateEscoamento.add(escoamento);
            }
        }

        for(HistoricoNota__c historicoNota : [SELECT Id, IdTerritorioSF__c, TerritorioGerencial__c, IdContaSF__c FROM HistoricoNota__c WHERE IdTerritorioSF__c IN : territoriesIds]){
            if(mapCustomerTerritory.containsKey(historicoNota.IdTerritorioSF__c + '-' + historicoNota.IdContaSF__c)){
                historicoNota.TerritorioGerencial__c =  mapCustomerTerritory.get(historicoNota.IdTerritorioSF__c + '-' + historicoNota.IdContaSF__c);
                updateHistoricoNota.add(historicoNota);
            }
        }

        Map<Id, NotaFiscalItem__c> notaItemOldContextMap = new Map<Id, NotaFiscalItem__c>();

        for(NotaFiscalItem__c notaItem : [SELECT Id, CriterioApuracao__c, NotaFiscal__c, CodigoMaterial__c FROM NotaFiscalItem__c WHERE NotaFiscal__c IN : updateNotaFiscal.keySet()]){
            notaItemOldContextMap.put(notaItem.Id, notaItem);
        }

        if(!updateNotaFiscal.isEmpty()){
            update updateNotaFiscal.values();
        }

        Map<Id, NotaFiscalItem__c> notaItemNewContextMap = new Map<Id, NotaFiscalItem__c>();

        for(NotaFiscalItem__c notaItem : [SELECT Id, CriterioApuracao__c, NotaFiscal__c, CodigoMaterial__c FROM NotaFiscalItem__c WHERE NotaFiscal__c IN : updateNotaFiscal.keySet()]){
            notaItemNewContextMap.put(notaItem.Id, notaItem);
        }

        if(!updateEscoamento.isEmpty()){
            update updateEscoamento;
        }

        if(!updateHistoricoNota.isEmpty()){
            update updateHistoricoNota;
        }

         if(!notaItemNewContextMap.isEmpty()){
            update notaItemNewContextMap.values();
            NotaFiscalItemHelper.updateApuracaoRelation(notaItemNewContextMap, notaItemOldContextMap);
        }
    }
}