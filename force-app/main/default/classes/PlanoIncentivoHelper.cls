public class PlanoIncentivoHelper extends TriggerContext{
    public static void checkBeforeDelete(PlanoIncentivo__c[] planoIncentivoList){
        // for (PlanoIncentivo__c planoIncentivo : planoIncentivoList){
        //     if (planoIncentivo.marco__c){
        //         planoIncentivo.addError('Não é permitido a exclusão do registro. =(');
        //     }
        // }
    }
    public static void checkStatusIncentivePlan(PlanoIncentivo__c[] planoIncentivoList){
        
        Set<Id> planoIncentivoSetId = new Set<Id>();
        Map<Id, PlanoIncentivo__c> mapIdToPlanoEmApuracao = new Map<Id, PlanoIncentivo__c>();
        Map<Id, PlanoIncentivo__c> mapIdToPlanoEncerrado  = new Map<Id, PlanoIncentivo__c>();
        
        for (PlanoIncentivo__c planoIncentivo : planoIncentivoList){
            planoIncentivoSetId.add(planoIncentivo.Id);
        }

        for (PlanoIncentivo__c planoIncentivo : [SELECT Id, /*AtingimentoMinimo__c,*/ Codigo__c, DataFinal__c, DataInicial__c, Descricao__c, /*Marco__c,*/ /*MesAno__c,*/ MinimoMeta__c, 
                                                 /*PremiacaoFaturamentoLiquido__c,*/ /*PremiacaoInova__c,*/ /*PremiacaoLitro__c,*/ PremiacaoMeta__c, /*PremiacaoSuperamentoMeta__c,*/ 
                                                 PremioAtingimento__c, PremioMnimo__c, PremioSuperacaoMeta__c, Status__c, SuperacaoMeta__c/*, ValorPremiacaoLitro__c, 
                                                 ValorPremiacaoLitroMeta__c, ValorPremiacaoLitroMetaSuperada__c*/ FROM PlanoIncentivo__c WHERE Id IN: planoIncentivoSetId]){
            if (planoIncentivo.Status__c == 'Encerrado'){
                mapIdToPlanoEncerrado.put(planoIncentivo.Id, planoIncentivo);
            } else if (planoIncentivo.Status__c == 'Em apuração'){
                mapIdToPlanoEmApuracao.put(planoIncentivo.Id, planoIncentivo);
            }
        }

        Set<string> invalidFieldsSet = new Set<String>{
            'Codigo__c',
            'DataFinal__c',
            'DataInicial__c',
            'Descricao__c',
            // 'Marco__c',
            // 'MesAno__c',
            'MinimoMeta__c',
            // 'PremiacaoFaturamentoLiquido__c',
            // 'PremiacaoInova__c',
            // 'PremiacaoLitro__c',
            'PremiacaoMeta__c',
            // 'PremiacaoSuperamentoMeta__c',
            'PremioAtingimento__c',
            'PremioMnimo__c',
            'PremioSuperacaoMeta__c',
            'SuperacaoMeta__c'/*,
            'ValorPremiacaoLitro__c',
            'ValorPremiacaoLitroMeta__c',
            'ValorPremiacaoLitroMetaSuperada__c',
            'AtingimentoMinimo__c'*/
        };
        
        for (PlanoIncentivo__c planoIncentivo : planoIncentivoList){
            if (mapIdToPlanoEncerrado.containsKey(planoIncentivo.Id)){
                planoIncentivo.addError('Plano de Incentivo já foi encerrado. Alterações indisponíveis.');
            }
            if (mapIdToPlanoEmApuracao.containsKey(planoIncentivo.Id)){
                PlanoIncentivo__c comparaPlano = mapIdToPlanoEmApuracao.get(planoIncentivo.Id);
                if (planoIncentivo.Status__c != 'Encerrado'){
                    planoIncentivo.addError('Plano de Incentivo está em apuração. Alterações indisponíveis.');
                } else{
                    SObject planNew = (SObject)planoIncentivo;
                    SObject planOld = (SObject)comparaPlano;
                    for(String field : invalidFieldsSet){                        
                        if (planNew.get(field) != planOld.get(field)){
                            planoIncentivo.addError('Esse registro possui alterações além das permitidas.');
                            break;
                        }
                    }
                }
            }
        }

    }
}