global class EmailApprovalDeliveryCLineItem {
    global String  ProductName {get;set;}
    global String  Packing {get;set;}
    global Decimal Quantity {get;set;}
    global String  PrecoVendasJurosBRLUSD {get;set;}
    global String  TotalValue {get;set;}
    global Date  OriginalDate {get;set;}
    global Date  NewDate {get;set;} 
    
    global EmailApprovalDeliveryCLineItem(AlteracaoDataEntregaItem__c deliveryItem) {
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        this.ProductName 			= deliveryItem.Produto__r.Name;
        this.Packing 			    = deliveryItem.Produto__r.Embalagem__c;
        this.Quantity 				= deliveryItem.QuantidadeAlterada__c.setScale(0);
        this.PrecoVendasJurosBRLUSD = String.format(deliveryItem.ItemPedido__r.ValorUnitarioComJuros__c.setScale(2).format(), args);
        this.TotalValue 			= String.format(deliveryItem.Valor__c.setScale(2).format(), args);
        this.OriginalDate 			= deliveryItem.DataEntregaOriginal__c;
        this.NewDate 			    = deliveryItem.DataEntregaNova__c;
    }

    /*global String getFormattedDateVP(DateTime dt) {
        if (dt == null) {
            return '';
        }
        return sSize(dt.day()) + '/' + sSize(dt.month()) + '/' + sSize(dt.year());
    }*/

    private String sSize(Decimal s) {
        String prefix = '';
        if (s < 10) {
            prefix = '0';
        }
        return prefix + s;
    }
}