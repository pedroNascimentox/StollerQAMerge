@IsTest
public class ShippingPolicyServiceTest {

    public static FINAL Id CLIENTE_RECORDTYPEID    = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();
    public static FINAL Id HIERARQUIA_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId();

    @TestSetup
    static void makeData(){

        Account hierarchyAccount = new Account(
            name = 'Hierarchy Account',
            externalId__c = 'h13r4rchy4cc0un7',
            tipoCliente__c = 'ZC',
            recordTypeId = HIERARQUIA_RECORDTYPEID
        );
        insert hierarchyAccount;
        
        Account customerAccount = new Account(
            name = 'Customer Account',
            externalId__c = 'cust0m3r4cc0un7',
            tipoCliente__c = 'ZB',
            recordTypeId = CLIENTE_RECORDTYPEID,
            parentId = hierarchyAccount.id,
            billingState = 'SP'
        );
        insert customerAccount;

        ZonaTransporte__c transportZone = new ZonaTransporte__c(
            descricao__c = 'tranport zone test',
            externalId__c = 'tr4n5p0r7z0n3'
        );
        insert transportZone;

        LocalNegocio__c businessLocation = new LocalNegocio__c(
            codigo__c = 'bu551n3ssL',
            zonaTransporte__c = transportZone.id
        );
        insert businessLocation;

    }
    
    @IsTest
    public static void getShippingTableFracionadoTest(){

        System.debug('getShippingTableFracionadoTest');

        Account         customerAccount  = [SELECT id FROM Account WHERE externalId__c = 'cust0m3r4cc0un7'];
        LocalNegocio__c businessLocation = [SELECT id FROM LocalNegocio__c];

        try {

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(10),
                accountId = customerAccount.id,
                organizacaoVenda__c = 'Organização Vendas Teste',
                condicaoExpedicao__c = 'Fracionado',
                localNegocio__c = businessLocation.id
            );
            insert opportunity;

            TabelaFrete__c shippingTable = new TabelaFrete__c(
                dataVigenciaFinal__c = Date.today().addDays(5),
                dataVigenciaInicial__c = Date.today().addDays(-15),
                frete__c = 20.0,
                organizacaoVenda__c = 'Organização Vendas Teste',
                regiaoUF__c = 'SP',
                tipoFrete__c = 'Fracionado',
                localNegocio__c = businessLocation.id
            );
            insert shippingTable;

            opportunity = [
                SELECT id, condicaoExpedicao__c, localNegocio__c, account.billingState
                FROM Opportunity
            ];

            ShippingPolicyService shippingPolicyService = new ShippingPolicyService(opportunity);
            ShippingPolicyServiceReturnedData shippingPolicyServiceReturnedData = shippingPolicyService.getShippingTable();

            System.debug('shippingPolicyServiceReturnedData => ' + shippingPolicyServiceReturnedData);
        
        } catch (Exception e){
            System.debug(e.getMessage());
        }

    }

    @IsTest
    public static void getShippingTableLotacaoTest(){

        System.debug('getShippingTableLotacaoTest');

        Account         customerAccount  = [SELECT id FROM Account WHERE externalId__c = 'cust0m3r4cc0un7'];
        LocalNegocio__c businessLocation = [SELECT id FROM LocalNegocio__c];

        try {

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(10),
                accountId = customerAccount.id,
                organizacaoVenda__c = 'Organização Vendas Teste',
                condicaoExpedicao__c = 'Lotação',
                localNegocio__c = businessLocation.id
            );
            insert opportunity;

            TabelaFrete__c shippingTable = new TabelaFrete__c(
                dataVigenciaFinal__c = Date.today().addDays(5),
                dataVigenciaInicial__c = Date.today().addDays(-15),
                frete__c = 20.0,
                organizacaoVenda__c = 'Organização Vendas Teste',
                regiaoUF__c = 'SP',
                tipoFrete__c = 'Lotação',
                localNegocio__c = businessLocation.id
            );
            insert shippingTable;

            opportunity = [
                SELECT id, condicaoExpedicao__c, localNegocio__c, account.billingState
                FROM Opportunity
            ];

            ShippingPolicyService shippingPolicyService = new ShippingPolicyService(opportunity);
            ShippingPolicyServiceReturnedData shippingPolicyServiceReturnedData = shippingPolicyService.getShippingTable();

            System.debug('shippingPolicyServiceReturnedData => ' + shippingPolicyServiceReturnedData);
        
        } catch (Exception e){
            System.debug(e.getMessage());
        }

    }

    @IsTest
    public static void getShippingTableFailTest(){

        System.debug('getShippingTableLotacaoTest');

        Account         customerAccount  = [SELECT id FROM Account WHERE externalId__c = 'cust0m3r4cc0un7'];
        LocalNegocio__c businessLocation = [SELECT id FROM LocalNegocio__c];

        try {

            Opportunity opportunity = new Opportunity(
                name = 'Opportunity',
                stageName = 'Em Aprovação Cliente',
                closeDate = Date.today().addDays(10),
                accountId = customerAccount.id,
                organizacaoVenda__c = 'Organização Vendas Teste',
                condicaoExpedicao__c = 'Lotação',
                localNegocio__c = businessLocation.id
            );
            insert opportunity;

            TabelaFrete__c shippingTable = new TabelaFrete__c(
                dataVigenciaFinal__c = Date.today().addDays(5),
                dataVigenciaInicial__c = Date.today().addDays(-15),
                frete__c = 20.0,
                organizacaoVenda__c = 'Organização Vendas Teste',
                regiaoUF__c = 'RJ',
                tipoFrete__c = 'Lotação',
                localNegocio__c = businessLocation.id
            );
            insert shippingTable;

            opportunity = [
                SELECT id, condicaoExpedicao__c, localNegocio__c, account.billingState
                FROM Opportunity
            ];

            ShippingPolicyService shippingPolicyService = new ShippingPolicyService(opportunity);
            ShippingPolicyServiceReturnedData shippingPolicyServiceReturnedData = shippingPolicyService.getShippingTable();

            System.debug('shippingPolicyServiceReturnedData => ' + shippingPolicyServiceReturnedData);
        
        } catch (Exception e){
            System.debug(e.getMessage());
        }

    }
    
}