public class ProductAppData {

    public String                id;    
    public String                name;
    public String                sku;
    public String                pbEntry;
    public Decimal               priceList;
    public Decimal               liter;
    public Decimal               multiplicity;
    public Boolean               recent;
    public Decimal               maxDiscount;
    public Decimal               minimumDiscount;
    public Decimal               recommendedDiscount;
    public Decimal               customerTypeDiscount;
    public Decimal               freightPercentage;
    public Decimal               customerTypeDiscountValue;
    public Decimal               freightValue;
    public Integer               internalDeadlineDays;
    public Integer               itineraryDays;
    public Id[]                  cultureIds;
    public ProductDetailsAppData details;
    public String                discountPolicyId;
    public String                priceEntryId;
    public String                shippingTableId;
    public String                customerTypeDiscountId;
    public Decimal               priceFromTable;
    public String                initialDate;
    public String                finishDate;
    public Decimal               ipiPercentage;

    public ProductAppData(){}

    public ProductAppData(Product2 product, String pricebookEntryId, Decimal price, Decimal discountByCustomerType, Decimal freightValue, ProductDetailsAppData productDetailsAppData){
        this.id                         = product.id;
        this.pbEntry                    = pricebookEntryId;
        this.name                       = product.name;
        this.sku                        = product.sku__c;

        Decimal discountClient          = discountByCustomerType / 100;
        // discountClient                  = discountClient.setScale(2, RoundingMode.HALF_UP);
        Decimal percentClient           = price * discountClient;
        // percentClient                   = percentClient.setScale(2, RoundingMode.HALF_UP);
        this.priceList                  = (price - percentClient);

        Decimal freightPercentage       = freightValue / 100;
        // freightPercentage               = freightPercentage.setScale(2, RoundingMode.HALF_UP);
        Decimal percentFreightClient    = this.priceList * freightPercentage;
        // percentFreightClient            = percentFreightClient.setScale(2, RoundingMode.HALF_UP);

        this.priceList                  = this.priceList + percentFreightClient;
        this.priceList                  = this.priceList.setScale(2, RoundingMode.HALF_UP);

        this.liter                      = product.litragem__c;
        this.multiplicity               = product.multiplicidade__c;
        this.recent                     = productDetailsAppData == null? false : true;
        this.maxDiscount                = 0;
        this.minimumDiscount            = 0;
        this.recommendedDiscount        = 0;
        this.details                    = productDetailsAppData;
    }

    public void setProductData(Product2 product){
        this.id            = product.id;
        this.name          = product.name;
        this.sku           = product.sku__c;
        this.liter         = product.litragem__c;
        this.multiplicity  = product.multiplicidade__c;
        this.ipiPercentage = product.ipi__c;
    }

    public void setPricebookEntry(String pricebookEntryId){
        this.pbEntry = pricebookEntryId;
    }

    public void setPriceList(Decimal price, Decimal discountByCustomerType, Decimal freightValue){
        this.freightPercentage          = freightValue;
        this.customerTypeDiscount       = discountByCustomerType;
        Decimal discountClient          = discountByCustomerType / 100;
        Decimal percentClient           = price * discountClient;
        // percentClient                   = percentClient.setScale(2, RoundingMode.HALF_UP);
        this.priceList                  = (price - percentClient);
        // this.priceList                  = this.priceList.setScale(2, RoundingMode.HALF_UP);
        Decimal freightPercentage       = freightValue / 100;
        Decimal percentFreightClient    = this.priceList * freightPercentage;
        // percentFreightClient            = percentFreightClient.setScale(2, RoundingMode.HALF_UP);
        this.priceList                  = this.priceList + percentFreightClient;
        this.priceList                  = this.priceList.setScale(2, RoundingMode.HALF_UP);
        this.customerTypeDiscountValue  = percentClient;
        this.freightValue               = percentFreightClient;
        this.priceFromTable             = price;
    }

    public void setProductDetails(ProductDetailsAppData productDetailsAppData){
        this.recent  = productDetailsAppData == null? false : true;
        this.details = productDetailsAppData;
    }

    public void setCultures(CulturaProduto__c[] cultureRecords){
        if (cultureRecords != null){
            List<Id> cultures = Collection.of(cultureRecords).pluckIds(CulturaProduto__c.cultura__c);

            this.cultureIds = new List<Id>(cultures);
        } else {
            this.cultureIds = new List<Id>();
        }
    }

    public void setDiscountPolicyDataToProduct(DiscountPolicyServiceData discountPolicyData){
        this.maxDiscount         = discountPolicyData.maxDiscount;
        this.minimumDiscount     = discountPolicyData.minimumDiscount;
        this.recommendedDiscount = discountPolicyData.recommendedDiscount;
        this.discountPolicyId    = discountPolicyData.discountPolicyId;
        this.initialDate         = discountPolicyData.initialDate;
        this.finishDate          = discountPolicyData.finishDate;
    }

    public void setReferences(Id priceEntryId, Id shippingTableId, Id customerTypeDiscountId){
        this.priceEntryId           = priceEntryId;
        this.shippingTableId        = shippingTableId;
        this.customerTypeDiscountId = customerTypeDiscountId;
    }

    public void setInternalDeadlineDays(Integer numberOfDays){
        this.internalDeadlineDays = numberOfDays;
    }

    public void setItineraryDays(Integer itineraryDays){
        this.itineraryDays = itineraryDays;
    }

}