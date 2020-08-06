@isTest
public with sharing class BatchOrderItemTaxaMediaTest {
    @isTest
    public static void testUpdateTaxa() {

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

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 1,
                Taxa__c = 20.00
            ));
        insert cotacaoMoeda;

        CotacaoMoeda__c cotacaoMoeda1 = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 3
            ));
        insert cotacaoMoeda1;

        CotacaoMoeda__c cotacaoMoedaBase = [SELECT Id, Taxa__c, TaxaMedia__c FROM CotacaoMoeda__c WHERE Id = :cotacaoMoeda.Id];

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
                SetorAtividade__c      = '10- Produtos',
                TaxaMedia__c           = cotacaoMoedaBase.TaxaMedia__c
            )
        );
        insert order;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

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

        NotaFiscal__c notaFiscal2 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account2.Id,
                CodigoCliente__c    = account2.Id,
                NrOrdem__c          = order.Id,
                Oportunidade__c     = opportunity.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id,
                DataNF__c           = Date.today().addMonths(1)
            )
        );
        insert notaFiscal2;
        
        NotaFiscalItem__c notaFiscalItem1 = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c     = notaFiscal1.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id,
                Litros__c         = 50
            )
        );

        NotaFiscalItemHelper.disableTrigger();
        insert notaFiscalItem1;
        NotaFiscalItemHelper.enableTrigger();
        
        NotaFiscalItem__c notaFiscalItem2 = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c     = notaFiscal2.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id,
                Litros__c         = 20
            )
        );

        NotaFiscalItemHelper.disableTrigger();
        insert notaFiscalItem2;
        NotaFiscalItemHelper.enableTrigger();

        Apuracao__c apuracao = new Apuracao__c(
            NomeConta__c       = notaFiscal1.CodigoCliente__c,
            Territorio__c      = notaFiscal1.Territorio__c,
            Produto__c         = notaFiscalItem1.CodigoMaterial__c,
            DataFaturamento__c = notaFiscal1.DataNF__c,
            Atualizado__c      = false
        );
        insert apuracao;

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id,
                Produto__c        = product.Id,
                Territorio__c     = territorio.Id,
                EmissorOrdem__c   = account.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();

        ProgramacaoEntrega__c programacaoEntrega1 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c   = opportunity.Id,
                Produto__c          = product.Id,
                Territorio__c       = territorio.Id,
                EmissorOrdem__c     = account.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega1;
        ProgramacaoEntregaHelper.enableTrigger();

        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];

        OrderItem newOrderItem = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                PricebookEntryId = pricebookEntry.Id,
                OrderId          = order.Id,
                Product2Id       = product.Id,
                Cultura__c       = cultura.Id,
                LocalNegocio__c  = localNegocio.Id,
                StatusSAP__c     = 'Cancelado'
            )
        );
        insert newOrderItem;

        OrderItem newOrderItem1 = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                PricebookEntryId    = pricebookEntry.Id,
                OrderId             = order.Id,
                Product2Id          = product.Id,
                Cultura__c          = cultura.Id,
                LocalNegocio__c     = localNegocio.Id,
                StatusSAP__c        = 'Confirmado',
                StatusGlobalItem__c = 'C'
            )
        );
        insert newOrderItem1;

        LancamentoContabil__c lancamentoContabil = (LancamentoContabil__c)TestFactory.createSObject(
            new LancamentoContabil__c(
                NomeConta__c = account.Id,
                Produto__c   = product.Id
            )
        );
        insert lancamentoContabil;

        Escoamento__c escoamento = (Escoamento__c)TestFactory.createSObject(
            new Escoamento__c(
                Produto__c     = product.Id,
                NomeCliente__c = account.Id,
                Quantidade__c  = 50,
                Territorio__c  = territorio.Id
            )
        );
        EscoamentoHelper.disableTrigger();
        insert escoamento;
        EscoamentoHelper.enableTrigger();

        Meta__c meta = new Meta__c(
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

        BatchOrderItemTaxaMedia batch = new BatchOrderItemTaxaMedia();
        batch.execute(null, Database.query(batch.start(null).getQuery()));
        batch.finish(null);

        OrderItem orderItemBase = [SELECT Id, ValorTotalUSD__c, ValorTotal__c FROM OrderItem LIMIT 1];

        System.assertEquals(orderItemBase.ValorTotal__c / cotacaoMoedaBase.TaxaMedia__c, orderItemBase.ValorTotalUSD__c);
        
    }

    @isTest
    public static void testSchedule() {

        Test.startTest();
        
        List<CronTrigger> schedule = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                        FROM CronTrigger 
                                       WHERE CronJobDetail.Name = 'Update Item do Pedido Taxa Média'];
        
        String jobId;
        if (schedule.size() == 0){
            jobId = BatchOrderItemTaxaMedia.setSchedule();
        } else {
            System.abortJob(schedule[0].Id);
            jobId = BatchOrderItemTaxaMedia.setSchedule();
        }
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                            FROM CronTrigger 
                           WHERE Id = :jobId];

        Test.stopTest();

        System.assertEquals('0 0 * * * ? *', ct.CronExpression);
        System.assertEquals(Datetime.now().addHours(1).hour(), ct.NextFireTime.hour());
    }
}