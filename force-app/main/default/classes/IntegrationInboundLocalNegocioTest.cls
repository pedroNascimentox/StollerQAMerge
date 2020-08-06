@isTest
public with sharing class IntegrationInboundLocalNegocioTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;
        
        lookups.put(zonaTransporte.Id, zonaTransporte.ExternalId__c);

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c  = zonaTransporte.Id
            )
        );
        LocalNegocio__c localNegocioError = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c());

        TemplateDataIntegrationFields.LocalNegocioINData deserializedLocalNegocio = new TemplateDataIntegrationFields.LocalNegocioINData(localNegocio, lookups);

        TemplateDataIntegrationFields.LocalNegocioINData deserializedLocalNegocioError = new TemplateDataIntegrationFields.LocalNegocioINData(localNegocioError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.LocalNegocioINData>{deserializedLocalNegocio, deserializedLocalNegocioError}));
        IntegrationInboundLocalNegocio.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundLocalNegocio.parseRequest();

        List<LocalNegocio__c> receivedLocalNegocio = [SELECT Id FROM LocalNegocio__c WHERE Codigo__c = :localNegocio.Codigo__c OR Codigo__c = :localNegocioError.Codigo__c];

        System.assertEquals(1, receivedLocalNegocio.size());

    }
}