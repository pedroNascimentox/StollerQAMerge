@isTest
public with sharing class BatchNotaFiscalTaxaMediaMonthTest {
    @isTest
    public static void testUpdateTaxa() {

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

        Integer thisYear = Date.today().year();
        Integer thisMonth = Date.today().month();
        Integer thisDay = Date.today().day();
        
        CotacaoMoeda__c cotacaoMoedaError = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Taxa__c = 5.00,
                Data__c = Date.newInstance(thisYear, thisMonth, 1)
            ));
        insert cotacaoMoedaError;

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.newInstance(thisYear, Date.today().addMonths(-1).month(), 28),
                Taxa__c = 20.00
            ));
        insert cotacaoMoeda;

        CotacaoMoeda__c cotacaoMoeda1 = (CotacaoMoeda__c)TestFactory.createSObject(
            new CotacaoMoeda__c(
                Data__c = Date.newInstance(thisYear, Date.today().addMonths(-1).month(), 10),
                Taxa__c = 15.00
            ));
        insert cotacaoMoeda1;

        NotaFiscal__c notaFiscal = (NotaFiscal__c)TestFactory.createSObject(
            new NotaFiscal__c(
                CodigoAgenciador__c = account.Id,
                CodigoCliente__c    = account.Id,
                // Itinerario__c       = itinerario.Id,
                NrOrdem__c          = order.Id,
                Oportunidade__c     = opportunity.Id,
                Regional__c         = regional.Id,
                Territorio__c       = territorio.Id,
                VendedorRTV__c      = user.Id,
                DataNF__c           = Date.today().addMonths(-1)
            )
        );
        insert notaFiscal;

        NotaFiscalItem__c notaFiscalItem = (NotaFiscalItem__c)TestFactory.createSObject(
            new NotaFiscalItem__c(
                NotaFiscal__c     = notaFiscal.Id,
                CodigoMaterial__c = product.Id,
                Cultura__c        = cultura.Id
            )
        );
        insert notaFiscalItem;

        BatchNotaFiscalTaxaMediaMonth batch = new BatchNotaFiscalTaxaMediaMonth();
        batch.execute(null, Database.query(batch.start(null).getQuery()));
        batch.finish(null);

        NotaFiscalItem__c notaFiscalItemBase = [SELECT Id, ValorTotalUSD__c, ValorTotalItem__c FROM NotaFiscalItem__c LIMIT 1];
        CotacaoMoeda__c cotacaoMoedaBase = [SELECT Id, Taxa__c, TaxaMedia__c FROM CotacaoMoeda__c WHERE Id = :cotacaoMoeda.Id];

        // System.debug('cotacaoMoeda.Taxa__c => ' + cotacaoMoedaBase.Taxa__c);
        // System.debug('cotacaoMoeda.TaxaMedia__c => ' + cotacaoMoedaBase.TaxaMedia__c);
        // System.debug('notaFiscalItemBase.ValorTotalItem__c => ' + notaFiscalItemBase.ValorTotalItem__c);
        // System.debug('notaFiscalItemBase.ValorTotalUSD__c => ' + notaFiscalItemBase.ValorTotalUSD__c);

        // System.assertEquals(notaFiscalItemBase.ValorTotalItem__c / cotacaoMoedaBase.TaxaMedia__c, notaFiscalItemBase.ValorTotalUSD__c);
        
    }

    @isTest
    public static void testSchedule() {

        Test.startTest();
        
        List<CronTrigger> schedule = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                        FROM CronTrigger 
                                       WHERE CronJobDetail.Name = 'Update Nota Fiscal Taxa Média Monthly'];
        
        String jobId;
        if (schedule.size() == 0){
            jobId = BatchNotaFiscalTaxaMediaMonth.setSchedule();
        } else {
            System.abortJob(schedule[0].Id);
            jobId = BatchNotaFiscalTaxaMediaMonth.setSchedule();
        }
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                            FROM CronTrigger 
                           WHERE Id = :jobId];

        Test.stopTest();

        System.assertEquals('0 0 0 1 * ? *', ct.CronExpression);
        System.assertEquals(1, ct.NextFireTime.day());
    }
}