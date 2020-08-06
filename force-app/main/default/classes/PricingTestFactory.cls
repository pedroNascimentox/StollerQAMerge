@TestVisible
public class PricingTestFactory {
    public static final String DEFAULT_ACCOUNT_TYPE  = 'ZC';

    public Regional__c region;
    public Account hierarchy;
    public Account account;
    public String accountType;
    public Product2 product;

    public PricingTestFactory(){
    }

    public Product2 fetchSimpleProduct(){
        if (this.product == null){
            this.product = (Product2) TestFactory.createSObject(new Product2(
                ExternalId__c = 'PROD2'
            ));
        }

        return this.product;
    }                    
    
    public Boolean hasProduct(){
        return (this.product != null);
    }                    
    
    public Regional__c fetchRegion(){
        if (this.region == null){
            this.region = (Regional__c) TestFactory.createSObject(new Regional__c(
                externalId__c = 'R001',
                NomeRegional__c = 'R001'
            ));
        }

        if (this.region.id == null){
            insert this.region;
        }

        return this.region;
    }    

    public Boolean hasRegion(){
        return (this.region != null);
    }                     
    
    public Account fetchAccount(){
        if (this.account == null){
            this.account = (Account) TestFactory.createSObject(new Account(
                listaPreco__c = 'Z1',
                recordTypeId = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            ));
        }

        return this.account;
    }    
    
    public Boolean hasAccount(){
        return (this.account != null);
    }             
            
    
    public Account fetchHierarchy(){
        if (this.hierarchy == null){
            this.hierarchy = (Account) TestFactory.createSObject(new Account(
                canaldistribuicao__c = '10',
                recordTypeId = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            ));
        }

        if (this.hierarchy.id == null){
            insert this.hierarchy;
        }

        return this.hierarchy;
    }   

    public Boolean hasType(){
        return (this.accountType != null);
    }                  

    public Boolean hasHierarchy(){
        return (this.hierarchy != null);
    }                        

    @TestVisible
    private Account getAccountWithRegion(){
        return this.addAccountRegion().fetchAccount();
    }
    
    @TestVisible
    private Account getAccountWithType(){
        return this.addAccountType().fetchAccount();
    }

    @TestVisible
    private PricingTestFactory addAccountRegion(){

        Regional__c region = fetchRegion();
        Account acc = fetchAccount();

        acc.regionalVendas__c = region.id;
        return this;
    }
    
    @TestVisible
    private PricingTestFactory addAccountType(){

        Account acc = fetchAccount();
        acc.tipoCliente__c = accountType = DEFAULT_ACCOUNT_TYPE;
        return this;
    }

    @TestVisible
    private PricingTestFactory addAccountHierarchy(){

        Account acc = fetchAccount();
        Account accountHierarchy = fetchHierarchy();

        acc.parentId = accountHierarchy.id;
        return this;
    }

}