public class PricingServiceTest {

    // @IsTest
    // public static void testShouldGetUSDPrices(){

    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();

    //     Account targetAccount = pricingTestFactory.fetchAccount();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository pricebookTestRepo = new PriceTestRepository(pricingTestFactory);

    //     TabelaPreco__c genericPrice = pricebookTestRepo.addEntry(product.id);
    //     insert genericPrice;

    //     TabelaPreco__c usdSpecificPrice = genericPrice.clone();
    //     usdSpecificPrice.id = null;
    //     usdSpecificPrice.produto__c = product.id;
    //     usdSpecificPrice.listaPreco__c = 'Z4';
    //     usdSpecificPrice.ExternalId__c = GuidGenerator.generate();
    //     insert usdSpecificPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());
    //             service.setCurrency('USD');

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(usdSpecificPrice.id, customerPrices.get(product.id).priceId, 'Specific USD price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testShouldGetGeneric(){

    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();

    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     Account targetAccount = pricingTestFactory.addAccountRegion().fetchAccount();
    //     insert targetAccount;

    //     PriceTestRepository priceRepository = new PriceTestRepository(pricingTestFactory);
        
    //     TabelaPreco__c regionSpecificPrice = PriceRepository.addEntry(product.id);
    //     insert regionSpecificPrice;

    //     PriceTestRepository mostSpecificPriceRepository = new PriceTestRepository(new PricingTestFactory().addAccountHierarchy());
        
    //     TabelaPreco__c mostSpecificPrice = mostSpecificPriceRepository.addEntry(product.id);
    //     insert mostSpecificPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(regionSpecificPrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }

    // @IsTest
    // public static void testMostSpecificPriceOverGeneric(){

    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();

    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

        
    //     pricingTestFactory.addAccountRegion();

    //     /* 
    //      * The following pricebook record should be retrieved by the service, 
    //      * because it matches for the region criteria. But since we're going 
    //      * to use a more specific record, then it should be discarded, because 
    //      * the query will limit the results for ONE record, ordering records by specificity.
    //      */

    //     PriceTestRepository priceRepository = new PriceTestRepository(pricingTestFactory);
        
    //     TabelaPreco__c regionSpecificPrice = PriceRepository.addEntry(product.id);
    //     insert regionSpecificPrice;

    //     /* This should be the actual pricebook coming through the service. */
    //     Account targetAccount = pricingTestFactory.addAccountHierarchy().fetchAccount();

    //     PriceTestRepository mostSpecificPriceRepository = new PriceTestRepository(pricingTestFactory);
        
    //     TabelaPreco__c mostSpecificPrice = mostSpecificPriceRepository.addEntry(product.id);
    //     insert mostSpecificPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(mostSpecificPrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testMostSpecificPrices(){
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();
        
    //     Account targetAccount = pricingTestFactory.addAccountHierarchy()
    //                                               .fetchAccount();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository priceRepository = new PriceTestRepository(pricingTestFactory);
        
    //     TabelaPreco__c hierarchySpecificPrice = PriceRepository.addEntry(product.id);
    //     insert hierarchySpecificPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(hierarchySpecificPrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testSpecificCustomerPrices(){
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();
        
    //     Account targetAccount = pricingTestFactory.fetchAccount();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository priceRepository = new PriceTestRepository(pricingTestFactory);
    //     PriceRepository.isClientSpecific(true);
        
    //     TabelaPreco__c customerSpecificPrice = PriceRepository.addEntry(product.id);
    //     insert customerSpecificPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(customerSpecificPrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testPricesForRegionalAndCustomerType(){
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();
        
    //     Account targetAccount = pricingTestFactory.addAccountRegion()
    //                                               .addAccountType()
    //                                               .fetchAccount();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository priceRepository = new PriceTestRepository(pricingTestFactory);
        
    //     TabelaPreco__c regionAndTypePrice = PriceRepository.addEntry(product.id);
    //     insert regionAndTypePrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(regionAndTypePrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testPricesForCustomerType(){
        
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();
        
    //     Account targetAccount = pricingTestFactory.getAccountWithType();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository pricebookTestRepo = new PriceTestRepository(pricingTestFactory);

    //     TabelaPreco__c customerTypePrice = pricebookTestRepo.addEntry(product.id);
    //     insert customerTypePrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(customerTypePrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testPricesForRegion(){
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();
        
    //     Account targetAccount = pricingTestFactory.getAccountWithRegion();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository pricebookTestRepo = new PriceTestRepository(pricingTestFactory);

    //     TabelaPreco__c regionPrice = pricebookTestRepo.addEntry(product.id);
    //     insert regionPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(regionPrice.id, customerPrices.get(product.id).priceId, 'Specific price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Specific price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
    
    // @IsTest
    // public static void testMostGenericPrices(){
    //     PricingTestFactory pricingTestFactory = new PricingTestFactory();

    //     Account targetAccount = pricingTestFactory.fetchAccount();
    //     insert targetAccount;
        
    //     Product2 product = pricingTestFactory.fetchSimpleProduct();
    //     insert product;

    //     PriceTestRepository pricebookTestRepo = new PriceTestRepository(pricingTestFactory);

    //     TabelaPreco__c genericPrice = pricebookTestRepo.addEntry(product.id);
    //     insert genericPrice;

    //     Test.startTest();
    //         try {
    //             PricingService service = new PricingService(targetAccount, System.today());

    //             Map<String, ProductPriceEntry> customerPrices = service.getPrices();

    //             System.assertEquals(genericPrice.id, customerPrices.get(product.id).priceId, 'Generic price was not returned by the service.');
    //         } catch (AssertException e) {
    //             System.assert(false, e.getMessage());
    //         } catch (Exception e) {
    //             System.assert(false, 'Generic price was not returned by the service. Exception: ' + e.getMessage() + ' - @: \n' + e.getStackTraceString());
                
    //         }
            
    //     Test.stopTest();
    // }
}