public class OpportunityAppReturnedData extends ResultTemplate {

    public OpportunityAppData data;

    public OpportunityAppReturnedData(){}

    public OpportunityAppReturnedData(OpportunityAppData opportunityAppData) {
        this.data       = opportunityAppData;
        this.hasErrors  = false;
        this.message    = 'Success';
        this.stackStrace = null;
    }

    public OpportunityAppReturnedData(Exception error) {
        this.data        = null;
        this.hasErrors   = true;
        this.message     = error.getMessage();
        this.stackStrace = error.getStackTraceString();
    }

    public OpportunityAppReturnedData(String message) {
        this.data        = null;
        this.hasErrors   = false;
        this.message     = message;
        this.stackStrace = null;
    }
}