public class GoalsAffiliatesHelper extends TriggerContext {
    public static void checkBeforeInsert(MetaFilial__c[] metaFilialList) {
        Set<Id> metasExistentes = new Set<Id>();
        Set<Id> metasFiliaisExistentes = new Set<Id>();
        Set<Id> clientesExistentes = new Set<Id>();
        Map<String, MetaFilial__c> mapIdToMetaFilial = new Map<String, MetaFilial__c>();
        Boolean metaFilialRepetida = false;

        for (MetaFilial__c meta : metaFilialList){
            metasExistentes.add(meta.MetaMatriz__c);
            mapIdToMetaFilial.put(meta.MetaMatriz__c + ' - ' + meta.Territrio__c, meta);
        }

        system.debug(mapIdToMetaFilial);

        for (Meta__c meta : [SELECT Id, NomeConta__c, Territorio__c FROM Meta__c WHERE Id IN: metasExistentes]){
            if (mapIdToMetaFilial.containsKey(meta.Id)){
                if (mapIdToMetaFilial.get(meta.Id + ' - ' + meta.Territorio__c).Filial__c == meta.NomeConta__c){
                    clientesExistentes.add(meta.NomeConta__c);
                }
            }
        }

        for (MetaFilial__c mFilial : [SELECT id, Filial__c, MetaMatriz__c, MetaMatriz__r.NomeConta__c, Territrio__c FROM MetaFilial__c WHERE MetaMatriz__c IN: metasExistentes]){
            system.debug(mFilial);
            if (mapIdToMetaFilial.containsKey(mFilial.MetaMatriz__c + ' - ' + mFilial.Territrio__c)){
                system.debug('mFilial.Filial__c: '+ mFilial.Filial__c);
                system.debug('mapIdToMetaFilial.get(mFilial.Id).Filial__c: '+ mapIdToMetaFilial.get(mFilial.MetaMatriz__c + ' - ' + mFilial.Territrio__c).Filial__c);
                if (mFilial.Filial__c == mapIdToMetaFilial.get(mFilial.MetaMatriz__c + ' - ' + mFilial.Territrio__c).Filial__c){
                    metaFilialRepetida = true;
                    metasFiliaisExistentes.add(mFilial.Filial__c);
                }else if (mFilial.MetaMatriz__r.NomeConta__c == mapIdToMetaFilial.get(mFilial.MetaMatriz__c + ' - ' + mFilial.Territrio__c).Filial__c){
                    metaFilialRepetida = true;
                }
            }
        }

        for (MetaFilial__c mFilial : metaFilialList){
            if (metaFilialRepetida){
                if (metasFiliaisExistentes.contains(mFilial.Filial__c)){
                    mFilial.addError('Filial ja existente na Meta');        
                }else if (clientesExistentes.contains(mFilial.Filial__c)){
                    mFilial.addError('Filial não pode ser o mesmo da Meta');
                }   
            }
        }
    }

