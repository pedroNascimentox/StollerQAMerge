public class PricingService {
 
    private Account account;
    private Date effectiveDate;
    private String currencyName;
    private String regional;

    public PricingService(Account a, Date d){
        this.account = a;
        this.effectiveDate = d;
    }

    public void setCurrency(String currencyName){
        this.currencyName = currencyName;
    }

    public void setRegional(String regional){
        this.regional = regional;
    }

    public Map<String, ProductPriceEntry> getPrices(){
        List<Id> allProductIds = Collection.of([
            SELECT 
                id 
            FROM Product2 
            LIMIT 10000
        ]).pluckIds();

        return this.getPrices(allProductIds);
    }
    
    // public Map<String, ProductPriceEntry> getPrices(Id[] productIds){
    //     Map<String, ProductPriceEntry> result = new Map<String, ProductPriceEntry>();

    //     TabelaPreco__c[] targetEntries;

    //     try {
    //         if (this.currencyName != null){
    //             targetEntries = PriceRepository.getMostSpecificPrices(this.account, this.currencyName, productIds);
    //         } else {
    //             targetEntries = PriceRepository.getMostSpecificPrices(this.account, productIds);
    //         }
    //     } catch(Exception e){
    //         throw new PricingServiceException('Não foi encontrada uma lista de preço para este cliente.');
    //     }

    //     for(TabelaPreco__c entry : targetEntries){
    //         result.put(entry.produto__c, new ProductPriceEntry(entry));
    //     }

    //     return result;
        
    // }
    
    public Map<String, ProductPriceEntry> getPrices(Id[] productIds){
        Map<String, ProductPriceEntry> result = new Map<String, ProductPriceEntry>();

        TabelaPreco__c[] targetEntries;

        try {
            if (this.currencyName != null){
                targetEntries = PriceRepository.getMostSpecificPrices(this.account, this.currencyName, productIds, this.effectiveDate, this.regional);
            } else {
                targetEntries = PriceRepository.getMostSpecificPrices(this.account, productIds, this.effectiveDate, this.regional);
            }
        } catch(Exception e){
            throw new PricingServiceException('Não foi encontrada uma lista de preço para este cliente.');
        }

        for(TabelaPreco__c entry : targetEntries){
            if(!result.containsKey(entry.produto__c))
                result.put(entry.produto__c, new ProductPriceEntry(entry));
        }

        return result;
        
    }

    public class PricingServiceException extends Exception{}
}