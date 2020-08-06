@isTest
public with sharing class CondicaoPagamentoHelperTest {
    @isTest
    public static void TestCondicaoPagamentoHelper() {

        CondicaoPagamento__c condicaoPagamento = new CondicaoPagamento__c();
        condicaoPagamento.ExternalId__c = 'CR00';
        condicaoPagamento.Tipo__c = '';
        condicaoPagamento.DataVigenciaAte__c = date.today().addDays(1);
        condicaoPagamento.DataVigenciaDe__c = date.today();
        condicaoPagamento.JurosComercialFinanceiro__c = 10;
        insert condicaoPagamento;

        List<CondicaoPagamento__c> condicaoPagamentoList = [SELECT Id, Tipo__c FROM CondicaoPagamento__c WHERE Tipo__c = 'CR'];
        
        System.assertEquals(1, condicaoPagamentoList.size());

        CondicaoPagamento__c condicaoPagamentoError = new CondicaoPagamento__c();
        condicaoPagamentoError.ExternalId__c = 'KK00';
        condicaoPagamentoError.Tipo__c = '';

        String message = '';
        try {
            insert condicaoPagamentoError;
        } catch(Exception e){
            message = e.getMessage();
        }

        System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, O tipo do registro não foi encontrado no Id Externo: KK00: []', message);

    }
}