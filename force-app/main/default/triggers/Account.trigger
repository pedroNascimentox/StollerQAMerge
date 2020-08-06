trigger Account on Account (before insert, before update) {
    if (AccountHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                AccountHelper.getCredit(Trigger.new, Trigger.oldMap, Trigger.isInsert);
                AccountHelper.updateCredit(Trigger.newMap, Trigger.oldMap);
            }
            when BEFORE_INSERT {
                AccountHelper.getCredit(Trigger.new, new Map<Id, Account>(), Trigger.isInsert);                
            }
        }
    } 
}