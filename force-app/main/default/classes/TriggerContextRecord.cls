public class TriggerContextRecord{
    
    private SObject oldRecord;
    private SObject newRecord;
    
    public TriggerContextRecord(SObject oldRecord, SObject newRecord){
        this.oldRecord = oldRecord;
        this.newRecord = newRecord;
    }
    
    public SObject getNewRecord(){
        return this.newRecord;
    }
    
    public SObject getOldRecord(){
        return this.oldRecord;
    }
    
    public Object get(String s){
        return getNew(s);
    }
    
    public Id getId(){
        return getNewRecord().id;
    }
    
    public Object getNew(String s){
        return this.newRecord.get(s);
    }
    
    public Object getOld(String s){
        return this.oldRecord.get(s);
    }
    
    public Boolean hasChangesOn(String fieldName){
        return getNew(fieldName) != getOld(fieldName);
    }
    
    public TriggerContextRecordChanges getChangesOn(Set<String> fieldNames){
        TriggerContextRecordChanges result = new TriggerContextRecordChanges();
        
        for(String fieldName : fieldNames){
            result.addChange(fieldName, getNew(fieldName) != getOld(fieldName));
        }
        
        return result;
    }
    
    public Boolean hasChangesOn(Set<String> fieldNames){
        TriggerContextRecordChanges result = new TriggerContextRecordChanges();
        
        for(String fieldName : fieldNames){
            result.addChange(fieldName, getNew(fieldName) != getOld(fieldName));
        }
        
        return result.hasAny();
    }
}