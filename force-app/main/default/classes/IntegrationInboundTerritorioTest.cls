@isTest
public with sharing class IntegrationInboundTerritorioTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User rtvOrGerente = new User(
            username = 'alberto@stoller.com',
            lastName = 'Alberto',
            email = 'gerentealberto@stoller.com',
            alias = 'gealb',
            communityNickname = 'Ger. Alberto',
            emailEncodingKey = 'ISO-8859-1',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/New_York',
            profileId = profile.Id
        );
        insert rtvOrGerente;
        
        User diretor = new User(
            username = 'adalberto@stoller.com',
            lastName = 'Adalberto',
            email = 'gerenteadalberto@stoller.com',
            alias = 'geadalb',
            communityNickname = 'Ger. Adalberto',
            emailEncodingKey = 'ISO-8859-1',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/New_York',
            BusinessPartnerSAP__c = '123',
            profileId = profile.Id
        );
        insert diretor;        

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        lookups.put(rtvOrGerente.Id, rtvOrGerente.Email);
        lookups.put(diretor.Id, diretor.BusinessPartnerSAP__c);
        lookups.put(regional.Id, regional.ExternalId__c);

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(
            new Territorio__c(
                RTV__c      = rtvOrGerente.Id,
                Gerente__c  = rtvOrGerente.Id,
                Diretor__c  = diretor.Id,
                Regional__c = regional.Id
            )
        );
        Territorio__c territorioError = (Territorio__c)TestFactory.createSObject(new Territorio__c());

        TemplateDataIntegrationFields.TerritorioINData deserializedTerritorio = new TemplateDataIntegrationFields.TerritorioINData(territorio, lookups);
        TemplateDataIntegrationFields.TerritorioINData deserializedTerritorioError = new TemplateDataIntegrationFields.TerritorioINData(territorioError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.TerritorioINData>{deserializedTerritorio, deserializedTerritorioError}));
        IntegrationInboundTerritorio.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundTerritorio.parseRequest();

        List<Territorio__c> receivedTerritorio = [SELECT Id FROM Territorio__c WHERE ExternalId__c = :territorio.ExternalId__c OR ExternalId__c = :territorioError.ExternalId__c];

        // System.assertEquals(1, receivedTerritorio.size());

    }
}