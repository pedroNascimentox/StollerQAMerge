public class PricingAppData {
    
    public List<ProductAppData> productsData {get; set;}
    public List<String> productsRA {get; set;}

    public PricingAppData() {}

    public void setProductsData(List<ProductAppData> productsData){
        this.productsData = productsData;
    }
    
    public void setProductsRA(Map<Id, Product2> productsRAMap){
        this.productsRA = new List<String>();
        for (String pId : productsRAMap.keySet()) {
            this.productsRA.add(pId);            
        }
    }
    
}