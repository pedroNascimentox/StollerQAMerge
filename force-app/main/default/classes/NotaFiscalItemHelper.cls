public class NotaFiscalItemHelper extends TriggerContext {

    public static void updateApuracaoRelation(Map<Id, NotaFiscalItem__c> newContextMap, Map<Id, NotaFiscalItem__c> oldContextMap) {

        Set<String> criterioApuracaoOld = new Set<String>();

        List<Apuracao__c> updateApuracoes = new List<Apuracao__c>();

        if(!oldContextMap.isEmpty()){
            for (NotaFiscalItem__c item : newContextMap.values()) {
                if(item.CriterioApuracao__c != oldContextMap.get(item.Id).CriterioApuracao__c){
                    criterioApuracaoOld.add(oldContextMap.get(item.Id).CriterioApuracao__c);
                }
            }
        }

        List<Apuracao__c> apuracoesByCriterioApuracao = [SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioApuracaoOld];

        if(!apuracoesByCriterioApuracao.isEmpty()){
            for(Apuracao__c apuracao : apuracoesByCriterioApuracao){
                apuracao.Atualizado__c = false;
                updateApuracoes.add(apuracao);
            }
        }

        Map<Id, NotaFiscalItem__c> notaFiscalItemMap = new Map<Id, NotaFiscalItem__c>(
            [SELECT Id, CodigoMaterial__c, CriterioApuracao__c, Apuracao__c, NotaFiscal__c FROM NotaFiscalItem__c WHERE Id IN :newContextMap.keySet()]
        );

        Map<String, List<NotaFiscalItem__c>> criterioApuracaoToItemListMap = new Map<String, List<NotaFiscalItem__c>>();
        Map<Id, NotaFiscal__c> notaFiscalMap = new Map<Id, NotaFiscal__c>();

        for (NotaFiscalItem__c item : newContextMap.values()) {
            if (!criterioApuracaoToItemListMap.containsKey(item.CriterioApuracao__c)) {
                criterioApuracaoToItemListMap.put(item.CriterioApuracao__c, new List<NotaFiscalItem__c>());
            }
            criterioApuracaoToItemListMap.get(item.CriterioApuracao__c).add(item);
            notaFiscalMap.put(item.NotaFiscal__c, new NotaFiscal__c());
        }

        Map<Id, Apuracao__c> apuracaoMap = new Map<Id, Apuracao__c>(
            [SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioApuracaoToItemListMap.keySet()]
        );
 
        System.debug('apuracaoMap ' + apuracaoMap);

        Map<String, Apuracao__c> criterioToApuracaoMap = new Map<String, Apuracao__c>();
        for (Apuracao__c apuracao : apuracaoMap.values()) {
            criterioToApuracaoMap.put(apuracao.CriterioApuracao__c, apuracao);
        }

        notaFiscalMap = new Map<Id, NotaFiscal__c>(
            [SELECT Id, Territorio__c, DataNF__c, NrOrdem__c, NrOrdem__r.AccountId, NrOrdem__r.Account.ExternalId__c, TerritorioGerencial__c FROM NotaFiscal__c WHERE Id IN :notaFiscalMap.keySet()]
        );

        Map<String, Apuracao__c> apuracoesToInsertMap = new Map<String, Apuracao__c>();

        for (String key : criterioApuracaoToItemListMap.keySet()) {
            if (criterioToApuracaoMap.containsKey(key)) {
                criterioToApuracaoMap.get(key).Atualizado__c = false;
                for (NotaFiscalItem__c item : criterioApuracaoToItemListMap.get(key)) {
                    notaFiscalItemMap.get(item.Id).Apuracao__c = criterioToApuracaoMap.get(key).Id;
                }
            } else {
                NotaFiscalItem__c item = criterioApuracaoToItemListMap.get(key)[0]; // getting only the first record data
                NotaFiscal__c nota = notaFiscalMap.get(item.NotaFiscal__c);
                System.debug('nota.Territorio__C: ' + nota.Territorio__C);
                if (item.CodigoMaterial__c != null && 
                    nota.NrOrdem__c != null && 
                    nota.NrOrdem__r.AccountId != null && 
                    nota.Territorio__c != null && 
                    nota.DataNF__c != null && 
                    nota.TerritorioGerencial__c != null &&
                    !apuracoesToInsertMap.containsKey(key)) {
                    apuracoesToInsertMap.put(key,
                        new Apuracao__c(
                            NomeConta__c       = nota.NrOrdem__r.AccountId,
                            Territorio__c      = nota.TerritorioGerencial__c,
                            Produto__c         = item.CodigoMaterial__c,
                            DataFaturamento__c = Date.newInstance(nota.DataNF__c.year(), nota.DataNF__c.month(), 01),
                            Atualizado__c      = false
                        )
                    );
                }
            }
        }

        update criterioToApuracaoMap.values();

        if (!apuracoesToInsertMap.isEmpty()) {
            System.debug('apuracoesToInsertMap: ' + apuracoesToInsertMap.values());
            insert apuracoesToInsertMap.values();
        }

        if(!updateApuracoes.isEmpty()){
            update updateApuracoes;
        }

        List<Id> apuracaoIds = new List<Id>();
        for (Apuracao__c a : apuracoesToInsertMap.values()) {
            apuracaoIds.add(a.Id);
        }

        List<Apuracao__c> apuracoes = [SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE Id IN :apuracaoIds];

        for (Apuracao__c apuracao : apuracoes) {
            if(criterioApuracaoToItemListMap.containsKey(apuracao.CriterioApuracao__c)){
                for (NotaFiscalItem__c item : criterioApuracaoToItemListMap.get(apuracao.CriterioApuracao__c)) {
                    notaFiscalItemMap.get(item.Id).Apuracao__c = apuracao.Id;
                }
            }
        }

        NotaFiscalItemHelper.disableTrigger();
        update notaFiscalItemMap.values();
        NotaFiscalItemHelper.enableTrigger();
        
    }

    public static void setValorTotalOnUpsert(List<NotaFiscalItem__c> notaFiscalItens) {

        Map<Id, NotaFiscal__c> notaFiscalMap = new Map<Id, NotaFiscal__c>();
        for (NotaFiscalItem__c item : notaFiscalItens) {
            notaFiscalMap.put(item.NotaFiscal__c, new NotaFiscal__c());
        }

        notaFiscalMap = new Map<Id, NotaFiscal__c>([SELECT Id, ValorTotalNota__c, ValorTotalNotaUSD__c, ValorTotalLitros__c, Moeda__c, ValorTotalNotaLiquido__c FROM NotaFiscal__c WHERE Id IN :notaFiscalMap.keySet()]);

        NotaFiscalItem__c[] notaFiscalItemBase = [SELECT Id, Litros__c, ValorTotalItem__c, ValorTotalUSD__c, NotaFiscal__c, ValorTotalLiquido__c FROM NotaFiscalItem__c WHERE NotaFiscal__c IN :notaFiscalMap.keySet()];

        for (NotaFiscal__c nota : notaFiscalMap.values()) {
            nota.ValorTotalNota__c = 0;
            nota.ValorTotalNotaUSD__c = 0;
            nota.ValorTotalLitros__c = 0;
        }

        for (NotaFiscalItem__c item : notaFiscalItemBase) {

            NotaFiscal__c nota = notaFiscalMap.get(item.NotaFiscal__c);

            nota.ValorTotalLitros__c += IntegrationUtils.checkDecimal(item.Litros__c);
            nota.ValorTotalNotaLiquido__c += IntegrationUtils.checkDecimal(item.ValorTotalLiquido__c);
            nota.ValorTotalNota__c += IntegrationUtils.checkDecimal(item.ValorTotalItem__c);
            nota.ValorTotalNotaUSD__c += IntegrationUtils.checkDecimal(item.ValorTotalUSD__c);
        }

        if (!notaFiscalMap.isEmpty()) {
            NotaFiscalHelper.disableTrigger();
            update notaFiscalMap.values();
            NotaFiscalHelper.enableTrigger();
        }

    }

    public static void setValorTotalOnDelete(List<NotaFiscalItem__c> notaFiscalItens) {

        Map<Id, NotaFiscal__c> notaFiscalMap = new Map<Id, NotaFiscal__c>();
        for (NotaFiscalItem__c item : notaFiscalItens) {
            notaFiscalMap.put(item.NotaFiscal__c, new NotaFiscal__c());
        }

        notaFiscalMap = new Map<Id, NotaFiscal__c>([SELECT Id, ValorTotalNota__c, ValorTotalNotaUSD__c, ValorTotalLitros__c, ValorTotalNotaLiquido__c, Moeda__c FROM NotaFiscal__c WHERE Id IN :notaFiscalMap.keySet()]);

        for (NotaFiscalItem__c item : notaFiscalItens) {

            NotaFiscal__c nota = notaFiscalMap.get(item.NotaFiscal__c);

            nota.ValorTotalLitros__c -= IntegrationUtils.checkDecimal(item.Litros__c);
            nota.ValorTotalNotaLiquido__c -= IntegrationUtils.checkDecimal(item.ValorTotalLiquido__c);
            nota.ValorTotalNota__c -= IntegrationUtils.checkDecimal(item.ValorTotalItem__c);
            nota.ValorTotalNotaUSD__c -= IntegrationUtils.checkDecimal(item.ValorTotalUSD__c);
        }

        NotaFiscalHelper.disableTrigger();
        update notaFiscalMap.values();
        NotaFiscalHelper.enableTrigger();

    }

    public static void setSaldoLitrosEscoamento(List<NotaFiscalItem__c> notaFiscalItens) {
        for (NotaFiscalItem__c item : notaFiscalItens) {
            item.SaldoLitrosEscoamento__c = item.QuantidadeNota__c;
        }
    }

    public static void calculateBalance(Map<Id, NotaFiscalItem__c> newContextMap) {

        Map<Id, NotaFiscalItem__c> newItemMap = new Map<Id, NotaFiscalItem__c>([
                SELECT Id, Litros__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c, QuantidadeNota__c FROM NotaFiscalItem__c 
                WHERE Id IN :newContextMap.KeySet() 
                AND NotaFiscal__r.TipoFat__c != 'ZBON' 
                AND NotaFiscal__r.TipoFat__c != 'ZREB' 
                AND NotaFiscal__r.TipoNota__c = 'ZA' 
                AND NotaFiscal__r.StatusCancelado__c = false
            ]);

        Integer escoamentoBalance = 0;

        Map<String, List<NotaFiscalItem__c>> criterioToNotaFiscalItemList = new Map<String, List<NotaFiscalItem__c>>();
        for (NotaFiscalItem__c item : newItemMap.values()) {
            if (!criterioToNotaFiscalItemList.containsKey(item.CriterioEscoamento__c)) {
                criterioToNotaFiscalItemList.put(item.CriterioEscoamento__c, new List<NotaFiscalItem__c>());
            }
            criterioToNotaFiscalItemList.get(item.CriterioEscoamento__c).add(item);
        }

        Map<Id, Escoamento__c> escoamentoMap = new Map<Id, Escoamento__c>(
            [
                SELECT Id, Quantidade__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c 
                FROM Escoamento__c 
                WHERE CriterioEscoamento__c IN :criterioToNotaFiscalItemList.keySet() AND
                SaldoLitrosEscoamento__c != 0
                ORDER BY CreatedDate
            ]);
        
        if (!escoamentoMap.isEmpty()) {
            Map<Id, Integer> idToQuantity = new Map<Id, Integer>();
            Integer itemQuantity = 0;
            for (Escoamento__c escoamento : escoamentoMap.values()) {
                escoamentoBalance += Integer.valueOf(escoamento.SaldoLitrosEscoamento__c);
                idToQuantity.put(escoamento.Id, Integer.valueOf(escoamento.SaldoLitrosEscoamento__c));
            }

            for (Integer i = 0; i < newItemMap.values().size(); i++) {
                itemQuantity += Integer.valueOf(newItemMap.values()[i].SaldoLitrosEscoamento__c);
                escoamentoBalance -= Integer.valueOf(newItemMap.values()[i].QuantidadeNota__c);
                if (escoamentoBalance < 0) {
                    newItemMap.values()[i].SaldoLitrosEscoamento__c = escoamentoBalance * -1;
                    break;
                }
                newItemMap.values()[i].SaldoLitrosEscoamento__c = 0;
            }

            for (Id id : idToQuantity.keySet()) {
                Integer result = itemQuantity - idToQuantity.get(id);
                if (result > 0 || result == 0) {
                    idToQuantity.put(id, 0);
                    itemQuantity = result;
                } else if (result < 0) {
                    Integer invertedResult = result * -1;
                    idToQuantity.put(id, invertedResult);
                    break;
                }
            }
            for (Id id : idToQuantity.keySet()) {
                escoamentoMap.get(id).SaldoLitrosEscoamento__c = idToQuantity.get(id);
            }
            
            EscoamentoHelper.disableTrigger();
            update escoamentoMap.values();
            EscoamentoHelper.enableTrigger();
            NotaFiscalItemHelper.disableTrigger();
            update newItemMap.values();
            NotaFiscalItemHelper.enableTrigger();
        }
    }

    public static void withdrawBalance(Map<Id, NotaFiscalItem__c> notaFiscalItemMap) {

        // need to use SELECT due to parent fiter
        Map<Id, NotaFiscalItem__c> newNotaFiscalItemMap = new Map<Id, NotaFiscalItem__c>([
            SELECT Id, QuantidadeNota__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c FROM NotaFiscalItem__c 
            WHERE Id IN :notaFiscalItemMap.keySet() 
            AND NotaFiscal__r.TipoFat__c != 'ZBON' 
            AND NotaFiscal__r.TipoFat__c != 'ZREB' 
            AND NotaFiscal__r.TipoNota__c = 'ZA' 
            AND NotaFiscal__r.StatusCancelado__c = false
        ]);

        withdrawBalanceWithoutSelect(newNotaFiscalItemMap);

    }

    public static void withdrawBalanceWithoutSelect(Map<Id, NotaFiscalItem__c> newNotaFiscalItemMap) {

        Map<String, List<NotaFiscalItem__c>> criterioToNotaFiscalItemList = new Map<String, List<NotaFiscalItem__c>>();

        Integer notaFiscalItemBalance = 0;

        for (NotaFiscalItem__c notaFiscalItem : newNotaFiscalItemMap.values()) {
            notaFiscalItemBalance += Integer.valueOf(notaFiscalItem.QuantidadeNota__c) - Integer.valueOf(notaFiscalItem.SaldoLitrosEscoamento__c);
            if (!criterioToNotaFiscalItemList.containsKey(notaFiscalItem.CriterioEscoamento__c)) {
                criterioToNotaFiscalItemList.put(notaFiscalItem.CriterioEscoamento__c, new List<NotaFiscalItem__c>());
            }
            criterioToNotaFiscalItemList.get(notaFiscalItem.CriterioEscoamento__c).add(notaFiscalItem);
        }

        Map<Id, Escoamento__c> escoamentoMap = new Map<Id, Escoamento__c>(
            [
                SELECT Id, Quantidade__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c 
                FROM Escoamento__c 
                WHERE CriterioEscoamento__c IN :criterioToNotaFiscalItemList.keySet()
                ORDER BY CreatedDate
            ]);
        
        for (Integer i = escoamentoMap.values().size() - 1; i >= 0; i--) {
            Integer balanceToWithdraw = Integer.valueOf(escoamentoMap.values()[i].Quantidade__c - escoamentoMap.values()[i].SaldoLitrosEscoamento__c);
            
            if (notaFiscalItemBalance == 0) {
                break;
            }
            if (notaFiscalItemBalance >= balanceToWithdraw) {
                notaFiscalItemBalance -= balanceToWithdraw;
                balanceToWithdraw = 0;
            } else {
                balanceToWithdraw -= notaFiscalItemBalance;
                notaFiscalItemBalance = 0;
            }

            escoamentoMap.values()[i].SaldoLitrosEscoamento__c = escoamentoMap.values()[i].Quantidade__c - balanceToWithdraw;
        }
        EscoamentoHelper.disableTrigger();
        update escoamentoMap.values();
        EscoamentoHelper.enableTrigger();
    }

    public static void updateApWallet(Map<Id, NotaFiscalItem__c> newContextMap, Map<Id, NotaFiscalItem__c> oldContextMap) {

        Set<String> critApuracao = new Set<String>();

        List<Apuracao__c> updateSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> removeSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> addingToAnotherAp = new List<Apuracao__c>();

        Map<String, List<NotaFiscalItem__c>> mapCritRemoveToNfItem  = new Map<String, List<NotaFiscalItem__c>>();
        Map<String, List<NotaFiscalItem__c>> mapCritAddingToAnotherAp = new Map<String, List<NotaFiscalItem__c>>();

        Map<String, List<NotaFiscalItem__c>> mapCritUpdateToNfItem  = new Map<String, List<NotaFiscalItem__c>>();
        Map<String, List<NotaFiscalItem__c>> mapSubtractToNfItem    = new Map<String, List<NotaFiscalItem__c>>();

        Map<Id, NotaFiscalItem__c> oldContextMapAux = new Map<Id, NotaFiscalItem__c>([SELECT Id, NotaFiscal__c, NotaFiscal__r.TipoFat__c, CriterioApuracao__c, ValorTotalItem__c, ValorTotalUSD__c, Litros__c FROM NotaFiscalItem__c WHERE Id IN :oldContextMap.keySet()]);
        
        for (NotaFiscalItem__c nfItemNew : [SELECT Id, NotaFiscal__c,  NotaFiscal__r.StatusCancelado__c,  NotaFiscal__r.TipoFat__c, CriterioApuracao__c, ValorTotalItem__c, ValorTotalUSD__c, Litros__c FROM NotaFiscalItem__c WHERE Id IN :newContextMap.keySet()]){

            NotaFiscalItem__c nfItemOld = oldContextMapAux.get(nfItemNew.Id);

            String newValue = nfItemNew.CriterioApuracao__c;
            String oldValue = nfItemOld.CriterioApuracao__c;

            if (nfItemNew.NotaFiscal__r.TipoFat__c == 'ZBON' && nfItemOld.NotaFiscal__r.TipoFat__c != 'ZBON' && nfItemOld.NotaFiscal__r.TipoFat__c != 'ZEXP' && 
                nfItemNew.NotaFiscal__r.TipoFat__c == 'ZEXP' && nfItemOld.NotaFiscal__r.TipoFat__c != 'ZEXP' && nfItemOld.NotaFiscal__r.TipoFat__c != 'ZBON') {

                critApuracao.add(nfItemNew.CriterioApuracao__c);
                critApuracao.add(nfItemOld.CriterioApuracao__c);
                    
                if (!mapCritRemoveToNfItem.containsKey(nfItemOld.CriterioApuracao__c)) {
                    mapCritRemoveToNfItem.put(nfItemOld.CriterioApuracao__c, new List<NotaFiscalItem__c>());
                }
                mapCritRemoveToNfItem.get(nfItemOld.CriterioApuracao__c).add(nfItemOld);
            
            } else if (nfItemNew.ValorTotalItem__c != nfItemOld.ValorTotalItem__c || nfItemNew.ValorTotalUSD__c != nfItemOld.ValorTotalUSD__c || nfItemNew.Litros__c != nfItemOld.Litros__c || nfItemNew.CriterioApuracao__c != nfItemOld.CriterioApuracao__c) {

                critApuracao.add(nfItemNew.CriterioApuracao__c);
                critApuracao.add(nfItemOld.CriterioApuracao__c);

                if (nfItemNew.CriterioApuracao__c != nfItemOld.CriterioApuracao__c) {
                    if (!mapCritAddingToAnotherAp.containsKey(nfItemNew.CriterioApuracao__c)) {
                        mapCritAddingToAnotherAp.put(nfItemNew.CriterioApuracao__c, new List<NotaFiscalItem__c>());
                    }
                    mapCritAddingToAnotherAp.get(nfItemNew.CriterioApuracao__c).add(nfItemNew);
                    
                    if (!mapCritRemoveToNfItem.containsKey(nfItemOld.CriterioApuracao__c)) {
                        mapCritRemoveToNfItem.put(nfItemOld.CriterioApuracao__c, new List<NotaFiscalItem__c>());
                    }
                    mapCritRemoveToNfItem.get(nfItemOld.CriterioApuracao__c).add(nfItemOld);
                } else {
                    if (!mapCritUpdateToNfItem.containsKey(nfItemNew.CriterioApuracao__c)) {
                        mapCritUpdateToNfItem.put(nfItemNew.CriterioApuracao__c, new List<NotaFiscalItem__c>());
                    }
                    mapCritUpdateToNfItem.get(nfItemNew.CriterioApuracao__c).add(nfItemNew);

                    if (!mapSubtractToNfItem.containsKey(nfItemNew.CriterioApuracao__c)) {
                        mapSubtractToNfItem.put(nfItemNew.CriterioApuracao__c, new List<NotaFiscalItem__c>());
                    }
                    mapSubtractToNfItem.get(nfItemNew.CriterioApuracao__c).add(nfItemOld);
                }
            }
        }

        for (Apuracao__c apuracao : [SELECT Id, CarteiraReais__c, CarteiraDolar__c, CarteiraLitros__c, CriterioApuracao__c, FaturadoReais__c, FaturadoDolar__c, FaturadoLitros__c FROM Apuracao__c WHERE CriterioApuracao__c IN: critApuracao]){

            if (mapCritAddingToAnotherAp.containsKey(apuracao.CriterioApuracao__c)){
                for (NotaFiscalItem__c nfItem : mapCritAddingToAnotherAp.get(apuracao.CriterioApuracao__c)) {
                    apuracao.FaturadoReais__c  = apuracao.FaturadoReais__c  != null ? apuracao.FaturadoReais__c  + nfItem.ValorTotalItem__c : nfItem.ValorTotalItem__c;
                    apuracao.FaturadoDolar__c  = apuracao.FaturadoDolar__c  != null ? apuracao.FaturadoDolar__c  + nfItem.ValorTotalUSD__c  : nfItem.ValorTotalUSD__c;
                    apuracao.FaturadoLitros__c = apuracao.FaturadoLitros__c != null ? apuracao.FaturadoLitros__c + nfItem.Litros__c         : nfItem.Litros__c;

                    addingToAnotherAp.add(apuracao);
                }
            }            
            if (mapCritRemoveToNfItem.containsKey(apuracao.CriterioApuracao__c)){
                for (NotaFiscalItem__c nfItem : mapCritRemoveToNfItem.get(apuracao.CriterioApuracao__c)) {
                    apuracao.FaturadoReais__c  = apuracao.FaturadoReais__c  != null ? apuracao.FaturadoReais__c  - nfItem.ValorTotalItem__c : null;
                    apuracao.FaturadoDolar__c  = apuracao.FaturadoDolar__c  != null ? apuracao.FaturadoDolar__c  - nfItem.ValorTotalUSD__c  : null;
                    apuracao.FaturadoLitros__c = apuracao.FaturadoLitros__c != null ? apuracao.FaturadoLitros__c - nfItem.Litros__c         : null;

                    removeSumApuracao.add(apuracao);
                }
            }
            if (mapCritUpdateToNfItem.containsKey(apuracao.CriterioApuracao__c)){

                NotaFiscalItem__c[] newList = mapCritUpdateToNfItem.get(apuracao.CriterioApuracao__c);
                NotaFiscalItem__c[] oldList = mapSubtractToNfItem.get(apuracao.CriterioApuracao__c);

                for (Integer i = 0; i < newList.size(); i++ ) {
                    NotaFiscalItem__c nfItemNew = newList[i];
                    NotaFiscalItem__c nfItemOld = oldList[i];

                    apuracao.FaturadoReais__c  = apuracao.FaturadoReais__c  != null ? apuracao.FaturadoReais__c  - nfItemOld.ValorTotalItem__c    + nfItemNew.ValorTotalItem__c    : nfItemNew.ValorTotalItem__c;
                    apuracao.FaturadoDolar__c  = apuracao.FaturadoDolar__c  != null ? apuracao.FaturadoDolar__c  - nfItemOld.ValorTotalUSD__c + nfItemNew.ValorTotalUSD__c : nfItemNew.ValorTotalUSD__c;
                    apuracao.FaturadoLitros__c = apuracao.FaturadoLitros__c != null ? apuracao.FaturadoLitros__c - nfItemOld.Litros__c        + nfItemNew.Litros__c        : nfItemNew.Litros__c;
                }

                updateSumApuracao.add(apuracao);
            }            
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
}