public class PicklistEntryData {

    public String  value;
    public String  label;
    public Boolean isDefault;

    public static Set<String> invalidValues {get;set;}

    static{
        invalidValues = InvalidValuesOppScreen__c.getAll().keySet();
    }

    public PickListEntryData(String label, String value, Boolean isDefault){
        this.value = value;
        this.label = label;
        this.isDefault = isDefault;
    }
    
    public PicklistEntryData(Schema.PicklistEntry pickListEntry) {
        this.value = pickListEntry.getLabel();
        this.label = pickListEntry.getValue();
        this.isDefault = pickListEntry.isDefaultValue();
    }
    public PicklistEntryData(Schema.PicklistEntry pickListEntry, Boolean overrideValues) {
        this.value = pickListEntry.getValue();
        this.label = pickListEntry.getLabel();
        this.isDefault = pickListEntry.isDefaultValue();
    }
    public static List<PicklistEntryData> filterInvalidValues(List<PicklistEntryData> valuesList){
        for(integer i = valuesList.size()-1; i>=0; i--){
            PicklistEntryData pickListvalue = valuesList[i];
            if(invalidValues.contains(pickListvalue.value) || invalidValues.contains(pickListvalue.label)){
                valuesList.remove(i);
            }
        }
        return valuesList;
    }
}