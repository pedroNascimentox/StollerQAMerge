@RestResource(urlMapping = '/productService/*')
global with sharing class IntegrationInboundProduct2 {
    @HttpPost
    global static TemplateDataIntegrationFields.ResponseList parseRequest() {

        Savepoint sp = Database.setSavepoint();

        String serializedRequest = RestContext.request.requestBody.toString();

        try {

            Map<String, Object> rawRequest = (Map<String, Object>)JSON.deserializeUntyped(serializedRequest);

            List<TemplateDataIntegrationFields.Product2INData> request = (List<TemplateDataIntegrationFields.Product2INData>)JSON.deserialize(JSON.serialize(rawRequest.get('request')), List<TemplateDataIntegrationFields.Product2INData>.class);

            return upsertProduct2(request);

        } catch (Exception e) {

            Database.rollback(sp);

            TemplateDataIntegrationFields.ResponseList responseList = IntegrationUtils.getStandardException(e);

            IntegrationUtils.WSLog('Produto', 'Inbound', serializedRequest, JSON.serializePretty(responseList), true);
            
            return responseList;
            
        }
    }

    global static TemplateDataIntegrationFields.ResponseList upsertProduct2(List<TemplateDataIntegrationFields.Product2INData> request) {

        Map<String, Id> lookups = new Map<String, Id>();

        List<String> productLookups = new List<String>();

        Map<String, TemplateDataIntegrationFields.Response> responseMap = new Map<String, TemplateDataIntegrationFields.Response>();
        List<Product2> productListToUpsert = new List<Product2>();

        Map<String, List<String>> produtoExternalIdToCulturaExternalIdsMap = new Map<String, List<String>>();
        Set<String> externalIdsToVerify = new Set<String>();

        Map<String, TemplateDataIntegrationFields.Product2INData> requestMap = new Map<String, TemplateDataIntegrationFields.Product2INData>();
        Set<String> atributoRestricaoListName = new Set<String>();
        for (TemplateDataIntegrationFields.Product2INData product2INData : request) {
            requestMap.put(product2INData.externalId, product2INData);

            /*if (product2INData.atributoRestricao != null) {
                for (String att : product2INData.atributoRestricao) {
                    atributoRestricaoListName.add(att);
                }
            }*/

            
            productLookups.add(product2INData.produtoSubstituto);

            // if (product2INData.culturaIds.size() != 0) {
            //     for (String externalId : product2INData.culturaIds) {
            //         if (produtoExternalIdToCulturaExternalIdsMap.containsKey(product2INData.externalId)) {
            //             produtoExternalIdToCulturaExternalIdsMap.get(product2INData.externalId).add(externalId);
            //         } else {
            //             produtoExternalIdToCulturaExternalIdsMap.put(product2INData.externalId, new List<String>{externalId});
            //         }
            //         externalIdsToVerify.add(externalId);
            //     }
            // } else {
            //     TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
            //     response.error(product2INData.externalId, 
            //         'A lista de External Ids de Culturas está vazia', 
            //         'Account');
            //     responseMap.put(product2INData.externalId, response);
            // }
        }
        
        FactoryDataIntegration.addLookup('Product2', 'ExternalId__c', 'Product2', productLookups, lookups);
        
        // List<Cultura__c> culturaList = [SELECT Id, ExternalId__c 
        //                                   FROM Cultura__c 
        //                                  WHERE ExternalId__c IN :externalIdsToVerify];

        // Map<String, Id> culturaExternalIdToIdMap = new Map<String, Id>();
        // for (Cultura__c cultura : culturaList) {
        //     culturaExternalIdToIdMap.put(cultura.ExternalId__c, cultura.Id);
        // }

        // if (culturaList.size() != externalIdsToVerify.size()) {

        //     verifyCulturas(culturaList, productListToUpsert, responseMap, request, lookups);

        // }
        
        FactoryDataIntegration.convertSObject(new Product2(), 'IN', request, responseMap, productListToUpsert, lookups);

        List<Database.UpsertResult> upsResults = Database.upsert(productListToUpsert, Product2.ExternalId__c, false);

        Boolean hasError = IntegrationUtils.upsertRecords(upsResults, responseMap, productListToUpsert, Product2.ExternalId__c);
        
        IntegrationUtils.WSLog('Produto', 'Inbound', JSON.serializePretty(request), JSON.serializePretty(responseMap.values()), hasError, IntegrationUtils.serializeToObjectList(responseMap.values()));

        // List<Product2> successfulProducts = insertProdutoAtributo(productListToUpsert, upsResults, requestMap, atributoRestricaoListName);

        // if (successfulProducts.size() > 0) {
        //     insertRelation(successfulProducts, produtoExternalIdToCulturaExternalIdsMap, culturaExternalIdToIdMap);
        // }
        
        return new TemplateDataIntegrationFields.ResponseList(responseMap.values());

    }

    /*private static List<Product2> insertProdutoAtributo(List<Product2> productListToUpsert, List<Database.UpsertResult> upsResults, Map<String, TemplateDataIntegrationFields.Product2INData> requestMap, Set<String> atributoRestricaoListName) {
        
        List<AtributoDefensivos__c> atributoRestricaoList = new List<AtributoDefensivos__c>();
        for (String att : atributoRestricaoListName) {
            atributoRestricaoList.add(new AtributoDefensivos__c(Atributo__c = att));
        }

        Database.upsert(atributoRestricaoList, AtributoDefensivos__c.Atributo__c, false);

        Map<String, Id> atributoRestricaoMap = new Map<String, Id>();
        List<AtributoDefensivos__c> localAtributosRestricao = [SELECT Id, Atributo__c FROM AtributoDefensivos__c WHERE Atributo__c IN :atributoRestricaoListName];
        for (AtributoDefensivos__c att : localAtributosRestricao) {
            atributoRestricaoMap.put(att.Atributo__c, att.Id);
        }

        List<ProdutoAtributo__c> produtoAtributoList = new List<ProdutoAtributo__c>();
        List<Id> produtoAtributoIdList = new List<Id>();
        List<Product2> successfulProducts = new List<Product2>();
        for (Integer i = 0; i < productListToUpsert.size(); i++) {
            if (upsResults[i].isSuccess()) {
                successfulProducts.add(productListToUpsert[i]);
                
                produtoAtributoIdList.add(productListToUpsert[i].Id);
                if (requestMap.get(productListToUpsert[i].ExternalId__c).atributoRestricao != null) {
                    for (String atributoRestricao : requestMap.get(productListToUpsert[i].ExternalId__c).atributoRestricao) {
                        ProdutoAtributo__c produtoAtributo = new ProdutoAtributo__c(
                            Produto__c = productListToUpsert[i].Id, 
                            AtributoDefensivos__c = atributoRestricaoMap.get(atributoRestricao)
                        );
                        produtoAtributoList.add(produtoAtributo);
                    }
                }
            }
        }

        List<ProdutoAtributo__c> produtoAtributoToDelete = [SELECT Id FROM ProdutoAtributo__c WHERE Produto__c IN :produtoAtributoIdList];
        delete produtoAtributoToDelete;
        
        Database.insert(produtoAtributoList, false);

        return successfulProducts;
    }*/
    
    /*private static void insertRelation(List<Product2> successfulProducts, Map<String, List<String>> produtoExternalIdToCulturaExternalIdsMap, Map<String, Id> culturaExternalIdToIdMap) {

        Map<String, List<String>> produtoIdToCulturaIdsMap = new Map<String, List<String>>();
        for (Product2 product : successfulProducts) {
            if (produtoExternalIdToCulturaExternalIdsMap.containsKey(product.ExternalId__c)) {
                for (String externalId : produtoExternalIdToCulturaExternalIdsMap.get(product.ExternalId__c)) {
                    if (produtoIdToCulturaIdsMap.containsKey(product.Id)) {
                        produtoIdToCulturaIdsMap.get(product.Id).add(culturaExternalIdToIdMap.get(externalId));
                    } else {
                        produtoIdToCulturaIdsMap.put(product.Id, new List<String>{culturaExternalIdToIdMap.get(externalId)});
                    }
                }
            }
        }

        List<CulturaProduto__c> culturaProdutoList = new List<CulturaProduto__c>();
        for (String key : produtoIdToCulturaIdsMap.keySet()) {
            for (String culturaId : produtoIdToCulturaIdsMap.get(key)) {
                culturaProdutoList.add(new CulturaProduto__c(
                    Cultura__c = culturaId,
                    Produto__c = key
                ));
            }
        }

        replaceRelation(successfulProducts, culturaProdutoList);
    }*/

    /*private static void replaceRelation(List<Product2> productList, List<CulturaProduto__c> culturaProdutoList) {

        List<String> productIds = new List<String>();
        for (Product2 product : productList) {
            productIds.add(product.Id);
        }

       List<CulturaProduto__c> currentChildren = new List<CulturaProduto__c>([SELECT Id, Produto__c, Cultura__c FROM CulturaProduto__c WHERE Produto__c IN :productIds]);

        delete currentChildren;

        Database.insert(culturaProdutoList, false);

    }*/

    /*private static void verifyCulturas(List<Cultura__c> culturaList, List<Product2> productListToUpsert, Map<String, TemplateDataIntegrationFields.Response> responseMap, List<TemplateDataIntegrationFields.Product2INData> request, Map<String, Id> lookups) {

        Map<String, Id> localCulturas = new Map<String, Id>();
        for (Cultura__c cultura : culturaList) {
            localCulturas.put(cultura.ExternalId__c, cultura.Id);
        }

        Map<String, List<String>> errorMap = new Map<String, List<String>>();
        for (TemplateDataIntegrationFields.Product2INData data : request) {
            // for (String id : data.culturaIds) {
            //     if (!localCulturas.containsKey(id)) {
            //         if (errorMap.containsKey(data.externalId)){
            //             errorMap.get(data.externalId).add(id);
            //         } else {
            //             errorMap.put(data.externalId, new List<String>{id});
            //         }
            //     }
            // }
        }

        for (TemplateDataIntegrationFields.Product2INData data : request) {
            TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
            if (errorMap.containsKey(data.externalId)) {
                response.error(
                    data.externalId,
                    'Cultura External Id não encontrado: ' + String.join(errorMap.get(data.externalId), ', '),
                    'Product2'
                );
                responseMap.put(data.externalId, response);
            }
        }
    }*/
}