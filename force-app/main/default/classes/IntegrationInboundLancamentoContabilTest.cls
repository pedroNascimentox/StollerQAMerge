@isTest
public with sharing class IntegrationInboundLancamentoContabilTest {
    @isTest
    public static void testPost() {

        LancamentoContabil__c lancamentoContabil = (LancamentoContabil__c)TestFactory.createSObject(new LancamentoContabil__c());
        LancamentoContabil__c lancamentoContabilError = (LancamentoContabil__c)TestFactory.createSObject(new LancamentoContabil__c());
        lancamentoContabilError.OrganizacaoVendas__c = null;

        TemplateDataIntegrationFields.LancamentoContabilINData deserializedLancamentoContabil = new TemplateDataIntegrationFields.LancamentoContabilINData(lancamentoContabil);
        TemplateDataIntegrationFields.LancamentoContabilINData deserializedLancamentoContabilError = new TemplateDataIntegrationFields.LancamentoContabilINData(lancamentoContabilError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.LancamentoContabilINData>{deserializedLancamentoContabil, deserializedLancamentoContabilError}));
        IntegrationInboundLancamentoContabil.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundLancamentoContabil.parseRequest();

        List<LancamentoContabil__c> receivedLancamentoContabil = [SELECT Id FROM LancamentoContabil__c WHERE ExternalId__c = :lancamentoContabil.ExternalId__c OR ExternalId__c = :lancamentoContabilError.ExternalId__c];

        System.assertEquals(1, receivedLancamentoContabil.size());

    }
}