trigger Campanha on Campanha__c (before insert, before update) {
    if (CampanhaHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                CampanhaHelper.changeRecordType(Trigger.new);
            }   
            when BEFORE_INSERT{
                CampanhaHelper.changeRecordType(Trigger.new);
            }
        }
    } 
}