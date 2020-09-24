@isTest
public with sharing class CancelamentoHelperTest {
    @isTest
    public static void testCancelamentoHelper() {

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
        User manager = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert manager;

        User user = (User)TestFactory.createSObject(
            new User(
                ManagerId = manager.Id,
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

        Campanha__c campanha = (Campanha__c)TestFactory.createSObject(new Campanha__c());
        insert campanha;

        CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(
            new CondicaoPagamento__c(
                ExternalId__c = 'CR00'
            )
        );
        insert condicaoPagamento;
        
        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        insert cotacaoMoeda;

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
                GerenteRegional__c     = user.Id,
                DiretorComercial__c    = user.Id
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

        Product2 product = (Product2)TestFactory.createSObject(new Product2(
            subFamily__c = '029'
        ));
        insert product;

        ProgramacaoEntrega__c programacaoEntrega = (ProgramacaoEntrega__c)TestFactory.createSObject(
            new ProgramacaoEntrega__c(
                IdOportunidade__c = opportunity.Id,
                EmissorOrdem__c   = account.Id
            )
        );
        ProgramacaoEntregaHelper.disableTrigger();
        insert programacaoEntrega;
        ProgramacaoEntregaHelper.enableTrigger();

        Cancelamento__c cancelamento = (Cancelamento__c)TestFactory.createSObject(
            new Cancelamento__c(
                ProgramacaoEntrega__c   = programacaoEntrega.Id,
                ValorTotal__c = 10,
                ValorTotalUSD__c = 10,
                QuantidadeProgramada__c = 2,
                Produto__c              = product.Id,
                IdOportunidade__c       = opportunity.Id,
                EmissorOrdem__c         = account.Id,
                RecebedorOrdem__c       = account.Id,
                GerenteComercial__c     = user.Id,
                DiretorComercial__c     = user.Id,
                DiretorNegocios__c      = user.Id,
                GerenteRegional__c      = user.Id,
                Pedido__c               = order.Id,
                StatusSAP__c            = 'Faturado Parcial'
            )
        );
        insert cancelamento;

        Cancelamento__c cancelamentoBase = [SELECT Id, SolicitacaoCancelamento__c, CreatedDate FROM Cancelamento__c WHERE Id = :cancelamento.Id];

        ProcessInstance pi = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :cancelamentoBase.SolicitacaoCancelamento__c];

        System.assertEquals(cancelamentoBase.CreatedDate.day(), pi.CreatedDate.day());

    }
}