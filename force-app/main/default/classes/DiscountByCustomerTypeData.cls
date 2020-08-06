public with sharing class DiscountByCustomerTypeData {
    
    public Id      id;
    public String  customerType;
    public Decimal discount{
        get {
            return discount;
        }
        set {
            Decimal d = value;
            discount = d != null? d : d < 0? 0 : d;
        }
    }
    public String initialDate;
    public String finishDate;

    public DiscountByCustomerTypeData(DescontoTipoCliente__c discountByCustomerType){
        this.id           = discountByCustomerType.id;
        this.discount     = discountByCustomerType.desconto__c;
        this.customerType = discountByCustomerType.tipoCliente__c;
        this.initialDate  = String.valueOf(discountByCustomerType.dataVigenciaInicial__c);
        this.finishDate   = String.valueOf(discountByCustomerType.dataVigenciaFinal__c);
    }

}