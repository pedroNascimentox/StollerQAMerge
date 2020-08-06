@IsTest
public class OpportunityLineItemHelperTest {

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

        Product2 product = (Product2)TestFactory.createSObject(new Product2(
            embalagem__c = 'normal'
        ));
        insert product;

        CondicaoPagamento__c validPaymentCondition = new CondicaoPagamento__c(
            descricao__c = '15 DIAS - À VISTA',
            dataVigenciaDe__c = today.addDays(-30),
            dataVigenciaAte__c = today.addDays(30),
            externalId__c = 'B00',
            dias__c = 15,
            jurosComercialFinanceiro__c = 1
        );
        insert validPaymentCondition;  

        Pricebook2 pricebook = new Pricebook2(
            // organizacaoVenda__c = '1000',
            isActive = true,
            name = 'pricebook test'
            // externalId__c = 'pr1c3b00k7357',
            // listaPreco__c = '123',
            // recordTypeId = Schema.SObjectType.Pricebook2.getRecordTypeInfosByDeveloperName().get('TabelaPreco').getRecordTypeId()
        );
        insert pricebook;

        PricebookEntry pricebookEntry = new PricebookEntry(
            unitPrice = 100.00,
            pricebook2Id = pricebook.Id,
            product2Id = product.Id,
            // externalId__c = 'pr1c3b00k3n7ry',
            isActive = true
        );
        insert pricebookEntry;

        ProductPriceEntry productPriceEntry = new productPriceEntry(pricebookEntry);

        Opportunity opportunity = new Opportunity(
            name = 'Last Opportunity',
            stageName = 'Aprovado Cliente',
            closeDate = Date.today().addDays(-15),
            regional__c = regional.id,
            territorio__c = territory.id,
            accountId = account.id,
            organizacaoVenda__c = '1000',
            pricebook2Id = pricebook.id,
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
            dataEntrega__c = today.addDays(10),
            confirmado__c = true
        );
        insert opportunityLineItem;

        opportunityLineItem.dataFaturamento__c = today.addDays(8);
        opportunityLineItem.dataEntrega__c = today.addDays(15);
        //update opportunityLineItem;
    }
}