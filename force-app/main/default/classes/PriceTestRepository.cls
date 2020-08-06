public class PriceTestRepository {
    private TabelaPreco__c priceList;
    private Boolean isClientSpecific;
    private PricingTestFactory pricingTestFactory;

    @TestVisible
    private PriceTestRepository(PricingTestFactory pricingTestFactory){
        this.pricingTestFactory = pricingTestFactory;
        this.isClientSpecific = false;
    }

    public PriceTestRepository isClientSpecific(Boolean s){
        this.isClientSpecific = s;
        return this;
    }

    @TestVisible
    private TabelaPreco__c getRecord(){
        if (this.priceList == null){
            this.priceList = (TabelaPreco__c) TestFactory.createSObject(new TabelaPreco__c(
                externalId__c = GuidGenerator.generate(),
                organizacaoVenda__c = '1000', 
                hierarquiaCliente__c = pricingTestFactory.hasHierarchy()? pricingTestFactory.fetchHierarchy().id : null,
                listaPreco__c = pricingTestFactory.fetchAccount().listaPreco__c,
                tipoCliente__c = pricingTestFactory.fetchAccount().tipoCliente__c,
                regional__c = pricingTestFactory.hasRegion()? pricingTestFactory.fetchRegion().id : null,
                cliente__c = this.isClientSpecific? pricingTestFactory.fetchAccount().id : null
            ));
        
            this.priceList.hierarquiaCliente__c = pricingTestFactory.hasHierarchy()? pricingTestFactory.fetchHierarchy().id : null;
            this.priceList.listaPreco__c        = pricingTestFactory.fetchAccount().listaPreco__c;
            this.priceList.tipoCliente__c       = pricingTestFactory.fetchAccount().tipoCliente__c;
            this.priceList.regional__c          = pricingTestFactory.hasRegion()? pricingTestFactory.fetchRegion().id : null;
            this.priceList.cliente__c           = this.isClientSpecific? pricingTestFactory.fetchAccount().id : null;
        }

        return this.priceList;
    }

    @TestVisible
    private TabelaPreco__c addEntry(Id productId){
        this.getRecord();
        this.priceList.produto__c = productId;
        return this.priceList;
    }
}