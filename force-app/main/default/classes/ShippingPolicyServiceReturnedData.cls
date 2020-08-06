public class ShippingPolicyServiceReturnedData extends ResultTemplate {
    
    public ShippingPolicyServiceData data;

    public ShippingPolicyServiceReturnedData(){
        this.data = new ShippingPolicyServiceData();
    }
    
    public ShippingPolicyServiceReturnedData(TabelaFrete__c shippingTable) {
        if (shippingTable != null) {
            this.data    = new ShippingPolicyServiceData(shippingTable);            
        }else {
            this.data    = new ShippingPolicyServiceData();
        }
        this.hasErrors = false;
        this.message   = 'Success';
        this.stackStrace = null;
    }

    public ShippingPolicyServiceReturnedData(Exception e) {
        this.data        = null;
        this.hasErrors   = true;
        this.message     = e.getMessage();
        this.stackStrace = e.getStackTraceString();
    }

}