public without sharing class OpportunityBulkApprovalController {
    private static Map<String, ApprovalPageContent> profileContentMap;
    public static ApprovalPageContent approverContent;
    public String oppId {get;set;}
    static {
        approverContent = new ApprovalPageContent()
                                                  .setStatus('Em Aprovação')
                                                  .setApproveLabel('Aprovar')
                                                  .setRejectLabel('Rejeitar')
                                                  .isFinalApprover(true);

        profileContentMap = new Map<String, ApprovalPageContent>{
			'Administrador do sistema'  => approverContent,
            'Customer Service'  => approverContent
        };
    }
    public ApprovalPageContent pageContent {get;set;}

    public OpportunityBulkApprovalController(){
        this.pageContent = getContentUsingUserProfile();
   
        this.oppId = (ApexPages.currentPage().getParameters().containsKey('Id') ? ApexPages.currentPage().getParameters().get('Id') : null);
   
    }


    @RemoteAction
    public static List<OpportunityData> handleOrderItems(List<Id> oppIds, Boolean approve, String comments){

        List<OpportunityData> orderModalDataToReturn = new List<OpportunityData>();       
            
        Savepoint savepointStatusAprovacao = Database.setSavePoint();
        ApprovalResult approvalResult = approveRecordsBulk(oppIds, approve, comments); 
        if(approvalResult.hasError){
            Database.rollback(savepointStatusAprovacao);
            orderModalDataToReturn.add(new OpportunityData(approvalResult.message));
            return orderModalDataToReturn;
        }
        return getRecords(null, null, null, null, null, null);

    }

    @RemoteAction
    public static OppModalData getModalData(Id oppId){

        Opportunity Opp = [SELECT id, GerenteRegional__c, DiretorComercial__c, NumeroOportunidade__c, Account.name, NomeRTV__c, MotivoOrdem__c, TipoOrdem__c, Campanha__r.Descricao__c, ValorTotalMercadoriasDolar__c, ValorTotalMercadoriasReal__c, moeda__C FROM Opportunity WHERE id = :oppId];

        Double maxDiscount = 0;
        if(opp.GerenteRegional__c == UserInfo.getUserId()){
            maxDiscount = 0;
        }else if(opp.DiretorComercial__c == UserInfo.getUserId()){
            maxDiscount = 3;
        }else{
            maxDiscount = 5;
        }

        OppItemData[] OppItemDataToApprove = new OppItemData[]{};
        OppItemData[] OppItemDataAlreadyHandled = new OppItemData[]{};


        for(OpportunityLineItem obj : [SELECT id, Acrescimo__c, OpportunityId, product2Id, product2.Name, Quantity, UnitPrice, Discount, DescontoExcedente__c, Opportunity.Moeda__C, PrecoVendasJurosBRLUSD__C 
                                       FROM OpportunityLineItem 
                                       WHERE OpportunityId = :Opp.Id]){
            if(obj.DescontoExcedente__c > 0){
                OppItemDataToApprove.add(new OppItemdata(obj, obj.DescontoExcedente__c));
            } else {
                OppItemDataAlreadyHandled.add(new OppItemdata(obj, obj.DescontoExcedente__c));
            }
        }

        OppModalData orderModalData = new OppModalData(Opp, OppItemDataToApprove, OppItemDataAlreadyHandled);


        return orderModalData;
    }
    @RemoteAction
    public static BaseData getBaseData(){
        List<String> orderTypes     = getPickListValue(Opportunity.TipoOrdem__c.getDescribe());
        List<String> orderMotivs    = getPickListValue(Opportunity.MotivoOrdem__c.getDescribe());

        BaseData baseData = new BaseData(orderTypes, orderMotivs);

        return baseData;
    }

    public static List<String> getPickListValue(Schema.DescribeFieldResult fieldResult){

        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        List<String> statusList = new List<String>();

        for(Schema.PicklistEntry value : values){
            statusList.add(value.getValue());
        }

        return statusList;
    }

    @RemoteAction
    public static OpportunityData[] getRecords(String clienteId, String rtvName, String oppNumber, String ordType, String ordMotiv, String oppObsInter){        

        OpportunityData[] result = new OpportunityData[]{};
        ApprovalPageContent pageContent = getContentUsingUserProfile();

        List<ProcessInstanceWorkitem> processInstanceWorkitems = [
            SELECT id, actorId, processInstanceId, processInstance.targetObjectId
            FROM ProcessInstanceWorkitem
            WHERE actorId =: UserInfo.getUserId()
            OR originalActorId =: UserInfo.getUserId()
        ];

        if(!processInstanceWorkitems.isEmpty()){

            Set<Id> targetObjectIds = new Set<Id>();
            Set<Id> processInstanceIds = new Set<Id>();

            for(ProcessInstanceWorkitem processInstanceWorkitem : processInstanceWorkitems){
                processInstanceIds.add(processInstanceWorkitem.processInstanceId);
            }

            List<ProcessInstanceWorkitem> processInstanceWorkitemsFiltered = new List<ProcessInstanceWorkitem>();

            List<ProcessInstanceStep> processInstanceSteps = [SELECT id, processInstanceId, stepStatus FROM ProcessInstanceStep WHERE processInstanceId IN: processInstanceIds AND stepStatus != 'Approved'];
            Set<Id> processInstanceIdsFiltered = new Set<Id>();

            for(ProcessInstanceStep processInstanceStep : processInstanceSteps){
                processInstanceIdsFiltered.add(processInstanceStep.processInstanceId);
            }

            for(ProcessInstanceWorkitem processInstanceWorkitem : processInstanceWorkitems){
                if(processInstanceIdsFiltered.contains(processInstanceWorkitem.processInstanceId)){
                    targetObjectIds.add(processInstanceWorkitem.processInstance.targetObjectId);
                }
            }
            
            List<String> evaluationRequiredsToFilter = new List<String>{'Bonificação em produto', 'Desconto Comercial'};
                
            String query = 'SELECT id, NumeroOportunidade__c, Account.Name, Moeda__c, NomeRTV__c, MotivoOrdem__c, TipoOrdem__c, Campanha__r.Descricao__c, CondicaoPagamento__r.Descricao__c, DataInicioJuros__c, ValorTotalMercadoriasDolar__c, ValorTotalMercadoriasReal__c, AvaliacaoNecessaria__c, ObservacaoInterna__c FROM Opportunity WHERE Id IN :targetObjectIds AND avaliacaoNecessaria__c IN :evaluationRequiredsToFilter';

            if(clienteId != null && clienteId != ''){
                query += ' AND AccountId = : clienteId';
            }
            if(rtvName != null && rtvName != ''){
                rtvName = '%'+rtvName+'%';
                query += ' AND NomeRTV__c LIKE : rtvName';
            }
            if(oppNumber != null && oppNumber != ''){
                oppNumber = '%'+oppNumber+'%';
                query += ' AND NumeroOportunidade__c LIKE :oppNumber';
            }
            if(ordType != null && ordType != ''){
                query += ' AND TipoOrdem__c = :ordType';
            }
            if(ordMotiv != null && ordMotiv != ''){
                query += ' AND MotivoOrdem__c = :ordMotiv';
            }
            List<Opportunity> oppList = (List<Opportunity>)Database.query(query);
            System.debug('filteredList 1 ' + oppList);
            if(oppObsInter != null && oppObsInter != ''){
                oppList = filterOppObsInter(oppList, oppObsInter);                                
            }

            for(Opportunity obj : oppList){
                result.add(new OpportunityData(obj));
            }       
        }else{
            result.add(new OpportunityData('Não há Oportunidades em Processo de Aprovação.'));
        }
        return result;
    }

    public static List<Opportunity> filterOppObsInter(List<Opportunity> opptList, String oppObsInter){
        List<Opportunity> filteredList = new List<Opportunity>();
        for(Opportunity oppt : opptList) {
            if(oppt.ObservacaoInterna__c != null){
                String obs = oppt.ObservacaoInterna__c;
            	if(obs.contains(oppObsInter)){
                	System.debug('oppObsInter ' + oppObsInter);
                	filteredList.add(oppt);
                	System.debug('filteredList 2 ' + filteredList);
            		} 
            }        
        }
        return filteredList;        
    }

    @RemoteAction
    public static List<ResultData> searchLookup(String searchTerm, String tableName, String fieldName, String queryFilterJSON){

        System.debug('searchTerm => ' + searchTerm);
        System.debug('tableName => ' + tableName);
        System.debug('fieldName => ' + fieldName);
        System.debug('queryFilterJSON => ' + queryFilterJSON);

        String columnWhereClause = '%' + searchTerm + '%';
        Map<String, String> columnToValue;
        String queryFilter = '';

        if (queryFilterJSON != null){
            columnToValue = (Map<String, String>) JSON.deserialize(queryFilterJSON, Map<String, String>.class);
            List<String> queryFilterList = new List<String>();

            for(String key : columnToValue.keySet()){
                if (columnToValue.get(key) == 'true' ||
                    columnToValue.get(key) == 'false')
                    queryFilterList.add(key + ' = ' +  columnToValue.get(key));
                else
                    queryFilterList.add(key + ' = ' + '\'' + columnToValue.get(key) + '\'');
            }

            queryFilter = String.join(queryFilterList, ' AND ') + ' AND ';
        }

        List<SObject> queryResult = Database.query(
            String.format('SELECT id, name FROM {0} WHERE {1} {2} LIKE : columnWhereClause LIMIT 900', new List<String> {
                tableName, queryFilter, fieldName
            })
        );
        return parseRowsToResult(queryResult, tableName);
    }

    private static List<ResultData> parseRowsToResult(List<SObject> selectResult, String tableName){
        List<ResultData> toReturn = new List<ResultData>();

        for(SObject row : selectResult){
            toReturn.add(new ResultData(row, tableName));
        }

        return toReturn;
    }

    public static ApprovalResult approveRecordsBulk(List<Id> oppIdToApprove, Boolean approve, String comments){
        String action = approve ? 'Approve' : 'Reject';
        ApprovalPageContent pageContent = getContentUsingUserProfile();

        try{
            List<Approval.ProcessWorkitemRequest> itemsFinalActions =  new List<Approval.ProcessWorkitemRequest>();
            
            for(ProcessInstanceWorkitem item : [SELECT  id, processInstance.targetObjectId 
                                                FROM ProcessInstanceWorkitem 
                                                WHERE processInstance.status = 'Pending' 
                                                AND processInstance.targetObjectId IN : oppIdToApprove]){
                Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                request.setWorkItemId(item.id);
                request.setAction(action); 
                request.setComments(comments);
                itemsFinalActions.add(request);
            }
            if (!itemsFinalActions.isEmpty()){
                System.debug('itemsFinalActions => ' + itemsFinalActions);
                Approval.process(itemsFinalActions);
            }
        } catch (Exception e){
            return new ApprovalResult(e.getMessage());
        }

        return new ApprovalResult(pageContent, oppIdToApprove, approve);
    }
    @RemoteAction
    public static ApprovalResult approveRecords(Id orderIdToApprove, Boolean approve){
        String action = approve ? 'Approve' : 'Reject';
        ApprovalPageContent pageContent = getContentUsingUserProfile();

        try{
            List<Approval.ProcessWorkitemRequest> itemsFinalActions =  new List<Approval.ProcessWorkitemRequest>();
            
            for(ProcessInstanceWorkitem item : [SELECT  id, processInstance.targetObjectId 
                                                FROM ProcessInstanceWorkitem 
                                                WHERE processInstance.status = 'Pending' 
                                                AND processInstance.targetObjectId =: orderIdToApprove]){
                Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                request.setWorkItemId(item.id);
                request.setAction(action); 
                itemsFinalActions.add(request);
            }
            if (!itemsFinalActions.isEmpty()){
                System.debug('itemsFinalActions => ' + itemsFinalActions);
                Approval.process(itemsFinalActions);
            }
        } catch (Exception e){
            return new ApprovalResult(e.getMessage());
        }

        return new ApprovalResult(pageContent, orderIdToApprove, approve);
    }
    private static ApprovalPageContent getContentUsingUserProfile(){
        
        Boolean isProfileValid;
        String exceptionMessage;
        Profile userProfile;
        /*
        try{

            userProfile = [SELECT name FROM Profile WHERE id = :UserInfo.getProfileId()];
            isProfileValid = isProfileValid(userProfile);

            if (!isProfileValid){
                exceptionMessage = String.format(
                    'O perfil "{0}" não tem acesso à essa função.',
                    new List<String>{
                        userProfile.name
                    }
                );
            }

        } catch(QueryException e){
            
            exceptionMessage = 'O usuário não tem perfil atribuído.';
            isProfileValid = false;

        } finally {
            if (!isProfileValid){
                throw new OpportunityBulkApprovalException(exceptionMessage);
            }
        }*/

        return approverContent; //profileContentMap.get(userProfile.name);
    }

    private static Boolean isProfileValid(Profile profile){
        return profileContentMap.get(profile.name) != null;
    }
    public class ApprovalPageContent {

        public String approveButtonName {get;set;}
        public String rejectButtonName  {get;set;}
        public String targetStatus      {get;set;}
        public Boolean finalApprover    {get;set;}
       
        public ApprovalPageContent setApproveLabel(String approveButtonName){
            this.approveButtonName = approveButtonName;
            return this;
        }

        public ApprovalPageContent setRejectLabel(String rejectButtonName){
            this.rejectButtonName = rejectButtonName;
            return this;
        }

        public ApprovalPageContent setStatus(String targetStatus){
            this.targetStatus = targetStatus;
            return this;
        }

        public ApprovalPageContent isFinalApprover(Boolean isFinalApprover){
            this.finalApprover = isFinalApprover;
            return this;
        }

    }

    public class BaseData {

        public List<String>     orderTypes    {get;set;}
        public List<String>     orderMotivs      {get;set;}
        
        public BaseData(List<String> orderTypes, List<String> orderMotivs){

            this.orderTypes = orderTypes;
            this.orderMotivs = orderMotivs;

        }

    }
    public class OpportunityData {
        public Id       id                  {get;set;}
        public String   id15                {get;set;}
        public Boolean  checked             {get;set;}
        public String oppNumber             {get;set;}
        public String accountName           {get;set;}
        public String rtvName               {get;set;}
        public String orderType             {get;set;}
        public String orderReason           {get;set;}
        public String campaignType          {get;set;}
        public String condiPagto            {get;set;}
        public Date dateInterest            {get;set;}
        public Decimal totalPrice           {get;set;}
        public String evaluationRequired    {get;set;}
        public Boolean hasError             {get;set;}
        public String message               {get;set;}
        public String currencyCoin          {get;set;}
        public String oppObsInter           {get;set;}

        public OpportunityData(Opportunity record){
            if(String.valueOf(record.Id).length() > 15){
                this.id15                 = String.valueOf(record.Id).substring(0, 15);
                this.id                   = record.Id;
            }else{
                this.id15                 = String.valueOf(record.Id);
            }
            this.oppObsInter          = record.ObservacaoInterna__c;
            this.oppNumber            = record.NumeroOportunidade__c;
            this.accountName          = record.Account.name;
            this.rtvName              = record.NomeRTV__c;
            this.orderReason          = record.MotivoOrdem__c;
            this.orderType            = record.TipoOrdem__c;
            this.campaignType         = record.Campanha__r.Descricao__c;
            this.currencyCoin         = record.MOeda__c;
            this.checked              = false;
            this.condiPagto           = record.CondicaoPagamento__r.Descricao__c;
            this.dateInterest         = record.DataInicioJuros__c;
            this.totalPrice           = (record.Moeda__c == 'USD' ? record.ValorTotalMercadoriasDolar__c : record.ValorTotalMercadoriasReal__c);
            this.evaluationRequired   = record.AvaliacaoNecessaria__c;
        }

        public OpportunityData(String message){
            this.hasError   = true;
            this.checked    = false;
            this.message    = message;
        }
    }

    public class OppModalData {

        public Id               id                        {get;set;}
        public String           id15                      {get;set;}
        public String           oppNumber                 {get;set;}
        public String           accountName               {get;set;}
        public String           rtvName                   {get;set;}
        public String           orderReason               {get;set;}
        public String           orderType                 {get;set;}
        public String           campaignType              {get;set;}
        public String           message                   {get;set;}
        public OppItemData[]    orderItemsToHandle        {get;set;}
        public OppItemData[]    orderItemsAlreadyHandled  {get;set;}
        public Boolean          hasError                  {get;set;}

        public OppModalData(Opportunity record, OppItemData[] orderItemsToHandle, OppItemData[] orderItemsAlreadyHandled){
            if(String.valueOf(record.Id).length() > 15){
                this.id15                 = String.valueOf(record.Id).substring(0, 15);
                this.id                   = record.Id; 
            }else{
                this.id15                 = String.valueOf(record.Id);
            }
            this.oppNumber                  = record.NumeroOportunidade__c;
            this.accountName                = record.Account.name;
            this.rtvName                    = record.NomeRTV__c;
            this.orderReason                = record.MotivoOrdem__c;
            this.OrderType                  = record.TipoOrdem__c;
            this.campaignType               = record.Campanha__r.Descricao__c;
            this.orderItemsToHandle         = orderItemsToHandle;
            this.orderItemsAlreadyHandled   = orderItemsAlreadyHandled;
        }

        public OppModalData(String error){
            hasError = true;
            message  = error;
        }

    }

    public class OppItemData {

        public Id       id                          {get;set;}
        public Id       oppid                       {get;set;}
        public Id       productId                   {get;set;}
        public String   productName                 {get;set;}
        public Decimal  productQtd                  {get;set;}
        public Decimal  salesPrice                  {get;set;}
        public Decimal  discountGranted             {get;set;}
        public Decimal  discountExcess              {get;set;}
        public String  currencyCoin              {get;set;}

        public OppItemData(OpportunityLineItem record, Decimal porcentagemDesconto){
            this.id                 = record.id;
            this.oppid              = record.OpportunityId;
            this.productId          = record.product2Id;
            this.productName        = record.product2.name;
            this.productQtd         = record.Quantity;
            this.salesPrice         = record.PrecoVendasJurosBRLUSD__C;
            this.discountGranted    = (record.Discount != 0 ? record.Discount*-1 : record.Acrescimo__c);
            this.currencyCoin       = record.Opportunity.Moeda__C;
            this.discountExcess     = record.DescontoExcedente__c;//record.Discount - porcentagemDesconto  > 0 ? record.Discount - porcentagemDesconto : 0;
            
        }
    }

    
    public class ResultData{
        public String id;
        public String name;
        public List<String> returningFields;

        public ResultData(SObject row, String tableName){

            String name   = (String) row.get('name');

            this.id       = row.id;
            this.name     = name;

            this.returningFields = new List<String>{
                Schema.getGlobalDescribe().get(tableName).getDescribe().getLabel(), name
            };
        }
    }
    
    public class ApprovalResult {
        public String statusAction;
        public Id recordId;
        public List<Id> recordsId;
        public String message;
        public boolean hasError;

        private ApprovalResult(ApprovalPageContent pageContent, Id targetRecordId, Boolean approving){
            this.statusAction   = pageContent.finalApprover? (approving? 'aprovados' : 'rejeitados') : 'enviados para aprovação';
            this.recordId       = targetRecordId;
            this.message        = null;
            this.hasError       = false;
        }

        private ApprovalResult(ApprovalPageContent pageContent, List<Id> targetRecordsId, Boolean approving){
            this.statusAction   = pageContent.finalApprover? (approving? 'aprovados' : 'rejeitados') : 'enviados para aprovação';
            this.recordsId      = targetRecordsId;
            this.message        = null;
            this.hasError       = false;
        }

        private ApprovalResult(String errorMessage){
            this.message    = errorMessage;
            this.hasError   = true;
        }
    }
    private class OpportunityBulkApprovalException extends Exception {}
}