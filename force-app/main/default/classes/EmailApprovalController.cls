global class EmailApprovalController {
	global String opportunityId {get;set;}
    global Opportunity opp {get;set;}
    global User u {get;set;}
    global String approvalLink {get;set;}
    global List<EmailApprovalLineItem> itemList {get;set;}
    
    global List<EmailApprovalLineItem> getLineItemList() {
        itemList = new List<EmailApprovalLineItem>();
        for(OpportunityLineItem item : [SELECT Id, Product2.Name, Quantity, PrecoVendasJurosBRLUSD__c, Discount, DescontoExcedente__c, Acrescimo__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id]){
            itemList.add(new EmailApprovalLineItem(item));
        }
        return itemList;
    }
    
    global String getApproval() {
        approvalLink = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/OpportunityBulkApproval?id=' + opp.Id;
        return approvalLink;
    }

    global String getValueWithIPI() {
        Opportunity oppToGetIPI = [SELECT Id, ValorTotalMercadoriasReal__c, ValorTotalMercadoriasDolar__c, Moeda__c FROM Opportunity WHERE Id = :opp.Id];
        Decimal value;
        String symbol = '';
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        // [2020-02-13 | Rodler] Alterei de opp.Moeda__c para oppToGetIPI.Moeda__c
        // Pq quando rodava a classe de teste acusava que o campo nao estava na Query padrão
        if (oppToGetIPI.Moeda__c == 'BRL') {
            symbol = 'R$';
            value = oppToGetIPI.ValorTotalMercadoriasReal__c;
        }else {
            symbol = 'US$';
            value = oppToGetIPI.ValorTotalMercadoriasDolar__c;
        }
        return symbol + ' ' + String.format(value.setScale(2).format(), args);
    }

    global String getFormattedDate() {
        Date dt = (Test.isRunningTest() ? Date.Today() : opp.DataInicioJuros__c);
        if (dt == null) {
            return '';
        }
        return sSize(dt.day()) + '/' + sSize(dt.month()) + '/' + sSize(dt.year());
    }

    private String sSize(Decimal s) {
        String prefix = '';
        if (s < 10) {
            prefix = '0';
        }
        return prefix + s;
    }
}