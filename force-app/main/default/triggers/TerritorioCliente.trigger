trigger TerritorioCliente on TerritorioCliente__c (before insert, before update, before delete, after insert, after update) {
    if (TerritorioClienteHelper.isTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                TerritorioClienteHelper.updateTerritoriosConcatenadosField(Trigger.new, Trigger.operationType);
                TerritorioClienteHelper.insertAccountSharingRules(Trigger.new);
            }
            when BEFORE_UPDATE {
                TerritorioClienteHelper.updateTerritoriosConcatenadosField(Trigger.new, Trigger.operationType);
                TerritorioClienteHelper.updateAccountSharingRules(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                TerritorioClienteHelper.updateTerritoriosConcatenadosField(Trigger.old, Trigger.operationType);
                TerritorioClienteHelper.deleteAccountSharingRules(Trigger.old);
            }
            when AFTER_INSERT{
                TerritorioClienteHelper.managerialTerritoryChange(Trigger.newMap);
            }
            when AFTER_UPDATE{
                TerritorioClienteHelper.managerialTerritoryChange(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}