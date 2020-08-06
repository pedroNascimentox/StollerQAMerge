trigger Goals on Meta__c (before insert, after insert, before update, after update) {
    if (GoalsHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                GoalsHelper.changeMetaOwner(Trigger.new);
            }
            when AFTER_INSERT {
                IntegrationUtils.checkDuplicity(Trigger.newMap, 'CriterioMeta__c', Label.MessageErrorDuplicity); // formula field
                GoalsHelper.insertApuracao(Trigger.new);
            }
            when BEFORE_UPDATE {
                GoalsHelper.updateApuracao(Trigger.newMap);
                GoalsHelper.changeMetaOwner(Trigger.new);
            }
            when AFTER_UPDATE {
                IntegrationUtils.checkDuplicity(Trigger.newMap, Trigger.oldMap, 'CriterioMeta__c', Label.MessageErrorDuplicity); // formula field
            }
        }
    }
}