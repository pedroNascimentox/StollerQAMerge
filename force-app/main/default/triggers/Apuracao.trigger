trigger Apuracao on Apuracao__c (before insert, before update, after insert, after update) {
    if (ApuracaoHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                ApuracaoHelper.changeApuracaoOwner(Trigger.new);
            }
            when BEFORE_UPDATE {
                ApuracaoHelper.changeApuracaoOwner(Trigger.new);
            }
            when AFTER_INSERT {
                IntegrationUtils.checkDuplicity(Trigger.newMap, 'CriterioApuracao__c', Label.MessageErrorDuplicity); // formula field
            }
            when AFTER_UPDATE {
                IntegrationUtils.checkDuplicity(Trigger.newMap, Trigger.oldMap, 'CriterioApuracao__c', Label.MessageErrorDuplicity); // formula field
            }
        }
    }
}