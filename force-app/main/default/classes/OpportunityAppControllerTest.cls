@IsTest
public class OpportunityAppControllerTest {

    public static FINAL Id CLIENTE_RECORDTYPEID      = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();
    public static FINAL Id HIERARQUIA_RECORDTYPEID   = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId();

    @testSetup static void setup() {
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

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(
            new Territorio__c(
                RTV__c      = user.Id,
                Gerente__c  = user.Id,
                Diretor__c  = user.Id,
                Regional__c = regional.Id
            )
        );
        insert territorio;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                Name                = 'Account Parent Test',
                OwnerId             = user.Id,
                GerenteRegional__c  = user.Id,
                DiretorComercial__c = user.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId(),
                RatingPagamento__c  = 'A'
            )
        );
        insert parentAccount;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                Name                  = 'Account Test',
                OwnerId               = user.Id,
                Status__c             = 'Ativo',
                GerenteRegional__c    = user.Id,
                DiretorComercial__c   = user.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = CLIENTE_RECORDTYPEID,
                MatrizCredito__c      = parentAccount.Id
            )
        );
        insert account;

        TerritorioCliente__c accountTerritory = new TerritorioCliente__c(
            Conta__c              = account.Id,
            Territorio__c         = territorio.Id,
            VendaDireta__c        = true
        );
        insert accountTerritory;

        Campanha__c campanha = (Campanha__c)TestFactory.createSObject(new Campanha__c());
        insert campanha;

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
    }

    @isTest
    public static void instanceClassTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        Test.startTest();        
        
        new OpportunityAppController();

        PageReference pageRef = Page.OpportunityApp;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        new OpportunityAppController(sc);

        Test.stopTest();
    }

    @isTest
    public static void simulateApprovalProcessTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        // System.debug(JSON.serializePretty(
        Test.startTest();
        // System.assertEquals(false, OpportunityAppController.simulateApprovalProcess(opportunity.Id).hasErrors);
        opportunity.tipoOrdem__c = 'Bonificação';
        update opportunity;
        // System.assertEquals(false, OpportunityAppController.simulateApprovalProcess(opportunity.Id).hasErrors);
        Test.stopTest();    
        // );

    }

    @isTest
    public static void approveOpportunityTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.approveOpportunity(opportunity.Id).hasErrors);
        Test.stopTest();    
        // );

    }

    @isTest
    public static void cloneOpportunityTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.cloneOpportunity(opportunity.Id).hasErrors);
        Test.stopTest();    
        // );

    }

    @isTest
    public static void deleteOpportunityTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.deleteOpportunity(opportunity.Id).hasErrors);
        Test.stopTest();    
        // );

    }

    @isTest
    public static void getItineraryTest() {

        Itinerario__c itinerario                   = [SELECT Id, Name, TipoExpedicao__c From Itinerario__c LIMIT 1];
        LocalNegocio__c localNegocio               = [SELECT Id, Name From LocalNegocio__c LIMIT 1];

        List<Id> zonasTransporteId = new List<Id>();
        Set<String> zonasTransporteOrigemId = new Set<String>();
        for (ZonaTransporte__c zT : [SELECT Id, Name From ZonaTransporte__c]) {
            zonasTransporteId.add(zT.Id);
            zonasTransporteOrigemId.add(zT.Id);
        }
        
        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.getItinerary(zonasTransporteId, new Set<String>{itinerario.TipoExpedicao__c}, zonasTransporteOrigemId).keyset().isEmpty());
        Test.stopTest();    
        // );

    }

    @isTest
    public static void sendEmailClientTest() {
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.sendEmailClient(opportunity.Id).hasErrors);
        Test.stopTest();    
        // );

    }

    @isTest
    public static void upsertOpportunityTest() {

        Account account                            = [SELECT Id, Name, ListaPreco__c From Account WHERE RecordTypeId = :CLIENTE_RECORDTYPEID LIMIT 1];
        Itinerario__c itinerario                   = [SELECT Id, Name, TipoExpedicao__c From Itinerario__c LIMIT 1];
        Campanha__c campanha                       = [SELECT Id, Name, Moeda__c, Descricao__c, DataVigenciaInicial__c, DataVigenciaFinal__c From Campanha__c LIMIT 1];
        Territorio__c territorio                   = [SELECT Id, Name From Territorio__c LIMIT 1];
        LocalNegocio__c localNegocio               = [SELECT Id, Name From LocalNegocio__c LIMIT 1];
        Cultura__c cultura                         = [SELECT Id, Name From Cultura__c LIMIT 1];
        Product2 product                           = [SELECT Id, Name, Multiplicidade__c From Product2 LIMIT 1];
        TabelaFrete__c tabelaFrete                 = [SELECT Id, Name From TabelaFrete__c LIMIT 1];
        DescontoTipoCliente__c descontoTipoCliente = [SELECT Id, Name, Desconto__c, tipoCliente__c, dataVigenciaInicial__c, dataVigenciaFinal__c From DescontoTipoCliente__c LIMIT 1];
        OpportunityLineItem opportunityLineItem    = [SELECT Id, opportunity.Id, PricebookEntryId, Cultura__c, DataEntrega__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, PrecoLitro__c, Quantity, PrecoVendaSemJuros__c, Discount, DescontoMaximo__c, DescontoMinimo__c, DescontoRecomendado__c, PrecoListaReferencia__c, PrecoListaReferenciaUSD__c, Litros__c, Juros__c, Confirmado__c, DescontoTipoCliente__c, ValorFrete__c, TotalPrice, TotalItemComJuros__c, TotalItemSemjurosUSD__c, TotalItemComJurosUSD__c, PrazoInterno__c, Itinerario__c, PrecoVendasJuros__c, IdPoliticaDesconto__c, IdTabelaPreco__c, IdTabelaFrete__c, IdDescontoTipoCliente__c, DataConfirmacao__c, PrecoLista__c, DataVigenciaInicialDesconto__c, DataVigenciaFinalDesconto__c, IPI__c, TaxaDolar__c, PrecoVendaSemJurosUSD__c, PrecoVendasJurosUSD__c, ValorDescontoTipoClienteUSD__c, ValorFreteUSD__c, ValorJurosItem__c, ValorJurosItemUSD__c, ValorDescontoItem__c, ValorDescontoItemUSD__c, precoLitroUSD__c  FROM OpportunityLineItem];
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        
        OpportunityAppController.OpportunityDataRequest request = new OpportunityAppController.OpportunityDataRequest();
        request.id                       = opportunity.Id;
        request.interest                 = opportunity.JurosComercialFinanceiro__c;
        request.totalAmountInterest      = opportunity.ValorTotalMercadoriasRealSemIPI__c;
        // request.totalAmountDolar;
        request.totalAmountDolarInterest = opportunity.ValorTotalMercadoriasDolarSemIPI__c;
        request.shipmentCondition        = itinerario.TipoExpedicao__c;
        request.orderType                = opportunity.TipoOrdem__c;
        request.salesClassification      = opportunity.classificacaoVenda__c;
        request.orderReason              = opportunity.MotivoOrdem__c;
        request.orderNumber              = opportunity.NumeroPedidoCliente__c;
        request.receiverAccount          = opportunity.RecebedorMercadoria__c;
        request.shipperAccount           = opportunity.ClienteOrigemRemanejamento__c;
        request.selectedAccount          = opportunity.AccountId;
        request.selectedAccountName      = opportunity.account.Name;
        request.selectedCampaign         = opportunity.Campanha__c;
        request.selectedCurrency         = opportunity.Moeda__c;
        request.paymentCondition         = opportunity.CondicaoPagamento__c;
        request.vendorDueDate            = String.valueOf(opportunity.VencimentoVendor__c);
        request.obsInternal              = opportunity.ObservacaoInterna__c;
        request.obsLogistic              = opportunity.ObservacaoLogistica__c;
        request.obsPrint                 = opportunity.ObservacaoPDF__c;
        request.obsPrintNF               = opportunity.ObservacaoImpressaNF__c;
        request.culture                  = opportunity.Cultura__c;
        request.isAgencied               = opportunity.Agenciamento__c;
        request.priceReferenceDate       = String.valueOf(opportunity.DataReferenciaPreco__c);
        request.selectedBusinessPlace    = opportunity.LocalNegocio__c;
        request.interestStartDate        = String.valueOf(opportunity.DataInicioJuros__c);
        request.previousSelectedCampaign = opportunity.Campanha__c;

        DiscountByCustomerTypeData discount = new DiscountByCustomerTypeData(descontoTipoCliente);
        ShippingPolicyServiceData shipping = new ShippingPolicyServiceData(
            [SELECT Id, 
            (SELECT Id, Frete__c FROM VigenciaTabelaFrete__r)
            FROM TabelaFrete__c WHERE Id = :tabelaFrete.Id]);

        PriceAppData priceAppData = new PriceAppData(discount, shipping);

        request.priceAppData = priceAppData;

        OpportunityAppController.ProductDataRequest productDataRequest = new OpportunityAppController.ProductDataRequest();
        productDataRequest.id                             = product.Id;
        productDataRequest.opportunityId                  = opportunityLineItem.opportunity.Id;
        productDataRequest.itemId                         = opportunityLineItem.Id;
        productDataRequest.pbEntry                        = opportunityLineItem.PricebookEntryId;
        productDataRequest.culture                        = opportunityLineItem.Cultura__c;
        productDataRequest.deliveryDate                   = String.valueOf(opportunityLineItem.DataEntrega__c);
        productDataRequest.orderNumber                    = opportunityLineItem.NumeroPedidoCliente__c;
        productDataRequest.receiver                       = opportunityLineItem.RecebedorMercadoria__c;
        productDataRequest.pricePerLiter                  = opportunityLineItem.PrecoLitro__c;
        productDataRequest.quantity                       = opportunityLineItem.Quantity;
        productDataRequest.salesPrice                     = opportunityLineItem.PrecoVendaSemJuros__c;
        productDataRequest.discount                       = opportunityLineItem.Discount;
        // productDataRequest.total                          = opportunityLineItem.;
        productDataRequest.maxDiscount                    = opportunityLineItem.DescontoMaximo__c;
        productDataRequest.minimumDiscount                = opportunityLineItem.DescontoMinimo__c;
        productDataRequest.recommendedDiscount            = opportunityLineItem.DescontoRecomendado__c;
        productDataRequest.priceList                      = opportunityLineItem.PrecoListaReferencia__c;
        productDataRequest.priceListDolar                 = opportunityLineItem.PrecoListaReferenciaUSD__c;
        productDataRequest.liter                          = opportunityLineItem.Litros__c;
        productDataRequest.interest                       = opportunityLineItem.Juros__c;
        productDataRequest.confirmed                      = opportunityLineItem.Confirmado__c;
        productDataRequest.customerTypeDiscountValue      = opportunityLineItem.DescontoTipoCliente__c;
        productDataRequest.freightValue                   = opportunityLineItem.ValorFrete__c;
        productDataRequest.totalValue                     = opportunityLineItem.TotalPrice;
        productDataRequest.totalValueWithInterest         = opportunityLineItem.TotalItemComJuros__c;
        productDataRequest.totalValueDolar                = opportunityLineItem.TotalItemSemjurosUSD__c;
        productDataRequest.totalValueWithInterestDolar    = opportunityLineItem.TotalItemComJurosUSD__c;
        productDataRequest.internalDeadlineDays           = Integer.valueOf(opportunityLineItem.PrazoInterno__c);
        productDataRequest.itineraryDays                  = Integer.valueOf(opportunityLineItem.Itinerario__c);
        productDataRequest.salesPriceWithInterest         = opportunityLineItem.PrecoVendasJuros__c;
        productDataRequest.discountPolicyId               = opportunityLineItem.IdPoliticaDesconto__c;
        productDataRequest.priceEntryId                   = opportunityLineItem.IdTabelaPreco__c;
        productDataRequest.shippingTableId                = opportunityLineItem.IdTabelaFrete__c;
        productDataRequest.customerTypeDiscountId         = opportunityLineItem.IdDescontoTipoCliente__c;
        productDataRequest.confirmationDate               = String.valueOf(opportunityLineItem.DataConfirmacao__c);
        productDataRequest.priceFromTable                 = opportunityLineItem.PrecoLista__c;
        productDataRequest.initialDate                    = String.valueOf(opportunityLineItem.DataVigenciaInicialDesconto__c);
        productDataRequest.finishDate                     = String.valueOf(opportunityLineItem.DataVigenciaFinalDesconto__c);
        productDataRequest.ipiPercentage                  = opportunityLineItem.IPI__c;
        productDataRequest.dollarRate                     = opportunityLineItem.TaxaDolar__c;
        productDataRequest.multiplicity                   = product.Multiplicidade__c;
        productDataRequest.salesPriceDolar                = opportunityLineItem.PrecoVendaSemJurosUSD__c;
        productDataRequest.salesPriceWithInterestDolar    = opportunityLineItem.PrecoVendasJurosUSD__c;
        productDataRequest.customerTypeDiscountValueDolar = opportunityLineItem.ValorDescontoTipoClienteUSD__c;
        productDataRequest.freightValueDolar              = opportunityLineItem.ValorFreteUSD__c;
        productDataRequest.interestValue                  = opportunityLineItem.ValorJurosItem__c;
        productDataRequest.interestValueDolar             = opportunityLineItem.ValorJurosItemUSD__c;
        productDataRequest.discountValue                  = opportunityLineItem.ValorDescontoItem__c;
        productDataRequest.discountValueDolar             = opportunityLineItem.ValorDescontoItemUSD__c;
        productDataRequest.pricePerLiterDolar             = opportunityLineItem.precoLitroUSD__c;

        request.products = new List<OpportunityAppController.ProductDataRequest>{productDataRequest};

        TerritoryData territoryData = new TerritoryData(
            [SELECT Id, 
                    Name, 
                    NomeTerritorio__c, 
                    Regional__c,
                    Regional__r.ACS__c,
                    Rtv__c, 
                    Rtv__r.Name, 
                    Gerente__c, 
                    Gerente__r.Name, 
                    Diretor__c, 
                    Diretor__r.Name, 
                    Diretor__r.ManagerId, 
                    Diretor__r.Manager.Name
               FROM Territorio__c
              WHERE Id = :territorio.Id]
        );
        request.territoryData = territoryData;

        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.upsertOpportunity(request).hasErrors);
        Test.stopTest();    
        // ));

    }

    @isTest
    public static void getOpportunityAppProductDataTest() {

        Account account                            = [SELECT Id, Name, ListaPreco__c From Account WHERE RecordTypeId = :CLIENTE_RECORDTYPEID LIMIT 1];
        Itinerario__c itinerario                   = [SELECT Id, Name, TipoExpedicao__c From Itinerario__c LIMIT 1];
        Cultura__c cultura                         = [SELECT Id, Name From Cultura__c LIMIT 1];
        LocalNegocio__c localNegocio               = [SELECT Id, Name From LocalNegocio__c LIMIT 1];
        Opportunity opportunity                    = [SELECT Id, Name, JurosComercialFinanceiro__c, ValorTotalMercadoriasRealSemIPI__c, ValorTotalMercadoriasDolarSemIPI__c, TipoOrdem__c, classificacaoVenda__c, MotivoOrdem__c, NumeroPedidoCliente__c, RecebedorMercadoria__c, ClienteOrigemRemanejamento__c, AccountId, account.Name, Campanha__c, Moeda__c, CondicaoPagamento__c, VencimentoVendor__c, ObservacaoInterna__c, ObservacaoLogistica__c, ObservacaoPDF__c, ObservacaoImpressaNF__c, Cultura__c, Agenciamento__c, DataReferenciaPreco__c, LocalNegocio__c, DataInicioJuros__c From Opportunity LIMIT 1];

        
        OpportunityAppDataRequest opportunityAppDataRequest = new OpportunityAppDataRequest();
        opportunityAppDataRequest.accountId         = account.Id;
        opportunityAppDataRequest.receiverId        = account.Id;
        opportunityAppDataRequest.cultures          = new List<Id>{cultura.Id};
        opportunityAppDataRequest.shipmentCondition = itinerario.TipoExpedicao__c;
        opportunityAppDataRequest.businessPlaceId   = localNegocio.Id;
        
        // System.debug(JSON.serializePretty(
        Test.startTest();
        OpportunityHelper.disableTrigger();
        opportunity.stageName = 'Aprovado Cliente';
        update opportunity;
        OpportunityHelper.enableTrigger();
        System.assertEquals(false, OpportunityAppController.getOpportunityAppProductData(opportunityAppDataRequest).hasErrors);
        Test.stopTest();    
        // ));

    }
    
    @isTest
    public static void getBaseDataTest() {
        // System.debug(JSON.serializePretty(
        Test.startTest();
        System.assertEquals(false, OpportunityAppController.getBaseData().hasErrors);
        Test.stopTest();    
        // ));

    }

    @isTest
    public static void lookupTest() {

        Account account                            = [SELECT Id, Name, ListaPreco__c From Account WHERE RecordTypeId = :CLIENTE_RECORDTYPEID LIMIT 1];
        Territorio__c territorio                   = [SELECT Id, Name From Territorio__c LIMIT 1];
        Campanha__c campanha                       = [SELECT Id, Name, Moeda__c, Descricao__c, DataVigenciaInicial__c, DataVigenciaFinal__c From Campanha__c LIMIT 1];

        Test.startTest();
        
        String searchTerm = account.Name,
               tableName  = 'Account',
               fieldName  = 'ListaPreco__c';

        List<String> returningFields = new List<String>{'ExternalId__c', 'ListaPreco__c'};
        
        OpportunityAppController.LookupComponentRecordFilter lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        lookupComponentRecordFilter.fieldApiName = 'ListaPreco__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = '\'' + account.ListaPreco__c + '\'';
        List<OpportunityAppController.LookupComponentRecordFilter> lookupComponentRecordFilterList = new List<OpportunityAppController.LookupComponentRecordFilter>{};

        OpportunityAppController.RecordQueryRequest recordQueryRequest = new OpportunityAppController.RecordQueryRequest();
        recordQueryRequest.searchTerm = searchTerm;
        recordQueryRequest.tableName = 'Account';
        recordQueryRequest.filters = lookupComponentRecordFilterList;
        
        // System.debug(JSON.serializePretty(
        System.assertEquals(false, OpportunityAppController.searchAccount(recordQueryRequest).isEmpty());            
        // ));

        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);
        recordQueryRequest.filters = lookupComponentRecordFilterList;
        recordQueryRequest.searchTerm = 'Z1';
        recordQueryRequest.searchTarget = 'ListaPreco__c';
        recordQueryRequest.returnedFields = returningFields;

        // System.debug(JSON.serializePretty(
        System.assertEquals(false, OpportunityAppController.searchLookup(recordQueryRequest).isEmpty());            
        // ));
        
        recordQueryRequest.searchTerm = campanha.Descricao__c;
        lookupComponentRecordFilterList.clear();

        lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        
        lookupComponentRecordFilter.fieldApiName = 'moeda__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = '\'' + campanha.Moeda__c + '\'';
        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);

        lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        
        lookupComponentRecordFilter.fieldApiName = 'territory__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = territorio.Id;
        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);

        lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        
        lookupComponentRecordFilter.fieldApiName = 'datavigenciade__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = String.valueOf(campanha.DataVigenciaInicial__c);
        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);

        lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        
        lookupComponentRecordFilter.fieldApiName = 'datavigenciaate__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = String.valueOf(campanha.DataVigenciaFinal__c);
        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);

        lookupComponentRecordFilter = new OpportunityAppController.LookupComponentRecordFilter();
        
        lookupComponentRecordFilter.fieldApiName = 'conta__c';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = account.Id;
        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);

        recordQueryRequest.filters = lookupComponentRecordFilterList;
        System.debug(JSON.serializePretty(
            OpportunityAppController.searchCampaign(recordQueryRequest)
        ));

        Test.stopTest();

    }

    @isTest
    public static void getRemoteAllPaymentConditionsTest() {

        Test.startTest();
        OpportunityAppController.ResponsePaymentCondition respPaymentCondition = OpportunityAppController.getRemoteAllPaymentConditions(String.valueOf( System.today() ));
        Test.stopTest();    

        
    }

    @isTest
    public static void simulateApprovalProcess2Test() {

        Opportunity opp             = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityAppController.ApprovalProcessSimulationAppReturnedData respApprovalProcessSimulation = OpportunityAppController.simulateApprovalProcess(opp.Id);
        Test.stopTest();    

        
    }

}