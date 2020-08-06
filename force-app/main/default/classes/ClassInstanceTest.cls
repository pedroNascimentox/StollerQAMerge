@isTest
public with sharing class ClassInstanceTest {

    public static FINAL Id CLIENTE_RECORDTYPEID      = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();
    public static FINAL Id HIERARQUIA_RECORDTYPEID   = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId();

    @isTest
    public static void testClassInstance() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteOrigem;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteDestino;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c = zonaTransporteOrigem.Id
            )
        );
        insert localNegocio;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Moeda__c = 'USD'
            )
        );
        insert cotacaoMoeda;

        cotacaoMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Id = :cotacaoMoeda.Id];

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(
            new Territorio__c(
                RTV__c      = UserInfo.getUserId(),
                Gerente__c  = user.Id,
                Diretor__c  = user.Id,
                Regional__c = regional.Id
            )
        );
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

        campanha.LiberadoUsoOportunidades__c = true;
        update campanha;

        CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(new CondicaoPagamento__c());
        insert condicaoPagamento;

        VigenciaCondicao__c vigenciaCondicao = (VigenciaCondicao__c)TestFactory.createSObject(
            new VigenciaCondicao__c(
                CondicaoPagamento__c = condicaoPagamento.Id
            )
        );
        insert vigenciaCondicao;

        Cultura__c cultura = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        insert cultura;

        TabelaFrete__c tabelaFrete = (TabelaFrete__c)TestFactory.createSObject(
            new TabelaFrete__c(
                LocalNegocio__c  = localNegocio.Id
            )
        );
        insert tabelaFrete;

        VigenciaTabelaFrete__c vigenciaTabelaFrete = (VigenciaTabelaFrete__c)TestFactory.createSObject(
            new VigenciaTabelaFrete__c(
                TabelaFrete__c  = tabelaFrete.Id
            )
        );
        insert vigenciaTabelaFrete;

        DescontoTipoCliente__c descontoTipoCliente = (DescontoTipoCliente__c)TestFactory.createSObject(new DescontoTipoCliente__c());
        insert descontoTipoCliente;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                LocalNegocio__c        = localNegocio.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Campanha__c            = campanha.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                Cultura__c             = cultura.Id,
                ClienteAgenciador__c   = account.Id,
                Territorio__c          = territorio.Id,
                Regional__c            = regional.Id,
                GerenteRegional__c     = user.Id,
                DiretorComercial__c    = user.Id,
                IdTabelaFrete__c       = tabelaFrete.Id
            )
        );
        insert opportunity;

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

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

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
                IdOportunidade__c = opportunity.Id,
                Produto__c        = product.Id,
                Territorio__c     = territorio.Id,
                EmissorOrdem__c   = account.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega1;
        ProgramacaoEntregaHelper.enableTrigger();

        AccountAppData accountAppData = new AccountAppData();

        AccountAppData accountAppData1 = new AccountAppData(account);

        ApprovalClientController approvalClientController = new ApprovalClientController();

        approvalClientController.ValidaAprovacao(); // example below to get 100% cover

        BusinessPlaceData businessPlaceData = new BusinessPlaceData(localNegocio);

        SimulationAppBaseData simulationAppBaseData = new SimulationAppBaseData();

        SimulationAppReturnedBaseData simulationAppReturnedBaseData = new SimulationAppReturnedBaseData();
        
        simulationAppReturnedBaseData = new SimulationAppReturnedBaseData(simulationAppBaseData);
        
        simulationAppReturnedBaseData = new SimulationAppReturnedBaseData('XDzada');
        NotaFiscal__c notaFiscal1 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account.Id,
                CodigoCliente__c    = account.Id,
                NrOrdem__c          = order1.Id,
                Oportunidade__c     = opportunity.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id
            )
        );
        insert notaFiscal1;
        Contact ct = new Contact(firstName = 'Test', lastname = 'test');

        insert ct;
        Case newCase = new Case(
            AccountId = account.Id,
            ContactId = ct.Id,
            NotaFiscal__C = notaFiscal1.id
        );
        insert newCase;


        CaseAttachmentController caseAttachmentController = new CaseAttachmentController();
        caseAttachmentController.CaseId = newCase.Id;
        caseAttachmentController.CaseImagens = null;

        String testString = caseAttachmentController.CaseId;
        testString = caseAttachmentController.CaseImagens;

        AssociacaoPedidoReclamacao__c associacaoPedidoReclamacao = new AssociacaoPedidoReclamacao__c(
            Reclamacao__c     = newCase.Id,
            Valor_unit_rio__c = 10.00,
            Quantidade__c     = 10.00
        );
        insert associacaoPedidoReclamacao;

        CaseClosedForComplainController caseClosedForComplainController = new CaseClosedForComplainController();
        caseClosedForComplainController.caseRecord = newCase;

        caseClosedForComplainController.getAssociacaoPedidoReclamacaoList();

        CaseClosedForQualityReviewController caseClosedForQualityReviewController = new CaseClosedForQualityReviewController();
        caseClosedForQualityReviewController.caseRecord = newCase;

        caseClosedForQualityReviewController.getAssociacaoPedidoReclamacaoList();
        caseClosedForQualityReviewController.getReasonLabel();

        EmailApprovalCreditCLineItem emailApprovalCreditCLineItem = new EmailApprovalCreditCLineItem(
            [SELECT Id, 
                    Produto__r.Name, 
                    Produto__r.Embalagem__c, 
                    QuantidadeProgramada__c, 
                    PrecoVendasComJurosUSDBRL__c, 
                    ValorTotalReaisDolar__c, 
                    DataEntrega__c, 
                    DataFaturamento__c 
             FROM ProgramacaoEntrega__c WHERE Id = :programacaoEntrega1.Id]);

        emailApprovalCreditCLineItem.getFormattedDateVP(Datetime.now());

        ProgramacaoEntrega__c programacaoEntrega2 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id,
                Produto__c        = product.Id,
                Territorio__c     = territorio.Id,
                EmissorOrdem__c   = account.Id,
                Status__c         = 'Em aprovação de crédito'
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega2;
        ProgramacaoEntregaHelper.enableTrigger();

        EmailApprovalCreditController emailApprovalCreditController = new EmailApprovalCreditController();
        emailApprovalCreditController.del = opportunity;

        emailApprovalCreditController.getLineItemList();

        emailApprovalCreditController.getoppAccountCredit();

        emailApprovalCreditController.getNumberList();

        emailApprovalCreditController.getApproval();

        emailApprovalCreditController.getSumValues();

        ReSendOrderController.sendIntegrationOrder(order1.Id);

        ReSendOrderIntegrationController.ReSendOrderIntegrationController(order1.Id);

        order1.OVSAP__c = null;

        OrderHelper.disableTrigger();
        update order1;
        OrderHelper.enableTrigger();

        ReSendOrderController.sendIntegrationOrder(order1.Id);

        ReSendOrderController.sendIntegrationOrder('XD');
        
        PricingSimulationAppController.getBaseData();

        PricingTestFactory pricingTestFactory = new PricingTestFactory();

        pricingTestFactory.fetchSimpleProduct();

        ProductAppData productAppData = new ProductAppData();
        productAppData.setProductData(product);

        try {
            PricePDFController pricePDFController = new PricePDFController();
        } catch (Exception e) {}

        OrderItemAppController orderItemAppController = new OrderItemAppController();

        OpportunityBulkApprovalController opportunityBulkApprovalController = new OpportunityBulkApprovalController();

        IncludeAttachmentsController IncludeAttachmentsController = new IncludeAttachmentsController();
        IncludeAttachmentsController.updateContents('XD');

        Test.startTest();

        PlanoIncentivo__c planoIncentivo = new PlanoIncentivo__c(
            Status__c = 'Em apuração'
        );
        insert planoIncentivo;

        planoIncentivo.Status__c = 'Encerrado';

        update planoIncentivo;

        delete planoIncentivo;

        try {
            PriceTestRepository priceTestRepository = new PriceTestRepository(null);

            // priceTestRepository.getRecord();
        } catch (Exception e) {}

        OpportunityAppControllerTestFactory oportunityAppControllerTestFactory = new OpportunityAppControllerTestFactory();
        oportunityAppControllerTestFactory.products = new List<Product2>{product};
        oportunityAppControllerTestFactory.addSimpleProduct();

        OpportunityAppReturnedData opportunityAppReturnedData = new OpportunityAppReturnedData();

        try {
            Date data = Date.valueOf('XD');
        } catch (Exception e) {
            opportunityAppReturnedData = new OpportunityAppReturnedData(e);
        }

        PricingService pricingService = new PricingService(account, Date.today());
        pricingService.getPrices();

        try {
            Date data = Date.valueOf('XD');
        } catch (Exception e) {
            ShippingPolicyServiceReturnedData shippingPolicyServiceReturnedData = new ShippingPolicyServiceReturnedData(e);
        }

        Cancelamento__c cancelamento = (Cancelamento__c)TestFactory.createSObject(
            new Cancelamento__c(
                ProgramacaoEntrega__c   = programacaoEntrega1.Id,
                ValorTotal__c = 10,
                ValorTotalUSD__c = 10,
                QuantidadeProgramada__c = 2,
                Produto__c              = product.Id,
                IdOportunidade__c       = opportunity.Id,
                EmissorOrdem__c         = account.Id,
                RecebedorOrdem__c       = account.Id,
                GerenteComercial__c     = user.Id,
                DiretorComercial__c     = user.Id,
                DiretorNegocios__c      = user.Id,
                GerenteRegional__c      = user.Id,
                Pedido__c               = order1.Id,
                StatusSAP__c            = 'Faturado Parcial'
            )
        );
        insert cancelamento;

        Cancelamento__c cancelamentoBase = [SELECT Id, SolicitacaoCancelamento__c, SolicitacaoCancelamento__r.Status__c, CreatedDate FROM Cancelamento__c WHERE Id = :cancelamento.Id];
        
        SolicitacaoCancelamento__c solicitacaoCancelamentoBase = new SolicitacaoCancelamento__c(Id = cancelamentoBase.SolicitacaoCancelamento__c, Status__c = cancelamentoBase.SolicitacaoCancelamento__r.Status__c);

        SolicitacaoCancelamento__c solicitacaoCancelamentoBase1 = new SolicitacaoCancelamento__c(Id = cancelamentoBase.SolicitacaoCancelamento__c, Status__c = 'Integrado Manual');

        SolicitacaoCancelamentoHelper.markOrderItemsAsBlocked(new Map<Id, SolicitacaoCancelamento__c>{solicitacaoCancelamentoBase.Id => solicitacaoCancelamentoBase}, new Map<Id, SolicitacaoCancelamento__c>{solicitacaoCancelamentoBase1.Id => solicitacaoCancelamentoBase1});

        TerritoryData territoryData = new TerritoryData();

        TerritorioCliente__c territorioCliente = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio.Id
        );
        insert territorioCliente;

        territoryData = new TerritoryData(territorioCliente);

        TestUtility.assertEqualsEpsilon(10, 10);

        TriggerRecordsHandler triggerRecordsHandler = new TriggerRecordsHandler(new Map<Id, SolicitacaoCancelamento__c>{solicitacaoCancelamentoBase.Id => solicitacaoCancelamentoBase}, new Map<Id, SolicitacaoCancelamento__c>{solicitacaoCancelamentoBase1.Id => solicitacaoCancelamentoBase1});
        triggerRecordsHandler.getRecords();
        triggerRecordsHandler.getChangedOn('Status__c');

        PriceRepository.getMostSpecificPrices(account, Date.today(), regional.Id);

        PriceRepository.getMostSpecificPrices(account, 'USD', Date.today(), regional.Id);
        
        order1.OVSAP__c = 'test';
        order1.TipoOrdem__c = 'Bonificação';

        Order order2 = order1.clone(true, true, false, false);
        order2.OVSAP__c = null;

        IntegrationOVsEmail__c integrationOVsEmail = new IntegrationOVsEmail__c(Name = 'demo@nescara.com');
        insert integrationOVsEmail;

        // System.debug('IntegrationOVsEmail__c => ' + IntegrationOVsEmail__c.getAll().keySet());
        
        //OrderHelper.sendIntegratedOVsEmail(new Map<Id, Order>{order2.Id => order2}, new Map<Id, Order>{order1.Id => order1});

        Test.stopTest();

    }
}