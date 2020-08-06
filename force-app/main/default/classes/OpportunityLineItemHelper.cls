public class OpportunityLineItemHelper extends TriggerContext{
    public static List<ApprovedItemDatePair> calcItemUpdatedDates(OpportunityLineItem[] items){
        List<ApprovedItemDatePair> result = new List<ApprovedItemDatePair>();

        for(OpportunityLineItem item : items){
            ApprovedItemDatePair pair = new ApprovedItemDatePair(item);

            result.add(pair);
        }

        return result;
    }
    public static void blockDelete(List<OpportunityLineitem> context){
        Set<String> profileSet = ProfileDeleteOpp__c.getAll().keySet();
        String profileName = [SELECT id, name FROM Profile  WHERE id = :UserInfo.getProfileId() LIMIT 1].Name;
        if(!profileSet.contains(profileName)){ 
            Set<id> oppIdSet = new Set<id>();
            for(OpportunityLineitem oppLine : context){
                oppIdSet.add(oppLine.OpportunityId);
            }
            Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>([SELECT id, StageName FROM Opportunity WHERE id IN : oppIdSet]);
            for(OpportunityLineitem oppLine : context){
                Opportunity opp = mapOpp.get(oppLine.OpportunityId);
                // if(opp.StageName != 'Iniciado'){
                oppLine.addError(Label.CantDeleteOpp);
                // }
            }
        }
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

    public static void sendEmailForApprovedItemsWithDateChange(OpportunityLineItem[] items){
        items = [
            SELECT 
                opportunityId, 
                opportunity.account.name,
                opportunity.owner.name,
                opportunity.owner.email,
                opportunity.numeroOportunidade__c,
                itinerario__c,
                dataFaturamento__c,
                dataEntrega__c,
                quantity,
                pricebookEntry.product2.name,
                pricebookEntry.product2.embalagem__c
            FROM OpportunityLineItem
            WHERE id IN :items
            AND confirmado__c = TRUE
        ];

        Map<Id, OpportunityLineItem[]> itemsGrouped = Collection.of(items).groupByIds(OpportunityLineItem.opportunityId);
        List<Id> opportunityLineItemsIds = Collection.of(items).pluckIds(OpportunityLineItem.Id);
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();

        List<ApprovedItemDatePair> itemsWithChangedDate = new List<ApprovedItemDatePair>();

        for(Id opportunityId : itemsGrouped.keySet()){
            OpportunityLineItem[] oppItems = itemsGrouped.get(opportunityId);

            Opportunity o = items.get(0).opportunity;

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
            
            List<ApprovedItemDatePair> dateResult = calcItemUpdatedDates(items);

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

            List<ProgramacaoEntrega__c> deliveryRecords = [
                SELECT id, dataEntrega__c, idOpportunityLineItem__c
                FROM ProgramacaoEntrega__c
                WHERE idOpportunityLineItem__c = :opportunityLineItemsIds
                AND confirmado__c = true
            ];

            if(!deliveryRecords.isEmpty()){

                Map<String, ProgramacaoEntrega__c> opportunityLineItemIdToDeliveryRecord = new Map<String, ProgramacaoEntrega__c>();

                for(ProgramacaoEntrega__c deliveryRecord : deliveryRecords){
                    opportunityLineItemIdToDeliveryRecord.put(deliveryRecord.idOpportunityLineItem__c, deliveryRecord);
                }

                OpportunityLineItem[] recordsWithChangedDate = new OpportunityLineItem[]{};
                for(ApprovedItemDatePair datePair : itemsWithChangedDate){
                    recordsWithChangedDate.add(datePair.updateItem());
                }

                for(OpportunityLineItem item : recordsWithChangedDate){
                    opportunityLineItemIdToDeliveryRecord.get(item.id).dataEntrega__c     = item.dataEntrega__c;
                    opportunityLineItemIdToDeliveryRecord.get(item.id).dataFaturamento__c = item.dataFaturamento__c;
                }

                update opportunityLineItemIdToDeliveryRecord.values();

                // OpportunityLineItemHelper.disableTrigger();        
                //     update recordsWithChangedDate;
                // OpportunityLineItemHelper.enableTrigger();
            }
        }
    }
    
    public static void removeConfirmedFields(Map<Id, OpportunityLineItem> oldMap, Map<Id, OpportunityLineItem> newMap){
        TriggerRecordsHandler recordsHandler = new TriggerRecordsHandler(oldMap, newMap);

        OpportunityLineItem[] records = Collection.of(
                                            recordsHandler.getChangedRecordsOn('confirmado__c')
                                        ).filter(
                                            Match.field('confirmado__c').equals(false)
                                        ).asList();

        for(OpportunityLineItem item : records){
            item.dataConfirmacao__c    = null;
            item.usuarioConfirmacao__c = null;
        }
    }
}