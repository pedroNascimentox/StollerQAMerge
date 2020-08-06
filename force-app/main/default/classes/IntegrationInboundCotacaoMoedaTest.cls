@isTest
public with sharing class IntegrationInboundCotacaoMoedaTest {
    @isTest
    public static void testPost() {

        CotacaoMoeda__c cotacaoMoeda = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        CotacaoMoeda__c cotacaoMoedaError = (CotacaoMoeda__c)TestFactory.createSObject(new CotacaoMoeda__c());
        cotacaoMoedaError.Taxa__c = null;

        TemplateDataIntegrationFields.CotacaoMoedaINData deserializedCotacaoMoeda = new TemplateDataIntegrationFields.CotacaoMoedaINData(cotacaoMoeda);
        TemplateDataIntegrationFields.CotacaoMoedaINData deserializedCotacaoMoedaError = new TemplateDataIntegrationFields.CotacaoMoedaINData(cotacaoMoedaError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.CotacaoMoedaINData>{deserializedCotacaoMoeda, deserializedCotacaoMoedaError}));
        IntegrationInboundCotacaoMoeda.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundCotacaoMoeda.parseRequest();

        List<CotacaoMoeda__c> receivedCotacoesMoeda = [SELECT Id FROM CotacaoMoeda__c WHERE ExternalId__c = :cotacaoMoeda.ExternalId__c OR ExternalId__c = :cotacaoMoedaError.ExternalId__c];

        System.assertEquals(1, receivedCotacoesMoeda.size());

    }
}