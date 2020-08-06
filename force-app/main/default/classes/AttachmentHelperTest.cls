@IsTest
public class AttachmentHelperTest {
    @IsTest
    static void simpleTest() {       

        Account account = (Account)TestFactory.createSObject(new Account());
        insert account;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(new Opportunity(            
            jurosComercialFinanceiro__c = 10,
            stageName = 'Em Aprovação Cliente'
        ));
        insert opportunity;

        // Opportunity opportunityApproved = (Opportunity)TestFactory.createSObject(new Opportunity(            
        //     jurosComercialFinanceiro__c = 10,
        //     stageName = 'Aprovado Cliente'
        // ));
        // insert opportunityApproved;

        Opportunity opportunityReproved = (Opportunity)TestFactory.createSObject(new Opportunity(            
            jurosComercialFinanceiro__c = 10,
            stageName = 'Reprovado'
        ));
        insert opportunityReproved;

        Opportunity opportunityError = (Opportunity)TestFactory.createSObject(new Opportunity(            
            jurosComercialFinanceiro__c = 10,
            stageName = 'Cancelado'
        ));
        insert opportunityError;

        GenerateOpportunityPDFController.generateAttachment(opportunity.id);
        GenerateOpportunityPDFController.generateAttachment(opportunityError.id);
        // GenerateOpportunityPDFController.generateAttachment(opportunityApproved.id);
        GenerateOpportunityPDFController.generateAttachment(opportunityReproved.id);
    }
    @IsTest
    static void opportunityPDFControllerTest() { 

        OpportunityAppControllerTestFactory opportunityAppControllerTestFactory = new OpportunityAppControllerTestFactory(); 

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c = zonaTransporte.Id
            ));
        insert localNegocio;

        Account account = (Account)TestFactory.createSObject(new Account(
            Name = 'Reginaldo',
            emailComercial__c = 'billingState@nescara.com',
            billingStreet = 'billingStreet', 
            billingCity = 'billingCity',
            billingState = 'billingState', 
            billingPostalCode = 'billingPostalCode', 
            cnpj__c = '31063470000128', 
            inscricaoEstadual__c = '1256165156', 
            localNegocio__c = localNegocio.id,            
            nomeFazenda__c = 'nome',
            suframa__c = ''
        ));
        insert account;

        Product2 product  = (Product2)TestFactory.createSObject(new Product2());
        insert product;


        CondicaoPagamento__c condicaoPagamento = new CondicaoPagamento__c(
            ExternalId__c = 'CR00',
            Tipo__c = '',
            DataVigenciaAte__c = date.today().addDays(1),
            DataVigenciaDe__c = date.today(),
            JurosComercialFinanceiro__c = 10
        );
        insert condicaoPagamento;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(new Opportunity(   
            accountId = account.id,
            pricebook2Id = Test.getStandardPricebookId(),
            CondicaoPagamento__c = condicaoPagamento.id,
            amount = 100, 
            valorTotalMercadoriasReal__c = 10, 
            valorTotalMercadoriasRealSemIPI__c = 10, 
            valorTotalMercadoriasDolar__c = 2, 
            valorTotalMercadoriasDolarSemIPI__c = 2, 
            tipoFrete__c = 'CIF', 
            tipoOrdem__c = 'Normal', 
            moeda__c = 'BRL',
            emailAprovacaoPedidoCliente__c = 'billingState@nescara.com', 
            nomeRTV__c = 'nomeRTV', 
            vencimentoVendor__c = Date.today().addDays(10),
            observacaoPDF__c = 'observaçãoPDF',          
            jurosComercialFinanceiro__c = 10,
            stageName = 'Em Aprovação Cliente'
        ));
        insert opportunity;

        Opportunity opportunityError = (Opportunity)TestFactory.createSObject(new Opportunity( 
            jurosComercialFinanceiro__c = 10,
            stageName = 'Cancelado'
        ));
        insert opportunityError;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            opportunityId = opportunity.id,
            quantity = 20,
            product2Id = product.id,
            unitPrice = 100,
            precoLitro__c = 3,
            discount = 2
        );
        insert opportunityLineItem;

        PageReference pageRef = Page.OpportunityPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',opportunity.id);

        OpportunityPDFController opportunityPDFController = new OpportunityPDFController();
    }

    @IsTest
    static void deliveryAppControllerTest() { 

        OpportunityAppControllerTestFactory opportunityAppControllerTestFactory = new OpportunityAppControllerTestFactory(); 

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c = zonaTransporte.Id
            ));
        insert localNegocio;

        Account account = (Account)TestFactory.createSObject(new Account(
            Name = 'Reginaldo',
            emailComercial__c = 'billingState@nescara.com',
            billingStreet = 'billingStreet', 
            billingCity = 'billingCity',
            billingState = 'billingState', 
            billingPostalCode = 'billingPostalCode', 
            cnpj__c = '31063470000128', 
            inscricaoEstadual__c = '1256165156', 
            localNegocio__c = localNegocio.id,            
            nomeFazenda__c = 'nome',
            suframa__c = ''
        ));
        insert account;

        Product2 product  = (Product2)TestFactory.createSObject(new Product2());
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

        CondicaoPagamento__c condicaoPagamento = new CondicaoPagamento__c(
            ExternalId__c = 'CR00',
            Tipo__c = '',
            DataVigenciaAte__c = date.today().addDays(1),
            DataVigenciaDe__c = date.today(),
            JurosComercialFinanceiro__c = 10
        );
        insert condicaoPagamento;

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(new Opportunity(   
            accountId = account.id,
            pricebook2Id = pricebook.id,
            CondicaoPagamento__c = condicaoPagamento.id,
            amount = 100, 
            valorTotalMercadoriasReal__c = 10, 
            valorTotalMercadoriasRealSemIPI__c = 10, 
            valorTotalMercadoriasDolar__c = 2, 
            valorTotalMercadoriasDolarSemIPI__c = 2, 
            tipoFrete__c = 'CIF', 
            tipoOrdem__c = 'Normal', 
            moeda__c = 'BRL',
            emailAprovacaoPedidoCliente__c = 'billingState@nescara.com', 
            nomeRTV__c = 'nomeRTV', 
            vencimentoVendor__c = Date.today().addDays(10),
            observacaoPDF__c = 'observaçãoPDF',          
            jurosComercialFinanceiro__c = 10,
            stageName = 'Em Aprovação Cliente'
        ));
        insert opportunity;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Título',
            PathOnClient = 'titulo',
            VersionData = Blob.valueof('titulo')
        );
        insert contentVersion;
        contentVersion = [SELECT id, Title, VersionData, FileExtension, ContentDocumentId FROM ContentVersion WHERE id = :contentVersion.id];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = opportunity.id;
        contentDocumentLink.ShareType = 'V';
        insert contentDocumentLink;

        Opportunity opportunityError = (Opportunity)TestFactory.createSObject(new Opportunity( 
            jurosComercialFinanceiro__c = 10,
            stageName = 'Cancelado'
        ));
        insert opportunityError;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            opportunityId = opportunity.id,
            quantity = 20,
            product2Id = product.id,
            unitPrice = 100,
            precoLitro__c = 3,
            discount = 2
        );
        insert opportunityLineItem;

        SendOpportunityPDFController.send(opportunity.Id);
        SendOpportunityPDFController.send(opportunityError.Id);

        DeliveryAppController deliveryApp = new DeliveryAppController();

        DeliveryAppController.RecordQueryRequest recordQuery = new DeliveryAppController.RecordQueryRequest();
        recordQuery.searchTerm     = 'Reginaldo';
        recordQuery.tableName      = 'Account';
        recordQuery.searchTarget   = 'Name;billingStreet';
        recordQuery.returnedFields = new List<String>{'billingStreet'};
        recordQuery.filters        = null;
        
        ApexPages.StandardController apexPage = new ApexPages.StandardController(opportunity);
        PageReference pageRef = Page.DeliveryApp;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',opportunity.id);

        DeliveryAppController deliveryAppControllerPage = new DeliveryAppController(apexPage);

        List<DeliveryAppController.ResultData> resultDataList = DeliveryAppController.searchLookup(recordQuery);


    }
}