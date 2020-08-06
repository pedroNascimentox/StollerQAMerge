global class IncludeAttachmentsController {

    global String PageContents{ get; set; }
    global String caseObjectId{ get; set {
            updateContents(value);
        } 
    }

    public void updateContents(String caseObjectId){
        
        try {
            PageReference pageRef = Page.CaseAttachment;
            pageRef.getParameters().put('caseId', caseObjectId);

            System.debug('pageRef.getContent().toString() => ' + pageRef.getContent().toString());
        
            PageContents = pageRef.getContent().toString().replace('<html style="display:none !important; page-break-inside: avoid;">', '<html>').replace('src=', 'style="width:100% !important;height:100% !important;" src=');
        } catch(Exception ex) { 
            PageContents = 'Um erro ocorreu! Contate a equipe Salesforce.';
        }

        System.debug('PageContents => ' + PageContents);

    }
}