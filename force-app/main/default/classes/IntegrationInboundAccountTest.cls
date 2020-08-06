@isTest
public with sharing class IntegrationInboundAccountTest {
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
        
        lookups.put(zonaTransporte.Id, zonaTransporte.ExternalId__c);
        lookups.put(localNegocio.Id, localNegocio.Codigo__c);
        lookups.put(user.Id, user.BusinessPartnerSAP__c);
        lookups.put(regional.Id, regional.ExternalId__c);
        lookups.put(account1.Id, account1.ExternalId__c);

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
        Account accountError = (Account)TestFactory.createSObject(new Account());

        List<String> atributoDefensivos = new List<String>{'test'};
        
        TemplateDataIntegrationFields.AccountINData deserializedAccount = new TemplateDataIntegrationFields.AccountINData(account, lookups, territorioList, atributoDefensivos);
        TemplateDataIntegrationFields.AccountINData deserializedAccountError = new TemplateDataIntegrationFields.AccountINData(accountError, lookups, territorioList, atributoDefensivos);

        // System.debug('Account response => ' + JSON.serializePretty(
        /*IntegrationInboundAccount.upsertAccount(*/
        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.AccountINData>{deserializedAccount, deserializedAccountError}));
        IntegrationInboundAccount.parseRequest();
            // ));

        Territorio__c territorio3 = (Territorio__c)TestFactory.createSObject(new Territorio__c());
        territorioList.add(territorio3);
        Territorio__c territorio4 = (Territorio__c)TestFactory.createSObject(new Territorio__c());
        territorioList.add(territorio4);

        TemplateDataIntegrationFields.AccountINData deserializedAccount2 = new TemplateDataIntegrationFields.AccountINData(account, lookups, territorioList, atributoDefensivos);

        /*IntegrationInboundAccount.upsertAccount(*/
        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.AccountINData>{deserializedAccount2}));
        IntegrationInboundAccount.parseRequest();

        territorioList.remove(territorioList.size() - 1);
        territorioList.remove(territorioList.size() - 1);
        territorioList.remove(territorioList.size() - 1);

        Territorio__c territorio5 = (Territorio__c)TestFactory.createSObject(new Territorio__c());
        insert territorio5;
        territorioList.add(territorio5);

        TemplateDataIntegrationFields.AccountINData deserializedAccount3 = new TemplateDataIntegrationFields.AccountINData(account, lookups, territorioList, atributoDefensivos);

        /*IntegrationInboundAccount.upsertAccount(*/
        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.AccountINData>{deserializedAccount3}));
        IntegrationInboundAccount.parseRequest();
        
        territorioList.clear();
        
        TemplateDataIntegrationFields.AccountINData deserializedAccount4 = new TemplateDataIntegrationFields.AccountINData(account, lookups, territorioList, atributoDefensivos);

        /*IntegrationInboundAccount.upsertAccount(*/
        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.AccountINData>{deserializedAccount4}));
        IntegrationInboundAccount.parseRequest();

        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundAccount.parseRequest();

        List<Account> receivedAccounts = [SELECT Id FROM Account LIMIT 10];

        System.assertEquals(2, receivedAccounts.size());

    }
}