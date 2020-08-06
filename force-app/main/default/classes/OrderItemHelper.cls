public class OrderItemHelper {

    private static Boolean isEnabled;

    static{
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }

    public static void updateUSDValues(List<OrderItem> context){
        List<OrderItem> ordItemList = new List<OrderItem>();
        for(OrderItem ordItem : [SELECT id, SaldoBRL__c, order.TaxaMedia__c FROM OrderItem WHERE id IN : Collection.of(context).pluckIds()]){
            ordItem.SaldoUSD__C = (ordItem.SaldoBRL__c / ordItem.order.TaxaMedia__c);
            ordItemList.add(ordItem);
        }
        if(!ordItemList.isEmpty()){
            update ordItemList;
        }
    }
    public static void updateUSDValues(List<OrderItem> context, Map<Id, OrderItem> oldCOntext){
        List<OrderItem> ordITemContextList = new List<OrderItem>();
        for(OrderItem ordItem : context){
            OrderItem oldOrd = oldCOntext.get(ordItem.id);
            if(ordItem.SaldoBRL__c != oldOrd.SaldoBRL__c){
                ordITemContextList.add(ordItem);
            }
        }
        if(!ordITemContextList.isEmpty()){
            updateUSDValues(ordITemContextList);
        }
    }
    public static void changeNumSche(Map<Id, OrderItem> newOrderMap, Map<Id, OrderItem> oldOrderMap, Boolean isInsert){
        Set<Id> ordIdSet = new Set<Id>();
        for(OrderItem orditem : newOrderMap.values()){
            if(isInsert){
                ordIdSet.add(orditem.OrderId);
            }else{                
                Orderitem oldOrdItem = oldOrderMap.get(ordItem.Id);
                if(orditem.NumeroRemessa__c != oldOrdItem.NumeroRemessa__c){
                    ordIdSet.add(orditem.OrderId);
                }
            }
        }
        Map<Id, Set<String>> numScheMap = new Map<Id, Set<String>>();
        for(OrderItem ordItem : [SELECT id, NumeroRemessa__c, OrderId FROM OrderItem WHERE OrderId IN :ordIdSet]){
            if(ordItem.NumeroRemessa__c != null){
                if(!numScheMap.containsKey(ordItem.OrderId))
                    numScheMap.put(ordItem.OrderId, new Set<String>());
                numScheMap.get(ordItem.OrderId).addAll(ordItem.NumeroRemessa__c.split('\n'));
            }
        }
        List<order> orderUpdateList = new List<order>();
        for(Id ordId : numScheMap.keySet()){
            orderUpdateList.add(new Order(Id = ordId, RemessaSAP__c = String.join(new List<String>(numScheMap.get(ordId)), '\n')));
        }
        if(!orderUpdateList.isEmpty()){
            OrderHelper.disableTrigger();
            update orderUpdateList;
            OrderHelper.enableTrigger();
        }

    }
    public static void updtIntegrationCheck(Map<Id, OrderItem> newOrderItemMap) {
        List<OrderITem> ordItemUpdtList = new List<OrderITem>();
        for(OrderItem ordItem : newOrderItemMap.values()){
            ordItemUpdtList.add(new orderitem(Id = orditem.id, IntegrationUpdate__c = false));
        }
        System.debug(ordItemUpdtList);
        if(!ordItemUpdtList.isEmpty()){
            OrderItemHelper.disableTrigger();
            update ordItemUpdtList;
            OrderItemHelper.enableTrigger();
        }
    }
    public static void sendEmailCreditBlock(Map<Id, OrderItem> newOrderMap, Map<Id, OrderItem> oldOrderMap){
        String TI_EMAIL = Label.EmailTiStoller;
        List<Messaging.EmailFileAttachment> attch = new List<Messaging.EmailFileAttachment>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 
        Set<Id> contextIdSet = new Set<Id>();
        for(OrderItem ord : newOrderMap.values()){
            OrderItem oldOrd = oldOrderMap.get(ord.id);
            if(ord.StatusSAP__c != oldOrd.StatusSAP__c && ord.StatusSAP__c == 'Bloqueado Crédito'){
                contextIdSet.add(ord.OrderId);   
            }
        }
        Map<String, EmailTemplate> searchEmailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate email :[SELECT id, name, subject, htmlvalue, markup, Body, developerName
				                  FROM   EmailTemplate
				                  WHERE  developerName =  'BloqueioCredito']){
            searchEmailTemplateMap.put(email.DeveloperName, email);
        }     
        for(Order ord: [SELECT id, Owner.Email, OrderNumber FROM Order WHERE Id IN :contextIdSet]){
            if(searchEmailTemplateMap.containsKey('BloqueioCredito')){

                EmailTemplate searchEmailTemplate = null;
                searchEmailTemplate = searchEmailTemplateMap.get('BloqueioCredito');

                mails.add(EmailClientToApprove.composeEmail(new List<String>{ord.Owner.Email}, 
                            'Bloqueio de Credito', 
                            searchEmailTemplate.Subject.replace('{OrdNumber}', ord.OrderNumber),
                            searchEmailTemplate.Body.replace('{OrdNumber}', '<a href="' +Label.EmailOrgUrl+'/'+ord.Id+'">'+ord.OrderNumber+'</a>'),
                            attch,
                            new List<String>{TI_EMAIL}));
            }
        }
        if(!Test.isRunningTest() && !mails.isEmpty()) Messaging.sendEmail(mails);

    }

    public static void setValorTotalUSD(Map<Id, OrderItem> newContextMap) {

        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];

        if (!cotacoesMoeda.isEmpty()) {

            // Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(
            //     [
            //         SELECT Id, ValorTotal__c, ValorTotalUSD__c
            //         FROM OrderItem
            //         WHERE StatusSAP__c != 'Faturado' 
            //         AND IntegrationUpdate__c = false
            //     ]
            // );

            OrderItem[] oiToUpdate = new List<OrderItem>();

            for (OrderItem orderItem : newContextMap.values()) {
                if (orderItem.StatusSAP__c != 'Faturado' && orderItem.IntegrationUpdate__c == false) {
                    oiToUpdate.add(
                        new OrderItem(
                            Id = orderItem.Id, 
                            ValorTotalUSD__c = orderItem.ValorTotal__c / cotacoesMoeda[0].TaxaMedia__c
                        )
                    );
                }
            }

            OrderItemHelper.disableTrigger();
            update oiToUpdate;
            OrderItemHelper.enableTrigger();
        }

    }

    public static void updateApWallet(Map<Id, OrderItem> newContextMap, Map<Id, OrderItem> oldContextMap){

        Set<String> critApuracao = new Set<String>();

        List<Apuracao__c> updateSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> removeSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> addingToAnotherAp = new List<Apuracao__c>();
        List<ClientesPlanoIncentivos__c> cliPlanoIncentivoList = new List<ClientesPlanoIncentivos__c>();

        Map<Id, OrderItem> mapCliIdToOrdItemAdd = new Map<Id, OrderItem>();
        Map<Id, OrderItem> mapCliIdToOrdItemMin = new Map<Id, OrderItem>();

        Map<String, OrderItem> mapCritRemoveToOrderItem  = new Map<String,OrderItem>();
        Map<String, OrderItem> mapCritAddingToAnotherAp = new Map<String, OrderItem>();

        Map<String, OrderItem> mapCritUpdateToOrderItem  = new Map<String,OrderItem>();
        Map<String, OrderItem> mapSubtractToOrderItem    = new Map<String, OrderItem>();
        
        //2020.05.08 - William Leite - Adicionado campo para valor à vista (Reais/Dólar)
        for (OrderItem ordItem: [SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c, ClientePlanoIncentivo__c, ValorTotalSemJurosReais__c, ValorTotalSemJurosDolar__c FROM OrderItem WHERE Id IN: oldContextMap.keySet()]){ 
            OrderItem ordItemOld = oldContextMap.get(ordItem.Id);
            if (ordItem.ClientePlanoIncentivo__c != null){
                mapCliIdToOrdItemAdd.put(ordItem.ClientePlanoIncentivo__c, ordItem);
                mapCliIdToOrdItemMin.put(ordItem.ClientePlanoIncentivo__c, ordItemOld);
            }
            // system.debug(ordItemOld.ValorTotal__c);
            // system.debug(ordItem.ValorTotal__c);
            if (ordItem.ValorTotal__c != ordItemOld.ValorTotal__c || ordItem.ValorTotalUSD__c != ordItemOld.ValorTotalUSD__c || ordItem.Litros__c != ordItemOld.Litros__c || ordItem.CriterioApuracao__c != ordItemOld.CriterioApuracao__c){
                String newValue = ordItem.CriterioApuracao__c;
                String oldValue = ordItemOld.CriterioApuracao__c;
                // system.debug('Compara: '+( newValue.equals(oldValue) ? 'true' : 'false'));

                critApuracao.add(ordItem.CriterioApuracao__c);
                critApuracao.add(ordItemOld.CriterioApuracao__c);

                if (ordItem.CriterioApuracao__c != ordItemOld.CriterioApuracao__c){
                    mapCritAddingToAnotherAp.put(ordItem.CriterioApuracao__c, ordItem);
                    mapCritRemoveToOrderItem.put(ordItemOld.CriterioApuracao__c, ordItemOld);
                }else{
                    mapCritUpdateToOrderItem.put(ordItem.CriterioApuracao__c, ordItem);
                    mapSubtractToOrderItem.put(ordItemOld.CriterioApuracao__c, ordItemOld);
                }
            }
        }

        // system.debug(mapCritRemoveToOrderItem);
        // system.debug(mapCritUpdateToOrderItem);

        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, Carteira__c, Moeda__c FROM ClientesPlanoIncentivos__c WHERE Id IN: mapCliIdToOrdItemAdd.keySet()]){
            OrderItem newOrdItem = mapCliIdToOrdItemAdd.get(cliPlan.Id);
            OrderItem oldOrdItem = mapCliIdToOrdItemMin.get(cliPlan.Id);
            if (newOrdItem.ValorTotal__c != oldOrdItem.ValorTotal__c || newOrdItem.ValorTotalUSD__c != oldOrdItem.ValorTotalUSD__c){
                if (cliPlan.Moeda__c == 'BRL'){
                    cliPlan.Carteira__c = cliPlan.Carteira__c - oldOrdItem.ValorTotal__c    + newOrdItem.ValorTotal__c;
                }else{
                    cliPlan.Carteira__c = cliPlan.Carteira__c - oldOrdItem.ValorTotalUSD__c + newOrdItem.ValorTotalUSD__c;
                }
                cliPlanoIncentivoList.add(cliPlan);
            }
        }

        for (Apuracao__c apuracao : [SELECT Id, CarteiraReais__c, CarteiraDolar__c, CarteiraLitros__c, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN: critApuracao]){

            if (mapCritAddingToAnotherAp.containsKey(apuracao.CriterioApuracao__c)){
                OrderItem ordItem = mapCritAddingToAnotherAp.get(apuracao.CriterioApuracao__c);
                //2020.05.08 - William Leite - Alterado para pegar campos com valor à vista (Reais/Dólar)
                /*
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  + ordItem.ValorTotal__c    : ordItem.ValorTotal__c;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  + ordItem.ValorTotalUSD__c : ordItem.ValorTotalUSD__c;
				*/
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  + ordItem.ValorTotalSemJurosReais__c : ordItem.ValorTotalSemJurosReais__c;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  + ordItem.ValorTotalSemJurosDolar__c : ordItem.ValorTotalSemJurosDolar__c;
                
                if(ordItem.Litros__c != null)
                    apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null ? apuracao.CarteiraLitros__c + ordItem.Litros__c        : ordItem.Litros__c;

                addingToAnotherAp.add(apuracao);
            }            
            if (mapCritRemoveToOrderItem.containsKey(apuracao.CriterioApuracao__c)){
                OrderItem ordItem = mapCritRemoveToOrderItem.get(apuracao.CriterioApuracao__c);
                //2020.05.08 - William Leite - Alterado para pegar campos com valor à vista (Reais/Dólar)
                /*                
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - ordItem.ValorTotal__c    : null;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - ordItem.ValorTotalUSD__c : null;
				*/
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - ordItem.ValorTotalSemJurosReais__c : null;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - ordItem.ValorTotalSemJurosDolar__c : null;

                if(ordItem.Litros__c != null)
                    apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null ? apuracao.CarteiraLitros__c - ordItem.Litros__c        : null;

                removeSumApuracao.add(apuracao);
            }
            if (mapCritUpdateToOrderItem.containsKey(apuracao.CriterioApuracao__c)){
                OrderItem ordItemNew = mapCritUpdateToOrderItem.get(apuracao.CriterioApuracao__c);
                OrderItem ordItemOld = mapSubtractToOrderItem.get(apuracao.CriterioApuracao__c);

                // system.debug(ordItemNew.ValorTotal__c);
                // system.debug(ordItemOld.ValorTotal__c);
                //2020.05.08 - William Leite - Alterado para pegar campos com valor à vista (Reais/Dólar)
                /*                
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - ordItemOld.ValorTotal__c    + ordItemNew.ValorTotal__c    : ordItemNew.ValorTotal__c;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - ordItemOld.ValorTotalUSD__c + ordItemNew.ValorTotalUSD__c : ordItemNew.ValorTotalUSD__c;
				*/
                apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - ordItemOld.ValorTotalSemJurosReais__c + ordItemNew.ValorTotalSemJurosReais__c : ordItemNew.ValorTotalSemJurosReais__c;
                apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - ordItemOld.ValorTotalSemJurosDolar__c + ordItemNew.ValorTotalSemJurosDolar__c : ordItemNew.ValorTotalSemJurosDolar__c;
                
                if(ordItemNew.Litros__c != null)
                    apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null && ordItemOld.Litros__c != null ? apuracao.CarteiraLitros__c - ordItemOld.Litros__c        + ordItemNew.Litros__c        : ordItemNew.Litros__c;

                updateSumApuracao.add(apuracao);
            }            
        }

        // system.debug('cliPlanoIncentivoList: '+ cliPlanoIncentivoList);
        // system.debug('removeSumApuracao: '+ removeSumApuracao);
        // system.debug('updateSumApuracao: '+ updateSumApuracao);
        // system.debug('addingToAnotherAp: '+ addingToAnotherAp);

        if (!cliPlanoIncentivoList.isEmpty()){
            update cliPlanoIncentivoList;
        }

        if (!addingToAnotherAp.isEmpty()){
            update addingToAnotherAp;
        }

        if (!removeSumApuracao.isEmpty()){
            update removeSumApuracao;
        }

        if (!updateSumApuracao.isEmpty()){
            update updateSumApuracao;
        }               
    }

    public static void updatePlanoIncentivo(OrderItem[] ordItemList){
        Set<Id> clienteEmissorSet = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();
        Set<Id> ordIdSet = new Set<Id>();
        List<PlanoIncentivo__c> planoIncentivoToUpdate = new List<PlanoIncentivo__c>();

        for (OrderItem ordItem : ordItemList){
            ordIdSet.add(ordItem.OrderId);
        }

        for (Order ord : [SELECT Id, ClienteEmissor__c FROM Order WHERE Id IN: ordIdSet]){            
            if (ord.ClienteEmissor__c != null){
                clienteEmissorSet.add(ord.ClienteEmissor__c);
            }
        }

        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, PlanoIncentivo__c FROM ClientesPlanoIncentivos__c WHERE NomeCliente__c IN: clienteEmissorSet]){
            // system.debug(cliPlan.PlanoIncentivo__c);
            planoIncentivoSet.add(cliPlan.PlanoIncentivo__c);
        }

        for (ClienteFamilia__c cliFam : [SELECT Id, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__c FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: clienteEmissorSet]){
            // system.debug(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
            planoIncentivoSet.add(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
        }

        for (PlanoIncentivo__c planoIncentivo : [SELECT Id, Atualizado__c FROM PlanoIncentivo__c WHERE Id IN: planoIncentivoSet]){
            planoIncentivo.Atualizado__c = false;
            planoIncentivoToUpdate.add(planoIncentivo);
        }

        if (!planoIncentivoToUpdate.isEmpty()){
            PlanoIncentivoHelper.disableTrigger();
            update planoIncentivoToUpdate;
            PlanoIncentivoHelper.enableTrigger();
        }
    }

    // public static void insertNewDeliveryRecords(Map<Id, OrderItem> oldRecordsMap, Map<Id, OrderItem> newRecordsMap){

    //     Map<Id, Integer> productIdToNewBalance = new Map<Id, Integer>();
    //     List<OrderItem> orderItemsChanged = new List<OrderItem>();

    //     Integer oldTotalQuantity = 0;
    //     Integer newTotalQuantity = 0;

    //     for(OrderItem orderItem : newRecordsMap.values()){
    //         oldTotalQuantity = Integer.valueOf(oldRecordsMap.get(orderItem.id).quantidadeTotal__c);
    //         newTotalQuantity = Integer.valueOf(orderItem.quantidadeTotal__c);
    //         if(!productIdToNewBalance.containsKey(orderItem.product2Id) && oldTotalQuantity != newTotalQuantity){
    //             productIdToNewBalance.put(orderItem.product2Id, oldTotalQuantity - newTotalQuantity);
    //             orderItemsChanged.add(orderItem);
    //         }
    //     }

    //     if(!orderItemsChanged.isEmpty()){

    //         Map<Id, Order> orderMap = new Map<Id, Order>([
    //             SELECT id, opportunityId
    //             FROM Order
    //             WHERE id IN :Collection.of(orderItemsChanged).pluckIds(OrderItem.OrderId)
    //         ]);

    //         Map<Id, ProgramacaoEntrega__c> deliveryMap = new Map<Id, ProgramacaoEntrega__c>([
    //             SELECT  Name, IdOpportunityLineItem__c, Produto__c, Status__c, StatusSAP__c, 
    //                     Litros__c, DataEntrega__c, PrecoLitro__c,
    //                     QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
    //                     Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__c,
    //                     EmissorOrdem__c, ClienteOrigemRemanejamento__c, DataConfirmacao__c, PrecoVendasJurosUSD__c, DescontoTipoCliente__c,
    //                     Itinerario__c, LimiteCreditoTotal__c, LocalNegocio__c, RTV__c, SaldoLimiteCredito__c, TabelaPreco__c, 
    //                     TaxaDolar__c, ValorFrete__c, ValorUnitario__c, TipoOrdem__c, DataFaturamento__c, DiretorComercial__c, Regional__c
    //             FROM ProgramacaoEntrega__c
    //             WHERE id IN :Collection.of(orderItemsChanged).pluckIds(OrderItem.ProgramacaoEntrega__c)
    //         ]);

    //         List<ProgramacaoEntrega__c> deliveryRecordsToInsert = new List<ProgramacaoEntrega__c>();
            
    //         for(OrderItem orderItem : orderItemsChanged){
                
    //             ProgramacaoEntrega__c deliveryRecordToInsert = deliveryMap.get(orderItem.programacaoEntrega__c).clone(false, true);
    //             deliveryRecordToInsert.status__c                  = 'Liberado';
    //             deliveryRecordToInsert.statusSAP__c               = 'Não Confirmado';
    //             deliveryRecordToInsert.dataIntegracao__c          = null;
    //             deliveryRecordToInsert.confirmado__c              = false;
    //             deliveryRecordToInsert.quantidadeProgramada__c    = productIdToNewBalance.get(orderItem.product2Id);
    //             deliveryRecordToInsert.quantidadeDisponivelSAP__c = 0;
    //             deliveryRecordToInsert.idDivisaoEntregaSAP__c     = null;
                
    //             deliveryRecordsToInsert.add(deliveryRecordToInsert);

    //         }

    //         if(!deliveryRecordsToInsert.isEmpty()){
    //             insert deliveryRecordsToInsert;
    //         }

    //     }
    // }

    public static void updateDeliveryRecord(Map<Id, OrderItem> oldContextMap, Map<Id, OrderItem> newContextMap){
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
        List<OrderItem> ordItemList = new List<OrderItem>();
        Map<Id, OrderItem> mapIdDeliveryToOrderItem = new Map<Id, OrderItem>();
        Set<Id> deliverySet = new Set<Id>();

        for (OrderItem oldOrdItem : oldContextMap.Values()){
            OrderItem newOrdItem = newContextMap.get(oldOrdItem.Id);
            if (oldOrdItem.StatusSAP__c != newOrdItem.StatusSAP__c){
                mapIdDeliveryToOrderItem.put(newOrdItem.ProgramacaoEntrega__c, newOrdItem);
            }  
        }

        for (ProgramacaoEntrega__c delivery : [SELECT Id, statusSAP__c FROM ProgramacaoEntrega__c WHERE Id IN: mapIdDeliveryToOrderItem.keySet()]){
                delivery.statusSAP__c = mapIdDeliveryToOrderItem.get(delivery.Id).StatusSAP__c;
                deliveryList.add(delivery);
        }

        if (!deliveryList.isEmpty()){
            update deliveryList;
        }
    }
}