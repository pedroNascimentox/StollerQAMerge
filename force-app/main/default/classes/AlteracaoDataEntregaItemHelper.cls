public class AlteracaoDataEntregaItemHelper extends TriggerContext {

    public static void markOrderItemsAsBlocked(Map<Id, AlteracaoDataEntregaItem__c> newRecordsMap){
        List<Id> contextIds = Collection.of(
                                  newRecordsMap.values()
                              ).pluckIds(AlteracaoDataEntregaItem__c.programacaoEntrega__c);
        List<Id> contextFatherIds = new List<Id>();
        for(ProgramacaoEntrega__c related : [SELECT id, ProgramacaoEntrega__c FROM ProgramacaoEntrega__c WHERE Id IN : contextIds AND ProgramacaoEntrega__c != null]){
            contextFatherIds.add(related.ProgramacaoEntrega__c);
        }
        Map<Id, OrderItem> relatedItemsMap = new Map<Id, OrderItem>([
            SELECT 
                id,
                statusSAP__c
            FROM OrderItem
            WHERE programacaoEntrega__c IN :contextIds
            OR programacaoEntrega__c IN :contextFatherIds
        ]);

        for(OrderItem orderItem : relatedItemsMap.values()){
            orderItem.MotivoRecusaItem__c = 'Z1';
        }

        update relatedItemsMap.values();
    }

}