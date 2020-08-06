@RestResource(urlMapping = '/tabelaFreteService/*')
global with sharing class IntegrationInboundTabelaFrete {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.TabelaFreteINData> request = (List<TemplateDataIntegrationFields.TabelaFreteINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.TabelaFreteINData>.class);

            return upsertTabelaFrete(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Tabela de Frete', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertTabelaFrete(List<TemplateDataIntegrationFields.TabelaFreteINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> localNegocioLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.Response> responseVigenciaList = new List<TemplateDataIntegrationFields.Response>();
        List<TabelaFrete__c> tabelaFreteListToUpsert = new List<TabelaFrete__c>();
        List<VigenciaTabelaFrete__c> requestVigencia = new List<VigenciaTabelaFrete__c>();
        List<String> tabelaFreteExternalSet = new List<String>();

        for (TemplateDataIntegrationFields.TabelaFreteINData tabelaFreteINData : request) {
            localNegocioLookups.add(tabelaFreteINData.localNegocioId);
            tabelaFreteExternalSet.add(tabelaFreteINData.ExternalId);
        }
        
        FactoryDataIntegration.addLookup('LocalNegocio__c', 'Codigo__c', 'LocalNegocio__c', localNegocioLookups, lookups);

        for (LocalNegocio__c localNegocio : [SELECT Id, Codigo__c FROM LocalNegocio__c WHERE Codigo__c IN :localNegocioLookups]) {
            lookups.put('LocalNegocio__c' + localNegocio.Codigo__c, localNegocio.Id);
        }

        FactoryDataIntegration.convertSObject(new TabelaFrete__c(), 'IN', request, responseList, tabelaFreteListToUpsert, lookups);

        Database.UpsertResult[] upsResults = Database.upsert(tabelaFreteListToUpsert, TabelaFrete__c.IdSAP__c, false);

        Map<String, Id> successfulResultsMap = new Map<String, Id>();

        for (Integer i = 0; i < upsResults.size(); i++) {
            if (upsResults[i].isSuccess()) {
                successfulResultsMap.put(tabelaFreteListToUpsert[i].IdSAP__c, upsResults[i].Id);
            }
        }

        Boolean hasError = IntegrationUtils.upsertRecords(upsResults, responseList, tabelaFreteListToUpsert, TabelaFrete__c.IdSAP__c);

        IntegrationUtils.WSLog('Tabela de Frete', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));

        if(!successfulResultsMap.isEmpty()){
            
            FactoryDataIntegration.addLookup('TabelaFrete__c', 'IdSAP__c', 'TabelaFrete__c', new List<String>(successfulResultsMap.keySet()), lookups);

            List<TemplateDataIntegrationFields.VigenciaTabelaFreteINData> requestVigenciaList = new List<TemplateDataIntegrationFields.VigenciaTabelaFreteINData>();
            for(TemplateDataIntegrationFields.TabelaFreteINData condIN : request){

                TemplateDataIntegrationFields.VigenciaTabelaFreteINData vigencia = new TemplateDataIntegrationFields.VigenciaTabelaFreteINData(condIN);
                
                requestVigenciaList.add(vigencia);
                requestVigencia.add(vigencia.serialize(lookups));
            }
            
            Boolean hasErrorVigencia = IntegrationUtils.upsertRecords(Database.upsert(requestVigencia, VigenciaTabelaFrete__c.ExternalId__c, false), responseVigenciaList, requestVigencia, VigenciaTabelaFrete__c.ExternalId__c);
        
            IntegrationUtils.WSLog('Vigencia Condição', 'Inbound', JSON.serialize(requestVigenciaList), JSON.serialize(responseVigenciaList), hasError, IntegrationUtils.serializeToObjectList(responseVigenciaList));
        

        }

        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}