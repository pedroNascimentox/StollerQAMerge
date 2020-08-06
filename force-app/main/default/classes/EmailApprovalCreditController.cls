global class EmailApprovalCreditController {
    global Opportunity del {get;set;}
    global User u {get;set;}
    global String approvalLink {get;set;}
    global List<EmailApprovalCreditCLineItem> itemList {get;set;}
    
    global List<EmailApprovalCreditCLineItem> getLineItemList() {
        itemList = new List<EmailApprovalCreditCLineItem>();
        for(ProgramacaoEntrega__c item : [SELECT Name, Id, Produto__r.Name, ValorTotalReaisDolar__c, QuantidadeProgramada__c, Produto__r.Embalagem__c, PrecoVendasComJurosUSDBRL__c, ValorTotal__c, Dataentrega__c, DataFaturamento__c 
                                          FROM ProgramacaoEntrega__c 
                                          WHERE IdOportunidade__c = :del.Id
                                          AND Status__c =  'Em aprovação de crédito']){
            itemList.add(new EmailApprovalCreditCLineItem(item));
        }
        return itemList;
    }
    global String getoppAccountCredit(){
        for(Account acc : [SELECT id, LimiteCreditoTotal__c, SaldoLimiteCredito__c FROM Account WHERE id = : del.AccountId]){
            return String.valueOf(acc.SaldoLimiteCredito__c);
        }
        return '';
    }
    global List<String> getNumberList() {
        List<String> numberList = new List<String>();
        for(ProgramacaoEntrega__c item : [SELECT Name, Id, Produto__r.Name, QuantidadeProgramada__c, Produto__r.Embalagem__c, PrecoVendasComJurosUSDBRL__c, ValorTotal__c, Dataentrega__c, DataFaturamento__c 
                                          FROM ProgramacaoEntrega__c 
                                          WHERE IdOportunidade__c = :del.Id
                                          AND Status__c =  'Em aprovação de crédito']){
            numberList.add(item.Name + ', ');
        }
        return numberList;
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
        String m = [SELECT Id, Moeda__c FROM Opportunity WHERE Id = :del.Id].Moeda__c;
        for(ProgramacaoEntrega__c s : [SELECT Id, ValorTotalReaisDolar__c, Moeda__c FROM ProgramacaoEntrega__c WHERE IdOportunidade__c = :del.Id AND Status__c =  'Em aprovação de crédito' ]) {
            value +=  s.ValorTotalReaisDolar__c;
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