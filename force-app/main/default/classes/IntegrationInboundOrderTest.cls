@isTest
public with sharing class IntegrationInboundOrderTest {
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
                Itinerario__c          = itinerario.Id
            )
        );

        Order orderError = (Order)TestFactory.createSObject(
            new Order(
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = user.Id,
                GerenteRegional__c     = user.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id
            )
        );

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        OrderItem newOrderItem = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                Product2Id              = product.Id,
                Cultura__c              = cultura.Id,
                LocalNegocio__c         = localNegocio.Id,
                Quantity                = 10,
                QuantidadeConfirmada__c = 8
            )
        );

        OrderItem newOrderItemError = (OrderItem)TestFactory.createSObject(new OrderItem());

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

        OrderItem newOrderItem1 = (OrderItem)TestFactory.createSObject(
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
        insert newOrderItem1;
        
        lookups.put(condicaoPagamento.Id, condicaoPagamento.ExternalId__c);
        lookups.put(opportunity.Id, opportunity.NumeroOportunidade__c);
        lookups.put(product.Id, product.ExternalId__c);
        lookups.put(account.Id, account.ExternalId__c);
        lookups.put(territorio.Id, territorio.ExternalId__c);
        lookups.put(user.Id, user.BusinessPartnerSAP__c);
        lookups.put(itinerario.Id, itinerario.ExternalId__c);
        lookups.put(cultura.Id, cultura.ExternalId__c);
        lookups.put(localNegocio.Id, localNegocio.Codigo__c);

        TemplateDataIntegrationFields.OrderINData deserializedOrder = new TemplateDataIntegrationFields.OrderINData(order, lookups);
        TemplateDataIntegrationFields.OrderItemINData deserializedOrderItem = new TemplateDataIntegrationFields.OrderItemINData(newOrderItem, lookups);
        deserializedOrder.items = new List<TemplateDataIntegrationFields.OrderItemINData>{deserializedOrderItem};

        TemplateDataIntegrationFields.OrderINData deserializedOrder1 = new TemplateDataIntegrationFields.OrderINData(order1, lookups);
        TemplateDataIntegrationFields.OrderItemINData deserializedOrderItem1 = new TemplateDataIntegrationFields.OrderItemINData(newOrderItem1, lookups);
        deserializedOrder1.items = new List<TemplateDataIntegrationFields.OrderItemINData>{deserializedOrderItem1};

        IntegrationUtils.setTestRequest(JSON.serialize(deserializedOrder));
        IntegrationInboundOrder.parseRequest();

        Test.startTest();

        IntegrationUtils.setTestRequest(JSON.serialize(deserializedOrder1));
        IntegrationInboundOrder.parseRequest();

        TemplateDataIntegrationFields.OrderINData deserializedOrderError = new TemplateDataIntegrationFields.OrderINData(orderError, lookups);
        
        IntegrationUtils.setTestRequest(JSON.serialize(deserializedOrderError));
        IntegrationInboundOrder.parseRequest();

        deserializedOrderError.items = new List<TemplateDataIntegrationFields.OrderItemINData>{deserializedOrderItem};

        IntegrationUtils.setTestRequest(JSON.serialize(deserializedOrderError));
        IntegrationInboundOrder.parseRequest();

        TemplateDataIntegrationFields.OrderItemINData deserializedOrderItemError = new TemplateDataIntegrationFields.OrderItemINData(newOrderItemError, lookups);
        deserializedOrder.items = new List<TemplateDataIntegrationFields.OrderItemINData>{deserializedOrderItemError};

        Test.stopTest();
        IntegrationUtils.setTestRequest(JSON.serialize(deserializedOrder));
        IntegrationInboundOrder.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundOrder.parseRequest();


        // List<Order> orderList = [SELECT Id FROM Order LIMIT 10];

        System.assertEquals(1, [SELECT COUNT() FROM ProgramacaoEntrega__c LIMIT 10]);
        // System.assertEquals(2, orderList.size());

    }
}