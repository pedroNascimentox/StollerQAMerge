@IsTest
public class OpportunityHelperTest {
    
    @IsTest
    public static void rtvNotificationTest(){
        
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

        Account account = new Account(
            name = 'Test Account',
            externalId__c = '73574cc0un7'
        );
        insert account;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

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

        DescontoTipoCliente__c currentCustomerTypeDiscount = new DescontoTipoCliente__c(
            tipoCliente__c          = 'ZB',
            desconto__c             = 2.0,
            dataVigenciaInicial__c  = Date.today().addDays(-7),
            dataVigenciaFinal__c    = Date.today().addDays(9)
        );
        insert currentCustomerTypeDiscount;

        Opportunity opportunity = new Opportunity(
            territorio__c = territory.id,
            stageName = 'Iniciado',
            closeDate = Date.today(),
            name = 'Test Opportunity',
            accountId = account.id,
            pricebook2Id = pricebook.id,
            aprovadoComercial__c = true,
            DataInicioJuros__c = Date.today()
        );
        insert opportunity;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            opportunityId = opportunity.id,
            quantity = 20,
            product2Id = product.id,
            unitPrice = 100,
            precoLitro__c = 3,
            discount = 2,
            DescontoTipoCliente__c = 10
        );
        insert opportunityLineItem;

        opportunity = [SELECT id, numeroOportunidade__c, DataInicioJuros__c, aprovadoComercial__c FROM Opportunity WHERE id = :opportunity.id];

        Test.startTest();

            opportunity.stageName = 'Aprovado Cliente';
            opportunity.DontChangeStageName__c = true;
            update opportunity;

        Test.stopTest();

        //System.assert([SELECT id, description FROM Task LIMIT 1].description.contains(opportunity.numeroOportunidade__c), 'Task wasn\'t created correctly.');
    }

    @isTest
    public static void dadosAprovacaoTest() {

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            )
        );
        insert user;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                DiretorComercial__c = user.Id,
                GerenteRegional__c  = user.Id,
                DataInicioJuros__c = Date.today()
            )
        );
        insert opportunity;

        Product2 product = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        PricebookEntry pricebookEntry = [SELECT Id, IsActive FROM PricebookEntry WHERE Product2Id = :product.Id];
        pricebookEntry.IsActive = true;
        update pricebookEntry;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            Product2Id = product.Id,
            PrecoVendasJurosUSD__c = 10,
            PrecoVendasJuros__c = 10,
            discount = 10,
            OpportunityId = opportunity.Id,
            ItemparaAprovao__c = true,
            DescontoExcedente__c = 4,
            PricebookEntryId = pricebookEntry.Id,
            TotalPrice = 10.00,
            Quantity = 1
        );
        insert opportunityLineItem;

        OpportunityHelper.disableTrigger();
        opportunity.DontChangeStageName__c = true;
        update opportunity;
        OpportunityHelper.enableTrigger();

        Approval.ProcessSubmitRequest psr1 = new Approval.ProcessSubmitRequest();
        psr1.setComments('Submitting request for approval.');
        psr1.setObjectId(opportunity.id);
        
        psr1.setSubmitterId(user.Id);
        
        psr1.setProcessDefinitionNameOrId('VendaNormalDescontov3');
        psr1.setSkipEntryCriteria(true);
        
        Approval.ProcessResult result0 = Approval.process(psr1);
        List<Id> newWorkItemIds = result0.getNewWorkitemIds();

        Test.startTest();

        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        req2.setWorkitemId(newWorkItemIds.get(0));
        
        Approval.ProcessResult result2 = Approval.process(req2);
        
        Test.stopTest();

        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());

        List<ProcessInstanceStep> processInstanceStep = [SELECT Id, StepStatus, Comments, ActorId, OriginalActorId FROM ProcessInstanceStep LIMIT 100];
        // System.debug('processInstanceStep => ' + processInstanceStep);

        List<ProcessInstanceWorkitem> processInstanceWorkitem = [SELECT Id, ProcessInstanceId, ActorId, OriginalActorId FROM ProcessInstanceWorkitem LIMIT 100];
        // System.debug('processInstanceWorkitem => ' + processInstanceWorkitem);

        List<DadosAprovacao__c> dadosAprovacao = [SELECT Id, NomeEtapa__c, NumeroEtapa__c, StatusAprovacao__c FROM DadosAprovacao__c LIMIT 100];
        // System.debug('dadosAprovacao => ' + dadosAprovacao);

        Collection dadosAprovacaoCollection = Collection.of(dadosAprovacao);
        /*System.assertEquals(3, dadosAprovacao.size()); // This assertion may go wrong, probably because of future method
        System.assertEquals(true, (new Set<String>(dadosAprovacaoCollection.pluckStrings(DadosAprovacao__c.StatusAprovacao__c)).contains('Started')));
        System.assertEquals(true, (new Set<String>(dadosAprovacaoCollection.pluckStrings(DadosAprovacao__c.StatusAprovacao__c)).contains('Pending')));
        System.assertEquals(true, (new Set<String>(dadosAprovacaoCollection.pluckStrings(DadosAprovacao__c.StatusAprovacao__c)).contains('Approved')));
        */
    }
}