@isTest
public with sharing class TerritorioClienteHelperTest {
    @isTest
    public static void TerritorioClienteHelperTest() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporte.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            )
        );
        insert user;

        Territorio__c territorio1 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio1;

        TerritoryData territoryData = new TerritoryData(territorio1);

        Territorio__c territorio2 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio2;

        Account account = (Account)TestFactory.createSObject(new Account(
            OwnerId             = user.Id,
            GerenteRegional__c  = user.Id,
            DiretorComercial__c = user.Id,
            ZonaTransporte__c   = zonaTransporte.Id,
            LocalNegocio__c     = localNegocio.Id,
            RegionalVendas__c   = regional.Id,
            RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
        ));
        insert account;

        List<TerritorioCliente__c> territoriosClienteToInsert = new List<TerritorioCliente__c>();

        TerritorioCliente__c territorioCliente1 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio1.Id
        );
        
        territoriosClienteToInsert.add(territorioCliente1);

        TerritorioCliente__c territorioCliente2 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio2.Id
        );

        territoriosClienteToInsert.add(territorioCliente2);

        insert territoriosClienteToInsert;

        String concatenatedExternalIds = territorio1.ExternalId__c + ';' + territorio2.ExternalId__c;

        List<Account> localAccounts = [SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id = :account.Id];
        
        System.assertEquals(territorio1.ExternalId__c + ';' + territorio2.ExternalId__c, localAccounts[0].TerritoriosConcatenados__c);

        delete territorioCliente2;

        localAccounts = [SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(territorio1.ExternalId__c, localAccounts[0].TerritoriosConcatenados__c);

    }

    @isTest
    public static void managerialTerritoryChangeTest(){

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        Regional__c regional2 = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional2;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteDestino;

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteOrigem;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporteOrigem.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio;

        Territorio__c territorio2 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional2.Id
        ));
        insert territorio2;

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
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert account;

        Campanha__c campanha = (Campanha__c)TestFactory.createSObject(new Campanha__c());
        insert campanha;

        CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(
            new CondicaoPagamento__c(
                ExternalId__c = 'CR00'
            )
        );
        insert condicaoPagamento;

        Cultura__c cultura = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        insert cultura;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                LocalNegocio__c = localNegocio.Id,
                AccountId = account.Id,
                RecebedorMercadoria__c = account.Id,
                Campanha__c = campanha.Id,
                CondicaoPagamento__c = condicaoPagamento.Id,
                Cultura__c = cultura.Id,
                ClienteAgenciador__c = account.Id,
                Territorio__c = territorio.Id,
                Regional__c = regional.Id,
                GerenteRegional__c = user.Id,
                DiretorComercial__c = user.Id
            )
        );
        insert opportunity;

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

        Order order = (Order)TestFactory.createSObject(
            new Order(
                OpportunityId          = opportunity.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = user.Id,
                GerenteRegional__c     = user.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id,
                SetorAtividade__c      = '10- Produtos'
            )
        );
        insert order;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today().addDays(-4),
                Taxa__c = 20.00
            ));
        insert cotacaoMoeda;

        NotaFiscal__c notaFiscal = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account.Id,
                CodigoCliente__c    = account.Id,
                NrOrdem__c          = order.Id,
                Oportunidade__c     = opportunity.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id,
                DataNF__c           = Date.today()
            )
        );
        insert notaFiscal;

        TerritorioCliente__c territorioCliente1 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio.Id,
            TerritorioGerencial__c = territorio2.Id
        );
        insert territorioCliente1;

        NotaFiscal__c nota = [SELECT Id, TerritorioGerencial__c FROM NotaFiscal__c];

        System.assertEquals(nota.TerritorioGerencial__c, territorioCliente1.TerritorioGerencial__c);

        territorioCliente1.TerritorioGerencial__c = territorio.Id;
        update territorioCliente1;

        NotaFiscal__c notaUpdate = [SELECT Id, TerritorioGerencial__c FROM NotaFiscal__c];

        System.assertEquals(notaUpdate.TerritorioGerencial__c, territorioCliente1.TerritorioGerencial__c);

    }
}