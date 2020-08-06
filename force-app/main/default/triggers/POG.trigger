trigger POG on POG__c (after update) {
if (POGHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_UPDATE {
                POGHelper.updateHistory(Trigger.oldMap, Trigger.newMap);
            }
        }
    } 
}