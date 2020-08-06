@RestResource(urlMapping = '/tabelaPrecoService/*')
global with sharing class IntegrationInboundTabelaPreco {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.TabelaPrecoINData> request = (List<TemplateDataIntegrationFields.TabelaPrecoINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.TabelaPrecoINData>.class);

            return upsertTabelaPreco(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Tabela de Preço', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertTabelaPreco(List<TemplateDataIntegrationFields.TabelaPrecoINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> hierarquiaClienteLookups = new List<String>();
        List<String> clienteLookups = new List<String>();
        List<String> regionalLookups = new List<String>();
        List<String> productLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TabelaPreco__c> tabelaPrecoListToUpsert = new List<TabelaPreco__c>();

        for (TemplateDataIntegrationFields.TabelaPrecoINData tabelaPrecoINData : request) {
            hierarquiaClienteLookups.add(tabelaPrecoINData.hierarquiaClienteId);
            clienteLookups.add(tabelaPrecoINData.clienteId);
            regionalLookups.add(tabelaPrecoINData.regionalId);
            productLookups.add(tabelaPrecoINData.product2Id);
        }
        
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'HierarquiaCliente__c', hierarquiaClienteLookups, lookups);
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'Cliente__c', clienteLookups, lookups);
        FactoryDataIntegration.addLookup('Regional__c', 'ExternalId__c', 'Regional__c', regionalLookups, lookups);
        FactoryDataIntegration.addLookup('Product2', 'ExternalId__c', 'Produto__c', productLookups, lookups);
        
        FactoryDataIntegration.convertSObject(new TabelaPreco__c(), 'IN', request, responseList, tabelaPrecoListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(tabelaPrecoListToUpsert, TabelaPreco__c.ExternalId__c, false), responseList, tabelaPrecoListToUpsert, TabelaPreco__c.ExternalId__c);

        IntegrationUtils.WSLog('Tabela de Preço', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}