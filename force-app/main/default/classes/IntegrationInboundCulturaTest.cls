@isTest
public with sharing class IntegrationInboundCulturaTest {
    @isTest
    public static void testPost() {

        Cultura__c cultura = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        Cultura__c culturaError = (Cultura__c)TestFactory.createSObject(new Cultura__c());
        culturaError.Descricao__c = null;

        CultureData cultureData = new CultureData(cultura);

        TemplateDataIntegrationFields.CulturaINData deserializedCultura = new TemplateDataIntegrationFields.CulturaINData(cultura);
        TemplateDataIntegrationFields.CulturaINData deserializedCulturaError = new TemplateDataIntegrationFields.CulturaINData(culturaError);

        IntegrationUtils.setTestRequest(JSON.serialize(new List<TemplateDataIntegrationFields.CulturaINData>{deserializedCultura, deserializedCulturaError}));
        IntegrationInboundCultura.parseRequest();
        
        IntegrationUtils.setWrongTestRequest();
        IntegrationInboundCultura.parseRequest();

        List<Cultura__c> receivedCulturas = [SELECT Id FROM Cultura__c WHERE ExternalId__c = :cultura.ExternalId__c OR ExternalId__c = :culturaError.ExternalId__c];

        System.assertEquals(1, receivedCulturas.size());

    }
}