trigger Escoamento on Escoamento__c (before insert, before update, after insert, after update, before delete) {
if (EscoamentoHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                EscoamentoHelper.setSaldoLitrosEscoamento(Trigger.new);
                EscoamentoHelper.changeEscoamentoOwner(Trigger.new);
                EscoamentoHelper.fillApuracaoRelation(Trigger.new);
                EscoamentoHelper.changeManagerialTerritory(Trigger.new);
            }
            when BEFORE_UPDATE {
                EscoamentoHelper.changeEscoamentoOwner(Trigger.new);
                EscoamentoHelper.fillApuracaoRelation(Trigger.new);
            }
            when AFTER_INSERT {
                EscoamentoHelper.updateEscoamentoRelationship(Trigger.newMap);
                EscoamentoHelper.calculateBalance(Trigger.newMap);
                EscoamentoHelper.sendToSAP(Trigger.newMap);
            }
            when AFTER_UPDATE {
                EscoamentoHelper.updateEscoamentoRelationship(Trigger.newMap);
                EscoamentoHelper.updateHistory(Trigger.oldMap, Trigger.newMap);
                EscoamentoHelper.calculateBalance(Trigger.newMap);// estava comentado
            }
            when BEFORE_DELETE {
                EscoamentoHelper.withdrawBalance(Trigger.oldMap);
            }
        }
    } 
}