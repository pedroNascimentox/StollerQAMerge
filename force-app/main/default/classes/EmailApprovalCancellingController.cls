global class EmailApprovalCancellingController {
    global SolicitacaoCancelamento__c canc {get;set;}
    global User u {get;set;}
    global String approvalLink {get;set;}
    global List<EmailApprovalCancellingLineItem> itemList {get;set;}
    
    global List<EmailApprovalCancellingLineItem> getLineItemList() {
        itemList = new List<EmailApprovalCancellingLineItem>();
        for(Cancelamento__c item : [SELECT Id, Produto__r.Name, QuantidadeProgramada__c, ValorUnitario__c, Produto__r.Embalagem__c, Moeda__c, ValorTotal__c, ValorTotalUSD__c FROM Cancelamento__c WHERE SolicitacaoCancelamento__c = :canc.Id]){
            itemList.add(new EmailApprovalCancellingLineItem(item));
        }
        return itemList;
    }
    
    global String getApproval() {
        approvalLink = null;
        List<ProcessInstance> pI = [SELECT Id, ProcessDefinitionId, TargetObjectId, SubmittedById FROM ProcessInstance WHERE TargetObjectId = :canc.Id AND Status = 'Pending' LIMIT 1];
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
        Decimal valueUSD = 0;
        String m = [SELECT Id, ValorTotal__c, Moeda__c FROM SolicitacaoCancelamento__c WHERE Id = :canc.Id].Moeda__c;
        for(Cancelamento__c s : [SELECT Id, ValorTotal__c, ValorTotalUSD__c, Moeda__c FROM Cancelamento__c WHERE SolicitacaoCancelamento__c = :canc.Id]) {
            value +=  s.ValorTotal__c;
            valueUSD +=  s.ValorTotalUSD__c;
        }
        String symbol = '';
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        if (m == 'BRL') {
            symbol = 'R$';
        }else {
            value  = valueUSD;
            symbol = 'US$';
        }
        return symbol + ' ' + String.format(value.setScale(2).format(), args);
    }
}