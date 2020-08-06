trigger ProgramacaoEntrega on ProgramacaoEntrega__c (before update, after insert, before insert, after update, before delete) {
        if (ProgramacaoEntregaHelper.IsTriggerEnabled()){
            switch on Trigger.operationType{
            when BEFORE_INSERT {
                //ProgramacaoEntregaHelper.validateQuantity(Trigger.new);
                ProgramacaoEntregaHelper.statusCenterAgro(Trigger.new, new Map<Id, ProgramacaoEntrega__c>(), Trigger.isInsert);
                ProgramacaoEntregaHelper.changeProgramacaoEntregaOwner(Trigger.new);
            }
            when AFTER_INSERT {
                ProgramacaoEntregaHelper.updateApuracaoRelation(Trigger.newMap);
                ProgramacaoEntregaHelper.insertOrder(Trigger.new);
            }
            when BEFORE_UPDATE {
                //ProgramacaoEntregaHelper.validateQuantity(Trigger.new);
                ProgramacaoEntregaHelper.updateTotalPrice(Trigger.newMap, Trigger.oldMap);
                ProgramacaoEntregaHelper.checkTotalAmount(Trigger.new, Trigger.oldMap);
                ProgramacaoEntregaHelper.statusCenterAgro(Trigger.new, Trigger.oldMap, Trigger.isInsert);
                ProgramacaoEntregaHelper.insertOrder(Trigger.new, Trigger.oldMap, Trigger.isInsert);
                ProgramacaoEntregaHelper.updatePlanoIncentivo(Trigger.new);
                ProgramacaoEntregaHelper.changeProgramacaoEntregaOwner(Trigger.new);
            }
            when AFTER_UPDATE {
                ProgramacaoEntregaHelper.updateApuracaoRelation(Trigger.newMap); 
                ProgramacaoEntregaHelper.updateApWallet(Trigger.newMap, Trigger.oldMap);
            }
            when BEFORE_DELETE {
                //ProgramacaoEntregaHelper.validateQuantity(Trigger.old);
                ProgramacaoEntregaHelper.updateApuracaoField(Trigger.old);
            }
        }
    }
}