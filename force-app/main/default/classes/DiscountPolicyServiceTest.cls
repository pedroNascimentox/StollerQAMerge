@IsTest
public class DiscountPolicyServiceTest {

    public static FINAL String STANDARD_SALES_ORGANIZATION = '1000';

    @TestSetup
    static void makeData(){
    
            Id profileId = [SELECT id FROM Profile WHERE name = 'Administrador do Sistema'].Id;

            User manager = new User(
                username = 'alberto@stoller.com',
                lastName = 'Alberto',
                email = 'gerentealberto@stoller.com',
                alias = 'gealb',
                communityNickname = 'Ger. Alberto',
                emailEncodingKey = 'ISO-8859-1',
                languageLocaleKey = 'en_US',
                localeSidKey = 'en_US',
                timeZoneSidKey = 'America/New_York',
                profileId = profileId
            );

            User manager2 = new User(
                username = 'alcides@stoller.com',
                lastName = 'Alcides',
                email = 'diretoralcides@stoller.com',
                alias = 'diralc',
                communityNickname = 'Dir. Alcides',
                emailEncodingKey = 'ISO-8859-1',
                languageLocaleKey = 'en_US',
                localeSidKey = 'en_US',
                timeZoneSidKey = 'America/New_York',
                profileId = profileId
            );

            User rtv = new User(
                username = 'paulo@stoller.com',
                lastName = 'Paulo',
                email = 'rtvpaulo@stoller.com',
                alias = 'rtvpau',
                communityNickname = 'RTV Paulo',
                emailEncodingKey = 'ISO-8859-1',
                languageLocaleKey = 'en_US',
                localeSidKey = 'en_US',
                timeZoneSidKey = 'America/New_York',
                profileId = profileId
            );
            
            List<User> usersToInsert = new List<User>{manager, manager2, rtv};
            insert usersToInsert;

            Regional__c regional = new Regional__c(
                nomeRegional__c = 'Regional 1',
                externalId__c = 'r3g10n4l1'
            );
            insert regional;

            Territorio__c territory = new Territorio__c(
                nomeTerritorio__c = 'Territory',
                externalId__c = 't3rr1t0r10',
                gerente__c = manager.id,
                diretor__c = manager2.id,
                rtv__c = rtv.id,
                regional__c = regional.id
            );
            insert territory;

            Account hierarchyAccount = new Account(
                name = 'Hierarchy Account',
                externalId__c = 'h13r4rchy4cc0un7',
                tipoCliente__c = 'ZC',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            );
            insert hierarchyAccount;

            Account customerAccount = new Account(
                name = 'Customer Account',
                externalId__c = 'cust0m3r4cc0un7',
                tipoCliente__c = 'ZB',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId(),
                parentId = hierarchyAccount.id
            );
            insert customerAccount;
            
    }
    
