@IsTest
public class OpportunityAppDataTest {

    @TestSetup
    static void makeData(){

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

        Regional__c regional = new Regional__c(
            nomeRegional__c = 'Regional 1',
            externalId__c = 'r3g10n4l1'
        );
        insert regional;

        Territorio__c territory = new Territorio__c(
            nomeTerritorio__c = 'Territory',
            externalId__c = 't3rr1t0r10',
            gerente__c = manager.id,
            diretor__c = manager2.id,
            rtv__c = rtv.id,
            regional__c = regional.id
        );
        insert territory;

        ZonaTransporte__c originTransportZone = new ZonaTransporte__c(
            descricao__c  = 'Origin Transport Zone',
            externalId__c = '0r1g1n7r4n5'
        );
        ZonaTransporte__c destinationTransportZone = new ZonaTransporte__c(
            descricao__c  = 'Destination Transport Zone',
            externalId__c = 'd3571n4710n7r4n5'
        );
        List<ZonaTransporte__c> transportZones = new List<ZonaTransporte__c>{originTransportZone, destinationTransportZone};
        insert transportZones;

        LocalNegocio__c businessLocation = new LocalNegocio__c(
            codigo__c         = 'bu51n355',
            zonaTransporte__c = originTransportZone.id
        );
        insert businessLocation;

        Itinerario__c itinerary = new Itinerario__c(
            dias__c                  = 8,
            tipoExpedicao__c         = 'Lotação',
            zonaTransporteOrigem__c  = originTransportZone.id,
            zonaTransporteDestino__c = destinationTransportZone.id,
            externalId__c            = '171n3r4ry',
            internalexternalId__c    = originTransportZone.ExternalId__c+'_'+destinationTransportZone.ExternalId__c
        );
        insert itinerary;    
    }
    @IsTest
    public static void simpleTest(){

        Regional__c       regional                 = [SELECT id FROM Regional__c];
        Territorio__c     territory                = [SELECT id FROM Territorio__c];
        LocalNegocio__c   businessLocation         = [SELECT id FROM LocalNegocio__c WHERE codigo__c = 'bu51n355'];
        ZonaTransporte__c destinationTransportZone = [SELECT id FROM ZonaTransporte__c WHERE externalId__c = 'd3571n4710n7r4n5' LIMIT 1];

        OpportunityAppControllerTestFactory opportunityAppControllerTestFactory = new OpportunityAppControllerTestFactory();   

        Account account = opportunityAppControllerTestFactory.fetchAccount();
        account.zonaTransporte__c = destinationTransportZone.id;
        account.localNegocio__c = businessLocation.id;
        account.canaldistribuicao__c = '10';
        insert account;

        Date today = Date.today();

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        PricebookEntry pricebookEntry = [SELECT id FROM PricebookEntry WHERE product2Id = :product.id LIMIT 1];

        CondicaoPagamento__c validPaymentCondition = new CondicaoPagamento__c(
            descricao__c = '15 DIAS - À VISTA',
            dataVigenciaDe__c = today.addDays(-30),
            dataVigenciaAte__c = today.addDays(30),
            externalId__c = 'B00',
            dias__c = 15,
            jurosComercialFinanceiro__c = 1
        );
        insert validPaymentCondition;  

        Opportunity opportunity = new Opportunity(
            name = 'Last Opportunity',
            stageName = 'Aprovado Cliente',
            closeDate = Date.today().addDays(-15),
            regional__c = regional.id,
            territorio__c = territory.id,
            accountId = account.id,
            organizacaoVenda__c = '1000',
            pricebook2Id = Test.getStandardPricebookId(),
            condicaoPagamento__c = validPaymentCondition.id,
            jurosComercialFinanceiro__c = 10
        );
        insert opportunity;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            opportunityId = opportunity.id,
            quantity = 20,
            product2Id = product.id,
            unitPrice = 100,
            precoLitro__c = 3,
            discount = 2,
            Itinerario__c = 1000,
            dataFaturamento__c = today.addDays(5),
            dataEntrega__c = today.addDays(10)
        );
        insert opportunityLineItem;

