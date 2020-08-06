public class AssociacaoPedidoReclamacaoHelper extends TriggerContext {
    
    public static void fillApprovers(List<AssociacaoPedidoReclamacao__c> newContext){
        
        List<Id> caseIds = Collection.of(newContext).pluckIds(AssociacaoPedidoReclamacao__c.Reclamacao__c);

        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT id, account.gerenteRegional__c, account.diretorComercial__c
            FROM Case
            WHERE id IN :caseIds
            AND (
                   account.gerenteRegional__c != null
                OR account.diretorComercial__c != null
            )
        ]);
        
        for(AssociacaoPedidoReclamacao__c associacaoPedidoReclamacao : newContext){
            if(caseMap.containsKey(associacaoPedidoReclamacao.Reclamacao__c)){
                associacaoPedidoReclamacao.gerenteRegional__c  = caseMap.get(associacaoPedidoReclamacao.Reclamacao__c).account.gerenteRegional__c;
                associacaoPedidoReclamacao.diretorComercial__c = caseMap.get(associacaoPedidoReclamacao.Reclamacao__c).account.diretorComercial__c;
            }
        }
    }

}