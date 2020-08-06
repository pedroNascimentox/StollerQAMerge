public class OpportunityHelper extends TriggerContext{

    // SERÁ UTILIZADO PROCESS BUILDER NO LUGAR DO MÉTODO DE CRIAR TASKS PARA RTV
    // public static void createTasksForRTVs(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap){

    //     Set<String> stageNamesToNotify = new Set<String>{'Aprovado Cliente', 'Reprovado Comercial', 'Reprovado Marketing', 'Reprovado Cliente'};

    //     Set<Id> opportunitiesToNotifyIds = new Set<Id>();

    //     for(Opportunity opportunity : newRecordsMap.values()){
    //         if(opportunity.stageName != oldRecordsMap.get(opportunity.id).stageName && stageNamesToNotify.contains(opportunity.stageName)){
    //             opportunitiesToNotifyIds.add(opportunity.id);
    //         }
    //     }

    //     List<Opportunity> opportunities = [SELECT id, name, territorio__r.rtv__c, account.name, numeroOportunidade__c FROM Opportunity WHERE id IN: opportunitiesToNotifyIds];

    //     List<Task> tasksToInsert = new List<Task>();

    //     for(Opportunity opportunity : opportunities){
            
    //         Task task = new Task(
    //             ownerId = opportunity.territorio__r.rtv__c,
    //             subject = 'Atualização de Status de Oportunidade',
    //             description = 'A oportunidade ' + opportunity.numeroOportunidade__c + ' foi ' + newRecordsMap.get(opportunity.id).stageName + '. Cliente: ' + account.name + '.',
    //             status = 'In Progress'
    //         );

    //         tasksToInsert.add(task);
        
    //     }

    //     insert tasksToInsert;
    // }

    public static void blockDelete(List<Opportunity> context){
        Set<String> profileSet = ProfileDeleteOpp__c.getAll().keySet();
        String profileName = [SELECT id, name FROM Profile  WHERE id = :UserInfo.getProfileId() LIMIT 1].Name;
        if(!profileSet.contains(profileName)){ 
            for(Opportunity opp : context){
                if(opp.StageName != 'Iniciado'){
                    opp.addError(Label.CantDeleteOpp);
                }
            }
        }
    }
    public static void changeOpportunityOwner(List<Opportunity> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(opportunity.territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        List<Opportunity> opportunitiesToUpdateOwner = new List<Opportunity>();

        for(Opportunity opportunity : newRecordsList){
            if(opportunity.territorio__c != null && territories.containsKey(opportunity.territorio__c) && opportunity.ownerId != territories.get(opportunity.territorio__c).rtv__c){
                opportunity.ownerId = territories.get(opportunity.territorio__c).rtv__c;
            }
        }
    }
    
    public static void changeOpportunityName(Map<Id, Opportunity> newRecordsMap){

        Map<Id, Opportunity> idToAfterContext = new Map<Id, Opportunity>([
            SELECT id, name, numeroOportunidade__c
            FROM Opportunity
            WHERE id IN :newRecordsMap.keySet()
        ]);
 
        for(Opportunity opportunity : idToAfterContext.values()){
            // System.debug('opportunity.numeroOportunidade__c => ' + opportunity.numeroOportunidade__c);
            // System.debug('opportunity.name => ' + opportunity.name);
                opportunity.name = opportunity.numeroOportunidade__c;
            // System.debug('opportunity.nam => ' + opportunity.name);
        }

        OpportunityHelper.disableTrigger();
            update idToAfterContext.values();
        OpportunityHelper.enableTrigger();
    }
    
    public static void createDeliveryRecords(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){

        // TriggerRecordsHandler handler = new TriggerRecordsHandler(oldRecordsMap, newRecordsMap);

        // List<Id> filteredOpportunityIds = Collection.of(
        //                                                 handler.getChangedRecordsOn('aprovadoComercial__c')
        //                                             )
        //                                             .filter(Match.field('aprovadoComercial__c').equals(true))
        //                                             .pluckIds();

        List<Id> filteredOpportunityIds = new List<Id>();
        List<Id> filteredAccIds = new List<Id>();

        for(Opportunity opportunity : newRecordsMap.values()){
            if(opportunity.aprovadoCliente__c && !oldRecordsMap.get(opportunity.id).aprovadoCliente__c && opportunity.stageName == 'Aprovado Cliente'){
                filteredOpportunityIds.add(opportunity.id);
                filteredAccIds.add(opportunity.AccountId);
            }
        }

        if(!filteredOpportunityIds.isEmpty()){

            Map<Id, Account> receiverMap = new Map<Id, Account>([SELECT id, BLoqueadoCredito__c, LimiteCreditototal__c, SaldoLimiteCreditoFormula__c FROM Account WHERE id IN :filteredAccIds]);


            List<ProgramacaoEntrega__c> deliveriesToInsert = new List<ProgramacaoEntrega__c>();

            List<OpportunityLineItem> opportunityLineItems = [
                SELECT  id, itinerarioId__c, confirmado__c, cultura__c, dataEntrega__c,  ValorJurosItemUSD__c, PrecoListaReferenciaUSD__c , PrecoVendaSemJurosUSD__c ,
                        dataFaturamento__c, dataConfirmacao__c, discount,  precoVendasJurosBRLUSD__c,
                        descontoTipoCliente__c, opportunity.diretorComercial__c, opportunity.diretorNegocios__c,
                        opportunity.accountId, opportunityId, juros__c, numeroPedidoCliente__c,
                        opportunity.saldoLimiteCredito__c, litros__c, opportunity.account.localNegocio__c,
                        opportunity.nomeRTV__c, usuarioConfirmacao__c, usuarioConfirmacao__r.name,
                        precoListaReferencia__c, precoLista__c, precoVendasJuros__c, precoVendaSemJuros__c,
                        precoLitro__c, product2Id, recebedorMercadoria__c, opportunity.GerenteRegional__c,
                        opportunity.regional__c, opportunity.territorio__c, opportunity.tipoOrdem__c,
                        opportunity.clienteOrigemRemanejamento__c, opportunity.territorio__r.Rtv__c,
                        valorFrete__c, totalPrice, unitPrice, quantity, opportunity.localNegocio__c,
                        totalItemComJuros__c, valorJurosItem__c, totalItemComJurosUSD__c, totalItemComJurosReaisDolar__c,
                        opportunity.account.name, opportunity.owner.name, opportunity.owner.email, opportunity.numeroOportunidade__c, 
                        itinerario__c, pricebookEntry.product2.name, pricebookEntry.product2.embalagem__c, precoVendasJurosUSD__c,
                        prazoInterno__c, Opportunity.Moeda__c, idTabelaPreco__r.tabelaPreco__c, taxaDolar__c,Acrescimo__c
                FROM OpportunityLineItem
                WHERE opportunityId IN :filteredOpportunityIds
            ];

            Map<Id, List<OpportunityLineItem>> oppLineItemMap = new Map<Id, List<OpportunityLineItem>>();
            for(OpportunityLineItem oppLine : opportunityLineItems){
                if(!oppLineItemMap.containsKey(oppLine.OpportunityId)){
                    oppLineItemMap.put(oppLine.OpportunityId, new List<OpportunityLineItem>());
                }
                oppLineItemMap.get(oppLine.OpportunityId).add(oppLine);                
            }

            List<OpportunityLineItem> confirmedLineItems = new List<OpportunityLineItem>();

            for(OpportunityLineItem item : opportunityLineItems){
                if(item.confirmado__c){
                    confirmedLineItems.add(item);
                }
            }

            Map<Id, OpportunityLineItem[]> itemsGrouped = Collection.of(confirmedLineItems).groupByIds(OpportunityLineItem.opportunityId);
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            List<ApprovedItemDatePair> itemsWithChangedDate = new List<ApprovedItemDatePair>();

            Set<Id> oppCreditIdSet = new Set<Id>();
            List<Opportunity> oppEmailRTV = new List<Opportunity>();
            
            Map<Id, territorio__c> territoryMap  = new Map<Id, territorio__c>([SELECT id, RTV__C FROM Territorio__c WHERE id IN : Collection.of(newRecordsMap.values()).pluckIds(Opportunity.Territorio__c)]);

            for(Id opportunityId : filteredOpportunityIds){

                Map<Id, OpportunityLineItem> recordsWithChangedDate = new Map<Id, OpportunityLineItem>();

                OpportunityLineItem[] oppItems = itemsGrouped.get(opportunityId);

                if(!confirmedLineItems.isEmpty()){

                    Opportunity o = confirmedLineItems.get(0).opportunity;

                    String emailHtmlBody = (
                        '<html>                                                                                                                                              \n' +
                        '    <body>                                                                                                                                          \n' +
                        '    <style>                                                                                                                                         \n' +
                        '        .items-table.col-1{                                                                                                                         \n' +
                        '            width: 15%;                                                                                                                             \n' +
                        '        }                                                                                                                                           \n' +
                        '                                                                                                                                                    \n' +
                        '        .items-table.col-5, .items-table.col-6, .items-table.col-7, .items-table.col-8{                                                             \n' +
                        '            width: 12.5%;                                                                                                                           \n' +
                        '        }                                                                                                                                           \n' +
                        '                                                                                                                                                    \n' +
                        '        .items-table th, .items-table td {                                                                                                          \n' +
                        '            text-align: center; padding: 0 10px;                                                                                                                        \n' +
                        '        }                                                                                                                                           \n' +
                        '    </style>                                                                                                                                        \n' +
                        '        <div>                                                                                                                                       \n' +
                        '            <p>Prezado {{rtvName}}</p>                                                                                                              \n' +
                        '                                                                                                                                                    \n' +
                        '            <p>Informamos que a data de entrega indicada no(s) produto(s) abaixo foram atualizadas, visto que a data original não está vigente.</p> \n' +
                        '        </div>                                                                                                                                      \n' +
                        '                                                                                                                                                    \n' +
                        '        <div>                                                                                                                                       \n' +
                        '            <table style="border-spacing: 0px; border-collapse: collapse" class="items-table">                                                                                                             \n' +
                        '                <thead>                                                                                                                             \n' +
                        '                    <tr>                                                                                                                            \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px;" >Nº. Da Oportunidade</th>                                                                                  \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px;" >Produto</th>                                                                                              \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px;" >Embal.</th>                                                                                               \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px;" >Qtd.</th>                                                                                                 \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;" >Data de entrega Original</th>                                                                             \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;" >Dt. de faturamento Original</th>                                                                          \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;" >Data de entrega atualizada</th>                                                                           \n' +
                        '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;" >Data de faturamento atualizada</th>                                                                       \n' +
                        '                    </tr>                                                                                                                           \n' +
                        '                </thead>                                                                                                                            \n' +
                        '                                                                                                                                                    \n' +
                        '                <tbody>                                                                                                                             \n' +
                        '                    {{tableContent}}                                                                                                                \n' +
                        '                </tbody>                                                                                                                            \n' +
                        '            </table>                                                                                                                                \n' +
                        '        </div>                                                                                                                                      \n' +
                        '    </body>                                                                                                                                         \n' +
                        '</html>                                                                                                                                             \n'
                    );  

                    String tableContent = ''; 
                    
                    List<ApprovedItemDatePair> dateResult = calcItemUpdatedDates(confirmedLineItems);

                    for(ApprovedItemDatePair datePair : dateResult){
                        if (datePair.hasValueChanges){
                            tableContent += getInvalidApprovedItemHtmlRow(datePair);

                            itemsWithChangedDate.add(datePair);
                        }
                    }

                    if (!itemsWithChangedDate.isEmpty()){
                    
                        emailHtmlBody = emailHtmlBody.replace('{{rtvName}}', o.owner.name)
                                                    .replace('{{tableContent}}', tableContent);

                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        
                        mail.setHtmlBody(emailHtmlBody);
                        mail.setToAddresses(new String[]{
                            o.owner.email
                        });
                        mail.setSubject(String.format(
                            'Atualização da data de entrega - {0} - {1}',
                            new List<String>{
                                String.valueOf(o.numeroOportunidade__c),
                                o.account.name
                            }
                        ));

                        mailList.add(mail);
                    }

                    if (!mailList.isEmpty()){
                        Messaging.sendEmail(mailList);
                    }

                    for(ApprovedItemDatePair datePair : itemsWithChangedDate){
                        recordsWithChangedDate.put(datePair.itemId, datePair.updateItem());
                    }
                }

                Decimal TotalItems = 0;
                Boolean hasConfirmedItems = false;
                if(oppItems != null){
                    for(OpportunityLineItem item : oppItems){
                        if(item.Confirmado__c){
                            TotalItems += item.totalItemComJuros__c;
                            hasConfirmedItems = true;
                        }
                    }
                }
                Opportunity opp = newRecordsMap.get(opportunityId);
                Account receiver = receiverMap.get(opp.AccountId);

                Boolean blockCredit = opp.tipoOrdem__c == 'Bonificação' ? false : (receiver.SaldoLimiteCreditoFormula__c < TotalItems && hasConfirmedItems);

                if(blockCredit && !receiver.BLoqueadoCredito__c){
                    oppCreditIdSet.add(opp.id);
                }else if(blockCredit && receiver.BLoqueadoCredito__c){
                    oppEmailRTV.add(opp);
                    opp.BloqueadoCredito__c = true;
                }
                if(oppLineItemMap.containsKey(opportunityId)){
                for(OpportunityLineItem item : oppLineItemMap.get(opportunityId)){
                
                    ProgramacaoEntrega__c delivery = new ProgramacaoEntrega__c(
                        confirmado__c = (blockCredit && !receiver.BLoqueadoCredito__c ? false : item.confirmado__c),
                        cultura__c    = item.cultura__c, 
                        dataEntrega__c = item.dataEntrega__c, 
                        dataFaturamento__c = item.dataFaturamento__c, 
                        dataConfirmacao__c = item.dataConfirmacao__c,
                        descontoConcedido__c = (item.discount != 0 ? item.discount*-1 : item.Acrescimo__c),
                        descontoTipoCliente__c = item.descontoTipoCliente__c,
                        diretorComercial__c = item.opportunity.diretorComercial__c,
                        diretorNegocios__c = item.opportunity.diretorNegocios__c,
                        gerenteRegional__c = item.opportunity.GerenteRegional__c,
                        emissorOrdem__c = item.opportunity.accountId,
                        clienteOrigemRemanejamento__c = item.opportunity.clienteOrigemRemanejamento__c,
                        idOportunidade__c = item.opportunityId,
                        idOpportunityLineItem__c = item.id,
                        juros__c = (item.Opportunity.Moeda__c == 'USD' ? item.ValorJurosItemUSD__c : item.valorJurosItem__c),
                        litros__c = item.litros__c, 
                        localNegocio__c = item.opportunity.localNegocio__c != null? item.opportunity.localNegocio__c : item.opportunity.account.localNegocio__c,
                        nomeRTV__c = item.opportunity.nomeRTV__c,
                        nomeUsuarioConfirmacao__c = item.usuarioConfirmacao__r.name,
                        numeroPedidoCliente__c = item.numeroPedidoCliente__c,
                        prazoInterno__c = item.prazoInterno__c,
                        prazoItinerario__c = item.itinerario__c,
                        itinerario__c = item.itinerarioId__c,
                        precoListaReferencia__c = (item.Opportunity.Moeda__c == 'USD' ? item.precoListaReferenciaUSD__c :  item.precoListaReferencia__c),
                        precoLista__c = item.precoLista__c,
                        precoVenda__c = (item.Opportunity.Moeda__c == 'USD' ? item.precoVendaSemJurosUSD__c : item.precoVendaSemJuros__c),
                        precoVendaJuros__c = item.precoVendasJuros__c,
                        precoVendasJurosUSD__c = item.precoVendasJurosUSD__c,
                        taxaDolar__c = item.taxaDolar__c,
                        precoLitro__c = item.precoLitro__c, 
                        produto__c = item.product2Id, 
                        quantidadeProgramada__c = item.quantity,
                        recebedorOrdem__c = item.recebedorMercadoria__c,
                        regional__c = item.opportunity.regional__c, 
                        saldoLimiteCredito__c = item.opportunity.saldoLimiteCredito__c,
                        territorio__c = item.opportunity.territorio__c, 
                        tipoOrdem__c = item.opportunity.tipoOrdem__c,
                        valorFrete__c = item.valorFrete__c, 
                        valorTotal__c = item.totalItemComJuros__c, 
                        valorUnitario__c = item.precoVendasJurosBRLUSD__c,
                        statusSAP__c = 'Não Confirmado',
                        valorTotalUSD__c = item.totalItemComJurosUSD__c,
                        //valorTotalReaisDolar__c = item.totalItemComJurosReaisDolar__c,
                        RTV__c = (territoryMap.containsKey(item.opportunity.territorio__c) ? territoryMap.get(item.opportunity.territorio__c).rtv__c : null),
                        tabelaPreco__c = item.idTabelaPreco__r.tabelaPreco__c
                    );

                    if(item.confirmado__c){
                        if(!receiver.BLoqueadoCredito__c){
                            if(blockCredit){
                                delivery.Status__C =  'Em aprovação de crédito';
                            }else{
                                delivery.Status__C = 'Integrado';
                            }
                        }else{
                            delivery.Status__C = 'Liberado';
                        }
                    }else{
                        delivery.Status__C = 'Liberado';
                    }

                    if(recordsWithChangedDate.containsKey(item.id)){
                        delivery.dataEntrega__c = recordsWithChangedDate.get(item.id).dataEntrega__c;
                        delivery.dataFaturamento__c = recordsWithChangedDate.get(item.id).dataFaturamento__c;
                    }

                    deliveriesToInsert.add(delivery);
                }
                }   
            }

            insert deliveriesToInsert;

            Map<Id, Set<String>> programacaoNumberMap = new Map<Id, Set<String>>();
            for(ProgramacaoEntrega__c delivery : [SELECT id, idOportunidade__c, Name FROM ProgramacaoEntrega__c WHERE idOportunidade__c IN :oppCreditIdSet AND Status__C =  'Em aprovação de crédito' ]){
                if(!programacaoNumberMap.containsKey(delivery.idOportunidade__c)){
                    programacaoNumberMap.put(delivery.idOportunidade__c, new Set<String>());
                }
                programacaoNumberMap.get(delivery.idOportunidade__c).add(delivery.Name);
            }
            if(!oppCreditIdSet.isEmpty())
                sendApproveCredit(oppCreditIdSet, programacaoNumberMap);
        
        }
    }

    public static void seeCreditApprovalResult(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){
        Set<Id> oppIntegratedSet  = new Set<Id>();
        Set<Id> oppLiberadoSet  = new Set<Id>();
        for(Opportunity opp : newRecordsMap.values()){
            Opportunity oppOld = oldRecordsMap.get(opp.Id);
            if(oppOld.StatusCredito__C != opp.StatusCredito__C ){
                if(opp.StatusCredito__C == 'Aprovado'){
                    oppIntegratedSet.add(opp.Id);
                }else if(opp.StatusCredito__C == 'Reprovado'){
                    oppLiberadoSet.add(opp.Id);
                }
            }
        }
        List<ProgramacaoEntrega__c> deliveryToUpdate = new List<ProgramacaoEntrega__c>();
        List<OpportunityLineItem> oppLineItemsToUpdate = new List<OpportunityLineItem>();

        Map<Id, OpportunityLineItem> oppLineItemsLiberados = new Map<Id, OpportunityLineItem> ([SELECT id, Confirmado__c, OpportunityId
                                                                                                FROM OpportunityLineItem
                                                                                                WHERE OpportunityId IN: oppLiberadoSet]);

        for(ProgramacaoEntrega__c delivery : [SELECT id, idOportunidade__c, IdOpportunityLineItem__c 
                                              FROM ProgramacaoEntrega__c 
                                              WHERE Status__C =  'Em aprovação de crédito'
                                              AND (idOportunidade__c IN : oppIntegratedSet OR idOportunidade__c IN : oppLiberadoSet)]){
            if(oppIntegratedSet.contains(delivery.idOportunidade__c)){
                delivery.Status__c = 'Integrado';
                delivery.Confirmado__c = true;
            }else if(oppLiberadoSet.contains(delivery.idOportunidade__c)){
                delivery.Status__c = 'Liberado';
                delivery.Confirmado__c = false;

                OpportunityLineItem oldOppLineItem = oppLineItemsLiberados.get(Id.valueOf(delivery.IdOpportunityLineItem__c));

                if (oldOppLineItem != null) {
                    oldOppLineItem.Confirmado__c = false;
                    oppLineItemsToUpdate.add(oldOppLineItem);
                } 
            }
            deliveryToUpdate.add(delivery);
        }
        if(!deliveryToUpdate.isEmpty()){
            update deliveryToUpdate;
        }
        if(!oppLineItemsToUpdate.isEmpty()){
            update oppLineItemsToUpdate;
        }
    }


    public static void sendApproveCredit(Set<Id> opps, Map<Id, Set<String>> programacaoNumberMap ){
        Approval.ProcessSubmitRequest[] approvalProcessCredit = new List<Approval.ProcessSubmitRequest>();
        for(Opportunity opp : [SELECT id, StatusCredito__c, StatusAprovacoes__c  FROM Opportunity WHERE id IN :opps]){
            if(!Approval.isLocked(opp) || opp.StatusCredito__c != 'Em aprovação' || opp.StatusAprovacoes__c == 'Aprovado - Cliente' ||  opp.StatusAprovacoes__c == 'Aguardando Aprovação - Cliente'){
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setComments(String.join(new List<String>(programacaoNumberMap.get(opp.Id)), '\n '));
                request.setObjectId(opp.Id);
                request.setSkipEntryCriteria(true);
                request.setSubmitterId(UserInfo.getUserId()); 
                request.setProcessDefinitionNameOrId('SolicitacaoCredito');
                approvalProcessCredit.add(request);
            }
        }
        System.debug(approvalProcessCredit);
        if(!approvalProcessCredit.isEmpty()){
            Approval.process(approvalProcessCredit);
        }
    }

    public static List<ApprovedItemDatePair> calcItemUpdatedDates(OpportunityLineItem[] items){
        List<ApprovedItemDatePair> result = new List<ApprovedItemDatePair>();

        for(OpportunityLineItem item : items){
            ApprovedItemDatePair pair = new ApprovedItemDatePair(item);

            result.add(pair);
        }

        return result;
    }

    private static String getInvalidApprovedItemHtmlRow(ApprovedItemDatePair pair){
        return String.format(
            '<tr>             ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px;">{0}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px;">{1}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px;">{2}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px;">{3}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;">{4}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;">{5}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;">{6}</td> ' +
            '    <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 12.5%;">{7}</td> ' +
            '</tr>            ', 
            
            new List<String>{
               
                String.valueOf(pair.item.opportunity.NumeroOportunidade__c),
                pair.item.pricebookEntry.product2.name,
                pair.item.pricebookEntry.product2.embalagem__c,
                String.valueOf(pair.item.quantity),
                
                pair.previousDeliveryDate.format(),
                pair.previousBillingDate.format(),
                pair.updatedDeliveryDate.format(),
                pair.updatedBillingDate.format()
            }
        );
    }
    
    public static void removeCampaignFieldsIfNeeded(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){
        TriggerRecordsHandler oppRecordsHandler = new TriggerRecordsHandler(oldRecordsMap, newRecordsMap);
        Opportunity[] oppChangedRecords =   Collection.of(
                                                oppRecordsHandler.getChangedRecordsOn('campanha__c')
                                            ).filter(
                                                Match.field('campanha__c').equals(null)
                                            ).asList();

        for(Opportunity opp : oppChangedRecords){
            opp.dataInicioJuros__c = null;
            opp.dataVencimento__c = null;
        }
    }

    
    public static void fillDadosAprovacao(List<Id> opportunityIds) {

        Map<Id, Opportunity> newRecordMap = new Map<Id, Opportunity>([SELECT Id, StatusAprovacoes__c FROM Opportunity WHERE Id IN :opportunityIds]);

        Map<Id, ProcessInstance> opportunityIdToProcessInstanceMap = new Map<Id, ProcessInstance>();
        Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance> ([SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId IN :newRecordMap.keySet()]);
        for (ProcessInstance pi : processInstanceMap.values()) {
            opportunityIdToProcessInstanceMap.put(pi.TargetObjectId, pi);
        }
            // System.debug('opportunityIdToProcessInstanceMap => ' + opportunityIdToProcessInstanceMap);
        
        Map<Id, List<ProcessInstanceWorkitem>> opportunityIdToProcessInstanceWorkitemMap = new Map<Id, List<ProcessInstanceWorkitem>>();
        
        List<ProcessInstanceWorkitem> processInstanceWorkitemList = [
            SELECT  Id, CreatedDate, ProcessInstance.createdDate, 
                    ProcessInstance.TargetObjectId, ActorId, OriginalActorId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstanceId IN :processInstanceMap.keySet()
        ];

        System.debug('All opportunity process instance workitem => ' + JSON.serializePretty([SELECT  Id, CreatedDate, ProcessInstance.createdDate, 
                    ProcessInstance.TargetObjectId, ActorId, Actor.name, OriginalActorId, OriginalActor.name
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId IN :opportunityIds
        ]));
        
        System.debug('All opportunity process instance step => ' + JSON.serializePretty([SELECT  Id, CreatedDate, ProcessInstance.createdDate, 
                    ProcessInstance.TargetObjectId, ActorId, Actor.name, OriginalActorId, OriginalActor.name, Comments
            FROM ProcessInstanceStep 
            WHERE ProcessInstance.TargetObjectId IN :opportunityIds
        ]));

        for (ProcessInstanceWorkitem piw : processInstanceWorkitemList) {
            if (opportunityIdToProcessInstanceWorkitemMap.containsKey(piw.ProcessInstance.TargetObjectId)) {
                opportunityIdToProcessInstanceWorkitemMap.get(piw.ProcessInstance.TargetObjectId).add(piw);
            } else {
                opportunityIdToProcessInstanceWorkitemMap.put(piw.ProcessInstance.TargetObjectId, new List<ProcessInstanceWorkitem>{piw});
            }
        }
            // System.debug('opportunityIdToProcessInstanceWorkitemMap => ' + opportunityIdToProcessInstanceWorkitemMap);

        List<DadosAprovacao__c> approvalDataList = [
            SELECT id, oportunidade__c, idInstanceWorkItem__c, idInstanceStep__c, AprovadorDelegado__r.name, AprovadorReal__r.name, NomeEtapa__c, Comentarios__c
            FROM DadosAprovacao__c
            WHERE oportunidade__c IN :newRecordMap.keySet()
        ];

        System.debug('approvalDataList => ' + JSON.serializePretty(approvalDataList));

        List<String> instanceStepIdsAlreadyProcessedList = Collection.of(approvalDataList).filter(Match.field('idInstanceStep__c').notEquals(null)).pluckStrings(DadosAprovacao__c.idInstanceStep__c);

        System.debug('instanceStepIdsAlreadyProcessedList => ' + instanceStepIdsAlreadyProcessedList);

        Map<Id, List<DadosAprovacao__c>> opportunityIdsToApprovalDataList = Collection.of(approvalDataList).filter(Match.field('idInstanceStep__c').equals(null)).groupByIds(DadosAprovacao__c.Oportunidade__c);

        System.debug('opportunityIdsToApprovalDataList => ' + opportunityIdsToApprovalDataList);

        System.debug('All ProcessInstanceSteps => ' + JSON.serializePretty([SELECT  Id, CreatedDate, ProcessInstance.createdDate, 
                                ProcessInstance.TargetObjectId, ActorId, OriginalActorId, 
                                toLabel(StepStatus), Comments, StepNodeId 
                        FROM ProcessInstanceStep 
                        WHERE ProcessInstanceId IN :processInstanceMap.keySet()]));
        
        List<ProcessInstanceStep> processInstanceStepList = [
            SELECT  Id, CreatedDate, ProcessInstance.createdDate, 
                    ProcessInstance.TargetObjectId, ActorId, OriginalActorId, 
                    toLabel(StepStatus), Comments, StepNodeId 
            FROM ProcessInstanceStep 
            WHERE ProcessInstanceId IN :processInstanceMap.keySet()
            ORDER BY createdDate DESC
            LIMIT 1
            // AND id NOT IN: instanceStepIdsAlreadyProcessedList
        ];
        
        Map<Id, ProcessInstanceStep> opportunityIdToProcessInstanceStep = new Map<Id, ProcessInstanceStep>();
        
        for (ProcessInstanceStep processInstanceStep : processInstanceStepList) {

            opportunityIdToProcessInstanceStep.put(processInstanceStep.processInstance.targetObjectId, processInstanceStep);

            // if (opportunityIdToProcessInstanceStepMap.containsKey(piw.ProcessInstance.TargetObjectId)) {
            //     opportunityIdToProcessInstanceStepMap.get(piw.ProcessInstance.TargetObjectId).add(piw);
            // } else {
            //     opportunityIdToProcessInstanceStepMap.put(piw.ProcessInstance.TargetObjectId, new List<ProcessInstanceStep>{piw});
            // }
        }
            // System.debug('opportunityIdToProcessInstanceStepMap => ' + opportunityIdToProcessInstanceStepMap);

        // Map<String, DadosAprovacao__c> mapToSort = new Map<String, DadosAprovacao__c>();

        System.debug('opportunityIdToProcessInstanceWorkitemMap => ' + JSON.serializePretty(opportunityIdToProcessInstanceWorkitemMap));

        if (opportunityIdToProcessInstanceWorkitemMap.size() != 0 || !opportunityIdToProcessInstanceStep.isEmpty()) {
            // delete [SELECT Id FROM DadosAprovacao__c WHERE Oportunidade__c IN :newRecordMap.keySet()];

            List<DadosAprovacao__c> dadosAprovacaoListToInsert = new List<DadosAprovacao__c>();
            for (Id key : opportunityIdToProcessInstanceWorkitemMap.keySet()) {
                System.debug('key => ' + key);
                System.debug('opportunityIdToProcessInstanceWorkitemMap.get(key) => ' + opportunityIdToProcessInstanceWorkitemMap.get(key));
                for (ProcessInstanceWorkitem piw : opportunityIdToProcessInstanceWorkitemMap.get(key)) {
                    DadosAprovacao__c dadosAprovacao = new DadosAprovacao__c(
                        AprovadorDelegado__c           = piw.ActorId,
                        AprovadorReal__c               = piw.OriginalActorId,
                        NomeEtapa__c                   = newRecordMap.get(key).StatusAprovacoes__c,
                        Oportunidade__c                = key,
                        StatusAprovacao__c             = 'Pendente',
                        DataInicioProcessoAprovacao__c = piw.processInstance.createdDate,
                        idInstanceWorkItem__c          = piw.id
                    );
                    // mapToSort.put(String.valueOf(piw.CreatedDate), dadosAprovacao);
                    dadosAprovacaoListToInsert.add(dadosAprovacao);
                    // System.debug('dadosAprovacaoWorkitem => ' + dadosAprovacao);
                }
            }

            List<DadosAprovacao__c> approvalDataListToUpdate = new List<DadosAprovacao__c>();

            System.debug('dadosAprovacaoListToInsert => ' + JSON.serializePretty(dadosAprovacaoListToInsert));

            System.debug('!opportunityIdsToApprovalDataList.isEmpty() => ' + !opportunityIdsToApprovalDataList.isEmpty());

            if(!opportunityIdsToApprovalDataList.isEmpty()){

                for (Id key : opportunityIdToProcessInstanceStep.keySet()) {
                    
                    if(opportunityIdsToApprovalDataList.containsKey(key)){

                        System.debug('opportunityIdToProcessInstanceStep.get(key) => ' + opportunityIdToProcessInstanceStep.get(key));

                        ProcessInstanceStep pis = opportunityIdToProcessInstanceStep.get(key);
                        DadosAprovacao__c approvalDataToUpdate = opportunityIdsToApprovalDataList.get(key)[0];

                        System.debug('approvalDataToUpdate => ' + approvalDataToUpdate);
                        System.debug('approvalDataToUpdate.AprovadorDelegado__r.name => ' + approvalDataToUpdate.AprovadorDelegado__r.name);
                        System.debug('approvalDataToUpdate.AprovadorReal__r.name => ' + approvalDataToUpdate.AprovadorReal__r.name);
                        System.debug('approvalDataToUpdate.NomeEtapa__c => ' + approvalDataToUpdate.NomeEtapa__c);
                        System.debug('approvalDataToUpdate.Comentarios__c => ' + approvalDataToUpdate.Comentarios__c);

                        approvalDataToUpdate.AprovadorDelegado__c           = pis.ActorId;
                        approvalDataToUpdate.AprovadorReal__c               = pis.OriginalActorId;
                        approvalDataToUpdate.Comentarios__c                 = pis.Comments;
                        approvalDataToUpdate.NomeEtapa__c                   = newRecordMap.get(key).StatusAprovacoes__c;
                        // approvalDataToUpdate.Oportunidade__c                = key;
                        approvalDataToUpdate.StatusAprovacao__c             = pis.StepStatus;
                        approvalDataToUpdate.DataAtualizacaoStatus__c       = pis.createdDate;
                        approvalDataToUpdate.DataInicioProcessoAprovacao__c = pis.processInstance.createdDate;
                        approvalDataToUpdate.idInstanceStep__c              = pis.id;

                        approvalDataListToUpdate.add(approvalDataToUpdate);

                        // mapToSort.put(String.valueOf(pis.CreatedDate), dadosAprovacao);
                        // dadosAprovacaoListToInsert.add(dadosAprovacao);
                        // System.debug('dadosAprovacaoStep => ' + dadosAprovacao);
                    
                    }
                }
            }

            // List<DadosAprovacao__c> orderedList = new List<DadosAprovacao__c>();

            // List<String> auxList = new List<String>(mapToSort.keySet());
            // auxList.sort();
            // for (String oDate : auxList) {
            //     orderedList.add(mapToSort.get(oDate));
            // }
            OpportunityHelper.disableTrigger();
            // insert orderedList;
            if(!dadosAprovacaoListToInsert.isEmpty()){
                System.debug('dadosAprovacaoListToInsert => ' + JSON.serializePretty(dadosAprovacaoListToInsert));
                insert dadosAprovacaoListToInsert;
            }
            if(!opportunityIdsToApprovalDataList.isEmpty()){
                System.debug('opportunityIdsToApprovalDataList => ' + JSON.serializePretty(opportunityIdsToApprovalDataList));
                System.debug('approvalDataListToUpdate => ' + JSON.serializePretty(approvalDataListToUpdate));
                update approvalDataListToUpdate;
            }
            OpportunityHelper.enableTrigger();

            Map<Id, DadosAprovacao__c> instanceWorkItemIdToinsertedApprovalData = new Map<Id, DadosAprovacao__c>();

            for(DadosAprovacao__c approvalData : dadosAprovacaoListToInsert){
                instanceWorkItemIdToinsertedApprovalData.put(approvalData.idInstanceWorkItem__c, approvalData);
            }

            Map<Id, List<OpportunityLineItem>> opportunityIdToOpportunityLineItemsList = Collection.of([
                SELECT id, opportunityId, product2Id, quantity, discount, unitPrice, valorTotal__c
                FROM OpportunityLineItem
                WHERE opportunityId IN :newRecordMap.keySet() 
            ]).groupByIds(OpportunityLineItem.OpportunityId);

            List<DadosAprovacaoItem__c> itemApprovalDataListToInsert = new List<DadosAprovacaoItem__c>();

            for (Id key : opportunityIdToProcessInstanceWorkitemMap.keySet()) {
                for (ProcessInstanceWorkitem piw : opportunityIdToProcessInstanceWorkitemMap.get(key)) {
                    
                    DadosAprovacao__c approvalData = instanceWorkItemIdToinsertedApprovalData.get(piw.id);

                    for(OpportunityLineItem opportunityLineItem : opportunityIdToOpportunityLineItemsList.get(approvalData.oportunidade__c)){
                        
                        DadosAprovacaoItem__c itemApprovalData = new DadosAprovacaoItem__c(
                            DadosAprovacao__c = approvalData.id,
                            Produto__c = opportunityLineItem.product2Id,
                            Quantidade__c = opportunityLineItem.quantity,
                            DescontoConcedido__c = opportunityLineItem.discount, 
                            ValorUnitario__c = opportunityLineItem.unitPrice,
                            ValorTotal__c = opportunityLineItem.valorTotal__c
                            // ProdutoDaOportunidade__c = opportunityLineItem.id
                        );

                        itemApprovalDataListToInsert.add(itemApprovalData);
                    }
                }
            }

            if(!itemApprovalDataListToInsert.isEmpty()){
                insert itemApprovalDataListToInsert;
            }

        }
    }
    
    /*
    public static void fillDadosAprovacao(List<Id> opportunityIds) {

        Map<Id, Opportunity> newRecordMap = new Map<Id, Opportunity>([SELECT Id, StatusAprovacoes__c FROM Opportunity WHERE Id IN :opportunityIds]);

        Map<Id, ProcessInstance> opportunityIdToProcessInstanceMap = new Map<Id, ProcessInstance>();
        Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance> ([SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId IN :newRecordMap.keySet()]);
        for (ProcessInstance pi : processInstanceMap.values()) {
            opportunityIdToProcessInstanceMap.put(pi.TargetObjectId, pi);
        }
            // System.debug('opportunityIdToProcessInstanceMap => ' + opportunityIdToProcessInstanceMap);
        
        Map<Id, List<ProcessInstanceWorkitem>> opportunityIdToProcessInstanceWorkitemMap = new Map<Id, List<ProcessInstanceWorkitem>>();
        List<ProcessInstanceWorkitem> processInstanceWorkitemList = [SELECT Id, CreatedDate, ProcessInstance.createdDate, ProcessInstance.TargetObjectId, ActorId, OriginalActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :processInstanceMap.keySet()];
        for (ProcessInstanceWorkitem piw : processInstanceWorkitemList) {
            if (opportunityIdToProcessInstanceWorkitemMap.containsKey(piw.ProcessInstance.TargetObjectId)) {
                opportunityIdToProcessInstanceWorkitemMap.get(piw.ProcessInstance.TargetObjectId).add(piw);
            } else {
                opportunityIdToProcessInstanceWorkitemMap.put(piw.ProcessInstance.TargetObjectId, new List<ProcessInstanceWorkitem>{piw});
            }
        }
            // System.debug('opportunityIdToProcessInstanceWorkitemMap => ' + opportunityIdToProcessInstanceWorkitemMap);

        Map<Id, List<ProcessInstanceStep>> opportunityIdToProcessInstanceStepMap = new Map<Id, List<ProcessInstanceStep>>();
        List<ProcessInstanceStep> processInstanceStepList = [SELECT Id, CreatedDate, ProcessInstance.createdDate, ProcessInstance.TargetObjectId, ActorId, OriginalActorId, StepStatus, Comments, StepNodeId FROM ProcessInstanceStep WHERE ProcessInstanceId IN :processInstanceMap.keySet()];
        for (ProcessInstanceStep piw : processInstanceStepList) {
            if (opportunityIdToProcessInstanceStepMap.containsKey(piw.ProcessInstance.TargetObjectId)) {
                opportunityIdToProcessInstanceStepMap.get(piw.ProcessInstance.TargetObjectId).add(piw);
            } else {
                opportunityIdToProcessInstanceStepMap.put(piw.ProcessInstance.TargetObjectId, new List<ProcessInstanceStep>{piw});
            }
        }
            // System.debug('opportunityIdToProcessInstanceStepMap => ' + opportunityIdToProcessInstanceStepMap);

        Map<String, DadosAprovacao__c> mapToSort = new Map<String, DadosAprovacao__c>();

        if (opportunityIdToProcessInstanceWorkitemMap.size() != 0 || opportunityIdToProcessInstanceStepMap.size() != 0) {
            delete [SELECT Id FROM DadosAprovacao__c WHERE Oportunidade__c IN :newRecordMap.keySet()];

            List<DadosAprovacao__c> dadosAprovacaoList = new List<DadosAprovacao__c>();
            for (Id key : opportunityIdToProcessInstanceWorkitemMap.keySet()) {
                for (ProcessInstanceWorkitem piw : opportunityIdToProcessInstanceWorkitemMap.get(key)) {
                    DadosAprovacao__c dadosAprovacao = new DadosAprovacao__c(
                        AprovadorDelegado__c           = piw.ActorId,
                        AprovadorReal__c               = piw.OriginalActorId,
                        NomeEtapa__c                   = newRecordMap.get(key).StatusAprovacoes__c,
                        Oportunidade__c                = key,
                        StatusAprovacao__c             = 'Pending',
                        DataInicioProcessoAprovacao__c = piw.processInstance.createdDate
                    );
                    // mapToSort.put(String.valueOf(piw.CreatedDate), dadosAprovacao);
                    dadosAprovacaoList.add(dadosAprovacao);
                    // System.debug('dadosAprovacaoWorkitem => ' + dadosAprovacao);
                }
            }
            for (Id key : opportunityIdToProcessInstanceStepMap.keySet()) {
                for (ProcessInstanceStep pis : opportunityIdToProcessInstanceStepMap.get(key)) {
                    DadosAprovacao__c dadosAprovacao = new DadosAprovacao__c(
                        AprovadorDelegado__c           = pis.ActorId,
                        AprovadorReal__c               = pis.OriginalActorId,
                        Comentarios__c                 = pis.Comments,
                        NomeEtapa__c                   = newRecordMap.get(key).StatusAprovacoes__c,
                        Oportunidade__c                = key,
                        StatusAprovacao__c             = pis.StepStatus,
                        DataAtualizacaoStatus__c       = pis.createdDate,
                        DataInicioProcessoAprovacao__c = pis.processInstance.createdDate
                    );
                    mapToSort.put(String.valueOf(pis.CreatedDate), dadosAprovacao);
                    // dadosAprovacaoList.add(dadosAprovacao);
                    // System.debug('dadosAprovacaoStep => ' + dadosAprovacao);
                }
            }

            List<DadosAprovacao__c> orderedList = new List<DadosAprovacao__c>();

            List<String> auxList = new List<String>(mapToSort.keySet());
            auxList.sort();
            for (String oDate : auxList) {
                orderedList.add(mapToSort.get(oDate));
            }
            OpportunityHelper.disableTrigger();
            insert orderedList;
            insert dadosAprovacaoList;
            OpportunityHelper.enableTrigger();
        }
    }*/

    public static void case31720(List<Opportunity> opportunity){
        for (Opportunity opt : opportunity){
            if (opt.stageName != 'Aprovado Cliente') {
                List<ProgramacaoEntrega__c> accDeliveries = [SELECT Id FROM ProgramacaoEntrega__c WHERE IdOportunidade__c = :opt.Id];
                if (accDeliveries.size() > 0){
                    opt.addError('Oportunidade tem Programações de Entrega');
                }
            }
        }
    }

    public static void stageNameChanged(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){
        Set<String> profileSet = ProfileChangeStage__c.getAll().keySet();
        String profileName = [SELECT id, name FROM Profile  WHERE id = :UserInfo.getProfileId() LIMIT 1].Name; 
        List<Opportunity> oppContextList =  new List<Opportunity>();
        for(Opportunity oppRecord : newRecordsMap.values()){
            Opportunity oppOld = oldRecordsMap.get(oppRecord.Id);

            if(oppOld.StageName != oppRecord.StageName){
                if(oppRecord.DontChangeStageName__c){
                    oppRecord.DontChangeStageName__c = false;
                }else if(!Approval.isLocked(oppRecord.id) && !profileSet.contains(profileName)){
                    oppRecord.addError(Label.CantChangeStageName);
                }
            }else if(oppRecord.DontChangeStageName__c){
                oppRecord.DontChangeStageName__c = false;
            }
        }
    }
    public static void sendEmailApprovalClient(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){
        Set<String> fieldsToCheck = new Set<String>{
            'StageName'
        }; 
        Set<Id> oppClientEmailSet =  new Set<Id>();
        for(Opportunity oppRecord : newRecordsMap.values()){
            Opportunity oppOld = oldRecordsMap.get(oppRecord.Id);
            if(oppOld.StageName != oppRecord.StageName){
                if(oppRecord.StageName == 'Em Aprovação Cliente'){
                    // System.debug(oppRecord);
                    oppRecord.StatusAprovacoes__c = 'Aguardando Aprovação - Cliente';
                    oppClientEmailSet.add(oppRecord.Id);
                }else if(oppRecord.StageName == 'Aprovado Cliente'){
                    oppRecord.AprovadoCliente__c = true;
                    oppRecord.StatusAprovacoes__c = 'Aprovado - Cliente';
                }else if(oppRecord.StageName == 'Reprovado Cliente'){
                    oppRecord.StatusAprovacoes__c = 'Rejeitado - Cliente';
                    oppRecord.AprovadoCliente__c = false;
                    oppRecord.AprovadoComercial__c = false;
                }else if(oppRecord.StageName == 'Iniciado'){
                    oppRecord.StatusAprovacoes__c = 'Pendente Envio';
                    oppRecord.AprovadoCliente__c = false;
                    oppRecord.AprovadoComercial__c = false;
                }
            }
        }
        // System.debug(oppClientEmailSet);
        if(!oppClientEmailSet.isEmpty()){
            OpportunityHelper.generateAttachmentSendEmail(oppClientEmailSet);
        }
    }
    @future(callout = true)
    public static void generateAttachmentSendEmail(Set<Id> oppIdSet){

        List<ContentVersion> ctVersionList = new List<ContentVersion>();
        List<Opportunity> oppClientEmailList = new List<Opportunity>();
        Map<String, Id> oppNumberToId = new Map<String, Id>();
        for(Opportunity opp : [SELECT id, numeroOportunidade__c, NomeCliente__c, stageName, EMailAprovacaoPedidoCliente__c, Territorio__c 
                               FROM Opportunity 
                               WHERE id IN: oppIdSet]){
            PageReference pageRef = Page.OpportunityPDF;
        
            pageRef.getParameters().put('Id', opp.id);
            
            Blob pdf = !Test.isRunningTest() ? pageRef.getContentAsPDF() : Blob.valueOf('Test');

            ContentVersion ctVersion    = new ContentVersion();
            ctVersion.Title             = 'Negociação-' + opp.numeroOportunidade__c + '.pdf';
            ctVersion.PathOnClient      = 'Negociação-' + opp.numeroOportunidade__c + '.pdf';
            ctVersion.VersionData       = pdf;

            oppNumberToId.put(opp.numeroOportunidade__c, opp.Id);
            ctVersionList.add(ctVersion);
            oppClientEmailList.add(opp);
        }
        // System.debug(ctVersionList);
        if(!ctVersionList.isEmpty()){
            insert ctVersionList;

            Map<Id, ContentVersion> ctVersionToLinkMap = new Map<Id, ContentVersion>([SELECT id, contentDocumentId, Title FROM ContentVersion WHERE id = :Collection.of(ctVersionList).pluckIds()]);
            Map<Id, Id> ctVToOpp = new Map<Id, Id>();
            for(ContentVersion ctVersion : ctVersionToLinkMap.values()){
                String oppNumber = ctVersion.Title.replace('Negociação-', '').replace('.pdf', '');
                if(oppNumberToId.containsKey(oppNumber)){
                    ctVToOpp.put(ctVersion.Id, oppNumberToId.get(oppNumber));
                }                
            }

            List<ContentDocumentLink> ctDocumentLinkList = new List<ContentDocumentLink>();
            for(ContentVersion ctVersion : ctVersionToLinkMap.values()){
                if(ctVToOpp.containsKey(ctVersion.Id)){
                    ctDocumentLinkList.add(new ContentDocumentLink(
                        ContentDocumentId       = ctVersion.contentDocumentId, 
                        LinkedEntityId          = ctVToOpp.get(ctVersion.Id), 
                        ShareType               = 'V'));
                }
            }

            if(!ctDocumentLinkList.isEmpty()){
                delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :oppNumberToId.values()];
                insert ctDocumentLinkList;
            }
        }
        EmailClientToApprove.sendEmail(oppClientEmailList);
    }

    public static void relayUpdatedBusinessLocationToChildDeliveryRecords(Map<Id, Opportunity> oldRecordsMap, Map<Id, Opportunity> newRecordsMap){

        Map<Id, Opportunity> filteredOpportunities = new Map<Id, Opportunity>();

        for(Opportunity opportunity : newRecordsMap.values()){
            if(opportunity.localNegocio__c != oldRecordsMap.get(opportunity.id).localNegocio__c){
                filteredOpportunities.put(opportunity.id, opportunity);
            }
        }

        if(!filteredOpportunities.isEmpty()){

            List<ProgramacaoEntrega__c> deliveryRecordsToUpdate = new List<ProgramacaoEntrega__c>();

            for(ProgramacaoEntrega__c deliveryRecord : [SELECT id, localNegocio__c, idOportunidade__c FROM ProgramacaoEntrega__c WHERE idOportunidade__c IN :filteredOpportunities.keySet()]){
                
                deliveryRecord.localNegocio__c = filteredOpportunities.get(deliveryRecord.idOportunidade__c).localNegocio__c;

                deliveryRecordsToUpdate.add(deliveryRecord);

            }

            if(!deliveryRecordsToUpdate.isEmpty()){
                OpportunityHelper.disableTrigger();
                ProgramacaoEntregaHelper.disableTrigger();
                    update deliveryRecordsToUpdate;
                ProgramacaoEntregaHelper.enableTrigger();
                OpportunityHelper.enableTrigger();
            }
        }

    }
}