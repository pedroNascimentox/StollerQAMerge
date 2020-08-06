public class TriggerContextRecordChanges{
    
    private Map<String, Boolean> fieldNameToChanges;
    public TriggerContextRecordChanges(){
        fieldNameToChanges = new Map<String, Boolean>();
    } 
    
    public void addChange(String fieldName, Boolean value){
        fieldNameToChanges.put(fieldName, value);
    }
    
    public Boolean hasAny(){
        for(Boolean hasChanges : fieldNameToChanges.values()){
            if (hasChanges){
                return true;
            }
        }
        return false;
    }
    
    public Set<String> getChangedFields(){
        Set<String> fields = new Set<String>();
        for(String fieldName : fieldNameToChanges.keySet()){
            if (fieldNameToChanges.get(fieldName)){
                fields.add(fieldName);
            }
        }
        return fields;
    }
}