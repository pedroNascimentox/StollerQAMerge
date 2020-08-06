public class ProductHelper extends TriggerContext{

    @TestVisible
    private static final Id STANDARD_PRICEBOOK_ID;
        
    static {
		
        STANDARD_PRICEBOOK_ID = 
            Test.isRunningTest()?
            Test.getStandardPricebookId():
            [
                SELECT id 
                FROM Pricebook2 
                WHERE isStandard = true 
                LIMIT 1
            ].id;
    }

    public static void createStandardEntries(List<Product2> newRecordList){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();

        for(Product2 product : newRecordList){
        	pricebookEntryList.add(
        		new PriceBookEntry(
        			pricebook2Id = STANDARD_PRICEBOOK_ID, 
        			product2Id = product.id,
                    isActive = true,
                    unitPrice = 0
        		)
        	);
        }

        if(!pricebookEntryList.isEmpty()){
        	insert pricebookEntryList;
        }
    }
}