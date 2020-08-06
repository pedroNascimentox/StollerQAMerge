public class OpportunityPDFController {
    
    public final Opportunity opportunity {get; set;}
    public String issueDate {get; set;}
    public String issueDateReplaced {get; set;}
    public String paymentCondition {get; set;}
    public String sinceDate {get; set;}
    public String untilDate {get; set;}
    public Boolean isVendor {get; set;}
    public Boolean isDolar {get; set;}
    public Boolean isSuframado {get; set;}
    public String dueDate {get; set;}
    public String totalAmount {get; set;}
    public String totalAmountWithoutIPI {get; set;}
    public List<OpportunityLineItemVO> items {get; set;}
    public String opportunityNumber {get; set;}
    public Boolean hideDueDate {get; set;}
    public String vendorDueDate {get; set;}
    // fix merge
    public Integer itemCounter {get; set;}

    public OpportunityPDFController() {

        String opportunityId = ApexPages.currentPage().getParameters().get('Id');

        System.debug('ApexPages.currentPage().getParameters() => ' + ApexPages.currentPage().getParameters());

        System.debug('opportunityId => ' + opportunityId);

        opportunity = [
            SELECT id, amount, valorTotalMercadoriasReal__c, valorTotalMercadoriasRealSemIPI__c, valorTotalMercadoriasDolar__c, 
            valorTotalMercadoriasDolarSemIPI__c, numeroOportunidade__c, account.name, account.localNegocio__r.name, account.emailComercial__c,
            account.billingStreet, account.billingCity, account.billingState, account.billingPostalCode, 
            account.shippingStreet, account.shippingCity, account.shippingState, account.shippingPostalCode, 
            account.cnpj__c, account.inscricaoEstadual__c, createdDate, tipoFrete__c, nomeFazenda__c, tipoOrdem__c, moeda__c,
            emailAprovacaoPedidoCliente__c, condicaoPagamento__r.descricao__c, condicaoPagamento__r.jurosComercialFinanceiro__c,
            condicaoPagamento__r.dataVigenciaDe__c, condicaoPagamento__r.dataVigenciaAte__c, nomeRTV__c, vencimentoVendor__c,
            observacaoPDF__c, localNegocio__r.descricao__c, account.suframa__c, dataVencimento__c, dataInicioJuros__c, campanha__c 
            FROM Opportunity
            WHERE id = :opportunityId
        ];

        opportunityNumber = String.valueOf(opportunity.numeroOportunidade__c).remove('OPT-');

        paymentCondition = opportunity.condicaoPagamento__r.descricao__c;
        isVendor = paymentCondition == 'Vendor'? true : false;
        System.debug('isVendor => ' + isVendor);
        issueDate = opportunity.createdDate.date().format();
        System.debug('issueDate => ' + issueDate);
        issueDateReplaced = issueDate.replace(' ', ' às ');
        dueDate = isVendor? (opportunity.campanha__c == null? (opportunity.vencimentoVendor__c != null? opportunity.vencimentoVendor__c.format() : '' ) : (opportunity.dataInicioJuros__c != null? opportunity.dataInicioJuros__c.format() : '')) : opportunity.dataVencimento__c != null? opportunity.dataVencimento__c.format() : '' ;
        System.debug('dueDate => ' + dueDate);
        isDolar = opportunity.moeda__c == 'BRL'? false : true;
        System.debug('isDolar => ' + isDolar);
        isSuframado = opportunity.account.suframa__c != null? true : false;
        System.debug('isSuframado => ' + isSuframado);
        totalAmount = isDolar? getFormattedValue(opportunity.valorTotalMercadoriasDolar__c) : getFormattedValue(opportunity.valorTotalMercadoriasReal__c);
        System.debug('totalAmount => ' + totalAmount);
        totalAmountWithoutIPI = isDolar? getFormattedValue(opportunity.valorTotalMercadoriasDolarSemIPI__c) : getFormattedValue(opportunity.valorTotalMercadoriasRealSemIPI__c);
        System.debug('totalAmountWithoutIPI => ' + totalAmountWithoutIPI);
        vendorDueDate = (opportunity.vencimentoVendor__c != null? opportunity.vencimentoVendor__c.format() : '' );
        System.debug('vendorDueDate => ' + vendorDueDate);

        if(opportunity.dataInicioJuros__c == null && opportunity.campanha__c == null){
            hideDueDate = true;
        } else {
            hideDueDate = false;
        }

        if(isVendor){

            hideDueDate = opportunity.campanha__c != null? false : true;

            sinceDate = opportunity.dataInicioJuros__c != null? opportunity.dataInicioJuros__c.format() : '';
            System.debug('sinceDate => ' + sinceDate);
            untilDate = opportunity.vencimentoVendor__c != null? opportunity.vencimentoVendor__c.format() : '';
            System.debug('untilDate => ' + untilDate);
        
        }

        System.debug('opportunity => ' + opportunity);

        List<OpportunityLineItem> lineItems = [
            SELECT id, product2.name, product2.description, product2.sku__c, description, product2.embalagem__c,
            quantity, litros__c, unitPrice, precoLitro__c, totalPrice, numeroPedidoCliente__c, totalItemComJuros__c,
            valorIPI__c, totalItemComJurosUSD__c, valorTotalIPIDolar__c, precoVendasJuros__c, precoLitroUSD__c, precoVendasJurosUSD__c, PrecoVendasJurosBRLUSD__c
            FROM OpportunityLineItem
            WHERE opportunityId = :opportunityId
            ORDER BY product2.description ASC
        ];

        items = new List<OpportunityLineItemVO>();

        itemCounter = 0;

        for(OpportunityLineItem item : lineItems){

            OpportunityLineItemVO itemVO = new OpportunityLineItemVO(item, isDolar);
            itemVO.itemNumber(itemCounter + 1);

            itemCounter++;

            System.debug('item.product2.name => ' + item.product2.name);
            System.debug('itemVO.productName => ' + itemVO.productName);

            // itemVO.verifyLength();

            items.add(itemVO);
        }

    }

    public class OpportunityLineItemVO {
        
        public String  id                           {get; set;}
        public String  productName                  {get; set;}
        public String  sku                          {get; set;}
        public String  productDescription           {get; set;}
        public String  emabalagem                   {get; set;}
        public String  quantity                     {get; set;}
        public String  liters                       {get; set;}
        public String  unitPrice                    {get; set;}
        public String  pricePerLiter                {get; set;}
        public String  totalPrice                   {get; set;}
        public String  IPIvalue                     {get; set;}
        public String  customerOrderNumber          {get; set;}
        public Boolean totalPriceFontSizeSmaller    {get; set;}
        public Boolean unitPriceFontSizeSmaller     {get; set;}
        public Boolean pricePerLiterFontSizeSmaller {get; set;}
        public Integer itemNumber                   {get; set;}
        public String  salesPriceWithInterest       {get; set;}

        public OpportunityLineItemVO(OpportunityLineItem item, Boolean isDolar){
            this.id                     = item.id;
            this.productName            = item.product2.name;
            this.sku                    = item.product2.sku__c.isNumeric()? String.valueOf(Integer.valueOf(item.product2.sku__c)) : item.product2.sku__c;
            this.productDescription     = item.product2.description;
            this.emabalagem             = item.product2.embalagem__c;
            this.quantity               = item.quantity.format();
            this.liters                 = item.litros__c != null? item.litros__c.format() : '0';
            this.unitPrice              = OpportunityPDFController.getFormattedValue(item.PrecoVendasJurosBRLUSD__c);
            this.pricePerLiter          = item.precoLitro__c != null? OpportunityPDFController.getFormattedValue(item.precoLitro__c) : '0';
            this.totalPrice             = OpportunityPDFController.getFormattedValue(item.totalItemComJuros__c);
            this.IPIvalue               = OpportunityPDFController.getFormattedValue(item.valorIPI__c);
            this.salesPriceWithInterest = OpportunityPDFController.getFormattedValue(item.precoVendasJuros__c);

            if(isDolar){
                this.pricePerLiter          = OpportunityPDFController.getFormattedValue(item.precoLitroUSD__c);
                this.totalPrice             = OpportunityPDFController.getFormattedValue(item.totalItemComJurosUSD__c);
                this.IPIvalue               = OpportunityPDFController.getFormattedValue(item.valorTotalIPIDolar__c);
                this.salesPriceWithInterest = OpportunityPDFController.getFormattedValue(item.precoVendasJurosUSD__c);
            }

            this.customerOrderNumber = item.numeroPedidoCliente__c;
        }

        public void verifyLength(){
            
            System.debug('this.totalPrice => ' + this.totalPrice);
            if(this.totalPrice != null && this.totalPrice.length() > 13){
                System.debug('this.totalPrice.length() => ' + this.totalPrice.length());
                this.totalPriceFontSizeSmaller = true;
            } 
            
            System.debug('this.unitPrice => ' + this.unitPrice);
            if(this.unitPrice != null && this.unitPrice.length() > 11){
                System.debug('this.unitPrice.length() => ' + this.unitPrice.length());
                this.unitPriceFontSizeSmaller = true;
            } 
            
            System.debug('this.pricePerLiter => ' + this.pricePerLiter);
            if(this.pricePerLiter != null && this.pricePerLiter.length() > 7){
                System.debug('this.pricePerLiter.length() => ' + this.pricePerLiter.length());
                this.pricePerLiterFontSizeSmaller = true;
            }

        }

        public void itemNumber(Integer i){
            this.itemNumber = i;
        }
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