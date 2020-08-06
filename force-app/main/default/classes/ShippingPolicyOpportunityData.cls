public class ShippingPolicyOpportunityData {
    
    public String businessLocation;
    public String UF;
    public String shipmentCondition;
    public Boolean exportFreight;


    public ShippingPolicyOpportunityData(Opportunity opportunity) {
        this.shipmentCondition  = opportunity.condicaoExpedicao__c;
        this.businessLocation   = opportunity.localNegocio__c;
        this.UF                 = opportunity.recebedorMercadoria__c != null ? opportunity.recebedorMercadoria__r.shippingState : opportunity.account.shippingState;
        this.exportFreight      = opportunity.account.CanalDistribuicao__c == '20';
    }

    public ShippingPolicyOpportunityData(OpportunityData opportunityData) {
        this.shipmentCondition  = opportunityData.shipmentCondition;
        this.businessLocation   = opportunityData.businessLocation;
        this.UF                 = opportunityData.uf;
        this.exportFreight      = opportunityData.distributionChannel == '20';
    }
}