public virtual class OpportunityAppReturnedBaseData extends ResultTemplate{

    public OpportunityAppBaseData data;
    
    public OpportunityAppReturnedBaseData() {}

    public OpportunityAppReturnedBaseData(OpportunityAppBaseData opportunityAppBaseData) {
        this.data = opportunityAppBaseData;
        this.hasErrors = false;
        this.message = message;
    }

    public OpportunityAppReturnedBaseData(String message){
        this.data = null;
        this.hasErrors = true;
        this.message = message;
    }
}