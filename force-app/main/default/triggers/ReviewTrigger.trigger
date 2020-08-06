trigger ReviewTrigger on Depoimento__c (before insert, before update) {
    if (ReviewHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                ReviewHelper.changeDepoimentoOwner(Trigger.new);
            }
            when BEFORE_UPDATE {
                ReviewHelper.changeDepoimentoOwner(Trigger.new);
            }
        }
    }
}