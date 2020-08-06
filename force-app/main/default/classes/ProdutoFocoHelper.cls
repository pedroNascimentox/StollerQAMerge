public class ProdutoFocoHelper extends TriggerContext {
    public static void checkBeforeInsert(ProdutoFoco__c[] produtoFocoList) {
        Set<Id> prodExistentes = new Set<Id>();        
        Set<Id> planoIncentivoSet = new Set<Id>();
        Set<String> familiaExistente = new Set<String>();
        Set<Id> prodExisteFamilia = new Set<Id>();
        Boolean registroBloqueado = false;

        Set<Id> prodFocoSet = new Set<Id>();
        Map<Id, ProdutoFoco__c> mapIdToPlanoIncentivo = new Map<Id, ProdutoFoco__c>();

        for (ProdutoFoco__c prod : produtoFocoList){
            mapIdToPlanoIncentivo.put(prod.PlanoIncentivo__c, prod);
            prodFocoSet.add(prod.ProdutoFoco__c);
        }

        // system.debug(mapIdToPlanoIncentivo);
        // system.debug(prodFocoSet);

        for (ProdutoFoco__c prod : [SELECT id, ProdutoFoco__c, PlanoIncentivo__c, FamiliaProdutos__c, PlanoIncentivo__r.Status__c  FROM ProdutoFoco__c WHERE PlanoIncentivo__c IN: mapIdToPlanoIncentivo.keySet()]){
            // system.debug(prod);
            if (mapIdToPlanoIncentivo.containsKey(prod.PlanoIncentivo__c)){
                if (prod.PlanoIncentivo__r.Status__c == 'Em apuração' || prod.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(prod.PlanoIncentivo__c);
                }
                if (prod.ProdutoFoco__c != null){
                    if (prod.ProdutoFoco__c == mapIdToPlanoIncentivo.get(prod.PlanoIncentivo__c).ProdutoFoco__c){
                        prodExistentes.add(prod.ProdutoFoco__c);
                    }
                }else if (prod.FamiliaProdutos__c != null){
                    if (prod.FamiliaProdutos__c == mapIdToPlanoIncentivo.get(prod.PlanoIncentivo__c).FamiliaProdutos__c){
                        familiaExistente.add(prod.FamiliaProdutos__c);
                    }
                }
            }
        }

        for (ProdutoFoco__c prod : produtoFocoList){
            if (prod.FamiliaProdutos__c == null && prod.ProdutoFoco__c == null) {
                prod.addError('O Produto Foco deve ter um valor no campo "Produto foco" ou "Familia de Produtos".');
            } else if (registroBloqueado && planoIncentivoSet.contains(prod.PlanoIncentivo__c)){
                prod.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');     
            } else if (prodExistentes.contains(prod.ProdutoFoco__c)){
                prod.addError('Produto já existente no Plano de Incentivo');           
            } else if (familiaExistente.contains(prod.FamiliaProdutos__c)) {                
                prod.addError('Familia de produto já existente no Plano de Incentivo');
            } 
        }        
    }

    public static void checkBeforeDelete(ProdutoFoco__c[] produtoFocoList){
        Boolean registroBloqueado = false;        
        Set<Id> planoIncentivoSet = new Set<Id>();
        Map<Id, ProdutoFoco__c> mapIdToPlanoIncentivo = new Map<Id, ProdutoFoco__c>();

        for (ProdutoFoco__c prod : produtoFocoList){
            mapIdToPlanoIncentivo.put(prod.PlanoIncentivo__c, prod);
        }

        for (ProdutoFoco__c prod : [SELECT id, ProdutoFoco__c, PlanoIncentivo__c, FamiliaProdutos__c, PlanoIncentivo__r.Status__c FROM ProdutoFoco__c WHERE PlanoIncentivo__c IN: mapIdToPlanoIncentivo.keySet()]){
            if (mapIdToPlanoIncentivo.containsKey(prod.PlanoIncentivo__c)){
                if (prod.PlanoIncentivo__r.Status__c == 'Em apuração' || prod.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(prod.PlanoIncentivo__c);
                }
            }
        }

        for (ProdutoFoco__c prod : produtoFocoList){
            if (registroBloqueado && planoIncentivoSet.contains(prod.PlanoIncentivo__c)){
                prod.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');
            }
        }
    }

    public static void checkProdFamilyBeforeInsert(ProdutoFoco__c[] produtoFocoList){
        Boolean produtoExistente = false;
        Set<String> familiaProdSet = new Set<String>();
        Set<Id> prodFocoSetId = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();

        for (ProdutoFoco__c prod : produtoFocoList){
            prodFocoSetId.add(prod.ProdutoFoco__c);
            planoIncentivoSet.add(prod.PlanoIncentivo__c);
        }     

        for (Product2 prod : [SELECT Id, Family FROM Product2 WHERE Id IN: prodFocoSetId]){
            familiaProdSet.add(prod.Family);
        }

        for (ProdutoFoco__c prod : [SELECT id, ProdutoFoco__c, PlanoIncentivo__c, FamiliaProdutos__c  FROM ProdutoFoco__c WHERE PlanoIncentivo__c IN: planoIncentivoSet]){
            if (prod.FamiliaProdutos__c != null){
                if (familiaProdSet.contains(prod.FamiliaProdutos__c)){         
                    produtoExistente = true;
                }
            }
        }
       
        for (ProdutoFoco__c prod : produtoFocoList){
            if (produtoExistente) {
                prod.addError('Produto já existe no Plano de Incentivo a partir de sua família.');
            }
        }    
        
    }
    public static void insertFamillyProducts(ProdutoFoco__c[] newContextList){
        List<ProdutosFamilia__c> prodFamiliaList = new List<ProdutosFamilia__c>();

        Map<String, List<Product2>> mapFamToProd = new Map<String, List<Product2>>();        
        Map<String, ProdutoFoco__c> mapFamToProdFoco = new Map<String, ProdutoFoco__c>();

        for (ProdutoFoco__c prodFoco : newContextList){   
            if (prodFoco.FamiliaProdutos__c != null) {    
                mapFamToProdFoco.put(prodFoco.FamiliaProdutos__c, prodFoco);
            }
        }

        for (Product2 prod : [SELECT Id, Name, family FROM Product2 WHERE family IN: mapFamToProdFoco.keySet()]){
            if (!mapFamToProd.containsKey(prod.family)){
                mapFamToProd.put(prod.family, new List<Product2> {prod});
            }else{
                mapFamToProd.get(prod.family).add(prod);
            }
        }

        for (String family: mapFamToProd.keySet()){
            for (Product2 prod : mapFamToProd.get(family)){
                ProdutosFamilia__c prodFam = new ProdutosFamilia__c();
                prodFam.Produto__c = prod.Id;
                prodFam.Relativo__c = mapFamToProdFoco.get(family).Id;

                prodFamiliaList.add(prodFam);
            }
        }

        if (!prodFamiliaList.isEmpty()){
            insert prodFamiliaList;
        }
    }

    public static void updateFamillyProducts(Map<Id, ProdutoFoco__c> oldContextMap, Map<Id, ProdutoFoco__c> newContextMap){
        List<ProdutosFamilia__c> prodFamiliaListToInsert = new List<ProdutosFamilia__c>();
        List<ProdutosFamilia__c> prodFamiliaListToDelete = new List<ProdutosFamilia__c>();

        Map<String, List<Product2>> mapFamToProdNew = new Map<String, List<Product2>>();    
        Map<String, List<Product2>> mapFamToProdOld = new Map<String, List<Product2>>();    

        Map<String, ProdutoFoco__c> mapFamToProdFocoNew = new Map<String, ProdutoFoco__c>();
        Map<String, ProdutoFoco__c> mapFamToProdFocoOld = new Map<String, ProdutoFoco__c>();

        Set<Id> oldProducts = new Set<Id>();

        Map<Id, Product2> mapIdToProduct2 = new Map<Id, Product2>();

        Boolean hasToDelete = false;

        for (Id Id: oldContextMap.keySet()){

            ProdutoFoco__c newProdutoFoco = newContextMap.get(Id);
            ProdutoFoco__c oldProdutoFoco = oldContextMap.get(Id);

            if (newProdutoFoco.FamiliaProdutos__c == null && newProdutoFoco.ProdutoFoco__c == null) {
                newProdutoFoco.addError('O Produto Foco deve ter um valor no campo "Produto foco" ou "Familia de Produtos".');
            } else if (oldProdutoFoco.FamiliaProdutos__c != newProdutoFoco.FamiliaProdutos__c){
                if (newProdutoFoco.FamiliaProdutos__c != null) {
                    mapFamToProdFocoNew.put(newProdutoFoco.FamiliaProdutos__c, newProdutoFoco);
                    mapFamToProdFocoOld.put(oldProdutoFoco.FamiliaProdutos__c, oldProdutoFoco);
                }
                hasToDelete = true;
            }        
        }
        // system.debug('mapFamToProdFocoNew: '+mapFamToProdFocoNew);
        // system.debug('mapFamToProdFocoOld: '+mapFamToProdFocoOld);

        for (Product2 prod : [SELECT Id, Name, family FROM Product2 WHERE family IN: mapFamToProdFocoNew.keySet() OR family IN: mapFamToProdFocoOld.keySet()]){
            if (mapFamToProdFocoNew.containsKey(prod.family)){
                if (prod.family != null){
                    if (!mapFamToProdNew.containsKey(prod.family)){
                        mapFamToProdNew.put(prod.family, new List<Product2> {prod});
                    }else{
                        mapFamToProdNew.get(prod.family).add(prod);
                    }
                }
            }else{
                if (prod.family != null){
                    if (!mapFamToProdOld.containsKey(prod.family)){
                        mapFamToProdOld.put(prod.family, new List<Product2> {prod});
                    }else{
                        mapFamToProdOld.get(prod.family).add(prod);
                    }
                }
            }
        }

        for (ProdutosFamilia__c prodFam : [SELECT Id, Produto__c, Relativo__c FROM ProdutosFamilia__c WHERE Relativo__c IN: oldContextMap.keySet()]){
            if (hasToDelete){
                prodFamiliaListToDelete.add(prodFam);
            }
        }

        for (String family: mapFamToProdNew.keySet()){
            for (Product2 prod : mapFamToProdNew.get(family)){
                ProdutosFamilia__c prodFam = new ProdutosFamilia__c();
                prodFam.Produto__c = prod.Id;
                prodFam.Relativo__c = mapFamToProdFocoNew.get(family).Id;

                prodFamiliaListToInsert.add(prodFam);
            }
        }

        if (!prodFamiliaListToDelete.isEmpty()){
            delete prodFamiliaListToDelete;
        }

        if (!prodFamiliaListToInsert.isEmpty()){
            insert prodFamiliaListToInsert;
        }
    }
}