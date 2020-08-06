public class VisitaHelper extends TriggerContext{
    
    public static final String CHECK_IN_CHECK_OUT_ORDER_ERROR = 'Você deve realizar o check-in antes do check-out.';
    public static final String CHECK_FIELD_CHANGE_ERROR = 'Você não pode alterar as informações de check-in e de check-out após seu preenchimento.';
        
    public static void validateCheckFields(Map<Id, Visita__c> oldRecordsMap, Map<Id, Visita__c> newRecordsMap){         
        for(Visita__c visit : newRecordsMap.values()){
            
            if (visit.dataHorarioVisitaCheckIn__c == null && visit.dataHorarioVisitaCheckOut__c != null){
                visit.addError(CHECK_IN_CHECK_OUT_ORDER_ERROR);
            }
            
            if (visit.LocalizacaoGeograficaCheckIn__latitude__s == null && visit.LocalizacaoGeograficaCheckOut__latitude__s != null || 
                visit.LocalizacaoGeograficaCheckIn__longitude__s == null && visit.LocalizacaoGeograficaCheckOut__longitude__s != null
            ){
            	visit.addError(CHECK_IN_CHECK_OUT_ORDER_ERROR);    
            }
        }
        
        Set<String> fieldsToCheckForChanges = new Set<String>{
            'LocalizacaoGeograficaCheckIn__latitude__s',
            'LocalizacaoGeograficaCheckIn__longitude__s',
            'dataHorarioVisitaCheckIn__c', 
            'dataHorarioVisitaCheckOut__c'
        };
        
        TriggerRecordsHandler visitRecordsHandler = new TriggerRecordsHandler(oldRecordsMap, newRecordsMap);
        TriggerContextRecord[] visitChangedRecords = visitRecordsHandler.getChangedOn(fieldsToCheckForChanges);
        
        for(TriggerContextRecord record : visitChangedRecords){
            TriggerContextRecordChanges changes = record.getChangesOn(fieldsToCheckForChanges);
            Visita__c newVisit = (Visita__c) record.getNewRecord();
            Visita__c oldVisit = (Visita__c) record.getOldRecord();
            
            for(String fieldName : changes.getChangedFields()){
                if (oldVisit.get(fieldName) != null && newVisit.get(fieldName) != null){
                    newVisit.addError(CHECK_FIELD_CHANGE_ERROR);
                }
            }
        }
    }
}