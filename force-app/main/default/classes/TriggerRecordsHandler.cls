public class TriggerRecordsHandler {
    private TriggerContextRecord[] records;

    //TODO: handle 'oldMap' null value (trigger 'insert' event)
    public TriggerRecordsHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        records = new TriggerContextRecord[]{};
        for(Id recordId : newMap.keySet()){
            SObject oldRecord = oldMap.get(recordId),
                    newRecord = newMap.get(recordId);

            records.add(new TriggerContextRecord(oldRecord, newRecord));
        }
    }

    public TriggerContextRecord[] getRecords(){
        return records;
    }

    public TriggerContextRecord[] getChangedOn(String fieldName){
        TriggerContextRecord[] changedRecords = new TriggerContextRecord[]{};

        for(TriggerContextRecord r : records){
            if (r.hasChangesOn(fieldName)){
                changedRecords.add(r);
            }
        }

        return changedRecords;
    }
    
    public TriggerContextRecord[] getChangedOn(Set<String> fieldNames){
        TriggerContextRecord[] changedRecords = new TriggerContextRecord[]{};

        for(TriggerContextRecord r : records){
            if (r.hasChangesOn(fieldNames)){
                changedRecords.add(r);
            }
        }

        return changedRecords;
    }

    public SObject[] getChangedRecordsOn(String fieldName){
        SObject[] changedRecords = new SObject[]{};

        for(TriggerContextRecord r : records){
            if (r.hasChangesOn(fieldName)){
                changedRecords.add(r.getNewRecord());
            }
        }

        return changedRecords;
    }
}