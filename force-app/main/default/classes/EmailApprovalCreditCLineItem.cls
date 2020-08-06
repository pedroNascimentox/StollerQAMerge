global class EmailApprovalCreditCLineItem {
    global String  ProductName {get;set;}
    global String  Packing {get;set;}
    global Decimal Quantity {get;set;}
    global String  PrecoVendasJurosBRLUSD {get;set;}
    global String  TotalValue {get;set;}
    global Date  deliveryDate {get;set;}
    global Date  fatDate {get;set;}
    
    global EmailApprovalCreditCLineItem(ProgramacaoEntrega__c deliveryItem) {
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        this.ProductName 			= deliveryItem.Produto__r.Name;
        this.Packing 			    = deliveryItem.Produto__r.Embalagem__c;
        this.Quantity 				= deliveryItem.QuantidadeProgramada__c.setScale(0);
        this.PrecoVendasJurosBRLUSD = String.format(deliveryItem.PrecoVendasComJurosUSDBRL__c.setScale(2).format(), args);
        this.TotalValue 			= String.format(deliveryItem.ValorTotalReaisDolar__c.setScale(2).format(), args);
        this.deliveryDate 			= date.valueOf(deliveryItem.DataEntrega__c);
        this.fatDate 			    = date.valueOf(deliveryItem.DataFaturamento__c);
    }

    global String getFormattedDateVP(DateTime dt) {
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