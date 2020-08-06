@isTest
public with sharing class IntegrationInboundItinerarioTest {
    @isTest
    public static void testPost() {

        Map<Id, String> lookups = new Map<Id, String>();

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;
        
        lookups.put(zonaTransporte.Id, zonaTransporte.ExternalId__c);

        Itinerario__c itinerario = (Itinerario__c)TestFactory.createSObject(
            new Itinerario__c(
                ZonaTransporteOrigem__c  = zonaTransporte.Id,
                ZonaTransporteDestino__c = zonaTransporte.Id
            )
        );
        Itinerario__c itinerarioError = (Itinerario__c)TestFactory.createSObject(new Itinerario__c());

        TemplateDataIntegrationFields.ItinerarioINData deserializedItinerario = new TemplateDataIntegrationFields.ItinerarioINData(itinerario, lookups);
        TemplateDataIntegrationFields.ItinerarioINData deserializedItinerarioError = new TemplateDataIntegrationFields.ItinerarioINData(itinerarioError, lookups);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.ItinerarioINData>{deserializedItinerario, deserializedItinerarioError}));
        IntegrationInboundItinerario.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundItinerario.parseRequest();

        List<Itinerario__c> receivedItinerario = [SELECT Id FROM Itinerario__c WHERE ExternalId__c = :itinerario.ExternalId__c OR ExternalId__c = :itinerarioError.ExternalId__c];

        System.assertEquals(1, receivedItinerario.size());

    }
}