public class CancelamentoHelper extends TriggerContext {
    public static void updateRelatedDeliveryItems(Map<Id, Cancelamento__c> oldRecordsMap, Map<Id, Cancelamento__c> newRecordsMap){
        Boolean isUpdate = oldRecordsMap != null;

        if (isUpdate){
            markOrderItemsAsBlocked(newRecordsMap, oldRecordsMap);
            cancelRelatedDeliveryItems(oldRecordsMap, newRecordsMap);
        } else {
            markOrderItemsAsBlocked(newRecordsMap);
            updateRelatedDeliveryItems(newRecordsMap);
        }
    }

    private static void cancelRelatedDeliveryItems(Map<Id, Cancelamento__c> oldRecordsMap, Map<Id, Cancelamento__c> newRecordsMap){
        TriggerRecordsHandler recordsHandler = new TriggerRecordsHandler(oldRecordsMap, newRecordsMap);
        Collection changedRecordsCollection = Collection.of(recordsHandler.getChangedRecordsOn('status__c'));

        Cancelamento__c[] cancelledRecords = changedRecordsCollection.filter(Match.field('status__c').equals('Cancelado')).asList();
        // Set<Id> rejectedRecordsIds = changedRecordsCollection.filter(Match.field('status__c').equals('Cancelamento reprovado')).asMap().keySet();
        Cancelamento__c[] rejectedRecordsIds = changedRecordsCollection.filter(Match.field('status__c').equals('Cancelamento reprovado')).asList();

        List<ProgramacaoEntrega__c> deliveryRecordsToInsert = new List<ProgramacaoEntrega__c>();
        List<ProgramacaoEntrega__c> deliveryRecordsToUpdate = new List<ProgramacaoEntrega__c>();
        List<ProgramacaoEntrega__c> deliveryRecordsToDelete = new List<ProgramacaoEntrega__c>();

        Map<Id, SolicitacaoCancelamento__c> reqIdMap = new Map<Id, SolicitacaoCancelamento__c>();
        for(SolicitacaoCancelamento__c req : [SELECT id, OrdemIntegrada__c FROM SolicitacaoCancelamento__c WHERE id IN :changedRecordsCollection.pluckIds(Cancelamento__c.SolicitacaoCancelamento__c)]){
            reqIdMap.put(req.Id, req);
        }

        Set<Id> deliveryIdSet = new Set<Id>();
        for(Cancelamento__c cancellingRecord : cancelledRecords){
            deliveryIdSet.add(cancellingRecord.programacaoEntrega__c);
        }

        Map<Id, ProgramacaoEntrega__c> deliveryIdMap = new Map<Id, ProgramacaoEntrega__c>();
        for(ProgramacaoEntrega__c req : 
            [
                SELECT Id,
                       Confirmado__c,
                       PrecoVendasComJurosUSDBRL__c,
                       Cultura__c,
                       Produto__r.Litragem__c,
                       DataEntrega__c,
                       DataFaturamento__c,
                       DataConfirmacao__c,
                       DescontoConcedido__c,
                       DescontoTipoCliente__c,
                       DiretorComercial__c,
                       DiretorNegocios__c,
                       GerenteRegional__c,
                       EmissorOrdem__c,
                       ClienteOrigemRemanejamento__c,
                       IdOportunidade__c,
                       Juros__c,
                       Litros__c,
                       LocalNegocio__c,
                       NomeRTV__c,
                       NomeUsuarioConfirmacao__c,
                       NumeroPedidoCliente__c,
                       PrazoInterno__c,
                       PrazoItinerario__c,
                       PrecoListaReferencia__c,
                       PrecoLista__c,
                       PrecoVenda__c,
                       PrecoVendaJuros__c,
                       PrecoVendasJurosUSD__c,
                       TaxaDolar__c,
                       PrecoLitro__c,
                       Produto__c,
                       QuantidadeProgramada__c,
                       RecebedorOrdem__c,
                       Regional__c,
                       SaldoLimiteCredito__c,
                       Territorio__c,
                       TipoOrdem__c,
                       ValorFrete__c,
                       ValorTotal__c,
                       ValorUnitario__c,
                       Status__c,
                       StatusSAP__c,
                       ValorTotalUSD__c,
                       RTV__c,
                       Moeda__c,
                       TabelaPreco__c  
                FROM ProgramacaoEntrega__c 
                WHERE id IN :deliveryIdSet
            ]){
            deliveryIdMap.put(req.Id, req);
        }

        for(Cancelamento__c cancellingRecord : cancelledRecords){
            Boolean integrated = reqIdMap.get(cancellingRecord.SolicitacaoCancelamento__c).OrdemIntegrada__c;
            ProgramacaoEntrega__c oldReq = deliveryIdMap.get(cancellingRecord.programacaoEntrega__c);
            ProgramacaoEntrega__c deliveryRecord = new ProgramacaoEntrega__c(
                status__c = 'Cancelado',
                statusSAP__c = 'Cancelado',
                id = cancellingRecord.programacaoEntrega__c
            );

            if(!integrated)
                deliveryRecord.QuantidadeProgramada__c = cancellingRecord.QuantidadeProgramada__c;

            // System.debug('cancellingRecord.QuantidadeProgramada__c != oldReq.QuantidadeProgramada__c => ' + (cancellingRecord.QuantidadeProgramada__c != oldReq.QuantidadeProgramada__c));
            // System.debug('!integrated => ' + !integrated);
            if(cancellingRecord.QuantidadeProgramada__c != oldReq.QuantidadeProgramada__c && !integrated){
                oldReq.id = null;
                oldReq.Status__c = 'Liberado';
                oldReq.IdOrderITem__C = null;
                oldReq.Confirmado__C = false;
                oldReq.IdOpportunityLineItem__c = null;
                oldReq.StatusSAP__c = 'Não Confirmado';
                // System.debug('BEFORE oldReq.QuantidadeProgramada__c => ' + oldReq.QuantidadeProgramada__c);
                oldReq.QuantidadeProgramada__c = (oldReq.QuantidadeProgramada__c - cancellingRecord.QuantidadeProgramada__c);
                // System.debug('AFTER oldReq.QuantidadeProgramada__c => ' + oldReq.QuantidadeProgramada__c);
                oldReq.Litros__c = oldReq.QuantidadeProgramada__c * oldReq.Produto__r.Litragem__c;
                // System.debug('BEFORE oldReq.ValorTotal__c => ' + oldReq.ValorTotal__c);
                // System.debug('oldReq.Moeda__c => ' + oldReq.Moeda__c);
                // System.debug('oldReq.PrecoVendaJuros__c => ' + oldReq.PrecoVendaJuros__c);
                // System.debug('oldReq.PrecoVendasJurosUSD__c => ' + oldReq.PrecoVendasJurosUSD__c);
                // System.debug('oldReq.PrecoVendasComJurosUSDBRL__c => ' + oldReq.PrecoVendasComJurosUSDBRL__c);

                oldReq.ValorTotal__c = oldReq.QuantidadeProgramada__c * oldReq.PrecoVendasComJurosUSDBRL__c;

                oldReq.ValorTotalUSD__c = oldReq.ValorTotal__c / oldReq.TaxaDolar__c;

                if (oldReq.Moeda__c == 'USD') {
                   oldReq.ValorTotal__c = oldReq.ValorTotal__c * oldReq.TaxaDolar__c;
                   oldReq.ValorTotalUSD__c = oldReq.ValorTotalUSD__c * oldReq.TaxaDolar__c;
                }
                // System.debug('AFTER oldReq.ValorTotal__c => ' + oldReq.ValorTotal__c);
                deliveryRecordsToInsert.add(oldReq);
            }

            deliveryRecordsToUpdate.add(deliveryRecord);
        }
        for(Cancelamento__c cancellingRecord : rejectedRecordsIds){
            String currStatus = 'Integrado';
            if(reqIdMap.containsKey(cancellingRecord.SolicitacaoCancelamento__c) && !reqIdMap.get(cancellingRecord.SolicitacaoCancelamento__c).OrdemIntegrada__c){
                currStatus = 'Liberado';
            }
            ProgramacaoEntrega__c deliveryRecord = new ProgramacaoEntrega__c(
                status__c = currStatus,
                statusSAP__c = 'Não Confirmado',
                id = cancellingRecord.programacaoEntrega__c
            );

            deliveryRecordsToUpdate.add(deliveryRecord);
        }
        /*
        List<Cancelamento__c> rejectedRecords = new List<Cancelamento__c>([
            SELECT id, programacaoEntrega__c, pedido__r.ovsap__c
            FROM Cancelamento__c
            WHERE id IN :rejectedRecordsIds
        ]);

        Map<Id, Cancelamento__c> deliveryToCancellingRecord = new Map<Id, Cancelamento__c>();
        for(Cancelamento__c cancellingRecord : rejectedRecords){
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
            WHERE id IN :Collection.of(rejectedRecords).pluckIds('programacaoEntrega__c')
        ];

        for(ProgramacaoEntrega__c deliveryRecord : parentDeliveryRecords){
            
            String targetField = (deliveryRecord.statusSAP__c == 'Faturado Parcial')? 'QuantidadeDisponivelSAP__c' : 'QuantidadeProgramada__c';

            if (deliveryRecord.programacaoEntrega__c != null){

                ProgramacaoEntrega__c deliveryRecordToUpdate = new ProgramacaoEntrega__c(
                    id = deliveryRecord.programacaoEntrega__c,
                    quantidadeDisponivelSAP__c = deliveryRecord.programacaoEntrega__r.QuantidadeDisponivelSAP__c,
                    quantidadeProgramada__c = deliveryRecord.programacaoEntrega__r.QuantidadeProgramada__c
                );
                
                Integer parentPreviousQuantity = Integer.valueOf(deliveryRecordToUpdate.get(targetField));
                Integer deliveryQuantity = Integer.valueOf(deliveryRecord.get(targetField));

                deliveryRecordToUpdate.put(targetField, parentPreviousQuantity + deliveryQuantity);
                deliveryRecordsToDelete.add(deliveryRecord);

                deliveryRecordToUpdate.ValorTotal__c = Integer.valueOf(deliveryRecordToUpdate.get(targetField)) * deliveryRecord.programacaoEntrega__r.PrecoVendasComJurosUSDBRL__c;
                deliveryRecordsToUpdate.add(deliveryRecordToUpdate);

                Cancelamento__c cancellingRecord = deliveryToCancellingRecord.get(deliveryRecord.id);
                cancellingRecord.programacaoEntrega__c = deliveryRecordToUpdate.id;
            } else {

                ProgramacaoEntrega__c deliveryRecordToUpdate = new ProgramacaoEntrega__c(
                    id = deliveryRecord.id
                );

                deliveryRecordToUpdate.put(targetField, deliveryRecord.quantidadeOriginal__c);
                if(deliveryToCancellingRecord.get(deliveryRecord.id).pedido__r.ovsap__c != null){
                    deliveryRecordToUpdate.status__c = 'Integrado';
                }else {
                    deliveryRecordToUpdate.status__c = 'Liberado';
                }

                deliveryRecordsToUpdate.add(deliveryRecordToUpdate);
            }
        }

        delete deliveryRecordsToDelete;
        */
        update deliveryRecordsToUpdate;
                // System.debug('deliveryRecordsToInsert BEFORE TRIGGER PROCESS => ' + JSON.serializePretty(deliveryRecordsToInsert));
        if(!deliveryRecordsToInsert.isEmpty())
            insert deliveryRecordsToInsert;
                // System.debug('deliveryRecordsToInsert AFTER TRIGGER PROCESS => ' + JSON.serializePretty(deliveryRecordsToInsert));
    }
    
