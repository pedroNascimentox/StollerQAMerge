public class OpportunityDocumentHelper extends TriggerContext{
    
    public static void approvalProcessByValidatedOpportunityDocuments(Map<Id, DocumentoOportunidade__c> oldRecordsMap, Map<Id, DocumentoOportunidade__c> newRecordsMap){

        List<DocumentoOportunidade__c> opportunityDocumentsFiltered = [
            SELECT id, oportunidade__c, oportunidade__r.stageName, tipoDocumento__c, validado__c
            FROM DocumentoOportunidade__c
            WHERE id IN : newRecordsMap.keySet()
            AND oportunidade__r.stageName = 'Em aprovação cliente'
            AND tipoDocumento__c != NULL
        ];
        
        if(!opportunityDocumentsFiltered.isEmpty()){

            Set<Id> opportunitiesToApprove = new Set<Id>();

            for(DocumentoOportunidade__c opportunityDocument : opportunityDocumentsFiltered){
                System.debug('opportunityDocument.validado__c => ' + opportunityDocument.validado__c);
                System.debug('oldRecordsMap.get(opportunityDocument.id).validado__c => ' + oldRecordsMap.get(opportunityDocument.id).validado__c);
                System.debug('opportunityDocument.tipoDocumento__c.toLowerCase() => ' + opportunityDocument.tipoDocumento__c.toLowerCase());
                if(newRecordsMap.get(opportunityDocument.id).validado__c && !oldRecordsMap.get(opportunityDocument.id).validado__c && opportunityDocument.tipoDocumento__c.toLowerCase() == 'oportunidade aprovada'){
                    opportunitiesToApprove.add(opportunityDocument.oportunidade__c);
                }
            }

            System.debug('opportunitiesToApprove => ' + opportunitiesToApprove);//

            if(!opportunitiesToApprove.isEmpty()){//
                //
                List<ProcessInstanceWorkItem> processInstanceWorkItems = [//
                    SELECT id, actorId, originalActorId, processInstanceId, processInstance.targetObjectId//
                    FROM ProcessInstanceWorkitem//
                    WHERE processInstance.targetObjectId IN :opportunitiesToApprove//
                    AND processInstance.status = 'Pending'//
                ];//

                System.debug('processInstanceWorkItems => ' + processInstanceWorkItems);//

                List<Approval.ProcessWorkitemRequest> itemsFinalActions = new List<Approval.ProcessWorkitemRequest>();//
                //
                for(ProcessInstanceWorkitem item : processInstanceWorkItems){//
                    Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();//
                    request.setWorkItemId(item.id);//
                    request.setAction('Approve'); //
                    itemsFinalActions.add(request);//
                }//

                if (!itemsFinalActions.isEmpty()){//
                    System.debug('itemsFinalActions => ' + itemsFinalActions);//
                    Approval.process(itemsFinalActions);//
                }//

                List<Opportunity> opportunities = [SELECT id, stagename FROM Opportunity WHERE id IN :opportunitiesToApprove];//

                for(Opportunity opportunity : opportunities){//
                    opportunity.stageName = 'Aprovado Cliente';//
                    opportunity.DontChangeStageName__c = true;
                    opportunity.closeDate = Date.today();
                }//

                update opportunities;//
                //
            }//
        }
    }
}