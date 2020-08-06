@isTest
public with sharing class IntegrationInboundZonaTransporteTest {
    @isTest
    public static void testPost() {

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        ZonaTransporte__c zonaTransporteError = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        zonaTransporteError.Descricao__c = null;

        TemplateDataIntegrationFields.ZonaTransporteINData deserializedZonaTransporte = new TemplateDataIntegrationFields.ZonaTransporteINData(zonaTransporte);
        TemplateDataIntegrationFields.ZonaTransporteINData deserializedZonaTransporteError = new TemplateDataIntegrationFields.ZonaTransporteINData(zonaTransporteError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.ZonaTransporteINData>{deserializedZonaTransporte, deserializedZonaTransporteError}));
        IntegrationInboundZonaTransporte.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundZonaTransporte.parseRequest();

        List<ZonaTransporte__c> receivedZonaTransporte = [SELECT Id FROM ZonaTransporte__c WHERE ExternalId__c = :zonaTransporte.ExternalId__c OR ExternalId__c = :zonaTransporteError.ExternalId__c];

        System.assertEquals(1, receivedZonaTransporte.size());

    }
}