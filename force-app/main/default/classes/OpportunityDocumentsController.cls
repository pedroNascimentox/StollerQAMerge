public class OpportunityDocumentsController {

    public List<DocumentVO> items {get; set;}
    public List<List<DocumentVO>> listofItems {get; set;}
    public Boolean userHasFullAccess {get; set;}
    
    public OpportunityDocumentsController(){
        items = new List<DocumentVO>();
        listofItems = new List<List<DocumentVO>>();
        userHasFullAccess();
        getDocuments();
    }

    public void userHasFullAccess(){

        Profile userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        userHasFullAccess = userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM) || userProfile.name.containsIgnoreCase('Admin');

    }

    public OpportunityDocumentsController(ApexPages.StandardController controller){
        items = new List<DocumentVO>();
        listofItems = new List<List<DocumentVO>>();
        getDocuments();
        userHasFullAccess();
        System.debug('items.size() => ' + items.size());
        System.debug('userHasFullAccess => ' + userHasFullAccess);
    }

    @RemoteAction//
    public static OpportunityDocumentsReturn validateOpportunityDocuments(List<String> documentIds){//

        OpportunityDocumentsReturn returnData;//

        try {//

            List<DocumentoOportunidade__c> opportunityDocumentsToValidate = [//
                SELECT  id, validado__c, //
                        oportunidade__c, tipoDocumento__c//
                FROM DocumentoOportunidade__c//
                WHERE id IN :documentIds//
            ];//

            Id userId = UserInfo.getUserId();//
            Date today = Date.today();//

            Set<Id> opportunitiesToApprove = new Set<Id>();//

            for(DocumentoOportunidade__c opportunityDocument : opportunityDocumentsToValidate){//
                //
                opportunityDocument.validado__c = true;//
                opportunityDocument.dataValidacao__c = today;//
                opportunityDocument.usuarioValidador__c = userId;//
                //
            }

            update opportunityDocumentsToValidate;//

            returnData = new OpportunityDocumentsReturn('Os documentos da oportunidade foram validados!');//
        //
        } catch (Exception e){//

            returnData = new OpportunityDocumentsReturn(e);//

        }//

        System.debug('returnData => ' + returnData);//

        return returnData;//

    }//

    @RemoteAction
    public static OpportunityDocumentsReturn deleteOpportunityDocuments(List<String> documentIds){

        OpportunityDocumentsReturn returnData;

        try {

            List<DocumentoOportunidade__c> opportunityDocumentsToValidate = [
                SELECT id, validado__c
                FROM DocumentoOportunidade__c
                WHERE id IN :documentIds
            ];

            delete opportunityDocumentsToValidate;

            returnData = new OpportunityDocumentsReturn('Os documentos da oportunidade foram excluídos com sucesso!');
        
        } catch (Exception e){

            returnData = new OpportunityDocumentsReturn(e);

        }

        System.debug('returnData => ' + returnData);

        return returnData;

    }
     
    public void getDocuments(){

        Map<Id, DocumentoOportunidade__c> opportunityDocumentMap = new Map<Id, DocumentoOportunidade__c>([
            SELECT id, oportunidade__c, oportunidade__r.numeroOportunidade__c, tipoDocumento__c, dataValidacao__c, 
            validado__c, createdDate, usuarioValidador__r.id, usuarioValidador__r.name, owner.name, ownerId, 
            oportunidade__r.nomeRTV__c, oportunidade__r.gerenteRegional__r.name, oportunidade__r.account.name,
            oportunidade__r.stageName
            FROM DocumentoOportunidade__c 
            WHERE validado__c = false
            ORDER BY createdDate DESC
        ]);

        if (!opportunityDocumentMap.isEmpty()){
            
            List<ContentDocumentLink> contentDocumentLinkList = [
                SELECT id, contentDocumentId, linkedEntityId, contentDocument.title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :opportunityDocumentMap.keySet()
            ];

            items = new List<DocumentVO>();     

            for (ContentDocumentLink item : contentDocumentLinkList){

                DocumentVO itemVO = new DocumentVO(item);
                itemVO.setContentDocument(opportunityDocumentMap.get(item.linkedEntityId));
                items.add(itemVO);

                if(items.size() == 999){
                    listOfItems.add(items);
                    items = new List<DocumentVO>();
                }
            }

            if(items.size() != 0){
                listofItems.add(items);
            }
        }
    }

    @RemoteAction
    public static OpportunityDocumentsReturn getDocumentsRemote(){

        OpportunityDocumentsReturn returnData;

        try {

            Map<Id, DocumentoOportunidade__c> opportunityDocumentMap = new Map<Id, DocumentoOportunidade__c>([
                SELECT id, oportunidade__c, oportunidade__r.numeroOportunidade__c, tipoDocumento__c, dataValidacao__c, 
                validado__c, createdDate, usuarioValidador__r.id, usuarioValidador__r.name, owner.name, ownerId, 
                oportunidade__r.nomeRTV__c, oportunidade__r.gerenteRegional__r.name, oportunidade__r.account.name,
                oportunidade__r.stageName
                FROM DocumentoOportunidade__c 
                WHERE validado__c = false
                ORDER BY createdDate DESC
            ]);

            List<DocumentVO> itemsList = new List<DocumentVO>();
            List<List<DocumentVO>> listOfItemsList = new List<List<DocumentVO>>();

            if (!opportunityDocumentMap.isEmpty()){
                
                List<ContentDocumentLink> contentDocumentLinkList = [
                    SELECT id, contentDocumentId, linkedEntityId, contentDocument.title
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :opportunityDocumentMap.keySet()
                ];

                for (ContentDocumentLink item : contentDocumentLinkList){

                    DocumentVO itemVO = new DocumentVO(item);
                    itemVO.setContentDocument(opportunityDocumentMap.get(item.linkedEntityId));
                    itemsList.add(itemVO);

                    if(itemsList.size() == 999){
                        listOfItemsList.add(itemsList);
                        itemsList = new List<DocumentVO>();
                    }
                }

                if(itemsList.size() != 0){
                    listOfItemsList.add(itemsList);
                }
            }

            returnData = new OpportunityDocumentsReturn(listOfItemsList);
        
        } catch (Exception e) {
            
            returnData = new OpportunityDocumentsReturn(e);
        
        }

        return returnData;
    }
    
    public class DocumentVO{
        public String  id                            {get; set;}
        public String  opportunityId                 {get; set;}
        public String  opportunityName               {get; set;}
        public String  typeOfDocument                {get; set;}
        public Boolean validated                     {get; set;}
        public String  responsibleUserId             {get; set;}
        public String  responsibleUserName           {get; set;}
        public String  createdDate                   {get; set;}
        public String  validatorUserId               {get; set;}
        public String  validatorUserName             {get; set;}
        public String  validationDate                {get; set;}
        public String  documentName                  {get; set;}
        public String  documentId                    {get; set;}
        public String  linkedEntityId                {get; set;}
        public String  rtvName                       {get; set;}
        public String  grName                        {get; set;}
        public String  customerName                  {get; set;}
        public String  opportunityStatus             {get; set;}

        public DocumentVO(ContentDocumentLink item){            
            this.documentName        = item.contentDocument.title;
            this.documentId          = item.contentDocumentId;
            this.linkedEntityId      = item.linkedEntityId;
        }
        
        public void setContentDocument(DocumentoOportunidade__c item){
            this.id                  = item.id;
            this.opportunityId       = item.oportunidade__c;
            this.opportunityName     = item.oportunidade__r.numeroOportunidade__c;
            this.typeOfDocument      = String.isBlank(item.tipoDocumento__c)? '' : item.tipoDocumento__c;
            this.validated           = item.validado__c;
            this.responsibleUserId   = item.ownerId;
            this.responsibleUserName = String.isBlank(item.owner.name)? '' : item.owner.name;
            this.createdDate         = String.valueOf(item.createdDate.date());
            this.validatorUserId     = item.usuarioValidador__r.id;
            this.validatorUserName   = String.isBlank(item.usuarioValidador__r.name)? '' : item.usuarioValidador__r.name;
            this.validationDate      = String.valueOf(item.dataValidacao__c);
            this.rtvName             = String.isBlank(item.oportunidade__r.nomeRTV__c)? '' : item.oportunidade__r.nomeRTV__c;
            this.grName              = String.isBlank(item.oportunidade__r.gerenteRegional__r.name)? '' : item.oportunidade__r.gerenteRegional__r.name;
            this.customerName        = String.isBlank(item.oportunidade__r.account.name)? '' : item.oportunidade__r.account.name;
            this.opportunityStatus   = item.oportunidade__r.stageName;
        }
    }

    public class OpportunityDocumentsReturn extends ResultTemplate{

        public List<List<DocumentVO>> data;

        public OpportunityDocumentsReturn(List<List<DocumentVO>> data){
            this.data        = data;
            this.hasErrors   = false;
            this.message     = 'Success';
            this.stackStrace = null;
        }

        public OpportunityDocumentsReturn(String message) {
            this.hasErrors   = false;
            this.message     = message;
            this.stackStrace = null;
        }

        public OpportunityDocumentsReturn(Exception error) {
            this.hasErrors   = true;
            this.message     = error.getMessage();
            this.stackStrace = error.getStackTraceString();
        }

    }
}