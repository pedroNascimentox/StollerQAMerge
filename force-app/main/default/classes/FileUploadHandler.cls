public class FileUploadHandler {

    @AuraEnabled
    public static Boolean userHasFullAccess(){
        
        Profile userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        return (userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM) || userProfile.name.containsIgnoreCase('Admin'));

    }
    
    @AuraEnabled  
    public static List<DocumentVO> getFiles(String recordId){ 

        Map<Id, DocumentoOportunidade__c> idToOpportunityDocument = new Map<Id, DocumentoOportunidade__c>([
            SELECT  id, tipoDocumento__c, validado__c, ownerId, owner.name, createdDate, 
                    usuarioValidador__c, usuarioValidador__r.name, dataValidacao__c
            FROM DocumentoOportunidade__c
            WHERE oportunidade__c = :recordId
            ORDER BY createdDate DESC
        ]);

        List<DocumentVO> documentVOList = new List<DocumentVO>();

        Set<Id> opportunityDocumentIdsToDelete = new Set<Id>();

        for(DocumentoOportunidade__c opportunityDocument : idToOpportunityDocument.values()){
            if(String.isBlank(opportunityDocument.tipoDocumento__c)){
                opportunityDocumentIdsToDelete.add(opportunityDocument.id);
                idToOpportunityDocument.remove(opportunityDocument.id);
            }
        }

        if(!opportunityDocumentIdsToDelete.isEmpty()){
            delete [SELECT id FROM DocumentoOportunidade__c WHERE id IN :opportunityDocumentIdsToDelete];
        }

        if(!idToOpportunityDocument.isEmpty()){
        
            Set<Id> documentIds = new Set<Id>(); 
            List<ContentDocumentLink> cdl = [SELECT id, linkedEntityId, contentDocumentId FROM ContentDocumentLink WHERE linkedEntityId IN :idToOpportunityDocument.keySet()];
            Map<Id, Id> contentDocumentIdToOpportunityDocumentId = new Map<Id, Id>();
        
            for(ContentDocumentLink cdLink : cdl){  
                documentIds.add(cdLink.contentDocumentId);
                contentDocumentIdToOpportunityDocumentId.put(cdLink.contentDocumentId, cdLink.linkedEntityId);
            }
            
            List<ContentDocument> contentDocuments = [SELECT id, title, fileType FROM ContentDocument WHERE id IN :contentDocumentIdToOpportunityDocumentId.keySet()];

            for(ContentDocument contentDocument : contentDocuments){
                
                DocumentVO documentVO = new DocumentVO(contentDocument);
                documentVO.setOpportunityDocumentData(idToOpportunityDocument.get(contentDocumentIdToOpportunityDocumentId.get(contentDocument.id)));

                documentVOList.add(documentVO);
            }

            System.debug('documentVOList => ' + documentVOList);
        
        }

        return documentVOList;

    }

    @AuraEnabled
    public static void reattributeFiles(String recordId, List<String> contentDocumentIds){

        List<DocumentoOportunidade__c> opportunityDocumentsToInsert = new List<DocumentoOportunidade__c>();

        System.debug('contentDocumentIds => ' + contentDocumentIds);
        System.debug('contentDocumentIds.size() => ' + contentDocumentIds.size());
        System.debug('contentDocumentIds => ' + JSON.serialize(contentDocumentIds));

        for(String contentDocumentId : contentDocumentIds){
            
            DocumentoOportunidade__c opportunityDocument = new DocumentoOportunidade__c(
                oportunidade__c = recordId
            );
            
            opportunityDocumentsToInsert.add(opportunityDocument);
        
        }

        System.debug('opportunityDocumentsToInsert => ' + opportunityDocumentsToInsert);
        System.debug('opportunityDocumentsToInsert.size() => ' + opportunityDocumentsToInsert.size());

        insert opportunityDocumentsToInsert;

        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

        for(Integer i = 0; i < contentDocumentIds.size(); i++){
            
            ContentDocumentLink cdl = new ContentDocumentLink(
                contentDocumentId = contentDocumentIds[i],
                linkedEntityId    = opportunityDocumentsToInsert[i].id,
                shareType         = 'I'
            );

            contentDocumentLinksToInsert.add(cdl);

        }

        insert contentDocumentLinksToInsert;

        delete [SELECT id FROM ContentDocumentLink WHERE linkedEntityId = :recordId AND contentDocumentId IN :contentDocumentIds];

    }
    
    @AuraEnabled  
    public static FileUploadHandlerReturn deleteFiles(List<String> opportunityDocumentIdsToDelete, Boolean userHasFullAccess){

        System.debug('opportunityDocumentIdsToDelete => ' + opportunityDocumentIdsToDelete);

        FileUploadHandlerReturn result;

        try {

            List<DocumentoOportunidade__c> opportunityDocuments = [
                SELECT id, validado__c FROM DocumentoOportunidade__c WHERE id IN :opportunityDocumentIdsToDelete
            ];

            for(DocumentoOportunidade__c opportunityDocument : opportunityDocuments){
                if(opportunityDocument.validado__c && !userHasFullAccess){
                    throw new FileUploadHandlerException('Você não pode deletar um documento da oportunidade que já foi validado!');
                }
            }

            System.debug('opportunityDocuments => ' + opportunityDocuments);
            
            delete [SELECT id FROM DocumentoOportunidade__c WHERE id IN :opportunityDocumentIdsToDelete];

            result = new FileUploadHandlerReturn('Documentos da oportunidade deletados com sucesso!');
        
        } catch (Exception e){

            System.debug('e.getMessage() => ' + e.getMessage());

            result = new FileUploadHandlerReturn(e);

        }

        System.debug('result => ' + result);

        return result;
    }

    @AuraEnabled  
    public static FileUploadHandlerReturn validateFiles(List<String> opportunityDocumentIdsToValidate){

        FileUploadHandlerReturn result;

        try {

            System.debug('opportunityDocumentIdsToValidate => ' + opportunityDocumentIdsToValidate);
            
            List<DocumentoOportunidade__c> opportunityDocumentsToValidate = [
                SELECT id, validado__c, dataValidacao__c, usuarioValidador__c
                FROM DocumentoOportunidade__c
                WHERE id IN :opportunityDocumentIdsToValidate
                AND validado__c = false
            ];

            if(!opportunityDocumentsToValidate.isEmpty()){

                Id validatorUserId = UserInfo.getUserId();

                for(DocumentoOportunidade__c opportunityDocument : opportunityDocumentsToValidate){
                    opportunityDocument.validado__c         = true;
                    opportunityDocument.dataValidacao__c    = Date.today();
                    opportunityDocument.usuarioValidador__c = validatorUserId;
                }

                update opportunityDocumentsToValidate;

                result = new FileUploadHandlerReturn('Documentos da Oportunidade valiadados com sucesso!');
            
            } else {

                throw new FileUploadHandlerException('Todos os documentos selecionados já foram validados!');

            }
        
        } catch (Exception e){

            result = new FileUploadHandlerReturn(e);

        }

        return result;

    }

    @AuraEnabled
    public static List<DocumentVO> getOpportunityDocumentsByDocumentId(List<String> contentDocumentIds){

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT id, linkedEntityId, contentDocumentId, contentDocument.title
            FROM ContentDocumentLink
            WHERE contentDocumentId IN :contentDocumentIds
        ];

        List<Id> opportunityDocumentIds = Collection.of(contentDocumentLinks).pluckIds(ContentDocumentLink.linkedEntityId);

        Map<Id, DocumentoOportunidade__c> idToOpportunityDocument = new Map<Id, DocumentoOportunidade__c>([
            SELECT id, tipoDocumento__c, validado__c, ownerId, owner.name, createdDate, 
                    usuarioValidador__c, usuarioValidador__r.name, dataValidacao__c
            FROM DocumentoOportunidade__c
            WHERE id IN :opportunityDocumentIds
            ORDER BY createdDate DESC
        ]);


        System.debug('idToOpportunityDocument => ' + JSON.serializePretty(idToOpportunityDocument));
        System.debug('idToOpportunityDocument.keySet() => ' + idToOpportunityDocument.keySet());

        List<DocumentVO> documentVOList = new List<DocumentVO>();

        System.debug('contentDocumentLinks.size() => ' + contentDocumentLinks.size());

        for(ContentDocumentLink cdl : contentDocumentLinks){
            System.debug('idToOpportunityDocument.get(cdl.linkedEntityId) => ' + JSON.serializePretty(idToOpportunityDocument.get(cdl.linkedEntityId)));
            System.debug('cdl.linkedEntityId => ' + cdl.linkedEntityId);
            if(idToOpportunityDocument.containsKey(cdl.linkedEntityId)){
                DocumentVO documentVO = new DocumentVO();
                documentVO.setOpportunityDocumentData(idToOpportunityDocument.get(cdl.linkedEntityId));
                documentVO.setContentDocumentData(cdl);
                documentVOList.add(documentVO);
            }
        }

        System.debug('documentVOList => ' + JSON.serializePretty(documentVOList));

        return documentVOList;
        
    }

    @AuraEnabled
    public static void cancelDocuments(List<String> contentDocumentIds, List<String> opportunityDocumentIds){

        System.debug('contentDocumentIds => ' + contentDocumentIds);
        System.debug('opportunityDocumentIds => ' + opportunityDocumentIds);
        
        delete [SELECT id FROM ContentDocument WHERE id IN :contentDocumentIds];

        delete [SELECT id FROM DocumentoOportunidade__c WHERE id IN :opportunityDocumentIds];

    }

    @AuraEnabled
    public static void saveNewDocumentTypes(List<DocumentVO> opportunityDocuments){

        System.debug('opportunityDocuments => ' + JSON.serializePretty(opportunityDocuments));
        System.debug('opportunityDocuments.size() => ' + opportunityDocuments.size());

        List<DocumentoOportunidade__c> opportunityDocumentsToUpdate = new List<DocumentoOportunidade__c>();

        for(DocumentVO document : opportunityDocuments){
            System.debug('document => ' + document);
            System.debug('document.opportunityDocumentId => ' + document.opportunityDocumentId);
            DocumentoOportunidade__c opportunityDocument = new DocumentoOportunidade__c(
                id = document.opportunityDocumentId,
                tipoDocumento__c = document.documentType
            );
            opportunityDocumentsToUpdate.add(opportunityDocument);
        }

        System.debug('opportunityDocumentsToUpdate => ' + JSON.serializePretty(opportunityDocumentsToUpdate));

        update opportunityDocumentsToUpdate;

    }

    @AuraEnabled
    public static List<String> getDocumentTypes(){
        
        List<String> pickListValuesList = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = DocumentoOportunidade__c.TipoDocumento__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        System.debug('ple => ' + JSON.serializePretty(ple));
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     

        System.debug('pickListValuesList => ' + pickListValuesList);
        
        return pickListValuesList;

    }

    public class DocumentVO {

        @AuraEnabled
        public String  documentType          {get; set;}
        @AuraEnabled
        public Boolean validated             {get; set;}
        @AuraEnabled
        public String  responsibleUserId     {get; set;}
        @AuraEnabled
        public String  responsibleUserName   {get; set;}
        @AuraEnabled
        public String  createdDate           {get; set;}
        @AuraEnabled
        public String  validatorUserId       {get; set;}
        @AuraEnabled
        public String  validatorUserName     {get; set;}
        @AuraEnabled
        public String  validationDate        {get; set;}
        @AuraEnabled
        public String  documentName          {get; set;}
        @AuraEnabled
        public String  documentId            {get; set;}
        @AuraEnabled
        public String  opportunityDocumentId {get; set;}
        
        public DocumentVO(){}

        public DocumentVO(ContentDocument contentDocument){
            this.documentName = contentDocument.title;
            this.documentId   = contentDocument.id;
        }

        public void setContentDocumentData(ContentDocumentLink contentDocumentLink){
            this.documentName = contentDocumentLink.contentDocument.title;
            this.documentId   = contentDocumentLink.contentDocumentId;
        }

        public void setOpportunityDocumentData(DocumentoOportunidade__c opportunityDocument){
            documentType          = opportunityDocument.tipoDocumento__c == null? '' : opportunityDocument.tipoDocumento__c;
            validated             = opportunityDocument.validado__c;
            responsibleUserId     = opportunityDocument.ownerId;
            responsibleUserName   = opportunityDocument.owner.name;
            createdDate           = String.valueOf(opportunityDocument.createdDate.date().format());
            validatorUserId       = opportunityDocument.usuarioValidador__c;
            validatorUserName     = opportunityDocument.usuarioValidador__r.name;
            validationDate        = opportunityDocument.dataValidacao__c != null? String.valueOf(opportunityDocument.dataValidacao__c.format()) : '';
            opportunityDocumentId = opportunityDocument.id;
        }

    }

    public class FileUploadHandlerReturn {

        @AuraEnabled
        public Boolean hasErrors;
        @AuraEnabled
        public String  message;
        @AuraEnabled
        public String  stackTrace;
        
        public FileUploadHandlerReturn(String message){
            this.hasErrors = false;
            this.message = message;
            this.stackTrace = null;
        }

        public FileUploadHandlerReturn(Exception e){
            this.hasErrors = true;
            this.message = e.getMessage();
            this.stackTrace = e.getStackTraceString();
        }

    }

    public class FileUploadHandlerException extends Exception{}
}