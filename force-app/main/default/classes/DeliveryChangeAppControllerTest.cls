@isTest
public with sharing class DeliveryChangeAppControllerTest {
    @isTest
    public static void testDeliveryChangeAppController() {

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

        String rtvTerm = '%rtv%';
        Profile profileRtv = [SELECT Id FROM Profile WHERE Name Like :rtvTerm];
        
        User userRtv = (User)TestFactory.createSObject(
            new User(
                ProfileId = profileRtv.Id
            ));
        insert userRtv;

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

        CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(new CondicaoPagamento__c());
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

        Product2 product = (Product2)TestFactory.createSObject(new Product2(
            tipo__c = 'Defensivo'
        ));
        insert product;

        TabelaPreco__c tabelaPreco = (TabelaPreco__c)TestFactory.createSObject(new TabelaPreco__c(
            HierarquiaCliente__c = parentAccount.Id,
            Cliente__c           = account.Id,
            Regional__c          = regional.Id,
            Produto__c           = product.Id
        ));
        insert tabelaPreco;

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];

        OpportunityLineItem opportunityLineItem = (OpportunityLineItem)TestFactory.createSObject(
            new OpportunityLineItem(
                PricebookEntryId       = pricebookEntry.Id,
                Cultura__c             = cultura.Id,
                OpportunityId          = opportunity.Id,
                UsuarioConfirmacao__c  = user.Id,
                Product2Id             = product.Id,
                IdTabelaPreco__c       = tabelaPreco.Id,
                RecebedorMercadoria__c = account.Id
            )
        );
        insert opportunityLineItem;

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

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                DataEntrega__c           = Date.today().addDays(3),
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                Status__c                = 'Integrado',
                StatusSAP__c             = 'Confirmado',
                Confirmado__c            = true,
                GerenteRegional__c       = user.Id,
                DataIntegracao__c        = Date.Today()
            )
        );

        OrderItem oi = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                orderId = order.id,
                PricebookEntryId         = pricebookEntry.Id,
                Product2Id               = product.Id,
                MOtivoRecusaItem__c      = '',
                DataEntrega__c           = programacaoEntrega.DataEntrega__c,
                programacaoEntrega__c    = programacaoEntrega.id
            )
        );
        OrderItemHelper.disableTrigger();
        insert oi;
        OrderItemHelper.enableTrigger();

        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();

        ProgramacaoEntrega__c programacaoEntrega1 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                DataEntrega__c           = Date.today().addDays(5),
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                Status__c                = 'Integrado',
                StatusSAP__c             = 'Confirmado',
                Confirmado__c            = true,
                GerenteRegional__c       = user.Id,
                DataIntegracao__c        = Date.Today()
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega1;
        ProgramacaoEntregaHelper.enableTrigger();
        
        OrderItem oi1 = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                orderId = order.id,
                PricebookEntryId         = pricebookEntry.Id,
                Product2Id               = product.Id,
                MOtivoRecusaItem__c      = '',
                DataEntrega__c           = programacaoEntrega1.DataEntrega__c,
                programacaoEntrega__c    = programacaoEntrega1.id
            )
        );
        OrderItemHelper.disableTrigger();
        insert oi1;
        OrderItemHelper.enableTrigger();

        ProgramacaoEntrega__c programacaoEntrega2 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                DataEntrega__c           = Date.today().addDays(8),
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                Status__c                = 'Integrado',
                StatusSAP__c             = 'Confirmado',
                Confirmado__c            = true,
                GerenteRegional__c       = user.Id,
                DataIntegracao__c        = Date.Today()
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega2;
        ProgramacaoEntregaHelper.enableTrigger();
        
        OrderItem oi2 = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                orderId = order.id,
                PricebookEntryId         = pricebookEntry.Id,
                Product2Id               = product.Id,
                MOtivoRecusaItem__c      = '',
                DataEntrega__c           = programacaoEntrega2.DataEntrega__c,
                programacaoEntrega__c    = programacaoEntrega2.id
            )
        );
        OrderItemHelper.disableTrigger();
        insert oi2;
        OrderItemHelper.enableTrigger();

        
        PageReference pageRef = Page.DeliveryApp;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);

        PrazoConfirmacaoEntrega__c pce = new PrazoConfirmacaoEntrega__c(Name = 'PCE Test', Dias__c = 3);
        insert pce;

        CotacaoMoeda__c cm = new CotacaoMoeda__c(TaxaMedia__c = 1, Data__c = Date.Today().addDays(-1), ExternalId__c = '15841LLff4', Taxa__c = 1);
        insert cm;

        DeliveryChangeAppController.RequestDeliveryChangeData request = new DeliveryChangeAppController.RequestDeliveryChangeData();
        request.orderId = order.id;
        request.changeType = 'Total';
        request.changeReason = 'Erro RTV';
        request.description = 'Desc Test';
        request.listId  = new List<String>();
        request.listId.add(programacaoEntrega.id);
        request.listId.add(programacaoEntrega1.id);
        request.listId.add(programacaoEntrega2.id);

        DeliveryChangeAppController.DeliveryChangeData dcd = new DeliveryChangeAppController.DeliveryChangeData();
        dcd.id = programacaoEntrega.id;
        dcd.orderItemId = oi.id;
        dcd.oppCurrency = 'BRL';
        dcd.deliveryDate = String.valueOf(programacaoEntrega.DataEntrega__c);
        dcd.quantity = programacaoEntrega.quantidadeProgramada__c;
        dcd.billingDate = String.valueOf(Date.Today());
        dcd.totalValue = 500;
        dcd.totalValueDolar = 250;

        // DeliveryChangeAppController.DeliveryChangeData dcd1 = new DeliveryChangeAppController.DeliveryChangeData();
        // dcd1.id = programacaoEntrega1.id;
        // dcd1.orderItemId = oi1.id;
        // dcd1.oppCurrency = 'BRL';
        // dcd1.deliveryDate = String.valueOf(programacaoEntrega1.DataEntrega__c);
        // dcd1.quantity = programacaoEntrega1.quantidadeProgramada__c;
        // dcd1.billingDate = String.valueOf(Date.Today());
        // dcd1.totalValue = 500;
        // dcd1.totalValueDolar = 250;

        // DeliveryChangeAppController.DeliveryChangeData dcd2 = new DeliveryChangeAppController.DeliveryChangeData();
        // dcd2.id = programacaoEntrega2.id;
        // dcd2.orderItemId = oi2.id;
        // dcd2.oppCurrency = 'BRL';
        // dcd2.deliveryDate = String.valueOf(programacaoEntrega2.DataEntrega__c);
        // dcd2.quantity = programacaoEntrega2.quantidadeProgramada__c;
        // dcd2.billingDate = String.valueOf(Date.Today());
        // dcd2.totalValue = 500;
        // dcd2.totalValueDolar = 250;

        List<DeliveryChangeAppController.DeliveryChangeData> dcdList = new List<DeliveryChangeAppController.DeliveryChangeData>{
            dcd
        };

        request.listDeliveryChangeData = dcdList;

        Test.startTest();

        new DeliveryChangeAppController();
        new DeliveryChangeAppController(sc);
        System.assertEquals(false, DeliveryChangeAppController.getOpportunityListData().hasErrors);
        System.runAs(userRtv) {
            new DeliveryChangeAppController();
            System.assertEquals(false, DeliveryChangeAppController.getOpportunityListData().hasErrors);
        }
        DeliveryChangeAppController.RecordQueryRequest search1 = new DeliveryChangeAppController.RecordQueryRequest();
        DeliveryChangeAppController.LookupComponentRecordFilter filter1 = new DeliveryChangeAppController.LookupComponentRecordFilter();
        search1.searchTerm = account.Name;

        System.assertEquals(account.Id, DeliveryChangeAppController.searchAccount(search1)[0].id);

        filter1.fieldApiName = 'opportunityid';
        filter1.value = opportunity.Id;
        search1.filters = new List<DeliveryChangeAppController.LookupComponentRecordFilter>{filter1};

        System.assertEquals(account.Id, DeliveryChangeAppController.searchClientOpp(search1)[0].id);

        search1.tableName = 'Account';
        search1.searchTarget = 'ListaPreco__c;Name';
        search1.returnedFields = new List<String>{'ListaPreco__c'};
        
        filter1.operator = '=';
        filter1.fieldApiName = 'ListaPreco__c';
        filter1.value = '\'' + account.ListaPreco__c + '\'';
        search1.filters = new List<DeliveryChangeAppController.LookupComponentRecordFilter>{filter1};

        System.assertEquals(account.Id, DeliveryChangeAppController.searchLookup(search1)[0].id);

        System.assertEquals(false, DeliveryChangeAppController.getBaseData().hasErrors);
        System.assertEquals(false, DeliveryChangeAppController.getDeliveryData(opportunity.id).hasErrors);
        System.assertEquals(true, DeliveryChangeAppController.createChangeDelivery(request).hasErrors);        
        request.changeReason = 'Erro na confirmação';
        System.debug(JSON.serializePretty(DeliveryChangeAppController.createChangeDelivery(request)));
        System.assertEquals(false, DeliveryChangeAppController.createChangeDelivery(request).hasErrors);

        Test.stopTest();

    }
}