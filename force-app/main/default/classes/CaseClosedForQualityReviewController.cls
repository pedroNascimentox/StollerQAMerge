global class CaseClosedForQualityReviewController {

    global Case caseRecord {get; set;}
    global List<AssociacaoPedidoReclamacao__c> associacaoPedidoRecList {get; set;}

    global List<AssociacaoPedidoReclamacao__c> getAssociacaoPedidoReclamacaoList(){
        
        System.debug('caseRecord => ' + caseRecord);
        
        associacaoPedidoRecList = new List<AssociacaoPedidoReclamacao__c>();

        for(AssociacaoPedidoReclamacao__c associacaoPedidoReclamacao : [SELECT id, Name, Procedimento_de_Reclama_o__c, N_Pedido__c, Produto__c, Produto__r.name, Embalagem__c, Quantidade__c, Valor_unit_rio__c, Valor_Total__c FROM AssociacaoPedidoReclamacao__c WHERE reclamacao__c = :caseRecord.id]){
            associacaoPedidoRecList.add(associacaoPedidoReclamacao);
        }

        return associacaoPedidoRecList;
    }

    global String getReasonLabel(){
        return [SELECT toLabel(reason) FROM Case WHERE id = :caseRecord.id].reason;
    }

}