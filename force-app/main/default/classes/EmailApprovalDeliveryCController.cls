global class EmailApprovalDeliveryCController {
    global AlteracaoDataEntrega__c del {get;set;}
    global User u {get;set;}
    global String approvalLink {get;set;}
    global List<EmailApprovalDeliveryCLineItem> itemList {get;set;}
    
    global List<EmailApprovalDeliveryCLineItem> getLineItemList() {
        itemList = new List<EmailApprovalDeliveryCLineItem>();
        for(AlteracaoDataEntregaItem__c item : [SELECT Id, Produto__r.Name, QuantidadeProgramada__c, ItemPedido__r.ValorUnitarioComJuros__c, Produto__r.Embalagem__c, Moeda__c, Valor__c, DataEntregaOriginal__c, DataEntregaNova__c, QuantidadeAlterada__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c = :del.Id]){
            itemList.add(new EmailApprovalDeliveryCLineItem(item));
        }
        return itemList;
    }
    
    global String getApproval() {
        approvalLink = null;
        List<ProcessInstance> pI = [SELECT Id, ProcessDefinitionId, TargetObjectId, SubmittedById FROM ProcessInstance WHERE TargetObjectId = :del.Id AND Status = 'Pending' LIMIT 1];
        if(pI.size() > 0) {
            List<ProcessInstanceWorkitem> pIW = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :pI[0].Id LIMIT 1];
            if(pIW.size() > 0) {
                approvalLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + pIW[0].Id;
            }
        }
        return approvalLink;
    }

    global String getSumValues() {
        Decimal value = 0;
        String m = [SELECT Id, Moeda__c FROM AlteracaoDataEntrega__c WHERE Id = :del.Id].Moeda__c;
        for(AlteracaoDataEntregaItem__c s : [SELECT Id, Valor__c, Moeda__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c = :del.Id]) {
            value +=  s.Valor__c;
        }
        String symbol = '';
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        if (m == 'BRL') {
            symbol = 'R$';
        }else {
            symbol = 'US$';
        }
        return symbol + ' ' + String.format(value.setScale(2).format(), args);
    }
}