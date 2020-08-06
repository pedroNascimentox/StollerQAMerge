@RestResource(urlMapping = '/descontoTipoClienteService/*')
global with sharing class IntegrationInboundDescontoTipoCliente {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.DescontoTipoClienteINData> request = (List<TemplateDataIntegrationFields.DescontoTipoClienteINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.DescontoTipoClienteINData>.class);

            return upsertDescontoTipoCliente(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Desconto Tipo Cliente', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertDescontoTipoCliente(List<TemplateDataIntegrationFields.DescontoTipoClienteINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<DescontoTipoCliente__c> descontoTipoClienteListToUpsert = new List<DescontoTipoCliente__c>();
        
        FactoryDataIntegration.convertSObject(new DescontoTipoCliente__c(), 'IN', request, responseList, descontoTipoClienteListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(descontoTipoClienteListToUpsert, DescontoTipoCliente__c.IdSAP__c, false), responseList, descontoTipoClienteListToUpsert, DescontoTipoCliente__c.IdSAP__c);

        IntegrationUtils.WSLog('Desconto Tipo Cliente', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}