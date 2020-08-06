public class CancellingAppBaseData extends OpportunityAppBaseData {

    public List<CancellingTypeData> cancellingTypes;
    
    public CancellingAppBaseData(){
        super();
    }

    public void fetchCancellingReasons(){
        this.cancellingTypes = new List<CancellingTypeData>();
        
        List<Schema.PicklistEntry> cancellingTypePicklistValues = Cancelamento__c.MotivoCancelamento__c.getDescribe().getPicklistValues();

        for(Schema.PicklistEntry picklistValue : cancellingTypePicklistValues){
            this.cancellingTypes.add(new CancellingTypeData(picklistValue.getLabel(), picklistValue.getValue()));
        }
    }
}