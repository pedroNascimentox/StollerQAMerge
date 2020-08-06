@RestResource(urlMapping = '/politicaDescontoService/*')
global with sharing class IntegrationInboundPoliticaDesconto {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.PoliticaDescontoINData> request = (List<TemplateDataIntegrationFields.PoliticaDescontoINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.PoliticaDescontoINData>.class);

            return upsertPoliticaDesconto(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Política de Desconto', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertPoliticaDesconto(List<TemplateDataIntegrationFields.PoliticaDescontoINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> territorioLookups = new List<String>();
        List<String> hierarquiaClienteLookups = new List<String>();
        List<String> accountLookups = new List<String>();
        List<String> regionalLookups = new List<String>();
        List<String> productLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<PoliticaDesconto__c> politicaDescontoListToUpsert = new List<PoliticaDesconto__c>();

        for (TemplateDataIntegrationFields.PoliticaDescontoINData politicaDesconto : request) {
            territorioLookups.add(politicaDesconto.territorioId);
            hierarquiaClienteLookups.add(politicaDesconto.hierarquiaClienteId);
            accountLookups.add(politicaDesconto.accountId);
            regionalLookups.add(politicaDesconto.regionalId);
            productLookups.add(politicaDesconto.productId);
        }
        
        FactoryDataIntegration.addLookup('Territorio__c', 'ExternalId__c', 'Territorio__c', territorioLookups, lookups);
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'Hierarquia__c', hierarquiaClienteLookups, lookups);
        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'Conta__c', accountLookups, lookups);
        FactoryDataIntegration.addLookup('Regional__c', 'ExternalId__c', 'Regional__c', regionalLookups, lookups);
        FactoryDataIntegration.addLookup('Product2', 'ExternalId__c', 'Produto__c', productLookups, lookups);
        
        FactoryDataIntegration.convertSObject(new PoliticaDesconto__c(), 'IN', request, responseList, politicaDescontoListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(politicaDescontoListToUpsert, PoliticaDesconto__c.ExternalId__c, false), responseList, politicaDescontoListToUpsert, PoliticaDesconto__c.ExternalId__c);

        IntegrationUtils.WSLog('Política de Desconto', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}