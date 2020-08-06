public class sendDeliveryChangeController {
    public static  String CUSTOMER_ID {get;set;}
    
    public sendDeliveryChangeController() {}

    public sendDeliveryChangeController(ApexPages.StandardController standardController) {
        CUSTOMER_ID = [SELECT id, Queue.Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName = 'CustomerService' LIMIT 1].Queue.Id; 
    }
    
    @RemoteAction
    public static Response approveProcessPage(String objId, string comments){
        try{
            if(Approval.isLocked(objId)){
                ProcessInstanceWorkitem processItem = null;
                for(ProcessInstanceWorkitem processItems : [SELECT  id, processInstance.targetObjectId, ActorId
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE processInstance.status = 'Pending' 
                                                    AND processInstance.targetObjectId = :objId LIMIT 1]){
                    processItem = processItems;
                }
                if(processItem == null){
                    return new Response(true, Label.MissingApprovalProcess);                    
                }

                if(isApprover(processItem)){
                    return ApproveProcess(objId, true, comments, processItem.Id);
                }else{
                    return new Response(true, Label.NotCorrectApprover);
                }  
            }else{
                return new Response(true, Label.MissingApprovalProcess);
            }
        }catch(Exception ex){
            return new Response(true, ex.getMessage());
        }
    }
    @RemoteAction
    public static Response rejectedProcessPage(String objId, string comments){
        try{
            if(Approval.isLocked(objId)){
                ProcessInstanceWorkitem processItem = [SELECT  id, processInstance.targetObjectId, ActorId
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE processInstance.status = 'Pending' 
                                                    AND processInstance.targetObjectId = :objId LIMIT 1]; 
                if(isApprover(processItem)){
                    // if(isLastApprover(processItem)){
                    Response respSap = trySendSAP(objId);
                    // }
                    if(!respSap.errorMessage.contains(Label.DocumentoEmUsoSAP) && !respSap.errorMessage.contains(Label.DocumentoEmBloqueadoSAP))
                        return ApproveProcess(objId, false, comments, processItem.Id);
                    else{
                        respSap.hasError = true;
                        return respSap;
                    }
                }else{
                    return new Response(true, Label.NotCorrectApprover);
                }                
            }else{
                return new Response(true, Label.MissingApprovalProcess);
            }
        }catch(Exception ex){
            return new Response(true, ex.getMessage());
        }
    }
    public static Response trySendSAP(String objId){
        String myIdPrefix = String.valueOf(objId).substring(0,3);
        Set<Id> ordItemSet = new Set<Id>();
        Boolean integrated = true;
        String currReason = '';

        Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
        for(Schema.SObjectType stype : gd.values()){
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            if(prefix !=null && prefix.equals(myIdPrefix)){
                String objectName = r.getName();
                if(objectName == 'AlteracaoDataEntrega__c'){
                    currReason = 'Z1';
                    for(AlteracaoDataEntregaItem__c item : [SELECT ItemPedido__c FROM AlteracaoDataEntregaItem__c WHERE AlteracaoDataEntrega__c =: objId]){
                        ordItemSet.add(item.ItemPedido__c);
                    }
                }else if(objectName == 'SolicitacaoCancelamento__c'){ 
                    currReason = 'ZS';                   
                    for(Cancelamento__c item : [SELECT ItemPedido__c, SolicitacaoCancelamento__r.OrdemIntegrada__c FROM Cancelamento__c WHERE SolicitacaoCancelamento__c =: objId]){
                        ordItemSet.add(item.ItemPedido__c);
                        integrated = item.SolicitacaoCancelamento__r.OrdemIntegrada__c;
                    }
                }
            }
        }
        String responseOut = '';
        if(integrated){
            try{
                responseOut = IntegrationOutboundCancellation.sendCancellation(ordItemSet, '');
            }catch(Exception ex){
                return new Response(true, Label.ErrorConnectingSAP);
            }
            TemplateDataIntegrationFields.DocumentSAP responseDocument = (TemplateDataIntegrationFields.DocumentSAP)JSON.deserialize(responseOut, TemplateDataIntegrationFields.DocumentSAP.class);
            if(responseDocument.response[0].message.contains(Label.DocumentoEmUsoSAP) || responseDocument.response[0].message.contains(Label.DocumentoEmBloqueadoSAP)){
                List<OrderITem> ordUpdtList = new List<OrderITem>();
                for(Id ordId : ordItemSet){
                    ordUpdtList.add(new OrderITem(id = ordId, MotivoRecusaItem__c = currReason));
                }
                if(!ordUpdtList.isEmpty()){
                    OrderITemHelper.disableTrigger();
                    update ordUpdtList;
                    OrderITemHelper.enableTrigger();
                }
            }
            return new Response(false, responseDocument.response[0].message); 
        }else{
            return new Response(false, 'Success'); 
        }

    }
    public static Boolean isLastApprover(ProcessInstanceWorkitem processItem){
        return CUSTOMER_ID == processItem.ActorId;
    }
    public static Boolean isApprover(ProcessInstanceWorkitem processItem){
        return (CUSTOMER_ID == processItem.ActorId ? checkQueueMember(UserInfo.getUserId()) : UserInfo.getUserId() == processItem.ActorId);
    }
    public static Boolean checkQueueMember(Id UserId){
        User logged = [SELECT id, UserRoleId  FROM User WHERE id  = :userId LIMIT 1];
        Group grp = [SELECT id, RelatedId FROM Group WHERE id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :CUSTOMER_ID) LIMIT 1];
        
        return logged.UserRoleId == grp.RelatedId;
    }
    public static Response ApproveProcess(String objId, Boolean approve, string comments, Id itemId){
        String action = approve ? 'Approve' : 'Reject';
        try{
            List<Approval.ProcessWorkitemRequest> itemsFinalActions = new List<Approval.ProcessWorkitemRequest>();
            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
            request.setWorkItemId(itemId);
            request.setAction(action); 
            request.setComments(comments);
            itemsFinalActions.add(request);            
            if (!itemsFinalActions.isEmpty()){
                System.debug('itemsFinalActions => ' + itemsFinalActions);
                Approval.process(itemsFinalActions);
            }
            return new Response(objId);
        }catch(Exception ex){
            return new Response(true, ex.getMessage());
        }
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

    public class ApprovalProcessException extends Exception{}
}