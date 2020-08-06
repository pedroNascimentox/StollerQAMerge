public virtual class OpportunityAppDataRequest {

    public String accountId;
    public String receiverId;
    public String shipmentCondition;
    public String freightType;
    public String businessPlaceId;
    public String currencyName;
    public String priceReferenceDate;
    public TerritoryData territoryData;
    public List<Id> cultures;
    
    public OpportunityAppDataRequest() {}
}