    private static void updateRelatedDeliveryItems(Map<Id, Cancelamento__c> newRecordsMap){
        ProgramacaoEntrega__c[] deliveryRecords = new List<ProgramacaoEntrega__c>();
        for(Cancelamento__c cancellingRecord : newRecordsMap.values()){
            ProgramacaoEntrega__c deliveryRecord = new ProgramacaoEntrega__c(
                status__c = 'Solicitado Cancelamento',
                id = cancellingRecord.programacaoEntrega__c
            );

            deliveryRecords.add(deliveryRecord);
        }

        update deliveryRecords;
    }

    public static void markOrderItemsAsBlocked(Map<Id, Cancelamento__c> newRecordsMap){
        List<Id> contextIds = Collection.of(
                                  newRecordsMap.values()
                              ).filter(
                                  Match.field('status__c').equals('Solicitado Cancelamento')
                              )
                              .pluckIds(Cancelamento__c.programacaoEntrega__c);
        //Cancelamento faz referencia a uma nova programação de entrega em alguns momentos, aonde não tem referencia a OrderItem, com isso é necessário pegar a referencia do pai para buscar o OrderItem.
        List<Id> contextFatherIds = new List<Id>();
        for(ProgramacaoEntrega__c related : [SELECT id, ProgramacaoEntrega__c FROM ProgramacaoEntrega__c WHERE Id IN : contextIds]){
            contextFatherIds.add(related.ProgramacaoEntrega__c);
        }

        Map<Id, OrderItem> relatedItemsMap = new Map<Id, OrderItem>([
            SELECT 
                id,
                statusSAP__c
            FROM OrderItem
            WHERE (programacaoEntrega__c IN :contextIds
            OR programacaoEntrega__c IN :contextFatherIds)
            AND programacaoEntrega__c != null
        ]);

        for(OrderItem orderItem : relatedItemsMap.values()){
            orderItem.MotivoRecusaItem__c = 'ZS';
        }

        update relatedItemsMap.values();
    }
    public static void markOrderItemsAsBlocked(Map<Id, Cancelamento__c> newRecordsMap, Map<Id, Cancelamento__c> oldRecordsMap){
        Set<Id> contextReprovedIds = new Set<Id>();
        Set<Id> contextApprovedIds = new Set<Id>();

        for(Cancelamento__c req : newRecordsMap.values()){
            Cancelamento__c oldReq = oldRecordsMap.get(req.Id);
            if(req.Status__c == 'Cancelamento reprovado' && req.Status__c != oldReq.Status__c){
                contextReprovedIds.add(req.ProgramacaoEntrega__c);
            }
            if(req.Status__c == 'Cancelado' && req.Status__c != oldReq.Status__c){
                contextApprovedIds.add(req.ProgramacaoEntrega__c);
            }
        }
        /*
        //Cancelamento faz referencia a uma nova programação de entrega em alguns momentos, aonde não tem referencia a OrderItem, com isso é necessário pegar a referencia do pai para buscar o OrderItem.
        List<Id> contextFatherIds = new List<Id>();
        for(ProgramacaoEntrega__c related : [SELECT id, ProgramacaoEntrega__c FROM ProgramacaoEntrega__c WHERE Id IN :contextReprovedIds AND ProgramacaoEntrega__c != null]){
            contextFatherIds.add(related.ProgramacaoEntrega__c);
        }
        */
        
        Map<Id, OrderItem> relatedItemsMap = new Map<Id, OrderItem>([
            SELECT 
                id, ProgramacaoEntrega__c,
                statusSAP__c, StatusGlobalItem__c, MotivoRecusaItem__c, numeroRemessa__c, SaldoFornecer__c, QuantidadeConfirmada__c, quantity, 
                OrderId
            FROM OrderItem
            WHERE (programacaoEntrega__c IN :contextReprovedIds OR programacaoEntrega__c IN :contextApprovedIds )
        ]);

        Map<Id, Order> ordIdMap = new Map<Id, Order>([SELECT id, BloqueioRemessa__c FROM Order WHERE id IN : Collection.of(relatedItemsMap.values()).pluckIds(OrderItem.OrderId)]);

        for(OrderItem orderItem : relatedItemsMap.values()){
            if(contextApprovedIds.contains(orderItem.ProgramacaoEntrega__c))
                orderItem.StatusSAP__c = 'Cancelado';
            else if(contextReprovedIds.contains(orderItem.ProgramacaoEntrega__c))
                orderItem.MotivoRecusaItem__c = '';

            IntegrationInboundOrder.setStatusSAP(orderItem, ordIdMap.get(orderITem.orderId));
        }

        update relatedItemsMap.values();
    }
    public static void groupItems(Cancelamento__c[] newRecords){
        Set<Id> oppIdSet = new Set<Id>(Collection.of(newRecords).pluckIds(Cancelamento__c.IdOportunidade__c));
        Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>([SELECT id, Moeda__c, NumeroOportunidade__C, Territorio__c, Territorio__r.Diretor__c,  Territorio__r.Diretor__r.ManagerId FROM Opportunity WHERE Id IN :oppIdSet]);
        Map<String, List<Cancelamento__c>> keyToCancellingMap = (Map<String, List<Cancelamento__c>>)Collection.of(newRecords).groupByMappingFunction(new CancellingKeyMapper(oppIdMap));
        Map<Id, Order> orderMAp = new Map<Id, Order>([SELECT id, OVSAP__c FROM Order WHERE Id IN : Collection.of(newRecords).pluckIds(Cancelamento__c.Pedido__c)]);
        Map<String, SolicitacaoCancelamento__c> requestCancelInsertList = new Map<String, SolicitacaoCancelamento__c>();
        for(String key : keyToCancellingMap.keySet()){
            requestCancelInsertList.put(key, createRequest(keyToCancellingMap.get(key), orderMAp, oppIdMap));
        }
        if(!requestCancelInsertList.isEmpty()){
            insert requestCancelInsertList.values();
            for(String key : requestCancelInsertList.keySet()){
                for(Cancelamento__c cancelling : keyToCancellingMap.get(key)){
                    cancelling.SolicitacaoCancelamento__c = requestCancelInsertList.get(key).Id;
                }
            }
            // sendApprovalProcess(requestCancelInsertList.values());
        }
    }

