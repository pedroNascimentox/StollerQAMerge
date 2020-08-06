@isTest
public with sharing class IntegrationInboundProduct2Test {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        // List<Cultura__c> culturaList = new List<Cultura__c>();
        // Cultura__c cultura1 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura1;
        // culturaList.add(cultura1);

        // Cultura__c cultura2 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura2;
        // culturaList.add(cultura2);

        Product2 produtoSustituto = (Product2)TestFactory.createSObject(new Product2());
        insert produtoSustituto;

        lookups.put(produtoSustituto.Id, produtoSustituto.ExternalId__c);
        
        Product2 product1 = (Product2)TestFactory.createSObject(new Product2(
            ProdutoSubstituto__c = produtoSustituto.Id
        ));
        Product2 productError = (Product2)TestFactory.createSObject(new Product2());
        productError.Description = null;

        List<String> atributoDefensivos = new List<String>{'test'};

        TemplateDataIntegrationFields.Product2INData deserializedProduct1 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, /*culturaList, */atributoDefensivos);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct1}));
        IntegrationInboundProduct2.parseRequest();
        
        TemplateDataIntegrationFields.Product2INData deserializedProductError = new TemplateDataIntegrationFields.Product2INData(productError, lookups, /*new List<Cultura__c>(), */atributoDefensivos);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProductError}));
        IntegrationInboundProduct2.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundProduct2.parseRequest();
        
        // Cultura__c cultura3 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // culturaList.add(cultura3);
        // Cultura__c cultura4 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // culturaList.add(cultura4);

        // TemplateDataIntegrationFields.Product2INData deserializedProduct2 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct2});

        // culturaList.remove(culturaList.size() - 1);
        // culturaList.remove(culturaList.size() - 1);
        // culturaList.remove(culturaList.size() - 1);

        // Cultura__c cultura5 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura5;
        // culturaList.add(cultura5);

        // TemplateDataIntegrationFields.Product2INData deserializedProduct3 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct3});

        // culturaList.clear();

        // TemplateDataIntegrationFields.Product2INData deserializedProduct4 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct4});

        List<Product2> receivedProducts = [SELECT Id FROM Product2 WHERE ExternalId__c = :product1.ExternalId__c OR ExternalId__c = :productError.ExternalId__c];

        System.assertEquals(1, receivedProducts.size());

    }
    @isTest
    public static void testNewField() {

        Map<Id, String> lookups = new Map<Id, String>();

        // List<Cultura__c> culturaList = new List<Cultura__c>();
        // Cultura__c cultura1 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura1;
        // culturaList.add(cultura1);

        // Cultura__c cultura2 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura2;
        // culturaList.add(cultura2);

        Product2 produtoSustituto = (Product2)TestFactory.createSObject(new Product2());
        insert produtoSustituto;

        lookups.put(produtoSustituto.Id, produtoSustituto.ExternalId__c);
        
        Product2 product1 = (Product2)TestFactory.createSObject(new Product2(
            ProdutoSubstituto__c = produtoSustituto.Id,
            SubFamily__c = 'AZOKOP'
        ));
        Product2 productError = (Product2)TestFactory.createSObject(new Product2());
        productError.Description = null;

        List<String> atributoDefensivos = new List<String>{'test'};

        TemplateDataIntegrationFields.Product2INData deserializedProduct1 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, /*culturaList, */atributoDefensivos);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct1}));
        IntegrationInboundProduct2.parseRequest();
        
        TemplateDataIntegrationFields.Product2INData deserializedProductError = new TemplateDataIntegrationFields.Product2INData(productError, lookups, /*new List<Cultura__c>(), */atributoDefensivos);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProductError}));
        IntegrationInboundProduct2.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundProduct2.parseRequest();
        
        // Cultura__c cultura3 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // culturaList.add(cultura3);
        // Cultura__c cultura4 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // culturaList.add(cultura4);

        // TemplateDataIntegrationFields.Product2INData deserializedProduct2 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct2});

        // culturaList.remove(culturaList.size() - 1);
        // culturaList.remove(culturaList.size() - 1);
        // culturaList.remove(culturaList.size() - 1);

        // Cultura__c cultura5 = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        // insert cultura5;
        // culturaList.add(cultura5);

        // TemplateDataIntegrationFields.Product2INData deserializedProduct3 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct3});

        // culturaList.clear();

        // TemplateDataIntegrationFields.Product2INData deserializedProduct4 = new TemplateDataIntegrationFields.Product2INData(product1, lookups, culturaList, atributoDefensivos);

        // IntegrationInboundProduct2.upsertProduct2(new List<TemplateDataIntegrationFields.Product2INData>{deserializedProduct4});

        List<Product2> receivedProducts = [SELECT Id, SubFamily__c FROM Product2 WHERE ExternalId__c = :product1.ExternalId__c OR ExternalId__c = :productError.ExternalId__c LIMIT 1];

        System.assertEquals('AZOKOP', receivedProducts[0].SubFamily__c);

    }
}