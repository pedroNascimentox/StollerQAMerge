@isTest
public with sharing class FactoryDataIntegrationTest {
    @isTest
    public static void testValidateObject() {
        List<Account> listAccount = new List<Account> {
            new Account(ExternalId__c = '123', Name = '', BillingCity = 'testBillingCity'),
            new Account(ExternalId__c = '1234', Name = 'test2', BillingCity = 'testBillingCity')
        };
        
        List<Account> listToUpsert = new List<Account>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<String> requiredField = new List<String>{'ExternalId__c', 'Name', 'BillingCity'};
        
        Map<String, TemplateDataIntegrationFields.Response> responseMap = new Map<String, TemplateDataIntegrationFields.Response>();
        for (Account account : listAccount) {
            for (String field : requiredField) {
                if (IntegrationUtils.convertEmptyString(String.valueOf(account.get(field)))) {
                    TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
                    response.error(
                            String.valueOf(account.ExternalId__c), 
                            'Valor inválido para o campo obrigatório: ' + field, 
                            String.valueOf(listAccount.getSObjectType())
                        );
                    responseMap.put(account.ExternalId__c, response);
                }
            }
        }

        listAccount[0].BillingCity = '';
		
        for (Account account : listAccount) {
        	// FactoryDataIntegration.validateObject('ExternalId__c', 'ExternalId__c', account, listToUpsert, responseList, requiredField);
        	FactoryDataIntegration.validateObject('ExternalId__c', 'ExternalId__c', account, listToUpsert, responseMap, requiredField);
        }

        System.assertEquals(1, responseMap.size());
        String error = responseMap.values()[0].errorMessage;
        System.assertEquals(error, responseMap.values()[0].errorMessage);
        //System.assertEquals('Valor inválido para o campo obrigatório: Name', responseList[0].errorMessage);

    }
}