    // public static void callApprovalProcess(Cancelamento__c[] newRecords){
    //     Set<Id> cancellingIdSet = new Set<Id>(Collection.of(newRecords).pluckIds(Cancelamento__c.SolicitacaoCancelamento__c));
    //     List<SolicitacaoCancelamento__c> cancellingList = [SELECT id, OrdemIntegrada__c, valorTotalUSD__c FROM SolicitacaoCancelamento__c WHERE Id IN :cancellingIdSet];
    //     sendApprovalProcess(cancellingList);
    // }

    // public static void sendApprovalProcess(List<SolicitacaoCancelamento__c> relatedCancelling){
    //     List<Approval.ProcessSubmitRequest> appRequest = new List<Approval.ProcessSubmitRequest>();
    //     for(SolicitacaoCancelamento__c requestCancelling : relatedCancelling){
    //         System.debug(requestCancelling);
    //         System.debug('requestCancelling.valorTotalUSD__c => ' + requestCancelling.valorTotalUSD__c);
    //         Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
    //         request.setComments('Processo de aprovação de cancelamento.');
    //         request.setObjectId(requestCancelling.id);
    //         request.setSubmitterId(UserInfo.getUserId()); 
    //         request.setProcessDefinitionNameOrId(requestCancelling.OrdemIntegrada__c ? 'SolicitacaoCancelamentoIntegradoSAP' : 'SolicitacaoCancelamentoNaoIntegradoSAP');

