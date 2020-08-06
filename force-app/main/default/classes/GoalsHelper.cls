public  class GoalsHelper extends TriggerContext {
    public static void insertApuracao(Meta__c[] goalsList) {

        List<String> criterioMetaList = new List<String>();
        for (Meta__c meta : goalsList) {
            criterioMetaList.add(meta.CriterioMeta__c);
        }

        Map<Id, Apuracao__c> baseApuracaoList = new Map<Id, Apuracao__c>([SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioMetaList]);
        Map<String, Apuracao__c> criterioApuracaoToApuracaoMap = new Map<String, Apuracao__c>();
        for (Apuracao__c apuracao : baseApuracaoList.values()) {
            criterioApuracaoToApuracaoMap.put(apuracao.CriterioApuracao__c, apuracao);
        }

        List<Apuracao__c> apuracaoList = new List<Apuracao__c>();

        for (Meta__c meta : goalsList){

            if (criterioApuracaoToApuracaoMap.containsKey(meta.CriterioMeta__c)) {
                Apuracao__c apuracao = criterioApuracaoToApuracaoMap.get(meta.CriterioMeta__c);

                metaToApuracao(meta, apuracao);

            } else {
                Apuracao__c apuracao = new Apuracao__c();

                metaToApuracao(meta, apuracao);

                apuracaoList.add(apuracao);
            }
        }

        if (!criterioApuracaoToApuracaoMap.isEmpty()) {
            update criterioApuracaoToApuracaoMap.values();
        }

        if (!apuracaoList.isEmpty()) {
            insert apuracaoList;
        }
    }

    private static void metaToApuracao(Meta__c meta, Apuracao__c apuracao) {
        apuracao.Atualizado__c      = false;
        apuracao.Meta__c            = meta.Id;
        apuracao.Litros__c          = meta.Litros__c;
        apuracao.Produto__c         = meta.Produto__c;
        apuracao.NomeConta__c       = meta.NomeConta__c;
        apuracao.Territorio__c      = meta.Territorio__c;
        apuracao.OrcamentoReais__c  = meta.OrcamentoReal__c;
        apuracao.OrcamentoDolar__c  = meta.OrcamentoDolar__c;
        apuracao.DataFaturamento__c = meta.Data__c;
        apuracao.ApuracaoPai__c     = true;
    }

    public static void updateApuracao(Map<Id, Meta__c> newContextMap){
        
        Map<Id, List<Apuracao__c>> mapIdToApuracaoList = new Map<Id, List<Apuracao__c>>();

        List<Apuracao__c> apuracaoList = new List<Apuracao__c>();

        for (Apuracao__c apuracao : [SELECT Meta__c, Produto__c, Litros__c, NomeConta__c, Territorio__c, OrcamentoReais__c, OrcamentoDolar__c, DataFaturamento__c
                                     FROM Apuracao__c WHERE Meta__c IN: newContextMap.keySet() AND ApuracaoPai__c = true]){
            if (!mapIdToApuracaoList.containsKey(apuracao.Meta__c)){
                mapIdToApuracaoList.put(apuracao.Meta__c, new List<Apuracao__c>{apuracao});
            }else{
                mapIdToApuracaoList.get(apuracao.Meta__c).add(apuracao);
            }
        }

        for (Id id : mapIdToApuracaoList.keySet()){
            for (Apuracao__c apuracao : mapIdToApuracaoList.get(id)){
                Meta__c newMeta = newContextMap.get(apuracao.Meta__c);

                metaToApuracao(newMeta, apuracao);

                apuracaoList.add(apuracao);
            }
        }

        if (!apuracaoList.isEmpty()){
            update apuracaoList;
        }
    }

    public static void changeMetaOwner(List<Meta__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Meta__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(Meta__c goals : newRecordsList){
            if(goals.territorio__c != null && territories.containsKey(goals.territorio__c) && goals.ownerId != territories.get(goals.territorio__c).rtv__c){
                goals.ownerId = territories.get(goals.territorio__c).rtv__c;
            }
        }
    }
}