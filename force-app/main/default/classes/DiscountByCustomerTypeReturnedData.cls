public class DiscountByCustomerTypeReturnedData extends ResultTemplate{
        
    public DiscountByCustomerTypeData data;

    public DiscountByCustomerTypeReturnedData(){}

    public DiscountByCustomerTypeReturnedData(DescontoTipoCliente__c customerTypeDiscount){
        this.data        = new DiscountByCustomerTypeData(customerTypeDiscount);
        this.hasErrors   = false;
        this.message     = 'Success';
        this.stackStrace = null;
    }

    public DiscountByCustomerTypeReturnedData(Exception e){
        this.data        = null;
        this.hasErrors   = true;
        this.message     = e.getMessage();
        this.stackStrace = e.getStackTraceString();
    }
}