@RestResource(urlMapping = '/cotacaoMoedaService/*')
global with sharing class IntegrationInboundCotacaoMoeda {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.CotacaoMoedaINData> request = (List<TemplateDataIntegrationFields.CotacaoMoedaINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.CotacaoMoedaINData>.class);

            return upsertCotacaoMoeda(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Cotação Moeda', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertCotacaoMoeda(List<TemplateDataIntegrationFields.CotacaoMoedaINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<CotacaoMoeda__c> cotacaoMoedaListToUpsert = new List<CotacaoMoeda__c>();
        
        FactoryDataIntegration.convertSObject(new CotacaoMoeda__c(), 'IN', request, responseList, cotacaoMoedaListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(cotacaoMoedaListToUpsert, CotacaoMoeda__c.ExternalId__c, false), responseList, cotacaoMoedaListToUpsert, CotacaoMoeda__c.ExternalId__c);

        IntegrationUtils.WSLog('Cotação Moeda', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}