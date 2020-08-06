trigger TerritorioTrigger on Territorio__c (before update) {
    if (TerritorioHelper.isTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_UPDATE {
                TerritorioHelper.updateAccountSharingRules(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}