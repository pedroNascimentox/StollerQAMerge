@isTest
public with sharing class IntegrationInboundPoliticaDescontoTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        Cultura__c cultura = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        insert cultura;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        CulturaProduto__c culturaProduto = new CulturaProduto__c(
            Cultura__c = cultura.Id,
            Produto__c = product.Id
        );
        insert culturaProduto;

        Account account = new Account(
            name = 'Hierarchy Account',
            externalId__c = 'h13r4rchy4cc0un7',
            tipoCliente__c = 'ZC',
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId(),
            CanalDistribuicao__c = '10'
        );
        insert account;

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User user = new User(
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
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio;

        lookups.put(account.Id, account.ExternalId__c);
        lookups.put(regional.Id, regional.ExternalId__c);
        lookups.put(territorio.Id, territorio.ExternalId__c);
        lookups.put(product.Id, product.ExternalId__c);

        PoliticaDesconto__c politicaDesconto = (PoliticaDesconto__c)TestFactory.createSObject(new PoliticaDesconto__c(
            Hierarquia__c = account.Id,
            Conta__c      = account.Id,
            Regional__c   = regional.Id,
            Territorio__c = territorio.Id,
            Produto__c    = product.Id
        ));
        PoliticaDesconto__c politicaDescontoError = (PoliticaDesconto__c)TestFactory.createSObject(new PoliticaDesconto__c());

        TemplateDataIntegrationFields.PoliticaDescontoINData deserializedPoliticaDesconto = new TemplateDataIntegrationFields.PoliticaDescontoINData(politicaDesconto, lookups);
        TemplateDataIntegrationFields.PoliticaDescontoINData deserializedPoliticaDescontoError = new TemplateDataIntegrationFields.PoliticaDescontoINData(politicaDescontoError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.PoliticaDescontoINData>{deserializedPoliticaDesconto, deserializedPoliticaDescontoError}));
        IntegrationInboundPoliticaDesconto.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundPoliticaDesconto.parseRequest();

        List<PoliticaDesconto__c> receivedPoliticaDesconto = [SELECT Id FROM PoliticaDesconto__c WHERE ExternalId__c = :politicaDesconto.ExternalId__c OR ExternalId__c = :politicaDescontoError.ExternalId__c];

        System.assertEquals(1, receivedPoliticaDesconto.size());

    }
}