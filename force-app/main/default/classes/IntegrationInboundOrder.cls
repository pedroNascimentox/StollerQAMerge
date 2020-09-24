@RestResource(urlMapping = '/orderService/*')
global with sharing class IntegrationInboundOrder {
    @HttpPost
    global static ResponseModel parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            TemplateDataIntegrationFields.OrderINData request = (TemplateDataIntegrationFields.OrderINData)JSON.deserialize(JSON.serialize(rawRequest.get('request')), TemplateDataIntegrationFields.OrderINData.class);

            return upsertOrder(request);

        } catch (Exception e) {

            Database.rollback(sp);

            String errorMessage = 'MESSAGE: ' + e.getMessage() + ' \n STACK TRACE: ' + e.getStackTraceString();

            ResponseModel response = new ResponseModel((Response)(new Response()).error(errorMessage));

            IntegrationUtils.WSLog('Pedido', 'Inbound', serializedRequest, JSON.serializePretty(response), true);
            
            return response;
            
        }
    }

    global static ResponseModel upsertOrder(TemplateDataIntegrationFields.OrderINData request) {
        // System.debug(request);

        String serializedRequest = JSON.serializePretty(request);

        Set<String> cliNotToIntegrate = new Set<String>();
        Map<String, CentroDelAgro__c> mapDescToCli = new Map<String, CentroDelAgro__c>();
        mapDescToCli = CentroDelAgro__c.getAll();

        for (String exIds : mapDescToCli.KeySet()){
             cliNotToIntegrate.add(mapDescToCli.get(exIds).ExternalId__c);
        }

        Integer internalDeadlineDays = PrazoInterno__c.getOrgDefaults().dias__c == null? 0 : Integer.valueOf(PrazoInterno__c.getOrgDefaults().dias__c);
        Savepoint sp = Database.setSavepoint();

        Map<String, Response> responseMap = new Map<String, Response>();
        List<Order> orderListToUpsert = new List<Order>();
        Boolean hasErrorOrder = false;
        
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();
        

        if (request.items != null && request.items.size() != 0) {


            Decimal taxaMedia = 1;
            for(CotacaoMoeda__c cotacoesMoeda : [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c <= :Date.today() ORDER BY Data__c DESC LIMIT 1]){
                taxaMedia = cotacoesMoeda.TaxaMedia__c;
            }

            TemplateDataIntegrationFields.OrderItemINData[] orderItemINDataList = new List<TemplateDataIntegrationFields.OrderItemINData>();

            for (TemplateDataIntegrationFields.OrderItemINData orderItemINData : request.items) {
                orderItemINData.orderData = request;
                // if(orderItemINData.schedules != null)
                    orderItemINDataList.addAll(orderItemINData.sapToSalesforce(orderItemINData.schedules, request.sapId));
            }

            request.items = orderItemINDataList;

            Map<String, Id> lookups = new Map<String, Id>();

            // Order Lookups
            List<String> condicaoPagamentoLookups = new List<String>();
            List<String> opportunityLookups = new List<String>();
            List<String> accountLookups = new List<String>();
            List<String> recebedorMercadoriaLookups = new List<String>();
            List<String> territorioLookups = new List<String>();
            List<String> rtvLookups = new List<String>();
            List<String> gerenteRegionalLookups = new List<String>();
            List<String> clienteAgenciadorLookups = new List<String>();

            // Order Item Lookups
            List<String> productLookups = new List<String>();
            List<String> deliveryLookups = new List<String>();
            List<String> culturaLookups = new List<String>();
            List<String> localNegocioLookups = new List<String>();
            List<String> itinerarioLookups = new List<String>();
            List<String> diretorLookups = new List<String>();
            
            Map<Id, ProgramacaoEntrega__c> itemIdToProgramacaoEntregaMap = new Map<Id, ProgramacaoEntrega__c>();

            Map<String, TemplateDataIntegrationFields.Response> responseChildrenMap = new Map<String, TemplateDataIntegrationFields.Response>();

            Map<String, String> metadataMap = IntegrationUtils.getMetadataDePara(new List<String>{'SetorAtividade',
                    'TipoOrdemNormal',
                    'TipoOrdemExportacao',
                    'TipoOrdemCredito',
                    'TipoOrdemDebito',
                    'TipoOrdemBonificacao',
                    'TipoOrdemContaOrdem',
                    'TipoOrdemRemanejamento',
                    'TipoOrdemComplemento',
                    'TipoOrdemDevolucao',
                    'TipoOrdemDevolucaoCliente',
                    'TipoOrdemVendaFutura'});
                    
            request.setorAtividade = metadataMap.containsKey(request.setorAtividade) ? metadataMap.get(request.setorAtividade) : request.setorAtividade;
            request.orderType = metadataMap.containsKey(request.orderType) ? metadataMap.get(request.orderType) : request.orderType;

            // adding Order Lookups
            condicaoPagamentoLookups.add(request.condicaoPagamentoId);
            opportunityLookups.add(request.opportunityId);
            accountLookups.add(request.accountId);
            recebedorMercadoriaLookups.add(request.recebedorMercadoriaId);
            territorioLookups.add(request.territorioId);
            rtvLookups.add(request.rtvId);
            gerenteRegionalLookups.add(request.gerenteRegionalId);
            clienteAgenciadorLookups.add(request.clienteAgenciadorId);
            diretorLookups.add(request.salesPlace);

            // adding OrderItem Lookups
            List<Id> orderItemExternalIds = new List<Id>();
            for (TemplateDataIntegrationFields.OrderItemINData orderItemINData : request.items) {
                if (!String.isBlank(orderItemINData.sfId)) {
                    orderItemExternalIds.add(orderItemINData.sfId);
                }
                itinerarioLookups.add(orderItemINData.itinerarioId);
                productLookups.add(orderItemINData.product2Id);
                culturaLookups.add(orderItemINData.culturaId);
                localNegocioLookups.add(orderItemINData.localNegocioId);
                deliveryLookups.add(orderItemINData.ProgramacaoId);
            }

            for (PricebookEntry pe : [SELECT Id, Product2Id, Product2.ExternalId__c FROM PricebookEntry WHERE Product2.ExternalId__c IN :productLookups]) {
                lookups.put('PricebookEntry' + pe.Product2.ExternalId__c, pe.Id);
            }
            
            // filling lookups map with Salesforce ids
            // Order lookups
            FactoryDataIntegration.addLookup('CondicaoPagamento__c', 'ExternalId__c', 'CondicaoPagamento__c', condicaoPagamentoLookups, lookups);
            FactoryDataIntegration.addLookup('Opportunity', 'NumeroOportunidade__c', 'OpportunityId', opportunityLookups, lookups);
            FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'AccountId', accountLookups, lookups);
            FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'RecebedorMercadoria__c', recebedorMercadoriaLookups, lookups);
            // FactoryDataIntegration.addLookup('Territorio__c', 'ExternalId__c', 'Territorio__c', territorioLookups, lookups);

            for (Territorio__c territorio : [SELECT Id, ExternalId__c, OwnerId FROM Territorio__c WHERE ExternalId__c IN :territorioLookups]) {
                lookups.put('Territorio__c' + territorio.ExternalId__c, territorio.Id);
                lookups.put('OwnerId' + territorio.ExternalId__c, territorio.OwnerId);
            }

            FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'RTV__c', rtvLookups, lookups);
            FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'GerenteRegional__c', gerenteRegionalLookups, lookups);
            FactoryDataIntegration.addLookup('User', 'BusinessPartnerSAP__c', 'Diretor__c', diretorLookups, lookups);
            FactoryDataIntegration.addLookup('Account', 'ExternalId__c', 'ClienteAgenciador__c', clienteAgenciadorLookups, lookups);
            FactoryDataIntegration.addLookup('ProgramacaoEntrega__c', 'Name', 'ProgramacaoEntrega__c', deliveryLookups, lookups);

            //OrderItem lookups
            Map<String, Integer> productExternalIdToLitragem = new Map<String, Integer>();
            Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();    
            Set<String> externalIdSet = new Set<String>();    
            for (Product2 product : [SELECT Id, ExternalId__c, Litragem__c, Embalagem__c FROM Product2 WHERE ExternalId__c IN :productLookups]) {
                lookups.put('Product2Id' + product.ExternalId__c, product.Id);
                productExternalIdToLitragem.put(product.ExternalId__c, Integer.valueOf(product.Litragem__c));
                mapIdToProduct.put(product.Id, product);
            }
            for(Territorio__c ter : [SELECT id, regional__c, ExternalId__c FROM Territorio__c WHERE ExternalId__c IN :territorioLookups]){
                lookups.put('Regional__c' + ter.ExternalId__c, ter.regional__c);
            }
            FactoryDataIntegration.addLookup('Itinerario__c', 'ExternalId__c', 'Itinerario__c', itinerarioLookups, lookups);
            FactoryDataIntegration.addLookup('Cultura__c', 'ExternalId__c', 'Cultura__c', culturaLookups, lookups);
            FactoryDataIntegration.addLookup('LocalNegocio__c', 'Codigo__c', 'LocalNegocio__c', localNegocioLookups, lookups);

            Response response = new Response();

            Order orderObj = request.serialize(lookups);
            
            orderObj.PrazoInterno__c = internalDeadlineDays;

            externalIdSet.add(orderObj.OVSAP__c);
            String stringFieldId = String.valueOf(orderObj.get(request.getFieldId()));
            String stringFieldKey = String.valueOf(orderObj.get(request.getFieldKey()));

            for (String field : request.getRequiredFields(request)) {
                if (IntegrationUtils.convertEmptyString(String.valueOf(orderObj.get(field)))){
                    hasErrorOrder = true;
                    if (responseMap.containsKey(stringFieldKey)) {
                        responseMap.get(stringFieldKey).error(
                            stringFieldKey,
                            ' | Valor inválido para o campo obrigatório: ' + field,
                            String.valueOf(orderListToUpsert.getSObjectType())
                        );
                    } else {
                        if (String.isNotEmpty(stringFieldId)){
                            response.error(
                                stringFieldId,
                                stringFieldKey,
                                'Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(orderListToUpsert.getSObjectType())
                            );
                        } else {
                            response.error(
                                stringFieldKey,
                                'Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(orderListToUpsert.getSObjectType())
                            );
                        }
                        responseMap.put(stringFieldKey, response);
                    }
                }
            }

            for (TemplateDataIntegrationFields.OrderItemINData orderItemINData : request.items) {

                orderItemINData.orderId = request.sapId;

                if (productExternalIdToLitragem.containsKey(orderItemINData.product2Id) && productExternalIdToLitragem.get(orderItemINData.product2Id) != null && orderItemINData.quantity != null) {
                    orderItemINData.litros = productExternalIdToLitragem.get(orderItemINData.product2Id) * orderItemINData.quantity;
                }
            
                TemplateDataIntegrationFields.Response responseChild = new TemplateDataIntegrationFields.Response();
                
                OrderItem orderItemObj = orderItemINData.serialize(lookups);

                IntegrationINboundOrder.setStatusSAP(orderItemObj, orderObj);

                // System.debug(orderItemObj.StatusSAP__c);

                String stringFieldIdChild = String.valueOf(orderItemObj.get(orderItemINData.getFieldId()));
                String stringFieldKeyChild = (orderItemINData.sfId != null ? orderItemINData.sfId+'_' : '_')+orderItemINData.nrItem;

                Boolean hasErrorOrderItem = false;

                for (String field : orderItemINData.getRequiredFields(orderItemINData)) {
                    if (IntegrationUtils.convertEmptyString(String.valueOf(orderItemObj.get(field)))){
                        hasErrorOrderItem = true;
                        if (responseChildrenMap.containsKey(stringFieldKeyChild)) {
                            responseChildrenMap.get(stringFieldKeyChild).error(
                                null,
                                ' | Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(orderItemListToUpsert.getSObjectType())
                            );
                        } else {
                            if (String.isNotEmpty(stringFieldIdChild)){
                                responseChild.error(
                                    stringFieldIdChild,
                                    null,
                                    'Valor inválido para o campo obrigatório: ' + field,
                                    String.valueOf(orderItemListToUpsert.getSObjectType())
                                );
                            } else {
                                responseChild.error(
                                    null,
                                    'Valor inválido para o campo obrigatório: ' + field,
                                    String.valueOf(orderItemListToUpsert.getSObjectType())
                                );
                            }
                            responseChildrenMap.put(stringFieldKeyChild, responseChild);
                        }
                    }
                }
                if (!hasErrorOrderItem) {
                    orderItemListToUpsert.add(orderItemObj);
                }
            }

            if(!hasErrorOrder) {
                orderListToUpsert.add(orderObj);
            }
            // System.debug(orderListToUpsert[0].TaxaMedia__c);

            Map<Id, Order> baseOrders = new Map<Id, Order>([SELECT Id, OVSAP__c, Moeda__c, CanalDistribuicao__c, TaxaMedia__c FROM Order WHERE OVSAP__c IN :externalIdSet]);
            if (!baseOrders.isEmpty() && !hasErrorOrder) {
                Order baseOrder = baseOrders.values()[0];
                orderListToUpsert[0].Moeda__c = baseOrder.moeda__c;
                if (baseOrder.Moeda__c == 'USD' && baseOrder.CanalDistribuicao__c == '10') {
                    for (OrderItem orderItem : orderItemListToUpsert) {
                        orderItem.ValorUnitarioComJuros__c = orderItem.ValorUnitarioComJuros__c / baseOrder.TaxaMedia__c;
                        orderItem.unitPrice = orderItem.unitPrice / baseOrder.TaxaMedia__c;
                    }
                }
                if(baseOrder.TaxaMedia__c != null){                    
                    orderListToUpsert[0].TaxaMedia__c = baseOrder.TaxaMedia__c;
                }
                // System.debug(taxaMedia);
            }
            if(!orderListToUpsert.isEmpty() && orderListToUpsert[0].TaxaMedia__c == null){                    
                orderListToUpsert[0].TaxaMedia__c = taxaMedia;
            }
            // System.debug(orderListToUpsert[0].TaxaMedia__c);

            List<Database.UpsertResult> orderResults = Database.upsert(orderListToUpsert, Order.OVSAP__c, true);
            
            Boolean hasErrorOnOrder = IntegrationUtils.upsertRecords(orderResults, responseMap, orderListToUpsert, Order.OVSAP__c);
            Boolean hasErrorOnOrderItem = false;

            List<Database.UpsertResult> insResults = new List<Database.UpsertResult>();
            List<Database.UpsertResult> upsResults = new List<Database.UpsertResult>();
            List<Database.UpsertResult> upsResultsZ2 = new List<Database.UpsertResult>();
            List<Database.UpsertResult> insResultsZ2 = new List<Database.UpsertResult>();
            
            List<OrderItem> orderItemListToUpdate = new List<OrderItem>();
            List<OrderItem> orderItemListToUpdateZ2 = new List<OrderItem>();
            List<OrderItem> orderItemListToInsertZ2 = new List<OrderItem>();

            List<OrderItem> orderItemListToInsert = new List<OrderItem>();
            
            Map<String, OrderItem> externalToOrdITemMap = new Map<String, OrderItem>();
            Map<Id, OrderItem> deleteItemMap = new Map<Id, OrderItem>();
            Set<Id> deleteDeliverySet = new Set<Id>();
            Set<string> existentPESet = new Set<string>();
            Set<String> ordItemExternalIdSet = new Set<String>(Collection.of(orderItemListToUpsert).pluckStrings(OrderITem.ExternalId__c));

            Map<String, ProgramacaoEntrega__c> existentPeMap = new Map<String, ProgramacaoEntrega__c>();
            Map<Id, ProgramacaoEntrega__c> productExistentPeMap = new Map<Id, ProgramacaoEntrega__c>();

            Order ord = null;
            Boolean isOrderNew = true;

            if(!hasErrorOnOrder) {

                isOrderNew = [SELECT Id, CreatedDate FROM Order WHERE Id = :orderListToUpsert[0].Id].CreatedDate.day() == Date.today().day();
                
                ord = orderListToUpsert[0];

                for(OrderItem existentOrderItem : [SELECT id, ExternalId__c, ProgramacaoEntrega__c 
                                                   FROM OrderItem 
                                                   WHERE  OrderId = : ord.id]){
                    if(ordItemExternalIdSet.contains(existentOrderItem.ExternalId__c)){
                        externalToOrdITemMap.put(existentOrderItem.ExternalId__c, existentOrderItem);
                        existentPESet.add(existentOrderItem.ExternalId__c);
                    }else{
                        deleteItemMap.put(existentOrderItem.id, existentOrderItem);
                        deleteDeliverySet.add(existentOrderItem.ProgramacaoEntrega__c);
                    }
                }

                for(ProgramacaoEntrega__c existentPe : [SELECT id, IdOrderitem__r.ExternalId__c, Name, EmissorOrdem__c, Status__c, Produto__c    
                                                        FROM ProgramacaoEntrega__c 
                                                        WHERE IdOrderitem__r.ExternalId__c IN : existentPESet
                                                        OR (IdOportunidade__c = : ord.OpportunityId AND Status__c = 'Integrado Manual')]){
                    if(existentPESet.contains(existentPe.IdOrderitem__r.ExternalId__c)){
                        existentPeMap.put(existentPe.IdOrderitem__r.ExternalId__c, existentPe);
                    }else if(existentPe.Status__c == 'Integrado Manual'){
                        productExistentPeMap.put(existentPe.Produto__c, existentPe);
                    }
                }
            }
            
            Map<String, OrderItem> productToFirstOrdItemMap = new Map<String, OrderItem>();

            List<ProgramacaoEntrega__c> newProgramacoesEntrega = new List<ProgramacaoEntrega__c>();
            List<ProgramacaoEntrega__c> newProgramacoesEntregaDelAgro = new List<ProgramacaoEntrega__c>();
            Map<Id, ProgramacaoEntrega__c> mapProgramacaoEntregaDelAgro = new Map<Id, ProgramacaoEntrega__c>();
            Map<Id,ProgramacaoEntrega__c> mapProgramacaoEntrega = new Map<Id, ProgramacaoEntrega__c>();
            Map<String, ProgramacaoEntrega__c> programacoesEntregaUpdateZ2 = new Map<String, ProgramacaoEntrega__c>();
            Map<String, ProgramacaoEntrega__c> newProgramacoesEntregaInsertZ2 = new Map<String, ProgramacaoEntrega__c>();
            Map<Id, ProgramacaoEntrega__c> mapProgramacaoEntregaInsertZ2 = new Map<Id, ProgramacaoEntrega__c>();
            Map<Id, ProgramacaoEntrega__c> mapProgramacaoEntregaUpdateZ2 = new Map<Id, ProgramacaoEntrega__c>();
            Map<Id, Order> idToOrdMap = null;
            Map<Id, Opportunity> idToOppMap = null;
            Map<Id, Itinerario__c> idToItinerarioMap = null;

            List<Id> newProgramacoesEntregaIds         = new List<Id>();
            List<Id> newProgramacoesEntregaInsertZ2Ids = new List<Id>();
            List<Id> programacoesEntregaDelAgroIds     = new List<Id>();
            List<Id> programacoesEntregaUpdateZ2Ids    = new List<Id>();

            Boolean isDelAgro = false;

            if (!hasErrorOnOrder) {

                idToOppMap = new Map<Id, Opportunity>([SELECT id, RecebedorMercadoria__c, AccountId, Territorio__c, NomeRTV__c, TipoOrdem__c FROM Opportunity WHERE id  = : ord.OpportunityId]);

                

                // System.debug(ord);

                idToItinerarioMap = new Map<Id, Itinerario__c>([SELECT id, Dias__c FROM Itinerario__c WHERE id IN : Collection.of(orderItemListToUpsert).pluckIds(OrderItem.Itinerario__c)]);

                idToOrdMap = new Map<Id, Order>([SELECT id, RTV__c, RTV__r.name, ClienteEmissor__c, Diretor__c, RecebedorMercadoria__c, ClienteEmissor__r.ExternalId__c,  BloqueioRemessa__c, OpportunityId, Moeda__c, TaxaMedia__c, TipoOrdem__c, Territorio__c, CanalDistribuicao__c, GerenteRegional__c
                                               FROM Order WHERE OVSAP__c = :ord.OVSAP__c]);

                isDelAgro = cliNotToIntegrate.contains(idToOrdMap.get(ord.id).ClienteEmissor__r.ExternalId__c);

                Map<String, Decimal> firstScheduleOrdMap = new Map<String, Decimal>();
                /*for(OrderItem existentOrderItem : [SELECT id, DescontoConcedido__c, NrITem__c, HeaderOrderItem__c, Product2Id, MotivoRecusaItem__c, PricebookEntryId,  NumeroRemessa__c,  ValorTotal__c,  ValorTotalUSD__c,  ValorUnitarioComJuros__c, LinhaDivisaoRemessa__c 
                                                   FROM OrderItem WHERE orderId = :ord.id  ORDER BY CreatedDate ASC]){
                    if(existentOrderItem.LinhaDivisaoRemessa__c != null){
                        Decimal linhaDecimal = Decimal.valueOf(existentOrderItem.LinhaDivisaoRemessa__c);

                        //Inicializa o mapa para descobrir qual o produto e sua remessa mais nova
                        //se o mapa esta vazio, não há remessas ainda, entao deve-se pegar a primeira para validar
                        if(!firstScheduleOrdMap.containsKey(existentOrderItem.NrITem__c))
                            firstScheduleOrdMap.put(existentOrderItem.NrITem__c, linhaDecimal);

                        //com o valor de remessa antigo, verificar se o valor que esta rodando agora é menor, indicando uma remessa mais antiga ainda, sendo assim pegando o orderitem com programação de entrega
                        if(firstScheduleOrdMap.get(existentOrderItem.NrITem__c) >= linhaDecimal){
                            firstScheduleOrdMap.put(existentOrderItem.NrITem__c, linhaDecimal);
                            productToFirstOrdItemMap.put(existentOrderItem.NrITem__c, existentOrderItem);
                        }
                    }else if(!productToFirstOrdItemMap.containsKey(existentOrderItem.NrITem__c)){
                        productToFirstOrdItemMap.put(existentOrderItem.NrITem__c, existentOrderItem);
                    }
                    if(isDelAgro){
                        if(existentOrderItem.HeaderOrderItem__c){
                            productToOrdItemMap.put(existentOrderItem.Product2Id, existentOrderItem);
                        }
                    }
                }*/
                    
                Map<Id, Id> prodToEntryMap = new Map<Id, Id>();

                if (Test.isRunningTest()) {
                    for(PricebookEntry price : [SELECT ID, Product2Id FROM PricebookEntry WHERE Product2Id IN : Collection.of(orderItemListToUpsert).pluckIds(OrderITem.Product2Id)]){
                        prodToEntryMap.put(price.Product2Id, price.Id);
                    }
                } else {
                    for(PricebookEntry price : [SELECT ID, Product2Id FROM PricebookEntry WHERE Product2Id IN : Collection.of(orderItemListToUpsert).pluckIds(OrderITem.Product2Id) AND Pricebook2.isStandard = true ]){
                        prodToEntryMap.put(price.Product2Id, price.Id);
                    }
                }
                for (Integer i = orderItemListToUpsert.size() - 1; i > -1; i--) {
                    OrderItem orderItem = orderItemListToUpsert[i];

                    Order existentOrder = idToOrdMap.get(ord.Id);

                    OrderItem orderItemNew = new OrderItem();
                        
                    orderItemNew.OrderId                         = ord.Id;
                    orderItemNew.ValorUnitarioComJuros__c        = orderItem.ValorUnitarioComJuros__c;
                    orderItemNew.Quantity                        = orderItem.Quantity;
                    orderItemNew.ValorTotal__c                   = IntegrationUtils.checkDecimal(orderItemNew.ValorUnitarioComJuros__c) * IntegrationUtils.checkDecimal(orderItem.Quantity);
                    orderItemNew.PrecoLista__c                   = orderItem.PrecoLista__c;
                    orderItemNew.ValorJuros__c                   = orderItem.ValorJuros__c;
                    orderItemNew.PrecoVendaSemJuros__c           = orderItem.PrecoVendaSemJuros__c;
                    orderItemNew.PrecoListaReferencia__c         = orderItem.PrecoListaReferencia__c;

                    if (existentOrder.Moeda__c == 'USD' && existentOrder.CanalDistribuicao__c == '10'){
                        orderItemNew.ValorTotal__c            = orderItemNew.ValorTotal__c * existentOrder.TaxaMedia__c;
                        orderItemNew.PrecoLista__c            = orderItem.PrecoLista__c/existentOrder.TaxaMedia__c;
                        orderItemNew.ValorJuros__c            = orderItem.ValorJuros__c/existentOrder.TaxaMedia__c;
                        orderItemNew.PrecoVendaSemJuros__c    = orderItem.PrecoVendaSemJuros__c/existentOrder.TaxaMedia__c;
                        orderItemNew.PrecoListaReferencia__c  = orderItem.PrecoListaReferencia__c/existentOrder.TaxaMedia__c;
                    }

                    orderItemNew.ValorTotalComJuros__c           = IntegrationUtils.checkDecimal(orderItemNew.ValorUnitarioComJuros__c) * IntegrationUtils.checkDecimal(orderItem.Quantity);
                    orderItemNew.UnitPrice                       = orderItem.UnitPrice;
                    orderItemNew.Itinerario__c                   = orderItem.Itinerario__c;
                    orderItemNew.NumeroPedidoCliente__c          = orderItem.NumeroPedidoCliente__c;
                    orderItemNew.Cultura__c                      = orderItem.Cultura__c;
                    orderItemNew.LocalNegocio__c                 = orderItem.LocalNegocio__c;
                    orderItemNew.DataEntrega__c                  = orderItem.DataEntrega__c;
                    orderItemNew.QuantidadeConfirmada__c         = orderItem.QuantidadeConfirmada__c;
                    orderItemNew.Unidade__c                      = orderItem.Unidade__c;
                    orderItemNew.Embalagem__c                    = mapIdToProduct.get(orderItem.Product2Id).Embalagem__c;
                    orderItemNew.SaldoLitros__c                  = orderItem.SaldoLitros__c;
                    orderItemNew.DataFaturamento__c              = orderItem.DataFaturamento__c;
                    orderItemNew.StatusGlobalItem__c             = orderItem.StatusGlobalItem__c;
                    orderItemNew.StatusFornecItem__c             = orderItem.StatusFornecItem__c;
                    orderItemNew.StatusSAP__c                    = orderItem.StatusSAP__c;
                    orderItemNew.BloqueioDocumentoFaturamento__c = orderItem.BloqueioDocumentoFaturamento__c;
                    orderItemNew.NrItem__c                       = orderItem.NrItem__c;
                    orderItemNew.DataRemSolicitReal__c           = orderItem.DataRemSolicitReal__c;
                    orderItemNew.QuantidadeFornecida__c          = orderItem.QuantidadeFornecida__c;
                    orderItemNew.SaldoFornecer__c                = orderItem.SaldoFornecer__c;
                    orderItemNew.DataInicioExpedicao__c          = orderItem.DataInicioExpedicao__c;
                    orderItemNew.NumeroRemessa__c                = orderItem.NumeroRemessa__c;
                    orderItemNew.ExternalId__c                   = orderItem.ExternalId__c;
                    orderItemNew.QuantidadeTotal__c              = orderItem.QuantidadeTotal__c;                  
                    orderItemNew.LinhaDivisaoRemessa__c          = orderItem.LinhaDivisaoRemessa__c;
                    // orderItemNew.ValorTotalReaisDolar__c         = (existentOrder.Moeda__c == 'BRL' || existentOrder.tipoOrdem__c == 'Exportação' ? orderItemNew.ValorTotalComJuros__c : orderItemNew.ValorTotalComJuros__c / taxaMedia);
                    orderItemNew.ValorTotalReaisDolar__c         = orderItemNew.ValorTotalComJuros__c;
                    orderItemNew.DescontoConcedido__c            = orderItem.DescontoConcedido__c;
                    orderItemNew.IntegrationUpdate__c            = true;
                    orderItemNew.Litros__c                       = mapIdToProduct.get(orderItem.Product2Id).Litragem__c;

                    IntegrationINboundOrder.setStatusSAP(orderItemNew, existentOrder);

                    if(Integer.ValueOf(orderItem.LinhaDivisaoRemessa__c) == 1){
                        // System.debug('orderItem => ' + JSON.serializePretty(orderItem));
                        orderItemNew.MotivoRecusaItem__c             = orderItem.MotivoRecusaItem__c;
                        orderItemNew.HeaderOrderItem__c              = true;
                        if(orderitem.programacaoEntrega__c != null)
                            orderItemNew.ProgramacaoEntrega__c           = orderitem.programacaoEntrega__c;
                    }
        
                    // System.debug(orderItem);
                    if(existentOrder.tipoOrdem__c == 'Exportação'){
                        orderItemNew.ValorTotalUSD__c                = orderItem.ValorTotal__c;
                        orderItemNew.ValorTotal__c                = orderItemNew.ValorTotalUSD__c * existentOrder.TaxaMedia__c;
                        if(!externalToOrdITemMap.containsKey(orderItem.ExternalId__c)){
                            orderItemNew.unitPrice = orderItem.ValorUnitarioComJuros__c;
                            orderItemNew.PricebookEntryId = prodToEntryMap.get(orderitem.Product2Id);
                            orderItemNew.Product2Id       = orderItem.Product2Id;
                            orderItemListToInsert.add(orderItemNew);
                        }else{
                            orderItemListToUpdate.add(orderItemNew);
                        }
                    } 
                    if(orderItem.MotivoRecusaItem__c != 'Z2'){
                        if(existentOrder.tipoOrdem__c != 'Exportação'){
                            if(!externalToOrdITemMap.containsKey(orderItem.ExternalId__c)){
                                orderItemNew.ValorTotalUSD__c                = orderItem.ValorTotal__C / existentOrder.TaxaMedia__c;
                                orderItemNew.unitPrice = orderItem.ValorUnitarioComJuros__c;
                                orderItemNew.PricebookEntryId = prodToEntryMap.get(orderitem.Product2Id);
                                orderItemNew.Product2Id       = orderItem.Product2Id;
                                orderItemListToInsert.add(orderItemNew);
                            }else{
                                // System.debug(orderItem.ValorTotal__C);
                                // System.debug(ord.TaxaMedia__c);
                                orderItemNew.ValorTotalUSD__c                = orderItem.ValorTotal__C / existentOrder.TaxaMedia__c;
                                orderItemListToUpdate.add(orderItemNew);
                            }
                        }
                    }else{

                        if(existentOrder.tipoOrdem__c != 'Exportação'){
                            if(!externalToOrdITemMap.containsKey(orderItem.ExternalId__c)){
                                orderItemNew.ValorTotalUSD__c                = orderItem.ValorTotal__C / existentOrder.TaxaMedia__c;
                                orderItemNew.unitPrice = orderItem.ValorUnitarioComJuros__c;
                                orderItemNew.PricebookEntryId = prodToEntryMap.get(orderitem.Product2Id);
                                orderItemNew.Product2Id       = orderItem.Product2Id;
                                orderItemListToInsertZ2.add(orderItemNew);
                            }else{
                                // System.debug(orderItem.ValorTotal__C);
                                // System.debug(ord.TaxaMedia__c);
                                orderItemNew.ValorTotalUSD__c                = orderItem.ValorTotal__C / existentOrder.TaxaMedia__c;
                                orderItemListToUpdateZ2.add(orderItemNew);

                            }
                        }
                        if(orderItemNew.HeaderOrderItem__c){
                            Boolean isInsert = !externalToOrdITemMap.containsKey(orderItem.ExternalId__c);
                            ProgramacaoEntrega__c programacaoEntrega =    new ProgramacaoEntrega__c();
                            programacaoEntrega.Status__c                  = 'Liberado';
                            programacaoEntrega.Litros__c                  = orderItemNew.Litros__c * orderItemNew.QuantidadeTotal__C;
                            programacaoEntrega.EmissorOrdem__c            = existentOrder.ClienteEmissor__c;
                            programacaoEntrega.StatusSAP__c               = 'Não Confirmado';
                            programacaoEntrega.TaxaDolar__c               = isOrderNew ? taxamedia : ord.TaxaMedia__c;
                            programacaoEntrega.DescontoConcedido__c       = orderItemNew.DescontoConcedido__c;
                            programacaoEntrega.DataEntrega__c             = orderItemNew.DataEntrega__c;
                            programacaoEntrega.DataIntegracao__c          = null;
                            programacaoEntrega.Confirmado__c              = false;
                            programacaoEntrega.Produto__c                 = orderItem.Product2Id;
                            programacaoEntrega.IdOportunidade__c          = ord.OpportunityId;
                            programacaoEntrega.QuantidadeProgramada__c    = orderItemNew.QuantidadeTotal__C;                   
                            programacaoEntrega.Cultura__c =  orderItemNew.Cultura__c; 
                            programacaoEntrega.PrecoLista__c                   = orderItemNew.PrecoLista__c;
                            programacaoEntrega.LocalNegocio__c =  orderItemNew.LocalNegocio__c;
                            programacaoEntrega.PrecoListaReferencia__c =  orderItemNew.PrecoListaReferencia__c;
                            programacaoEntrega.PrecoVenda__c =  orderItemNew.PrecoVendaSemJuros__c;
                            programacaoEntrega.Juros__c =  orderItemNew.ValorJuros__c;
                            programacaoEntrega.IdOrderItem__c = null;
                            programacaoEntrega.DataFaturamento__c              = orderItemNew.DataFaturamento__c;
                            programacaoEntrega.ValorTotal__c =  orderItemNew.ValorTotal__c;
                            programacaoEntrega.DiretorComercial__c                       = existentOrder.Diretor__c;
                            programacaoEntrega.ValorTotalUSD__c =  orderItemNew.ValorTotalUSD__c;
                            programacaoEntrega.precoVendaJuros__c =  (orderItemNew.ValorTotal__c / orderItemNew.QuantidadeTotal__c);
                            programacaoEntrega.precoVendasJurosUSD__c =  (orderItemNew.ValorTotalUSD__c / orderItemNew.QuantidadeTotal__c);
                            programacaoEntrega.Litros__c =  orderItemNew.Litros__c * orderItemNew.QuantidadeTotal__C;
                            programacaoEntrega.TipoOrdem__c = existentOrder.tipoOrdem__c;

                            // programacaoEntrega.DataIntegracao__c =  System.today();
                            programacaoEntrega.Confirmado__c =  false;
                            programacaoEntrega.PrazoINterno__c = internalDeadlineDays;

                            programacaoEntrega.Valorunitario__c = orderItemNew.UnitPrice;
                            programacaoEntrega.RTV__c =  existentOrder.RTV__c;
                            programacaoEntrega.Territorio__c = existentOrder.Territorio__c;
                            programacaoEntrega.GerenteRegional__c = existentOrder.GerenteRegional__c;
                            programacaoEntrega.RecebedorOrdem__c = existentOrder.RecebedorMercadoria__c;

                            if(idToOppMap.containsKey(existentOrder.OpportunityId)){
                                Opportunity opp = idToOppMap.get(existentOrder.OpportunityId);
                                if(programacaoEntrega.TipoOrdem__c == null)
                                    programacaoEntrega.TipoOrdem__c = opp.TipoOrdem__c;
                                programacaoEntrega.RecebedorOrdem__c = opp.RecebedorMercadoria__c;
                                System.debug('WRONG opp.AccountId => ' + opp.AccountId);
                                System.debug('RIGHT existentOrder.ClienteEmissor__c => ' + existentOrder.ClienteEmissor__c);
                                programacaoEntrega.EmissorOrdem__c = existentOrder.ClienteEmissor__c;//opp.AccountId;
                                programacaoEntrega.Territorio__c = opp.Territorio__c;
                                programacaoEntrega.NomeRTV__c = opp.NomeRTV__c;
                            }else{
                                programacaoEntrega.TipoOrdem__c =  existentOrder.TipoOrdem__c;
                                programacaoEntrega.RTV__c =  existentOrder.RTV__c;
                                programacaoEntrega.NomeRTV__c = existentOrder.RTV__r.name;
                                programacaoEntrega.DiretorComercial__c = existentOrder.Diretor__c;
                            }

                            if(idToItinerarioMap.containsKey(orderItemNew.Itinerario__c)){
                                programacaoEntrega.PrazoItinerario__c = idToItinerarioMap.get(orderItemNew.Itinerario__c).dias__c;
                            }

                            if(!existentPeMap.containsKey(orderItemNew.ExternalId__c) && isInsert){
                                if(isDelAgro && orderItem.programacaoEntrega__c != null){
                                    programacaoEntrega.id = orderItem.programacaoEntrega__c;
                                    programacoesEntregaUpdateZ2.put(orderItemNew.ExternalId__c, programacaoEntrega);
                                }else{
                                    newProgramacoesEntregaInsertZ2.put(orderItemNew.ExternalId__c, programacaoEntrega);
                                }
                            }else if(existentPeMap.containsKey(orderItemNew.ExternalId__c)){
                                programacaoEntrega.Id = existentPeMap.get(orderItemNew.ExternalId__c).id;
                                programacoesEntregaUpdateZ2.put(orderItemNew.ExternalId__c, programacaoEntrega);
                            }
                            System.debug('BEFORE orderItemNew.programacaoEntrega__c' + orderItemNew.programacaoEntrega__c);
                            orderItemNew.programacaoEntrega__c = null;
                            System.debug('AFTER orderItemNew.programacaoEntrega__c' + orderItemNew.programacaoEntrega__c);
                        }                        
                    }
                    // System.debug(orderItemNew);
                    // System.debug('orderItem.OrderId => ' + orderItemNew.OrderId);
                }
                // System.debug(orderItemListToInsert);
                // System.debug(orderItemListToUpdate);
                // System.debug(orderItemListToUpdateZ2);
                // System.debug('orderItemListToInsert => ' + JSON.serializePretty(orderItemListToInsert));
                insResults = Database.upsert(orderItemListToInsert,  true);
                insResultsZ2 = Database.upsert(orderItemListToInsertZ2,  true);
                ProgramacaoEntregaHelper.disableTrigger();
                upsResults = Database.upsert(orderItemListToUpdate, OrderItem.ExternalId__c, true);
                upsResultsZ2 = Database.upsert(orderItemListToUpdateZ2, OrderItem.ExternalId__c, true);
                ProgramacaoEntregaHelper.enableTrigger();

                /*
                for(OrderItem ordItem : [SELECT id, ExternalId__c FROM OrderItem WHERE (ExternalId__c IN :programacoesEntregaUpdateZ2.keySet() OR ExternalId__c IN :newProgramacoesEntregaInsertZ2.keySet())]){
                    if(programacoesEntregaUpdateZ2.containsKey(ordItem.ExternalId__c)){
                        programacoesEntregaUpdateZ2.get(ordItem.ExternalId__c).IdOrderItem__c = ordItem.id;
                    }else{
                        newProgramacoesEntregaInsertZ2.get(ordItem.ExternalId__c).IdOrderItem__c = ordItem.id;
                    }
                }
                */

                if (!programacoesEntregaUpdateZ2.values().isEmpty()) {

                    for(ProgramacaoEntrega__c delivery : programacoesEntregaUpdateZ2.values()){
                        programacoesEntregaUpdateZ2Ids.add(delivery.Id);
                    }

                    List<ProgramacaoEntrega__c> lstProgramacaoEntregaUpdateZ2 = [SELECT Id, CriterioApuracao__c, EmissorOrdem__C, Territorio__c, 
                                                                                Produto__c, DataFaturamento__c, Apuracao__c, TipoOrdem__c
                                                                                FROM ProgramacaoEntrega__c WHERE Id IN : programacoesEntregaUpdateZ2Ids];
                    
                    for(ProgramacaoEntrega__c delivery : lstProgramacaoEntregaUpdateZ2){
                        if(!mapProgramacaoEntregaUpdateZ2.containsKey(delivery.Id))
                            mapProgramacaoEntregaUpdateZ2.put(delivery.Id, delivery);
                    }

                    ProgramacaoEntregaHelper.disableTrigger();
                    System.debug('IGNI programacoesEntregaUpdateZ2 => ' + JSON.serializePretty(programacoesEntregaUpdateZ2));
                    update programacoesEntregaUpdateZ2.values();
                    ProgramacaoEntregaHelper.updateApuracaoRelation(mapProgramacaoEntregaUpdateZ2);
                    ProgramacaoEntregaHelper.enableTrigger();
                }
                if (!newProgramacoesEntregaInsertZ2.values().isEmpty()) {
                    
                    ProgramacaoEntregaHelper.disableTrigger();
                    System.debug('PROMPTO newProgramacoesEntregaInsertZ2 => ' + JSON.serializePretty(newProgramacoesEntregaInsertZ2));
                    insert newProgramacoesEntregaInsertZ2.values();

                    for(ProgramacaoEntrega__c delivery : newProgramacoesEntregaInsertZ2.values()){
                        newProgramacoesEntregaInsertZ2Ids.add(delivery.Id);
                    }

                    List<ProgramacaoEntrega__c> lstProgramacaoEntregaZ2 = [SELECT Id, CriterioApuracao__c, EmissorOrdem__C, Territorio__c, 
                                                                          Produto__c, DataFaturamento__c, Apuracao__c, TipoOrdem__c
                                                                          FROM ProgramacaoEntrega__c WHERE Id IN : newProgramacoesEntregaInsertZ2Ids];

                    for(ProgramacaoEntrega__c delivery : lstProgramacaoEntregaZ2){
                        if(!mapProgramacaoEntregaInsertZ2.containsKey(delivery.Id))
                            mapProgramacaoEntregaInsertZ2.put(delivery.Id, delivery);
                    }


                    ProgramacaoEntregaHelper.updateApuracaoRelation(mapProgramacaoEntregaInsertZ2);
                    ProgramacaoEntregaHelper.changeProgramacaoEntregaOwner(lstProgramacaoEntregaZ2);
                    ProgramacaoEntregaHelper.enableTrigger();
                }
                // System.debug('newProgramacoesEntregaInsertZ2 => ' + JSON.serializePretty(newProgramacoesEntregaInsertZ2));
                // System.debug('programacoesEntregaUpdateZ2 => ' + JSON.serializePretty(programacoesEntregaUpdateZ2));
                // upsResults.addAll(insResults);

                hasErrorOnOrderItem = IntegrationUtils.upsertRecords(upsResults, responseChildrenMap, orderItemListToUpsert, OrderItem.ExternalId__c);
                if(!hasErrorOnOrderItem)
                    hasErrorOnOrderItem = IntegrationUtils.upsertRecords(upsResultsZ2, responseChildrenMap, orderItemListToUpsert, OrderItem.ExternalId__c);
                if(!hasErrorOnOrderItem)
                    hasErrorOnOrderItem = IntegrationUtils.upsertRecords(insResults, responseChildrenMap, orderItemListToUpsert, OrderItem.ExternalId__c);
                if(!hasErrorOnOrderItem)
                    hasErrorOnOrderItem = IntegrationUtils.upsertRecords(insResultsZ2, responseChildrenMap, orderItemListToUpsert, OrderItem.ExternalId__c);
            }
            
            for (String key : responseMap.keySet()) {
                // System.debug(responseChildrenMap.values());
                responseMap.get(key).itemResponse = new List<TemplateDataIntegrationFields.Response>(responseChildrenMap.values());
            }

            if (hasErrorOnOrder || hasErrorOnOrderItem) {
                hasErrorOrder = true;
                Database.rollback(sp);
            } else {
                
                List<String> externalIdsToCheck = new List<String>();
                List<String> orderItemIdsToInsert = new List<String>();
                List<String> orderItemIdsToUpdate = new List<String>();
                for (Integer i = 0; i < upsResults.size(); i++) {
                    if(Integer.ValueOf(orderItemListToUpdate[i].LinhaDivisaoRemessa__c) == 1){
                        if (externalToOrdITemMap.containsKey(orderItemListToUpdate[i].ExternalId__c)) {
                            orderItemIdsToUpdate.add(orderItemListToUpdate[i].Id);
                        }
                    }
                }

                for (Integer i = 0; i < insResults.size(); i++) {
                    if(Integer.ValueOf(orderItemListToInsert[i].LinhaDivisaoRemessa__c) == 1)
                        orderItemIdsToInsert.add(orderItemListToInsert[i].Id);                    
                }
/*
                List<OrderItem> orderItemsToCheckQuantity = [SELECT Id, DataEntrega__c, StatusSAP__c, Quantity, QuantidadeConfirmada__c, MotivoRecusaItem__c FROM OrderItem WHERE ExternalId__c IN :externalIdsToCheck];
                List<ProgramacaoEntrega__c> newProgramacoesEntregaDueToQuantity = new List<ProgramacaoEntrega__c>();
                for (OrderItem oi : orderItemsToCheckQuantity) {
                    if (oi.QuantidadeConfirmada__c < oi.Quantity) {
                        newProgramacoesEntregaDueToQuantity.add(
                            new ProgramacaoEntrega__c(
                                Status__c                  = (oi.MotivoRecusaItem__c != 'ZS' ? 'Liberado' : 'Cancelado'),
                                StatusSAP__c               = oi.StatusSAP__c == 'Produto Indisponível' ? oi.StatusSAP__c : (oi.MotivoRecusaItem__c != 'ZS' ? 'Não Confirmado' : 'Cancelado'),
                                DataEntrega__c             = oi.DataEntrega__c,
                                IdOportunidade__c          = orderObj.OpportunityId,
                                IdOpportunityLineItem__c   = oi.Id,
                                QuantidadeProgramada__c    = oi.Quantity,
                                QuantidadeDisponivelSAP__c = oi.Quantity - oi.QuantidadeConfirmada__c
                            )
                        );
                    }
                }
                if (!newProgramacoesEntregaDueToQuantity.isEmpty()) {
                    ProgramacaoEntregaHelper.disableTrigger();
                    insert newProgramacoesEntregaDueToQuantity;
                    ProgramacaoEntregaHelper.enableTrigger();
                }
                */
                Map<Id, String> productToOrdItemMap = new Map<Id, String>();
                Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(
                    [
                        SELECT Id, 
                               Moeda__c, 
                               PrecoLista__c, 
                               Order.RecebedorMercadoria__c, 
                               Order.RTV__r.name, 
                               Order.Diretor__c, 
                               Order.OpportunityId, 
                               Product2Id, 
                               Itinerario__c, 
                               Itinerario__r.dias__c, 
                               NumeroPedidoCliente__c, 
                               Order.ClienteEmissor__c , 
                               Cultura__c, 
                               LocalNegocio__c, 
                               PrecoListaReferencia__c, 
                               PrecoVendaSemJuros__c, 
                               ValorJuros__c, 
                               UnitPrice, 
                               ValorTotal__c, 
                               ValorTotalUSD__c, 
                               ValorTotalComJuros__c, 
                               ValorUnitarioComJuros__c, 
                               Litros__c, 
                               MotivoRecusaItem__c, 
                               DataFaturamento__c, 
                               ProgramacaoEntrega__c, 
                               OrderId, 
                               Quantity, 
                               QuantidadeConfirmada__c, 
                               Order.Territorio__c, 
                               Order.GerenteRegional__c, 
                               Order.TipoOrdem__c, 
                               Order.RTV__c, 
                               Order.TaxaMedia__c, 
                               Order.CreatedDate, 
                               DataEntrega__c, 
                               Status__c, 
                               StatusSAP__c, 
                               QuantidadeTotal__C, 
                               DescontoConcedido__c 
                        FROM OrderItem 
                        WHERE Id IN :orderItemIdsToInsert
                    ]);
                for (OrderItem oi : orderItemMap.values()) {

                    Opportunity opp = idToOppMap.get(oi.Order.OpportunityId);
                    Decimal taxaToUse = oi.Order.CreatedDate.day() == Date.today().day() ? taxaMedia : oi.Order.TaxaMedia__c;

                    ProgramacaoEntrega__c programacaoEntrega = new ProgramacaoEntrega__c(
                        Status__c                  = (oi.MotivoRecusaItem__c != 'ZS' ? 'Integrado' : 'Cancelado'),
                        StatusSAP__c               = oi.StatusSAP__c == 'Bloqueio de Remessa' ? 'Bloqueio de Remessa' : (oi.StatusSAP__c == 'Produto Indisponível' ? 'Produto Indisponível' : (oi.MotivoRecusaItem__c != 'ZS' ? 'Confirmado' : 'Cancelado')),
                        DataEntrega__c             = oi.DataEntrega__c,
                        EmissorOrdem__c            = oi.order.ClienteEmissor__c,
                        DataIntegracao__c          = Date.Today(),
                        Confirmado__c              = true,
                        TaxaDolar__c               = taxaToUse,// taxamedia,
                        DiretorComercial__c        = oi.Order.Diretor__c,
                        PrecoLista__c              = oi.PrecoLista__c,
                        DataFaturamento__c         = oi.DataFaturamento__c,
                        Produto__c                 = oi.Product2Id,
                        IdOportunidade__c          = orderObj.OpportunityId,
                        IdOrderItem__c             = oi.Id,
                        QuantidadeProgramada__c    = oi.QuantidadeTotal__C,
                        QuantidadeDisponivelSAP__c = oi.QuantidadeConfirmada__c,
                        PrecoVendaJuros__c         = oi.Moeda__c == 'BRL' ? oi.ValorUnitarioComJuros__c : oi.ValorUnitarioComJuros__c * taxaToUse,
                        PrecoVendasJurosUSD__c     = oi.Moeda__c == 'BRL' ? oi.ValorUnitarioComJuros__c / taxaToUse : oi.ValorUnitarioComJuros__c,
                        RecebedorOrdem__c          = oi.Order.RecebedorMercadoria__c,
                        
                        NumeroPedidoCliente__c  = oi.NumeroPedidoCliente__c,
                        Cultura__c              = oi.Cultura__c, 
                        LocalNegocio__c         = oi.LocalNegocio__c,
                        PrecoListaReferencia__c = oi.PrecoListaReferencia__c,
                        PrecoVenda__c           = oi.PrecoVendaSemJuros__c,
                        Juros__c                = oi.ValorJuros__c,
                        ValorTotal__c           = oi.ValorTotal__c,
                        ValorTotalUSD__c        = oi.ValorTotalUSD__c,
                        Litros__c               = (oi.Litros__c * oi.QuantidadeTotal__C),
                        PrazoINterno__c         = internalDeadlineDays,
                        Valorunitario__c        = oi.UnitPrice,
                        Territorio__c           = oi.Order.Territorio__c,
                        GerenteRegional__c      = oi.Order.GerenteRegional__c,
                        TipoOrdem__c            = oi.Order.TipoOrdem__c,
                        RTV__c                  = oi.Order.RTV__c,
                        DescontoConcedido__c    = oi.DescontoConcedido__c,
                        NomeRTV__c              = oi.Order.RTV__r.name
                    );


                    if(oi.Itinerario__c != null){
                        programacaoEntrega.PrazoItinerario__c = oi.Itinerario__r.dias__c;
                    }
                    if(opp != null){
                        if(programacaoEntrega.TipoOrdem__c == null)
                            programacaoEntrega.TipoOrdem__c = opp.TipoOrdem__c;
                        programacaoEntrega.RecebedorOrdem__c = opp.RecebedorMercadoria__c;
                        programacaoEntrega.Territorio__c = opp.Territorio__c;
                        programacaoEntrega.NomeRTV__c = opp.NomeRTV__c; 
                    }
                    if(isDelAgro){
                        if(oi.ProgramacaoEntrega__c != null){
                            programacaoEntrega.id = oi.ProgramacaoEntrega__c;
                            newProgramacoesEntregaDelAgro.add(programacaoEntrega);
                        }else{
                            newProgramacoesEntrega.add(programacaoEntrega);
                        }
                    }else{
                        newProgramacoesEntrega.add(programacaoEntrega);
                    }
                }

                if (!newProgramacoesEntregaDelAgro.isEmpty()) {

                    for(ProgramacaoEntrega__c delivery : newProgramacoesEntregaDelAgro){
                        programacoesEntregaDelAgroIds.add(delivery.Id);
                    }

                    List<ProgramacaoEntrega__c> lstProgramacaoEntregaDelAgro = [SELECT Id, CriterioApuracao__c, EmissorOrdem__C, Territorio__c, 
                                                                                Produto__c, DataFaturamento__c, Apuracao__c, TipoOrdem__c
                                                                                FROM ProgramacaoEntrega__c WHERE Id IN : programacoesEntregaDelAgroIds];

                    for(ProgramacaoEntrega__c delivery : lstProgramacaoEntregaDelAgro){
                        if(!mapProgramacaoEntregaDelAgro.containsKey(delivery.Id)){
                            mapProgramacaoEntregaDelAgro.put(delivery.Id, delivery);
                        }
                    }

                    ProgramacaoEntregaHelper.disableTrigger();
                    update newProgramacoesEntregaDelAgro;
                    ProgramacaoEntregaHelper.updateApuracaoRelation(mapProgramacaoEntregaDelAgro);
                    System.debug('DELAGRO newProgramacoesEntregaDelAgro => ' + JSON.serializePretty(newProgramacoesEntregaDelAgro));
                    ProgramacaoEntregaHelper.enableTrigger();
                }

                if (!newProgramacoesEntrega.isEmpty()) {

                    ProgramacaoEntregaHelper.disableTrigger();
                    System.debug('NEWDELIVERY newProgramacoesEntregaDelAgro => ' + JSON.serializePretty(newProgramacoesEntregaDelAgro));
                    insert newProgramacoesEntrega;

                    for(ProgramacaoEntrega__c delivery : newProgramacoesEntrega){
                        newProgramacoesEntregaIds.add(delivery.Id);
                    }

                    List<ProgramacaoEntrega__c> lstProgramacaoEntrega = [SELECT Id, CriterioApuracao__c, EmissorOrdem__C, Territorio__c, 
                                                                        Produto__c, DataFaturamento__c,Apuracao__c, TipoOrdem__c
                                                                        FROM ProgramacaoEntrega__c WHERE Id IN : newProgramacoesEntregaIds];

                    for(ProgramacaoEntrega__c delivery : lstProgramacaoEntrega){
                        if(!mapProgramacaoEntrega.containsKey(delivery.Id))
                            mapProgramacaoEntrega.put(delivery.Id, delivery);
                    }
                    
                    ProgramacaoEntregaHelper.updateApuracaoRelation(mapProgramacaoEntrega);
                    ProgramacaoEntregaHelper.enableTrigger();
                }

                for (ProgramacaoEntrega__c pe : newProgramacoesEntregaDelAgro) {
                    orderItemMap.get(pe.IdOrderItem__c).ProgramacaoEntrega__c = pe.Id;
                }
                
                for (ProgramacaoEntrega__c pe : newProgramacoesEntrega) {
                    orderItemMap.get(pe.IdOrderItem__c).ProgramacaoEntrega__c = pe.Id;
                }
                OrderItemHelper.disableTrigger();
                if (orderItemMap.values().size() != 0) {
                    update orderItemMap.values();
                }
                OrderItemHelper.enableTrigger();
                
                Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>();
                if(!orderItemIdsToUpdate.isEmpty()){
                    orderItems = new Map<Id, OrderItem>([
                        SELECT Id,
                               DescontoConcedido__c,
                               Order.TipoOrdem__c,
                               ValorUnitarioComJuros__c,
                               PrecoLista__c,
                               Moeda__c,
                               ProgramacaoEntrega__c,
                               PrazoItinerario__c,
                               DataFaturamento__c,
                               LocalNegocio__c,
                               Quantity,
                               QuantidadeTotal__C,
                               QuantidadeConfirmada__c,
                               DataEntrega__c,
                               Status__c,
                               StatusSAP__c,
                               MotivoRecusaItem__c,
                               OrderId,
                               Order.ClienteEmissor__c,
                               Order.TaxaMedia__c
                        FROM OrderItem 
                        WHERE Id IN :orderItemIdsToUpdate
                    ]);
                }
                Map<Id, Id> itemIdToProgramacaoEntregaIdMap = new Map<Id, Id>();
                Map<Id, Id> programacaoEntregaIdToItemIdMap = new Map<Id, Id>();
                for (OrderItem oi : orderItems.values()) {
                    // System.debug('OrderItem oi => ' + JSON.serializePretty(oi));
                    itemIdToProgramacaoEntregaIdMap.put(oi.Id, oi.ProgramacaoEntrega__c);
                    programacaoEntregaIdToItemIdMap.put(oi.ProgramacaoEntrega__c, oi.Id);
                }
                // System.debug('orderItems.size() => ' + JSON.serializePretty(orderItems.size()));
                Map<Id, ProgramacaoEntrega__c> programacoesEntrega = new Map<Id, ProgramacaoEntrega__c>();
                if(!itemIdToProgramacaoEntregaIdMap.isEmpty() || !deleteDeliverySet.isEmpty()){
                    programacoesEntrega = new Map<Id, ProgramacaoEntrega__c>([
                        SELECT Id,
                               PrecoLista__c,
                               TipoOrdem__c,
                               DataIntegracao__c,
                               LocalNegocio__c,
                               StatusSAP__c,
                               Status__c,
                               QuantidadeDisponivelSAP__c,
                               DataEntrega__c,
                               QuantidadeProgramada__c,
                               PrecoVendaJuros__c,
                               TaxaDolar__c,
                               Produto__c,
                               ValorTotal__c,
                               DescontoConcedido__c,
                               IdOrderItem__c,
                               PrecoVendasJurosUSD__c,
                               CriterioApuracao__c,
                               Apuracao__c
                        FROM ProgramacaoEntrega__c 
                        WHERE Id IN :itemIdToProgramacaoEntregaIdMap.values()
                        OR Id IN : deleteDeliverySet
                    ]);
                }
                Map<Id, ProgramacaoEntrega__c> deleteDeliveryMap = new Map<Id, ProgramacaoEntrega__c>();
                for (Id id : programacoesEntrega.keySet()) {
                    if(programacaoEntregaIdToItemIdMap.containsKey(id)){
                        ProgramacaoEntrega__c programacaoEntrega = programacoesEntrega.get(id);
                        OrderItem ordItem = orderItems.get(programacaoEntregaIdToItemIdMap.get(id));
                        if(programacaoEntrega.Status__c != 'Solicitação alteração data de entrega' && programacaoEntrega.Status__c != 'Solicitado Cancelamento')
                            programacaoEntrega.Status__c                  = (ordItem.MotivoRecusaItem__c != 'ZS' ? 'Integrado' : 'Cancelado');
                        programacaoEntrega.StatusSAP__c               = ordItem.StatusSAP__c == 'Bloqueio de Remessa' ? 'Bloqueio de Remessa' : (ordItem.StatusSAP__c == 'Produto Indisponível' ? 'Produto Indisponível' : (ordItem.MotivoRecusaItem__c != 'ZS' ? 'Confirmado' : 'Cancelado'));
                        programacaoEntrega.QuantidadeProgramada__c    = ordItem.QuantidadeTotal__C;
                        programacaoEntrega.QuantidadeDisponivelSAP__c = ordItem.QuantidadeConfirmada__c;
                        programacaoEntrega.DataEntrega__c             = ordItem.DataEntrega__c;
                        programacaoEntrega.IdOrderItem__c             = ordItem.Id;
                        programacaoEntrega.LocalNegocio__c             = ordItem.LocalNegocio__c;
                        programacaoEntrega.PrazoItinerario__c             = ordItem.PrazoItinerario__c;
                        programacaoEntrega.DataFaturamento__c         = ordItem.DataFaturamento__c;
                        programacaoEntrega.PrecoLista__c             = ordItem.PrecoLista__c;
                        programacaoEntrega.TipoOrdem__c             = ordItem.Order.TipoOrdem__c;

                        if(programacaoEntrega.DataIntegracao__c == null){
                            programacaoEntrega.DataIntegracao__c = Date.today();
                        }

                        if(programacaoEntrega.DescontoConcedido__c == null){
                            programacaoEntrega.DescontoConcedido__c = ordItem.DescontoConcedido__c;
                        }

                        if(programacaoEntrega.TaxaDolar__c == null)
                            programacaoEntrega.TaxaDolar__c = isOrderNew ? taxamedia : ordItem.Order.TaxaMedia__c;

                        programacaoEntrega.PrecoVendaJuros__c         = ordItem.Moeda__c == 'BRL' ? ordItem.ValorUnitarioComJuros__c : ordItem.ValorUnitarioComJuros__c*programacaoEntrega.TaxaDolar__c;
                        programacaoEntrega.PrecoVendasJurosUSD__c     = ordItem.Moeda__c == 'BRL' ? ordItem.ValorUnitarioComJuros__c/programacaoEntrega.TaxaDolar__c : ordItem.ValorUnitarioComJuros__c;

                        programacaoEntrega.EmissorOrdem__c = orditem.Order.ClienteEmissor__c;
                    }else if(deleteDeliverySet.contains(id)){
                        deleteDeliveryMap.put(id, new ProgramacaoEntrega__c(Id = id));
                    }                    
                }
                if (!programacoesEntrega.values().isEmpty()) {
                    ProgramacaoEntregaHelper.disableTrigger();
                    updateTotalPrice(programacoesEntrega.values(), mapIdToProduct, Taxamedia);
                    System.debug('FINAL programacoesEntrega => ' + JSON.serializePretty(programacoesEntrega));
                    update programacoesEntrega.values();
                    ProgramacaoEntregaHelper.updateApuracaoRelation(programacoesEntrega);
                    ProgramacaoEntregaHelper.enableTrigger();
                }
                ProgramacaoEntregaHelper.disableTrigger();
                if(!deleteDeliveryMap.isEmpty()){
                    delete deleteDeliveryMap.values();
                }
                if(!deleteItemMap.isEmpty()){
                    delete deleteItemMap.values();
                }
                ProgramacaoEntregaHelper.enableTrigger();

            }

        } else {
            hasErrorOrder = true;
            Response response = new Response();
            response.error(
                request.sapId,
                'Não há itens no Pedido',
                String.valueOf(orderListToUpsert.getSObjectType())
            );
            responseMap.put(request.sapId, response);
        }

        IntegrationUtils.WSLog('Pedido', 'Inbound', serializedRequest, JSON.serializePretty(responseMap.values()[0]), hasErrorOrder, IntegrationUtils.serializeToObjectList(responseMap.values()));

        // System.debug(Limits.getQueries());
        return new ResponseModel(responseMap.values()[0]);

    }
    public static void updateTotalPrice(List<ProgramacaoEntrega__c> contextList, Map<Id, Product2> mapIdToProduct, Decimal Taxamedia){
        for(ProgramacaoEntrega__c delivery : contextList){
            // System.debug(delivery.QuantidadeProgramada__c);
            // System.debug(delivery.PrecoVendaJuros__c);
            // System.debug(delivery.ValorTotal__c);
            // System.debug(delivery.TaxaDolar__c);
            // System.debug(mapIdToProduct.containsKey(delivery.Produto__c));
            if(delivery.PrecoVendaJuros__c != null)
                delivery.ValorTotal__c = delivery.QuantidadeProgramada__c * delivery.PrecoVendaJuros__c;
            if(delivery.PrecoVendasJurosUSD__c != null)
                delivery.ValorTotalUSD__c = delivery.QuantidadeProgramada__c * delivery.PrecoVendasJurosUSD__c;

            if(mapIdToProduct.containsKey(delivery.Produto__c))
                delivery.Litros__c = (mapIdToProduct.get(delivery.Produto__c).Litragem__c * delivery.QuantidadeProgramada__c);
        }
    }
    public static void setStatusSAP(OrderItem ordItem, Order currentOrd){
                // System.debug(ordItem.StatusGlobalItem__c);
                // System.debug(currentOrd.BloqueioRemessa__c);
                // System.debug(ordItem.MotivoRecusaItem__c);
                // System.debug(ordItem.numeroRemessa__c);
        if(ordItem.StatusGlobalItem__c != 'B' && ordItem.StatusGlobalItem__c != 'C'){
            //Status Bloqueio Remessa
            if(!String.isBlank(currentOrd.BloqueioRemessa__c)){
                if(ordItem.SaldoFornecer__c != 0){
                    ordItem.StatusSAP__c = 'Bloqueio de Remessa';
                }else if(!String.isBlank(ordItem.numeroRemessa__c)){
                    ordItem.StatusSAP__c = 'Em Remessa';
                }else{
                    ordItem.StatusSAP__c = 'Bloqueio de Remessa';
                }
            } else if(!String.isBlank(ordItem.MotivoRecusaItem__c)){
                if(ordItem.SaldoFornecer__c != 0){
                    ordItem.StatusSAP__c = 'Cancelado';
                }
            } else if(!String.isBlank(ordItem.numeroRemessa__c)){
                ordItem.StatusSAP__c = 'Em Remessa';
            } else if (ordItem.QuantidadeConfirmada__c != null){
                if (ordItem.QuantidadeConfirmada__c == 0){
                    ordItem.StatusSAP__c = 'Produto Indisponível';
                }else if (ordItem.QuantidadeConfirmada__c == ordITem.Quantity){
                    ordItem.StatusSAP__c = 'Confirmado';
                }else if (ordItem.QuantidadeConfirmada__c < ordITem.Quantity){
                    ordItem.StatusSAP__c = 'Confirmado Parcial';
                }
            }else if(!String.isBlank(currentOrd.BloqueioRemessa__c)){
                ordItem.StatusSAP__c = 'Bloqueio de Remessa';
            }
        }else{
            ordItem.StatusSAP__c = (ordItem.StatusGlobalItem__c == 'B' ?  'Faturado Parcial' : (ordItem.StatusGlobalItem__c == 'C' ? 'Faturado' : ordITem.StatusSAP__C));
        }
    }

    global class ResponseModel {

        Response response;

        public ResponseModel(Response response) {

            this.response = response;
            
        }
    }

    global class Response extends TemplateDataIntegrationFields.Response {

        public TemplateDataIntegrationFields.Response[] itemResponse;

    }
}