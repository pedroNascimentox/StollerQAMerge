@isTest
public with sharing class AssociacaoPedidoReclamacaoHelperTest {
    @isTest
    public static void testAssociacaoPedidoReclamacaoHelper() {

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
        User users = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert users;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = users.Id,
            Gerente__c  = users.Id,
            Diretor__c  = users.Id,
            Regional__c = regional.Id
        ));
        insert territorio;

        Territorio__c territorio1 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = users.Id,
            Gerente__c  = users.Id,
            Diretor__c  = users.Id,
            Regional__c = regional.Id
        ));
        insert territorio1;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = users.Id,
                GerenteRegional__c  = users.Id,
                DiretorComercial__c = users.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account accounts = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = users.Id,
                GerenteRegional__c    = users.Id,
                DiretorComercial__c   = users.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert accounts;
        
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
        
        Opportunity opportunitys = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                LocalNegocio__c = localNegocio.Id,
                AccountId = accounts.Id,
                RecebedorMercadoria__c = accounts.Id,
                Campanha__c = campanha.Id,
                CondicaoPagamento__c = condicaoPagamento.Id,
                Cultura__c = cultura.Id,
                ClienteAgenciador__c = accounts.Id,
                Territorio__c = territorio.Id,
                Regional__c = regional.Id,
                GerenteRegional__c = users.Id,
                DiretorComercial__c = users.Id
            )
        );
        insert opportunitys;

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                InternalExternalId__c    = zonaTransporteOrigem.ExternalId__c + '-' + zonaTransporteDestino.ExternalId__c,
                ZonaTransporteOrigem__c  = zonaTransporteOrigem.Id,
                ZonaTransporteDestino__c = zonaTransporteDestino.Id
            )
        );
        insert itinerario;

        Order orders = (Order)TestFactory.createSObject(
            new Order(
                OpportunityId          = opportunitys.Id,
                CondicaoPagamento__c   = condicaoPagamento.Id,
                AccountId              = accounts.Id,
                RecebedorMercadoria__c = accounts.Id,
                Territorio__c          = territorio.Id,
                RTV__c                 = users.Id,
                GerenteRegional__c     = users.Id,
                ClienteAgenciador__c   = accounts.Id,
                Itinerario__c          = itinerario.Id,
                SetorAtividade__c      = '10- Produtos'
            )
        );
        insert orders;
        NotaFiscal__c notaFiscal1 = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = accounts.Id,
                CodigoCliente__c    = accounts.Id,
                NrOrdem__c          = orders.Id,
                Oportunidade__c     = opportunitys.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = users.Id
            )
        );
        insert notaFiscal1;
        
        Contact ct = new Contact(firstName = 'Test', lastname = 'test');

        insert ct;
        Case newCase = new Case(
            AccountId = accounts.Id,
            ContactId = ct.Id,
            NotaFiscal__C = notaFiscal1.id
        );
        insert newCase;

        AssociacaoPedidoReclamacao__c associacaoPedidoReclamacao = new AssociacaoPedidoReclamacao__c(
            Reclamacao__c = newCase.Id
        );
        insert associacaoPedidoReclamacao;

        update associacaoPedidoReclamacao;


    }
}