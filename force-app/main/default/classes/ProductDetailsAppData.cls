public class ProductDetailsAppData {
        
    public Date    lastSalesDate;
    public Decimal lastSalesQuantity;
    public Decimal lastSalesPrice;
    public Decimal lastSalesDiscount;
    public Decimal lastSalesPricePerLiter;
    public String  lastSalesPaymentCondition;
    public Decimal lastSalesPriceWithInterest;
    public String  opportunityId;

    public ProductDetailsAppData(OpportunityLineItem opportunityLineItem){
        this.lastSalesDate              = opportunityLineItem.opportunity.closeDate;
        this.lastSalesQuantity          = opportunityLineItem.quantity;
        this.lastSalesPrice             = opportunityLineItem.precoVendaSemJurosBRLUSD__c;
        this.lastSalesDiscount          = opportunityLineItem.discount;
        this.lastSalesPricePerLiter     = opportunityLineItem.precoLitroBRLUSD__c;
        this.lastSalesPaymentCondition  = opportunityLineItem.opportunity.condicaoPagamento__r.descricao__c;
        Decimal interestValue           = (opportunityLineItem.opportunity.jurosComercialFinanceiro__c / 100);
        Decimal salesPercent            = opportunityLineItem.precoVendaSemJurosBRLUSD__c * interestValue;
        this.lastSalesPriceWithInterest = opportunityLineItem.precoVendasJurosBRLUSD__c;
        this.opportunityId              = opportunityLineItem.opportunityId;
    }
    
}