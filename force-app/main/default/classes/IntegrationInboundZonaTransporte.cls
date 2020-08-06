@RestResource(urlMapping = '/zonaTransporteService/*')
global with sharing class IntegrationInboundZonaTransporte {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.ZonaTransporteINData> request = (List<TemplateDataIntegrationFields.ZonaTransporteINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.ZonaTransporteINData>.class);

            return upsertZonaTransporte(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Zona de Transporte', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertZonaTransporte(List<TemplateDataIntegrationFields.ZonaTransporteINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<ZonaTransporte__c> zonaTransporteListToUpsert = new List<ZonaTransporte__c>();
        
        FactoryDataIntegration.convertSObject(new ZonaTransporte__c(), 'IN', request, responseList, zonaTransporteListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(zonaTransporteListToUpsert, ZonaTransporte__c.ExternalId__c, false), responseList, zonaTransporteListToUpsert, ZonaTransporte__c.ExternalId__c);

        IntegrationUtils.WSLog('Zona de Transporte', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}