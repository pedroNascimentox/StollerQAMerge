global class CaseClosedForComplainController {

    global Case caseRecord {get; set;}
    global List<AssociacaoPedidoReclamacao__c> associacaoPedidoRecList {get; set;}
    global String caseTotalValue {get; set;}

    global List<AssociacaoPedidoReclamacao__c> getAssociacaoPedidoReclamacaoList(){
        
        System.debug('caseRecord => ' + caseRecord);
        
        associacaoPedidoRecList = new List<AssociacaoPedidoReclamacao__c>();

        Decimal caseTotalValueAux = 0;

        for(AssociacaoPedidoReclamacao__c associacaoPedidoReclamacao : [SELECT id, Name, Procedimento_de_Reclama_o__c, N_Pedido__c, Produto__c, Produto__r.name, Embalagem__c, Quantidade__c, Valor_unit_rio__c, Valor_Total__c FROM AssociacaoPedidoReclamacao__c WHERE reclamacao__c = :caseRecord.id]){
            associacaoPedidoRecList.add(associacaoPedidoReclamacao);
            caseTotalValueAux += associacaoPedidoReclamacao.valor_total__c;
        }

        caseTotalValue = getFormattedValue(caseTotalValueAux);

        return associacaoPedidoRecList;
    }

    public static String getFormattedValue(Decimal value){

        System.debug('value => ' + value);

        if(value == null){
            return '';
        }

        String result = value.setScale(2, System.RoundingMode.HALF_UP).format();
        
        if(!result.contains(',')){
            result = result + ',00';
        } else {
            result = result.substringAfter(',').length() == 2? result : result + '0';
        }

        System.debug('result => ' + result);

        return result;
    }

}