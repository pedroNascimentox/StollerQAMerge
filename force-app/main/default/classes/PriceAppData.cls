public class PriceAppData {
    
    public DiscountByCustomerTypeData customerTypeData;
    public ShippingPolicyServiceData  freightData;
    
    public PriceAppData(){}

    public PriceAppData(DiscountByCustomerTypeData discountByCustomerTypeData, ShippingPolicyServiceData freightData){
        this.freightData      = freightData;
        this.customerTypeData = discountByCustomerTypeData;
    }

    public void setCustomerTypeDiscount(DiscountByCustomerTypeData discountByCustomerType){
        this.customerTypeData = discountByCustomerType;
    }

    public void setFreightPercentage(ShippingPolicyServiceData freightData){
        this.freightData = freightData;
    }
}