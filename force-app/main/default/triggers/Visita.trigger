trigger Visita on Visita__c (before update) {
    if (VisitaHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                VisitaHelper.validateCheckFields(Trigger.oldMap, Trigger.newMap);
            }
        }
    } 
}