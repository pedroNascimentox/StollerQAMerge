public with sharing class LancamentoContabilHelper extends TriggerContext {
    
    public static void updateApuracaoRelation(Map<Id, LancamentoContabil__c> newContextMap) {

        newContextMap = new Map<Id, LancamentoContabil__c>(
            [SELECT Id, CriterioCDA__c, Produto__c, NomeConta__c, NomeConta__r.TerritoriosConcatenados__c, DataLancamento__c, Apuracao__c FROM LancamentoContabil__c WHERE Id IN :newContextMap.keySet()]
        );

        Map<String, Id> territorioExternalIdToId = new Map<String, Id>();
        Set<String> criterioCDAMap = new Set<String>();
        for (LancamentoContabil__c lancamentoContabil : newContextMap.values()) {
            criterioCDAMap.add(lancamentoContabil.CriterioCDA__c);
            if (lancamentoContabil.NomeConta__c != null && lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c != null) {
                territorioExternalIdToId.put(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c, null);
            }
        }

        for (Territorio__c territorio : [SELECT Id, ExternalId__c FROM Territorio__c WHERE ExternalId__c IN :territorioExternalIdToId.keySet()]) {
            territorioExternalIdToId.put(territorio.ExternalId__c, territorio.Id);
        }
        // System.debug('territorioExternalIdToId => ' + JSON.serializePretty(territorioExternalIdToId));

        Map<Id, Apuracao__c> apuracaoMap = new Map<Id, Apuracao__c>(
            [SELECT Id, CriterioCDA__c FROM Apuracao__c WHERE CriterioCDA__c IN :criterioCDAMap]
        );

        Map<String, Apuracao__c> apuracaoCriterioCDAMap = new Map<String, Apuracao__c>();
        for (Apuracao__c apuracao : apuracaoMap.values()) {
            apuracaoCriterioCDAMap.put(apuracao.CriterioCDA__c, apuracao);
        }

        Map<String, Apuracao__c> apuracoesToInsertMap = new Map<String, Apuracao__c>();

        for (LancamentoContabil__c lancamentoContabil : newContextMap.values()) {
            // System.debug('apuracaoCriterioCDAMap.containsKey(lancamentoContabil.CriterioCDA__c) => ' + JSON.serializePretty(apuracaoCriterioCDAMap.containsKey(lancamentoContabil.CriterioCDA__c)));
            // System.debug('lancamentoContabil.Produto__c != null => ' + JSON.serializePretty(lancamentoContabil.Produto__c != null));
            // System.debug('lancamentoContabil.NomeConta__c != null => ' + JSON.serializePretty(lancamentoContabil.NomeConta__c != null));
            // System.debug('lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c != null => ' + JSON.serializePretty(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c != null));
            // System.debug('territorioExternalIdToId.get(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c) != null => ' + JSON.serializePretty(territorioExternalIdToId.get(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c) != null));
            // System.debug('lancamentoContabil.DataLancamento__c != null => ' + JSON.serializePretty(lancamentoContabil.DataLancamento__c != null));
            // System.debug('!apuracoesToInsertMap.containsKey(lancamentoContabil.CriterioCDA__c) => ' + JSON.serializePretty(!apuracoesToInsertMap.containsKey(lancamentoContabil.CriterioCDA__c)));
            if (apuracaoCriterioCDAMap.containsKey(lancamentoContabil.CriterioCDA__c)) {
                // System.debug('UPDATED');
                apuracaoCriterioCDAMap.get(lancamentoContabil.CriterioCDA__c).Atualizado__c = false;
                if (lancamentoContabil.Apuracao__c == null) {
                    lancamentoContabil.Apuracao__c = apuracaoCriterioCDAMap.get(lancamentoContabil.CriterioCDA__c).Id;
                }
            } else if (lancamentoContabil.Produto__c != null && 
                lancamentoContabil.NomeConta__c != null && 
                lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c != null && 
                territorioExternalIdToId.get(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c) != null && 
                lancamentoContabil.DataLancamento__c != null && 
                !apuracoesToInsertMap.containsKey(lancamentoContabil.CriterioCDA__c)) {
                try {
                    apuracoesToInsertMap.put(lancamentoContabil.CriterioCDA__c, 
                        new Apuracao__c(
                            NomeConta__c       = lancamentoContabil.NomeConta__c,
                            Territorio__c      = territorioExternalIdToId.get(lancamentoContabil.NomeConta__r.TerritoriosConcatenados__c),
                            Produto__c         = lancamentoContabil.Produto__c,
                            DataFaturamento__c = Date.newInstance(lancamentoContabil.DataLancamento__c.year(), lancamentoContabil.DataLancamento__c.month(), 01),
                            Atualizado__c      = false
                        )
                    );
                    // System.debug('INSERTED');
                } catch (Exception e) {
                    // System.debug('EXCEPTION => ' + e.getMessage() + ' - ' + e.getStackTraceString());
                    lancamentoContabil.addError(e.getMessage() + ' - ' + e.getStackTraceString());
                }
            }
        }

        update apuracaoCriterioCDAMap.values();

        Map<String, List<LancamentoContabil__c>> criterioToLancamentoContabilList = new Map<String, List<LancamentoContabil__c>>();
        if (!apuracoesToInsertMap.isEmpty()) {
            for (LancamentoContabil__c lancamentoContabil : newContextMap.values()) {
                if (!criterioToLancamentoContabilList.containsKey(lancamentoContabil.CriterioCDA__c)) {
                    criterioToLancamentoContabilList.put(lancamentoContabil.CriterioCDA__c, new List<LancamentoContabil__c>());
                }
                criterioToLancamentoContabilList.get(lancamentoContabil.CriterioCDA__c).add(lancamentoContabil);
            }
            // System.debug('criterioToLancamentoContabilList => ' + JSON.serializePretty(criterioToLancamentoContabilList));
        }

        if (!apuracoesToInsertMap.isEmpty()) {
            insert apuracoesToInsertMap.values();
        }

        List<Apuracao__c> insertedApuracoes = new List<Apuracao__c>();

        if (!apuracoesToInsertMap.isEmpty()) {
            insertedApuracoes = [SELECT Id, CriterioCDA__c FROM Apuracao__c WHERE CriterioCDA__c IN :apuracoesToInsertMap.keySet()];
        }

        for (Apuracao__c apuracao : insertedApuracoes) {
            // System.debug('apuracao.CriterioCDA__c => ' + JSON.serializePretty(apuracao.CriterioCDA__c));
            if (criterioToLancamentoContabilList.containsKey(apuracao.CriterioCDA__c)) {
                for (LancamentoContabil__c lancamentoContabil : criterioToLancamentoContabilList.get(apuracao.CriterioCDA__c)) {
                    // System.debug('apuracao.Id => ' + JSON.serializePretty(apuracao.Id));
                    newContextMap.get(lancamentoContabil.Id).Apuracao__c = apuracao.Id;
                }
            }
        }

        LancamentoContabilHelper.disableTrigger();
        update newContextMap.values();
        LancamentoContabilHelper.enableTrigger();

    }
}