@isTest
public class ProgramacaoEntregaHelperTest {
    @TestSetup
    public static void DeliveryHelperTest() {

        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundOrderMock());
        
        Id profileId = [SELECT id FROM Profile WHERE name = 'Administrador do Sistema'].Id;
        
        User manager = new User(
            username = 'alberto@stoller.com',
            lastName = 'Alberto',
            email = 'gerentealberto@stoller.com',
            alias = 'gealb',
            communityNickname = 'Ger. Alberto',
            emailEncodingKey = 'ISO-8859-1',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/New_York',
            profileId = profileId
        );
        
        User manager2 = new User(
            username = 'alcides@stoller.com',
            lastName = 'Alcides',
            email = 'diretoralcides@stoller.com',
            alias = 'diralc',
            communityNickname = 'Dir. Alcides',
            emailEncodingKey = 'ISO-8859-1',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/New_York',
            profileId = profileId
        );
        
        User rtv = new User(
            username = 'paulo@stoller.com',
            lastName = 'Paulo',
            email = 'rtvpaulo@stoller.com',
            alias = 'rtvpau',
            communityNickname = 'RTV Paulo',
            emailEncodingKey = 'ISO-8859-1',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/New_York',
            profileId = profileId
        );
        
        List<User> usersToInsert = new List<User>{manager, manager2, rtv};
        insert usersToInsert;
        
