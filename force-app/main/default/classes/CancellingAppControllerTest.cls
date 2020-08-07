@isTest
public with sharing class CancellingAppControllerTest {
    @isTest
    public static void testCancellingAppController() {

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
                Status__c        = 'Liberado'
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

        CancellingAppController.RequestDeliveryData requestDeliveryData = new CancellingAppController.RequestDeliveryData();

        CancellingAppController.DeliveryData deliveryData = new CancellingAppController.DeliveryData();
        deliveryData.id              = programacaoEntrega.Id;
        deliveryData.orderType       = programacaoEntrega.TipoOrdem__c;
        deliveryData.confirmed       = programacaoEntrega.Confirmado__c;
        deliveryData.deliveryDate    = String.valueOf(programacaoEntrega.DataEntrega__c);
        deliveryData.selectedAccount = programacaoEntrega.EmissorOrdem__c;
        deliveryData.receiver        = programacaoEntrega.RecebedorOrdem__c;
        deliveryData.shipper         = programacaoEntrega.ClienteOrigemRemanejamento__c;
        deliveryData.quantity        = programacaoEntrega.QuantidadeProgramada__c;
        deliveryData.confirmedDate   = String.valueOf(programacaoEntrega.DataConfirmacao__c);
        deliveryData.orderNumber     = programacaoEntrega.NumeroPedidoCliente__c;
        deliveryData.oppId           = programacaoEntrega.IdOportunidade__c;
        deliveryData.oppItemId       = programacaoEntrega.IdOpportunityLineItem__c;
        deliveryData.productId       = programacaoEntrega.Produto__c;
        deliveryData.liter           = programacaoEntrega.Litros__c;
        deliveryData.baseLiter       = product.Litragem__c;
        deliveryData.territoryData   = territoryData;
        deliveryData.itineraryDays   = Integer.valueOf(itinerario.Dias__c);

        requestDeliveryData.listDeliveryData = new List<CancellingAppController.DeliveryData>{deliveryData};

        CancellingAppController.getOpportunityListData();

        System.runAs(user1) {
            // System.debug('user1 => ' + user1);
            // System.debug('UserInfo.getName() => ' + UserInfo.getName());
            CancellingAppController.getOpportunityListData();
        }

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.upsertDeliveryData(requestDeliveryData);//.hasErrors);
        // ));

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.getBaseData();//.hasErrors);
        // ));

        CancellingAppController.CancellingData cancellingData = new CancellingAppController.CancellingData();
        cancellingData.deliveryRequestId     = programacaoEntrega.Id;
        cancellingData.cancellingType        = 'Total';
        cancellingData.cancellingReason      = 'Falta de produto';
        cancellingData.cancellingDescription = 'XD';
        cancellingData.quantity              = Integer.valueOf(programacaoEntrega.QuantidadeDisponivelSAP__c);

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            // CancellingAppController.insertCancelling(new List<CancellingAppController.CancellingData>{cancellingData});//.hasErrors);
        // ));

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.getDeliveryData(opportunity.Id);//.hasErrors);
        // ));
        
        String searchTerm = account.Name,
               tableName  = 'Account',
               fieldName  = 'ListaPreco__c';

        List<String> returningFields = new List<String>{'ExternalId__c', 'ListaPreco__c'};
        List<CancellingAppController.LookupComponentRecordFilter> lookupComponentRecordFilterList = new List<CancellingAppController.LookupComponentRecordFilter>();

        CancellingAppController.RecordQueryRequest recordQueryRequest = new CancellingAppController.RecordQueryRequest();
        recordQueryRequest.searchTerm = searchTerm;
        recordQueryRequest.tableName = 'Account';
        recordQueryRequest.filters = lookupComponentRecordFilterList;

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.searchAccount(recordQueryRequest);//.isEmpty());
        // ));
        
        CancellingAppController.LookupComponentRecordFilter lookupComponentRecordFilter = new CancellingAppController.LookupComponentRecordFilter();
        lookupComponentRecordFilter.fieldApiName = 'opportunityid';
        lookupComponentRecordFilter.operator = '=';
        lookupComponentRecordFilter.value = opportunity.Id;

        lookupComponentRecordFilterList.add(lookupComponentRecordFilter);
        recordQueryRequest.filters = lookupComponentRecordFilterList;

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.searchClientOpp(recordQueryRequest);//.isEmpty());
        // ));

        recordQueryRequest.searchTerm = 'Z1';
        recordQueryRequest.searchTarget = 'ListaPreco__c';
        recordQueryRequest.returnedFields = returningFields;

        lookupComponentRecordFilter.fieldApiName = 'CodigoIBGE__c';
        lookupComponentRecordFilter.value = '\'' + account.CodigoIBGE__c + '\'';

        // System.debug(JSON.serializePretty(
            // System.assertEquals(false, 
            CancellingAppController.searchLookup(recordQueryRequest);//.isEmpty());
        // ));

        new CancellingAppController();

        PageReference pageRef = Page.CancellingApp;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        new CancellingAppController(sc);

        CancellingAppBaseData cancellingAppBase= new CancellingAppBaseData();
        cancellingAppBase.fetchCancellingReasons();
        
        CancellingAppReturnedBaseData cancellingAppBasee = new CancellingAppReturnedBaseData(cancellingAppBase);
        CancellingAppReturnedBaseData cancellingAppBase1= new CancellingAppReturnedBaseData('Teste');

        CancellingResultReturnedData CancellingResultReturned= new CancellingResultReturnedData();
        CancellingResultReturnedData CancellingResultReturned1= new CancellingResultReturnedData('Teste');
        
        CancellingResultReturnedData CancellingResultReturnedE= new CancellingResultReturnedData(new CancellingAppController.CancellingAppControllerException('Teste'));

        CancellingTypeData CancellingType = new CancellingTypeData('Teste', 'Teste');
        CancellingTypeData CancellingType1 = new CancellingTypeData('Teste', 'Teste', true);

        CancellingAppController.RequestChunk requestChunk = new CancellingAppController.RequestChunk();
        requestChunk.today = '1571922329000';
        requestChunk.idDelivery = programacaoEntrega.Id;
        System.assertEquals(false, CancellingAppController.getOpportunityListDataChunk(requestChunk).hasErrors);

        //CancellingAppController.getOpportunityListDataOpp getOpp = new CancellingAppController.getOpportunityListDataOpp();
        

        System.assertEquals(false, CancellingAppController.getOpportunityListDataOpp(opportunity.Name).hasErrors);

        List<CancellingAppController.CancellingData> lstCancellingData = new List<CancellingAppController.CancellingData> {cancellingData};

        System.runAs(user1) {
            System.assertEquals(false, CancellingAppController.insertCancelling(lstCancellingData).hasErrors);
        }

    }
}