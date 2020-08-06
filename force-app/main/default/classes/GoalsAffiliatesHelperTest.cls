@isTest
public class GoalsAffiliatesHelperTest {
    
    @isTest
    public static void testInsertGoalsAffiliates() {

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

        Account account2 = (Account)TestFactory.createSObject(
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
                ExternalId__c         = 'Account2Test'
            )
        );
        insert account2;

        Product2 product = (Product2)TestFactory.createSObject(
            new Product2(
                ExternalId__c = 'Product2Test'
            )
        );
        insert product;

        Meta__c meta = new Meta__c(
            // CodigoProduto__c    = 'Product2Test', 
            // CodigoTerritorio__c = 'TerriCode', 
            IDMetaSAP__c        = 'MetaCode',
            NomeConta__c        = account.Id,
            Territorio__c       = territorio.Id,
            Produto__c          = product.Id
        );
        insert meta;

        MetaFilial__c metaFilial = new MetaFilial__c(
            Filial__c           = account2.Id,
            MetaMatriz__c       = meta.Id,
            Territrio__c        = territorio.Id,
            Produto__c          = product.Id
        );
        insert metaFilial;

        Apuracao__c apuracaoChild = [SELECT Id, ApuracaoPai__c, MetaFilial__c, Meta__c, NomeConta__c FROM Apuracao__c WHERE MetaFilial__c = :metaFilial.Id];

        System.assertEquals(metaFilial.Id,  apuracaoChild.MetaFilial__c,    'Apuracao__c Child Created');
        System.assertEquals(meta.Id,        apuracaoChild.Meta__c,          'Apuracao__c Child Created');
        System.assertEquals(false,          apuracaoChild.ApuracaoPai__c,   'Apuracao__c Child Created');

        MetaFilial__c metaFilial2 = new MetaFilial__c(
            Filial__c           = account2.Id,
            MetaMatriz__c       = meta.Id,
            Territrio__c        = territorio.Id,
            Produto__c          = product.Id
        );

        MetaFilial__c metaFilial3 = new MetaFilial__c(
            Filial__c           = account.Id,
            MetaMatriz__c       = meta.Id,
            Territrio__c        = territorio.Id,
            Produto__c          = product.Id
        );

        try{
            insert metaFilial2;
        }
        catch(Exception e){
            //System.debug('Message Error -> ' + e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('Filial ja existente na Meta') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }

        try{
            insert metaFilial3;
        }
        catch(Exception e){
            //System.debug('Message Error -> ' + e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('Filial não pode ser o mesmo da Meta') ? true : false;
            System.AssertEquals(expectedExceptionThrown, false);
        }

    }

    @isTest
    public static void testUpdateGoalsAffiliates() {

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

        Account account2 = (Account)TestFactory.createSObject(
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
                ExternalId__c         = 'Account2Test'
            )
        );
        insert account2;

        Product2 product = (Product2)TestFactory.createSObject(
            new Product2(
                ExternalId__c = 'Product2Test'
            )
        );
        insert product;

        Meta__c meta = new Meta__c(
            CodigoProduto__c    = 'Product2Test', 
            CodigoTerritorio__c = 'TerriCode', 
            IDMetaSAP__c        = 'MetaCode',
            NomeConta__c        = account.Id,
            Territorio__c       = territorio.Id,
            Produto__c          = product.Id
        );
        insert meta;

        MetaFilial__c metaFilial = new MetaFilial__c(
            Filial__c           = account2.Id,
            MetaMatriz__c       = meta.Id,
            Territrio__c        = territorio.Id,
            Produto__c          = product.Id,
            OrcamentoReais__c   = 1000
        );
        insert metaFilial;

        Apuracao__c apuracaoChild = [SELECT Id, OrcamentoReais__c FROM Apuracao__c WHERE MetaFilial__c = :metaFilial.Id];

        System.assertEquals(metaFilial.OrcamentoReais__c, apuracaoChild.OrcamentoReais__c, 'Apuracao__c Child Created');

        metaFilial.OrcamentoReais__c = 1100;
        update metaFilial;

        Apuracao__c apuracaoChildUpdated = [SELECT Id, OrcamentoReais__c FROM Apuracao__c WHERE MetaFilial__c = :metaFilial.Id];

        System.assertEquals(metaFilial.OrcamentoReais__c, apuracaoChildUpdated.OrcamentoReais__c, 'MetaFilial__c and Apuracao__c Child Updated');

    }
}