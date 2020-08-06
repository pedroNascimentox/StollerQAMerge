public with sharing class AlteracaoDataEntregaHelper extends TriggerContext{
    
    public static void markOrderItemsAsBlocked(Map<Id, AlteracaoDataEntrega__c> newRecordsMap, Map<Id, AlteracaoDataEntrega__c> oldRecordsMap ){
        List<Id> contextIds = new List<Id>();
        for(AlteracaoDataEntrega__c req : newRecordsMap.values()){
            AlteracaoDataEntrega__c oldReq = oldRecordsMap.get(req.Id);
            if(req.Status__c == 'Rejeitado' && req.Status__c != oldReq.Status__c){
                contextIds.add(req.Id);
            }
        }
        Set<Id> ordItemIdSet = new Set<id>();
        for(AlteracaoDataEntregaItem__c related : [SELECT id, ItemPedido__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c IN : contextIds  AND ItemPedido__c != null]){
            ordItemIdSet.add(related.ItemPedido__c);
        }
        Map<Id, OrderItem> relatedItemsMap = new Map<Id, OrderItem>([
            SELECT 
                id, ProgramacaoEntrega__c,
                statusSAP__c, StatusGlobalItem__c, MotivoRecusaItem__c, numeroRemessa__c, SaldoFornecer__c, QuantidadeConfirmada__c, quantity, 
                OrderId
            FROM OrderItem
            WHERE ID IN :ordItemIdSet
        ]);

        Map<Id, Order> ordIdMap = new Map<Id, Order>([SELECT id, BloqueioRemessa__c FROM Order WHERE id IN : Collection.of(relatedItemsMap.values()).pluckIds(OrderItem.OrderId)]);

        for(OrderItem orderItem : relatedItemsMap.values()){
            orderItem.MotivoRecusaItem__c = '';
            IntegrationInboundOrder.setStatusSAP(orderItem, ordIdMap.get(orderITem.orderId));
        }

        update relatedItemsMap.values();
        
    }
    
    public static void cancelRelatedDeliveryItems(Map<Id, AlteracaoDataEntrega__c> oldRecordsMap, Map<Id, AlteracaoDataEntrega__c> newRecordsMap){
        TriggerRecordsHandler recordsHandler = new TriggerRecordsHandler(oldRecordsMap, newRecordsMap);
        Collection changedRecordsCollection = Collection.of(recordsHandler.getChangedRecordsOn('status__c'));
        
        AlteracaoDataEntrega__c[] rejectedRecords = changedRecordsCollection.filter(Match.field('status__c').equals('Rejeitado')).asList();
        AlteracaoDataEntrega__c[] approvedRecords = changedRecordsCollection.filter(Match.field('status__c').equals('Aprovado')).asList();

        AlteracaoDataEntregaItem__c[] alteracaoItemRecords = [SELECT id, programacaoEntrega__c, QuantidadeProgramada__c, DataEntregaOriginal__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c IN : Collection.of(rejectedRecords).pluckIds()];

        AlteracaoDataEntregaItem__c[] approvedItemRecords = [SELECT id, programacaoEntrega__c, QuantidadeProgramada__c, DataEntregaOriginal__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c IN : Collection.of(approvedRecords).pluckIds()];

        List<ProgramacaoEntrega__c> deliveryRecordsToUpdate = new List<ProgramacaoEntrega__c>();
        List<ProgramacaoEntrega__c> deliveryRecordsToDelete = new List<ProgramacaoEntrega__c>();
        
        for(AlteracaoDataEntregaItem__c deliveryChange : approvedItemRecords){
            ProgramacaoEntrega__c deliveryRecord = new ProgramacaoEntrega__c(
                status__c = 'Aprovada alteração data de entrega',
                id = deliveryChange.programacaoEntrega__c
            );

            deliveryRecordsToUpdate.add(deliveryRecord);
        }
        for(AlteracaoDataEntregaItem__c deliveryChange : alteracaoItemRecords){
            ProgramacaoEntrega__c deliveryRecord = new ProgramacaoEntrega__c(
                status__c = 'Integrado',
                statusSap__c = 'Confirmado',
                id = deliveryChange.programacaoEntrega__c
            );

            deliveryRecordsToUpdate.add(deliveryRecord);
        }

        /*
        Map<Id, AlteracaoDataEntregaItem__c> deliveryToCancellingRecord = new Map<Id, AlteracaoDataEntregaItem__c>();
        for(AlteracaoDataEntregaItem__c cancellingRecord : alteracaoItemRecords){
            deliveryToCancellingRecord.put(cancellingRecord.programacaoEntrega__c, cancellingRecord);
        }
        
        ProgramacaoEntrega__c[] parentDeliveryRecords = [
            SELECT 
                programacaoEntrega__c,
                programacaoEntrega__r.id, 
                programacaoEntrega__r.statusSAP__c, 
                programacaoEntrega__r.QuantidadeDisponivelSAP__c, 
                programacaoEntrega__r.QuantidadeProgramada__c,
                programacaoEntrega__r.PrecoVendasComJurosUSDBRL__c,

                id,
                statusSAP__c,
                QuantidadeDisponivelSAP__c,
                QuantidadeProgramada__c,
                QuantidadeOriginal__c

            FROM ProgramacaoEntrega__c
            WHERE id IN :Collection.of(alteracaoItemRecords).pluckIds('programacaoEntrega__c')
        ];
        for(ProgramacaoEntrega__c deliveryRecord : parentDeliveryRecords){
            //String targetField = (deliveryRecord.statusSAP__c == 'Faturado Parcial')? 'QuantidadeDisponivelSAP__c' : 'QuantidadeProgramada__c';

            //AlteracaoDataEntregaItem__c cancellingRecord = deliveryToCancellingRecord.get(deliveryRecord.id);

            if(deliveryRecord.ProgramacaoEntrega__c != null){
                cancellingRecord.programacaoEntrega__c = deliveryRecord.programacaoEntrega__c;   

                ProgramacaoEntrega__c deliveryRecordToUpdate = new ProgramacaoEntrega__c(
                    id = deliveryRecord.programacaoEntrega__c,
                    quantidadeDisponivelSAP__c = deliveryRecord.programacaoEntrega__r.QuantidadeDisponivelSAP__c,
                    quantidadeProgramada__c = cancellingRecord.QuantidadeProgramada__c
                );           
                deliveryRecordToUpdate.ValorTotal__c = Integer.valueOf(deliveryRecordToUpdate.get(targetField)) * deliveryRecord.programacaoEntrega__r.PrecoVendasComJurosUSDBRL__c;


                deliveryRecordsToUpdate.add(deliveryRecordToUpdate);
                deliveryRecordsToDelete.add(deliveryRecord);         
            }else{
                ProgramacaoEntrega__c deliveryRecordToUpdate = new ProgramacaoEntrega__c(
                    id = deliveryRecord.Id,
                    Status__c = 'Integrado',
                    DataEntrega__c = cancellingRecord.DataEntregaOriginal__c
                );           
                deliveryRecordsToUpdate.add(deliveryRecordToUpdate);
                
             }   
        }
        
         if(!deliveryRecordsToDelete.isEmpty())        
             delete deliveryRecordsToDelete;
            */
        if(!deliveryRecordsToUpdate.isEmpty())                
            update deliveryRecordsToUpdate;

    }
}