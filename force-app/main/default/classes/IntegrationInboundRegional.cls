@RestResource(urlMapping = '/regionalService/*')
global with sharing class IntegrationInboundRegional {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.RegionalINData> request = (List<TemplateDataIntegrationFields.RegionalINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.RegionalINData>.class);

            return upsertRegional(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Regional', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertRegional(List<TemplateDataIntegrationFields.RegionalINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Regional__c> regionalListToUpsert = new List<Regional__c>();
        
        FactoryDataIntegration.convertSObject(new Regional__c(), 'IN', request, responseList, regionalListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(regionalListToUpsert, Regional__c.ExternalId__c, false), responseList, regionalListToUpsert, Regional__c.ExternalId__c);

        IntegrationUtils.WSLog('Regional', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}