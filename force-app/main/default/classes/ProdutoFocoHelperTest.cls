@isTest
public with sharing class ProdutoFocoHelperTest {
    @isTest
    public static void produtoFocoHelperTest() {
        List<Product2> prodList = new List<Product2>();
        List<ProdutoFoco__c> produtoFocoList = new List<ProdutoFoco__c>();
        List<PlanoIncentivo__c> planIncentivoList = new List<PlanoIncentivo__c>();

        PlanoIncentivo__c planIncentivo = new PlanoIncentivo__c();
        planIncentivo.Name = 'Teste';
        planIncentivo.Status__c = 'Novo';
        planIncentivo.Atualizado__c = false;

        planIncentivoList.add(planIncentivo);

        PlanoIncentivo__c planIncentivo2 = new PlanoIncentivo__c();
        planIncentivo2.Name = 'Teste2';
        planIncentivo2.Status__c = 'Em apuração';
        planIncentivo2.Atualizado__c = false;

        planIncentivoList.add(planIncentivo2);

        insert planIncentivoList;

        Product2 prod = new Product2();
        prod.ExternalId__c = '123';
        prod.Name = 'Produto';
        prod.Family = 'STIMULATE';

        prodList.add(prod);

        Product2 prod2 = new Product2();
        prod2.ExternalId__c = '1234';
        prod2.Name = 'Produto';
        prod2.Family = 'CELLERATE';

        prodList.add(prod2);

        insert prodList;

        Product2 product  = (Product2)TestFactory.createSObject(new Product2());
        insert product;

        ProdutoFoco__c prodFoco = new ProdutoFoco__c();
        prodFoco.QuantidadeLitros__c = 10;
        prodFoco.PlanoIncentivo__c   = planIncentivo.Id;
        prodFoco.FamiliaProdutos__c  = 'STIMULATE';

        produtoFocoList.add(prodFoco);        

        ProdutoFoco__c prodFoco2 = new ProdutoFoco__c();
        prodFoco2.QuantidadeLitros__c = 54;
        prodFoco2.PlanoIncentivo__c   = planIncentivo2.Id;
        prodFoco2.ProdutoFoco__c      = product.Id;

        produtoFocoList.add(prodFoco2);

        insert produtoFocoList;

        ProdutoFoco__c prodFocoExistente = new ProdutoFoco__c();
        prodFocoExistente.QuantidadeLitros__c = 20;
        prodFocoExistente.PlanoIncentivo__c = planIncentivo.Id;
        prodFocoExistente.produtoFoco__c = prod.Id;

        system.debug(prodFoco);

        prodFoco2.QuantidadeLitros__c = 30;

        update prodFoco2;

        prodFoco.FamiliaProdutos__c  = 'CELLERATE';

        update prodFoco;

        ProdutoFocoHelper.checkBeforeInsert(produtoFocoList);


        try {
            insert prodFocoExistente;
        } catch (Exception e) {
            system.debug('Erro: '+ e);
        }
        try {            
            delete prodFoco2;
        } catch (Exception e) {
            system.debug('Erro: '+e);
        }

    }
}