trigger GoalsAffiliates on MetaFilial__c (before insert, before update, after insert, after update) {
 if (GoalsAffiliatesHelper.IsTriggerEnabled()){
            switch on Trigger.operationType{
            when BEFORE_INSERT {
                GoalsAffiliatesHelper.checkBeforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                GoalsAffiliatesHelper.updateApuracao(Trigger.newMap);
            }
            when AFTER_INSERT {                
                GoalsAffiliatesHelper.insertApuracao(Trigger.new);
                GoalsAffiliatesHelper.updateMeta(Trigger.new);
            }
            when AFTER_UPDATE {
                GoalsAffiliatesHelper.updateMeta(Trigger.new);
            }
        }
    }
}