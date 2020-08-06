public class OpportunityData {

    public String regional;
    public String territory;
    public String salesOrganization;
    public String businessLocation;
    public String shipmentCondition;
    public String UF;
    public String distributionChannel;

    public OpportunityData(){}

    public OpportunityData(String shipmentCondition, String businessLocation, String uf){
        this.shipmentCondition = shipmentCondition;
        this.businessLocation = businessLocation;
        this.uf = uf;
    }

    public void setDistributionChannel(String channel) {
        this.distributionChannel = channel;
    }
}