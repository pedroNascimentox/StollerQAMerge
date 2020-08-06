public class OpportunityAppData {

    public DeliveryAppData      deliveryData  {get; set;}
    public List<ProductAppData> productsData  {get; set;}
    public List<String>         productsRA    {get; set;}
    public PriceAppData         priceAppData  {get; set;}
    public TerritoryData        territoryData {get; set;}
    public String               currencyName  {get; set;}

    public OpportunityAppData() {
        this.deliveryData  = null;
        this.productsData  = new List<ProductAppData>();
        this.priceAppData  = null;
        this.territoryData = null;
    }

    public void setPricingData(PricingAppData pricingAppData){
        this.productsData = pricingAppData.productsData;
    }
    
    public void setProductsRA(PricingAppData pricingAppData){
        this.productsRA = pricingAppData.productsRA;
    }

    public void setProductsData(List<ProductAppData> productsData){
        this.productsData = productsData;
    }

    public void setDeliveryData(DeliveryAppData deliveryData){
        this.deliveryData = deliveryData;
    }

    public void setPriceData(PriceAppData priceAppData){
        this.priceAppData = priceAppData;
    }

    public void setTerritoryData(TerritoryData territoryData){
        this.territoryData = territoryData;
    }

}