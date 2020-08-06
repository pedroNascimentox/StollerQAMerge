@RestResource(urlMapping = '/lancamentoContabilService/*')
global with sharing class IntegrationInboundLancamentoContabil {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.LancamentoContabilINData> request = (List<TemplateDataIntegrationFields.LancamentoContabilINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.LancamentoContabilINData>.class);

            return upsertLancamentoContabil(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Lançamento Contábil', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertLancamentoContabil(List<TemplateDataIntegrationFields.LancamentoContabilINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> codigoClienteLookups = new List<String>();
        List<String> codigoMaterialLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<LancamentoContabil__c> lancamentoContabilListToUpsert = new List<LancamentoContabil__c>();
        
        for (TemplateDataIntegrationFields.LancamentoContabilINData lancamentoContabilINData : request) {
            codigoClienteLookups.add(lancamentoContabilINData.codigoCliente);
            codigoMaterialLookups.add(lancamentoContabilINData.codigoMaterial);
        }

        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'ExternalId__c', codigoClienteLookups, lookups);
        FactoryDataIntegration.addLookup('Product2', 'ExternalId__c', 'CodigoMaterial__c', codigoMaterialLookups, lookups);
        
        FactoryDataIntegration.convertSObject(new LancamentoContabil__c(), 'IN', request, responseList, lancamentoContabilListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(lancamentoContabilListToUpsert, LancamentoContabil__c.ExternalId__c, false), responseList, lancamentoContabilListToUpsert, LancamentoContabil__c.ExternalId__c);

        IntegrationUtils.WSLog('Lançamento Contábil', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}