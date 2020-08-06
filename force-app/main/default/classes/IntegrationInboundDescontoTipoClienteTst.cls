@isTest
public with sharing class IntegrationInboundDescontoTipoClienteTst {
    @isTest
    public static void testPost() {

        DescontoTipoCliente__c descontoTipoCliente = (DescontoTipoCliente__c)TestFactory.createSObject(new DescontoTipoCliente__c());
        DescontoTipoCliente__c descontoTipoClienteError = (DescontoTipoCliente__c)TestFactory.createSObject(new DescontoTipoCliente__c());
        descontoTipoClienteError.OrganizacaoVenda__c = null;

        TemplateDataIntegrationFields.DescontoTipoClienteINData deserializedDescontoTipoCliente = new TemplateDataIntegrationFields.DescontoTipoClienteINData(descontoTipoCliente);
        TemplateDataIntegrationFields.DescontoTipoClienteINData deserializedDescontoTipoClienteError = new TemplateDataIntegrationFields.DescontoTipoClienteINData(descontoTipoClienteError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.DescontoTipoClienteINData>{deserializedDescontoTipoCliente, deserializedDescontoTipoClienteError}));
        IntegrationInboundDescontoTipoCliente.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundDescontoTipoCliente.parseRequest();

        List<DescontoTipoCliente__c> receivedDescontoTipoClientes = [SELECT Id FROM DescontoTipoCliente__c WHERE IdSAP__c = :descontoTipoCliente.IdSAP__c OR IdSAP__c = :descontoTipoClienteError.IdSAP__c];

        System.assertEquals(1, receivedDescontoTipoClientes.size());

    }
}