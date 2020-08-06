public with sharing class IntegrationOutboundCancellation {

    private static Map<Id, Order> orderMap;
    
    private static Map<Id, List<OrderItem>> ordIdToOrdItemMap;
    
    static{
        orderMap = new Map<Id, Order>();
        ordIdToOrdItemMap = new Map<Id, List<OrderItem>>();
    }
    
    @future(callout = true)
    public static void sendCancellationFuture(Set<Id> ordItemSetId, String reasonType){
        try{
            sendCancellation(ordItemSetId, reasonType);
        }catch(Exception ex){
            List<Attachment> attachmentList = new List<Attachment>();
            List<IntegrationLog__c> integrationLogList = new List<IntegrationLog__c>();
            Attachment att = new Attachment();

            IntegrationLog__c integrationLog = new IntegrationLog__c();
            if (IntegrationUtils.WSLog('Pedido Solicitação - Reenvio', 'Outbound', 'Exceção não tratada na tela, ao reenviar ordem ocorreu o erro:'+ex.getMessage()+'\n'+ex.getStackTraceString(), JSON.serialize(ordItemSetId), true, integrationLog, att, null)) {
                attachmentList.add(att);
            }
            integrationLogList.add(integrationLog);

            if (!integrationLogList.isEmpty()) {            
                insert integrationLogList;
            }
            if (!attachmentList.isEmpty()) {
                insert attachmentList;
            }
        }
    }
    // @future(callout = true)
    public static String sendCancellation(Set<Id> ordItemSetId, String reasonType){

        Map<Id, TemplateDataIntegrationFields.CancellationOUTData> mapIdToData = new Map<Id, TemplateDataIntegrationFields.CancellationOUTData>();
        Map<Id, OrderItem> mapIdToOrderItem = new Map<Id, OrderItem>();
        Map<String, List<StandardResponse>> standardResponseMap = new Map<String, List<StandardResponse>>();


        for (OrderItem orderItem : [SELECT Id, Product2Id, UnitPrice, PriceBookEntryId, Product2.ExternalId__c, Cultura__c, Cultura__r.ExternalId__c, 
                                    LocalNegocio__c, LocalNegocio__r.Codigo__c, OrderId, OrderItemNumber, DataEntrega__c, Quantity, Status__c, 
                                    StatusSAP__c, PrecoLista__c, ValorJuros__c, PrecoVendaSemJuros__c, PrecoListaReferencia__c, ProgramacaoEntrega__c, 
                                    ProgramacaoEntrega__r.QuantidadeDisponivelSAP__c, NumeroPedidoCliente__c, MotivoRecusaItem__c, nritem__c
                                    FROM OrderItem 
                                    WHERE Id IN: ordItemSetId]){
            orderItem.MotivoRecusaItem__c = reasonType;
            if (!ordIdToOrdItemMap.containsKey(orderItem.OrderId)) {
                ordIdToOrdItemMap.put(orderItem.OrderId, new List<OrderItem>());
            }
            ordIdToOrdItemMap.get(orderItem.OrderId).add(orderItem);
        }        

        
        for (Order order : [SELECT Id, OVSAP__c, ListaPreco__c, AccountId, Account.ExternalId__c, Type, OrganizacaoVendas__c, 
                            CanalDistribuicao__c, SetorAtividade__c, PedidoCliente__c, DataInicioJuros__c, MotivoOrdem__c, 
                            CondicaoPagamento__c, CondicaoPagamento__r.ExternalId__c, OpportunityId, Opportunity.NumeroOportunidade__c, 
                            Opportunity.DataReferenciaPreco__c, Opportunity.TipoOrdem__c, Agenciamento__c, RecebedorMercadoria__c, 
                            RecebedorMercadoria__r.ExternalId__c, Territorio__c, Territorio__r.ExternalId__c, RTV__c, 
                            RTV__r.BusinessPartnerSAP__c, GerenteRegional__c, GerenteRegional__r.BusinessPartnerSAP__c, 
                            ClienteAgenciador__c, ClienteAgenciador__r.ExternalId__c, Description, Moeda__c, ExternalId__c
                            FROM Order 
                            WHERE Id IN: ordIdToOrdItemMap.keySet()]) {
            orderMap.put(order.Id, order);
            mapIdToData.put(order.Id, new TemplateDataIntegrationFields.CancellationOUTData(order, ordIdToOrdItemMap.get(order.Id)));
        }
        Map<Id, ModelSAP> modelToSendMap = new Map<Id, ModelSAP>();

        Map<Id, Response> responseMap = new Map<Id, Response>();
        SAPCredential__mdt credential = [SELECT URL__c, Username__c, Password__c FROM SAPCredential__mdt WHERE DeveloperName = 'BasicAuthOC'];
        
        
        String returnedSAPSerialized = '';
        List<OrderItem> updtOrdItemList = new List<OrderITem>();

        for (Id ordId : mapIdToData.keySet()) {
            
            TemplateDataIntegrationFields.CancellationOUTData cancellationData = mapIdToData.get(ordId);

            String orderId = cancellationData.sfId;
            Boolean hasError = false;

            standardResponseMap.put(orderId, new List<StandardResponse>());

            ModelSAP modelToSend = new ModelSAP(cancellationData);
            modelToSendMap.put(orderId, modelToSend);

            HttpResponse authResponse = IntegrationUtils.sendAuthRequest(credential, JSON.serialize(modelToSend));
            // System.debug('authResponse => ' + authResponse);

            TemplateDataIntegrationFields.DocumentSAP returnedSAP;

            if (IntegrationUtils.isStatusSuccess(authResponse.getStatusCode())) {

                try {

                    returnedSAP = (TemplateDataIntegrationFields.DocumentSAP)JSON.deserialize(String.valueOf(authResponse.getBody()), TemplateDataIntegrationFields.DocumentSAP.class);
                    // System.debug('returnedSAP => ' + JSON.serializePretty(returnedSAP));
                    returnedSAPSerialized = JSON.serialize(returnedSAP);

                } catch (Exception e) {

                    standardResponseMap.get(orderId).add(new StandardResponse().error(e.getMessage() + ' - ' + e.getStackTraceString()));
                    responseMap.put(orderId, new Response(standardResponseMap, hasError));

                }
                if (returnedSAP.document != null) {
                    
                    for (TemplateDataIntegrationFields.ResponseSAP responseSAP : returnedSAP.response) {
                        if (responseSAP.type == 'S') { 
                            standardResponseMap.get(orderId).add(new StandardResponse().success(orderId));
                        } else if (responseSAP.type == 'E' || responseSAP.type == 'W') { 
                            standardResponseMap.get(orderId).add(new StandardResponse().error(responseSAP.message));
                        }
                    }
                } else {

                    for (TemplateDataIntegrationFields.ResponseSAP responseSAP : returnedSAP.response) {
                        if (responseSAP.type != 'S') {
                            standardResponseMap.get(orderId).add(new StandardResponse().error(responseSAP.message));
                        }
                    }
                    hasError = true;
                }
            } else {
                standardResponseMap.get(orderId).add(new StandardResponse().error('STATUS CODE: ' + authResponse.getStatusCode() + ' - ' + String.valueOf(authResponse.getBody())));
                hasError = true;
            }

            responseMap.put(orderId, new Response(standardResponseMap, hasError));

            String errMsg = '';
            if (hasError) {
                errMsg = 'Erro no envio da solicitação!';
            } else {
                errMsg = 'Solicitação enviada com sucesso!';
            }
            for(OrderItem ordItem : ordIdToOrdItemMap.get(ordId)){
                ordItem.StatusCancelamento__c = errMsg;
                updtOrdItemList.add(ordItem);
            }
        }
        System.debug('uptList'+JSON.serializePretty(updtOrdItemList));
        OrderITemHelper.disableTrigger();
        if(!updtOrdItemList.isEmpty()){
            update updtOrdItemList;
        }
        OrderITemHelper.enableTrigger();

        List<IntegrationLog__c> integrationLogList = new List<IntegrationLog__c>();
        List<Attachment> attachmentList = new List<Attachment>();

        for (String key : responseMap.keySet()) {

            IntegrationLog__c integrationLog = new IntegrationLog__c();
            Attachment att = new Attachment();

            if (IntegrationUtils.WSLog('Pedido Solicitação', 'Outbound', returnedSAPSerialized, JSON.serialize(modelToSendMap.get(key)), responseMap.get(key).hasError, integrationLog, att, orderMap.get(key))) {
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

        if (!attachmentList.isEmpty()) {
            insert attachmentList;
        }
        return returnedSAPSerialized;
    }

    @TestVisible
    private class ModelSAP {

        public TemplateDataIntegrationFields.CancellationOUTData header;
        public TemplateDataIntegrationFields.CancellingItemOUTData[] item;

        public ModelSAP() {
        }

        public ModelSAP(TemplateDataIntegrationFields.CancellationOUTData orderData) {
            this.header = orderData;
            this.item = new List<TemplateDataIntegrationFields.CancellingItemOUTData>(orderData.items);
            // System.debug('ModelSAP => ' + JSON.serializePretty(this));
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
}