trigger OpportunityDocumentTrigger on DocumentoOportunidade__C (before update) {
    if (OpportunityDocumentHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_UPDATE {
                OpportunityDocumentHelper.approvalProcessByValidatedOpportunityDocuments(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}