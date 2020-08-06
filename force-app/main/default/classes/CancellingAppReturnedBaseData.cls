public class CancellingAppReturnedBaseData extends OpportunityAppReturnedBaseData{
    public CancellingAppBaseData data;

    public CancellingAppReturnedBaseData(CancellingAppBaseData opportunityAppBaseData) {
        super(opportunityAppBaseData);
        this.data = opportunityAppBaseData;
    }

    public CancellingAppReturnedBaseData(String message){
        super(message);
    }

    public CancellingAppReturnedBaseData(){
        super();
    }
}