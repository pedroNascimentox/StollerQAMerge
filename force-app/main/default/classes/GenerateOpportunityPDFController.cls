public without sharing class GenerateOpportunityPDFController {

    public Boolean isSF1 {get; set;}

    public GenerateOpportunityPDFController(ApexPages.StandardController stdController) {
        
        if (isSalesforceOne()) isSF1 = true; 
        else isSF1 = false;
    }

    @RemoteAction
    public static Response generateAttachment(String opportunityId){

        // Order opportunity = OrderDAO.getOrderById(
        //     new List<String>{opportunityId}, 
        //     new Set<String>{'Id', 'AccountId', 'OwnerId', 'OrderNumber', 'Status'}
        // ).get(0);

        Opportunity opportunity = [SELECT id, numeroOportunidade__c, stageName FROM Opportunity WHERE id =: opportunityId];

        PageReference pageRef = Page.OpportunityPDF;

        AttachmentHelper.AttachmentParameter attachParameter = new AttachmentHelper.AttachmentParameter(
            opportunity.Id, 
            new Map<String, String>{'Id' => opportunity.Id}, 
            'Negociação-' + opportunity.numeroOportunidade__c,
            pageRef
        );

        AttachmentHelper attachment = new AttachmentHelper(attachParameter);
        return new Response(attachment.generateAttachment());

    }

    public static Boolean isSalesforceOne(){
        System.debug('UserInfo.getUiThemeDisplayed() => ' + UserInfo.getUiThemeDisplayed());
        return !(Test.isRunningTest()) ? UserInfo.getUiThemeDisplayed() == 'Theme4t' : true;
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