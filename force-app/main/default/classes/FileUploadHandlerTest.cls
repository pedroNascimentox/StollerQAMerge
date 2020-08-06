@IsTest
public class FileUploadHandlerTest {
    
    @IsTest
    public static void fullProcessTest(){

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
            aprovadoComercial__c = true
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
        
        Test.startTest();

            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

            //create ContentDocumentLink  record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = opportunity.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            insert cdl;

            Boolean userHasFullAccess = FileUploadHandler.userHasFullAccess();
            List<String> documentTypes = FileUploadHandler.getDocumentTypes();
            List<FileUploadHandler.DocumentVO> documentVOList = FileUploadHandler.getFiles(opportunity.id);
            FileUploadHandler.reattributeFiles(opportunity.id, new List<Id>{documents[0].Id});
            documentVOList = FileUploadHandler.getFiles(opportunity.id);
            /*
            documentVOList[0].documentType = 'Oportunidade Aprovada';
            FileUploadHandler.saveNewDocumentTypes(documentVOList);
            documentVOList = FileUploadHandler.getOpportunityDocumentsByDocumentId(new List<Id>{documents[0].Id});
            FileUploadHandler.FileUploadHandlerReturn fileUploadHandlerReturn = FileUploadHandler.validateFiles(new List<String>{documentVOList[0].opportunityDocumentId});
            fileUploadHandlerReturn = FileUploadHandler.deleteFiles(new List<String>{documentVOList[0].opportunityDocumentId}, true);
            */
        Test.stopTest();
        
    }

}