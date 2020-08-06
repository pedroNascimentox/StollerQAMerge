@isTest
public with sharing class IntegrationInboundMetaTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporte.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        List<Territorio__c> territorioList = new List<Territorio__c>();
        Territorio__c territorio1 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio1;
        territorioList.add(territorio1);

        Territorio__c territorio2 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio2;
        territorioList.add(territorio2);

        Account account1 = (Account)TestFactory.createSObject(
            new Account(
                OwnerId              = user.Id,
                GerenteRegional__c   = user.Id,
                DiretorComercial__c  = user.Id,
                ZonaTransporte__c    = zonaTransporte.Id,
                LocalNegocio__c      = localNegocio.Id,
                RegionalVendas__c    = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert account1;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                RTV__c                = user.Id,
                GerenteRegional__c    = user.Id,
                DiretorComercial__c   = user.Id,
                ZonaTransporte__c     = zonaTransporte.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = account1.Id,
                ParentId              = account1.Id
            )
        );
        insert account;
        
        lookups.put(account.Id, account.ExternalId__c);
        lookups.put(territorio1.Id, territorio1.ExternalId__c);
        lookups.put(product.Id, product.ExternalId__c);

        Meta__c meta = (Meta__c)TestFactory.createSObject(
            new Meta__c(
                NomeConta__c  = account.Id,
                Territorio__c = territorio1.Id,
                Produto__c    = product.Id
            )
        );
        Meta__c metaError = (Meta__c)TestFactory.createSObject(new Meta__c());

        TemplateDataIntegrationFields.MetaINData deserializedMeta1 = new TemplateDataIntegrationFields.MetaINData(meta, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.MetaINData>{deserializedMeta1}));
        IntegrationInboundMeta.parseRequest();

        TemplateDataIntegrationFields.MetaINData deserializedMetaError = new TemplateDataIntegrationFields.MetaINData(metaError, lookups);
        
        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.MetaINData>{deserializedMetaError}));
        IntegrationInboundMeta.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundMeta.parseRequest();
        
        List<Meta__c> receivedMeta = [SELECT Id FROM Meta__c WHERE IDMetaSAP__c = :meta.IDMetaSAP__c OR IDMetaSAP__c = :metaError.IDMetaSAP__c];

        System.assertEquals(1, receivedMeta.size());
    }
}