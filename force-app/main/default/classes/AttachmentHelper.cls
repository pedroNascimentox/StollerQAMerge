public without sharing class AttachmentHelper {

    private AttachmentParameter attachmentParameter { get; set; }

    public AttachmentHelper(AttachmentParameter attachmentParameter) {
        this.attachmentParameter = attachmentParameter;
    }

    public String generateAttachment() {
         return attachmentParameter.buildAttachment();
    }

    public class AttachmentParameter{

        private String objectId;
        private Map<String, String> urlParameterToValueMap;
        private String title;
        private String urlPageReference;
        private PageReference page;

        public AttachmentParameter(String objectId, Map<String, String>  urlParameterToValueMap, String title, String urlPageReference){
            this.objectId = objectId;
            this.urlParameterToValueMap = urlParameterToValueMap;
            this.title = title;
            this.urlPageReference = urlPageReference;
        }

        public AttachmentParameter(String objectId, Map<String, String>  urlParameterToValueMap, String title, PageReference page){
            this.objectId = objectId;
            this.urlParameterToValueMap = urlParameterToValueMap;
            this.title = title;
            this.page = page;
        }


        public String buildAttachment(){

            PageReference pageRef;

            if(this.page != null){
                pageRef = this.page;
            } else {
                pageRef = new PageReference(this.urlPageReference);
            }

            for(String param : this.urlParameterToValueMap.keySet()){
                pageRef.getParameters().put(param, this.urlParameterToValueMap.get(param));
            }
            
            Blob pdf = !Test.isRunningTest() ? pageRef.getContentAsPDF() : Blob.valueOf('Test');

            ContentVersion ctVersion    = new ContentVersion();
            ctVersion.Title             = this.title + '.pdf';
            ctVersion.PathOnClient      = this.title + '.pdf';
            ctVersion.VersionData       = pdf;
            insert ctVersion;

            ContentDocumentLink cdl     = new ContentDocumentLink();
            cdl.ContentDocumentId       = [SELECT id, contentDocumentId FROM ContentVersion WHERE id = :ctVersion.id].contentDocumentId;
            cdl.LinkedEntityId          = this.objectId;
            cdl.ShareType               = 'V';
            delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :this.objectId];
            insert cdl;

            System.debug('ctVersion.Idontent Version Id -> ' + ctVersion.Id);

            return ctVersion.Id;

        }
    }


}