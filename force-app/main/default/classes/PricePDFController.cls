public class PricePDFController {
    
    public List<PdfPriceResult> items  {get; set;}
    public Boolean isDollar {get;set;}
    public Document document {get;set;}

    public PricePDFController() {
        
        this.isDollar = false;

        Id documentId = ApexPages.currentPage().getParameters().get('id');

        Document targetDocument = [
            SELECT 
                body
            FROM Document
            WHERE id = :documentId
        ];

        this.document = targetDocument;

        OpportunityAppReturnedData content = (OpportunityAppReturnedData) JSON.deserialize(targetDocument.body.toString(), OpportunityAppReturnedData.class);

        this.items = new PdfPriceResult[]{};
        this.isDollar = content.data.currencyName == 'USD' ? true : false;
        for(ProductAppData productData : content.data.productsData){
            this.items.add(new PdfPriceResult(productData));
        }

    }

    public void deleteDocument(){
        delete this.document;
    }

    public class PdfPriceResult{
      
        public String               sku                       {get;set;}
        public String               name                      {get;set;}
        public Decimal              liter                     {get;set;}
        public String               priceList                 {get;set;}
        public String               multiplicity              {get;set;}
        public String               maxDiscount               {get;set;}
        public String               minimumDiscount           {get;set;}
        public String               recommendedDiscount       {get;set;}
        public String               customerTypeDiscount      {get;set;}
        public String               freightPercentage         {get;set;}
        public String               customerTypeDiscountValue {get;set;}
        public String               freightValue              {get;set;}
        public String               priceFromTable            {get;set;}
        public String               ipiPercentage             {get;set;}

        public Boolean priceListFontSizeSmaller     {get; set;}

        public PdfPriceResult(ProductAppData productResult){
            this.sku                       = productResult.sku;
            this.name                      = productResult.name;
            this.liter                     = productResult.liter;
            this.priceList                 = OpportunityPDFController.getFormattedValue(productResult.priceList);
            this.multiplicity              = OpportunityPDFController.getFormattedValue(productResult.multiplicity);
            this.maxDiscount               = OpportunityPDFController.getFormattedValue(productResult.maxDiscount);
            this.minimumDiscount           = OpportunityPDFController.getFormattedValue(productResult.minimumDiscount);
            this.recommendedDiscount       = OpportunityPDFController.getFormattedValue(productResult.recommendedDiscount);
            this.customerTypeDiscount      = OpportunityPDFController.getFormattedValue(productResult.customerTypeDiscount);
            this.freightPercentage         = OpportunityPDFController.getFormattedValue(productResult.freightPercentage);
            this.customerTypeDiscountValue = OpportunityPDFController.getFormattedValue(productResult.customerTypeDiscountValue);
            this.freightValue              = OpportunityPDFController.getFormattedValue(productResult.freightValue);
            this.priceFromTable            = OpportunityPDFController.getFormattedValue(productResult.priceFromTable);
            this.ipiPercentage             = OpportunityPDFController.getFormattedValue(productResult.ipiPercentage);

            this.verifyLength();
        }

        public Boolean verifyLength(){
            return this.priceListFontSizeSmaller = (this.priceList != null && this.priceList.length() > 11);
        }
    }
}