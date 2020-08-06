@RestResource(urlMapping = '/territorioService/*')
global with sharing class IntegrationInboundTerritorio {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.TerritorioINData> request = (List<TemplateDataIntegrationFields.TerritorioINData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.TerritorioINData>.class);

            return upsertTerritorio(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Território', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertTerritorio(List<TemplateDataIntegrationFields.TerritorioINData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> rtvLookups = new List<String>();
        List<String> gerenteLookups = new List<String>();
        List<String> diretorLookups = new List<String>();
        List<String> regionalLookups = new List<String>();

        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Territorio__c> territorioListToUpsert = new List<Territorio__c>();

        Map<String, String> codigoBPToEmail = new Map<String, String>();

        for (TemplateDataIntegrationFields.TerritorioINData territorioINData : request) {

            codigoBPToEmail.put(territorioINData.emailRtv, territorioINData.codigoBPRtv);
            codigoBPToEmail.put(territorioINData.emailGerente, territorioINData.codigoBPGerente);

            rtvLookups.add(territorioINData.emailRtv);
            gerenteLookups.add(territorioINData.emailGerente);
            diretorLookups.add(territorioINData.codigoBPDiretor);
            regionalLookups.add(territorioINData.regionalId);
        }
        
        FactoryDataIntegration.addLookup('User', 'Username', 'RTV__c', rtvLookups, lookups);
        FactoryDataIntegration.addLookup('User', 'Username', 'Gerente__c', gerenteLookups, lookups);
        FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'Diretor__c', diretorLookups, lookups);
        FactoryDataIntegration.addLookup('Regional__c', 'ExternalId__c', 'Regional__c', regionalLookups, lookups);
        
        FactoryDataIntegration.convertSObject(new Territorio__c(), 'IN', request, responseList, territorioListToUpsert, lookups);

        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(territorioListToUpsert, Territorio__c.ExternalId__c, false), responseList, territorioListToUpsert, Territorio__c.ExternalId__c);

        if (codigoBPToEmail.size() != 0)
            updateUserBPCode(codigoBPToEmail);

        IntegrationUtils.WSLog('Território', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseList), hasError, IntegrationUtils.serializeToObjectList(responseList));
        
        return new TemplateDataIntegrationFields.ResponseList(responseList);

    }

    private static void updateUserBPCode(Map<String, String> codigoBPToEmail) {

        List<User> userList = [SELECT Id, Username, BusinessPartnerSAP__c FROM User WHERE Username IN :codigoBPToEmail.keySet()];
        for (User user : userList) {
            user.BusinessPartnerSAP__c = codigoBPToEmail.get(user.Username);
        }
        update userList;

    }
}