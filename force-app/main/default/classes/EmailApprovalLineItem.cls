global class EmailApprovalLineItem {
    global String  ProductName {get;set;}
    global Decimal Quantity {get;set;}
    global String PrecoVendasJurosBRLUSD {get;set;}
    global String Discount {get;set;}
    global String DescontoExcedente {get;set;}
    
    global EmailApprovalLineItem(OpportunityLineItem oppItem) {
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        this.ProductName 			= oppItem.Product2.Name;
        this.Quantity 				= oppItem.Quantity.setScale(0);
        this.PrecoVendasJurosBRLUSD = String.format(oppItem.PrecoVendasJurosBRLUSD__c.setScale(2).format(), args);
        this.Discount 				= String.format((oppItem.Discount != 0 ? oppItem.Discount*-1 : oppItem.Acrescimo__c).setScale(2).format(), args);
        this.DescontoExcedente 		= String.format(oppItem.DescontoExcedente__c.setScale(2).format(), args);
    }
}