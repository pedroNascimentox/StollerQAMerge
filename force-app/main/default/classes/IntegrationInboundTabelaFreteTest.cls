@isTest
public with sharing class IntegrationInboundTabelaFreteTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(
            new LocalNegocio__c(
                ZonaTransporte__c = zonaTransporte.Id
            ));
        insert localNegocio;
        
        lookups.put(localNegocio.Id, localNegocio.Codigo__c);

        TabelaFrete__c tabelaFrete = (TabelaFrete__c)TestFactory.createSObject(
            new TabelaFrete__c(
                LocalNegocio__c  = localNegocio.Id
            )
        );
        TabelaFrete__c tabelaFreteError = (TabelaFrete__c)TestFactory.createSObject(new TabelaFrete__c());

        TemplateDataIntegrationFields.TabelaFreteINData deserializedTabelaFrete = new TemplateDataIntegrationFields.TabelaFreteINData(tabelaFrete, lookups);
        TemplateDataIntegrationFields.TabelaFreteINData deserializedTabelaFreteError = new TemplateDataIntegrationFields.TabelaFreteINData(tabelaFreteError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.TabelaFreteINData>{deserializedTabelaFrete, deserializedTabelaFreteError}));
        IntegrationInboundTabelaFrete.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundTabelaFrete.parseRequest();

        List<TabelaFrete__c> receivedTabelaFrete = [SELECT Id FROM TabelaFrete__c WHERE IdSAP__c = :tabelaFrete.IdSAP__c OR IdSAP__c = :tabelaFreteError.IdSAP__c];

        System.assertEquals(1, receivedTabelaFrete.size());

    }
}