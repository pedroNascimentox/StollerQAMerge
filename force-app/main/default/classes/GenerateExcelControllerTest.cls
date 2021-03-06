@isTest
public with sharing class GenerateExcelControllerTest {
    @isTest
    public static void testGenerateExcelController() {

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

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert cotacaoMoeda;

        cotacaoMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Id = :cotacaoMoeda.Id];

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

        DescontoTipoCliente__c descontoTipoCliente = (DescontoTipoCliente__c)TestFactory.createSObject(new DescontoTipoCliente__c());
        insert descontoTipoCliente;

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

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        TabelaPreco__c tabelaPreco = (TabelaPreco__c)TestFactory.createSObject(
            new TabelaPreco__c(
                HierarquiaCliente__c = parentAccount.Id,
                Cliente__c           = account.Id,
                Regional__c          = regional.Id,
                Produto__c           = product.Id
            )
        );
        insert tabelaPreco;

        PoliticaDesconto__c politicaDesconto = (PoliticaDesconto__c)TestFactory.createSObject(
            new PoliticaDesconto__c(
                Hierarquia__c = parentAccount.Id,
                Conta__c      = account.Id,
                Regional__c   = regional.Id,
                Territorio__c = territorio.Id,
                Produto__c    = product.Id
            )
        );
        insert politicaDesconto;

        Order order1 = (Order)TestFactory.createSObject(
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
                SetorAtividade__c      = '10- Produtos',
                TaxaMedia__c           = cotacaoMoeda.TaxaMedia__c
            )
        );
        insert order1;

        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];
        
        OpportunityLineItem opportunityLineItem = (OpportunityLineItem)TestFactory.createSObject(
            new OpportunityLineItem(
                PricebookEntryId         = pricebookEntry.Id,
                Cultura__c               = cultura.Id,
                OpportunityId            = opportunity.Id,
                UsuarioConfirmacao__c    = user.Id,
                Product2Id               = product.Id,
                IdTabelaPreco__c         = tabelaPreco.Id,
                RecebedorMercadoria__c   = account.Id,
                IdDescontoTipoCliente__c = descontoTipoCliente.Id,
                IdPoliticaDesconto__c    = politicaDesconto.Id
            )
        );
        insert opportunityLineItem;

        OrderItem orderItem1 = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                OrderId                 = order1.Id,
                PricebookEntryId        = pricebookEntry.Id,
                Product2Id              = product.Id,
                Cultura__c              = cultura.Id,
                LocalNegocio__c         = localNegocio.Id,
                Quantity                = 10,
                QuantidadeConfirmada__c = 8,
                MotivoRecusaItem__c     = 'Z1'
            )
        );
        insert orderItem1;

        ProgramacaoEntrega__c programacaoEntrega1 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c        = opportunity.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                IdOpportunityLineITem__c = opportunityLineItem.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega1;
        ProgramacaoEntregaHelper.enableTrigger();
        
        PageReference pageRef = Page.ExcelGeneratorPage;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        pageRef.getParameters().put('Pe', String.valueOf(programacaoEntrega1.Id)); //needs to split by ;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);

        GenerateExcelController generateExcelController = new GenerateExcelController(sc);

        generateExcelController.getExcelData();

    }
}