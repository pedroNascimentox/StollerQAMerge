trigger ClienteFamilia on ClienteFamilia__c (before insert, after insert, before delete) {
    if (ClienteFamiliaHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                ClienteFamiliaHelper.checkBeforeInsert(Trigger.new);                
            }
            when AFTER_INSERT {
                ClienteFamiliaHelper.calcAfterInsert(Trigger.new);
            }
            when BEFORE_DELETE{
                ClienteFamiliaHelper.checkBeforeDelete(Trigger.old);
            }
        }
    }
}