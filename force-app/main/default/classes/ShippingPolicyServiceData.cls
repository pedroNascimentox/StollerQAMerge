public class ShippingPolicyServiceData {

    public String  id {get; set;}
    public Decimal shipping {get; set;}

    public ShippingPolicyServiceData() {
        this.id       = null;
        this.shipping = null;
    }

    public ShippingPolicyServiceData(TabelaFrete__c shippingTable) {
        if(shippingTable != null && shippingTable.vigenciaTabelaFrete__r.size() > 0) {
            this.id       = shippingTable.id;
            this.shipping = shippingTable.vigenciaTabelaFrete__r[0].frete__c;
        }else {
            this.id       = null;
            this.shipping = 0;
        }
    }

}