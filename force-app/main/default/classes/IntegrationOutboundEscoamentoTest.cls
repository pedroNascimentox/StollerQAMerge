@isTest
public with sharing class IntegrationOutboundEscoamentoTest {

    @TestSetup
    static void setup() {

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
                SetorAtividade__c      = '10- Produtos'
            )
        );
        insert order;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();
        
        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c = :product.ExternalId__c];
        
        CotacaoMoeda__c cotacaoMoedaError = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert cotacaoMoedaError;

        CotacaoMoeda__c cotacaoMoedaError1 = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 3
            ));
        insert cotacaoMoedaError1;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.today() - 1,
                Taxa__c = 20.00
            ));
        insert cotacaoMoeda;

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
        
        NotaFiscalItem__c notaFiscalItem1 = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c       = notaFiscal1.Id,
                CodigoMaterial__c   = product.Id,
                Cultura__c          = cultura.Id,
                Litros__c           = 27
            )
        );
        insert notaFiscalItem1;

        Escoamento__c escoamento1 = 
            new Escoamento__c(
                Quantidade__c  = 50,
                Territorio__c = territorio.Id,
                NomeCliente__c = account.Id,
                Produto__c          = product.Id,
                // RSocial__c          = account.Id,
                QuantidadeLitros__c = 13
            
        );
        EscoamentoHelper.disableTrigger();
        insert escoamento1;
        EscoamentoHelper.enableTrigger();

        Escoamento__c escoamentoError1 = 
            new Escoamento__c(
                Quantidade__c  = 100,
                Territorio__c = territorio.Id,
                NomeCliente__c= account.Id,
                Produto__c          = product.Id,
                // RSocial__c          = account.Id,
                QuantidadeLitros__c = 14/*,
                DescricaoTerritorio__c = 'dataError'*/
                // need to change the field to put the same value and check on mock later
            
        );
        EscoamentoHelper.disableTrigger();
        insert escoamentoError1;
        EscoamentoHelper.enableTrigger();

        Escoamento__c escoamentoError2 = 
            new Escoamento__c(
                Quantidade__c  = 150,
                Territorio__c = territorio.Id,
                NomeCliente__c = account.Id,
                Produto__c          = product.Id,
                // RSocial__c          = account.Id,
                QuantidadeLitros__c = 20/*,
                DescricaoTerritorio__c = 'requestError'*/
                // need to change the field to put the same value and check on mock later
            
        );
        EscoamentoHelper.disableTrigger();
        insert escoamentoError2;
        EscoamentoHelper.enableTrigger();

    }
    
    @isTest
    public static void sendTest() {
        Test.setMock(HttpCalloutMock.class, new IntegrationOutboundEscoamentoMock());
        ApuracaoHelper.disableTrigger();
        for(Escoamento__c esc : [SELECT Id FROM Escoamento__c LIMIT 1]){
            IntegrationOutboundEscoamento.sendEscoamentoTrigger(new Set<Id>{esc.id});
            
        Test.startTest();
        Test.stopTest();
        }
        ApuracaoHelper.enableTrigger();
        /*

        Escoamento__c[] escoamentoList = [SELECT Id FROM Escoamento__c WHERE StatusIntegracao__c = 'Enviado'];

        System.assertEquals(1, escoamentoList.size());

        Escoamento__c[] escoamentoErrorList = [SELECT Id FROM Escoamento__c WHERE StatusIntegracao__c = 'Erro no envio'];

        System.assertEquals(2, escoamentoErrorList.size());
        */

    }
}