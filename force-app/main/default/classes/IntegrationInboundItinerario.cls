@RestResource(urlMapping = '/itinerarioService/*')
global with sharing class IntegrationInboundItinerario {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.ItinerarioINData> request = (List<TemplateDataIntegrationFields.ItinerarioINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.ItinerarioINData>.class);

            return upsertItinerario(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Itinerário', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertItinerario(List<TemplateDataIntegrationFields.ItinerarioINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> zonaTransporteOrigemLookups = new List<String>();
        List<String> zonaTransporteDestinoLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Itinerario__c> itinerarioListToUpsert = new List<Itinerario__c>();

        Map<String, String> metadataMap = IntegrationUtils.getMetadataDePara(new List<String>{'ItinerarioFracionado', 'ItinerarioLotacao'});
        
        for (TemplateDataIntegrationFields.ItinerarioINData itinerarioINData : request) {
            itinerarioINData.tipoExpedicao = metadataMap.containsKey(itinerarioINData.tipoExpedicao) ? metadataMap.get(itinerarioINData.tipoExpedicao) : itinerarioINData.tipoExpedicao;
            zonaTransporteOrigemLookups.add(itinerarioINData.origemZonaTransporteId);
            zonaTransporteDestinoLookups.add(itinerarioINData.destinoZonaTransporteId);
        }

        FactoryDataIntegration.addLookup('ZonaTransporte__c', 'ExternalId__c', 'ZonaTransporteOrigem', zonaTransporteOrigemLookups, lookups);
        FactoryDataIntegration.addLookup('ZonaTransporte__c', 'ExternalId__c', 'ZonaTransporteDestino', zonaTransporteDestinoLookups, lookups);

        FactoryDataIntegration.convertSObject(new Itinerario__c(), 'IN', request, responseList, itinerarioListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(itinerarioListToUpsert, Itinerario__c.InternalExternalId__c, false), responseList, itinerarioListToUpsert, Itinerario__c.InternalExternalId__c);

        IntegrationUtils.WSLog('Itinerário', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));

        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}