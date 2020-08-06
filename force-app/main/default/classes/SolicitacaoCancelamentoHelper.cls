public class SolicitacaoCancelamentoHelper  extends TriggerContext {

    public static void setTaxe(List<SolicitacaoCancelamento__c> newRecordsList){        
        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
        for(SolicitacaoCancelamento__c request : newRecordsList){
            request.TaxaMedia__c = cotacoesMoeda[0].TaxaMedia__c;
        }
    }

    public static void sendApprovalProcess(Map<Id, SolicitacaoCancelamento__c> oldRecordsMap, Map<Id, SolicitacaoCancelamento__c> newRecordsMap){

        List<SolicitacaoCancelamento__c> filteredRequests = [SELECT id, valorTotalUSD__c FROM SolicitacaoCancelamento__c WHERE id IN :newRecordsMap.keySet()];

        System.debug('teste => ' + filteredRequests[0].valorTotalUSD__c);

        filteredRequests = new List<SolicitacaoCancelamento__c>();

        for(SolicitacaoCancelamento__c request : newRecordsMap.values()){
            if(oldRecordsMap.get(request.id).valorTotalUSD__c <= 0 && request.valorTotalUSD__c > 0){
                filteredRequests.add(request);
            }
        }

        if(!filteredRequests.isEmpty()){

            List<Approval.ProcessSubmitRequest> appRequest = new List<Approval.ProcessSubmitRequest>();
            for(SolicitacaoCancelamento__c requestCancelling : filteredRequests){
                System.debug(requestCancelling);
                System.debug('requestCancelling.valorTotalUSD__c => ' + requestCancelling.valorTotalUSD__c);
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setComments('Processo de aprovação de cancelamento.');
                request.setObjectId(requestCancelling.id);
                request.setSubmitterId(UserInfo.getUserId()); 
                request.setProcessDefinitionNameOrId(requestCancelling.OrdemIntegrada__c ? 'SolicitacaoCancelamentoIntegradoSAP' : 'SolicitacaoCancelamentoNaoIntegradoSAP');

                appRequest.add(request);

            }

            SolicitacaoCancelamentoHelper.disableTrigger();

            Approval.process(appRequest);

            SolicitacaoCancelamentoHelper.enableTrigger();

        }
    }
    
    public static void markOrderItemsAsBlocked(Map<Id, SolicitacaoCancelamento__c> newRecordsMap, Map<Id, SolicitacaoCancelamento__c> oldRecordsMap){
        Map<Id, SolicitacaoCancelamento__c> reqIdMap = new Map<Id, SolicitacaoCancelamento__c>();
        for(SolicitacaoCancelamento__c request : newRecordsMap.values()){            
            SolicitacaoCancelamento__c oldReq = oldRecordsMap.get(request.id);
            if(oldReq.Status__c != request.Status__c){
                reqIdMap.put(request.Id, request);
            }
        }
        if(!reqIdMap.isEmpty()){
            List<Cancelamento__c> updtCancellingList = new List<Cancelamento__c>();
            Map<Id, List<Cancelamento__c>> cancellingContext = (Map<Id, List<Cancelamento__c>>)Collection.of([SELECT id, programacaoEntrega__c, SolicitacaoCancelamento__c FROM Cancelamento__c WHERE SolicitacaoCancelamento__c IN : reqIdMap.keySet()]).groupByIds(Cancelamento__c.SolicitacaoCancelamento__c);
            for(Id reqId : cancellingContext.keySet()){
                SolicitacaoCancelamento__c req = reqIdMap.get(reqId);
                for(Cancelamento__c cancelling : cancellingContext.get(reqId)){
                    cancelling.Status__c = req.Status__c;
                    updtCancellingList.add(cancelling);
                }
            }
            if(!updtCancellingList.isEmpty()){
                update updtCancellingList;
            }
        }
    }
}