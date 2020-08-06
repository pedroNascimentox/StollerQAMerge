public class OpportunityAppControllerTestFactory {

    public Account        account;
    public List<Product2> products;
    
    public OpportunityAppControllerTestFactory(){
        products = new List<Product2>();
    }

    public Account fetchAccount(){
        if (this.account == null){
            this.account = (Account) TestFactory.createSObject(new Account(
                listaPreco__c = '123'
            ));
        }

        return this.account;
    }

    public Product2 fetchSimpleProduct(){
        System.debug('this.products.size() => ' + this.products.size());
        Product2 product = (Product2) TestFactory.createSObject(
            new Product2(
                externalId__c     = 'PROD' + this.products.size(),
                litragem__c       = (this.products.size() + 1) * 10,
                sku__c            = 'SKUPROD' + this.products.size(),
                multiplicidade__c = this.products.size() + 1
            )
        );

        return product;
    }

    public Product2 addSimpleProduct(){
        this.products.add(fetchSimpleProduct());
        return this.products.get(this.products.size()-1);
    }

    // public List<Product2> addSimpleProducts(Integer numberOfProductsToCreate){

    //     for(Integer i = 0; i <= numberOfProductsToCreate; i++){
    //         this.products.add(fetchSimpleProduct());
    //     }

    //     return this.products;
    // }

}