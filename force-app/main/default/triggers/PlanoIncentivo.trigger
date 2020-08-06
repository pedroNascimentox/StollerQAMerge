trigger PlanoIncentivo on PlanoIncentivo__c (before update, before delete) {
    if (PlanoIncentivoHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                PlanoIncentivoHelper.checkStatusIncentivePlan(Trigger.new);
            }
            when BEFORE_DELETE {
                PlanoIncentivoHelper.checkBeforeDelete(Trigger.old);
            }
        }
    }
}