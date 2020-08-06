@RestResource(urlMapping = '/localNegocioService/*')
global with sharing class IntegrationInboundLocalNegocio {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.LocalNegocioINData> request = (List<TemplateDataIntegrationFields.LocalNegocioINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.LocalNegocioINData>.class);

            return upsertLocalNegocio(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Local de Negócio', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertLocalNegocio(List<TemplateDataIntegrationFields.LocalNegocioINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> zonaTransporteLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<LocalNegocio__c> localNegocioListToUpsert = new List<LocalNegocio__c>();

        for (TemplateDataIntegrationFields.LocalNegocioINData localNegocioINData : request) {
            zonaTransporteLookups.add(localNegocioINData.zonaTransporteId);
        }
        
        FactoryDataIntegration.addLookup('ZonaTransporte__c', 'ExternalId__c', 'ZonaTransporte__c', zonaTransporteLookups, lookups);

        FactoryDataIntegration.convertSObject(new LocalNegocio__c(), 'IN', request, responseList, localNegocioListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(localNegocioListToUpsert, LocalNegocio__c.Codigo__c, false), responseList, localNegocioListToUpsert, LocalNegocio__c.Codigo__c);

        IntegrationUtils.WSLog('Local de Negócio', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));

        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}