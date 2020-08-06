public class ProductPriceEntry {
    public Id pricebookEntry;
    public Id priceId;
    public Decimal price;

    public ProductPriceEntry(PricebookEntry entry){
        this.pricebookEntry = entry.id;
        this.price = entry.unitPrice;
    }
    public ProductPriceEntry(TabelaPreco__c entry){
        this.priceId = entry.id;
        this.price = entry.valor__c;
    }
}