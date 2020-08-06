@isTest
public with sharing class IntegrationInboundRegionalTest {
    @isTest
    public static void testPost() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        Regional__c regionalError = (Regional__c)TestFactory.createSObject(new Regional__c());
        regionalError.NomeRegional__c = null;

        TemplateDataIntegrationFields.RegionalINData deserializedRegional = new TemplateDataIntegrationFields.RegionalINData(regional);
        TemplateDataIntegrationFields.RegionalINData deserializedRegionalError = new TemplateDataIntegrationFields.RegionalINData(regionalError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.RegionalINData>{deserializedRegional, deserializedRegionalError}));
        IntegrationInboundRegional.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundRegional.parseRequest();

        List<Regional__c> receivedRegional = [SELECT Id FROM Regional__c WHERE ExternalId__c = :regional.ExternalId__c OR ExternalId__c = :regionalError.ExternalId__c];

        System.assertEquals(1, receivedRegional.size());

    }
}