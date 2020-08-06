@isTest
public with sharing class IntegrationInboundCondicaoPagamentoTest {
    @isTest
    public static void testPost() {

        CondicaoPagamento__c condicaoPagamento = (CondicaoPagamento__c)TestFactory.createSObject(new CondicaoPagamento__c());
        insert condicaoPagamento;
        
        CondicaoPagamento__c condicaoPagamentoError = (CondicaoPagamento__c)TestFactory.createSObject(new CondicaoPagamento__c());
        condicaoPagamentoError.Descricao__c = null;

        TemplateDataIntegrationFields.CondicaoPagamentoINData deserializedCondicaoPagamento = new TemplateDataIntegrationFields.CondicaoPagamentoINData(condicaoPagamento);
        TemplateDataIntegrationFields.CondicaoPagamentoINData deserializedCondicaoPagamentoError = new TemplateDataIntegrationFields.CondicaoPagamentoINData(condicaoPagamentoError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.CondicaoPagamentoINData>{deserializedCondicaoPagamento, deserializedCondicaoPagamentoError}));
        IntegrationInboundCondicaoPagamento.parseRequest();

        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundCondicaoPagamento.parseRequest();

        List<CondicaoPagamento__c> receivedCondicoesPagamento = [SELECT Id FROM CondicaoPagamento__c WHERE ExternalId__c = :condicaoPagamento.ExternalId__c OR ExternalId__c = :condicaoPagamentoError.ExternalId__c];

        System.assertEquals(1, receivedCondicoesPagamento.size());

    }
}