    //         appRequest.add(request);

    //     }
    //     Approval.process(appRequest);
    // }
    public static SolicitacaoCancelamento__c createRequest(List<Cancelamento__c> relatedCancelling, Map<Id, Order> orderMap, Map<Id, Opportunity> oppIdMap){
        Cancelamento__c cancellingData = relatedCancelling[0];
        Opportunity opp = oppIdMap.get(cancellingData.IdOportunidade__c);
        SolicitacaoCancelamento__c requestCancelling = new SolicitacaoCancelamento__c(
            Descricao__c = cancellingData.Descricao__c,
            Oportunidade__c = cancellingData.IdOportunidade__c,
            EmissorOrdem__C = cancellingData.EmissorOrdem__c,
            MotivoCancelamento__C = cancellingData.MotivoCancelamento__c,
            NomeRTV__c = cancellingData.NomeRTV__c,
            GerenteComercial__c = cancellingData.GerenteComercial__c,
            DiretorComercial__c = (opp.Territorio__c != null ? opp.Territorio__r.Diretor__c : cancellingData.DiretorComercial__c),
            DiretorNegocios__c =  (opp.Territorio__c != null && opp.Territorio__r.Diretor__c != null ? opp.Territorio__r.Diretor__r.ManagerId : cancellingData.DiretorNegocios__c),
            GerenteRegional__c = cancellingData.GerenteRegional__c,
            RecebedorOrdem__c = cancellingData.RecebedorOrdem__c, 
            TipoOrdem__c = cancellingData.TipoOrdem__c,
            NumeroOrdemSAP__c = (orderMap.containsKey(cancellingData.Pedido__c) ?orderMap.get(cancellingData.Pedido__c).OVSAP__c : null),
            OrdemIntegrada__c = orderMap.containsKey(cancellingData.Pedido__c),
            StatusSAP__c = cancellingData.StatusSAP__c); 
            System.debug(JSON.serializePretty(requestCancelling));
        return requestCancelling;

    }
    
	public class CancellingKeyMapper implements RecordMapper{
        public Map<Id, Opportunity> oppMap;
        public CancellingKeyMapper(Map<Id, Opportunity> currentOppMap){
            this.oppMap = currentOppMap;
        }
		public String mapRecord(SObject record){
            Cancelamento__c cancelRecord = (Cancelamento__c)record;
            Opportunity opp = oppMap.get(cancelRecord.IdOportunidade__c);
            return Opp.NumeroOportunidade__C+'_'+cancelRecord.TipoOrdem__c+'_'+ opp.Moeda__c +'_'+ cancelRecord.EmissorOrdem__c +'_'+ cancelRecord.RecebedorOrdem__c +'_'+cancelRecord.StatusSAP__c;
		}
	}
}