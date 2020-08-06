trigger Opportunity on Opportunity (before insert, before update, after update, after insert, before delete) {
    if (OpportunityHelper.isTriggerEnabled()){
        switch on Trigger.operationType{

            when BEFORE_INSERT {
                OpportunityHelper.changeOpportunityOwner(Trigger.new);
            }

            when BEFORE_UPDATE {
                OpportunityHelper.case31720(Trigger.new);
                OpportunityHelper.stageNameChanged(Trigger.oldMap, Trigger.newMap);
                // OpportunityHelper.createTasksForRTVs(Trigger.newMap, Trigger.oldMap);
                OpportunityHelper.removeCampaignFieldsIfNeeded(Trigger.oldMap, Trigger.newMap);
                OpportunityHelper.sendEmailApprovalClient(Trigger.oldMap, Trigger.newMap);
                OpportunityHelper.createDeliveryRecords(Trigger.oldMap, Trigger.newMap);//
                OpportunityHelper.relayUpdatedBusinessLocationToChildDeliveryRecords(Trigger.oldMap, Trigger.newMap);
                OpportunityHelper.seeCreditApprovalResult(Trigger.oldMap, Trigger.newMap);
                // OpportunityHelper.applyOpportunitySharingRule(Trigger.oldMap, Trigger.newMap);
                OpportunityHelper.changeOpportunityOwner(Trigger.new);
            }

            when AFTER_INSERT {
                OpportunityHelper.changeOpportunityName(Trigger.newMap);
                // OpportunityHelper.changeOpportunityOwner(Trigger.newMap);
                // OpportunityHelper.createOpportunitySharingRule(Trigger.new);
            }

            when AFTER_UPDATE {
                
                 OpportunityHelper.fillDadosAprovacao(new List<Id>(Collection.of(Trigger.new).pluckIds(Opportunity.Id)));
            }
            when BEFORE_DELETE {
                OpportunityHelper.blockDelete(Trigger.old);
            }
        }
    } 
}