    public static void insertApuracao(MetaFilial__c[] goalsAffiliateList) {
        List<Apuracao__c> apuracaoList = new List<Apuracao__c>();
        List<Meta__c> metaList = new List<Meta__c>();

        Set<Id> idMetaMatriz = new Set<Id>();

        Map<Id, Meta__c> mapIdToMeta = new Map<Id, Meta__c>();

        Set<Id> metaIdSet = new Set<Id>();

        for (MetaFilial__c metaFilial : goalsAffiliateList){
            metaIdSet.add(metaFilial.MetaMatriz__c);
        }

        for (Meta__c meta : [SELECT Id, Produto__c, Territorio__c, Data__c FROM Meta__c WHERE Id IN: metaIdSet]){
            mapIdToMeta.put(meta.Id, meta);            
        }

        for (MetaFilial__c metaFilial : goalsAffiliateList){            
            idMetaMatriz.add(metaFilial.MetaMatriz__c);

            system.debug('metaFilial.MetaMatriz__c: '+ metaFilial.MetaMatriz__c);

            Apuracao__c apuracao = new Apuracao__c();
            apuracao.Atualizado__c      = false;
            apuracao.MetaFilial__c      = metaFilial.Id;
            apuracao.Litros__c          = metaFilial.Litros__c;
            apuracao.NomeConta__c       = metaFilial.Filial__c;
            apuracao.Meta__c            = metaFilial.MetaMatriz__c;
            apuracao.OrcamentoReais__c  = metaFilial.OrcamentoReais__c;
            apuracao.OrcamentoDolar__c  = metaFilial.OrcamentoDolar__c;
            apuracao.Produto__c         = mapIdToMeta.get(metaFilial.MetaMatriz__c).Produto__c;
            apuracao.Territorio__c      = mapIdToMeta.get(metaFilial.MetaMatriz__c).Territorio__c;
            apuracao.DataFaturamento__c = mapIdToMeta.get(metaFilial.MetaMatriz__c).Data__c;
			apuracao.TipoApuracao1__c   = 'Escoamento';
            apuracaoList.add(apuracao);
        } 
        system.debug(idMetaMatriz);
        for (Meta__c meta : [SELECT Id, Atualizado__c FROM Meta__c WHERE Id IN: idMetaMatriz]){
            meta.Atualizado__c = false;
            metaList.add(meta); 
        }

        if (!metaList.isEmpty()){
            update metaList;
        }

        if (!apuracaoList.isEmpty()){            
            insert apuracaoList;
        }
    }

    public static void updateApuracao(Map<Id, MetaFilial__c> newContextMap){
        
        Map<Id, List<Apuracao__c>> mapIdToApuracaoList = new Map<Id, List<Apuracao__c>>();

        List<Apuracao__c> apuracaoList = new List<Apuracao__c>();

        for (Apuracao__c apuracao : [SELECT Id, Meta__c, MetaFilial__c, Produto__c, Litros__c, NomeConta__c, Territorio__c, OrcamentoReais__c, OrcamentoDolar__c 
                                     FROM Apuracao__c WHERE MetaFilial__c IN: newContextMap.keySet()]){
            if (!mapIdToApuracaoList.containsKey(apuracao.MetaFilial__c)){
                mapIdToApuracaoList.put(apuracao.MetaFilial__c, new List<Apuracao__c>{apuracao});
            }else{
                mapIdToApuracaoList.get(apuracao.MetaFilial__c).add(apuracao);
            }
        }

        for (Id id : mapIdToApuracaoList.keySet()){
            for (Apuracao__c apuracao : mapIdToApuracaoList.get(id)){
                MetaFilial__c newMetaFilial = newContextMap.get(apuracao.MetaFilial__c);

                system.debug('Produto: '+newMetaFilial.Produto__c);
                system.debug('Territorio: '+ newMetaFilial.Territrio__c);
                system.debug('Nome Conta: '+ newMetaFilial.Filial__c);
                
                apuracao.Atualizado__c     = false;
                apuracao.Meta__c           = newMetaFilial.MetaMatriz__c;
                apuracao.Litros__c         = newMetaFilial.Litros__c;
                apuracao.NomeConta__c      = newMetaFilial.Filial__c;
                apuracao.OrcamentoReais__c = newMetaFilial.OrcamentoReais__c;
                apuracao.OrcamentoDolar__c = newMetaFilial.OrcamentoDolar__c;
				apuracao.tipoApuracao1__c  = 'Escoamento';
                system.debug(apuracao);
                apuracaoList.add(apuracao);
            }
        }

        system.debug(apuracaoList);
        if (!apuracaoList.isEmpty()){
            update apuracaoList;
        }
    }

    public static void updateMeta(MetaFilial__c[] goalsAffiliateList){

        Set<Id> metaIdSet = new Set<Id>();

        List<Meta__c> metaList = new List<Meta__c>();

        for (MetaFilial__c metaFilial: goalsAffiliateList){
            metaIdSet.add(metaFilial.MetaMatriz__c);
        }

        for (Meta__c meta : [SELECT Id, Atualizado__c FROM Meta__c WHERE Id IN: metaIdSet]){          
            meta.Atualizado__c = false;
            metaList.add(meta);            
        }

        if (!metaList.isEmpty()){
            update metaList;
        }
    }
}