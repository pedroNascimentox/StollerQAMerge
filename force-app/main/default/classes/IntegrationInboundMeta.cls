@RestResource(urlMapping = '/metaService/*')
global with sharing class IntegrationInboundMeta {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.MetaINData> request = (List<TemplateDataIntegrationFields.MetaINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.MetaINData>.class);

            return upsertMeta(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Meta', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertMeta(List<TemplateDataIntegrationFields.MetaINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> accountLookups = new List<String>();
        List<String> territorioLookups = new List<String>();
        List<String> productLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Meta__c> metaListToUpsert = new List<Meta__c>();

        Map<String, Integer> productExternalIdToLitragem = new Map<String, Integer>();
        
        for (TemplateDataIntegrationFields.MetaINData metaINData : request) {
            accountLookups.add(metaINData.accountId);
            territorioLookups.add(metaINData.territorioId);
            productLookups.add(metaINData.productId);
        }

        for (Product2 product : [SELECT Id, ExternalId__c, Litragem__c FROM Product2 WHERE ExternalId__c IN :productLookups]) {
            lookups.put('Produto__c' + product.ExternalId__c, product.Id);
            productExternalIdToLitragem.put(product.ExternalId__c, Integer.valueOf(product.Litragem__c));
        }

        FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'NomeConta__c', accountLookups, lookups);
        // FactoryDataIntegration.addLookup('Territorio__c', 'ExternalId__c', 'Territorio__c', territorioLookups, lookups); this method can be upgraded to do what lies below

        for (Territorio__c territorio : [SELECT Id, ExternalId__c, OwnerId FROM Territorio__c WHERE ExternalId__c IN :territorioLookups]) {
            lookups.put('Territorio__c' + territorio.ExternalId__c, territorio.Id);
            lookups.put('OwnerId' + territorio.ExternalId__c, territorio.OwnerId);
        }

        for (TemplateDataIntegrationFields.MetaINData metaINData : request) {
            if (productExternalIdToLitragem.containsKey(metaINData.productId) && productExternalIdToLitragem.get(metaINData.productId) != null) {
                metaINData.litros = metaINData.litros * productExternalIdToLitragem.get(metaINData.productId);
            }
        }

        FactoryDataIntegration.convertSObject(new Meta__c(), 'IN', request, responseList, metaListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(metaListToUpsert, Meta__c.IDMetaSAP__c, false), responseList, metaListToUpsert, Meta__c.IDMetaSAP__c);

        IntegrationUtils.WSLog('Meta', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));

        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }
}