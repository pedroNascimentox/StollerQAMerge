trigger CaseTrigger on Case (before insert, before update, after update) {
    if (CaseHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                CaseHelper.changeCaseOwner(Trigger.new);
            }
            when BEFORE_UPDATE {
                CaseHelper.changeCaseOwner(Trigger.new);
            }
            when AFTER_UPDATE {
                CaseHelper.sendEmail(Trigger.new, Trigger.oldMap, Trigger.isInsert);
            }
        }
    }
}