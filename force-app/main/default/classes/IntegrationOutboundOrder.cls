public with sharing class IntegrationOutboundOrder {

    private static Map<Id, Order> orderMap;
    private static Map<Id, Map<String, OrderItem>> orderIdToOrderItemMapMap;
    private static Map<Id, ProgramacaoEntrega__c> itemIdToProgramacaoEntregaMap;
    
    static {
        orderMap = new Map<Id, Order>();
        orderIdToOrderItemMapMap = new Map<Id, Map<String, OrderItem>>();
        itemIdToProgramacaoEntregaMap = new Map<Id, ProgramacaoEntrega__c>();
    }

    @future(callout = true)
    public static void sendOrderTrigger(List<Id> orderIds) {
        sendOrder(orderIds);
    }

    public static Map<Id, Response> sendOrder(List<Id> orderIds) {

        Decimal taxaMedia = 1;
        for(CotacaoMoeda__c cotacoesMoeda : [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c <= :Date.today() ORDER BY Data__c DESC LIMIT 1]){
            taxaMedia = cotacoesMoeda.TaxaMedia__c;
        }
        
        List<Order> orders = [SELECT Id,
                                     OVSAP__c,
                                     ListaPreco__c,
                                     AccountId,
                                     Account.ExternalId__c,
                                     Type,
                                     Territorio__r.Diretor__r.BusinessPartnerSAP__c,
                                     OrganizacaoVendas__c,
                                     CanalDistribuicao__c,
                                     SetorAtividade__c,
                                     PedidoCliente__c,
                                     DataInicioJuros__c,
                                     MotivoOrdem__c,
                                     CondicaoPagamento__c,
                                     CondicaoPagamento__r.ExternalId__c,
                                     OpportunityId,
                                     Opportunity.NumeroOportunidade__c,
                                     Opportunity.DataReferenciaPreco__c,
                                     Opportunity.ClassificacaoVenda__c,
                                     Opportunity.TipoOrdem__c,
                                     Opportunity.ObservacaoImpressaNF__c,
                                     Opportunity.ObservacaoLogistica__c,
                                     Opportunity.ObservacaoInterna__c,
                                     Opportunity.DescricaoCampanha__c,
                                     Regional__r.ExternalId__c,
                                     Agenciamento__c,
                                     RecebedorMercadoria__c,
                                     RecebedorMercadoria__r.ExternalId__c,
                                     Territorio__c,
                                     Territorio__r.ExternalId__c,
                                     RTV__c,
                                     RTV__r.BusinessPartnerSAP__c,
                                     GerenteRegional__c,
                                     GerenteRegional__r.BusinessPartnerSAP__c,
                                     ClienteAgenciador__c,
                                     ClienteAgenciador__r.ExternalId__c,
                                     Description,
                                     Moeda__c,
                                     Itinerario__c,
                                     Itinerario__r.ExternalId__c,
                                     ExternalId__c,
                                     TipoOrdem__c,
                                     DataFixacaoPreco__c,
                                     TaxaMedia__c
                              FROM Order
                              WHERE Id IN :orderIds];

        orderMap = new Map<Id, Order>(orders);

        Map<String, String> metadataMap = IntegrationUtils.reverseMapKey(IntegrationUtils.getMetadataDePara(
            new List<String>{
                'SetorAtividade',
                'TipoOrdemNormal',
                'TipoOrdemExportacao',
                'TipoOrdemCredito',
                'TipoOrdemDebito',
                'TipoOrdemBonificacao',
                'TipoOrdemContaOrdem',
                'TipoOrdemComplemento',
                'TipoOrdemDevolucao',
                'TipoOrdemDevolucaoCliente',
                'TipoOrdemRemanejamento',
                'TipoOrdemVendaFutura'
            }
        ));
        
        List<OrderItem> orderItemList = [SELECT Id, 
                                                Product2Id, 
                                                UnitPrice,
                                                PriceBookEntryId,
                                                Product2.ExternalId__c, 
                                                Cultura__c, 
                                                Cultura__r.ExternalId__c, 
                                                LocalNegocio__c, 
                                                LocalNegocio__r.Codigo__c, 
                                                OrderId, 
                                                OrderItemNumber,
                                                DataEntrega__c,
                                                DataFaturamento__c,
                                                Quantity,
                                                QuantidadeTotal__c,
                                                Status__c,
                                                StatusSAP__c,
                                                PrecoLista__c,
                                                ValorJuros__c,
                                                PrecoVendaSemJuros__c,
                                                PrecoListaReferencia__c,
                                                ProgramacaoEntrega__c,
                                                DescontoConcedido__c,
                                                ProgramacaoEntrega__r.QuantidadeDisponivelSAP__c,
                                                NumeroPedidoCliente__c, ValorUnitarioComJuros__c, ValorTotal__c, ValorTotalUSD__c
                                           FROM OrderItem 
                                          WHERE OrderId IN :orderIds];

        Map<Id, Id> itemIdToProgramacaoEntregaIdMap = new Map<Id, Id>();
        for (OrderItem orderItem : orderItemList) {
            itemIdToProgramacaoEntregaIdMap.put(orderItem.Id, orderItem.ProgramacaoEntrega__c);
            if (!orderIdToOrderItemMapMap.containsKey(orderItem.OrderId)) {
                orderIdToOrderItemMapMap.put(orderItem.OrderId, new Map<String, OrderItem>{orderItem.Id => orderItem});
            } else {
                orderIdToOrderItemMapMap.get(orderItem.OrderId).put(orderItem.Id, orderItem);
            }
        }

        Map<Id, ProgramacaoEntrega__c> programacaoEntregaMap = new Map<Id, ProgramacaoEntrega__c>([SELECT Id, QuantidadeDisponivelSAP__c FROM ProgramacaoEntrega__c WHERE Id IN :itemIdToProgramacaoEntregaIdMap.values()]);
        for (Id key : itemIdToProgramacaoEntregaIdMap.keySet()) {
            itemIdToProgramacaoEntregaMap.put(key, programacaoEntregaMap.get(itemIdToProgramacaoEntregaIdMap.get(key)));
        }

        Map<Id, TemplateDataIntegrationFields.OrderOUTData> orderDataMap = new Map<Id, TemplateDataIntegrationFields.OrderOUTData>();
        for (Order order : orders) {
            if(orderIdToOrderItemMapMap.containsKey(order.Id)) {
                orderDataMap.put(order.Id, new TemplateDataIntegrationFields.OrderOUTData(order, orderIdToOrderItemMapMap.get(order.Id).values(), metadataMap));
            } else {
                orderDataMap.put(order.Id, new TemplateDataIntegrationFields.OrderOUTData(order, new List<OrderItem>(), metadataMap));
            }
        }

        SAPCredential__mdt credential = [SELECT URL__c, Username__c, Password__c FROM SAPCredential__mdt WHERE DeveloperName = 'BasicAuthOV'];
            // System.debug('credential => ' + JSON.serializePretty(credential));
        
        Map<String, List<StandardResponse>> standardResponseMap = new Map<String, List<StandardResponse>>();

        Map<Id, Response> responseMap = new Map<Id, Response>();

        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        List<ProgramacaoEntrega__c> programacoesEntregaToInsert = new List<ProgramacaoEntrega__c>();
        Map<Id, ModelSAP> modelToSendMap = new Map<Id, ModelSAP>();

        String returnedSAPSerialized;

        // System.debug('ordersToSend => ' + orderDataMap.values());

        for (TemplateDataIntegrationFields.OrderOUTData orderData : orderDataMap.values()) {

            String orderId = orderData.sfId;
            Boolean hasError = false;

            standardResponseMap.put(orderId, new List<StandardResponse>());

            if (orderData.items != null && !orderData.items.isEmpty()) {

                ModelSAP modelToSend = new ModelSAP(orderData);
                modelToSendMap.put(orderId, modelToSend);

                HttpResponse authResponse = IntegrationUtils.sendAuthRequest(credential, JSON.serialize(modelToSend));
                // System.debug('authResponse => ' + authResponse);

                TemplateDataIntegrationFields.ReturnedSAP returnedSAP;

                if (IntegrationUtils.isStatusSuccess(authResponse.getStatusCode())) {

                    try {

                        returnedSAP = (TemplateDataIntegrationFields.ReturnedSAP)JSON.deserialize(String.valueOf(authResponse.getBody()), TemplateDataIntegrationFields.ReturnedSAP.class);
                        // System.debug('returnedSAP => ' + JSON.serializePretty(returnedSAP));
                        returnedSAPSerialized = JSON.serialize(returnedSAP);

                    } catch (Exception e) {

                        standardResponseMap.get(orderId).add(new StandardResponse().error(e.getMessage() + ' - ' + e.getStackTraceString()));
                        responseMap.put(orderId, new Response(standardResponseMap, hasError));
                        break;

                    }
                    if (returnedSAP.defaultResponse.document != null) {

                        orderMap.get(orderId).OVSap__c = returnedSAP.defaultResponse.document;

                        addOrderItemsAndProgramacaoEntrega(orderId, returnedSAP, orderItemsToInsert, programacoesEntregaToInsert);

                        for (TemplateDataIntegrationFields.ResponseSAP responseSAP : returnedSAP.defaultResponse.response) {
                            // System.debug('SUCESSO');
                            if (responseSAP.type == 'S'|| responseSAP.type == 'W') { // Success || Warning
                                standardResponseMap.get(orderId).add(new StandardResponse().success(orderId));
                            } else if (responseSAP.type == 'E') { // Error
                            // System.debug('ERRO1 | AVISO1');
                                standardResponseMap.get(orderId).add(new StandardResponse().error(responseSAP.message));
                            }
                        }
                    } else {
                        orderMap.get(orderId).RetornoSAP__c = JSON.serialize(returnedSAP.defaultResponse.response);

                        for (TemplateDataIntegrationFields.ResponseSAP responseSAP : returnedSAP.defaultResponse.response) {
                            if (responseSAP.type != 'S') {
                            // System.debug('ERRO2 | AVISO2');
                                standardResponseMap.get(orderId).add(new StandardResponse().error(responseSAP.message));
                            }
                        }
                        hasError = true;
                    }
                } else {
                    standardResponseMap.get(orderId).add(new StandardResponse().error('STATUS CODE: ' + authResponse.getStatusCode() + ' - ' + String.valueOf(authResponse.getBody())));
                    hasError = true;
                }
            } else {
                standardResponseMap.get(orderId).add(new StandardResponse().error('Não há itens no Pedido!'));
                hasError = true;
            }

            responseMap.put(orderId, new Response(standardResponseMap, hasError));

            orderMap.get(orderId).DataIntegracao__c = DateTime.now();

            if (hasError) {
                orderMap.get(orderId).StatusIntegracao__c = 'Erro no envio';
                orderIdToOrderItemMapMap.remove(orderId);
            } else {
                orderMap.get(orderId).StatusIntegracao__c = 'Enviado';
            }
            // System.debug('orderMap.get(orderId).StatusIntegracao__c => ' + orderMap.get(orderId).StatusIntegracao__c);
        }

        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for (Map<String, OrderItem> orderItemMap : orderIdToOrderItemMapMap.values()) {
            orderItemsToUpdate.addAll(orderItemMap.values());
        }

        if (orderMap.values().size() != 0) {
            update orderMap.values();
        }
        if (orderItemsToUpdate.size() != 0) {
            update orderItemsToUpdate; 
        }
        if (orderItemsToInsert.size() != 0) {
            insert orderItemsToInsert;
        }
        ProgramacaoEntregaHelper.disableTrigger();
        if (programacoesEntregaToInsert.size() != 0) {
            insert programacoesEntregaToInsert;
        }
        if (itemIdToProgramacaoEntregaMap.values().size() != 0) {
            update itemIdToProgramacaoEntregaMap.values();
        }
        ProgramacaoEntregaHelper.enableTrigger();

        Map<Id, Id> itemIdToProgramacaoEntregaIdMap2 = new Map<Id, Id>();
        for (ProgramacaoEntrega__c pe : programacoesEntregaToInsert) {
            itemIdToProgramacaoEntregaIdMap2.put(pe.IdOpportunityLineItem__c, pe.Id);
        }

        for (OrderItem oi : orderItemsToInsert) {
            oi.ProgramacaoEntrega__c = itemIdToProgramacaoEntregaIdMap2.get(oi.Id);
        }
        if (orderItemsToInsert.size() != 0) {
            update orderItemsToInsert;
        }

        List<IntegrationLog__c> integrationLogList = new List<IntegrationLog__c>();
        List<Attachment> attachmentList = new List<Attachment>();

        for (String key : responseMap.keySet()) {

            IntegrationLog__c integrationLog = new IntegrationLog__c();
            Attachment att = new Attachment();

            if (IntegrationUtils.WSLog('Pedido', 'Outbound', returnedSAPSerialized, JSON.serialize(modelToSendMap.get(key)), responseMap.get(key).hasError, integrationLog, att, orderMap.get(key))) {
                attachmentList.add(att);
            }
            integrationLogList.add(integrationLog);

        }

        if (!integrationLogList.isEmpty()) {

            insert integrationLogList;

            for (IntegrationLog__c log : integrationLogList) {
                orderMap.get(log.SalesforceId__c).IntegrationLog__c = log.Id;
            }

            update orderMap.values();
        }

        if (attachmentList.size() > 0) {
            insert attachmentList;
        }

        // System.debug(JSON.serializePretty(responseMap.values()));
        
        return responseMap;

    }

    private static void addOrderItemsAndProgramacaoEntrega(String orderId, TemplateDataIntegrationFields.ReturnedSAP returnedSAP, List<OrderItem> orderItemsToInsert, List<ProgramacaoEntrega__c> programacoesEntregaToInsert) {
    
        Map<String, Integer> itemIdToQuantity = getSumOfQuantities(returnedSAP.schedule);
        
        Map<String, List<TemplateDataIntegrationFields.ScheduleSAP>> itemIdToScheduleList = new Map<String, List<TemplateDataIntegrationFields.ScheduleSAP>>();
        for (TemplateDataIntegrationFields.ScheduleSAP sch : returnedSAP.schedule) {
            if (itemIdToScheduleList.containsKey(sch.itmNumberSF)) {
                itemIdToScheduleList.get(sch.itmNumberSF).add(sch);
            } else {
                itemIdToScheduleList.put(sch.itmNumberSF, new List<TemplateDataIntegrationFields.ScheduleSAP>{sch});
            }
        }

        for (String key : itemIdToQuantity.keySet()) {
            /*
            if (itemIdToQuantity.get(key) != orderIdToOrderItemMapMap.get(orderId).get(key).Quantity) {
                // System.debug('itemIdToQuantity.get(key) => ' + itemIdToQuantity.get(key));
                // System.debug('orderIdToOrderItemMapMap.get(orderId).get(key).Quantity => ' + orderIdToOrderItemMapMap.get(orderId).get(key).Quantity);

                ProgramacaoEntrega__c programacaoEntrega = new ProgramacaoEntrega__c(
                    DataIntegracao__c          = Date.today(),
                    Status__c                  = 'Liberado',
                    StatusSAP__c               = 'Não Confirmado',
                    DataEntrega__c             = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[itemIdToScheduleList.get(key).size() - 1].scheduleDate)),
                    DataFaturamento__c         = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[itemIdToScheduleList.get(key).size() - 1].invoiceDate)),
                    IdOportunidade__c          = orderMap.get(orderId).OpportunityId,
                    IdOpportunityLineItem__c   = orderIdToOrderItemMapMap.get(orderId).get(key).Id,
                    QuantidadeProgramada__c    = orderIdToOrderItemMapMap.get(orderId).get(key).Quantity,
                    QuantidadeDisponivelSAP__c = orderIdToOrderItemMapMap.get(orderId).get(key).Quantity - itemIdToQuantity.get(key)
                );
                //programacoesEntregaToInsert.add(programacaoEntrega);
                // System.debug('NEW ProgramacaoEntrega__c DUE TO QUANTITY PENDING');
            }*/

            if (itemIdToScheduleList.get(key).size() == 1) {
                // System.debug('UPDATE OrderItem');
                updateFieldsOnMap(orderIdToOrderItemMapMap.get(orderId).get(key), itemIdToScheduleList.get(key)[0], returnedSAP.defaultResponse.document);
                updateFieldsOnMap(itemIdToProgramacaoEntregaMap.get(key), itemIdToScheduleList.get(key)[0]);
            }/* else if (itemIdToScheduleList.get(key).size() == 2) {
                /*if (Integer.valueOf(itemIdToScheduleList.get(key)[0].confirmedQuantity.trim()) == 0) {
                    // System.debug('UPDATE OrderItem');
                    updateFieldsOnMap(orderIdToOrderItemMapMap.get(orderId).get(key), itemIdToScheduleList.get(key)[1], returnedSAP.defaultResponse.document);
                    updateFieldsOnMap(itemIdToProgramacaoEntregaMap.get(key), itemIdToScheduleList.get(key)[1]);
                } else {
                    // System.debug('UPDATE OrderItem');
                    updateFieldsOnMap(orderIdToOrderItemMapMap.get(orderId).get(key), itemIdToScheduleList.get(key)[0], returnedSAP.defaultResponse.document);
                    updateFieldsOnMap(itemIdToProgramacaoEntregaMap.get(key), itemIdToScheduleList.get(key)[0]);

                    OrderItem orderItem = orderIdToOrderItemMapMap.get(orderId).get(itemIdToScheduleList.get(key)[1].itmNumberSF).clone(false, true, false, false);
                    updateFieldsOnMap(orderItem, itemIdToScheduleList.get(key)[1], returnedSAP.defaultResponse.document);
                    orderItemsToInsert.add(orderItem);
                    // System.debug('NEW OrderItem');

                    /*ProgramacaoEntrega__c programacaoEntrega = new ProgramacaoEntrega__c(
                        DataIntegracao__c          = Date.today(),
                        Status__c                  = 'Integrado',
                        StatusSAP__c               = orderIdToOrderItemMapMap.get(orderId).get(key).StatusSAP__c,
                        DataEntrega__c             = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[1].scheduleDate)),
                        DataFaturamento__c         = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[1].invoiceDate)),                    
                        IdOportunidade__c          = orderMap.get(orderId).OpportunityId,
                        IdOpportunityLineItem__c   = orderIdToOrderItemMapMap.get(orderId).get(key).Id,
                        QuantidadeProgramada__c    = orderIdToOrderItemMapMap.get(orderId).get(key).Quantity,
                        QuantidadeDisponivelSAP__c = Integer.valueOf(itemIdToScheduleList.get(key)[1].confirmedQuantity.trim())
                    );
                    // programacoesEntregaToInsert.add(programacaoEntrega);
                    // System.debug('NEW ProgramacaoEntrega__c NORMAL');
                // }
            }*/ else if (itemIdToScheduleList.get(key).size() >= 2) {
                /*if (Integer.valueOf(itemIdToScheduleList.get(key)[0].confirmedQuantity.trim()) == 0) {
                // System.debug('UPDATE OrderItem');
                    updateFieldsOnMap(orderIdToOrderItemMapMap.get(orderId).get(key), itemIdToScheduleList.get(key)[1], returnedSAP.defaultResponse.document);
                    updateFieldsOnMap(itemIdToProgramacaoEntregaMap.get(key), itemIdToScheduleList.get(key)[1]);
                } else {*/
                // System.debug('UPDATE OrderItem');
                    updateFieldsOnMap(orderIdToOrderItemMapMap.get(orderId).get(key), itemIdToScheduleList.get(key)[0], returnedSAP.defaultResponse.document);
                    updateFieldsOnMap(itemIdToProgramacaoEntregaMap.get(key), itemIdToScheduleList.get(key)[0]);
                    
                    /*OrderItem orderItem = orderIdToOrderItemMapMap.get(orderId).get(itemIdToScheduleList.get(key)[1].itmNumberSF).clone(false, true, false, false);
                    updateFieldsOnMap(orderItem, itemIdToScheduleList.get(key)[1], returnedSAP.defaultResponse.document);
                    orderItemsToInsert.add(orderItem);*/
                    // System.debug('NEW OrderItem');

                    /*ProgramacaoEntrega__c programacaoEntrega = new ProgramacaoEntrega__c(
                        DataIntegracao__c          = Date.today(),
                        Status__c                  = 'Integrado',
                        StatusSAP__c               = orderIdToOrderItemMapMap.get(orderId).get(key).StatusSAP__c,
                        DataEntrega__c             = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[1].scheduleDate)),
                        DataFaturamento__c         = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[1].invoiceDate)),                    
                        IdOportunidade__c          = orderMap.get(orderId).OpportunityId,
                        IdOpportunityLineItem__c   = orderIdToOrderItemMapMap.get(orderId).get(key).Id,
                        QuantidadeProgramada__c    = orderIdToOrderItemMapMap.get(orderId).get(key).Quantity,
                        QuantidadeDisponivelSAP__c = Integer.valueOf(itemIdToScheduleList.get(key)[1].confirmedQuantity.trim())
                    );
                    programacoesEntregaToInsert.add(programacaoEntrega);*/
                    // System.debug('NEW ProgramacaoEntrega__c NORMAL');
                //}
                for (Integer i = 1; i < itemIdToScheduleList.get(key).size(); i++) {
                    OrderItem orderItem = orderIdToOrderItemMapMap.get(orderId).get(itemIdToScheduleList.get(key)[i].itmNumberSF).clone(false, true, false, false);
                    updateFieldsOnMap(orderItem, itemIdToScheduleList.get(key)[i], returnedSAP.defaultResponse.document);
                    orderItemsToInsert.add(orderItem);
                    // System.debug('NEW OrderItem');

                    /*ProgramacaoEntrega__c programacaoEntrega = new ProgramacaoEntrega__c(
                        DataIntegracao__c          = Date.today(),
                        Status__c                  = 'Integrado',
                        StatusSAP__c               = orderIdToOrderItemMapMap.get(orderId).get(key).StatusSAP__c,
                        DataEntrega__c             = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[i].scheduleDate)),
                        DataFaturamento__c         = IntegrationUtils.stringToDate(String.valueOf(itemIdToScheduleList.get(key)[i].invoiceDate)),                    
                        IdOportunidade__c          = orderMap.get(orderId).OpportunityId,
                        IdOpportunityLineItem__c   = orderIdToOrderItemMapMap.get(orderId).get(key).Id,
                        QuantidadeProgramada__c    = orderIdToOrderItemMapMap.get(orderId).get(key).Quantity,
                        QuantidadeDisponivelSAP__c = Integer.valueOf(itemIdToScheduleList.get(key)[i].confirmedQuantity.trim())
                    );
                    programacoesEntregaToInsert.add(programacaoEntrega);*/
                    // System.debug('NEW ProgramacaoEntrega__c NORMAL');
                }
            }
        }
    }

    private static Map<String, Integer> getSumOfQuantities(List<TemplateDataIntegrationFields.ScheduleSAP> schedules) {

        Map<String, Integer> itemIdToQuantity = new Map<String, Integer>();
        for (TemplateDataIntegrationFields.ScheduleSAP sch : schedules) {
            if (itemIdToQuantity.containsKey(sch.itmNumberSF)) {
                itemIdToQuantity.put(sch.itmNumberSF, itemIdToQuantity.get(sch.itmNumberSF) + Integer.valueOf(sch.confirmedQuantity.trim()));
            } else {
                itemIdToQuantity.put(sch.itmNumberSF, Integer.valueOf(sch.confirmedQuantity.trim()));
            }
        }
        return itemIdToQuantity;
    }

    private static void updateFieldsOnMap(OrderItem orderItem, TemplateDataIntegrationFields.ScheduleSAP sch, String orderNumber) {
        orderItem.NrItem__c               = sch.itmNumber;
        orderItem.LinhaDivisaoRemessa__c  = sch.scheduleNumber;
        orderItem.HeaderOrderItem__c      = (Integer.valueOf(sch.scheduleNumber) == 1);
        orderItem.DataEntrega__c          = IntegrationUtils.stringToDate(String.valueOf(sch.scheduleDate));
        orderItem.DataFaturamento__c      = IntegrationUtils.stringToDate(String.valueOf(sch.invoiceDate));
        orderItem.QuantidadeConfirmada__c = Integer.valueOf(sch.confirmedQuantity.trim());
        orderItem.StatusSAP__c            = getCorrectStatus(sch);
        orderItem.ExternalId__c           = orderNumber + '-' + sch.itmNumber + '-' + sch.scheduleNumber;
        orderItem.DataInicioExpedicao__c  = IntegrationUtils.stringToDate(String.valueOf(sch.expeditionDate));
    }
    

    private static void updateFieldsOnMap(ProgramacaoEntrega__c programacaoEntrega, TemplateDataIntegrationFields.ScheduleSAP sch) {
        programacaoEntrega.DataEntrega__c             = IntegrationUtils.stringToDate(String.valueOf(sch.scheduleDate));
        programacaoEntrega.DataFaturamento__c         = IntegrationUtils.stringToDate(String.valueOf(sch.invoiceDate));        
        programacaoEntrega.QuantidadeDisponivelSAP__c = (sch == null || sch.confirmedQuantity == null ? 0 :  Integer.valueOf(sch.confirmedQuantity.trim()));
        programacaoEntrega.DataIntegracao__c          = Date.Today();
        programacaoEntrega.StatusSAP__c               = 'Confirmado';
        programacaoEntrega.Status__c                  = 'Integrado';
    }

    private static String getCorrectStatus(TemplateDataIntegrationFields.ScheduleSAP sch){        
        Integer qtdItem = Integer.valueOf(sch.quantity.trim());
        Integer confirmedQtdItem = Integer.valueOf(sch.confirmedQuantity.trim());
        String statusSap = 'Confirmado';

        if(qtdItem != confirmedQtdItem){
            if(confirmedQtdItem == 0){
                statusSap = 'Produto Indisponível';
            }else if(qtdItem >= confirmedQtdItem){
                statusSap = 'Confirmado Parcial';
            }
        }
        return statusSap;
    }
    
    @TestVisible
    private class ModelSAP {

        public TemplateDataIntegrationFields.OrderOUTData header;
        public TemplateDataIntegrationFields.PartnersData partners;
        public TemplateDataIntegrationFields.OrderItemOUTData[] item;

        public ModelSAP() {
        }

        public ModelSAP(TemplateDataIntegrationFields.OrderOUTData orderData) {
            this.header = orderData;
            this.partners = orderData.partners;
            this.item = new List<TemplateDataIntegrationFields.OrderItemOUTData>(orderData.items);
            // System.debug('ModelSAP => ' + JSON.serializePretty(this));
        }
    }

    public class Response {

        public Map<String, List<StandardResponse>> responseMap;
        public Boolean hasError;

        public Response() {
        }

        public Response(Map<String, List<StandardResponse>> responseMap, Boolean hasError) {
            this.responseMap = responseMap;
            this.hasError    = hasError;
        }

    }

    public class StandardResponse {

        public Boolean hasError;
        public String message;
        public Id orderId;

        public StandardResponse() {
        }
        
        public StandardResponse success(Id orderId) {
            this.hasError = false;
            this.orderId = orderId;
            return this;
        }
        
        public StandardResponse success(Id orderId, String message) {
            this.hasError = false;
            this.orderId = orderId;
            this.message = message;
            return this;
        }

        public StandardResponse error(String message) {
            this.hasError = true;
            this.message = message;
            return this;
        }
    }
}