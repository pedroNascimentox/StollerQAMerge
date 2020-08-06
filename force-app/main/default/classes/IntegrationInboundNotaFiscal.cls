@RestResource(urlMapping = '/notaFiscalService/*')
global with sharing class IntegrationInboundNotaFiscal {
    @HttpPost
    global static ResponseModel parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            TemplateDataIntegrationFields.NotaFiscalINData request = (TemplateDataIntegrationFields.NotaFiscalINData)JSON.deserialize(JSON.serialize(rawRequest.get('request')), TemplateDataIntegrationFields.NotaFiscalINData.class);

            return upsertNota(request);

        } catch (Exception e) {

            Database.rollback(sp);

            String errorMessage = 'MESSAGE: ' + e.getMessage() + ' \n STACK TRACE: ' + e.getStackTraceString();

            ResponseModel response = new ResponseModel((Response)(new Response()).error(errorMessage));

            IntegrationUtils.WSLog('Nota Fiscal', 'Inbound', serializedRequest, JSON.serializePretty(response), true);
            
            return response;
            
        }
    }

    global static ResponseModel upsertNota(TemplateDataIntegrationFields.NotaFiscalINData request) {

        Map<String, List<TemplateDataIntegrationFields.NotaFiscalItemINData>> NotaFiscalItemMapToUpsert = new Map<String, List<TemplateDataIntegrationFields.NotaFiscalItemINData>>();

        Map<String, Response> responseMap = new Map<String, Response>();
        Map<String, Id> lookups = new Map<String, Id>();

        List<NotaFiscal__c> notaFiscalListToUpsert = new List<NotaFiscal__c>();
        List<NotaFiscalItem__c> notaFiscalItemListToUpsert = new List<NotaFiscalItem__c>();

        Boolean hasErrorNotaFiscal = false;
        
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        if (request.items != null && request.items.size() != 0) {
            
            Decimal taxaMedia = 1;
            
            //NF
            List<String> codigoClienteSet = new List<String>();
            List<String> codigoOrdemSet = new List<String>();
            List<String> itinerarioSet = new List<String>();
            List<String> regionalSet = new List<String>();
            List<String> codigoAgenciadorSet = new List<String>();
            List<String> territorioSet = new List<String>();
            List<String> vendedorRTVSet = new List<String>();
            List<String> oportunidadeSet = new List<String>();

            //Item NF
            List<String> itemLookupNotaFiscalSet = new List<String>();
            List<String> itemLookupCodigoMaterialSet = new List<String>();
            List<String> itemLookupCulturaSet = new List<String>();
        
            Savepoint sp = Database.setSavepoint();

            Map<String, TemplateDataIntegrationFields.Response> responseChildrenMap = new Map<String, TemplateDataIntegrationFields.Response>();

            codigoClienteSet.add(request.codigoCliente);
            codigoOrdemSet.add(request.codigoOrdem);
            regionalSet.add(request.regional);
            oportunidadeSet.add(request.sfIdOpp);
            codigoAgenciadorSet.add(request.codigoAgenciador);
            territorioSet.add(request.territorio);
            vendedorRTVSet.add(request.vendedorRTV);
            if (request.items != null) {
                for(TemplateDataIntegrationFields.NotaFiscalItemINData item : request.items) {
                    itinerarioSet.add(item.itinerario);
                    itemLookupNotaFiscalSet.add(String.valueOf(item.nrNota));
                    itemLookupCodigoMaterialSet.add(item.CodigoMaterial);
                    itemLookupCulturaSet.add(item.Cultura);
                }
            }

            Map<Id, Decimal> prodToLitrosMap = new Map<Id, Decimal>();
            for(Product2 prod : [SELECT id, ExternalId__c, Litragem__c FROM Product2 WHERE ExternalId__c IN :itemLookupCodigoMaterialSet]){
                prodToLitrosMap.put(prod.id, prod.Litragem__c);
            }            

            FactoryDataIntegration.addLookup('Account',         'ExternalId__c',          'CodigoCliente__c',     codigoClienteSet,     lookups);
            FactoryDataIntegration.addLookup('Order',           'OVSAP__c',               'NrOrdem__c',           codigoOrdemSet,       lookups);
            FactoryDataIntegration.addLookup('Opportunity',     'Id',                     'Oportunidade__c',      oportunidadeSet,      lookups);
            FactoryDataIntegration.addLookup('Regional__c',     'ExternalId__c',          'Regional__c',          regionalSet,          lookups);
            FactoryDataIntegration.addLookup('Account',         'ExternalId__c',          'CodigoAgenciador__c',  codigoAgenciadorSet,  lookups);
            // FactoryDataIntegration.addLookup('Territorio__c',   'ExternalId__c',          'Territorio__c',        territorioSet,        lookups);

            for (Territorio__c territorio : [SELECT Id, ExternalId__c, OwnerId FROM Territorio__c WHERE ExternalId__c IN :territorioSet]) {
                lookups.put('Territorio__c' + territorio.ExternalId__c, territorio.Id);
                lookups.put('OwnerId' + territorio.ExternalId__c, territorio.OwnerId);
            }

            FactoryDataIntegration.addLookup('User',            'BusinessPartnerSAP__c',  'VendedorRTV__c',       vendedorRTVSet,       lookups);

            //Item NF
            FactoryDataIntegration.addLookup('Itinerario__c', 'ExternalId__c', 'Itinerario__c', itinerarioSet, lookups);
            //FactoryDataIntegration.addLookup('Notafiscal__c', 'NrNF__c', 'NotaFiscal__c', itemLookupNotaFiscalSet, lookups);
            FactoryDataIntegration.addLookup('Product2', 'ExternalId__c', 'CodigoMaterial__c', itemLookupCodigoMaterialSet, lookups);
            FactoryDataIntegration.addLookup('Cultura__c', 'ExternalId__c', 'Cultura__c', itemLookupCulturaSet, lookups);

            Response response = new Response();

            NotaFiscal__c notaObj = request.serialize(lookups);
            String stringFieldId = String.valueOf(notaObj.get(request.getFieldId()));
            String stringFieldKey = String.valueOf(notaObj.get(request.getFieldKey()));

            for (String field : request.getRequiredFields(request)) {
                if (IntegrationUtils.convertEmptyString(String.valueOf(notaObj.get(field)))){
                    hasErrorNotaFiscal = true;
                    if (responseMap.containsKey(stringFieldKey)) {
                        responseMap.get(stringFieldKey).error(
                            stringFieldKey,
                            ' | Valor inválido para o campo obrigatório: ' + field,
                            String.valueOf(notaFiscalListToUpsert.getSObjectType())
                        );
                    } else {
                        if (String.isNotEmpty(stringFieldId)){
                            response.error(
                                stringFieldId,
                                stringFieldKey,
                                'Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(notaFiscalListToUpsert.getSObjectType())
                            );
                        } else {
                            response.error(
                                stringFieldKey,
                                'Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(notaFiscalListToUpsert.getSObjectType())
                            );
                        }
                        responseMap.put(stringFieldKey, response);
                    }
                }
            }

            for (TemplateDataIntegrationFields.NotaFiscalItemINData notaFiscalItemINData : request.items) {

                // notaFiscalItemINData.NotaFiscal__cId = request.sapId;
            
                TemplateDataIntegrationFields.Response responseChild = new TemplateDataIntegrationFields.Response();
                
                // notaFiscalItemINData.setStatusSAP(notaObj);

                NotaFiscalItem__c notaFiscalItemObj = notaFiscalItemINData.serialize(lookups);
                String stringFieldIdChild = String.valueOf(notaFiscalItemObj.get(notaFiscalItemINData.getFieldId()));
                String stringFieldKeyChild = notaFiscalItemINData.nrItem;
                
                Boolean hasErrorNotaFiscalItem = false;

                for (String field : notaFiscalItemINData.getRequiredFields(notaFiscalItemINData)) {
                    if (IntegrationUtils.convertEmptyString(String.valueOf(notaFiscalItemObj.get(field)))){
                        hasErrorNotaFiscalItem = true;
                        if (responseChildrenMap.containsKey(stringFieldKeyChild)) {
                            responseChildrenMap.get(stringFieldKeyChild).error(
                                null,
                                ' | Valor inválido para o campo obrigatório: ' + field,
                                String.valueOf(notaFiscalItemListToUpsert.getSObjectType())
                            );
                        } else {
                            if (String.isNotEmpty(stringFieldIdChild)){
                                responseChild.error(
                                    stringFieldIdChild,
                                    null,
                                    'Valor inválido para o campo obrigatório: ' + field,
                                    String.valueOf(notaFiscalItemListToUpsert.getSObjectType())
                                );
                            } else {
                                responseChild.error(
                                    null,
                                    'Valor inválido para o campo obrigatório: ' + field,
                                    String.valueOf(notaFiscalItemListToUpsert.getSObjectType())
                                );
                            }
                            responseChildrenMap.put(stringFieldKeyChild, responseChild);
                        }
                    }
                }
                if (!hasErrorNotaFiscalItem) {
                    notaFiscalItemListToUpsert.add(notaFiscalItemObj);
                }
            }

            if(!hasErrorNotaFiscal) {
                notaFiscalListToUpsert.add(notaObj);
            }

            List<Database.UpsertResult> notaResults = Database.upsert(notaFiscalListToUpsert, NotaFiscal__c.codigoExterno__c, false);
            
            Boolean hasErrorOnNotaFiscal = IntegrationUtils.upsertRecords(notaResults, responseMap, notaFiscalListToUpsert, NotaFiscal__c.codigoExterno__c);
            Boolean hasErrorOnNotaFiscalItem = false;

            List<Database.UpsertResult> insResults = new List<Database.UpsertResult>();
            List<Database.UpsertResult> upsResults = new List<Database.UpsertResult>();

            List<NotaFiscalItem__c> notaFiscalItemList = new List<NotaFiscalItem__c>();
            if (!hasErrorOnNotaFiscal) {
                List<NotaFiscalItem__c> notaFiscalItemListToInsert = new List<NotaFiscalItem__c>();
                List<NotaFiscalItem__c> notaFiscalItemListToUpdate = new List<NotaFiscalItem__c>();
                NotaFiscal__c nota = notaFiscalListToUpsert[0];
                String tipoNota = [SELECT Id, TipoFat__c FROM NotaFiscal__c WHERE Id = : nota.Id].TipoFat__c;
                for(CotacaoMoeda__c cotacoesMoeda : [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :notaFiscalListToUpsert[0].dataNF__c ORDER BY Data__c DESC LIMIT 1]){
                    taxaMedia = cotacoesMoeda.TaxaMedia__c;
                }
                System.debug(tipoNota);
                for (Integer i = notaFiscalItemListToUpsert.size() - 1; i > -1; i--) {
                    NotaFiscalItem__c notaFiscalItem = notaFiscalItemListToUpsert[i];
                    NotaFiscalItem__c notaFiscalItemNew = new NotaFiscalItem__c(
                        NotaFiscal__c         = nota.Id,
                        NrItemOrdemNossonr__c = nota.codigoExterno__c+'-'+notaFiscalItem.NrItemOrdemNossonr__c,
                        DescontoConcedido__c  = notaFiscalItem.DescontoConcedido__c,
                        Familia__c            = notaFiscalItem.Familia__c,
                        DescricaoMaterial__c  = notaFiscalItem.DescricaoMaterial__c,
                        UnidadeMedida__c      = notaFiscalItem.UnidadeMedida__c,
                        SubFamilia__c         = notaFiscalItem.SubFamilia__c,
                        TipoMaterial__c       = notaFiscalItem.TipoMaterial__c,
                        ValorUnitarioItem__c  = notaFiscalItem.ValorUnitarioItem__c,
                        ValorTotalItem__c     = notaFiscalItem.ValorTotalItem__c,
                        Valor_Lista_Z001__c   = notaFiscalItem.Valor_Lista_Z001__c,
                        DescontoCanal__c      = notaFiscalItem.DescontoCanal__c,
                        FreteAcrescimo__c     = notaFiscalItem.FreteAcrescimo__c,
                        DescontoPolitica__c   = notaFiscalItem.DescontoPolitica__c,
                        jurosAcrescimo__c     = notaFiscalItem.jurosAcrescimo__c,
                        itinerario__c         = notaFiscalItem.itinerario__c,
                        CodigoMaterial__c     = notaFiscalItem.CodigoMaterial__c,
                        Cultura__c            = notaFiscalItem.Cultura__c,
                        NrItemNF__c           = notaFiscalItem.NrItemNF__c,
                        ValorIPI__c           = notaFiscalItem.ValorIPI__c
                    );

                    TipoNotaFiscalCS__c customTipoNota = TipoNotaFiscalCS__c.getOrgDefaults();

                    if (customTipoNota.Tipo__c.contains(tipoNota)){
                        notaFiscalItemNew.ValorTotalUSD__c      = (-1) * (notaFiscalItem.ValorTotalItem__c / taxamedia);
                        notaFiscalItemNew.ValorTotalItem__c     = (-1) * notaFiscalItem.ValorTotalItem__c;
                        notaFiscalItemNew.Litros__c             = (-1) * (notaFiscalItem.QuantidadeNota__c * prodToLitrosMap.get(notaFiscalItem.CodigoMaterial__c));
                        notaFiscalItemNew.valorTotalLiquido__c  = (-1) * notaFiscalItem.ValorTotalLiquido__c;
                        notaFiscalItemNew.ValorTotalComJuros__c = (-1) * notaFiscalItem.ValorTotalComJuros__c;
                        notaFiscalItemNew.QuantidadeNota__c     = (-1) * notaFiscalItem.QuantidadeNota__c;
                        notaFiscalItemNew.ValorUnitarioItem__c  = (-1) * notaFiscalItem.ValorUnitarioItem__c;
                        notaFiscalItemNew.jurosAcrescimo__c     = (-1) * notaFiscalItem.jurosAcrescimo__c;
                    }else{
                        notaFiscalItemNew.ValorTotalUSD__c      = notaFiscalItem.ValorTotalItem__c / taxamedia;
                        notaFiscalItemNew.ValorTotalItem__c     = notaFiscalItem.ValorTotalItem__c;
                        notaFiscalItemNew.Litros__c             = (notaFiscalItem.QuantidadeNota__c * prodToLitrosMap.get(notaFiscalItem.CodigoMaterial__c));
                        notaFiscalItemNew.valorTotalLiquido__c  = notaFiscalItem.ValorTotalLiquido__c;
                        notaFiscalItemNew.ValorTotalComJuros__c = notaFiscalItem.ValorTotalComJuros__c;
                        notaFiscalItemNew.QuantidadeNota__c     = notaFiscalItem.QuantidadeNota__c;
                        notaFiscalItemNew.ValorUnitarioItem__c  = notaFiscalItem.ValorUnitarioItem__c;
                        notaFiscalItemNew.jurosAcrescimo__c     = notaFiscalItem.jurosAcrescimo__c;
                    }
                    
                    notaFiscalItemListToUpdate.add(notaFiscalItemNew);
                    
                    notaFiscalItemList.add(notaFiscalItemNew);
                }
                upsResults = Database.upsert(notaFiscalItemListToUpdate, NotaFiscalItem__c.NrItemOrdemNossonr__c, false);
                hasErrorOnNotaFiscalItem = IntegrationUtils.upsertRecords(upsResults, responseChildrenMap, notaFiscalItemListToUpsert, NotaFiscalItem__c.NrItemOrdemNossonr__c);
            }
            
            for (String key : responseMap.keySet()) {
                responseMap.get(key).itemResponse = new List<TemplateDataIntegrationFields.Response>(responseChildrenMap.values());
            }

            if (hasErrorOnNotaFiscal || hasErrorOnNotaFiscalItem) {
                // System.debug('HAS ERROR');
                hasErrorNotaFiscal = true;
                Database.rollback(sp);
            }else{
                //updateRelatedOrderItem(notaFiscalListToUpsert);
            }

        } else {
            hasErrorNotaFiscal = true;
            Response response = new Response();
            response.error(
                getRightExternalId(request.numeroNF, request.fatura),
                'Não há itens na Nota Fiscal',
                String.valueOf(notaFiscalListToUpsert.getSObjectType())
            );
            responseMap.put(getRightExternalId(request.numeroNF, request.fatura), response);
        }

        IntegrationUtils.WSLog('Nota Fiscal', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseMap.values()[0]), hasErrorNotaFiscal, IntegrationUtils.serializeToObjectList(responseMap.values()));

        // System.debug('responseMap.values() => ' + responseMap.values());

        return new ResponseModel(responseMap.values()[0]);

    }
    /*
    public static void updateRelatedOrderItem(List<NotaFiscal__c> notaFiscalListToUpsert){
        Map<Id, List<NotaFiscalItem__c>> notaToItemMap = new Map<Id, List<NotaFiscalItem__c>>();
        Map<Id, Map<String, Decimal>> orderIdToNotaItemMap = new Map<Id, Map<String, Decimal>>();

        for(NotaFiscalItem__c notaItem : [SELECT id, Notafiscal__c, Notafiscal__r.NrOrdem__c, NrItemOrdemNossonr__c FROM NotafiscalItem__c WHERE Notafiscal__c IN : Collection.of(notaFiscalListToUpsert).pluckIds()]){
            if(!orderIdToNotaItemMap.containsKey(notaItem.Notafiscal__r.NrOrdem__c)){
                orderIdToNotaItemMap.put(notaItem.Notafiscal__r.NrOrdem__c, new Map<String, Decimal>());
            }

            Decimal newValue = 0;
            if(!orderIdToNotaItemMap.get(notaItem.Notafiscal__r.NrOrdem__c).containsKey(notaItem.NrItemOrdemNossonr__c)){
                newValue = notaItem.QuantidadeNota__c;
            }else{
                newValue = orderIdToNotaItemMap.get(notaItem.Notafiscal__r.NrOrdem__c).get(notaItem.NrItemOrdemNossonr__c) + notaItem.QuantidadeNota__c;
            }
            orderIdToNotaItemMap.get(notaItem.Notafiscal__r.NrOrdem__c).put(notaItem.NrItemOrdemNossonr__c, newValue);
        }
        List<OrderItem> ordItemList = new List<OrderItem>();
        for(OrderItem ordItem : [SELECT id, LinhaDivisaoRemessa__c, NrItem__c, QuantidadeConfirmada__c, OrderId 
                                 FROM OrderItem 
                                 WHERE OrderId IN : Collection.of(notaFiscalListToUpsert).pluckIds(NotaFiscal__c.NrOrdem__c)]){
            if(orderIdToNotaItemMap.containsKey(ordItem.OrderId)){
                if(orderIdToNotaItemMap.get(ordItem.OrderId).containsKey(ordItem.NrItem__c)){
                    Decimal nfITemQtd = orderIdToNotaItemMap.get(ordItem.OrderId).get(ordItem.NrItem__c);
                    if(ordItem.QuantidadeConfirmada__c < nfITemQtd){
                        ordItem.Status__c = 'Faturado Parcial';
                    }else if (ordItem.QuantidadeConfirmada__c == nfITemQtd){
                        ordItem.Status__c = 'Faturado Total';
                    }
                    ordItemList.add(ordItem);
                }                
            }
        }
        OrderItemHelper.disableTrigger();
        OrderHelper.disableTrigger();
        if(!ordItemList.isEmpty()){
            update ordItemList;
        }
        OrderHelper.enableTrigger();
        OrderItemHelper.enableTrigger();
    }
    */
    public static String getRightExternalId(Decimal numeroNF, String fatura) {

        return String.isBlank(String.valueOf(numeroNF)) ? fatura : String.valueOf(numeroNF);

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