    @IsTest
    public static void getDiscountPolicyByCustomerHierarchyTest(){

        System.debug('getDiscountPolicyByCustomerHierarchyTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Account hierarchyAccount2 = new Account(
                name = 'Hierarchy Account 2',
                externalId__c = 'h13r4rchy4cc0un72',
                tipoCliente__c = 'ZC',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            );

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                hierarquia__c = hierarchyAccount.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 10,
                maximo__c = 15,
                minimo__c = 5,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c wrongDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 20,
                hierarquia__c = hierarchyAccount2.id,
                maximo__c = 25,
                minimo__c = 10,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{discountPolicy, wrongDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);
            
            System.debug('discountPolicy.recomendado__c => ' + discountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, discountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, wrongDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyByCustomerTest(){

        System.debug('getDiscountPolicyByCustomerTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Account wrongCustomerAccount = new Account(
                name = 'Wrong Customer Account',
                externalId__c = 'cust0m3r4cc0un72',
                tipoCliente__c = 'ZB',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId(),
                parentId = hierarchyAccount.id
            );
            insert wrongCustomerAccount;

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                conta__c = customerAccount.id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 20,
                maximo__c = 30,
                minimo__c = 15,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c wrongDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                conta__c = wrongCustomerAccount.id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 32,
                maximo__c = 45,
                minimo__c = 10,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{discountPolicy, wrongDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);

            System.debug('discountPolicy.recomendado__c => ' + discountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, discountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, wrongDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyByRegionalTest(){

        System.debug('getDiscountPolicyByRegionalTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Regional__c wrongRegional = new Regional__c(
                nomeRegional__c = 'Regional 2',
                externalId__c = 'r3g10n4l2'
            );
            insert wrongRegional;

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 2,
                maximo__c = 4,
                minimo__c = 0,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c wrongDiscountPolicy = new PoliticaDesconto__c(
                regional__c = wrongRegional.Id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 6,
                maximo__c = 8,
                minimo__c = 2,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            
            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{discountPolicy, wrongDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);
            
            System.debug('discountPolicy.recomendado__c => ' + discountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, discountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, wrongDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyByTerritoryTest(){

        System.debug('getDiscountPolicyByTerritoryTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];
            User          manager          = [SELECT id FROM User WHERE userName = 'alberto@stoller.com'];
            User          manager2         = [SELECT id FROM User WHERE userName = 'alcides@stoller.com'];
            User          rtv              = [SELECT id FROM User WHERE userName = 'paulo@stoller.com'];

            Territorio__c wrongTerritory = new Territorio__c(
                nomeTerritorio__c = 'Wrong Territory',
                externalId__c = 't3rr1t0r102',
                gerente__c = manager.id,
                diretor__c = manager2.id,
                rtv__c = rtv.id,
                regional__c = regional.id
            );
            insert wrongTerritory;

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 2,
                maximo__c = 4,
                minimo__c = 0,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c wrongDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 1,
                maximo__c = 3,
                minimo__c = 0,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            
            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{discountPolicy, wrongDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);

            System.debug('discountPolicy.recomendado__c => ' + discountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, discountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, wrongDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyByGenericKeyTest(){

        System.debug('getDiscountPolicyByGenericKeyTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c discountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 2,
                maximo__c = 4,
                minimo__c = 0,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c wrongDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 7,
                maximo__c = 9,
                minimo__c = 5,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{discountPolicy, wrongDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);

            System.debug('discountPolicy.recomendado__c => ' + discountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, discountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, wrongDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyNotFound(){

        System.debug('getDiscountPolicyNotFound');
        
        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData2 = new DiscountPolicyServiceReturnedData('Ocorreu um erro.');
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).hasErrors, true, 'Found discount policy when it shouldn\'t.');
            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).message, 'Não existe politica de desconto cadastrada para este item, favor entrar em contato com o departamento de Marketing.', 'Found discount policy when it shouldn\'t.');

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyPriorityTest(){

        System.debug('getDiscountPolicyPriorityTest');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Account hierarchyAccount2 = new Account(
                name = 'Hierarchy Account 2',
                externalId__c = 'h13r4rchy4cc0un72',
                tipoCliente__c = 'ZC',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            );

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c prioritizedDiscountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 10,
                maximo__c = 15,
                minimo__c = 5,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c alsoValidDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 20,
                maximo__c = 25,
                minimo__c = 10,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c genericDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 5,
                maximo__c = 6,
                minimo__c = 2,
                externalId__c = 'pr1c3b00k3n7ry3',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{prioritizedDiscountPolicy, alsoValidDiscountPolicy, genericDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);
            
            System.debug('prioritizedDiscountPolicy.recomendado__c => ' + prioritizedDiscountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, prioritizedDiscountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, alsoValidDiscountPolicy.recomendado__c);
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, genericDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

    @IsTest
    public static void getDiscountPolicyPriorityTest2(){

        System.debug('getDiscountPolicyPriorityTest2');

        try {

            Account       customerAccount  = [SELECT id FROM Account WHERE name = 'Customer Account'];
            Account       hierarchyAccount = [SELECT id FROM Account WHERE name = 'Hierarchy Account'];
            Regional__c   regional         = [SELECT id FROM Regional__c];
            Territorio__c territory        = [SELECT id FROM Territorio__c];

            Account hierarchyAccount2 = new Account(
                name = 'Hierarchy Account 2',
                externalId__c = 'h13r4rchy4cc0un72',
                tipoCliente__c = 'ZC',
                recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            );

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(6),
                regional__c = regional.id,
                territorio__c = territory.id,
                accountId = customerAccount.id,
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );
            insert opportunity;

            Product2 product = new Product2(
                name = 'Product Test',
                externalId__c = 'pr0duc77357'
            );
            insert product;

            PoliticaDesconto__c prioritizedDiscountPolicy = new PoliticaDesconto__c(
                regional__c = regional.id,
                territorio__c = territory.id,
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 12,
                maximo__c = 13,
                minimo__c = 9,
                externalId__c = 'pr1c3b00k3n7ry',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c alsoValidDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 20,
                maximo__c = 25,
                minimo__c = 10,
                externalId__c = 'pr1c3b00k3n7ry2',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            PoliticaDesconto__c genericDiscountPolicy = new PoliticaDesconto__c(
                produto__c = product.Id,
                dataVigenciaInicial__c = opportunity.closeDate,
                dataVigenciaFinal__c = opportunity.closeDate,
                recomendado__c = 5,
                maximo__c = 6,
                minimo__c = 2,
                externalId__c = 'pr1c3b00k3n7ry3',
                organizacaoVenda__c = STANDARD_SALES_ORGANIZATION
            );

            List<PoliticaDesconto__c> discountPolicies = new List<PoliticaDesconto__c>{prioritizedDiscountPolicy, alsoValidDiscountPolicy, genericDiscountPolicy};
            insert discountPolicies;

            opportunity = [
                SELECT id, regional__c, territorio__c, accountId, account.parentId, organizacaoVenda__c, closeDate
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(opportunity);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedData = discountPolicyService.getDiscountPolicy(new Set<String>{product.id});
            DiscountPolicyServiceReturnedData discountPolicyServiceReturnedDataError = new DiscountPolicyServiceReturnedData('Ocorreu um erro.');
            System.debug('test discountPolicyServiceReturnedData => ' + discountPolicyServiceReturnedData);
            
            System.debug('prioritizedDiscountPolicy.recomendado__c => ' + prioritizedDiscountPolicy.recomendado__c);
            System.debug('discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount => ' + discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount);

            System.assertEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, prioritizedDiscountPolicy.recomendado__c, 'Incorrect discount policy.');
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, alsoValidDiscountPolicy.recomendado__c);
            System.assertNotEquals(discountPolicyServiceReturnedData.data.get(product.id).recommendedDiscount, genericDiscountPolicy.recomendado__c);

        } catch (Exception e){
            System.debug('e => ' + e);
        }

    }

}