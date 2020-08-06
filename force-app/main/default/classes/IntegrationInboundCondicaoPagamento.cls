@RestResource(urlMapping = '/condicaoPagamentoService/*')
global with sharing class IntegrationInboundCondicaoPagamento {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.CondicaoPagamentoINData> request = (List<TemplateDataIntegrationFields.CondicaoPagamentoINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.CondicaoPagamentoINData>.class);

            return upsertCondicaoPagamento(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Condição de Pagamento', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertCondicaoPagamento(List<TemplateDataIntegrationFields.CondicaoPagamentoINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.Response> responseVigenciaList = new List<TemplateDataIntegrationFields.Response>();
        List<VigenciaCondicao__C> requestVigencia = new List<VigenciaCondicao__C>();
        List<String> condExternalIdSet = new List<String>();
        List<CondicaoPagamento__c> condicaoPagamentoListToUpsert = new List<CondicaoPagamento__c>();
        for(TemplateDataIntegrationFields.CondicaoPagamentoINData condIN : request){
            condExternalIdSet.add(condIN.externalId);  
        }

        FactoryDataIntegration.convertSObject(new CondicaoPagamento__c(), 'IN', request, responseList, condicaoPagamentoListToUpsert, lookups);

        Database.UpsertResult[] upsResults = Database.upsert(condicaoPagamentoListToUpsert, CondicaoPagamento__c.ExternalId__c, false);

        Map<String, Id> successfulResultsMap = new Map<String, Id>();

        for (Integer i = 0; i < upsResults.size(); i++) {
            if (upsResults[i].isSuccess()) {
                successfulResultsMap.put(condicaoPagamentoListToUpsert[i].ExternalId__c, upsResults[i].Id);
            }
        }

        Boolean hasError = IntegrationUtils.upsertRecords(upsResults, responseList, condicaoPagamentoListToUpsert, CondicaoPagamento__c.ExternalId__c);
        
        IntegrationUtils.WSLog('Condição de Pagamento', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        if(!successfulResultsMap.isEmpty()){
            
            FactoryDataIntegration.addLookup('CondicaoPagamento__c', 'ExternalId__c', 'CondicaoPagamento__c', new List<String>(successfulResultsMap.keySet()), lookups);

            List<TemplateDataIntegrationFields.VigenciaCondicaoINData> requestVigenciaList = new List<TemplateDataIntegrationFields.VigenciaCondicaoINData>();
            for(TemplateDataIntegrationFields.CondicaoPagamentoINData condIN : request){

                TemplateDataIntegrationFields.VigenciaCondicaoINData vigencia = new TemplateDataIntegrationFields.VigenciaCondicaoINData(condIN);
                
                requestVigenciaList.add(vigencia);
                requestVigencia.add(vigencia.serialize(lookups));
            }
            
            Boolean hasErrorVigencia = IntegrationUtils.upsertRecords(Database.upsert(requestVigencia, VigenciaCondicao__c.ExternalId__c, false), responseVigenciaList, requestVigencia, VigenciaCondicao__c.ExternalId__c);
        
            IntegrationUtils.WSLog('Vigencia Condição', 'Inbound', JSON.serialize(requestVigenciaList), JSON.serialize(responseVigenciaList), hasError, IntegrationUtils.serializeToObjectList(responseVigenciaList));
        
        }
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}