        ApprovedItemDatePair approvedItemDate = new ApprovedItemDatePair([SELECT id, dataFaturamento__c, dataEntrega__c, Itinerario__c FROM OpportunityLineItem 
        WHERE id = :opportunityLineItem.id]);        

        ProductDetailsAppData productDetailsAppData = new ProductDetailsAppData([SELECT id, opportunityId, unitprice, precoVendaSemJurosBRLUSD__c,precoVendasJurosBRLUSD__c, precoLitroBRLUSD__c,  opportunity.jurosComercialFinanceiro__c,
         opportunity.condicaoPagamento__r.descricao__c, opportunity.CloseDate, quantity, product2Id, precoLitro__c, discount
         FROM OpportunityLineItem WHERE id  = :opportunityLineItem.Id]);

        TerritoryData territoryData = new TerritoryData([
            SELECT  regional__c, regional__r.ACS__c, id, name, rtv__c, rtv__r.name,
                    nomeTerritorio__c, gerente__c, gerente__r.name,
                    diretor__c, diretor__r.name, diretor__r.managerId,
                    diretor__r.manager.name
            FROM Territorio__c 
            WHERE id = :territory.id
        ]);

        TabelaFrete__c shippingTable = new TabelaFrete__c(
            dataVigenciaFinal__c = Date.today().addDays(5),
            dataVigenciaInicial__c = Date.today().addDays(-15),
            frete__c = 20.0,
            organizacaoVenda__c = 'Organização Vendas Teste',
            regiaoUF__c = 'SP',
            tipoFrete__c = 'Fracionado',
            localNegocio__c = businessLocation.id
        );
        insert shippingTable;

        VigenciaTabelaFrete__c shippingTableValidity = new VigenciaTabelaFrete__c(
            tabelaFrete__c = shippingTable.id,
            frete__c = 2,
            dataVigenciaDe__c = Date.today().addDays(-5),
            dataVigenciaAte__c = Date.today().addDays(5)
        );

        insert shippingTableValidity;

        shippingTable = [
            SELECT id, 
                (
                    SELECT id, frete__c
                    FROM VigenciaTabelaFrete__r
                )
            FROM TabelaFrete__c
            LIMIT 1
        ];

        ShippingPolicyServiceData shippingPoliceService = new ShippingPolicyServiceData(shippingTable);

        DescontoTipoCliente__c currentCustomerTypeDiscount = new DescontoTipoCliente__c(
            tipoCliente__c          = 'ZB',
            desconto__c             = 2.0,
            dataVigenciaInicial__c  = Date.today().addDays(-7),
            dataVigenciaFinal__c    = Date.today().addDays(9)
        );
        insert currentCustomerTypeDiscount;

        DiscountByCustomerTypeReturnedData discountByCustomer = new DiscountByCustomerTypeReturnedData(currentCustomerTypeDiscount);
        DiscountByCustomerTypeReturnedData emptyDiscountByCustomer = new DiscountByCustomerTypeReturnedData();
        DiscountByCustomerTypeReturnedData errorDiscountByCustomer = new DiscountByCustomerTypeReturnedData(new OpportunityAppController.OpportunityAppControllerException('Ocorreu um erro.'));
        
        PriceAppData priceAppData = new PriceAppData(discountByCustomer.data,shippingPoliceService);

        List<Date> unavailableDates = new List<Date>();
        unavailableDates.add(today);

        DeliveryAppData deliveryAppData = new DeliveryAppData(today,unavailableDates,10,5);

        ProductAppData productAppData = new ProductAppData(product,pricebookEntry.id,100,3,4,productDetailsAppData);
        List<ProductAppData> productAppDataList = new List<ProductAppData>{productAppData};

        PricingAppData newPricingAppData = new pricingAppData();
        newPricingAppData.setProductsData(productAppDataList);

        OpportunityAppData newOpportunityAppData = new OpportunityAppData();
        newOpportunityAppData.setPricingData(newPricingAppData);
        newOpportunityAppData.setDeliveryData(deliveryAppData);
        newOpportunityAppData.setProductsData(productAppDataList);
        newOpportunityAppData.setPriceData(priceAppData);
        newOpportunityAppData.setTerritoryData(territoryData);

    }
}