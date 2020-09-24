public class OpportunityAppController {

    // Teste pipeline
    
    public String opportunityId   {get; set;}
    public String opportunityName {get; set;}
    public Boolean hasMasterAccess {get; set;}
    
    public Boolean isCustomerService {get;set;}
    public Boolean isPDFGenerator {get;set;}
    public Boolean isRTV {get;set;}
    
    public static final String DEFAULT_CURRENCY_CODE = 'BRL';
    public static String CUSTOMER_SERVICE_PROFILE_TERM;
    public static String GERENTE_REGIONAL_PROFILE_TERM;
    public static String DIRETOR_COMERCIAL_PROFILE_TERM;
    public static String ADMINISTRATOR_PROFILE_TERM;
    public static String RTV_PROFILE_TERM;
    public static Profile userProfile;

    private static List<Holiday> holidays;
    private static Set<String>   holidaysShortDateSet;

    @TestVisible
    private static final Id STANDARD_PRICEBOOK_ID;

    static{
        holidaysShortDateSet = new Set<String>();
        userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ]; 
		
        STANDARD_PRICEBOOK_ID = 
            Test.isRunningTest()?
            Test.getStandardPricebookId():
            [
                SELECT id 
                FROM Pricebook2 
                WHERE isStandard = true 
                LIMIT 1
            ].id;

        CUSTOMER_SERVICE_PROFILE_TERM  = Label.CustomerServiceProfileTerm;
        RTV_PROFILE_TERM               = Label.RTVProfileTerm;
        GERENTE_REGIONAL_PROFILE_TERM  = Label.RegionalManagerProfileTerm;
        DIRETOR_COMERCIAL_PROFILE_TERM = Label.ComercialDirectorProfileTerm;
        ADMINISTRATOR_PROFILE_TERM     = [SELECT Id, name FROM Profile WHERE PermissionsModifyAllData = true AND PermissionsPrivacyDataAccess = true ORDER BY CreatedDate LIMIT 1].name;
    }

    public OpportunityAppController(PricingSimulationAppController a) {
        this();
    }

    public OpportunityAppController() {

    }
    
    public static Boolean isPDFGenerator(){
        Map<String, PDFOpportunityProfiles__c> pdfMap = PDFOpportunityProfiles__c.getAll();
        return pdfMap.containsKey(userProfile.name);
    }
    public static Boolean isCustomerService(){
        return (
            userProfile.name.containsIgnoreCase(CUSTOMER_SERVICE_PROFILE_TERM)  || 
            userProfile.name.containsIgnoreCase(GERENTE_REGIONAL_PROFILE_TERM)  || 
            userProfile.name.containsIgnoreCase(DIRETOR_COMERCIAL_PROFILE_TERM) ||
            userProfile.name.containsIgnoreCase(ADMINISTRATOR_PROFILE_TERM)     
        );
    }

    public static Boolean isRTV(){
        return userProfile.name.containsIgnoreCase(RTV_PROFILE_TERM);
    }

    public OpportunityAppController(ApexPages.StandardController standardController) {
        this.opportunityId = ApexPages.currentPage().getParameters().get('Id');
        this.hasMasterAccess = true;
        if(this.opportunityId != null){
            this.opportunityName = [SELECT numeroOportunidade__c FROM Opportunity WHERE id = :opportunityId].numeroOportunidade__c;
        }

        this.isCustomerService = isCustomerService();
        this.isPDFGenerator    = isPDFGenerator();
        this.isRTV             = isRTV();
    }

    @RemoteAction
    public static ApprovalProcessSimulationAppReturnedData simulateApprovalProcess(String opportunityId){

        // System.debug('opportunityId => ' + opportunityId);

        Savepoint savepoint = Database.setSavepoint();

        ApprovalProcessSimulationAppReturnedData returnData;

        try {

            Opportunity opportunity = [
                SELECT id, tipoOrdem__c, numeroOportunidade__c, recebedorMercadoria__c, 
                    (   SELECT id, confirmado__c, totalPrice, dataFaturamento__c, Opportunity.Account.BloqueadoCredito__c
                        FROM OpportunityLineItems
                    ), 
                    account.saldoLimiteCredito__c
                FROM Opportunity 
                WHERE id = :opportunityId
            ];

            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(opportunity.id);    
            submitRequest.setSkipEntryCriteria(true);

            if(opportunity.tipoOrdem__c == 'Bonificação'){
                submitRequest.setProcessDefinitionNameOrId('VendaBonficacaoValorDesconto');
            } else {
                submitRequest.setProcessDefinitionNameOrId('VendaNormalDescontov3');
            }

            // System.debug('submitRequest => ' + submitRequest);

            Boolean hasNextStep = true;
            Integer step = 1;
            Map<Integer, Id> stepIndexToWorkItemId = new Map<Integer, Id>();
            
            OpportunityHelper.disableTrigger();
            Approval.ProcessResult processResult = Approval.process(submitRequest);
            OpportunityHelper.enableTrigger();

            Id processInstanceId = processResult.getInstanceId();

            while(hasNextStep) {

                // System.debug('processResult => ' + processResult);
                // System.debug('JSON.serialize(processResult) => ' + JSON.serialize(processResult));

                List<Id> newWorkItemIds = processResult.getNewWorkitemIds();

                // System.debug('newWorkItemIds => ' + newWorkItemIds);

                if(!newWorkItemIds.isEmpty()){
                    
                    Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();
                    workItemRequest.setComments('' + step);
                    workItemRequest.setAction('Approve');

                    workItemRequest.setWorkitemId(newWorkItemIds.get(0));
                    workItemRequest.setNextApproverIds(null);

                    List<Id> users = workItemRequest.getNextApproverIds();

                    // System.debug('users => ' + users);

                    stepIndexToWorkItemId.put(step, newWorkItemIds.get(0));
                    
                    step++;

                    processResult = Approval.Process(workItemRequest);

                    List<Id> users2 = workItemRequest.getNextApproverIds();

                    // System.debug('users2 => ' + users2);
                
                } else {

                    hasNextStep = false;

                }

            }

            // System.debug('stepIndexToWorkItemId => ' + stepIndexToWorkItemId);

            Map<Id, ProcessInstanceStep> idToProcessInstanceStep = new Map<Id, ProcessInstanceStep>([
                SELECT id, actorId, originalActorId, comments
                FROM ProcessInstanceStep
                WHERE processInstanceId = :processInstanceId
                AND comments != null
            ]);
            
            // System.debug('idToProcessInstanceStep => ' + idToProcessInstanceStep);
            
            Map<Integer, Id> stepToProcessInstanceStepActorId = new Map<Integer, Id>();

            for(ProcessInstanceStep processStep : idToProcessInstanceStep.values()){
                // System.debug('processStep.comments => ' + processStep.comments);
                // System.debug('processStep.actorId => ' + processStep.actorId);
                // System.debug('processStep.originalActorId => ' + processStep.originalActorId);
                stepToProcessInstanceStepActorId.put(Integer.valueOf(processStep.comments), processStep.originalActorId);
            }
            
            Map<Integer, Id> stepIndexToApproverId = new Map<Integer, Id>();

            for(Integer index : stepIndexToWorkItemId.keySet()){
                // System.debug('stepIndexToWorkItemId.get(index) => ' + stepIndexToWorkItemId.get(index));
                // System.debug('idToProcessInstanceStep.get(stepIndexToWorkItemId.get(index)) => ' + idToProcessInstanceStep.get(stepIndexToWorkItemId.get(index)));
                stepIndexToApproverId.put(index, stepToProcessInstanceStepActorId.get(index));
            }

            Map<Id, User> approvers = new Map<Id, User>([
                SELECT id, name
                FROM User
                WHERE id IN :stepIndexToApproverId.values()
            ]);

            Map<Integer, ApprovalProcessSimulationAppData> stepIndexToApproverData = new Map<Integer, ApprovalProcessSimulationAppData>();

            Map<String, ProcessoAprovacao__c> approvalProcess = ProcessoAprovacao__c.getall();
            // System.debug(stepIndexToApproverId);
            // System.debug(approvalProcess);
            for(Integer i = 1; i <= stepIndexToApproverId.size(); i++){
                ApprovalProcessSimulationAppData approvalProcessSimulationData = new ApprovalProcessSimulationAppData(approvers.get(stepIndexToApproverId.get(i)));
                List<String> helpTexts = new List<String>();
                // System.debug(String.valueOf(i));
                if(approvalProcess.containsKey(String.valueOf(i))){
                    // System.debug('Amigo estou aqui');
                    helpTexts.add(approvalProcess.get(String.valueOf(i)).textoDesconto__c);
                 
                    if(opportunity.tipoOrdem__c == 'Bonificação'){
                        helpTexts.add(approvalProcess.get(String.valueOf(i)).textoValorTotal__c);
                    }
                }
                // System.debug(helpTexts);
                approvalProcessSimulationData.setHelpTexts(helpTexts);
                stepIndexToApproverData.put(i, approvalProcessSimulationData);
            }

            returnData = new ApprovalProcessSimulationAppReturnedData(stepIndexToApproverData);

            Database.rollback(savepoint);

        } catch (Exception e){
            
            Database.rollback(savepoint);

            returnData = new ApprovalProcessSimulationAppReturnedData(e);

        }

        return returnData;

    }

    @RemoteAction
    public static OpportunityAppApprovalReturn approveOpportunity(String opportunityId){

        // System.debug('opportunityId => ' + opportunityId);

        OpportunityAppApprovalReturn returnData;

        try {

            Opportunity opportunity = [
                SELECT id, tipoOrdem__c, numeroOportunidade__c, recebedorMercadoria__c, 
                    (   SELECT id, confirmado__c, totalPrice, dataFaturamento__c, Opportunity.Account.BloqueadoCredito__c
                        FROM OpportunityLineItems
                    ), 
                    account.saldoLimiteCredito__c
                FROM Opportunity 
                WHERE id = :opportunityId
            ];

            // a opp pode não ter um recebedor, porém os itens devem ter caso seja 'Conta e Ordem'
            // trava definida na tela
            // if(opportunity.tipoOrdem__c == 'Conta e Ordem' && String.isBlank(opportunity.recebedorMercadoria__c)){
            //     throw new OpportunityAppControllerException('Essa oportunidade não possui o recebedor da mercadoria preenchido.');
            // }

            // Decimal totalOppLineItemsAmount = 0;
            // Boolean hasConfirmedItems = false;
            // Boolean invalidDeliveryDate = false;
            // Date today = Date.today();

            // for(OpportunityLineItem oppLineItem : opportunity.opportunityLineItems){
            //     if(oppLineItem.confirmado__c){
            //         hasConfirmedItems = true;
            //         totalOppLineItemsAmount += oppLineItem.totalPrice;
            //         if(oppLineItem.dataFaturamento__c < today){
            //             invalidDeliveryDate = true;
            //         }
            //     }
            // }

            // não ter itens confirmados não é uma trava para rodar o fluxo
            // if(!hasConfirmedItems){
            //     throw new OpportunityAppControllerException('Essa oportunidade não possui itens confirmados.');

            // não ter crédito suficiente não é uma trava para rodar o fluxo
            // } else if(totalOppLineItemsAmount > opportunity.account.saldoLimiteCredito__c) {
            //     throw new OpportunityAppControllerException('O cliente não possui crédito suficiente para suprir os itens confirmados.');
            
            // não ter data de entrega válida não é uma trava para rodar o fluxo
            // } else if(invalidDeliveryDate){
            //     throw new OpportunityAppControllerException('A data de entrega não é mais válida.');
            // }

            // estudar a possibilidade de adicionar as informações a cima em forma de observação na tela


            opportunity.DontChangeStageName__c = true;
            
            OpportunityHelper.disableTrigger();
            update opportunity; 
            OpportunityHelper.enableTrigger();

            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setComments('submit by approveOpportunity');
            submitRequest.setObjectId(opportunity.id);    
            submitRequest.setSkipEntryCriteria(false);

            if(opportunity.tipoOrdem__c == 'Bonificação'){
                submitRequest.setProcessDefinitionNameOrId('VendaBonficacaoValorDesconto');
            } else {
                submitRequest.setProcessDefinitionNameOrId('VendaNormalDescontov3');
            }

            // System.debug('submitRequest => ' + submitRequest);

            Approval.ProcessResult processResult = Approval.process(submitRequest);

            OpportunityAppController.OpportunityAppApprovalData opportunityApprovalData = new OpportunityAppController.OpportunityAppApprovalData(opportunity);

            returnData = new OpportunityAppApprovalReturn(opportunityApprovalData);

            opportunity.DontChangeStageName__c = false;
            OpportunityHelper.disableTrigger();
            update opportunity; 
            OpportunityHelper.enableTrigger();
             
        } catch (Exception e){       


            
                   
            String errorMsg = e.getMessage();
            if(errorMsg.contains('NO_APPLICABLE_PROCESS')){
                Opportunity opportunity = [
                    SELECT id, tipoOrdem__c, Territorio__c, numeroOportunidade__c, recebedorMercadoria__c, EMailAprovacaoPedidoCliente__c,
                        (   SELECT id, confirmado__c, totalPrice, dataFaturamento__c, Opportunity.Account.BloqueadoCredito__c
                            FROM OpportunityLineItems
                        ), 
                        account.saldoLimiteCredito__c
                    FROM Opportunity 
                    WHERE id = :opportunityId
                ];

                opportunity.stageName = 'Em Aprovação Cliente';
                opportunity.DontChangeStageName__c = true;

                update opportunity; 

                OpportunityAppController.OpportunityAppApprovalData opportunityApprovalData = new OpportunityAppController.OpportunityAppApprovalData(opportunity);



                returnData = new OpportunityAppApprovalReturn(opportunityApprovalData);

                
            }else{
                returnData = new OpportunityAppApprovalReturn(e);
            }
        }
        return returnData;
    }

    @RemoteAction
    public static ExistentOpportunityDataResult cloneOpportunity(String opportunityId){

        ExistentOpportunityDataResult result;

        try {

            Opportunity opportunity = [
                SELECT  id, jurosComercialFinanceiro__c, valorTotalMercadoriasReal__c, valorTotalMercadoriasDolar__c, 
                        valorTotalMercadoriasDolarSemIPI__c, condicaoExpedicao__c, tipoOrdem__c, classificacaoVenda__c, 
                        motivoOrdem__c, numeroPedidoCliente__c, recebedorMercadoria__c, clienteOrigemRemanejamento__c, 
                        accountId, account.name, name, campanha__c, moeda__c, condicaoPagamento__c, vencimentoVendor__c, 
                        observacaoInterna__c, observacaoLogistica__c, observacaoPDF__c, observacaoImpressaNF__c, 
                        cultura__c, agenciamento__c, stageName, idTabelaFrete__c, localNegocio__c, 
                        account.billingState, regional__c, territorio__c, account.parentId, organizacaoVenda__c,
                        closeDate, dataReferenciaPreco__c, dataValidade__c, descontoFixoCliente__c, diretorComercial__c,
                        emailAprovacaoPedidoCliente__c, gerenteRegional__c, setorAtividade__c, valorTotalIPI__c,
                        valorTotalIPIDolar__c, valorTotalMercadoriasRealSemIPI__c, account.shippingState, account.shippingCountry, account.tipoCliente__c,
                        dataInicioJuros__c, dataVencimento__c, NomeRTV__c, account.CanalDistribuicao__c, PercentualFrete__c,
                        recebedorMercadoria__r.shippingState, AnalistaCustomerService__c 
                FROM Opportunity
                WHERE id = :opportunityId
            ];

            List<CondicaoPagamento__c> validPaymentCondition = [
                SELECT  id, jurosComercialFinanceiro__c, dias__c, 
                        (   SELECT condicaoPagamento__c 
                            FROM Vig_ncias_Condi_o_Pagamento__r
                            WHERE dataVigenciaDe__c  <= TODAY 
                            AND   dataVigenciaAte__c >= TODAY
                            AND   dataVigenciaDe__c  <= :opportunity.dataReferenciaPreco__c 
                            AND   dataVigenciaAte__c >= :opportunity.dataReferenciaPreco__c
                            ORDER BY createdDate DESC 
                        )
                FROM CondicaoPagamento__c
                WHERE id = :opportunity.condicaoPagamento__c
                AND id IN (
                    SELECT condicaoPagamento__c 
                    FROM VigenciaCondicao__c
                    WHERE dataVigenciaDe__c  <= TODAY 
                    AND   dataVigenciaAte__c >= TODAY
                    AND   dataVigenciaDe__c  <= :opportunity.dataReferenciaPreco__c 
                    AND   dataVigenciaAte__c >= :opportunity.dataReferenciaPreco__c
                )
            ];

            if(validPaymentCondition.isEmpty()){
                return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A condição de pagamento desta oportunidade não é mais válida.'));
            } else if(validPaymentCondition[0].Vig_ncias_Condi_o_Pagamento__r.isEmpty()){
                return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A condição de pagamento desta oportunidade não é mais válida.'));
            }

            Date campaignInterestStartDate;

            if(opportunity.campanha__c != null){

                Boolean isCampaignValid = false;
                
                try {
                    CampanhaCliente__c customerCampaign = [
                        SELECT campanha__c, campanha__r.dataInicioJuros__c
                        FROM CampanhaCliente__c
                        WHERE conta__c  = :opportunity.accountId
                        AND campanha__c = :opportunity.campanha__c
                        AND campanha__r.moeda__c = :opportunity.moeda__c
                        AND campanha__r.dataVigenciaInicial__c <= TODAY 
                        AND campanha__r.dataVigenciaFinal__c >= TODAY
                        AND campanha__r.liberadoUsoOportunidades__c = true
                    ];

                    campaignInterestStartDate = customerCampaign.campanha__r.dataInicioJuros__c;

                    isCampaignValid = true;

                } catch(QueryException e){

                    try {
                    
                        Campanha__c opportunityCampaign = [
                            SELECT id, dataInicioJuros__c, (
                                SELECT id
                                FROM ClientesCampanha__r
                            )
                            FROM Campanha__c 
                            WHERE id = :opportunity.campanha__c
                            AND moeda__c = :opportunity.moeda__c
                            AND dataVigenciaInicial__c <= TODAY 
                            AND dataVigenciaFinal__c >= TODAY
                            AND liberadoUsoOportunidades__c = true
                        ];  

                        campaignInterestStartDate = opportunityCampaign.dataInicioJuros__c;
                        
                        isCampaignValid = opportunityCampaign.clientesCampanha__r.isEmpty();
                    
                    } catch(QueryException qe){

                    } 
                }

                if(!isCampaignValid){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A campanha desta oportunidade não é mais válida.'));
                }
            }

            ShippingPolicyService shippingPolicyService = new ShippingPolicyService(opportunity);
            //export freight logic
            if(opportunity.account.ShippingCountry != 'BR'){
                shippingPolicyService.shippingPolicyOpportunityData.exportFreight = true;
            }

            ShippingPolicyServiceReturnedData shippingPolicyServiceReturn = shippingPolicyService.getShippingTable();

            if(shippingPolicyServiceReturn.hasErrors){
                return new ExistentOpportunityDataResult(new OpportunityAppControllerException(shippingPolicyServiceReturn.message));
            } else if(opportunity.idTabelaFrete__c != shippingPolicyServiceReturn.data.id){
                return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A tabela de frete atrelada à esta oportunidade não é mais válida.'));
            }

            List<OpportunityLineItem> opportunityLineItems = [
                SELECT  id, product2Id, product2.name, idPoliticaDesconto__c, idTabelaPreco__c,
                        descontoMaximo__c, descontoMinimo__c, descontoRecomendado__c, precoLista__c,
                        dataEntrega__c, confirmado__c, dataConfirmacao__c, opportunityId,
                        quantity, unitPrice, discount, precoLitro__c, cultura__c, litros__c, 
                        numeroPedidoCliente__c, recebedorMercadoria__c, juros__c, precoListaReferencia__c, 
                        valorDescontoTipoCliente__c, valorFrete__c, valorDescontoItem__c, valorJurosItem__c, 
                        precoVendaSemJuros__c, precoVendasJuros__c, itinerario__c, prazoInterno__c, 
                        dataFaturamento__c, totalItemComJuros__c, totalItemSemjurosUSD__c, acrescimo__c,
                        totalItemComJurosUSD__c, descontoTipoCliente__c, percFrete__c, dataVigenciaInicialDesconto__c, 
                        dataVigenciaFinalDesconto__c, descontoExcedente__c, itemParaAprovao__c, idTabelaFrete__c, 
                        ipi__c, precoListaComDesconto__c, taxaDolar__c, valorTotalIPIDolar__c, idDescontoTipoCliente__c,
                        precoListaReferenciaUSD__c, precoLitroUSD__c, precoVendaSemJurosUSD__c, precoVendasJurosUSD__c,
                        valorDescontoItemUSD__c, valorDescontoTipoClienteUSD__c, valorFreteUSD__c, valorJurosItemUSD__c, Opportunity.Account.BloqueadoCredito__c
                FROM OpportunityLineItem
                WHERE opportunityId = :opportunity.id
            ];

            DiscountByCustomerTypeService discountByCustomerTypeService = new DiscountByCustomerTypeService(opportunity.account.tipoCliente__c, Date.today());
            DiscountByCustomerTypeReturnedData discountByCustomerTypeReturn = discountByCustomerTypeService.getDiscountByCustomerType();

            if(discountByCustomerTypeReturn.hasErrors){
                if(discountByCustomerTypeReturn.message == 'Não existe desconto por tipo de cliente cadastrado para esse cliente.'){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A condição de desconto por tipo de cliente não é válida.'));
                } else {
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException(discountByCustomerTypeReturn.message));
                }
            } else if(opportunityLineItems[0].idDescontoTipoCliente__c != discountByCustomerTypeReturn.data.id) {
                return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A condição de desconto por tipo de cliente não é válida.'));
            }

            List<Id> productsIds = Collection.of(opportunityLineItems).pluckIds(OpportunityLineItem.product2Id);

            Set<String> productsIdsString = new Set<String>((List<String>) productsIds);

            DiscountPolicyService discountPolicyService = new DiscountPolicyService(new DiscountPolicyOpportunityData(opportunity));
            DiscountPolicyServiceReturnedData discountPolicyReturn = discountPolicyService.getDiscountPolicy(productsIdsString);

            Map<Id, Account> idToAccount = new Map<Id, Account>([
                SELECT  id, listaPreco__c, regionalVendas__c, tipoCliente__c, parentId, shippingState,
                        localNegocio__c, zonaTransporte__c, localNegocio__r.zonaTransporte__c,
                        Atributo7__c, Atributo8__c, Atributo9__c, Atributo10__c, SulFur__c, NaturOleo__c, NaturalOleo__c, Rizotec__c, Stimulate__c, Trianum__c
                FROM Account    
                WHERE id = :opportunity.accountId
                OR id = :opportunity.recebedorMercadoria__c
            ]);

            PricingService pricingService = new PricingService(idToAccount.get(opportunity.accountId), System.today());
            pricingService.setCurrency(opportunity.moeda__c);
            pricingService.setRegional(opportunity.regional__c);
            List<Id> accountValidProducts = filterValidProducts(idToAccount.get(opportunity.accountId), productsIds);
            Map<String, ProductPriceEntry> productIdToPriceEntry = pricingService.getPrices(accountValidProducts);

            for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
                
                if(!discountPolicyReturn.data.containsKey(opportunityLineItem.product2Id)){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A política de desconto do item com o produto ' + opportunityLineItem.product2.name + ' não existe mais ou não é mais válida.'));
                } else if(discountPolicyReturn.data.get(opportunityLineItem.product2Id).discountPolicyId != opportunityLineItem.idPoliticaDesconto__c){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A política de desconto do item com o produto ' + opportunityLineItem.product2.name + ' não é a mais apropriada.'));
                } else if(discountPolicyReturn.data.get(opportunityLineItem.product2Id).maxDiscount != opportunityLineItem.descontoMaximo__c){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A política de desconto do item com o produto ' + opportunityLineItem.product2.name + ' teve seu valor de desconto máximo alterada de ' + opportunityLineItem.descontoMaximo__c + ' para ' + discountPolicyReturn.data.get(opportunityLineItem.product2Id).maxDiscount + '.'));
                } else if(discountPolicyReturn.data.get(opportunityLineItem.product2Id).minimumDiscount != opportunityLineItem.descontoMinimo__c){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A política de desconto do item com o produto ' + opportunityLineItem.product2.name + ' teve seu valor de desconto máximo alterada de ' + opportunityLineItem.descontoMinimo__c + ' para ' + discountPolicyReturn.data.get(opportunityLineItem.product2Id).minimumDiscount + '.'));
                } else if(discountPolicyReturn.data.get(opportunityLineItem.product2Id).recommendedDiscount != opportunityLineItem.descontoRecomendado__c){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A política de desconto do item com o produto ' + opportunityLineItem.product2.name + ' teve seu valor de desconto máximo alterada de ' + opportunityLineItem.descontoRecomendado__c + ' para ' + discountPolicyReturn.data.get(opportunityLineItem.product2Id).recommendedDiscount + '.'));
                }

                if(!productIdToPriceEntry.containsKey(opportunityLineItem.product2Id)){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A tabela de preço do item com o produto ' + opportunityLineItem.product2.name + ' não é mais válida.'));
                } else if(productIdToPriceEntry.get(opportunityLineItem.product2Id).price != opportunityLineItem.precoLista__c){
                    return new ExistentOpportunityDataResult(new OpportunityAppControllerException('A tabela de preço do item com o produto ' + opportunityLineItem.product2.name + ' teve o valor do produto alterado de ' + opportunityLineItem.precoLista__c + ' para ' + productIdToPriceEntry.get(opportunityLineItem.product2Id).price + ' e não é mais válida.'));
                }
            }

            Account targetAccount = opportunity.recebedorMercadoria__c != null? idToAccount.get(opportunity.recebedorMercadoria__c) : idToAccount.get(opportunity.accountId);
            DeliveryAppData deliveryData = getDeliveryData(targetAccount, opportunity.condicaoExpedicao__c, targetAccount.localNegocio__r);

            // Pricebook2 targetPricebook = [SELECT id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

            Integer opportunityCloseDate = getOpportunityCloseDateLimit();

            Opportunity opportunityClone = opportunity.clone(false, false, false, false);
            opportunityClone.stageName              = 'Iniciado';
            opportunityClone.closeDate              = Date.today().addDays(opportunityCloseDate);
            opportunityClone.dataValidade__c        = Date.today().addDays(opportunityCloseDate);
            opportunityClone.dataReferenciaPreco__c = Date.today();
            opportunityClone.numeroPedidoCliente__c = null;
            opportunityClone.pricebook2Id           = STANDARD_PRICEBOOK_ID;
            if(opportunity.campanha__c != null){
                opportunityClone.dataInicioJuros__c     = campaignInterestStartDate < opportunityClone.dataReferenciaPreco__c? opportunityClone.dataReferenciaPreco__c : campaignInterestStartDate;
                Integer paymentConditionDays = Integer.valueOf(validPaymentCondition[0].dias__c);
                opportunityClone.dataVencimento__c = opportunityClone.dataInicioJuros__c.addDays(paymentConditionDays);
            }

            insert opportunityClone;

            Map<String, OpportunityLineItem> productIdToOpportunityLineItemsToInsert = new Map<String, OpportunityLineItem>();

            Decimal interestValue = validPaymentCondition[0].jurosComercialFinanceiro__c / 100;

            for(OpportunityLineItem item : opportunityLineItems){

                item.ItinerarioId__c         = deliveryData.itineraryId;
                    
                if(productIdToOpportunityLineItemsToInsert.containsKey(item.product2Id)){
                    
                    productIdToOpportunityLineItemsToInsert.get(item.product2Id).quantity                += item.quantity;
                    productIdToOpportunityLineItemsToInsert.get(item.product2Id).litros__c               += item.litros__c;
                    productIdToOpportunityLineItemsToInsert.get(item.product2Id).totalItemComJuros__c    += item.totalItemComJuros__c;
                    productIdToOpportunityLineItemsToInsert.get(item.product2Id).totalItemComJurosUSD__c += item.totalItemComJurosUSD__c;
                    productIdToOpportunityLineItemsToInsert.get(item.product2Id).totalItemSemjurosUSD__c += item.totalItemSemjurosUSD__c;
                    // productIdToOpportunityLineItemsToInsert.get(item.product2Id).totalItemSemjuros__c += item.totalItemSemjuros__c;

                } else {
            
                    OpportunityLineItem itemClone = item.clone(false, false, false, false);
                    itemClone.dataEntrega__c            = deliveryData.minimumDate;
                    itemClone.dataFaturamento__c        = getBillingDate(itemClone.dataEntrega__c, Integer.valueOf(itemClone.itinerario__c));
                    itemClone.confirmado__c             = false;
                    itemClone.dataConfirmacao__c        = null;
                    itemClone.usuarioConfirmacao__c     = null;
                    itemClone.opportunityId             = opportunityClone.id;
                    itemClone.numeroPedidoCliente__c    = null;
                    itemClone.ItinerarioId__c           = deliveryData.itineraryId;
                    // itemClone.valorJurosItem__c         = item.precoListaReferencia__c * interestValue;
                    // itemClone.juros__c                  = interestValue;
                    // itemClone.precoVendasJuros__c       = item.precoListaReferencia__c + itemClone.valorJurosItem__c;

                    productIdToOpportunityLineItemsToInsert.put(item.product2Id, itemClone);

                }
            
            }

            if(!productIdToOpportunityLineItemsToInsert.values().isEmpty()){
                insert productIdToOpportunityLineItemsToInsert.values();
            }

            result = getExistentOpportunityData(opportunityClone.id);

        } catch (Exception e){

            result = new ExistentOpportunityDataResult(e);

        }

        return result;

    }

    @RemoteAction
    public static ExistentOpportunityDataResult getExistentOpportunityData(String opportunityId){

        ExistentOpportunityDataResult result;

        try{
        
            Opportunity opportunity = [
                SELECT  id, jurosComercialFinanceiro__c, valorTotalMercadoriasReal__c, valorTotalMercadoriasDolar__c, 
                        valorTotalMercadoriasDolarSemIPI__c, condicaoExpedicao__c, tipoOrdem__c, classificacaoVenda__c, 
                        motivoOrdem__c, numeroPedidoCliente__c, recebedorMercadoria__c, clienteOrigemRemanejamento__c, 
                        accountId, account.name, name, campanha__c, moeda__c, condicaoPagamento__c, vencimentoVendor__c, 
                        observacaoInterna__c, observacaoLogistica__c, observacaoPDF__c, observacaoImpressaNF__c, 
                        cultura__c, agenciamento__c, stageName, dataReferenciaPreco__c, numeroOportunidade__c, territorio__c,
                        idTabelaFrete__c, dataInicioJuros__c, localNegocio__c
                FROM Opportunity
                WHERE id = :opportunityId
            ];

            List<OpportunityLineItem> opportunityLineItems = [
                SELECT  id, opportunityId, pricebookEntryId, cultura__c, dataEntrega__c, numeroPedidoCliente__c, precoLitro__c, 
                        quantity, unitPrice, discount, descontoMaximo__c, descontoMinimo__c, descontoRecomendado__c, precoVendaSemJuros__c, precoVendasJuros__c,
                        precoListaReferencia__c, litros__c, juros__c, confirmado__c, descontoTipoCliente__c, valorFrete__c, totalPrice, totalItemComJuros__c, 
                        totalItemSemjurosUSD__c, totalItemComJurosUSD__c,  precoVendaSemJurosUSD__c, precoVendasJurosUSD__c, precoListaReferenciaUSD__c,
                        prazoInterno__c, itinerario__c, product2Id, product2.name, recebedorMercadoria__c, product2.sku__c, product2.multiplicidade__c,
                        dataConfirmacao__c, precoLista__c, dataVigenciaInicialDesconto__c, dataVigenciaFinalDesconto__c, ipi__c, valorIPI__c, 
                        idPoliticaDesconto__c, idTabelaFrete__c, idTabelaPreco__c, IDDescontoTipoCliente__c, Opportunity.Account.BloqueadoCredito__c, Acrescimo__c
                FROM OpportunityLineItem
                WHERE opportunityId = :opportunityId
            ];

            // System.debug('opportunity => ' + opportunity);

            List<Id> accountIds = Collection.of(opportunityLineItems).pluckIds(OpportunityLineItem.recebedorMercadoria__c);
            accountIds.add(opportunity.accountId);
            accountIds.add(opportunity.recebedorMercadoria__c);
            accountIds.add(opportunity.clienteOrigemRemanejamento__c);

            Map<Id, Account> idToAccount = new Map<Id, Account>([
                SELECT  id, name, tipoCliente__c, revendaAgenciadora__c, ratingPagamento__c, BloqueadoCredito__c, 
                        shippingState, shippingCity, nomeFazenda__c, contribuinteICMS__c, localNegocio__c,
                        zonaTransporte__c, MatrizCredito__c, MatrizCredito__r.RatingPagamento__c, (
                                            SELECT 
                                                territorio__c,
                                                territorio__r.name,
                                                territorio__r.nomeTerritorio__c,
                                                territorio__r.regional__c,
                                                territorio__r.id,
                                                territorio__r.rtv__c,
                                                territorio__r.rtv__r.name,
                                                territorio__r.gerente__c,
                                                territorio__r.gerente__r.name,
                                                territorio__r.diretor__c,
                                                territorio__r.diretor__r.name,
                                                territorio__r.diretor__r.managerId,
                                                territorio__r.diretor__r.manager.name,
                                                VendaDireta__c,
                                                Territorio__r.regional__r.ACS__c
                                            FROM TerritoriosClientesConta__r
                                            )
                FROM Account 
                WHERE id IN :accountIds
            ]);

            Map<Id, Cultura__c> idToCulture = new Map<Id, Cultura__c>([
                SELECT id, descricao__c
                FROM Cultura__c
                WHERE id IN :Collection.of(opportunityLineItems).pluckIds(OpportunityLineItem.cultura__c)
            ]);

            // System.debug('idToAccount => ' + JSON.serializePretty(idToAccount));

            ExistentOpportunityData existentOpportunityData = new ExistentOpportunityData();
            existentOpportunityData.setOpportunityData(opportunity);
            
            if(idToAccount.containsKey(opportunity.accountId)){
                existentOpportunityData.setSelectedAccountData(new AccountAppData(idToAccount.get(opportunity.accountId)));
            }

            if(idToAccount.containsKey(opportunity.recebedorMercadoria__c)){
                existentOpportunityData.setSelectedReceiverData(new AccountAppData(idToAccount.get(opportunity.recebedorMercadoria__c)));
            }

            if(idToAccount.containsKey(opportunity.clienteOrigemRemanejamento__c)){
                existentOpportunityData.setSelectedShipperData(new AccountAppData(idToAccount.get(opportunity.clienteOrigemRemanejamento__c)));
            }

            if(opportunity.campanha__c != null){
                existentOpportunityData.setSelectedCampaignData(getCampaignResultData(opportunity.campanha__c));
            }

            List<Id> productIds = Collection.of(opportunityLineItems).pluckIds(OpportunityLineItem.product2Id);

            List<CulturaProduto__c> productCultures = [
                SELECT cultura__c, produto__c
                FROM CulturaProduto__c
                WHERE produto__c IN :Collection.of(opportunityLineItems).pluckIds(OpportunityLineItem.product2Id)
                AND cultura__c IN :idToCulture.keySet()
            ];

            Map<Id, CulturaProduto__c[]> groupedCultures = Collection.of(productCultures).groupByIds(CulturaProduto__c.produto__c);
            
            List<OpportunityLineItemAppData> products = new List<OpportunityLineItemAppData>();

            for(OpportunityLineItem item : opportunityLineItems){
                OpportunityLineItemAppData productData = new OpportunityLineItemAppData(item);
                
                if(item.recebedorMercadoria__c != null){
                    productData.setSelectedReceiverData(new AccountAppData(idToAccount.get(item.recebedorMercadoria__c)));
                }

                productData.setSelectedCultureData(new CultureData(idToCulture.get(item.cultura__c)));

                productData.setCultures(groupedCultures.get(item.product2Id));

                products.add(productData);
            }

            existentOpportunityData.setProductsData(products);

            Account receiverAccount = idToAccount.get(opportunity.recebedorMercadoria__c == null ? opportunity.accountId : opportunity.recebedorMercadoria__c);
            Account acc = idToAccount.get(opportunity.accountId);

            String businessPlaceId = opportunity.localNegocio__c != null? opportunity.localNegocio__c : acc.localNegocio__c;

            TerritoryData territoryData = null;
            LocalNegocio__c businessPlace = [
                SELECT id, name, zonaTransporte__c
                FROM LocalNegocio__c
                WHERE id = :businessPlaceId
            ];
            
            List<TerritoryData> accountTerritories = new List<TerritoryData>();

            for(TerritorioCliente__c accountTerritory : acc.territoriosClientesConta__r){
                accountTerritories.add(new TerritoryData(accountTerritory.territorio__r));
            }

            List<Territorio__c> territoryDataList = [
                SELECT  name, nomeTerritorio__c, id, gerente__c, gerente__r.name, 
                        diretor__c, diretor__r.name, regional__c, rtv__c, rtv__r.name, 
                        diretor__r.managerId, diretor__r.manager.name, regional__r.ACS__c 
                FROM Territorio__c 
                WHERE Id = :opportunity.territorio__c
            ];
            if(!territoryDataList.isEmpty()){
                territoryData = new TerritoryData(territoryDataList[0]);
            }

            DeliveryAppData deliveryData = getDeliveryData(receiverAccount, opportunity.condicaoExpedicao__c, businessPlace);
            PriceAppData    priceData    = new PriceAppData();
            
            DescontoTipoCliente__c discountByCustomerType = [SELECT id, desconto__c, tipoCliente__c, dataVigenciaInicial__c, dataVigenciaFinal__c FROM DescontoTipoCliente__c WHERE id = :opportunityLineItems[0].idDescontoTipoCliente__c];
            DiscountByCustomerTypeData discountByCustomerTypeData = new DiscountByCustomerTypeData(discountByCustomerType);
            priceData.setCustomerTypeDiscount(discountByCustomerTypeData);
            ShippingPolicyServiceData shippingPolicyServiceData;
            if (opportunity.idTabelaFrete__c != null) {
                TabelaFrete__c freightTable = [
                    SELECT id, frete__c, 
                        (
                            SELECT id, frete__c
                            FROM VigenciaTabelaFrete__r
                            WHERE dataVigenciaDe__c <= :opportunity.dataReferenciaPreco__c
                            AND dataVigenciaAte__c >= :opportunity.dataReferenciaPreco__c
                            ORDER BY createdDate DESC
                        )
                    FROM TabelaFrete__c 
                    WHERE id = :opportunity.idTabelaFrete__c 
                    LIMIT 1
                ];
                shippingPolicyServiceData = new ShippingPolicyServiceData(freightTable);
            }else {
                shippingPolicyServiceData = new ShippingPolicyServiceData();
            }
            
            priceData.setFreightPercentage(shippingPolicyServiceData);
            
            existentOpportunityData.setDeliveryData(deliveryData);
            existentOpportunityData.setPriceData(priceData);
            existentOpportunityData.setTerritoryData(territoryData);
            existentOpportunityData.setBusinessPlaceData(businessPlace);
            existentOpportunityData.setAccountTerritories(accountTerritories);

            result = new ExistentOpportunityDataResult(existentOpportunityData);
        
        } catch (Exception e){

            result = new ExistentOpportunityDataResult(e);

        }

        // System.debug('result => ' + JSON.serializePretty(result));

        return result;

    }

    public static CampaignResultData getCampaignResultData(Id campaignId){
        
        Campanha__c campaign = [
            SELECT 
                id,
                name,
                moeda__c,
                descricao__c,
                dataInicioJuros__c,
                (
                    SELECT id, name, condicaoPagamento__c, condicaoPagamento__r.descricao__c, condicaoPagamento__r.moeda__c, 
                    condicaoPagamento__r.tipo__c, condicaoPagamento__r.jurosComercialFinanceiro__c, condicaoPagamento__r.dias__c
                    FROM CondicoesPagamentoCampanha__r
                    WHERE condicaoPagamento__r.dataVigenciaDe__c <= TODAY
                    AND condicaoPagamento__r.dataVigenciaAte__c >= TODAY
                    ORDER BY createdDate DESC
                ),
                (
                    SELECT id, name, cultura__c, cultura__r.Descricao__c
                    FROM CulturasCampanha__r
                )
            FROM Campanha__c
            WHERE 
                id = :campaignId
        ];

        return new CampaignResultData(campaign);
    }

    @RemoteAction
    public static OpportunityAppReturnedData deleteOpportunity(String opportunityId){

        OpportunityAppReturnedData result;
        
        try{

            Opportunity opportunity = [SELECT id, numeroOportunidade__c FROM Opportunity WHERE id = :opportunityId];
            
            delete opportunity;

            result = new OpportunityAppReturnedData('Oportunidade ' + opportunity.numeroOportunidade__c + ' excluída com sucesso!');

        } catch (Exception e){
            result = new OpportunityAppReturnedData(e);
        }

        return result;

    }
    @RemoteAction
    public static OpportunityAppReturnedData sendEmailClient(String oppId){
        OpportunityAppReturnedData result;
        
        try{
            List<Opportunity> oppClientEmailList = new List<Opportunity>();
            for(Opportunity opp : [SELECT id, numeroOportunidade__c, NomeCliente__c, stageName, EMailAprovacaoPedidoCliente__c, Territorio__c 
                                   FROM Opportunity 
                                   WHERE id =: oppId]){
                oppClientEmailList.add(opp);
            }
            EmailClientToApprove.sendEmail(oppClientEmailList);
            result = new OpportunityAppReturnedData('Email enviado com sucesso!');

        } catch (Exception e){
            result = new OpportunityAppReturnedData(e);
        }
        return result;
    }

    @RemoteAction
    public static OpportunityAppReturnedData upsertOpportunity(OpportunityDataRequest opportunityDataRequest){

        OpportunityAppReturnedData opportunityAppReturnedData;

        Savepoint sp = Database.setSavepoint();

        try {

            Map<String, MinimumOpportunity__c> minimumValues = MinimumOpportunity__c.getAll();
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            if(!minimumValues.isEmpty() && opportunityDataRequest.orderType != 'Bonificação'){
                Decimal totalAmountOpp = 0;
                Decimal dollarRate = 0;
                Decimal minimumValue = minimumValues.values()[0].MinimumValue__c;
                for(ProductDataRequest productData : opportunityDataRequest.products){
                    totalAmountOpp += (productData.salesPriceWithInterest * productData.quantity);
                    dollarRate = productData.dollarRate;
                }
                if(totalAmountOpp < minimumValue){       
                    System.debug(dollarRate);  
                    System.debug(minimumValue);  
                    String value = String.format((opportunityDataRequest.selectedCurrency == 'USD' ? minimumValue * dollarRate : minimumValue).setScale(2).format(), args);   
                    String errorMsg = opportunityDataRequest.selectedCurrency == 'USD' ? Label.MinimumOpportunityErrorUSD : Label.MinimumOpportunityError;
                    throw new OpportunityAppControllerException(errorMsg.replace('{{Value}}', value));
                }
            }

            Account account = null;
            Account accountBusiness = null;
            Account accountReceiver = new Account();
            for(Account acc : [SELECT  id, listaPreco__c, zonaTransporte__c, regionalVendas__c, tipoCliente__c, parentId, shippingState, localNegocio__c, revendaAgenciadora__c, canalDistribuicao__c, saldoLimiteCredito__c,organizacaoVenda__c, setorAtividade__c, emailAprovacaoPedido__c
                               FROM Account
                               WHERE (id =: opportunityDataRequest.selectedAccount OR id =: opportunityDataRequest.selectedBusinessPlace OR id = :opportunityDataRequest.receiverAccount)]){
                if(acc.id == opportunityDataRequest.selectedAccount)
                    account = acc;
                else if(acc.id == opportunityDataRequest.receiverAccount)
                    accountReceiver = acc;
                else
                    accountBusiness = acc;                
            }

            LocalNegocio__c localNegocio = new LocalNegocio__c();

            Id localId = opportunityDataRequest.selectedBusinessPlace == null? account.localNegocio__c : (accountBusiness == null ? opportunityDataRequest.selectedBusinessPlace :  accountBusiness.localNegocio__c); 

            for(LocalNegocio__c local : [SELECT id, zonaTransporte__c FROM LocalNegocio__c WHERE id  = : localId LIMIT 1]){
                localNegocio = local;
            }

            Itinerario__c itin = getItinerary(account, opportunityDataRequest.shipmentCondition, localNegocio);
            
            // Pricebook2 targetPricebook = [SELECT id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

            Integer opportunityCloseDate = getOpportunityCloseDateLimit();

            Decimal totalReal = 0;
            Decimal totalDolar = 0;
            Decimal dollarRate = getDolar().rate;

            if (opportunityDataRequest.products != null && !opportunityDataRequest.products.isEmpty()) {
                for(ProductDataRequest productData : opportunityDataRequest.products) {
                    totalReal += IntegrationUtils.checkDecimal(productData.totalValueWithInterest);
                }
            }
            totalDolar = totalReal / dollarRate;

            Opportunity opportunity                         = new Opportunity();
            if(opportunityDataRequest.id == null){
                opportunity.name                            = opportunityDataRequest.selectedAccountName + ' - ' +  System.now();
            }
            opportunity.id                                  = opportunityDataRequest.id;
            opportunity.stageName                           = 'Iniciado';
            opportunity.closeDate                           = Date.today().addDays(opportunityCloseDate);
            opportunity.dataValidade__c                     = Date.today().addDays(opportunityCloseDate);
            opportunity.moeda__c                            = opportunityDataRequest.selectedCurrency;
            opportunity.condicaoExpedicao__c                = opportunityDataRequest.shipmentCondition;
            opportunity.tipoOrdem__c                        = opportunityDataRequest.orderType;
            opportunity.classificacaoVenda__c               = opportunityDataRequest.salesClassification;
            opportunity.motivoOrdem__c                      = opportunityDataRequest.orderType != 'Bonificação' ? null : opportunityDataRequest.orderReason;
            opportunity.numeroPedidoCliente__c              = opportunityDataRequest.orderNumber;
            opportunity.recebedorMercadoria__c              = opportunityDataRequest.orderType != 'Conta e Ordem' ? opportunityDataRequest.selectedAccount : opportunityDataRequest.receiverAccount;
            opportunity.clienteOrigemRemanejamento__c       = opportunityDataRequest.orderType != 'Remanejamento' ? null : opportunityDataRequest.shipperAccount;
            opportunity.accountId                           = opportunityDataRequest.selectedAccount;
            opportunity.campanha__c                         = opportunityDataRequest.selectedCampaign;
            opportunity.pricebook2Id                        = STANDARD_PRICEBOOK_ID;
            opportunity.condicaoPagamento__c                = opportunityDataRequest.paymentCondition;
            opportunity.vencimentoVendor__c                 = opportunityDataRequest.vendorDueDate != null ? Date.valueOf(opportunityDataRequest.vendorDueDate) : null;
            opportunity.observacaoPDF__c                    = opportunityDataRequest.obsPrint;
            opportunity.observacaoLogistica__c              = opportunityDataRequest.obsLogistic;
            opportunity.observacaoInterna__c                = opportunityDataRequest.obsInternal;
            opportunity.observacaoImpressaNF__c             = opportunityDataRequest.obsPrintNF;
            opportunity.agenciamento__c                     = opportunityDataRequest.isAgencied;
            opportunity.clienteAgenciador__c                = opportunityDataRequest.isAgencied? account.revendaAgenciadora__c : null;
            opportunity.localNegocio__c                     = opportunityDataRequest.selectedBusinessPlace == null? account.localNegocio__c : (accountBusiness == null ? opportunityDataRequest.selectedBusinessPlace :  accountBusiness.localNegocio__c); 
            opportunity.canalDistribuicao__c                = account.canalDistribuicao__c;
            opportunity.saldoLimiteCredito__c               = account.saldoLimiteCredito__c;
            opportunity.organizacaoVenda__c                 = account.organizacaoVenda__c;
            opportunity.jurosComercialFinanceiro__c         = opportunityDataRequest.interest;
            opportunity.valorTotalMercadoriasRealSemIPI__c  = totalReal;//opportunityDataRequest.totalAmountInterest == null? 0 : opportunityDataRequest.totalAmountInterest;
            opportunity.descontoFixoCliente__c              = opportunityDataRequest.priceAppData.customerTypeData != null? opportunityDataRequest.priceAppData.customerTypeData.discount : 0;
            opportunity.percentualFrete__c                  = opportunityDataRequest.priceAppData.freightData != null? (opportunityDataRequest.priceAppData.freightData.shipping != null ? opportunityDataRequest.priceAppData.freightData.shipping : 0) : 0;
            // opportunity.ValorTotalMercadoriasDolar__c       = opportunityDataRequest.totalAmountDolar;
            opportunity.ValorTotalMercadoriasDolarSemIPI__c = totalDolar;//opportunityDataRequest.totalAmountDolarInterest == null? 0 : opportunityDataRequest.totalAmountDolarInterest;
            opportunity.emailAprovacaoPedidoCliente__c      = account.emailAprovacaoPedido__c;
            opportunity.setorAtividade__c                   = account.setorAtividade__c;
            opportunity.cultura__c                          = opportunityDataRequest.culture;
            opportunity.idTabelaFrete__c                    = opportunityDataRequest.priceAppData.freightData != null?opportunityDataRequest.priceAppData.freightData.id : null;
            opportunity.dataReferenciaPreco__c              = opportunityDataRequest.priceReferenceDate == null? null : Date.valueOf(opportunityDataRequest.priceReferenceDate);

            if(opportunityDataRequest.territoryData != null){
                opportunity.territorio__c       = opportunityDataRequest.territoryData.territory;
                opportunity.gerenteRegional__c  = opportunityDataRequest.territoryData.managerId;
                Opportunity.AnalistaCustomerService__c = opportunityDataRequest.territoryData.acsId;
                opportunity.diretorComercial__c = opportunityDataRequest.territoryData.directorId;
                opportunity.regional__c         = opportunityDataRequest.territoryData.regional;
                opportunity.nomeRTV__c          = opportunityDataRequest.territoryData.rtvName;
                opportunity.diretorNegocios__c  = opportunityDataRequest.territoryData.businessDirectorId;
            }

            if (opportunity.campanha__c != null){
                Campanha__c targetCampaign = [
                    SELECT 
                        id, 
                        dataInicioJuros__c
                    FROM Campanha__c
                    WHERE id = :opportunity.campanha__c
                ];

                CondicaoPagamento__c paymentCondition = [
                    SELECT id, dias__c
                    FROM CondicaoPagamento__c
                    WHERE id = :opportunity.condicaoPagamento__c
                ];

                Integer paymentConditionDays = Integer.valueOf(paymentCondition.dias__c);

                if(opportunityDataRequest.interestStartDate != null) {
                    
                    Date interestStartDate;

                    if(opportunityDataRequest.previousSelectedCampaign != opportunityDataRequest.selectedCampaign || Date.valueOf(opportunityDataRequest.interestStartDate) > targetCampaign.dataInicioJuros__c){
                        interestStartDate = targetCampaign.dataInicioJuros__c;
                    } else {
                        interestStartDate = Date.valueOf(opportunityDataRequest.interestStartDate);
                    }
                    
					opportunity.dataInicioJuros__c = (targetCampaign.dataInicioJuros__c  > interestStartDate ? targetCampaign.dataInicioJuros__c : interestStartDate);
                    opportunity.dataInicioJuros__c = (opportunity.dataReferenciaPreco__c > opportunity.dataInicioJuros__c ? opportunity.dataReferenciaPreco__c : opportunity.dataInicioJuros__c);
                    
                } else {
                    opportunity.dataInicioJuros__c = targetCampaign.dataInicioJuros__c < opportunity.dataReferenciaPreco__c ? opportunity.dataReferenciaPreco__c : targetCampaign.dataInicioJuros__c;
                }

                opportunity.dataVencimento__c = opportunity.dataInicioJuros__c.addDays(paymentConditionDays);
            }

            opportunity.DontChangeStageName__c = true;
            upsert opportunity;

            opportunity = [
                SELECT  id, numeroOportunidade__c, observacaoRizotec__c, valorTotalMercadoriasDolar__c, 
                        valorTotalMercadoriasDolarSemIPI__c, valorTotalMercadoriasReal__c, valorTotalMercadoriasRealSemIPI__c 
                FROM Opportunity 
                WHERE id =: opportunity.id
            ];

            List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();

            Set<String> itemIds = new Set<String>();

            Decimal IPItotal = 0;
            Decimal dollarIPItotal = 0;

            for(ProductDataRequest productData : opportunityDataRequest.products){

                productData.discount = (productData.discount == null ? 0 : productData.discount);

                OpportunityLineItem opportunityLineItem = new OpportunityLineItem();
                opportunityLineItem.id                             = productData.itemId;
                opportunityLineItem.quantity                       = productData.quantity;
                opportunityLineItem.unitPrice                      = productData.salesPrice;
                opportunityLineItem.acrescimo__c                   = (productData.discount < 0 ? 0 : productData.discount);
                opportunityLineItem.discount                       = (productData.discount < 0 ? productData.discount*-1 : 0);
                opportunityLineItem.precoLitro__c                  = productData.pricePerLiter;
                opportunityLineItem.precoLitroUSD__c               = productData.pricePerLiterDolar;
                opportunityLineItem.cultura__c                     = productData.culture;
                opportunityLineItem.dataEntrega__c                 = Date.valueOf(productData.deliveryDate);
                opportunityLineItem.descontoMaximo__c              = productData.maxDiscount;
                opportunityLineItem.descontoMinimo__c              = productData.minimumDiscount;
                opportunityLineItem.descontoRecomendado__c         = productData.recommendedDiscount;
                opportunityLineItem.litros__c                      = productData.liter;
                opportunityLineItem.numeroPedidoCliente__c         = productData.orderNumber;
                opportunityLineItem.recebedorMercadoria__c         = productData.receiver;
                opportunityLineItem.confirmado__c                  = productData.confirmed;
                opportunityLineItem.juros__c                       = productData.interest;
                opportunityLineItem.precoListaReferencia__c        = productData.priceList;
                opportunityLineItem.precoListaReferenciaUSD__c     = productData.priceListDolar;
                opportunityLineItem.valorDescontoTipoCliente__c    = productData.customerTypeDiscountValue == null? 0 : productData.customerTypeDiscountValue;
                opportunityLineItem.valorDescontoTipoClienteUSD__c = productData.customerTypeDiscountValueDolar == null? 0 : productData.customerTypeDiscountValueDolar;
                opportunityLineItem.valorFrete__c                  = (productData.freightValue != null ? productData.freightValue : 0);
                opportunityLineItem.ValorFreteUSD__c               = (productData.freightValueDolar != null ? productData.freightValueDolar : 0);
                opportunityLineItem.valorDescontoItem__c           = productData.discountValue;
                opportunityLineItem.valorDescontoItemUSD__c        = productData.discountValueDolar;
                opportunityLineItem.valorJurosItem__c              = productData.interestValue;
                opportunityLineItem.valorJurosItemUSD__c           = productData.interestValueDolar;
                opportunityLineItem.precoVendaSemJuros__c          = productData.salesPrice;
                opportunityLineItem.precoVendasJuros__c            = productData.salesPriceWithInterest;
                opportunityLineItem.PrecoVendaSemJurosUSD__c       = productData.salesPriceDolar;
                opportunityLineItem.PrecoVendasJurosUSD__c         = productData.salesPriceWithInterestDolar;
                opportunityLineItem.itinerario__c                  = productData.itineraryDays == null? 0 : productData.itineraryDays;
                opportunityLineItem.itinerarioId__c                = itin.Id;
                opportunityLineItem.prazoInterno__c                = productData.internalDeadlineDays == null? 0 : productData.internalDeadlineDays;
                opportunityLineItem.dataFaturamento__c             = getBillingDate(opportunityLineItem.dataEntrega__c, Integer.valueOf(opportunityLineItem.itinerario__c));
                opportunityLineItem.totalItemComJuros__c           = productData.totalValueWithInterest;
                opportunityLineItem.totalItemSemjurosUSD__c        = productData.totalValueDolar;
                opportunityLineItem.totalItemComJurosUSD__c        = productData.totalValueWithInterestDolar;
                opportunityLineItem.idPoliticaDesconto__c          = productData.discountPolicyId;
                opportunityLineItem.idTabelaFrete__c               = opportunityDataRequest.priceAppData.freightData != null?opportunityDataRequest.priceAppData.freightData.id : null;
                opportunityLineItem.idTabelaPreco__c               = productData.priceEntryId;
                // System.debug('productData.customerTypeDiscountId => ' + productData.customerTypeDiscountId); //
                opportunityLineItem.idDescontoTipoCliente__C       = productData.customerTypeDiscountId;
                opportunityLineItem.precoLista__c                  = productData.priceFromTable;
                opportunityLineItem.precoListaComDesconto__c       = productData.priceFromTable - opportunityLineItem.valorDescontoTipoCliente__c;
                opportunityLineItem.ipi__c                         = productData.ipiPercentage == null? 0 : productData.ipiPercentage;
                productData.ipiPercentage                          = opportunityLineItem.ipi__c;
                opportunityLineItem.valorIPI__c                    = productData.ipiPercentage == 0? 0 : ((productData.totalValueWithInterest * productData.ipiPercentage) / 100);
                opportunityLineItem.valorTotalIPIDolar__c          = productData.ipiPercentage == 0? 0 : ((productData.totalValueWithInterestDolar * productData.ipiPercentage) / 100);
                opportunityLineItem.taxaDolar__c                   = productData.dollarRate;

                if(productData.discount < 0){
                   productData.discount =  productData.discount*-1;
                }else{
                    productData.discount = 0;
                }

                if(productData.discountPolicyId != null){
                    opportunityLineItem.dataVigenciaInicialDesconto__c = productData.initialDate != null? Date.valueOf(productData.initialDate) : null;
                    opportunityLineItem.DataVigenciaFinalDesconto__c   = productData.finishDate != null? Date.valueOf(productData.finishDate) : null;
                } else {
                    opportunityLineItem.dataVigenciaInicialDesconto__c = null;
                    opportunityLineItem.DataVigenciaFinalDesconto__c = null;
                }

                if(opportunityDataRequest.priceAppData != null){
                    if(opportunityDataRequest.priceAppData.customerTypeData != null){
                        opportunityLineItem.descontoTipoCliente__c = opportunityDataRequest.priceAppData.customerTypeData.discount;
                    }
                    if(opportunityDataRequest.priceAppData.freightData != null){
                        opportunityLineItem.percFrete__c = (opportunityDataRequest.priceAppData.freightData.shipping != null ? opportunityDataRequest.priceAppData.freightData.shipping : 0);
                    }
                }

                if(productData.itemId == null){
                    opportunityLineItem.opportunityId = opportunity.id;
                    opportunityLineItem.product2Id = productData.id;

                    if(productData.confirmed){
                        opportunityLineItem.dataConfirmacao__c      = Date.today();
                        opportunityLineItem.usuarioConfirmacao__c   = UserInfo.getUserId();
                    }
                }

                if(productData.discount > productData.maxDiscount){
                    opportunityLineItem.descontoExcedente__c = productData.discount - productData.maxDiscount;
                    opportunityLineItem.itemParaAprovao__c   = true;
                }else {
                    opportunityLineItem.descontoExcedente__c = 0;
                    opportunityLineItem.itemParaAprovao__c   = false;
                }

                if(productData.itemId != null){
                    
                    if(String.isBlank(productData.confirmationDate) && productData.confirmed){
                        opportunityLineItem.dataConfirmacao__c      = Date.today();
                        opportunityLineItem.usuarioConfirmacao__c   = UserInfo.getUserId();
                    } else if (!productData.confirmed){
                        opportunityLineItem.dataConfirmacao__c      = null;
                        opportunityLineItem.usuarioConfirmacao__c   = null;
                    }

                   itemIds.add(productData.itemId);

                }

                IPItotal       += opportunityLineItem.valorIPI__c;
                dollarIPItotal += opportunityLineItem.valorTotalIPIDolar__c;

                opportunityLineItemsToInsert.add(opportunityLineItem);
            }

            List<String> oppItemProductsId = new List<String>();
            oppItemProductsId = Collection.of(opportunityLineItemsToInsert).pluckIds(OpportunityLineItem.product2Id);
            
            List<Id> productsId = new List<Id>();
            productsId = Collection.of([
                SELECT 
                    Id
                FROM Product2
                WHERE id IN :oppItemProductsId AND family = 'RIZOTEC'
            ]).pluckIds();

            if (productsId.size() > 0) {
                MensagemRizotec__c mensagemRizotec = MensagemRizotec__c.getInstance('Rizotec');
                opportunity.observacaoRizotec__c = mensagemRizotec.linha1__c + mensagemRizotec.linha2__c;
            }

            opportunity.valorTotalIPI__c              = IPItotal;
            opportunity.ValorTotalIPIDolar__c         = dollarIPItotal;
            opportunity.valorTotalMercadoriasDolar__c = (opportunity.valorTotalMercadoriasDolarSemIPI__c + dollarIPItotal);
            opportunity.valorTotalMercadoriasReal__c  = (opportunity.valorTotalMercadoriasRealSemIPI__c + IPItotal);

            opportunity.DontChangeStageName__c = true;
            
            update opportunity;

            List<OpportunityLineItem> itemsToDelete = [
                SELECT id
                FROM OpportunityLineItem
                WHERE id NOT IN :itemIds
                AND opportunityId = :opportunity.id
            ];

            OpportunityLineItemHelper.disableTrigger();
            delete itemsToDelete;
            OpportunityLineItemHelper.enableTrigger();

            upsert opportunityLineItemsToInsert;

            opportunityAppReturnedData = new OpportunityAppReturnedData('Sua oportunidade ' + opportunity.numeroOportunidade__c + ' foi ' + (opportunityDataRequest.id == null? 'criada' : 'atualizada') + ' com sucesso!');


        } catch (Exception e){

            Database.rollback(sp);
            return new OpportunityAppReturnedData(e);

        }

        return opportunityAppReturnedData;
    }

    public static Date getBillingDate(Date deliveryDate, Integer itineraryDays){
        Integer a = 0; 
        Date targetDate = deliveryDate;

        while(a < itineraryDays){
            // System.debug('a => ' + a);
            // System.debug('targetDate => ' + targetDate);

            targetDate = targetDate.addDays(-1);

            // System.debug('(targetDate - 1) => ' + targetDate);
            // System.debug('new date is business day? ' + isBusinessDay(targetDate));

            if (!isBusinessDay(targetDate)){
                continue;
            }


            a++;
            // System.debug('a => ' + a);
        }

        return targetDate;
    }

    public static Boolean isBusinessDay(Date d){
        String weekDayNumber = ((Datetime) d).formatGmt('u');
        return weekDayNumber != '7' && weekDayNumber != '6' && !holidaysShortDateSet.contains(d.day() + '-' + d.month());
    }

    @RemoteAction
    public static OpportunityAppReturnedData getOpportunityAppProductData(OpportunityAppDataRequest request){

        Boolean isCustomerService = isCustomerService();

        if (!isCustomerService){
            request.priceReferenceDate = null;
            request.businessPlaceId = null;
            request.territoryData = null;
        }

        return getOppReturnedData(request);
    }
    
    @RemoteAction
    public static OpportunityAppReturnedData getSimulationProductData(OpportunitySimulationDataRequest request){

        Boolean isCustomerService = isCustomerService();

        if (!isCustomerService){
            request.priceReferenceDate = null;
            request.territoryData = null;
        }

        return getOppReturnedData(request);
    }

    public static OpportunityAppReturnedData getOppReturnedData(OpportunityAppDataRequest request){
        try {
        
            Map<Id, Account> idToAccount = new Map<Id, Account>([
                SELECT id, listaPreco__c, regionalVendas__c, tipoCliente__c, parentId, shippingState, shippingCountry, localNegocio__c, zonaTransporte__c, localNegocio__r.zonaTransporte__c,
                    Atributo7__c, Atributo8__c, Atributo9__c, Atributo10__c, SulFur__c, NaturOleo__c, NaturalOleo__c, Rizotec__c, Stimulate__c, Trianum__c, CanalDistribuicao__c
                FROM Account
                WHERE id = :request.accountId
                OR id= :request.receiverId
            ]); 

            Account account;
            Account receiverAccount;

            // else if is simulation

            Boolean isSimulation = request instanceof OpportunitySimulationDataRequest;

            if (isSimulation){

                OpportunitySimulationDataRequest simulationRequest = (OpportunitySimulationDataRequest) request;

                if (simulationRequest.isCustomerSpecific){
                    account = receiverAccount = [
                        SELECT id, listaPreco__c, regionalVendas__c, tipoCliente__c, parentId, shippingState, shippingCountry, localNegocio__c, zonaTransporte__c, localNegocio__r.zonaTransporte__c,
                                 Atributo7__c, Atributo8__c, Atributo9__c, Atributo10__c, SulFur__c, NaturOleo__c, NaturalOleo__c, Rizotec__c, Stimulate__c, Trianum__c, CanalDistribuicao__c
                        FROM Account
                        WHERE id = :request.accountId
                        LIMIT 1
                    ]; 
                } else {
                    account = receiverAccount = new Account(
                        listaPreco__c   = simulationRequest.priceList,
                        tipoCliente__c  = simulationRequest.customerType,
                        localNegocio__c = simulationRequest.simulationBusinessPlace,
                        shippingState   = simulationRequest.uf,
                        parentId        = simulationRequest.hierarchy,
                        Atributo7__c    = false, 
                        Atributo8__c    = false, 
                        Atributo9__c    = false, 
                        Atributo10__c   = false, 
                        SulFur__c       = false, 
                        NaturOleo__c    = false, 
                        NaturalOleo__c  = false, 
                        Rizotec__c      = false, 
                        Stimulate__c    = false, 
                        Trianum__c      = false 
                    );
                }   

            } else {
                account         = (idToAccount.containsKey(request.accountId) ?  idToAccount.get(request.accountId) : null);
                receiverAccount = (idToAccount.containsKey(request.receiverId) ?  idToAccount.get(request.receiverId) : null); 
            }

            if(account.listaPreco__c == 'Z4' && request.currencyName == 'BRL'){
                throw new OpportunityAppControllerException('Não existe lista de preços para a moeda ' + request.currencyName + '.');
            }

            // System.debug(request.territoryData);

            System.debug(receiverAccount);
            System.debug(request);
            //request.businessPlaceId = receiverAccount != null? receiverAccount.localNegocio__c : request.businessPlaceId;
            request.businessPlaceId = request.businessPlaceId != null? request.businessPlaceId : receiverAccount.localNegocio__c;

            if(request.businessPlaceId == null && receiverAccount.localNegocio__c == null){
                throw new OpportunityAppControllerException('O cliente não possui Local de Negócio cadastrado.');
            }

            LocalNegocio__c businessPlace = [
                SELECT id, zonaTransporte__c
                FROM LocalNegocio__c
                WHERE id = :request.businessPlaceId
            ];
            
            TerritoryData territoryData = null;

            if (request.territoryData != null){
                territoryData = request.territoryData;
            } else {
                List<Territorio__c> territoryDataList = getTerritoryAccordingToUserRole(account.id);
                if(!territoryDataList.isEmpty()){
                    territoryData = new TerritoryData(territoryDataList[0]);
                }
            }

            DeliveryAppData deliveryData;
            
            if (!isSimulation) {
                deliveryData = getDeliveryData(receiverAccount, request.shipmentCondition, businessPlace);
            } else {
                deliveryData = new DeliveryAppData();
                deliveryData.itineraryDays = 0;
            }

            //export freight validation 
            if(receiverAccount.shippingCountry != 'BR'){
                receiverAccount.shippingState = 'PY';
            }

            PriceAppData    priceData    = getPriceData(account.tipoCliente__c, request.shipmentCondition, businessPlace.id, receiverAccount.shippingState, request.priceReferenceDate, receiverAccount.CanalDistribuicao__c);
            PricingAppData  pricingData  = getProductsData(account, request, priceData, deliveryData.itineraryDays, territoryData, request.priceReferenceDate);

            OpportunityAppData opportunityAppData = new OpportunityAppData();
            opportunityAppData.setPricingData(pricingData);
            opportunityAppData.setProductsRA(pricingData);
            opportunityAppData.setDeliveryData(deliveryData);
            opportunityAppData.setPriceData(priceData);
            opportunityAppData.setTerritoryData(territoryData);

            return new OpportunityAppReturnedData(opportunityAppData);

        } catch (Exception e){

            return new OpportunityAppReturnedData(e);

        }
    }

    public static List<Holiday> getHolidays(){
        if (holidays == null){
            holidays = [
                SELECT id, name, activityDate
                FROM Holiday
                ORDER BY activityDate ASC
                LIMIT 3650
            ];

            for(Holiday h : holidays){
                holidaysShortDateSet.add(
                    h.activityDate.day() + '-' + h.activityDate.month()
                );
            }
        }

        return holidays;
    }

    public static DeliveryAppData getDeliveryData(Account receiverAccount, String shipmentCondition, LocalNegocio__c businessPlace){

        Integer internalDeadlineDays = PrazoInterno__c.getOrgDefaults().dias__c == null? 0 : Integer.valueOf(PrazoInterno__c.getOrgDefaults().dias__c);

        List<Holiday> holidays = getHolidays();

        List<Date> allHolidaysDates = new List<Date>();
        
        if(!holidays.isEmpty()){
            allHolidaysDates = Collection.of(holidays).pluckDates(Holiday.activityDate);
        }

        Itinerario__c itin = getItinerary(receiverAccount, shipmentCondition, businessPlace);

        Integer itineraryDays = Integer.valueOf(itin.dias__c);
        Date minimumDate = getMinimumDate(allHolidaysDates, internalDeadlineDays, itineraryDays);

        DeliveryAppData deliveryData = new DeliveryAppData();
        deliveryData.setMininumDate(minimumDate);
        deliveryData.setUnavailableDates(allHolidaysDates);
        deliveryData.setInternalDeadlineDays(internalDeadlineDays);
        deliveryData.setItineraryDays(itineraryDays);
        deliveryData.setitinerary(itin.Id);

        return deliveryData;
    }

    public static Itinerario__c getItinerary(Account account, String shipmentCondition, LocalNegocio__c businessPlace){

        String origin = businessPlace.zonaTransporte__c;

        Itinerario__c itinerary = null;

        System.debug(shipmentCondition);
        System.debug(account.zonaTransporte__c);
        System.debug(origin);
        System.debug(businessPlace);
        
        List<Itinerario__c> itineraries = [
            SELECT id, dias__c
            FROM Itinerario__c
            WHERE tipoExpedicao__c =: shipmentCondition
            AND zonaTransporteDestino__c =: account.zonaTransporte__c
            AND zonaTransporteOrigem__c =: origin
            LIMIT 1
        ];
        System.debug('shipmentCondition => ' + shipmentCondition);
        System.debug('account.zonaTransporte__c => ' + account.zonaTransporte__c);
        System.debug('origin => ' + origin);

        if(!itineraries.isEmpty()){

            itinerary = itineraries[0];

        } else {
            
            throw new OpportunityAppControllerException('Não foi encontrado um itinerário adequado para esta oportunidade.');
        
        }

        return itinerary;
    }
    
    public static Map<String, Itinerario__c> getItinerary(List<Id> accountZonaList, Set<String> shipmentConditionList, Set<String> originZonaList){
        System.debug(shipmentConditionList);
        System.debug(accountZonaList);
        System.debug(originZonaList);
        List<Itinerario__c> itineraries = [
            SELECT id, dias__c, ZonaTransporteDestino__c, tipoExpedicao__c, zonaTransporteOrigem__c
            FROM Itinerario__c
            WHERE tipoExpedicao__c IN: shipmentConditionList
            AND zonaTransporteDestino__c IN: accountZonaList
            AND zonaTransporteOrigem__c IN: originZonaList
        ];
        Map<String, Itinerario__c> itineraryMap = new Map<String, Itinerario__c>();
        for(Itinerario__c itin : itineraries){
            itineraryMap.put(itin.zonaTransporteDestino__c+'_'+itin.tipoExpedicao__c+'_'+itin.zonaTransporteOrigem__c, itin);
        }
        return itineraryMap;
    }

    public static Date getMinimumDate(List<Date> allHolidaysDates, Integer internalDeadlineDays, Integer itineraryDays){

        Datetime minimumDate = System.now();            
            
        Set<String> weekendDays = new Set<String>{'Saturday', 'Sunday'};
        
        Integer totalDays = Integer.valueOf(itineraryDays + internalDeadlineDays);

        Integer count = 0;

        do {
            minimumDate = minimumDate.addDays(1);
            // System.debug('count => ' + count);
            // System.debug('minimumDate => ' + minimumDate);
            // System.debug('returnDayInWeek(minimumDate) => ' + returnDayInWeek(minimumDate));
            // System.debug('!weekendDays.contains(returnDayInWeek(minimumDate)) => ' + !weekendDays.contains(returnDayInWeek(minimumDate)));
            // System.debug('!allHolidaysDates.contains(minimumDate.date()) => ' + !allHolidaysDates.contains(minimumDate.date()));
            if(!weekendDays.contains(returnDayInWeek(minimumDate)) && !allHolidaysDates.contains(minimumDate.date())){
                count++;
            }
        } while (count < totalDays);

        // System.debug('minimumDate => ' + minimumDate);

        // System.debug('minimumDate.date() => ' + minimumDate.date());
        return minimumDate.date();
    }
    
    public static Date getMinimumDate(Integer itineraryDays){
        
        List<Holiday> holidays = getHolidays();
        List<Date> allHolidaysDates = new List<Date>();
        
        if(!holidays.isEmpty()){
            allHolidaysDates = Collection.of(holidays).pluckDates(Holiday.activityDate);
        }
        Integer internalDeadlineDays = PrazoInterno__c.getOrgDefaults().dias__c == null? 0 : Integer.valueOf(PrazoInterno__c.getOrgDefaults().dias__c);
        return getMinimumDate(allHolidaysDates, internalDeadlineDays, itineraryDays);
    }

    public static String returnDayInWeek(DateTime dt){
        // System.debug('dt.format(\'EEEE\') => ' + dt.format('EEEE'));
        return dt.format('EEEE');
    }

    public static PriceAppData getPriceData(String customerType, String shipmentCondition, String businessLocation, String uf, String priceReferenceDate, String distributionChannel){

        PriceAppData priceData = new PriceAppData();
        
        try{

            Date referenceDate = priceReferenceDate == null? Date.today() : Date.valueOf(priceReferenceDate);            

            OpportunityData opportunityData = new OpportunityData(shipmentCondition, businessLocation, uf);
            opportunityData.setDistributionChannel(uf == 'PY' ? '20' : distributionChannel);
            
            DiscountByCustomerTypeService discountByCustomerTypeService = new DiscountByCustomerTypeService(customerType, referenceDate);

            DiscountByCustomerTypeReturnedData discountByCustomerTypeReturn = discountByCustomerTypeService.getDiscountByCustomerType();

            if(discountByCustomerTypeReturn.hasErrors){
                throw new OpportunityAppControllerException(discountByCustomerTypeReturn.message);
            } else {
                Decimal discountByCustomerType = discountByCustomerTypeReturn.data != null? discountByCustomerTypeReturn.data.discount : 0;
                priceData.setCustomerTypeDiscount(discountByCustomerTypeReturn.data);
            }
            ShippingPolicyService shippingPolicyService = new ShippingPolicyService(opportunityData);
            shippingPolicyService.setReferenceDate(referenceDate);
            ShippingPolicyServiceReturnedData shippingPolicyServiceReturn = shippingPolicyService.getShippingTable();

            if(shippingPolicyServiceReturn.hasErrors){
                throw new OpportunityAppControllerException(shippingPolicyServiceReturn.message);
            } else {
                Decimal freightPercentage = shippingPolicyServiceReturn != null && shippingPolicyServiceReturn.data != null? shippingPolicyServiceReturn.data.shipping : 0;
                priceData.setFreightPercentage(shippingPolicyServiceReturn.data);
            }

        } catch (Exception e){

            throw new OpportunityAppControllerException(e.getMessage());
        
        }

        return priceData;

    }

    public static PricingAppData getProductsData(Account account, OpportunityAppDataRequest request, PriceAppData priceData, Integer itineraryDays, TerritoryData territoryData, String priceReferenceDate){
        
        String shipmentCondition = request.shipmentCondition;
        PricingAppData result = new PricingAppData();

        Date referenceDate = priceReferenceDate != null? Date.valueOf(priceReferenceDate) : System.today();
        try{

            List<ProductAppData> productAppDataList = new List<ProductAppData>();
            List<Id> targetProductIds;
            // System.debug('request.cultures => ' + request.cultures);

            if (request.cultures.isEmpty()){
                targetProductIds = Collection.of([
                    SELECT 
                        id
                    FROM Product2
                    LIMIT 10000
                ]).pluckIds();
            } else {
                targetProductIds = Collection.of([
                    SELECT 
                        produto__c
                    FROM CulturaProduto__c
                    WHERE cultura__c IN :request.cultures
                ]).pluckIds(CulturaProduto__c.produto__c);
            }

            // System.debug('targetProductIds => ' + targetProductIds);

            PricingService pricingService = new PricingService(account, referenceDate);
            pricingService.setCurrency(request.currencyName);
            pricingService.setRegional(territoryData != null? territoryData.regional : null);

            List<Id> accountValidProducts = filterValidProducts(account, targetProductIds);

            // System.debug('accountValidProducts => ' + accountValidProducts);

            Map<String, ProductPriceEntry> productIdToPriceEntry = pricingService.getPrices(accountValidProducts);

            Decimal discountByCustomerType = priceData.customerTypeData != null? priceData.customerTypeData.discount : 0;
            Decimal freightPercentage = priceData.freightData != null? (priceData.freightData.shipping != null ? priceData.freightData.shipping : 0) : 0;

            AggregateResult[] lineItemCounts = [
                SELECT product2Id, count(quantity)quant
                FROM OpportunityLineItem
                WHERE product2Id IN: productIdToPriceEntry.keySet()
                AND opportunity.accountId = :account.id
                AND opportunity.tipoOrdem__c != 'Bonificação'
                AND opportunity.stageName = 'Aprovado Cliente'
                AND opportunity.moeda__c = :request.currencyName
                GROUP BY product2Id, product2.name
                ORDER BY count(quantity) DESC
                LIMIT 10
            ];

            Map<Id, ProductDetailsAppData> productIdToProductDetails = new Map<Id, ProductDetailsAppData>();

            if(!lineItemCounts.isEmpty()){

                Set<Id> productDetailsIds = new Set<Id>();

                for(AggregateResult aggregateResult : lineItemCounts){
                    productDetailsIds.add((Id) aggregateResult.get('product2Id'));
                }

                Map<Id, OpportunityLineItem> opportunityLineItems = new Map<Id, OpportunityLineItem>([
                    SELECT  product2.name, product2.sku__c, product2.litragem__c, opportunity.closeDate,  Opportunity.Account.BloqueadoCredito__c,
                            opportunity.condicaoPagamento__r.descricao__c, quantity, precoVendaSemJurosBRLUSD__c, precoVendasJurosBRLUSD__c, discount, precoLitroBRLUSD__c, opportunityId,  opportunity.jurosComercialFinanceiro__c
                    FROM OpportunityLineItem
                    WHERE product2Id IN: productDetailsIds
                    AND opportunity.accountId =: account.id
                    AND opportunity.tipoOrdem__c != 'Bonificação'
                    AND opportunity.stageName = 'Aprovado Cliente'
                    AND opportunity.moeda__c = :request.currencyName
                    ORDER BY opportunity.createdDate DESC, opportunity.closeDate DESC
                ]);

                for(OpportunityLineItem opportunityLineItem : opportunityLineItems.values()){
                    if(productDetailsIds.contains(opportunityLineItem.product2Id)){
                        productIdToProductDetails.put(opportunityLineItem.product2Id, new ProductDetailsAppData(OpportunityLineItem));
                        productDetailsIds.remove(opportunityLineItem.product2Id);
                    }
                }
            }

            Map<Id, Product2> productIdToProduct = new Map<Id, Product2>([
                SELECT id, name, litragem__c, sku__c, multiplicidade__c, ipi__c
                FROM Product2
                WHERE id IN: productIdToPriceEntry.keySet()
            ]);
            
            CulturaProduto__c[] productCultures;
            
            if (request.cultures.isEmpty()){ 
                productCultures = [
                    SELECT cultura__c, produto__c
                    FROM CulturaProduto__c
                    WHERE produto__c IN: productIdToProduct.keySet()
                ];
            } else {
                productCultures = [
                    SELECT cultura__c, produto__c
                    FROM CulturaProduto__c
                    WHERE produto__c IN: productIdToProduct.keySet()
                    AND cultura__c IN :request.cultures
                ];
            }

            Map<Id, CulturaProduto__c[]> groupedCultures = Collection.of(productCultures).groupByIds(CulturaProduto__c.produto__c);

            Map<String, ProductAppData> productIdToProductData = new Map<String, ProductAppData>();

            Integer internalDeadlineDays = PrazoInterno__c.getOrgDefaults().dias__c == null? 0 : Integer.valueOf(PrazoInterno__c.getOrgDefaults().dias__c);

            for(Product2 product : productIdToProduct.values()){

                ProductAppData productAppData = new ProductAppData();
                productAppData.setProductData(product);
                productAppData.setPricebookEntry(productIdToPriceEntry.get(product.id).pricebookEntry);
                productAppData.setPriceList(productIdToPriceEntry.get(product.id).price, discountByCustomerType, freightPercentage);
                productAppData.setProductDetails(productIdToProductDetails.get(product.id));
                productAppData.setCultures(groupedCultures.get(product.id));
                productAppData.setInternalDeadlineDays(internalDeadlineDays);
                productAppData.setItineraryDays(itineraryDays);
                productAppData.setItineraryDays(itineraryDays);
                productAppData.setReferences(productIdToPriceEntry.get(product.id).priceId, (priceData.freightData != null? priceData.freightData.id : null), (priceData.customerTypeData != null? priceData.customerTypeData.id : null));

                productIdToProductData.put(product.id, productAppData);
            }

            // DiscountPolicyService discountPolicyService = new DiscountPolicyService(territoryData, account.id, account.parentId);
            DiscountPolicyOpportunityData discountPolicyOpportunityData = new DiscountPolicyOpportunityData(territoryData, account.id, account.parentId);
            DiscountPolicyService discountPolicyService = new DiscountPolicyService(discountPolicyOpportunityData, Date.valueOf(referenceDate));
            // System.debug('discountPolicyService => ' + discountPolicyService);
            DiscountPolicyServiceReturnedData discountPolicyServiceReturn = discountPolicyService.getDiscountPolicy(new Set<String>((List<String>)(targetProductIds)));
            // System.debug('discountPolicyServiceReturn => ' + discountPolicyServiceReturn);

            // System.debug('productIdToProductData => ' + JSON.serializePretty(productIdToProductData));

            for(String productId : discountPolicyServiceReturn.data.keySet()){
                // System.debug('productId => ' + productId);
                // System.debug('discountPolicyServiceReturn.data.containsKey(productId) => ' + discountPolicyServiceReturn.data.containsKey(productId));
                if(productIdToProductData.containsKey(productId)){
                    productIdToProductData.get(productId).setDiscountPolicyDataToProduct(discountPolicyServiceReturn.data.get(productId));
                }
            }

            // System.debug('productIdToProductData => ' + JSON.serializePretty(productIdToProductData));
            productAppDataList = productIdToProductData.values();

            result.setProductsRA(DeliveryAppController.getRAValidationProducts(targetProductIds));
    
            result.setProductsData(productAppDataList);
        
        } catch (Exception e){

            throw new OpportunityAppControllerException(e.getStackTraceString());

        }

        return result;
    }

    private static List<Id> filterValidProducts(Account a, List<Id> productIds){
        List<String> fields = new List<String>{'Atributo7__c', 
                                                'Atributo8__c', 
                                                'Atributo9__c', 
                                                'Atributo10__c', 
                                                'Sulfur__c', 
                                                'NaturOleo__c', 
                                                'NaturalOleo__c', 
                                                'Rizotec__c', 
                                                'Stimulate__c', 
                                                'Trianum__c'};

        Set<Id> validProducts = new Set<Id>(productIds);
        List<Product2> allProdList = new List<Product2>(); 
        for(Product2 prod : [SELECT id, Atributo7__c, Atributo8__c, Atributo9__c, Atributo10__c, SulFur__c, NaturOleo__c, NaturalOleo__c, Rizotec__c, Stimulate__c, Trianum__c 
            FROM Product2
            WHERE Id IN :productIds]){
            allProdList.add(prod);
        }
        SObject sAccount = (sObject)a;
        for(String field : fields){
            if(Boolean.valueOf(sAccount.get(field))){
                // System.debug(sAccount.get(field));
                // System.debug(allProdList);
                // System.debug('Product2.'+field);
                // System.debug(field);
                Map<Boolean, List<Product2>> availableToProdMap = (Map<Boolean, List<Product2>>)Collection.of(allProdList).groupByBooleans(field);
                if(availableToProdMap.containsKey(true)){
                    for(Product2 prod : availableToProdMap.get(true)){
                        validProducts.remove(prod.Id);
                    }
                }
            }
        }
        
        Collection productCollection = Collection.of([
            SELECT atributoDefensivos__c, produto__c
            FROM ProdutoAtributo__c
            WHERE produto__c IN :productIds
        ]);

        Map<Id, ProdutoAtributo__c[]> productsGrouped = productCollection.groupByIds(ProdutoAtributo__c.atributoDefensivos__c);

        Set<Id> productRestrictions = new Set<Id>(
            Collection.of([
                SELECT atributoDefensivos__c
                FROM ProdutoAtributo__c
                WHERE produto__c IN :productIds
            ]).pluckIds('atributoDefensivos__c')
        );
        
        Set<Id> customerRestrictions = new Set<Id>(
            Collection.of([
                SELECT atributoDefensivos__c
                FROM ClienteAtributo__c
                WHERE cliente__c = :a.id
            ]).pluckIds('atributoDefensivos__c')
        );

        customerRestrictions.retainAll(productRestrictions);

        List<Id> invalidProducts = productCollection.filter(
            Match.field(ProdutoAtributo__c.atributoDefensivos__c).isIn(customerRestrictions)
        ).pluckIds(ProdutoAtributo__c.produto__c);

        validProducts.removeAll(invalidProducts);

        return new List<Id>(validProducts);
    }

    public static List<Territorio__c> getTerritoryAccordingToUserRole(Id accountId){

        List<Territorio__c> RTVTerritories = new List<Territorio__c>();

        User user = [
            SELECT id, name, userRoleId, userRole.name
            FROM User
            WHERE id =: UserInfo.getUserId()
        ];

        //if(user.userRole.name = 'RTV')

        List<TerritorioCliente__c> customerTerritories = [
            SELECT territorio__c
            FROM TerritorioCliente__c
            WHERE conta__c =: accountId
            AND Territorio__r.rtv__c =: UserInfo.getUserId()
            LIMIT 1
        ];

        if(!customerTerritories.isEmpty()){
            RTVTerritories = [
                SELECT  name, nomeTerritorio__c, id, gerente__c, 
                        gerente__r.name, diretor__c, diretor__r.name,
                        regional__c, rtv__c, rtv__r.name, diretor__r.managerId,
                        diretor__r.manager.name, regional__r.ACS__c
                FROM Territorio__c 
                WHERE id =: customerTerritories[0].territorio__c
            ];
        }

        return RTVTerritories;
    }

    public static DollarAppData getDolar() {
        CotacaoMoeda__c dollarExchangeRate = [SELECT id, data__c, taxa__c, taxaMedia__c FROM CotacaoMoeda__c WHERE moeda__c = 'USD' ORDER BY data__c DESC LIMIT 1];
        DollarAppData dollarData = new DollarAppData();
        dollarData.setDollarData(dollarExchangeRate);

        return dollarData;
    }

    @RemoteAction
    public static OpportunityAppReturnedBaseData getBaseData(){

        OpportunityAppReturnedBaseData opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData();
        
        try {
         
            OpportunityAppBaseData opportunityAppBaseData = new OpportunityAppBaseData(
                getShipmentConditions(),
                getCurrencies(),
                getAllPaymentConditions(),
                getOrderRecordTypes(),
                getSalesClassficiations(),
                getOrderReasons(),
                getAllCultures(),
                getDolar()
            );

            opportunityAppBaseData.setHolidays(getHolidays());

            Decimal confirmationDeadlineDays = 0;
            List<PrazoConfirmacaoEntrega__c> confirmationDeadlineList = [SELECT dias__c FROM PrazoConfirmacaoEntrega__c ORDER BY CreatedDate DESC LIMIT 1];

            if (confirmationDeadlineList.size() > 0) {
                confirmationDeadlineDays = confirmationDeadlineList[0].dias__c;
            }

            opportunityAppBaseData.setConfirmationDeadline(confirmationDeadlineDays);
            
            opportunityAppBaseData.setDeliveryQuantityLimit(getDeliveryQuantityLimit());

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(opportunityAppBaseData);

        } catch (Exception e){

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(e.getMessage());

        }

        return opportunityAppReturnedBaseData;
    }

    public static Integer getDeliveryQuantityLimit(){
        
        LimiteProgramacoesEntrega__c deliveryQuantityCustomSetting = LimiteProgramacoesEntrega__c.getOrgDefaults();

        if(deliveryQuantityCustomSetting.quantidadeMaxima__c == null){
            return 0;
        }

        return Integer.valueOf(deliveryQuantityCustomSetting.quantidadeMaxima__c);
        
    }

    public static Integer getOpportunityCloseDateLimit(){
                
        VencimentoOportunidade__c opportunityCloseDateCustomSetting = VencimentoOportunidade__c.getOrgDefaults();

        if(opportunityCloseDateCustomSetting.dias__c == null){
            return 0;
        }

        return Integer.valueOf(opportunityCloseDateCustomSetting.dias__c);
        
    }

    private static List<PicklistEntryData> getShipmentConditions(){
        
        Schema.DescribeFieldResult shipmentConditionsFieldResult = Opportunity.CondicaoExpedicao__c.getDescribe();
        List<Schema.PicklistEntry> shipmentConditionsPickListEntry = shipmentConditionsFieldResult.getPickListValues();

        List<PicklistEntryData> shipmentConditionsValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : shipmentConditionsPickListEntry){
            shipmentConditionsValuesList.add(new PicklistEntryData(value));
        }

        return  PicklistEntryData.filterInvalidValues(shipmentConditionsValuesList);
    }

    private static List<PicklistEntryData> getCurrencies(){
        
        Schema.DescribeFieldResult currenciesFieldResult = Opportunity.Moeda__c.getDescribe();
        List<Schema.PicklistEntry> currenciesPickListEntry = currenciesFieldResult.getPickListValues();

        List<PicklistEntryData> currenciesValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : currenciesPickListEntry){
            currenciesValuesList.add(new PicklistEntryData(value));
        }

        return currenciesValuesList;
    }

    @RemoteAction
    public static ResponsePaymentCondition getRemoteAllPaymentConditions(String dt) {
        ResponsePaymentCondition response;
        
        try {
            response = new ResponsePaymentCondition(getAllPaymentConditions(Date.valueOf(dt)));
        } catch (Exception e){
            response = new ResponsePaymentCondition(e);
        }

        return response;
    }

    private static List<PaymentConditionData> getAllPaymentConditions(){
        return getAllPaymentConditions(null);
    }

    private static List<PaymentConditionData> getAllPaymentConditions(Date dt){

        if (dt == null) {
            dt = Date.today();
        }

        List<PaymentConditionData> paymentConditions = new List<PaymentConditionData>();

        for(CondicaoPagamento__c paymentCondition : [
                                                        SELECT id, descricao__c, jurosComercialFinanceiro__c, tipo__c, moeda__c, dias__c,
                                                            (
                                                                SELECT id, jurosComercialFinanceiro__c
                                                                FROM Vig_ncias_Condi_o_Pagamento__r
                                                                WHERE dataVigenciaDe__c <= :dt 
                                                                AND dataVigenciaAte__c >= :dt
                                                                ORDER BY createdDate DESC
                                                            )
                                                        FROM CondicaoPagamento__c 
                                                        WHERE id IN (
                                                                        SELECT condicaoPagamento__c 
                                                                        FROM VigenciaCondicao__c
                                                                        WHERE dataVigenciaDe__c <= :dt AND dataVigenciaAte__c >= :dt
                                                                    )
                                                        ORDER BY dias__c ASC
                                                    ]){
            paymentConditions.add(new PaymentConditionData(paymentCondition));
        }

        return paymentConditions;
    }

    private static List<PicklistEntryData> getOrderRecordTypes(){

        Schema.DescribeFieldResult orderTypesFieldResult = Opportunity.TipoOrdem__c.getDescribe();
        List<Schema.PicklistEntry> orderTypesPickListEntry = orderTypesFieldResult.getPickListValues();

        List<PicklistEntryData> orderTypesValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : orderTypesPickListEntry){
            orderTypesValuesList.add(new PicklistEntryData(value));
        }

        return PicklistEntryData.filterInvalidValues(orderTypesValuesList);
    }

    private static List<PicklistEntryData> getSalesClassficiations(){
        
        Schema.DescribeFieldResult salesClassficiationsFieldResult = Opportunity.ClassificacaoVenda__c.getDescribe();
        List<Schema.PicklistEntry> salesClassficiationsPickListEntry = salesClassficiationsFieldResult.getPickListValues();

        List<PicklistEntryData> salesClassficiationsValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : salesClassficiationsPickListEntry){
            salesClassficiationsValuesList.add(new PicklistEntryData(value));
        }

        return salesClassficiationsValuesList;
    }

    private static List<PicklistEntryData> getOrderReasons(){
        
        Schema.DescribeFieldResult orderReasonsnsFieldResult = Opportunity.MotivoOrdem__c.getDescribe();
        List<Schema.PicklistEntry> orderReasonsPickListEntry = orderReasonsnsFieldResult.getPickListValues();

        List<PicklistEntryData> orderReasonsonsValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : orderReasonsPickListEntry){
            orderReasonsonsValuesList.add(new PicklistEntryData(value));
        }

        return PicklistEntryData.filterInvalidValues(orderReasonsonsValuesList);
    }

    private static List<CultureData> getAllCultures(){

        List<CultureData> cultures = new List<CultureData>();

        for(Cultura__c culture : [SELECT id, descricao__c FROM Cultura__c ORDER BY descricao__c ASC]){
            cultures.add(new CultureData(culture));
        }

        return cultures;
    }

    @RemoteAction
    public static List<AccountResultData> searchAccount(RecordQueryRequest request){

        Boolean iSRTV = isRTV();

        List<Id> allowedAccountIds = new List<Id>();

        if(isRTV){

            List<AccountShare> rtvAccountShareList = [SELECT accountId, userOrGroupId FROM AccountShare WHERE userOrGroupId = :UserInfo.getUserId()];

            allowedAccountIds = Collection.of(rtvAccountShareList).pluckIds(AccountShare.AccountId);
            
        }

        return searchAccountLookup(request, allowedAccountIds);

    }

    public static List<AccountResultData> searchAccountLookup(RecordQueryRequest request, List<Id> allowedAccountIds){

        List<AccountResultData> result = new List<AccountResultData>();

        String accountNameFilter = '%' + request.searchTerm + '%';

        Map<String, LookupComponentRecordFilter> filterMap = new Map<String, LookupComponentRecordFilter>();

        if (request.filters != null){
            for(LookupComponentRecordFilter filter : request.filters){
                filterMap.put(filter.fieldApiName.toLowerCase(), filter);
            }
        }

        LookupComponentRecordFilter recordTypeFilter = filterMap.get('recordtype.developername');

        String recordTypeTerm = recordTypeFilter == null? '' : (String.isEmpty(recordTypeFilter.value)? '' : recordTypeFilter.value);

        recordTypeTerm = String.isEmpty(recordTypeTerm)? '%%' : recordTypeTerm;

        Account[] targetAccounts;

        if(allowedAccountIds.isEmpty()){

            targetAccounts = [
                SELECT 
                    id,
                    Name,
                    TipoCliente__c,
                    RevendaAgenciadora__c,
                    RatingPagamento__c,
                    BloqueadoCredito__c,
                    ShippingState,
                    ShippingCity,
                    NomeFazenda__c,
                    ExternalId__c,
                    ContribuinteICMS__c,
                    ParentId,
                    Parent.BloqueadoCredito__c,
                    MatrizCredito__c,
                    MatrizCredito__r.RatingPagamento__c,
                    CNPJ__c,
                    localNegocio__c, 
                    localNegocio__r.id, 
                    localNegocio__r.name,
                    localNegocio__r.Descricao__c,
                    localNegocio__r.Codigo__c,
                    listaPreco__c,
                    recordType.developerName,
                    (
                        SELECT 
                            territorio__c,
                            territorio__r.name,
                            territorio__r.nomeTerritorio__c,
                            territorio__r.regional__c,
                            territorio__r.id,
                            territorio__r.rtv__c,
                            territorio__r.rtv__r.name,
                            territorio__r.gerente__c,
                            territorio__r.gerente__r.name,
                            territorio__r.diretor__c,
                            territorio__r.diretor__r.name,
                            territorio__r.diretor__r.managerId,
                            territorio__r.diretor__r.manager.name,
                        	territorio__r.regional__r.ACS__c,
                            VendaDireta__c
                        FROM TerritoriosClientesConta__r
                    )
                FROM Account
                WHERE 
                    recordType.developerName LIKE :recordTypeTerm AND 
                    (
                            CNPJ__c         LIKE :accountNameFilter
                        OR  name            LIKE :accountNameFilter
                        OR  nomeFazenda__c  LIKE :accountNameFilter
                        OR  ShippingCity    LIKE :accountNameFilter
                        OR  ShippingState   LIKE :accountNameFilter
                        OR  ExternalId__c   LIKE :accountNameFilter
                    )
                    AND Status__c != 'bloqueado' 
                    AND RecordType.DeveloperName != 'Hierarquia' 
            ];

        } else {

            targetAccounts = [
                SELECT 
                    id,
                    Name,
                    TipoCliente__c,
                    RevendaAgenciadora__c,
                    RatingPagamento__c,
                    BloqueadoCredito__c,
                    ShippingState,
                    ShippingCity,
                    NomeFazenda__c,
                    ExternalId__c,
                    ContribuinteICMS__c,
                    ParentId,
                    Parent.BloqueadoCredito__c,
                    MatrizCredito__c,
                    MatrizCredito__r.RatingPagamento__c,
                    CNPJ__c,
                    localNegocio__c, 
                    localNegocio__r.id, 
                    localNegocio__r.name,
                    localNegocio__r.Descricao__c,
                    localNegocio__r.Codigo__c,
                    listaPreco__c,
                    recordType.developerName,
                    (
                        SELECT 
                            territorio__c,
                            territorio__r.name,
                            territorio__r.nomeTerritorio__c,
                            territorio__r.regional__c,
                            territorio__r.id,
                            territorio__r.rtv__c,
                            territorio__r.rtv__r.name,
                            territorio__r.gerente__c,
                            territorio__r.gerente__r.name,
                            territorio__r.diretor__c,
                            territorio__r.diretor__r.name,
                            territorio__r.diretor__r.managerId,
                            territorio__r.diretor__r.manager.name,
                            VendaDireta__c
                        FROM TerritoriosClientesConta__r
                    )
                FROM Account
                WHERE 
                    recordType.developerName LIKE :recordTypeTerm AND 
                    (
                            CNPJ__c         LIKE :accountNameFilter
                        OR  name            LIKE :accountNameFilter
                        OR  nomeFazenda__c  LIKE :accountNameFilter
                        OR  ShippingCity    LIKE :accountNameFilter
                        OR  ShippingState   LIKE :accountNameFilter
                        OR  ExternalId__c   LIKE :accountNameFilter
                    )
                    AND Status__c != 'bloqueado' 
                    AND RecordType.DeveloperName != 'Hierarquia'
                    AND id IN :allowedAccountIds
            ];

        }

        for(Account a : targetAccounts){
            AccountResultData resultData = new AccountResultData(a);
            resultData.setPriceList(a.listaPreco__c);

            resultData.territories = new List<TerritoryData>();

            Boolean temVendaDireta = false;
            for(TerritorioCliente__c accountTerritory : a.territoriosClientesConta__r){
                if(accountTerritory.VendaDireta__c) {
                    temVendaDireta = true;
                    break;
                } 
            }

            for(TerritorioCliente__c accountTerritory : a.territoriosClientesConta__r){
                TerritoryData territoryData = new TerritoryData(accountTerritory);
                territoryData.addvendaDiretaToTerritoryData(accountTerritory.VendaDireta__c);

                if (!isRTV()) {
                    resultData.territories.add(territoryData);
                } else {
                    if (temVendaDireta && accountTerritory.VendaDireta__c) {
                        resultData.territories.add(territoryData);
                    }
                        
                    if (!temVendaDireta) {
                        resultData.territories.add(territoryData);
                    }
                }

            }

            if (String.isNotBlank(a.MatrizCredito__c) && String.isNotBlank(a.MatrizCredito__r.RatingPagamento__c)) {
                resultData.paymentRating = a.MatrizCredito__r.RatingPagamento__c;
            }

            result.add(resultData);
        }

        return result;

    }

    @RemoteAction
    public static List<ResultData> searchLookup(RecordQueryRequest request){

        String targetColumnWhereClause = '%' + request.searchTerm + '%';
        String[] queryFilterList = new String[]{};

        String[] fieldsToQuery = new List<String>{
            'id', 
            'name'
        };

        if (request.filters != null){
            for(LookupComponentRecordFilter filter : request.filters){
                queryFilterList.add(
                    String.format('{0} {1} {2}', 
                    new List<String>{ 
                        filter.fieldApiName,
                        filter.operator,
                        filter.value
                    })
                );
            }
        }

        String queryAdditionalFilters = (
            !queryFilterList.isEmpty()?
            ' AND ' + String.join(queryFilterList, ' AND '):
            ''
        );


        String nameFilterClause;

        // must be API 32.0 or higher
        if (request.searchTarget != null){
            List<String> targets = request.searchTarget.split(';');

            if (targets.size() > 1){
                List<String> clauses = new List<String>();

                for(String targetField : targets){
                    clauses.add(targetField + ' LIKE :targetColumnWhereClause');
                }

                nameFilterClause = String.join(clauses, ' OR ');

            } else {
                nameFilterClause = request.searchTarget + ' LIKE :targetColumnWhereClause';
            }
        } else {
            nameFilterClause = 'name LIKE :targetColumnWhereClause';
        }

        if (request.returnedFields != null){
            for(String returnedField : request.returnedFields){
                fieldsToQuery.add(returnedField);
            }
        }

        String fieldsJoined = String.join(fieldsToQuery, ', ');

        System.debug('targetColumnWhereClause => ' + targetColumnWhereClause);
        System.debug('nameFilterClause => ' + nameFilterClause);
        System.debug('query');
        System.debug(String.format('SELECT {0} FROM {1} WHERE ({2}) {3} LIMIT 900', new List<String> {
                fieldsJoined, request.tableName, nameFilterClause, queryAdditionalFilters
            }));
        
        List<SObject> queryResult = Database.query(
            String.format('SELECT {0} FROM {1} WHERE ({2}) {3} LIMIT 900', new List<String> {
                fieldsJoined, request.tableName, nameFilterClause, queryAdditionalFilters
            })
        );

        return parseRowsToResult(queryResult, request);
    }
    
    private static List<ResultData> parseRowsToResult(List<SObject> selectResult, RecordQueryRequest request){
        List<ResultData> toReturn = new List<ResultData>();

        for(SObject row : selectResult){
            toReturn.add(new ResultData(row, request));
        }

        return toReturn;
    }

    public class RequestAccountData {
        String id;
    }

    public virtual class ResultData{
        public String id;
        public String name;
        public Map<String, String> returningFields;

        protected ResultData(){}
        public ResultData(SObject row, RecordQueryRequest request){

            String name = (String) row.get('name');

            this.id = row.id;
            this.name = name;

            Map<String, String> targetFields = new Map<String, String>{ 
                'name' => name, 
                'id'   => id 
            };

            if (request.returnedFields != null){
                for(String field : request.returnedFields){
                    targetFields.put(field, String.valueOf(
                        row.get(field) 
                    ));
                }
            }

            this.returningFields = new Map<String, String>(targetFields);
        }
    }

    @RemoteAction
    public static List<CampaignResultData> searchCampaign(RecordQueryRequest request){

        List<CampaignResultData> result = new List<CampaignResultData>();

        String campaignNameFilter = '%' + request.searchTerm + '%';

        Map<String, LookupComponentRecordFilter> filterMap = new Map<String, LookupComponentRecordFilter>();

        for(LookupComponentRecordFilter filter : request.filters){
            filterMap.put(filter.fieldApiName.toLowerCase(), filter);
        }

        // System.debug(filterMap);

        String targetCurrency;
        String targetTerritoryData;
        Date dateInit;
        Date dateEnd;
        
        try {
            targetCurrency = filterMap.get('moeda__c').value;
        } catch(NullPointerException e){
            targetCurrency = DEFAULT_CURRENCY_CODE;
        } finally {
            if (targetCurrency == null){
                targetCurrency = DEFAULT_CURRENCY_CODE;
            }
        }
        
        try {
            targetTerritoryData = filterMap.get('territory__c').value;
        } catch(NullPointerException e){
            targetTerritoryData = null;
        }

        try {
            dateInit = Date.valueOf(filterMap.get('datavigenciade__c').value);
        } catch(NullPointerException e){
            dateInit = Date.today();
        } finally {
            if (dateInit == null){
                dateInit = Date.today();
            }
        }

        try {
            dateEnd = Date.valueOf(filterMap.get('datavigenciaate__c').value);
        } catch(NullPointerException e){
            dateEnd = dateInit;
        } finally {
            if (dateEnd == null){
                dateEnd = dateInit;
            }
        }

        // System.debug(dateInit);
        // System.debug(dateEnd);
        // System.debug(targetCurrency);
        // System.debug(targetTerritoryData);

        Set<Id> validCampaigns = new Set<Id>();

        if (filterMap.containsKey('conta__c') && filterMap.get('conta__c') != null){
          
            Id accountId = filterMap.get('conta__c').value;

            Account targetAccount = [
                SELECT 
                    id, 
                    regionalVendas__c
                FROM Account
                WHERE id = :accountId
            ];

            Boolean isRegionNull = true;
            Territorio__c targetTerritory;

            if (targetTerritoryData == null) {
                List<Territorio__c> territories = getTerritoryAccordingToUserRole(targetAccount.id);

                if (!territories.isEmpty()){
                    targetTerritory = territories.get(0);
                    isRegionNull = targetTerritory.regional__c == null;
                } else {
                    throw new OpportunityAppControllerException('A conta deve ter um território atribuído à ela.');
                }                
            }else {
                targetTerritory = [
                    SELECT  name, nomeTerritorio__c, id, gerente__c, gerente__r.name, 
                            diretor__c, diretor__r.name, regional__c, rtv__c, rtv__r.name,
                            diretor__r.managerId, diretor__r.manager.name , regional__r.ACS__c
                    FROM Territorio__c 
                    WHERE id =: targetTerritoryData
                ];
            }

            Map<Id, Campanha__c> possibleValidCampaignsMap = new Map<Id, Campanha__c>([
                SELECT 
                    id,
                    name,
                    descricao__c,
                    moeda__c,
                    dataInicioJuros__c,
                    (
                        SELECT id, name, condicaoPagamento__c, condicaoPagamento__r.descricao__c, condicaoPagamento__r.moeda__c, 
                        condicaoPagamento__r.tipo__c, condicaoPagamento__r.jurosComercialFinanceiro__c, condicaoPagamento__r.dias__c,
                        campanha__c
                        FROM CondicoesPagamentoCampanha__r
                        // WHERE condicaoPagamento__r.dataVigenciaDe__c <= :dateInit
                        // AND condicaoPagamento__r.dataVigenciaAte__c >= :dateEnd
                    ),
                    (
                        SELECT id, name, cultura__c, cultura__r.Descricao__c
                        FROM CulturasCampanha__r
                    ),
                    (
                        SELECT 
                            conta__c
                        FROM ClientesCampanha__r
                    ),
                    (
                        SELECT 
                            regional__c
                        FROM CampanhasRegionais__r
                    )
                FROM Campanha__c
                WHERE descricao__c LIKE :campaignNameFilter
                AND moeda__c = :targetCurrency
                AND dataVigenciaInicial__c <= :dateInit
                AND dataVigenciaFinal__c >= :dateEnd
                AND liberadoUsoOportunidades__c = true
            ]);

            // System.debug(possibleValidCampaignsMap);

            for(Campanha__c campaign : possibleValidCampaignsMap.values()){
                Boolean isValidForCustomer = campaign.clientesCampanha__r.isEmpty(), 
                        isValidForRegion   = isRegionNull || campaign.campanhasRegionais__r.isEmpty();

                
                if (!isValidForCustomer){
                    for(CampanhaCliente__c customerCampaign : campaign.ClientesCampanha__r){
                        if (customerCampaign.conta__c == accountId){
                            isValidForCustomer = true;
                            break;
                        }
                    }
                }

                if (!isValidForRegion){
                    for(CampanhaRegional__c regionCampaign : campaign.CampanhasRegionais__r){
                        if (regionCampaign.regional__c == targetTerritory.regional__c){
                            isValidForRegion = true;
                            break;
                        }
                    }
                }
                
                if (isValidForCustomer && isValidForRegion){
                    validCampaigns.add(campaign.id);
                }
            }
            
            possibleValidCampaignsMap.keySet().retainAll(validCampaigns);

            Map<Id, Map<Id, CondicaoPagamento__c>> campaignIdToPaymentConditionsToValidate = new Map<Id, Map<Id, CondicaoPagamento__c>>();
            Set<Id> paymentConditionIdsToValidate = new Set<Id>();
            Set<Id> campaignsPassBy = new Set<Id>();

            for(Campanha__c campaign : possibleValidCampaignsMap.values()){

                // System.debug('campaign.id => ' + campaign.id);
                // System.debug('campaign.descricao__c => ' + campaign.descricao__c);
                // System.debug('campaign.condicoesPagamentoCampanha__r => ' + JSON.serializePretty(campaign.condicoesPagamentoCampanha__r));

                if(campaign.condicoesPagamentoCampanha__r.isEmpty()){

                    campaignsPassBy.add(campaign.id);

                } else {

                    for(CampanhaCondicaoPagamento__c campaignPaymentCondition : campaign.condicoesPagamentoCampanha__r){

                        paymentConditionIdsToValidate.add(campaignPaymentCondition.condicaoPagamento__c);

                        if(campaignIdToPaymentConditionsToValidate.containsKey(campaignPaymentCondition.campanha__c)){
                            campaignIdToPaymentConditionsToValidate.get(campaignPaymentCondition.campanha__c).put(campaignPaymentCondition.condicaoPagamento__c, campaignPaymentCondition.condicaoPagamento__r);
                        } else {
                            campaignIdToPaymentConditionsToValidate.put(campaignPaymentCondition.campanha__c, new Map<Id, CondicaoPagamento__c>{campaignPaymentCondition.condicaoPagamento__c => campaignPaymentCondition.condicaoPagamento__r});
                        }
                    }

                }
            }

            // System.debug('paymentConditionIdsToValidate => ' + paymentConditionIdsToValidate);

            Map<Id, Map<Id, CondicaoPagamento__c>> campaignIdToValidPaymentConditions = getValidPaymentConditions(paymentConditionIdsToValidate, campaignIdToPaymentConditionsToValidate, dateInit, dateEnd);

            for(Campanha__c campaign : possibleValidCampaignsMap.values()){
                if(campaignsPassBy.contains(campaign.id)){
                    CampaignResultData campaignData = new CampaignResultData(possibleValidCampaignsMap.get(campaign.id));
                    result.add(campaignData);
                } else if(campaignIdToValidPaymentConditions.containsKey(campaign.id) && !campaignIdToValidPaymentConditions.get(campaign.id).isEmpty()){
                    CampaignResultData campaignData = new CampaignResultData(possibleValidCampaignsMap.get(campaign.id));
                    campaignData.setValidPaymentConditions(campaignIdToValidPaymentConditions.get(campaign.id).values());
                    result.add(campaignData);   
                }
            }

            // for(Id campaignId : campaignIdToValidPaymentConditions.keySet()){
            //     if(!campaignIdToValidPaymentConditions.get(campaignId).isEmpty()){
            //         CampaignResultData campaignData = new CampaignResultData(possibleValidCampaignsMap.get(campaignId));
            //         campaignData.setValidPaymentConditions(campaignIdToValidPaymentConditions.get(campaignId).values());
            //         result.add(campaignData);
            //     }
            // }

            return result;

        } else {
            throw new OpportunityAppControllerException('Não é possível procurar campanha sem especificar um cliente.');
        }
    }

    public static Map<Id, Map<Id, CondicaoPagamento__c>> getValidPaymentConditions(Set<Id> paymentConditionIdsToValidate, Map<Id, Map<Id, CondicaoPagamento__c>> campaignIdToPaymentConditionsToValidate, Date dateInit, Date dateEnd){

        // System.debug('paymentConditionIdsToValidate => ' + JSON.serialize(paymentConditionIdsToValidate));
        // System.debug('campaignIdToPaymentConditionsToValidate => ' + JSON.serialize(campaignIdToPaymentConditionsToValidate));
        // System.debug('dateInit => ' + dateInit);
        // System.debug('dateEnd => ' + dateEnd);

        Map<Id, CondicaoPagamento__c> paymentConditionsToValidate = new Map<Id, CondicaoPagamento__c>([
            SELECT id, descricao__c, moeda__c, tipo__c, jurosComercialFinanceiro__c, dias__c,
                (
                    SELECT id, jurosComercialFinanceiro__c
                    FROM Vig_ncias_Condi_o_Pagamento__r
                    WHERE dataVigenciaDe__c <= :dateInit
                    AND dataVigenciaAte__c >= :dateEnd
                    ORDER BY createdDate DESC
                )
            FROM CondicaoPagamento__c
            WHERE id IN :paymentConditionIdsToValidate
        ]);

        // System.debug('paymentConditionsToValidate => ' + JSON.serialize(paymentConditionsToValidate));

        for(Id campaingId : campaignIdToPaymentConditionsToValidate.keySet()){
            for(Id paymentConditionId : campaignIdToPaymentConditionsToValidate.get(campaingId).keySet()){
                if(paymentConditionsToValidate.get(paymentConditionId).vig_ncias_Condi_o_Pagamento__r.isEmpty()){
                    campaignIdToPaymentConditionsToValidate.get(campaingId).remove(paymentConditionId);
                } else {
                    campaignIdToPaymentConditionsToValidate.get(campaingId).put(paymentConditionId, paymentConditionsToValidate.get(paymentConditionId));
                }
            }
        }

        // System.debug('campaignIdToPaymentConditionsToValidate => ' + JSON.serializePretty(campaignIdToPaymentConditionsToValidate));

        return campaignIdToPaymentConditionsToValidate;

    }

    public class CampaignResultData extends ResultData {
        
        public PaymentConditionData[] paymentConditions;
        public CultureData[] cultures;
        public String currencyName;

        public CampaignResultData(Campanha__c campaign){
            this.paymentConditions = new List<PaymentConditionData>();
            this.cultures          = new List<CultureData>();

            this.currencyName = campaign.moeda__c;

            this.id = campaign.id;
            this.name = campaign.name;
            this.returningFields = new Map<String, String>();
            this.returningFields.put('descricao__c', campaign.descricao__c);
            this.returningFields.put('dataInicioJuros__c', String.valueOf(campaign.dataInicioJuros__c));

            // for(CampanhaCondicaoPagamento__c paymentCondition : campaign.CondicoesPagamentoCampanha__r){
            //     this.paymentConditions.add(new PaymentConditionData(paymentCondition.condicaoPagamento__r) );
            // }

            for(CampanhaCultura__c culture : campaign.CulturasCampanha__r){
                this.cultures.add(new CultureData(culture.cultura__r) );
            }
        }

        public void setValidPaymentConditions(List<CondicaoPagamento__c> validPaymentConditions){
            for(CondicaoPagamento__c paymentCondition : validPaymentConditions){
                this.paymentConditions.add(new PaymentConditionData(paymentCondition));
            }
        }
    }

    public class RecordQueryRequest{
        public String searchTerm;
        public String tableName;
        public String searchTarget;
        public String[] returnedFields;
        public LookupComponentRecordFilter[] filters;
    }

    public class LookupComponentRecordFilter{
        public String fieldApiName;
        public String operator;
        public String value;
    }

    public virtual class OpportunityDataModel{
        public String  id;
        public Double  interest;
        public Double  totalAmountInterest;
        public Double  totalAmountDolar;
        public Double  totalAmountDolarInterest;
        public String  shipmentCondition;
        public String  orderType;
        public String  salesClassification;
        public String  orderReason;
        public String  orderNumber;
        public String  receiverAccount;
        public String  shipperAccount;
        public String  selectedAccount;
        public String  selectedAccountName;
        public String  selectedCampaign;
        public String  selectedCurrency;
        public String  paymentCondition;
        public String  vendorDueDate;
        public String  obsInternal;
        public String  obsLogistic;
        public String  obsPrint;
        public String  obsPrintNF;
        public String  culture;
        public Boolean isAgencied;
        public PriceAppData priceAppData;
        public ProductDataRequest[] products;
        public TerritoryData territoryData;
        public String priceReferenceDate;
        public String selectedBusinessPlace;
        public String interestStartDate;
        public String previousSelectedCampaign;

        public OpportunityDataModel(){}        
    }

    public class OpportunityDataRequest extends OpportunityDataModel{}

    public class ExistentOpportunityData extends OpportunityDataModel{
        
        /* Opportunity Edit Fields */
        public String                           status;
        public AccountAppData                   selectedAccountData;
        public AccountAppData                   selectedReceiverData;
        public AccountAppData                   selectedShipperData;
        public CampaignResultData               selectedCampaignData;
        public List<OpportunityLineItemAppData> products;
        public String                           name;
        public DeliveryAppData                  deliveryData;
        public PriceAppData                     priceAppData;
        public TerritoryData                    territoryData;
        public BusinessPlaceData                businessPlaceData;
        public List<TerritoryData>              accountTerritories;

        public void setOpportunityData(Opportunity opportunity){
            this.id                       = opportunity.id;
            this.interest                 = opportunity.jurosComercialFinanceiro__c;
            this.totalAmountInterest      = opportunity.valorTotalMercadoriasReal__c;
            this.totalAmountDolar         = opportunity.valorTotalMercadoriasDolar__c;
            this.totalAmountDolarInterest = opportunity.valorTotalMercadoriasDolarSemIPI__c;
            this.shipmentCondition        = opportunity.condicaoExpedicao__c;
            this.orderType                = opportunity.tipoOrdem__c;
            this.salesClassification      = opportunity.classificacaoVenda__c;
            this.orderReason              = opportunity.motivoOrdem__c;
            this.orderNumber              = opportunity.numeroPedidoCliente__c;
            this.receiverAccount          = opportunity.recebedorMercadoria__c;
            this.shipperAccount           = opportunity.clienteOrigemRemanejamento__c;
            this.selectedAccount          = opportunity.accountId;
            this.selectedAccountName      = opportunity.account.name;
            this.selectedCampaign         = opportunity.campanha__c;
            this.selectedCurrency         = opportunity.moeda__c;
            this.paymentCondition         = opportunity.condicaoPagamento__c;
            this.vendorDueDate            = opportunity.vencimentoVendor__c == null? '' : String.valueOf(opportunity.vencimentoVendor__c);
            this.obsInternal              = opportunity.observacaoInterna__c;
            this.obsLogistic              = opportunity.observacaoLogistica__c;
            this.obsPrint                 = opportunity.observacaoPDF__c;
            this.obsPrintNF               = opportunity.observacaoImpressaNF__c;
            this.culture                  = opportunity.cultura__c;
            this.isAgencied               = opportunity.agenciamento__c;
            this.status                   = opportunity.stageName;
            this.priceReferenceDate       = opportunity.dataReferenciaPreco__c == null? '' : String.valueOf(opportunity.dataReferenciaPreco__c);
            this.name                     = opportunity.numeroOportunidade__c;
            this.interestStartDate        = opportunity.dataInicioJuros__c == null? '' : String.valueOf(opportunity.dataInicioJuros__c);
            this.previousSelectedCampaign = opportunity.campanha__c;
        }

        public void setSelectedAccountData(AccountAppData accountAppData){
            this.selectedAccountData = accountAppData;
        }

        public void setSelectedReceiverData(AccountAppData accountAppData){
            this.selectedReceiverData = accountAppData;
        }

        public void setSelectedShipperData(AccountAppData accountAppData){
            this.selectedShipperData = accountAppData;
        }

        public void setSelectedCampaignData(CampaignResultData campaignData){
            this.selectedCampaignData = campaignData;
        }

        public void setProductsData(List<OpportunityLineItemAppData> productsData){
            this.products = productsData;
        }

        public void setDeliveryData(DeliveryAppData deliveryData){
            this.deliveryData = deliveryData;
        }

        public void setPriceData(PriceAppData priceAppData){
            this.priceAppData = priceAppData;
        }

        public void setTerritoryData(TerritoryData territoryData){
            this.territoryData = territoryData;
        }
        
        public void setBusinessPlaceData(LocalNegocio__c businessPlaceData){
            this.businessPlaceData = new BusinessPlaceData(businessPlaceData);
        }

        public void setAccountTerritories(List<TerritoryData> accountTerritories){
            this.accountTerritories = accountTerritories;
        }
    }

    public class ExistentOpportunityDataResult extends ResultTemplate{
        
        public ExistentOpportunityData data;

        public ExistentOpportunityDataResult(ExistentOpportunityData existentOpportunityData) {
            this.data        = existentOpportunityData;
            this.hasErrors   = false;
            this.message     = 'Success';
            this.stackStrace = null;
        }

        public ExistentOpportunityDataResult(Exception error) {
            this.data        = null;
            this.hasErrors   = true;
            this.message     = error.getMessage();
            this.stackStrace = error.getStackTraceString();
        }
    }

    public virtual class ItemDataRequest{
        public String  id;
        public String  opportunityId;
        public String  itemId;   
        public String  pbEntry;
        public String  culture;
        public String  deliveryDate;
        public String  orderNumber;
        public String  receiver;
        public Decimal pricePerLiter;
        public Decimal quantity;
        public Decimal salesPrice;
        public Decimal discount;
        public Decimal total;
        public Decimal maxDiscount;
        public Decimal minimumDiscount;
        public Decimal recommendedDiscount;
        public Decimal priceList;
        public Decimal priceListDolar;
        public Decimal liter;
        public Decimal interest;
        public Boolean confirmed;
        public Decimal customerTypeDiscountValue;
        public Decimal freightValue;
        public Decimal totalValue;
        public Decimal totalValueWithInterest;
        public Decimal totalValueDolar;
        public Decimal totalValueWithInterestDolar;
        public Integer internalDeadlineDays;
        public Integer itineraryDays;
        public Decimal salesPriceWithInterest;
        public String  discountPolicyId;
        public String  priceEntryId;
        public String  shippingTableId;
        public String  customerTypeDiscountId;
        public String  confirmationDate;
        public Decimal priceFromTable;
        public String  initialDate;
        public String  finishDate;
        public Decimal ipiPercentage;
        public Decimal dollarRate;
        public Decimal multiplicity;
        public Decimal salesPriceDolar;
        public Decimal salesPriceWithInterestDolar;
        public Decimal customerTypeDiscountValueDolar;
        public Decimal freightValueDolar;
        public Decimal interestValue;
        public Decimal interestValueDolar;
        public Decimal discountValue;
        public Decimal discountValueDolar;
        public Decimal pricePerLiterDolar;
    }

    public class ProductDataRequest extends ItemDataRequest{}

    public class OpportunityLineItemAppData extends ItemDataRequest{
        public String         sku;
        public String         productName;
        public List<Id>       cultureIds;
        public CultureData    selectedCulture;
        public AccountAppData selectedReceiverData;

        public OpportunityLineItemAppData(OpportunityLineItem item){
            this.id                          = item.product2Id;
            this.itemId                      = item.id;
            this.sku                         = item.product2.sku__c;
            this.opportunityId               = item.opportunityId;
            this.pbEntry                     = item.pricebookEntryId;
            this.culture                     = item.cultura__c;
            this.deliveryDate                = item.dataEntrega__c == null? '' : String.valueOf(item.dataEntrega__c);
            this.orderNumber                 = item.numeroPedidoCliente__c;
            this.pricePerLiter               = item.precoLitro__c;
            this.quantity                    = item.quantity;
            this.salesPrice                  = item.precoVendaSemJuros__c;
            this.salesPriceWithInterest      = item.precoVendasJuros__c;
            this.salesPriceDolar             = item.precoVendaSemJurosUSD__c;
            this.salesPriceWithInterestDolar = item.precoVendasJurosUSD__c;
            this.discount                    = (item.discount != 0 ? item.discount*-1 : item.Acrescimo__c);
            this.maxDiscount                 = item.descontoMaximo__c;
            this.minimumDiscount             = item.descontoMinimo__c;
            this.recommendedDiscount         = item.descontoRecomendado__c;
            this.priceList                   = item.precoListaReferencia__c;
            this.priceListDolar              = item.precoListaReferenciaUSD__c;
            this.liter                       = item.litros__c;
            this.interest                    = item.juros__c;
            this.confirmed                   = item.confirmado__c;
            this.customerTypeDiscountValue   = item.descontoTipoCliente__c;
            this.freightValue                = item.valorFrete__c;
            this.totalValue                  = item.totalPrice;
            this.totalValueWithInterest      = item.totalItemComJuros__c;
            this.totalValueDolar             = item.totalItemSemjurosUSD__c;
            this.totalValueWithInterestDolar = item.totalItemComJurosUSD__c;
            this.internalDeadlineDays        = item.prazoInterno__c == null? 0 : Integer.valueOf(item.prazoInterno__c);
            this.itineraryDays               = item.itinerario__c == null? 0 : Integer.valueOf(item.itinerario__c);
            this.productName                 = item.product2.name;
            this.confirmationDate            = item.dataConfirmacao__c == null? '' : String.valueOf(item.dataConfirmacao__c);
            this.priceFromTable              = item.precoLista__c;
            this.initialDate                 = item.dataVigenciaInicialDesconto__c == null? '' : String.valueOf(item.dataVigenciaInicialDesconto__c);
            this.finishDate                  = item.dataVigenciaFinalDesconto__c == null? '' : String.valueOf(item.dataVigenciaFinalDesconto__c);
            this.ipiPercentage               = item.ipi__c;
            this.multiplicity                = item.product2.multiplicidade__c;
            this.discountPolicyId            = item.idPoliticaDesconto__c;
            this.priceEntryId                = item.idTabelaPreco__c;
            this.shippingTableId             = item.idTabelaFrete__c;
            this.customerTypeDiscountId      = item.idDescontoTipoCliente__c;
        }

        public void setCultures(CulturaProduto__c[] cultureRecords){
            if (cultureRecords != null){
                List<Id> cultures = Collection.of(cultureRecords).pluckIds(CulturaProduto__c.cultura__c);

                this.cultureIds = new List<Id>(cultures);
            } else {
                this.cultureIds = new List<Id>();
            }
        }

        public void setSelectedReceiverData(AccountAppData receiverAccountData){
            this.selectedReceiverData = receiverAccountData;
        }

        public void setSelectedCultureData(CultureData cultureData){
            this.selectedCulture = cultureData;
        }
    }

    public class OpportunityAppApprovalReturn extends ResultTemplate{
        public OpportunityAppApprovalData data;

        public OpportunityAppApprovalReturn(){}

        public OpportunityAppApprovalReturn(OpportunityAppApprovalData approvalData){
            this.hasErrors = false;
            this.message = 'Success';
            this.stackStrace = null;
            this.data = approvalData;
        }

        public OpportunityAppApprovalReturn(Exception e){
            this.hasErrors = true;
            this.message = e.getMessage();
            this.stackStrace = e.getStackTraceString();
            this.data = null;
        }

    }

    public class OpportunityAppApprovalData{
        public String id;
        public String name;

        public OpportunityAppApprovalData(Opportunity opportunity){
            this.id = opportunity.id;
            this.name = opportunity.numeroOportunidade__c;
        }
    }

    public class ApprovalProcessSimulationAppReturnedData extends ResultTemplate{

        public Map<Integer, ApprovalProcessSimulationAppData> data;

        public ApprovalProcessSimulationAppReturnedData(Map<Integer, ApprovalProcessSimulationAppData> data){
            this.hasErrors = false;
            this.message = 'Success';
            this.stackStrace = null;
            this.data = data;
        }

        public ApprovalProcessSimulationAppReturnedData(Exception e){
            this.hasErrors = true;
            this.message = e.getMessage();
            this.stackStrace = e.getStackTraceString();
            this.data = null;
        }

    }

    public class ApprovalProcessSimulationAppData {
        public String       approverId;
        public String       approverName;
        public List<String> helpTexts;

        public ApprovalProcessSimulationAppData(User user){
            this.approverId   = user.id;
            this.approverName = user.name;
        }

        public void setHelpTexts(List<String> helpTexts){
            this.helpTexts = helpTexts;
        }
    }

    public class BusinessPlaceData {
        String id;
        String name;

        public BusinessPlaceData(){}

        public BusinessPlaceData(LocalNegocio__c businessPlaceData) {
            this.id     = businessPlaceData.id;
            this.name   = businessPlaceData.name;
        }
    }

    public class OpportunityAppControllerException extends Exception{}
    
    public class ResponsePaymentCondition extends ResultTemplate {
        List<PaymentConditionData> paymentConditions = new List<PaymentConditionData>();

        public ResponsePaymentCondition(List<PaymentConditionData> paymentConditions){
            this.hasErrors = false;
            this.message = 'Success';
            this.stackStrace = null;
            this.paymentConditions = paymentConditions;
        }

        public ResponsePaymentCondition(Exception e){
            this.hasErrors = true;
            this.message = e.getMessage();
            this.stackStrace = e.getStackTraceString();
        }
    }
    
}