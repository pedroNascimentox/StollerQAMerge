@isTest
public with sharing class DeliveryAppControllerTest {
    @isTest
    public static void testDeliveryAppController() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());

        List<ZonaTransporte__c> zonasTransporte = new List<ZonaTransporte__c>{zonaTransporteOrigem, zonaTransporteDestino};
        insert zonasTransporte;

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

        List<Account> accounts = new List<Account>{account, parentAccount};
        insert accounts;

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
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                StatusSAP__c             = 'Não confirmado',
                Confirmado__c            = false,
                LocalNegocio__c          = localNegocio.Id
            )
        );

       

        ProgramacaoEntrega__c programacaoEntrega1 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                DataEntrega__c           = Date.today().addDays(5),
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                StatusSAP__c             = 'Não confirmado',
                Confirmado__c            = false
            )
        );

        ProgramacaoEntrega__c programacaoEntrega2 = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                DataEntrega__c           = Date.today().addDays(8),
                IdOportunidade__c        = opportunity.Id,
                IdOpportunityLineItem__c = opportunityLineItem.Id,
                Produto__c               = product.Id,
                Territorio__c            = territorio.Id,
                EmissorOrdem__c          = account.Id,
                Cultura__c               = cultura.Id,
                StatusSAP__c             = 'Não confirmado',
                Confirmado__c            = false
            )
        );

        List<ProgramacaoEntrega__c> programacaoEntregas = new List<ProgramacaoEntrega__c>{programacaoEntrega,programacaoEntrega1, programacaoEntrega2};

        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntregas;
        ProgramacaoEntregaHelper.enableTrigger();
      
        Test.startTest();
        new DeliveryAppController();

        PageReference pageRef = Page.DeliveryApp;
        pageRef.getParameters().put('id', String.valueOf(opportunity.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        new DeliveryAppController(sc);

        // System.debug('DeliveryAppController.getOpportunityListData() => ' + JSON.serializePretty(
            System.assertEquals(false, DeliveryAppController.getOpportunityListDataOpp(opportunity.NumeroOportunidade__c).hasErrors);
            System.assertEquals(false, DeliveryAppController.getOpportunityListData().hasErrors);
            System.runAs(userRtv) {
                new DeliveryAppController();
                System.assertEquals(false, DeliveryAppController.getOpportunityListData().hasErrors);
                System.assertEquals(false, DeliveryAppController.getOpportunityListDataOpp(opportunity.NumeroOportunidade__c).hasErrors);
            }
        // ));

        // System.debug('DeliveryAppController.getBaseData() => ' + JSON.serializePretty(
            System.assertEquals(false, DeliveryAppController.getBaseData().hasErrors);
        // ));

        // System.debug('DeliveryAppController.getDeliveryData() => ' + JSON.serializePretty(
            // System.assertEquals(false, DeliveryAppController.getDeliveryData(opportunity.Id).hasErrors);
        // ));

        DeliveryAppController.RecordQueryRequest search1 = new DeliveryAppController.RecordQueryRequest();
        DeliveryAppController.LookupComponentRecordFilter filter1 = new DeliveryAppController.LookupComponentRecordFilter();
        search1.searchTerm = account.Name;

        // System.debug('DeliveryAppController.searchAccount() => ' + JSON.serializePretty(
            System.assertEquals(account.Id, DeliveryAppController.searchAccount(search1)[0].id);
        // ));

        filter1.fieldApiName = 'opportunityid';
        filter1.value = opportunity.Id;
        search1.filters = new List<DeliveryAppController.LookupComponentRecordFilter>{filter1};

        // System.debug('DeliveryAppController.searchClientOpp() => ' + JSON.serializePretty(
            System.assertEquals(account.Id, DeliveryAppController.searchClientOpp(search1)[0].id);
        // ));

        search1.tableName = 'Account';
        search1.searchTarget = 'ListaPreco__c;Name';
        search1.returnedFields = new List<String>{'ListaPreco__c'};
        
        filter1.operator = '=';
        filter1.fieldApiName = 'ListaPreco__c';
        filter1.value = '\'' + account.ListaPreco__c + '\'';
        search1.filters = new List<DeliveryAppController.LookupComponentRecordFilter>{filter1};

        // System.debug('DeliveryAppController.searchLookup() => ' + JSON.serializePretty(
            System.assertEquals(account.Id, DeliveryAppController.searchLookup(search1)[0].id);
        // ));

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

        ProgramacaoEntrega__c baseProgramacaoEntrega = [SELECT Id,
                                                               TipoOrdem__c,
                                                               Confirmado__c,
                                                               DataEntrega__c,
                                                               EmissorOrdem__c,
                                                               RecebedorOrdem__c,
                                                               ClienteOrigemRemanejamento__c,
                                                               QuantidadeProgramada__c,
                                                               DataConfirmacao__c,
                                                               NumeroPedidoCliente__c,
                                                               IdOportunidade__c,
                                                               IdOpportunityLineItem__c,
                                                               Litros__c,
                                                               Produto__c,
                                                               Produto__r.Litragem__c,
                                                               DataFaturamento__c
                                                          FROM ProgramacaoEntrega__c
                                                         WHERE Id = :programacaoEntrega.Id];

        // ProgramacaoEntrega__c baseProgramacaoEntrega1 = [SELECT Id,
        //                                                        TipoOrdem__c,
        //                                                        Confirmado__c,
        //                                                        DataEntrega__c,
        //                                                        EmissorOrdem__c,
        //                                                        RecebedorOrdem__c,
        //                                                        ClienteOrigemRemanejamento__c,
        //                                                        QuantidadeProgramada__c,
        //                                                        DataConfirmacao__c,
        //                                                        NumeroPedidoCliente__c,
        //                                                        IdOportunidade__c,
        //                                                        IdOpportunityLineItem__c,
        //                                                        Litros__c,
        //                                                        Produto__c,
        //                                                        Produto__r.Litragem__c,
        //                                                        DataFaturamento__c
        //                                                   FROM ProgramacaoEntrega__c
        //                                                  WHERE Id = :programacaoEntrega1.Id];

        // ProgramacaoEntrega__c baseProgramacaoEntrega2 = [SELECT Id,
        //                                                        TipoOrdem__c,
        //                                                        Confirmado__c,
        //                                                        DataEntrega__c,
        //                                                        EmissorOrdem__c,
        //                                                        RecebedorOrdem__c,
        //                                                        ClienteOrigemRemanejamento__c,
        //                                                        QuantidadeProgramada__c,
        //                                                        DataConfirmacao__c,
        //                                                        NumeroPedidoCliente__c,
        //                                                        IdOportunidade__c,
        //                                                        IdOpportunityLineItem__c,
        //                                                        Litros__c,
        //                                                        Produto__c,
        //                                                        Produto__r.Litragem__c,
        //                                                        DataFaturamento__c
        //                                                   FROM ProgramacaoEntrega__c
        //                                                  WHERE Id = :programacaoEntrega2.Id];

        DeliveryAppController.DeliveryData deliveryData = new DeliveryAppController.DeliveryData();
        deliveryData.id              = baseProgramacaoEntrega.Id;
        deliveryData.orderType       = baseProgramacaoEntrega.TipoOrdem__c;
        deliveryData.confirmed       = baseProgramacaoEntrega.Confirmado__c;
        deliveryData.deliveryDate    = String.valueOf(baseProgramacaoEntrega.DataEntrega__c);
        deliveryData.selectedAccount = baseProgramacaoEntrega.EmissorOrdem__c;
        deliveryData.receiver        = baseProgramacaoEntrega.RecebedorOrdem__c;
        deliveryData.shipper         = baseProgramacaoEntrega.ClienteOrigemRemanejamento__c;
        deliveryData.quantity        = baseProgramacaoEntrega.QuantidadeProgramada__c;
        deliveryData.confirmedDate   = String.valueOf(baseProgramacaoEntrega.DataConfirmacao__c);
        deliveryData.orderNumber     = baseProgramacaoEntrega.NumeroPedidoCliente__c;
        deliveryData.oppId           = baseProgramacaoEntrega.IdOportunidade__c;
        deliveryData.oppItemId       = baseProgramacaoEntrega.IdOpportunityLineItem__c;
        deliveryData.productId       = baseProgramacaoEntrega.Produto__c;
        deliveryData.liter           = baseProgramacaoEntrega.Litros__c;
        deliveryData.baseLiter       = baseProgramacaoEntrega.Produto__r.Litragem__c;
        deliveryData.territoryData   = territoryData;
        deliveryData.itineraryDays   = Integer.valueOf(itinerario.Dias__c);

        // DeliveryAppController.DeliveryData deliveryData1 = new DeliveryAppController.DeliveryData();
        // deliveryData1.id              = baseProgramacaoEntrega1.Id;
        // deliveryData1.orderType       = baseProgramacaoEntrega1.TipoOrdem__c;
        // deliveryData1.confirmed       = baseProgramacaoEntrega1.Confirmado__c;
        // deliveryData1.deliveryDate    = String.valueOf(baseProgramacaoEntrega1.DataEntrega__c);
        // deliveryData1.selectedAccount = baseProgramacaoEntrega1.EmissorOrdem__c;
        // deliveryData1.receiver        = baseProgramacaoEntrega1.RecebedorOrdem__c;
        // deliveryData1.shipper         = baseProgramacaoEntrega1.ClienteOrigemRemanejamento__c;
        // deliveryData1.quantity        = baseProgramacaoEntrega1.QuantidadeProgramada__c;
        // deliveryData1.confirmedDate   = String.valueOf(baseProgramacaoEntrega1.DataConfirmacao__c);
        // deliveryData1.orderNumber     = baseProgramacaoEntrega1.NumeroPedidoCliente__c;
        // deliveryData1.oppId           = baseProgramacaoEntrega1.IdOportunidade__c;
        // deliveryData1.oppItemId       = baseProgramacaoEntrega1.IdOpportunityLineItem__c;
        // deliveryData1.productId       = baseProgramacaoEntrega1.Produto__c;
        // deliveryData1.liter           = baseProgramacaoEntrega1.Litros__c;
        // deliveryData1.baseLiter       = baseProgramacaoEntrega1.Produto__r.Litragem__c;
        // deliveryData1.territoryData   = territoryData;
        // deliveryData1.itineraryDays   = Integer.valueOf(itinerario.Dias__c);

        // DeliveryAppController.DeliveryData deliveryData2 = new DeliveryAppController.DeliveryData();
        // deliveryData2.id              = baseProgramacaoEntrega2.Id;
        // deliveryData2.orderType       = baseProgramacaoEntrega2.TipoOrdem__c;
        // deliveryData2.confirmed       = baseProgramacaoEntrega2.Confirmado__c;
        // deliveryData2.deliveryDate    = String.valueOf(baseProgramacaoEntrega2.DataEntrega__c);
        // deliveryData2.selectedAccount = baseProgramacaoEntrega2.EmissorOrdem__c;
        // deliveryData2.receiver        = baseProgramacaoEntrega2.RecebedorOrdem__c;
        // deliveryData2.shipper         = baseProgramacaoEntrega2.ClienteOrigemRemanejamento__c;
        // deliveryData2.quantity        = baseProgramacaoEntrega2.QuantidadeProgramada__c;
        // deliveryData2.confirmedDate   = String.valueOf(baseProgramacaoEntrega2.DataConfirmacao__c);
        // deliveryData2.orderNumber     = baseProgramacaoEntrega2.NumeroPedidoCliente__c;
        // deliveryData2.oppId           = baseProgramacaoEntrega2.IdOportunidade__c;
        // deliveryData2.oppItemId       = baseProgramacaoEntrega2.IdOpportunityLineItem__c;
        // deliveryData2.productId       = baseProgramacaoEntrega2.Produto__c;
        // deliveryData2.liter           = baseProgramacaoEntrega2.Litros__c;
        // deliveryData2.baseLiter       = baseProgramacaoEntrega2.Produto__r.Litragem__c;
        // deliveryData2.territoryData   = null;
        // deliveryData2.itineraryDays   = Integer.valueOf(itinerario.Dias__c);

        DeliveryAppController.RequestDeliveryData request = new DeliveryAppController.RequestDeliveryData();
        request.oppId            = opportunity.Id;
        request.listToDelete     = new List<String>{programacaoEntrega1.Id};
        request.listProductsId   = new List<String>();
        request.listDeliveryId   = new List<String>{programacaoEntrega.Id, programacaoEntrega1.Id};
        request.listDeliveryData = new List<DeliveryAppController.DeliveryData>{deliveryData};
        // System.debug('DeliveryAppController.upsertDeliveryData() => ' + JSON.serializePretty(
            System.assertEquals(false, DeliveryAppController.upsertDeliveryData(request).hasErrors);
        // ));

        // System.debug(JSON.serializePretty(
            System.assertEquals(false, DeliveryAppController.getBaseDeliveryData(opportunity.Id).hasErrors);
        // ));

        DeliveryAppController.RequestBusinessData requestBusinessData = new DeliveryAppController.RequestBusinessData();
        requestBusinessData.emitterId           = account.Id;
        // requestBusinessData.receiverId          = 
        requestBusinessData.businessPlaceId     = localNegocio.Id;
        requestBusinessData.expeditionCondition = itinerario.TipoExpedicao__c;

        // System.debug(JSON.serializePretty(
            System.assertEquals(false, DeliveryAppController.getDeliveryData(requestBusinessData).hasErrors);

        DeliveryAppController.RequestChunk requestChunk = new DeliveryAppController.RequestChunk();
        requestChunk.today = '1571922329000';
        requestChunk.idDelivery = programacaoEntrega.Id;

        System.assertEquals(false, DeliveryAppController.getOpportunityListDataChunk(requestChunk).hasErrors);
        // ));
        Test.stopTest();
    }
}