@isTest
public with sharing class EscoamentoHelperTest {
    @TestSetup
    public static void testEscoamentoHelper() {

        Map<Id, String> lookups = new Map<Id, String>();

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
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
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert account2;

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

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();
        
        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];
        
        CotacaoMoeda__c cotacaoMoedaError = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert cotacaoMoedaError;

        CotacaoMoeda__c cotacaoMoedaError1 = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 3
            ));
        insert cotacaoMoedaError1;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 1,
                Taxa__c = 20.00
            ));
        insert cotacaoMoeda;

        NotaFiscal__c notaFiscal1 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account.Id,
                CodigoCliente__c    = account.Id,
                NrOrdem__c          = order.Id,
                Oportunidade__c     = opportunity.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id
            )
        );
        insert notaFiscal1;
        
        NotaFiscalItem__c notaFiscalItem1 = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NrItemOrdemNossonr__c = '123',
                NotaFiscal__c         = notaFiscal1.Id,
                CodigoMaterial__c     = product.Id,
                Cultura__c            = cultura.Id,
                QuantidadeNota__c     = 27
            )
        );
        insert notaFiscalItem1;
        //LogImportacao__c[] logImportacaoList = [SELECT Id, ValoresAntigos__c, ValoresNovos__c FROM LogImportacao__c LIMIT 10];

        /*System.assertEquals(1, logImportacaoList.size());

        System.assertEquals(true, 
            String.valueOf(logImportacaoList[0].ValoresAntigos__c).contains('DataApuracao__c => ' + Date.today()));

        System.assertEquals(true, 
            String.valueOf(logImportacaoList[0].ValoresNovos__c).contains('DataApuracao__c => ' + (Date.today() + 1)));
        */
    }
    @isTest
    public static void testLog2() {        
        
        Id productId = [SELECT id FROM Product2 LIMIT 1].id;
        Id accountId = [SELECT id FROM Account LIMIT 1].id;
        Escoamento__c escoamento2 = (Escoamento__c)TestFactory.createSObject(
            new Escoamento__c(
                Produto__c     = productId,
                NomeCliente__c = accountId,
                Quantidade__c  = 6
            )
        );
        EscoamentoHelper.disableTrigger();
        insert escoamento2;
        EscoamentoHelper.enableTrigger();

        delete new Escoamento__c(id = escoamento2.id);
    }
    @isTest
    public static void testLog3() {
        Id productId                              = [SELECT id FROM Product2 LIMIT 1].id;
        String productExternalId                  = [SELECT ExternalId__c FROM Product2 LIMIT 1].ExternalId__c;
        Id accountId                              = [SELECT id FROM Account LIMIT 1].id;
        Id territorioId                           = [SELECT Id FROM Territorio__c LIMIT 1].Id;
        Id notaFiscalItemId                       = [SELECT Id FROM NotaFiscalItem__c LIMIT 1].Id;
        Id notaFiscalId                           = [SELECT Id FROM NotaFiscal__c LIMIT 1].Id;
        Id orderId                                = [SELECT Id FROM Order LIMIT 1].Id;
        Id oppId                                  = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Id regionalId                             = [SELECT Id FROM Regional__c LIMIT 1].Id;
        Id userId                                 = [SELECT Id FROM User LIMIT 1].Id;
        Id culturaId                              = [SELECT Id FROM Cultura__c LIMIT 1].Id;

        NotaFiscal__c notaFiscal1                 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                TipoNota__c                       = 'ZA',
                CodigoAgenciador__c               = accountId,
                CodigoCliente__c                  = accountId,
                NrOrdem__c                        = orderId,
                Oportunidade__c                   = oppId,
                Regional__c                       = regionalId,
                Territorio__c                     = territorioId
            )
        );
        
        insert notaFiscal1;

        NotaFiscalItem__c notaFiscalItem1         = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                SaldoLitrosEscoamento__c          = 1,
                NrItemOrdemNossonr__c             = '123',
                NotaFiscal__c                     = notaFiscal1.Id,
                CodigoMaterial__c                 = productId,
                Cultura__c                        = culturaId,
                QuantidadeNota__c                 = 27
            )
        );
        
        insert notaFiscalItem1;

        Escoamento__c escoamento2                 = (Escoamento__c)TestFactory.createSObject(
            new Escoamento__c(
                Produto__c                        = productId,
                NomeCliente__c                    = accountId,
                Quantidade__c                     = 6
            )
        );

        
        EscoamentoHelper.disableTrigger();
        insert escoamento2;
        EscoamentoHelper.enableTrigger();

        Escoamento__c escoamento3                 = (Escoamento__c)TestFactory.createSObject(
            new Escoamento__c(
                Territorio__c                     = territorioId,
                Produto__c                        = productId,
                NomeCliente__c                    = accountId,
                Quantidade__c                     = 6
            )
        );
        insert escoamento3;

        if(Test.isRunningTest()) {
            Test.setMock(HttpCalloutMock.class, new IntegrationOutboundEscoamentoMock());
        }
        
        IntegrationOutboundEscoamento.sendEscoamentoTrigger(new Set<Id>{escoamento3.id});

        Test.startTest();
        Test.stopTest();
        
        delete new Escoamento__c(id               = escoamento3.id);
    
        // System.assertEquals(14, 
        //     Integer.valueOf([SELECT Id, SaldoLitrosEscoamento__c FROM NotaFiscalItem__c WHERE Id = :notaFiscalItem1.Id].SaldoLitrosEscoamento__c));

        // System.assertEquals(1, 
        //     Integer.valueOf([SELECT Id, SaldoLitrosEscoamento__c FROM NotaFiscalItem__c WHERE Id = :notaFiscalItem1.Id].SaldoLitrosEscoamento__c));

        // System.assertEquals(5, 
        //     Integer.valueOf([SELECT Id, SaldoLitrosEscoamento__c FROM Escoamento__c WHERE Id = :escoamento3.Id].SaldoLitrosEscoamento__c));

        // System.assertEquals(1, 
        //     Integer.valueOf([SELECT Id, SaldoLitrosEscoamento__c FROM NotaFiscalItem__c WHERE Id = :notaFiscalItem1.Id].SaldoLitrosEscoamento__c));

        //System.assertEquals(14, 
        //    Integer.valueOf([SELECT Id, SaldoLitrosEscoamento__c FROM NotaFiscalItem__c WHERE NrItemOrdemNossonr__c = '123'].SaldoLitrosEscoamento__c));
    }
}