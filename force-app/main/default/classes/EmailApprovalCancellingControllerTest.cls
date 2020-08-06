@isTest
global with sharing class EmailApprovalCancellingControllerTest {
    @isTest(SeeAllData=true)
    public static void getLineItemListTest() { 
        Account acc = (Account)TestFactory.createSObject(new Account());
        insert acc;

        List<Profile> profileList = [SELECT Id, name FROM Profile WHERE Name LIKE '%Diretoria%' OR Name LIKE '%Gerente%' LIMIT 10];
        List<User> userList = new List<User>();
        User comercialDirector, businessDirector, comercialManager, regionalManager;

        for (Profile p : profileList) {
            if(p.name == 'Diretoria Comercial') {
                comercialDirector = (User)TestFactory.createSObject(new User(ProfileId = p.id));
                userList.add(comercialDirector);
            }
            else if(p.name == 'Diretoria de Negócios') {
                businessDirector = (User)TestFactory.createSObject(new User(ProfileId = p.id));
                userList.add(businessDirector);
            }
            else if(p.name == 'Gerente de Desenvolvimento de Mercado') {
                comercialManager = (User)TestFactory.createSObject(new User(ProfileId = p.id));
                userList.add(comercialManager);
            }
            else if(p.name == 'Gerente Regional') {
                regionalManager = (User)TestFactory.createSObject(new User(ProfileId = p.id));
                userList.add(regionalManager);
            }
        }
        insert userList;

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c transportZoneDestination = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert transportZoneDestination;

        ZonaTransporte__c transportZoneOrigin = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert transportZoneOrigin;

        LocalNegocio__c localbusiness = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = transportZoneOrigin.Id
        ));
        insert localbusiness;
        
        Territorio__c territory = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = UserInfo.getUserId(),
            Gerente__c  = comercialManager.Id,
            Diretor__c  = comercialDirector.Id,
            Regional__c = regional.Id
        ));
        insert territory;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = UserInfo.getUserId(),
                GerenteRegional__c  = regionalManager.Id,
                DiretorComercial__c = businessDirector.Id,
                ZonaTransporte__c   = transportZoneDestination.Id,
                LocalNegocio__c     = localbusiness.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account acc1 = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = UserInfo.getUserId(),
                GerenteRegional__c    = regionalManager.Id,
                DiretorComercial__c   = businessDirector.Id,
                ZonaTransporte__c     = transportZoneDestination.Id,
                LocalNegocio__c       = localbusiness.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert acc1;

        Campanha__c campaign = (Campanha__c)TestFactory.createSObject(new Campanha__c());
        insert campaign;

        CondicaoPagamento__c paymentCondition = (CondicaoPagamento__c)TestFactory.createSObject(
            new CondicaoPagamento__c(
                ExternalId__c = 'CR00'
            )
        );
        insert paymentCondition;

        CotacaoMoeda__c coinCotation = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert coinCotation;

        Cultura__c culture = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        insert culture;

        Opportunity opp = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                LocalNegocio__c = localbusiness.Id,
                AccountId = acc1.Id,
                RecebedorMercadoria__c = acc1.Id,
                Campanha__c = campaign.Id,
                CondicaoPagamento__c = paymentCondition.Id,
                Cultura__c = culture.Id,
                ClienteAgenciador__c = acc1.Id,
                Territorio__c = territory.Id,
                Regional__c = regional.Id,
                GerenteRegional__c = regionalManager.Id,
                DiretorComercial__c = businessDirector.Id
            )
        );
        insert opp;

        Itinerario__c itinerary = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = transportZoneOrigin.ExternalId__c + '-' + transportZoneDestination.ExternalId__c,
                ZonaTransporteOrigem__c  = transportZoneOrigin.Id,
                ZonaTransporteDestino__c = transportZoneDestination.Id
            )
        );
        insert itinerary;

        Order order = (Order)TestFactory.createSObject(
            new Order(
                OpportunityId          = opp.Id,
                CondicaoPagamento__c   = paymentCondition.Id,
                AccountId              = acc1.Id,
                RecebedorMercadoria__c = acc1.Id,
                Territorio__c          = territory.Id,
                RTV__c                 = UserInfo.getUserId(),
                GerenteRegional__c     = regionalManager.Id,
                ClienteAgenciador__c   = acc1.Id,
                Itinerario__c          = itinerary.Id,
                SetorAtividade__c      = '10- Produtos'
            )
        );
        insert order;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;
        
 		ProgramacaoEntrega__c deliverySchedule = (ProgramacaoEntrega__c)TestFactory.createSObject(new ProgramacaoEntrega__c(
        	IdOportunidade__c = opp.id,
            EmissorOrdem__c	  = acc1.id,
			Produto__c               = product.Id,
            Territorio__c            = territory.Id,
            Cultura__c               = culture.Id,
            StatusSAP__c             = 'Não confirmado'
        ));
        ProgramacaoEntregaHelper.disableTrigger();
        insert deliverySchedule;
        ProgramacaoEntregaHelper.enableTrigger();


        SolicitacaoCancelamento__c cancellationRequest = (SolicitacaoCancelamento__c)TestFactory.createSObject(new SolicitacaoCancelamento__c(
            RecebedorOrdem__c    =   acc.id,
            EmissorOrdem__c      =   acc1.id,
            Oportunidade__c      =   opp.id,
            GerenteRegional__c   =   regionalManager.id,
            GerenteComercial__c  =   comercialManager.id,
            DiretorNegocios__c   =   businessDirector.id,
            DiretorComercial__c  =   comercialDirector.id

        ));
        insert cancellationRequest;

        Cancelamento__c cancellation = (Cancelamento__c)TestFactory.createSObject(new Cancelamento__c(
            SolicitacaoCancelamento__c = cancellationRequest.id,
                ValorTotal__c = 10,
                ValorTotalUSD__c = 10,
                QuantidadeProgramada__c = 2,
            IdOportunidade__c          = opp.id,
            ProgramacaoEntrega__c	   = deliverySchedule.id,
            Produto__c              = product.Id,
            EmissorOrdem__c         = acc1.Id,
            RecebedorOrdem__c       = acc.Id,
            GerenteComercial__c     = comercialManager.Id,
            DiretorComercial__c     = comercialDirector.Id,
            DiretorNegocios__c      = businessDirector.Id,
            GerenteRegional__c      = regionalManager.Id,
            Pedido__c               = order.Id,
            StatusSAP__c            = 'Faturado Parcial',
            NomeRTV__c				= 'RTV Name',
            TipoOrdem__c			= 'Normal',
            MotivoCancelamento__c   = 'Solicitação do Cliente',
            Descricao__c			= 'Description test'
            
        ));
        insert cancellation;

        EmailApprovalCancellingController emailController = new EmailApprovalCancellingController();
        emailController.canc = cancellationRequest;

        List<EmailApprovalCancellingLineItem> lineItemList = emailController.getLineItemList();
    }
}


/*emailController.itemList = new List<EmailApprovalCancellingLineItem> {
           new EmailApprovalCancellingLineItem((Cancelamento__c)TestFactory.createSObject(new Cancelamento__c()))
        };*/