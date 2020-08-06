public with sharing class SendOpportunityPDFController {

    public SendOpportunityPDFController(ApexPages.StandardController stdController) {}

    @RemoteAction
    public static Response send(Id opportunityId) {
        
        Opportunity opportunity = [SELECT Id, EMailAprovacaoPedidoCliente__c, Account.Name FROM Opportunity WHERE Id = :opportunityId];

        ContentDocumentLink cdl;
        try {
            cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId];
        } catch (Exception e) {
            return new  Response(true, 'Não há anexos para enviar');
        }
        List<ContentVersion> cVersionList = [SELECT Id, Title, FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId  = :cdl.ContentDocumentId];

        // System.debug('cVersionList => ' + cVersionList);
        // System.debug('opportunity.Account.Name => ' + opportunity.Account.Name);
        // System.debug('opportunity.EMailAprovacaoPedidoCliente__c => ' + opportunity.EMailAprovacaoPedidoCliente__c);

        IntegrationUtils.sendMailWithContentVersion(cVersionList, opportunity.Account.Name, opportunity.EMailAprovacaoPedidoCliente__c);

        return new Response(opportunity.Id);

    }

    public class Response {
        public String recordId {get;set;}
        public Boolean hasError {get;set;}
        public String errorMessage {get;set;}

        public Response(String recordId) {
            this.hasError = false;
            this.errorMessage = '';
            this.recordId = recordId;
        }

        public Response(Boolean hasError, String errorMessage) {
            this.hasError = hasError;
            this.errorMessage = errorMessage;
            this.recordId = '';
        }
    }
}