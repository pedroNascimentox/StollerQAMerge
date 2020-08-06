public class PaymentConditionData {
    
    public String   id;
    public String   name;
    public String   type;
    public Decimal  days;
    public String   currencyOpt;
    public Decimal  value;

    public PaymentConditionData(CondicaoPagamento__c paymentCondition) {
        this.id           = paymentCondition.id;
        this.name         = paymentCondition.descricao__c;
        this.type         = paymentCondition.tipo__c;
        this.days         = paymentCondition.dias__c;
        this.currencyOpt  = paymentCondition.moeda__c;
        this.value        = paymentCondition.vig_ncias_Condi_o_Pagamento__r[0].jurosComercialFinanceiro__c;
    }
}