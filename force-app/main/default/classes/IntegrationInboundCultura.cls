@RestResource(urlMapping = '/culturaService/*')
global with sharing class IntegrationInboundCultura {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.CulturaINData> request = (List<TemplateDataIntegrationFields.CulturaINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.CulturaINData>.class);

            return upsertCultura(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Cultura', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertCultura(List<TemplateDataIntegrationFields.CulturaINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Cultura__c> culturaListToUpsert = new List<Cultura__c>();
        
        FactoryDataIntegration.convertSObject(new Cultura__c(), 'IN', request, responseList, culturaListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(culturaListToUpsert, Cultura__c.ExternalId__c, false), responseList, culturaListToUpsert, Cultura__c.ExternalId__c);

        IntegrationUtils.WSLog('Cultura', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}