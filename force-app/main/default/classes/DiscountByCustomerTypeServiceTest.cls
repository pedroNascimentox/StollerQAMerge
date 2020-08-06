@IsTest
public with sharing class DiscountByCustomerTypeServiceTest {
    
    @IsTest
    public static void getDiscountByCustomerTypeTest(){

        try {

            Account customerAccount = new Account(
                name = 'Customer Account',
                externalId__c = 'cust0m3r4cc0un7',
                tipoCliente__c = 'Cooperativa'
            );

            insert customerAccount;
            
            DescontoTipoCliente__c currentCustomerTypeDiscount = new DescontoTipoCliente__c(
                tipoCliente__c          = 'Cooperativa',
                desconto__c             = 2.0,
                dataVigenciaInicial__c  = Date.today().addDays(-7),
                dataVigenciaFinal__c    = Date.today().addDays(9)
            );

            DescontoTipoCliente__c notCurrentCustomerTypeDiscount = new DescontoTipoCliente__c(
                tipoCliente__c          = 'Cooperativa',
                desconto__c             = 2.0,
                dataVigenciaInicial__c  = Date.today().addDays(-10),
                dataVigenciaFinal__c    = Date.today().addDays(-3)
            );

            DescontoTipoCliente__c currentCustomerTypeDiscountRecordWithWrongCustomerType = new DescontoTipoCliente__c(
                tipoCliente__c          = 'ZE',
                desconto__c             = 4.5,
                dataVigenciaInicial__c  = Date.today().addDays(-7),
                dataVigenciaFinal__c    = Date.today().addDays(9)
            );

            DescontoTipoCliente__c notCurrentCustomerTypeDiscountRecordWithWrongCustomerType = new DescontoTipoCliente__c(
                tipoCliente__c          = 'ZE',
                desconto__c             = 4.5,
                dataVigenciaInicial__c  = Date.today().addDays(-10),
                dataVigenciaFinal__c    = Date.today().addDays(3)
            );

            List<DescontoTipoCliente__c> customerTypeDiscountsToInsert = new List<DescontoTipoCliente__c>{
                currentCustomerTypeDiscount,
                notCurrentCustomerTypeDiscount,
                currentCustomerTypeDiscountRecordWithWrongCustomerType,
                notCurrentCustomerTypeDiscountRecordWithWrongCustomerType
            };

            insert customerTypeDiscountsToInsert;

            DiscountByCustomerTypeService discountByCustomerTypeService = new DiscountByCustomerTypeService(customerAccount.tipoCliente__c, Date.today());
            DiscountByCustomerTypeReturnedData discountByCustomerTypeReturnedData = discountByCustomerTypeService.getDiscountByCustomerType();

            System.debug('discountByCustomerTypeReturnedData.data.id => ' + discountByCustomerTypeReturnedData.data.id);
            System.debug('currentCustomerTypeDiscount.id => ' + currentCustomerTypeDiscount.id);

            System.assertEquals(currentCustomerTypeDiscount.id, discountByCustomerTypeReturnedData.data.id, 'Not equals.');
            System.assertNotEquals(notCurrentCustomerTypeDiscount.id, discountByCustomerTypeReturnedData.data.id, 'Equals.');
            System.assertNotEquals(currentCustomerTypeDiscountRecordWithWrongCustomerType.id, discountByCustomerTypeReturnedData.data.id, 'Equals.');
            System.assertNotEquals(notCurrentCustomerTypeDiscountRecordWithWrongCustomerType.id, discountByCustomerTypeReturnedData.data.id, 'Equals.');
        
        } catch (Exception e){
            System.debug('e => ' + e);
        }
    }

    @IsTest
    public static void getDiscountByCustomerTypeTestFail(){

        try {

            Account customerAccount = new Account(
                name = 'Customer Account',
                externalId__c = 'cust0m3r4cc0un7',
                tipoCliente__c = 'Cooperativa'
            );

            insert customerAccount;
            
            DescontoTipoCliente__c currentCustomerTypeDiscount = new DescontoTipoCliente__c(
                tipoCliente__c          = 'Cooperativa',
                desconto__c             = 2.0,
                dataVigenciaInicial__c  = Date.today().addDays(-14),
                dataVigenciaFinal__c    = Date.today().addDays(-9)
            );

            DescontoTipoCliente__c notCurrentCustomerTypeDiscount = new DescontoTipoCliente__c(
                tipoCliente__c          = 'Cooperativa',
                desconto__c             = 2.0,
                dataVigenciaInicial__c  = Date.today().addDays(-10),
                dataVigenciaFinal__c    = Date.today().addDays(-3)
            );

            DescontoTipoCliente__c currentCustomerTypeDiscountRecordWithWrongCustomerType = new DescontoTipoCliente__c(
                tipoCliente__c          = 'ZE',
                desconto__c             = 4.5,
                dataVigenciaInicial__c  = Date.today().addDays(-7),
                dataVigenciaFinal__c    = Date.today().addDays(9)
            );

            DescontoTipoCliente__c notCurrentCustomerTypeDiscountRecordWithWrongCustomerType = new DescontoTipoCliente__c(
                tipoCliente__c          = 'ZE',
                desconto__c             = 4.5,
                dataVigenciaInicial__c  = Date.today().addDays(-10),
                dataVigenciaFinal__c    = Date.today().addDays(3)
            );

            List<DescontoTipoCliente__c> customerTypeDiscountsToInsert = new List<DescontoTipoCliente__c>{
                currentCustomerTypeDiscount,
                notCurrentCustomerTypeDiscount,
                currentCustomerTypeDiscountRecordWithWrongCustomerType,
                notCurrentCustomerTypeDiscountRecordWithWrongCustomerType
            };

            insert customerTypeDiscountsToInsert;

            DiscountByCustomerTypeService discountByCustomerTypeService = new DiscountByCustomerTypeService(customerAccount.tipoCliente__c, Date.today());
            DiscountByCustomerTypeReturnedData discountByCustomerTypeReturnedData = discountByCustomerTypeService.getDiscountByCustomerType();

            System.debug('discountByCustomerTypeReturnedData => ' + discountByCustomerTypeReturnedData);
            System.debug('discountByCustomerTypeReturnedData.hasErrors => ' + discountByCustomerTypeReturnedData.hasErrors);
            System.debug('discountByCustomerTypeReturnedData.message => ' + discountByCustomerTypeReturnedData.message);

            System.assertEquals(discountByCustomerTypeReturnedData.hasErrors, true, 'Exception not catched.');
        
        } catch (Exception e){
            System.debug('e => ' + e);
        }
    }
}