@IsTest
public class ProductHelperTest {
    
    @IsTest
    public static void testStandardEntriesCreation(){
        Product2 product = (Product2) TestFactory.createSObject(new Product2());
        insert product;

        Test.startTest();
        
            System.assertEquals(1, [SELECT count() FROM PricebookEntry WHERE pricebook2Id =: Test.getStandardPricebookId() AND product2Id = :product.id], 'The standard entry for the product was not created.');
        
        Test.stopTest();
    }
}