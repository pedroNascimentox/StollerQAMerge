@RestResource(urlMapping = '/accountService/*')
global with sharing class IntegrationInboundAccount {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.AccountINData> request = (List<TemplateDataIntegrationFields.AccountINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.AccountINData>.class);

            return upsertAccount(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Cliente', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertAccount(List<TemplateDataIntegrationFields.AccountINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> parentLookups = new List<String>();
        List<String> matrizLookups = new List<String>();
        List<String> revendaAgenciadoraLookups = new List<String>();
        List<String> regionalVendasLookups = new List<String>();
        List<String> rtvLookups = new List<String>();
        List<String> ownerLookups = new List<String>();
        List<String> gerenteRegionalLookups = new List<String>();
        List<String> diretorComercialLookups = new List<String>();
        List<String> zonaTransporteLookups = new List<String>();
        List<String> localNegocioLookups = new List<String>();
        List<String> accLookups = new List<String>();

        Map<String, TemplateDataIntegrationFields.Response> responseMap = new Map<String, TemplateDataIntegrationFields.Response>();
        List<Account> accountListToUpsert = new List<Account>();

        Map<String, List<String>> accountExternalIdToTerritorioExternalIdsMap = new Map<String, List<String>>();
        Set<String> externalIdsToVerify = new Set<String>();
        

        Map<String, TemplateDataIntegrationFields.AccountINData> requestMap = new Map<String, TemplateDataIntegrationFields.AccountINData>();
        //Set<String> atributoRestricaoListName = new Set<String>();
        for (TemplateDataIntegrationFields.AccountINData accountINData : request) {
            requestMap.put(accountINData.externalId, accountINData);

            /*if (accountINData.atributoRestricao != null) {
                for (String att : accountINData.atributoRestricao) {
                    atributoRestricaoListName.add(att);
                }
            }*/

            parentLookups.add(accountINData.parentId);
            matrizLookups.add(accountINData.matrizCredito);
            //accLookups.add(accountINData.ClienteEntrega);
            //accLookups.add(accountINData.ClienteCobranca);
            revendaAgenciadoraLookups.add(accountINData.revendaAgenciadora);
            regionalVendasLookups.add(accountINData.regionalVendas);
            rtvLookups.add(accountINData.rtv);
            gerenteRegionalLookups.add(accountINData.gerenteRegional);
            diretorComercialLookups.add(accountINData.diretorComercial);
            zonaTransporteLookups.add(accountINData.zonaTransporte);
            localNegocioLookups.add(accountINData.localNegocio);

            if ((accountINData.territorioIds != null && !accountINData.territorioIds.isEmpty()) || accountINData.hierarquia) {
                for (String externalId : accountINData.territorioIds) {
                    if (accountExternalIdToTerritorioExternalIdsMap.containsKey(accountINData.externalId)) {
                        accountExternalIdToTerritorioExternalIdsMap.get(accountINData.externalId).add(externalId);
                    } else {
                        accountExternalIdToTerritorioExternalIdsMap.put(accountINData.externalId, new List<String>{externalId});
                    }
                    externalIdsToVerify.add(externalId);
                }
            } else {
                TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
                response.error(accountINData.externalId, 
                    'A lista de External Ids de Territórios está vazia', 
                    'Account');
                responseMap.put(accountINData.externalId, response);
            }
        }

        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'ParentId', parentLookups, lookups);
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'MatrizCredito__c', matrizLookups, lookups);
        //FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'ClienteEntrega__c', accLookups, lookups);
        //FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'ClienteCobranca__c', accLookups, lookups);
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'RevendaAgenciadora__c', revendaAgenciadoraLookups, lookups);
        FactoryDataIntegration.addLookup('Regional__c', 'ExternalId__c', 'RegionalVendas__c', regionalVendasLookups, lookups);
        FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'RTV__c', rtvLookups, lookups);
        // FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'RTV__c', ownerLookups, lookups);
        FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'GerenteRegional__c', gerenteRegionalLookups, lookups);
        FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'DiretorComercial__c', diretorComercialLookups, lookups);
        FactoryDataIntegration.addLookup('ZonaTransporte__c', 'ExternalId__c', 'ZonaTransporte__c', zonaTransporteLookups, lookups);
        FactoryDataIntegration.addLookup('LocalNegocio__c', 'Codigo__c', 'LocalNegocio__c', localNegocioLookups, lookups);

        List<Territorio__c> territorioList = [SELECT Id, ExternalId__c 
                                                FROM Territorio__c 
                                               WHERE ExternalId__c IN :externalIdsToVerify];

        Map<String, Id> territorioExternalIdToIdMap = new Map<String, Id>();
        for (Territorio__c territorio : territorioList) {
            territorioExternalIdToIdMap.put(territorio.ExternalId__c, territorio.Id);
        }

        if (territorioList.size() != externalIdsToVerify.size()) {

            verifyTerritorios(territorioList, accountListToUpsert, responseMap, request, lookups);

        }

        FactoryDataIntegration.convertSObject(new Account(), 'IN', request, responseMap, accountListToUpsert, lookups);
        // System.debug('accountListToUpsert AFTER => ' + JSON.serializePretty(accountListToUpsert));
        // System.debug('responseMap AFTER => ' + JSON.serializePretty(responseMap));

        List<Database.UpsertResult> upsResults = Database.upsert(accountListToUpsert, Account.ExternalId__c, false);

        Boolean hasError = IntegrationUtils.upsertRecords(upsResults, responseMap, accountListToUpsert, Account.ExternalId__c);

        IntegrationUtils.WSLog('Cliente', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseMap.values()), hasError, IntegrationUtils.serializeToObjectList(responseMap.values()));

        //List<Account> successfulAccounts = insertClienteAtributo(accountListToUpsert, upsResults, requestMap, atributoRestricaoListName);

        if (accountListToUpsert.size() > 0) {
            insertRelation(accountListToUpsert, accountExternalIdToTerritorioExternalIdsMap, territorioExternalIdToIdMap);
        }
        
        return new TemplateDataIntegrationFields.ResponseList(responseMap.values());

    }

    /*private static List<Account> insertClienteAtributo(List<Account> accountListToUpsert, List<Database.UpsertResult> upsResults, Map<String, TemplateDataIntegrationFields.AccountINData> requestMap, Set<String> atributoRestricaoListName) {
        
        List<AtributoDefensivos__c> atributoRestricaoList = new List<AtributoDefensivos__c>();
        for (String att : atributoRestricaoListName) {
            atributoRestricaoList.add(new AtributoDefensivos__c(Atributo__c = att));
        }

        Database.upsert(atributoRestricaoList, AtributoDefensivos__c.Atributo__c, false);

        Map<String, Id> atributoRestricaoMap = new Map<String, Id>();
        List<AtributoDefensivos__c> localAtributosRestricao = [SELECT Id, Atributo__c FROM AtributoDefensivos__c WHERE Atributo__c IN :atributoRestricaoListName];
        for (AtributoDefensivos__c att : localAtributosRestricao) {
            atributoRestricaoMap.put(att.Atributo__c, att.Id);
        }

        List<ClienteAtributo__c> clienteAtributoList = new List<ClienteAtributo__c>();
        List<Id> clienteAtributoIdList = new List<Id>();
        List<Account> successfulAccounts = new List<Account>();
        for (Integer i = 0; i < accountListToUpsert.size(); i++) {
            if (upsResults[i].isSuccess()) {
                successfulAccounts.add(accountListToUpsert[i]);
                
                clienteAtributoIdList.add(accountListToUpsert[i].Id);
                if (requestMap.get(accountListToUpsert[i].ExternalId__c).atributoRestricao != null) {
                    for (String atributoRestricao : requestMap.get(accountListToUpsert[i].ExternalId__c).atributoRestricao) {
                        ClienteAtributo__c clienteAtributo = new ClienteAtributo__c(
                            Cliente__c = accountListToUpsert[i].Id, 
                            AtributoDefensivos__c = atributoRestricaoMap.get(atributoRestricao)
                        );
                        clienteAtributoList.add(clienteAtributo);
                    }
                }
            }
        }

        List<ClienteAtributo__c> clienteAtributoToDelete = [SELECT Id FROM ClienteAtributo__c WHERE Cliente__c IN :clienteAtributoIdList];

        delete clienteAtributoToDelete;
        
        Database.insert(clienteAtributoList, false);

        return successfulAccounts;
    }*/

    private static void insertRelation(List<Account> successfulAccounts, Map<String, List<String>> accountExternalIdToTerritorioExternalIdsMap, Map<String, Id> territorioExternalIdToIdMap) {
        
        Map<String, List<String>> accountIdToTerritorioIdsMap = new Map<String, List<String>>();
        for (Account account : successfulAccounts) {
            if (accountExternalIdToTerritorioExternalIdsMap.containsKey(account.ExternalId__c)) {
                for (String externalId : accountExternalIdToTerritorioExternalIdsMap.get(account.ExternalId__c)) {
                    if (accountIdToTerritorioIdsMap.containsKey(account.Id)) {
                        accountIdToTerritorioIdsMap.get(account.Id).add(territorioExternalIdToIdMap.get(externalId));
                    } else {
                        accountIdToTerritorioIdsMap.put(account.Id, new List<String>{territorioExternalIdToIdMap.get(externalId)});
                    }
                }
            }
        }

        List<TerritorioCliente__c> territorioClienteList = new List<TerritorioCliente__c>();
        for (String key : accountIdToTerritorioIdsMap.keySet()) {
            for (String territorioId : accountIdToTerritorioIdsMap.get(key)) {
                territorioClienteList.add(new TerritorioCliente__c(
                    Territorio__c = territorioId,
                    Conta__c = key
                ));
            }
        }

        replaceRelation(successfulAccounts, territorioClienteList);
    }

    private static void replaceRelation(List<Account> accountList, List<TerritorioCliente__c> territorioClienteList) {

        List<String> accountIds = new List<String>();
        for (Account account : accountList) {
            accountIds.add(account.Id);
        }

       List<TerritorioCliente__c> currentChildren = new List<TerritorioCliente__c>([SELECT Id, Conta__c, Territorio__c FROM TerritorioCliente__c WHERE Conta__c IN :accountIds]);

        delete currentChildren;

        Database.insert(territorioClienteList, false);

    }

    private static void verifyTerritorios(List<Territorio__c> territorioList, List<Account> accountListToUpsert, Map<String, TemplateDataIntegrationFields.Response> responseMap, List<TemplateDataIntegrationFields.AccountINData> request, Map<String, Id> lookups) {

        Map<String, Id> localTerritorios = new Map<String, Id>();
        for (Territorio__c territorio : territorioList) {
            localTerritorios.put(territorio.ExternalId__c, territorio.Id);
        }

        Map<String, List<String>> errorMap = new Map<String, List<String>>();
        for (TemplateDataIntegrationFields.AccountINData data : request) {
            if (!data.hierarquia) {
                for (String id : data.territorioIds) {
                    if (!localTerritorios.containsKey(id)) {
                        if (errorMap.containsKey(data.externalId)){
                            errorMap.get(data.externalId).add(id);
                        } else {
                            errorMap.put(data.externalId, new List<String>{id});
                        }
                    }
                }                
            }
        }

        for (TemplateDataIntegrationFields.AccountINData data : request) {
            TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
            if (errorMap.containsKey(data.externalId)) {
                response.error(
                    data.externalId,
                    'Território External Id não encontrado: ' + String.join(errorMap.get(data.externalId), ', '),
                    'Account'
                );
                responseMap.put(data.externalId, response);
            }
        }
    }
}