public class DiscountPolicyOpportunityData {

    public Id       regional;
    public Id       territory;
    public Id       customer;
    public Id       customersHierarchy;
    public String   salesOrganization;
    
    public DiscountPolicyOpportunityData(Opportunity opportunity) {
        this.regional           = opportunity.regional__c;
        this.territory          = opportunity.territorio__c;
        this.customer           = opportunity.accountId;
        this.customersHierarchy = opportunity.account.parentId;
        this.salesOrganization  = opportunity.organizacaoVenda__c;
    }

    public DiscountPolicyOpportunityData(TerritoryData territoryData, String accountId, String parentId) {
        this.regional           = (territoryData != null? (territoryData.regional  != null? territoryData.regional  : null) : null);
        this.territory          = (territoryData != null? (territoryData.territory != null? territoryData.territory : null) : null);
        this.customer           = accountId;
        this.customersHierarchy = parentId;
        this.salesOrganization  = '1000'; // default
    }
}