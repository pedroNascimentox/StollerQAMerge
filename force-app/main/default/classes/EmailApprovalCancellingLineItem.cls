global class EmailApprovalCancellingLineItem {
    global String  ProductName {get;set;}
    global String  Packing {get;set;}
    global Decimal Quantity {get;set;}
    global String  PrecoVendasJurosBRLUSD {get;set;}
    global String  TotalValue {get;set;}
    
    global EmailApprovalCancellingLineItem(Cancelamento__c cancellingItem) {
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        Decimal totalValue = cancellingItem.ValorTotal__c;
        if(cancellingItem.moeda__c == 'USD') {
            totalValue = cancellingItem.ValorTotalUSD__c;
        }
        this.ProductName 			= cancellingItem.Produto__r.Name;
        this.Packing 			    = cancellingItem.Produto__r.Embalagem__c;
        this.Quantity 				= cancellingItem.QuantidadeProgramada__c.setScale(0);

        Decimal precoUSDBRL = cancellingItem.ValorTotal__c / cancellingItem.QuantidadeProgramada__c;

        this.PrecoVendasJurosBRLUSD = String.format(precoUSDBRL.setScale(2).format(), args);
        this.TotalValue 			= String.format(totalValue.setScale(2).format(), args);
    }
}