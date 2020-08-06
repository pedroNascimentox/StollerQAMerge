@isTest
public with sharing class BatchSendFailedIntegrationTest {

    @TestSetup
    static void setup() {

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

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert cotacaoMoeda;

        cotacaoMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Id = :cotacaoMoeda.Id];

        Order order = (Order)TestFactory.createSObject(
            new Order(
                SetorAtividade__c      = '10- Produtos',
                OpportunityId          = opportunity.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = user.Id,
                GerenteRegional__c     = user.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id,
                TaxaMedia__c           = cotacaoMoeda.TaxaMedia__c
            )
        );
        insert order;

        Order orderError1 = (Order)TestFactory.createSObject(
            new Order(
                Description            = 'dataError',
                SetorAtividade__c      = '10- Produtos',
                OpportunityId          = opportunity.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = user.Id,
                GerenteRegional__c     = user.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id,
                TaxaMedia__c           = cotacaoMoeda.TaxaMedia__c
            )
        );
        insert orderError1;

        Order orderError2 = (Order)TestFactory.createSObject(
            new Order(
                Description            = 'requestError',
                SetorAtividade__c      = '10- Produtos',
                OpportunityId          = opportunity.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = user.Id,
                GerenteRegional__c     = user.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id,
                TaxaMedia__c           = cotacaoMoeda.TaxaMedia__c
            )
        );
        insert orderError2;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];

        OrderItem orderItem = (OrderItem)TestFactory.createSObject(new OrderItem(
            PricebookEntryId      = pricebookEntry.Id,
            OrderId               = order.Id,
            Product2Id            = product.Id,
            Cultura__c            = cultura.Id,
            LocalNegocio__c       = localNegocio.Id,
            ProgramacaoEntrega__c = programacaoEntrega.Id
        ));
        insert orderItem;

        ProgramacaoEntrega__c programacaoEntrega1 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega1;
        ProgramacaoEntregaHelper.enableTrigger();

        OrderItem orderItem1 = (OrderItem)TestFactory.createSObject(new OrderItem(
            PricebookEntryId      = pricebookEntry.Id,
            OrderId               = order.Id,
            Product2Id            = product.Id,
            Cultura__c            = cultura.Id,
            LocalNegocio__c       = localNegocio.Id,
            ProgramacaoEntrega__c = programacaoEntrega1.Id
        ));
        insert orderItem1;

        ProgramacaoEntrega__c programacaoEntrega2 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega2;
        ProgramacaoEntregaHelper.enableTrigger();

        OrderItem orderItem2 = (OrderItem)TestFactory.createSObject(new OrderItem(
            PricebookEntryId      = pricebookEntry.Id,
            OrderId               = order.Id,
            Product2Id            = product.Id,
            Cultura__c            = cultura.Id,
            LocalNegocio__c       = localNegocio.Id,
            ProgramacaoEntrega__c = programacaoEntrega2.Id
        ));
        insert orderItem2;

        ProgramacaoEntrega__c programacaoEntrega3 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega3;
        ProgramacaoEntregaHelper.enableTrigger();

        OrderItem orderItem3 = (OrderItem)TestFactory.createSObject(new OrderItem(
            PricebookEntryId      = pricebookEntry.Id,
            OrderId               = order.Id,
            Product2Id            = product.Id,
            Cultura__c            = cultura.Id,
            LocalNegocio__c       = localNegocio.Id,
            ProgramacaoEntrega__c = programacaoEntrega3.Id
        ));
        insert orderItem3;

        ProgramacaoEntrega__c programacaoEntrega4 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega4;
        ProgramacaoEntregaHelper.enableTrigger();

        OrderItem orderItem4 = (OrderItem)TestFactory.createSObject(new OrderItem(
            PricebookEntryId      = pricebookEntry.Id,
            OrderId               = order.Id,
            Product2Id            = product.Id,
            Cultura__c            = cultura.Id,
            LocalNegocio__c       = localNegocio.Id,
            ProgramacaoEntrega__c = programacaoEntrega4.Id
        ));
        insert orderItem4;

        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundOrderMock());

    }
    @isTest
    public static void testSendFailedIntegration() {

        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundOrderMock());
        List<Id> listId = new List<Id>();
        for(Order ord : [SELECT id FROM Order ORDER BY Id DESC]){
            listId.add(ord.id);
        }
        Test.startTest();
        IntegrationOutboundOrder.sendOrderTrigger(listId);
        
        Test.stopTest();
        callBatch();


    }

    @future
    public static void callBatch() {
        BatchSendFailedIntegration batch = new BatchSendFailedIntegration();
        batch.execute(null, Database.query(batch.start(null).getQuery()));
        batch.finish(null);

        // Order[] orderList = [SELECT Id, StatusIntegracao__c FROM Order LIMIT 10];
        // System.debug('orderList => ' + orderList);

        System.assertEquals(2, [SELECT COUNT() FROM Order WHERE StatusIntegracao__c = :Label.TentativaExcedida LIMIT 10]);

    }
    @isTest
    public static void testSchedule() {

        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundOrderMock());
        List<Id> listId = new List<Id>();
        for(Order ord : [SELECT id FROM Order ORDER BY Id DESC]){
            listId.add(ord.id);
        }
        IntegrationOutboundOrder.sendOrderTrigger(listId);
        Test.startTest();
        
        List<CronTrigger> schedule = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                        FROM CronTrigger 
                                       WHERE CronJobDetail.Name = 'Order Integration 60'];
        
        List<CronTrigger> schedule1 = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                         FROM CronTrigger 
                                        WHERE CronJobDetail.Name = 'Order Integration 30'];
        
        String jobId;
        
        if (schedule.size() == 0){
            jobId = BatchSendFailedIntegration.setSchedule();
        } else {
            System.abortJob(schedule[0].Id);
            System.abortJob(schedule1[0].Id);
            jobId = BatchSendFailedIntegration.setSchedule();
        }
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                            FROM CronTrigger 
                           WHERE Id = :jobId];

        Test.stopTest();

        System.assertEquals('0 0 * * * ? *', ct.CronExpression);
        System.assertEquals(Datetime.now().addHours(1).hour(), ct.NextFireTime.hour());
    }
}