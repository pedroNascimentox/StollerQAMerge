@IsTest
public class ProductAppDataTest {

    @IsTest
    public static void simpleTest(){

        Date today = Date.today();
        
        Account account = (Account)TestFactory.createSObject(new Account());
        insert account;

        Account hierarchyAccount = (Account)TestFactory.createSObject(new Account());
        insert hierarchyAccount;

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c());
        insert territorio;

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

        Opportunity opportunity = (Opportunity)TestFactory.createSObject(new Opportunity(
            pricebook2Id = Test.getStandardPricebookId(),
            jurosComercialFinanceiro__c = 10,
            condicaoPagamento__c = validPaymentCondition.id
        ));
        insert opportunity;
        
        opportunity = [SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate, pricebook2Id, jurosComercialFinanceiro__c FROM Opportunity WHERE id =: opportunity.id];

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            opportunityId = opportunity.id,
            quantity = 20,
            product2Id = product.id,
            unitPrice = 100,
            precoLitro__c = 3,
            discount = 2
        );
        insert opportunityLineItem;

    opportunityLineItem = [SELECT id, opportunityId, unitprice, precoVendaSemJurosBRLUSD__c,precoVendasJurosBRLUSD__c, precoLitroBRLUSD__c,  opportunity.jurosComercialFinanceiro__c,
         opportunity.condicaoPagamento__r.descricao__c, opportunity.CloseDate, quantity, product2Id, precoLitro__c, discount
         FROM OpportunityLineItem WHERE id  = :opportunityLineItem.Id];

        PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
            regional__c = regional.id,
            territorio__c = territorio.id,
            hierarquia__c = hierarchyAccount.id,
            produto__c = product.Id,
            dataVigenciaInicial__c = opportunity.closeDate,
            dataVigenciaFinal__c = opportunity.closeDate,
            recomendado__c = 10,
            maximo__c = 15,
            minimo__c = 5,
            externalId__c = 'pr1c3b00k3n7ry',
            organizacaoVenda__c = '1000'
        );
        insert discountPolicy;

        DiscountPolicyServiceData discountPolicyServiceData = new DiscountPolicyServiceData(discountPolicy);

        ProductDetailsAppData productAppDetailsAppData = new ProductDetailsAppData(opportunityLineItem);

        String pricebookEntryId = '';

        ProductAppData productAppData = new ProductAppData();
        productAppData.setProductData(product);
        productAppData.setPricebookEntry(pricebookEntryId);
        productAppData.setPriceList(100,10,5);
        productAppData.setDiscountPolicyDataToProduct(discountPolicyServiceData);
        productAppData.setProductDetails(productAppDetailsAppData);
        productAppData.setInternalDeadlineDays(10);
        productAppData.setItineraryDays(5);

        ProductAppData productAppData2 = new ProductAppData(product,pricebookEntryId,100,10,5,productAppDetailsAppData);

    }
}