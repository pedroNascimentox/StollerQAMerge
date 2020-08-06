@isTest
public class GoalsHelperTest {
    
    @isTest
    public static void testInsertGoals() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(
            new Regional__c(
                ExternalId__c = 'RegionalTest'
            )
        );
        insert regional;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteDestino;

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteOrigem;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporteOrigem.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];

        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id,
            ExternalId__c = 'TerriCode'
        ));
        insert territorio;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = user.Id,
                GerenteRegional__c  = user.Id,
                DiretorComercial__c = user.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = user.Id,
                GerenteRegional__c    = user.Id,
                DiretorComercial__c   = user.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId(),
                ExternalId__c         = 'AccountTest'
            )
        );
        insert account;

        Product2 product = (Product2)TestFactory.createSObject(
            new Product2(
                ExternalId__c = 'Product2Test'
            )
        );
        insert product;

        Meta__c meta = new Meta__c(
            // CodigoProduto__c = 'Product2Test', 
            // CodigoTerritorio__c = 'TerriCode', 
            IDMetaSAP__c = 'MetaCode',
            NomeConta__c = account.Id,
            Territorio__c = territorio.Id,
            Produto__c = product.Id
        );
        insert meta;

        Apuracao__c apuracao = [SELECT Id, ApuracaoPai__c, Meta__c FROM Apuracao__c WHERE Meta__c = :meta.Id];

        System.assertEquals(meta.Id, apuracao.Meta__c, 'Apuracao__c created');
        System.assertEquals(true, apuracao.ApuracaoPai__c, 'Apuracao__c created');

    }

    @isTest
    public static void testUpdateGoals() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(
            new Regional__c(
                ExternalId__c = 'RegionalTest'
            )
        );
        insert regional;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteDestino;

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteOrigem;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporteOrigem.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];

        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id,
            ExternalId__c = 'TerriCode'
        ));
        insert territorio;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = user.Id,
                GerenteRegional__c  = user.Id,
                DiretorComercial__c = user.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = user.Id,
                GerenteRegional__c    = user.Id,
                DiretorComercial__c   = user.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId(),
                ExternalId__c         = 'AccountTest'
            )
        );
        insert account;

        Product2 product = (Product2)TestFactory.createSObject(
            new Product2(
                ExternalId__c = 'Product2Test'
            )
        );
        insert product;

        Meta__c meta = new Meta__c(
            CodigoProduto__c = 'Product2Test', 
            CodigoTerritorio__c = 'TerriCode', 
            IDMetaSAP__c = 'MetaCode',
            NomeConta__c = account.Id,
            Territorio__c = territorio.Id,
            Produto__c = product.Id,
            OrcamentoReal__c = 1000
        );
        insert meta;

        Apuracao__c apuracao = [SELECT Id, OrcamentoReais__c, Meta__c FROM Apuracao__c WHERE Meta__c = :meta.Id];

        System.assertEquals(meta.OrcamentoReal__c, apuracao.OrcamentoReais__c, 'Apuracao__c created');

        meta.OrcamentoReal__c = 1100;
        update meta;

        Apuracao__c apuracaoUpdated = [SELECT Id, OrcamentoReais__c, Meta__c FROM Apuracao__c WHERE Meta__c = :meta.Id];

        System.assertEquals(meta.OrcamentoReal__c, apuracaoUpdated.OrcamentoReais__c, 'Apuracao__c Updated');

    }
}