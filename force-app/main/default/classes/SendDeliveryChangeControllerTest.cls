@isTest
public with sharing class SendDeliveryChangeControllerTest {
    @isTest
    public static void testController() {

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

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user;

        Profile[] profiles = [SELECT Id, Name FROM Profile ORDER BY CreatedDate DESC];
        Profile defaultUserProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Usuário Padrão'];
        // Integer num = 3;
        // System.debug('profiles => ' + profiles);
        // System.debug('profiles[' + num + '] => ' + profiles[num]);
        User user1 = (User)TestFactory.createSObject(
            new User(
                ProfileId = defaultUserProfile.Id
            ));
        insert user1;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user1.Id,
            Gerente__c  = user1.Id,
            Diretor__c  = user1.Id,
            Regional__c = regional.Id
        ));
        insert territorio;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = user1.Id,
                GerenteRegional__c  = user1.Id,
                DiretorComercial__c = user1.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = user1.Id,
                GerenteRegional__c    = user1.Id,
                DiretorComercial__c   = user1.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                tipoCliente__c        = 'ZE',
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
                LocalNegocio__c        = localNegocio.Id,
                AccountId              = account.Id,
                RecebedorMercadoria__c = account.Id,
                Campanha__c            = campanha.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                Cultura__c             = cultura.Id,
                ClienteAgenciador__c   = account.Id,
                Territorio__c          = territorio.Id,
                Regional__c            = regional.Id,
                GerenteRegional__c     = user1.Id,
                DiretorComercial__c    = user1.Id
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
                RTV__c                 = user1.Id,
                GerenteRegional__c     = user1.Id,
                ClienteAgenciador__c   = account.Id,
                Itinerario__c          = itinerario.Id,
                SetorAtividade__c      = '10- Produtos'
            )
        );
        insert order;

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
        
        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];

        OpportunityLineItem opportunityLineItem = (OpportunityLineItem)TestFactory.createSObject(
            new OpportunityLineItem(
                PricebookEntryId       = pricebookEntry.Id,
                Cultura__c             = cultura.Id,
                OpportunityId          = opportunity.Id,
                UsuarioConfirmacao__c  = user1.Id,
                Product2Id             = product.Id,
                IdTabelaPreco__c       = tabelaPreco.Id,
                RecebedorMercadoria__c = account.Id
            )
        );
        insert opportunityLineItem;

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
                GerenteRegional__c       = user1.Id,
                DataIntegracao__c        = Date.Today()
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();

        OrderItem newOrderItem = (OrderItem)TestFactory.createSObject(
            new OrderItem(
                PricebookEntryId = pricebookEntry.Id,
                OrderId          = order.Id,
                Product2Id       = product.Id,
                Cultura__c       = cultura.Id,
                LocalNegocio__c  = localNegocio.Id,
                Status__c        = 'Liberado',
                ValorUnitarioComJuros__c = 1564
            )
        );
        OrderItemHelper.disableTrigger();
        insert newOrderItem;
        OrderItemHelper.enableTrigger();

        TerritoryData territoryData = new TerritoryData(
            [SELECT Id, 
                    Name, 
                    NomeTerritorio__c, 
                    Regional__c,
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

        AlteracaoDataEntrega__c alteracaoDataEntrega = new AlteracaoDataEntrega__c(
            Status__c = 'Iniciado',
            GerenteRegional__c = territorio.Gerente__c,
            Moeda__c = 'BRL',
            EmissorOrdem__r = account,
            IdOportunidade__c = opportunity.Id
        );
        insert alteracaoDataEntrega;

        AlteracaoDataEntregaItem__c alteracaoDataEntregaItem = new AlteracaoDataEntregaItem__c(
            AlteracaoDataEntrega__c = alteracaoDataEntrega.Id,
            ItemPedido__c           = newOrderItem.Id,
            ProgramacaoEntrega__c   = programacaoEntrega.Id,
            Produto__c = product.id,
            DataEntregaOriginal__c = Date.Today(),
            DataEntregaNova__c = Date.Today(),
            QuantidadeAlterada__c = 1,
            Moeda__c = 'BRL',
            ValorBRL__c = 1585,
            ValorUSD__c = 745
        );
        insert alteracaoDataEntregaItem;

        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
        submitRequest.setComments('submit by createChangeDelivery');
        submitRequest.setObjectId(alteracaoDataEntrega.Id);

        submitRequest.setProcessDefinitionNameOrId('SoliAltDataProgramacaEntrega');

        System.debug('submitRequest => ' + submitRequest);

        Approval.ProcessResult processResult = Approval.process(submitRequest);
        
        new sendDeliveryChangeController();

        PageReference pageRef = Page.CancellingApp;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        new sendDeliveryChangeController(sc);

        System.debug(sendDeliveryChangeController.approveProcessPage(alteracaoDataEntrega.id, 'This is a test'));

        sendDeliveryChangeController.approveProcessPage(alteracaoDataEntrega.id, 'This is a test');
        sendDeliveryChangeController.rejectedProcessPage(alteracaoDataEntrega.id, 'This is a test');

    }
}