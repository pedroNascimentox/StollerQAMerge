trigger TerritorioTrigger on Territorio__c (before update, after update) {
    if (TerritorioHelper.isTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_UPDATE {
                TerritorioHelper.updateAccountSharingRules(Trigger.oldMap, Trigger.newMap);                
            }
            when AFTER_UPDATE {
                TerritorioHelper.updateApuracaoSharingRTV(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}