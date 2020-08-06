trigger ClientesPlanoIncentivo on ClientesPlanoIncentivos__c (before insert, after insert, before delete) {
    if (ClientesPlanoIncentivoHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                ClientesPlanoIncentivoHelper.checkBeforeInsert(Trigger.new);                
            }
            when AFTER_INSERT {
                ClientesPlanoIncentivoHelper.calcAfterInsert(Trigger.new);
            }
            when BEFORE_DELETE{
                ClientesPlanoIncentivoHelper.checkBeforeDelete(Trigger.old);
            }
        }
    }
}