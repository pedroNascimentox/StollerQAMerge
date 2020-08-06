@isTest
public with sharing class IntegrationInboundNotaFiscalTest {
    @isTest
    public static void testPost() {

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
        
        CotacaoMoeda__c cotacaoMoedaError = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Taxa__c = 5.00
            ));
        insert cotacaoMoedaError;

        CotacaoMoeda__c cotacaoMoedaError1 = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 3,
                Taxa__c = 15.00
            ));
        insert cotacaoMoedaError1;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today().addMonths(-1),
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
                DataNF__c           = Date.today().addMonths(-1)
            )
        );

        NotaFiscal__c notaFiscalError = (NotaFiscal__c)TestFactory.createSObject(new NotaFiscal__c());

        NotaFiscal__c notaFiscalError1 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account.Id,
                CodigoCliente__c    = account.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id,
                DataNF__c           = Date.today().addMonths(-1)
            )
        );

        NotaFiscalItem__c notaFiscalItem = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c     = notaFiscal.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id,
                Itinerario__c     = itinerario.Id
            )
        );

        NotaFiscalItem__c notaFiscalItemError = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c     = notaFiscal.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id,
                Itinerario__c     = itinerario.Id
            )
        );

        TipoNotaFiscalCS__c customTipo = new TipoNotaFiscalCS__c();
        customTipo.Tipo__c = 'ZREB, ZROB, CRB';
        insert customTipo;

        // NotaFiscal__c lookups
        lookups.put(account.Id, account.ExternalId__c);
        lookups.put(order.Id, order.OVSAP__c);
        lookups.put(regional.Id, regional.ExternalId__c);
        lookups.put(territorio.Id, territorio.ExternalId__c);
        lookups.put(user.Id, user.BusinessPartnerSAP__c);

        // NotaFiscalItem__c lookups
        lookups.put(product.Id, product.ExternalId__c);
        lookups.put(cultura.Id, cultura.ExternalId__c);
        lookups.put(itinerario.Id, itinerario.ExternalId__c);

        TemplateDataIntegrationFields.NotaFiscalINData deserializedNotaFiscal = new TemplateDataIntegrationFields.NotaFiscalINData(notaFiscal, lookups);
        TemplateDataIntegrationFields.NotaFiscalItemINData deserializedNotaFiscalItem = new TemplateDataIntegrationFields.NotaFiscalItemINData(notaFiscalItem, lookups);
        deserializedNotaFiscal.items = new List<TemplateDataIntegrationFields.NotaFiscalItemINData>{deserializedNotaFiscalItem};

        TemplateDataIntegrationFields.NotaFiscalINData deserializedNotaFiscalError = new TemplateDataIntegrationFields.NotaFiscalINData(notaFiscalError, lookups);

        TemplateDataIntegrationFields.NotaFiscalINData deserializedNotaFiscalError1 = new TemplateDataIntegrationFields.NotaFiscalINData(notaFiscalError1, lookups);
        deserializedNotaFiscalError1.items = new List<TemplateDataIntegrationFields.NotaFiscalItemINData>{deserializedNotaFiscalItem};

        Test.startTest();

        IntegrationUtils.setTestRequest(JSON.serialize(deserializedNotaFiscal));
        IntegrationInboundNotaFiscal.parseRequest();

        IntegrationUtils.setTestRequest(JSON.serialize(deserializedNotaFiscalError));
        IntegrationInboundNotaFiscal.parseRequest();
        
        IntegrationUtils.setTestRequest(JSON.serialize(deserializedNotaFiscalError1));
        IntegrationInboundNotaFiscal.parseRequest();

        TemplateDataIntegrationFields.NotaFiscalItemINData deserializedNotaFiscalItemError1 = new TemplateDataIntegrationFields.NotaFiscalItemINData(notaFiscalItemError, lookups);
        deserializedNotaFiscal.items = new List<TemplateDataIntegrationFields.NotaFiscalItemINData>{deserializedNotaFiscalItemError1};
        
        IntegrationUtils.setTestRequest(JSON.serialize(deserializedNotaFiscal));
        IntegrationInboundNotaFiscal.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundNotaFiscal.parseRequest();

        Test.stopTest();
        
        NotaFiscal__c[] receivedNotaFiscal = [SELECT Id FROM NotaFiscal__c LIMIT 10];

        System.assertEquals(1, receivedNotaFiscal.size());

    }
}