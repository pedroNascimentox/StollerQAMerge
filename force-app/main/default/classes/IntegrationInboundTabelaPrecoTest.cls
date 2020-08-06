@isTest
public with sharing class IntegrationInboundTabelaPrecoTest {
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

        Account account1 = (Account)TestFactory.createSObject(
            new Account(
                RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            ));
        insert account1;

        Account account2 = (Account)TestFactory.createSObject(
            new Account(
                ParentId = account1.Id,
                RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            ));
        insert account2;

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            )
        );
        insert user;

        lookups.put(account1.Id, account1.ExternalId__c);
        lookups.put(account2.Id, account2.ExternalId__c);
        lookups.put(regional.Id, regional.ExternalId__c);
        lookups.put(product.Id, product.ExternalId__c);

        TabelaPreco__c tabelaPreco = (TabelaPreco__c)TestFactory.createSObject(new TabelaPreco__c(
            HierarquiaCliente__c = account1.Id,
            Cliente__c           = account2.Id,
            Regional__c          = regional.Id,
            Produto__c           = product.Id
        ));
        TabelaPreco__c tabelaPrecoError = (TabelaPreco__c)TestFactory.createSObject(new TabelaPreco__c());
        tabelaPrecoError.OrganizacaoVenda__c = null;

        TemplateDataIntegrationFields.TabelaPrecoINData deserializedTabelaPreco = new TemplateDataIntegrationFields.TabelaPrecoINData(tabelaPreco, lookups);
        TemplateDataIntegrationFields.TabelaPrecoINData deserializedTabelaPrecoError = new TemplateDataIntegrationFields.TabelaPrecoINData(tabelaPrecoError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.TabelaPrecoINData>{deserializedTabelaPreco, deserializedTabelaPrecoError}));
        IntegrationInboundTabelaPreco.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundTabelaPreco.parseRequest();

        List<TabelaPreco__c> receivedTabelaPreco = [SELECT Id FROM TabelaPreco__c WHERE ExternalId__c = :tabelaPreco.ExternalId__c OR ExternalId__c = :tabelaPrecoError.ExternalId__c];

        System.assertEquals(1, receivedTabelaPreco.size());

    }
}