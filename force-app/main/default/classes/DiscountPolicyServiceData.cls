public class DiscountPolicyServiceData {

    public Decimal  maxDiscount;
    public Decimal  minimumDiscount;
    public Decimal  recommendedDiscount;
    public String   discountPolicyId;
    public String   initialDate;
    public String   finishDate;
    public String   message;
    public Boolean  hasErrors;

    public DiscountPolicyServiceData(PoliticaDesconto__c discountPolicy) {
        this.discountPolicyId    = discountPolicy.id;
        this.maxDiscount         = discountPolicy.maximo__c;
        this.minimumDiscount     = discountPolicy.minimo__c;
        this.recommendedDiscount = discountPolicy.recomendado__c;
        this.initialDate         = String.valueOf(discountPolicy.dataVigenciaInicial__c);
        this.finishDate          = String.valueOf(discountPolicy.DataVigenciaFinal__c);
        this.hasErrors           = false;
        this.message             = 'Success';
    }

    public DiscountPolicyServiceData(String message){
        this.discountPolicyId    = null;
        this.maxDiscount         = 0;
        this.minimumDiscount     = 0;
        this.recommendedDiscount = 0;
        this.initialDate         = null;
        this.finishDate          = null;
        this.hasErrors           = true;
        this.message             = message;
    }
}