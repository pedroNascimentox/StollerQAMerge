global class VisitController {
	@AuraEnabled
    global static void check(Id recordId, Boolean isCheckIn, Decimal[] latLng){
        
        SObject record = recordId.getSobjectType().newSObject(recordId);
        
        if (isCheckIn){
            record.put('LocalizacaoGeograficaCheckIn__latitude__s',  latLng[0]);
            record.put('LocalizacaoGeograficaCheckIn__longitude__s', latLng[1]);
            record.put('dataHorarioVisitaCheckIn__c', System.now());
        } else {
            record.put('LocalizacaoGeograficaCheckOut__latitude__s',  latLng[0]);
            record.put('LocalizacaoGeograficaCheckOut__longitude__s', latLng[1]);
            record.put('dataHorarioVisitaCheckOut__c', System.now());
        }
        
        update record;
    }
}