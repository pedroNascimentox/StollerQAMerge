public with sharing class IntegrationOutboundEscoamento {

    private static Map<Id, Escoamento__c> escoamentoMap;
    
    static {
        escoamentoMap = new Map<Id, Escoamento__c>();
    }

    @future(callout = true)
    public static void sendEscoamentoTrigger(Set<Id> escoamentoIds) {
        sendEscoamento(escoamentoIds);
    }

    public static Response sendEscoamento(Set<Id> escoamentoIds) {
        
        List<Escoamento__c> escoamentos = [SELECT Id,
                                                  DataApuracao__c,
                                                  NomeCliente__c,
                                                  NomeCliente__r.ExternalId__c,
                                                  NomeCliente__r.Name,
                                                  Territorio__c,
                                                  Territorio__r.NomeTerritorio__c,
                                                //   DescricaoTerritorio__c,
                                                  RTV__c,
                                                  RTV__r.Name,
                                                  RTV__r.BusinessPartnerSAP__c,
                                                  Produto__c,
                                                  Produto__r.ExternalId__c,
                                                  Produto__r.Name,
                                                  Quantidade__c
                                           FROM Escoamento__c
                                           WHERE Id IN :escoamentoIds];


        escoamentoMap = new Map<Id, Escoamento__c>(escoamentos);

        SAPCredential__mdt credential = [SELECT URL__c, Username__c, Password__c FROM SAPCredential__mdt WHERE DeveloperName = 'BasicAuthEscoamento'];

        Map<Id, ResponseChild> responseMap = new Map<Id, ResponseChild>();

        String returnedSAPSerialized;
        Boolean hasError = false;
        ReturnedList returnedList;
        String errorMessage;

        ModelSAP modelToSend = new ModelSAP(escoamentoMap.values());

        HttpResponse authResponse = IntegrationUtils.sendAuthRequest(credential, JSON.serialize(modelToSend));

        if (IntegrationUtils.isStatusSuccess(authResponse.getStatusCode())) {

            try {

                returnedList = (ReturnedList)JSON.deserialize(String.valueOf(authResponse.getBody()), ReturnedList.class);
                // System.debug('returnedList => ' + JSON.serializePretty(returnedList));
                returnedSAPSerialized = JSON.serialize(returnedList);

                for (ReturnedSAP returned : returnedList.response) {

                    if (returned.type == 'S' || returned.type == 'W') {
                        responseMap.put(returned.sfId, new ResponseChild().success(returned.sfId, returned.message));

                        // escoamentoMap.get(returned.sfId).CodigoSAP__c = Integer.valueOf(returned.SAPId);
                        escoamentoMap.get(returned.sfId).StatusIntegracao__c = 'Enviado';
                    } else {
                        responseMap.put(returned.sfId, new ResponseChild().error(returned.sfId, returned.message));

                        escoamentoMap.get(returned.sfId).StatusIntegracao__c = 'Erro no envio';
                        hasError = true;
                    }
                }

            } catch (Exception e) {

                for (Escoamento__c escoamento : escoamentoMap.values()) {
                    escoamento.StatusIntegracao__c = 'Erro no envio';
                }
                errorMessage = e.getMessage() + ' - ' + e.getStackTraceString();
                hasError = true;

            }

        } else {

            for (Escoamento__c escoamento : escoamentoMap.values()) {
                escoamento.StatusIntegracao__c = 'Erro no envio';
            }
            errorMessage = 'STATUS CODE: ' + authResponse.getStatusCode() + ' - ' + String.valueOf(authResponse.getBody());
            hasError = true;
        }

        update escoamentoMap.values();

        Response finalResponse = new Response(responseMap.values(), hasError, errorMessage);

        IntegrationUtils.WSLog('Escoamento', 'Outbound', returnedSAPSerialized, JSON.serialize(finalResponse), hasError, escoamentos);

        // System.debug(JSON.serializePretty(responseMap.values()) + '\n\nerrorMessage => ' + errorMessage);
        
        return finalResponse;

    }

    @TestVisible
    private class ReturnedList {

        ReturnedSAP[] response;

    }

    @TestVisible
    private class ReturnedSAP {

        public String sfId;
        public String SAPId;
        public String type;
        public String message;

    }
    
    @TestVisible
    private class ModelSAP {

        public TemplateDataIntegrationFields.EscoamentoOUTData[] request;

        // public ModelSAP() {
        // }

        public ModelSAP(Escoamento__c[] escoamentos) {
            request = new List<TemplateDataIntegrationFields.EscoamentoOUTData>();
            for (Escoamento__c escoamento : escoamentos) {
                this.request.add(new TemplateDataIntegrationFields.EscoamentoOUTData(escoamento));
            }
        }
    }

    public class Response {

        public Boolean hasError;
        public String message;
        public ResponseChild[] responses;

        // public Response() {
        // }

        public Response(ResponseChild[] responses, Boolean hasError, String message) {
            this.responses = responses;
            this.hasError  = hasError;
            this.message   = message;
        }

    }

    public class ResponseChild {

        public Boolean hasError;
        public String message;
        public Id escoamentoId;

        public ResponseChild() {
        }
        
        // public ResponseChild success(Id escoamentoId) {
        //     this.hasError     = false;
        //     this.escoamentoId = escoamentoId;
        //     return this;
        // }
        
        public ResponseChild success(Id escoamentoId, String message) {
            this.hasError     = false;
            this.escoamentoId = escoamentoId;
            this.message      = message;
            return this;
        }

        // public ResponseChild error(String message) {
        //     this.hasError = true;
        //     this.message  = message;
        //     return this;
        // }

        public ResponseChild error(Id escoamentoId, String message) {
            this.hasError     = true;
            this.escoamentoId = escoamentoId;
            this.message      = message;
            return this;
        }
    }
}