        Cultura__c cultura = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        insert cultura;
        
        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;
        
        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(
            new Territorio__c(
                Gerente__c  = manager.id,
                Diretor__c  = manager2.id,
                RTV__c      = rtv.id,
                Regional__c = regional.id
            )
        );
        insert territorio;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());

        List<ZonaTransporte__c> zonasTransporte = new List<ZonaTransporte__c>{zonaTransporteOrigem, zonaTransporteDestino};

        insert zonasTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c = zonaTransporteOrigem.Id
            )
        );
        insert localNegocio;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = manager.Id,
                GerenteRegional__c  = manager.Id,
                DiretorComercial__c = manager.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;
        
        // Account account = (Account)TestFactory.createSObject(
        //     new Account(
        //         LocalNegocio__c = localNegocio.id
        //     )
        // );
        // insert account;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = manager.Id,
                GerenteRegional__c    = manager.Id,
                DiretorComercial__c   = manager.Id,
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
                OwnerId               = manager.Id,
                GerenteRegional__c    = manager.Id,
                DiretorComercial__c   = manager.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert account2;
        
        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;
        
        // Pricebook2 pricebook = new Pricebook2(
        //     isActive = true,
        //     name = 'pricebook test'
        // );
        // insert pricebook;
        
        // PricebookEntry pricebookEntry = new PricebookEntry(
        //     unitPrice = 100.00,
        //     pricebook2Id = pricebook.Id,
        //     product2Id = product.Id,
        //     isActive = true
        // );
        // insert pricebookEntry;

        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];
        
        DescontoTipoCliente__c descontoTipoCliente = new DescontoTipoCliente__c(
            TipoCliente__c          = 'ZB',
            Desconto__c             = 2.0,
            DataVigenciaInicial__c  = Date.today().addDays(-7),
            DataVigenciaFinal__c    = Date.today().addDays(9)
        );
        insert descontoTipoCliente;
        
        Opportunity opportunity = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                Territorio__c        = territorio.id,
                StageName            = 'Iniciado',
                CloseDate            = Date.today(),
                Name                 = 'Test Opportunity',
                AccountId            = account.id,
                AprovadoComercial__c = true,
                ListaPreco__c        = 'Z1'
            )
        );
        insert opportunity;

        TabelaPreco__c tabelaPreco = (TabelaPreco__c)TestFactory.createSObject(new TabelaPreco__c(
            HierarquiaCliente__c = parentAccount.Id,
            Cliente__c           = account.Id,
            Regional__c          = regional.Id,
            Produto__c           = product.Id
        ));
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

        OpportunityLineItem opportunityLineItem = (OpportunityLineItem)TestFactory.createSObject(
            new OpportunityLineItem(
                PricebookEntryId         = pricebookEntry.Id,
                Cultura__c               = cultura.Id,
                OpportunityId            = opportunity.Id,
                UsuarioConfirmacao__c    = manager.Id,
                Product2Id               = product.Id,
                IdTabelaPreco__c         = tabelaPreco.Id,
                RecebedorMercadoria__c   = account.Id,
                IdDescontoTipoCliente__c = descontoTipoCliente.Id,
                IdPoliticaDesconto__c    = politicaDesconto.Id,
                UnitPrice                = 100,
                PrecoLitro__c            = 3,
                Discount                 = 2,
                PrazoInterno__c          = 2,
                Quantity                 = 20
            )
        );
        insert opportunityLineItem;
        
        CulturaProduto__c culturaProduto = new CulturaProduto__c(
            Cultura__c = cultura.Id,
            Produto__c = product.Id
        );
        insert culturaProduto;      

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

         CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(
            new CondicaoPagamento__c(
                ExternalId__c = 'CR00'
            )
        );
        insert condicaoPagamento;

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
                TaxaMedia__c           = 1.2
            )
        );
        insert order;

        NotaFiscal__c notaFiscal1 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account2.Id,
                CodigoCliente__c    = account2.Id,
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
                NotaFiscal__c     = notaFiscal1.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id,
                Litros__c         = 50

            )
        );
        notafiscalitemhelper.disabletrigger();
        insert notaFiscalItem1;
		notafiscalitemhelper.enabletriggeR();
        Apuracao__c apuracao = new Apuracao__c(
            NomeConta__c       = notaFiscal1.CodigoCliente__c,
            Territorio__c      = notaFiscal1.Territorio__c,
            Produto__c         = notaFiscalItem1.CodigoMaterial__c,
            DataFaturamento__c = notaFiscal1.DataNF__c,
            Atualizado__c      = false
        );
        insert apuracao;

         OrderItem orderItem1 = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                OrderId                 = order.Id,
                PricebookEntryId        = pricebookEntry.Id,
                Product2Id              = product.Id,
                Cultura__c              = cultura.Id,
                LocalNegocio__c         = localNegocio.Id,
                Quantity                = 10,
                QuantidadeConfirmada__c = 8,
                MotivoRecusaItem__c     = 'Z1',
                StatusGlobalItem__c     = 'B'
            )
        );
        insert orderItem1;

        PlanoIncentivo__c planoIncentivo = new PlanoIncentivo__c(
            Name          = 'Teste',
            Status__c     = 'Novo',
            Atualizado__c = false
        );
        insert planoIncentivo;

        ClientesPlanoIncentivos__c clientesPlanoIncentivos = new ClientesPlanoIncentivos__c(
            PlanoIncentivo__c = planoIncentivo.Id,
            ValorFaturamentoAnual__c = 1500.0,
            Moeda__c          = 'Dólar',
            NomeCliente__c    = parentAccount.Id
        );
        insert clientesPlanoIncentivos;
        
    }
    @isTest
    public static void confirmedDelivery(){   

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundOrderMock());
        
        cultura__c cultura = [SELECT id FROM cultura__c LIMIT 1];
        User manager = [SELECT id FROM User LIMIT 1];
        opportunity opportunity = [SELECT id FROM opportunity LIMIT 1];
        opportunityLineItem opportunityLineItem = [SELECT id FROM opportunityLineItem LIMIT 1];
        product2 product = [SELECT id FROM product2 LIMIT 1];
        account account = [SELECT id, LocalNegocio__c FROM account LIMIT 1];
        Apuracao__c apuracao = [SELECT Id FROM Apuracao__c LIMIT 1];
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
        ProgramacaoEntrega__c delivery = new ProgramacaoEntrega__c(
            Confirmado__c             = true,
            Cultura__c                = cultura.Id,
            DataEntrega__c            = System.Today(),
            DataFaturamento__c        = System.Today(),
            DataConfirmacao__c        = System.Today(),
            DescontoConcedido__c      = 0,
            DescontoTipoCliente__c    = 0,
            DiretorComercial__c       = manager.Id,
            EmissorOrdem__c           = account.Id,
            IdOportunidade__c         = opportunity.Id,
            IdOpportunityLineItem__c  = opportunityLineItem.Id,
            Juros__c                  = 1,
            Litros__c                 = 100,
            LocalNegocio__c           = account.LocalNegocio__c,
            NomeRTV__c                = 'teste',
            NomeUsuarioConfirmacao__c = 'teste',
            NumeroPedidoCliente__c    = '1',
            PrecoListaReferencia__c   = 20,
            PrecoVenda__c             = 20,
            PrecoVendaJuros__c        = 20,
            PrecoLitro__c             = 20,
            Produto__c                = product.Id,
            QuantidadeProgramada__c   = 100,
            RecebedorOrdem__c         = account.id,
            ValorFrete__c             = 20,
            ValorTotal__c             = 30,
            ValorUnitario__c          = 10,
            Status__c                 = 'Liberado',
            StatusSAP__c              = 'Não Confirmado',
            PrazoItinerario__c        = 10,
            Apuracao__c               = apuracao.Id
        );
        deliveryList.add(delivery);
        
        insert deliveryList;

        Test.stopTest();
    }

     @isTest
    public static void updateTotalPrice(){

        cultura__c cultura = [SELECT id FROM cultura__c LIMIT 1];
        User manager = [SELECT id FROM User LIMIT 1];
        opportunity opportunity = [SELECT id FROM opportunity LIMIT 1];
        opportunityLineItem opportunityLineItem = [SELECT id FROM opportunityLineItem LIMIT 1];
        product2 product = [SELECT id FROM product2 LIMIT 1];
        account account = [SELECT id, LocalNegocio__c FROM account LIMIT 1];
        Territorio__c territorio = [SELECT Id FROM Territorio__c LIMIT 1];
        ClientesPlanoIncentivos__c clientePlanoIncentivo = [SELECT Id FROM ClientesPlanoIncentivos__c LIMIT 1];
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
        ProgramacaoEntrega__c delivery = new ProgramacaoEntrega__c(
            Confirmado__c             = true,
            Cultura__c                = cultura.Id,
            DataEntrega__c            = System.Today(),
            DataFaturamento__c        = System.Today(),
            DataConfirmacao__c        = System.Today(),
            DescontoConcedido__c      = 0,
            DescontoTipoCliente__c    = 0,
            DiretorComercial__c       = manager.Id,
            EmissorOrdem__c           = account.Id,
            IdOportunidade__c         = opportunity.Id,
            IdOpportunityLineItem__c  = opportunityLineItem.Id,
            Juros__c                  = 1,
            Litros__c                 = 100,
            LocalNegocio__c           = account.LocalNegocio__c,
            NomeRTV__c                = 'teste',
            NomeUsuarioConfirmacao__c = 'teste',
            NumeroPedidoCliente__c    = '1',
            PrecoListaReferencia__c   = 20,
            PrecoVenda__c             = 20,
            PrecoVendaJuros__c        = 20,
            PrecoLitro__c             = 20,
            Produto__c                = product.Id,
            QuantidadeProgramada__c   = 100,
            RecebedorOrdem__c         = account.id,
            ValorFrete__c             = 20,
            ValorTotal__c             = 30,
            ValorUnitario__c          = 10,
            Status__c                 = 'Liberado',
            StatusSAP__c              = 'Não Confirmado',
            PrazoItinerario__c        = 10,
            TaxaDolar__c              = 5,
            Territorio__c             = territorio.Id,
            ClientePlanoIncentivo__c  = clientePlanoIncentivo.Id
        );
        deliveryList.add(delivery);

        insert deliveryList;

        delivery.QuantidadeProgramada__c = 90;
        update delivery;
        // update for delivery
        delivery.StatusSAP__c = 'Bloqueado Crédito';
        update delivery;


    }
   
}