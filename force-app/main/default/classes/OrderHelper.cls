public class OrderHelper extends TriggerContext {

    public static void countOrdByOpp(Map<Id, Order> context, Boolean isInsert){
        countOrdByOpp(JSON.serialize(context), isInsert);
    }   

    public static void integrateNewOrder(List<Order> context){
        for(Order ord : context){
            if(ord.OVSAP__c != null){
                ord.DataIntegracao__C = System.Today();
            }
        }
    }

    public static void changeOrderOwner(List<Order> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Order.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        List<Order> opportunitiesToUpdateOwner = new List<Order>();

        for(Order order : newRecordsList){
            if(order.territorio__c != null && territories.containsKey(order.territorio__c) && order.ownerId != territories.get(order.territorio__c).rtv__c){
                order.ownerId = territories.get(order.territorio__c).rtv__c;
            }
        }
    }

    @future
    public static void countOrdByOpp(String contextString, Boolean isInsert){
        Map<Id, Order> context = (Map<Id, Order> )JSON.deserialize(contextString, Map<Id, Order>.class);
        Map<Id, List<Order>> oppIdToOrdMap = (Map<Id, List<Order>>)Collection.of(context.values()).groupByIds(Order.OpportunityId, List<Order>.class);
        
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : [SELECT Id, ContadorOV__c FROM Opportunity WHERE id IN : oppIdToOrdMap.keySet()]){
            if(oppIdToOrdMap.containsKey(opp.Id)){
                Integer qtdOrd = oppIdToOrdMap.get(opp.Id).size();
                if(opp.ContadorOV__c == null)
                    opp.ContadorOV__c = 0;
                opp.ContadorOV__c = (isInsert ? opp.ContadorOV__c + qtdOrd : opp.ContadorOV__c - qtdOrd);
                oppList.add(opp);
            }
        }
        if(!oppList.isEmpty()){
            OpportunityHelper.disableTrigger();
            update oppList;
            OpportunityHelper.enableTrigger();
        }    
    }

    public static void fillItinerarioLookup(Map<Id, Order> newOrderMap) {
        Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, 
                                                             OpportunityId,
                                                             Opportunity.AccountId, 
                                                             Opportunity.Account.ZonaTransporte__c, 
                                                             Opportunity.Account.ZonaTransporte__r.ExternalId__c, 
                                                             Opportunity.LocalNegocio__c,
                                                             Opportunity.LocalNegocio__r.ZonaTransporte__c,
                                                             Opportunity.LocalNegocio__r.ZonaTransporte__r.ExternalId__c
                                                      FROM Order 
                                                      WHERE Id IN :newOrderMap.keySet()]);
        
        Map<Id, String> orderIdToZTExternalId = new Map<Id, String>();
        Set<String> zonaOrigemKeys = new Set<String>();
        Set<String> zonaDestinoKeys = new Set<String>();
        // Opp -> Local de negócio -> ZN origem
        // Opp -> Cliente -> ZN destino
        for (Order order : orderMap.values()) {

            String origemKey = order.Opportunity.LocalNegocio__r.ZonaTransporte__r.ExternalId__c;
            String destinoKey = order.Opportunity.Account.ZonaTransporte__r.ExternalId__c;

            orderIdToZTExternalId.put(order.Id, origemKey + destinoKey);
            zonaOrigemKeys.add(origemKey);
            zonaDestinoKeys.add(destinoKey);
        }

        Itinerario__c[] itinerarioList = 
            [
                SELECT Id, 
                       ExternalId__c, 
                       ZonaTransporteOrigem__c, 
                       ZonaTransporteOrigem__r.ExternalId__c, 
                       ZonaTransporteDestino__c, 
                       ZonaTransporteDestino__r.ExternalId__c 
                FROM Itinerario__c 
                WHERE ZonaTransporteOrigem__r.ExternalId__c IN :zonaOrigemKeys
                AND ZonaTransporteDestino__r.ExternalId__c IN :zonaDestinoKeys
            ];
            
        Map<String, Id> itinerarioMap = new Map<String, Id>();
        for (Itinerario__c itinerario : itinerarioList) {
            itinerarioMap.put(itinerario.ZonaTransporteOrigem__r.ExternalId__c + itinerario.ZonaTransporteDestino__r.ExternalId__c, itinerario.Id);
        }

        for (String orderKey : orderMap.keySet()) {
            orderMap.get(orderKey).Itinerario__c = itinerarioMap.get(orderIdToZTExternalId.get(orderKey));
        }
        OrderHelper.disableTrigger();
        update orderMap.values();
        OrderHelper.enableTrigger();
    }

    public static void sendIntegratedOVsEmail(Map<Id, Order> newRecordsMap){

        Set<Id> filteredIntegratedOrderIds = new Set<Id>();

        List<String> orderTypes = new List<String>{
            'Conta e Ordem',
            'Bonificação',
            'Remanejamento',
            'Venda futura'
        };

        for(Order order : newRecordsMap.values()){
            if(orderTypes.contains(order.tipoOrdem__c) && order.OVSAP__c != null){
                filteredIntegratedOrderIds.add(order.id);
            }
        }

        System.debug('filteredIntegratedOrderIds ' + filteredIntegratedOrderIds);

        if(!filteredIntegratedOrderIds.isEmpty()){

            Map<Id, Order> filteredIntegratedOrders = new Map<Id, Order>([
                SELECT  id, opportunityId, opportunity.name, clienteEmissor__r.name, 
                        tipoOrdem__c, valorTotalPedidoBRLUSD__c, rtv__r.name, gerenteRegional__r.name,Moeda__c,
                        ValorTotalItensPedido__c, ValorPedidoUSD__c
                FROM Order
                WHERE id IN: filteredIntegratedOrderIds
            ]);

            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            Set<Id> opportunityIdsToUpdate = new Set<Id>();
            Set<String> emailIntegration = IntegrationOVsEmail__c.getAll().keySet();
            
            for(Order order : filteredIntegratedOrders.values()){

                Decimal valorTotalPedidoBRLUSD = 0;

                if(order.Moeda__c == 'BRL'){
                    valorTotalPedidoBRLUSD = order.ValorTotalItensPedido__c;
                }else{
                    valorTotalPedidoBRLUSD = order.ValorPedidoUSD__c;
                }

                System.debug('valorTotalPedidoBRLUSD ' + valorTotalPedidoBRLUSD);

                String emailHtmlBody = (
                    '<html>                                                                                                                                              \n' +
                    '    <body>                                                                                                                                          \n' +
                    '    <style>                                                                                                                                         \n' +
                    '        .items-table th, .items-table td {                                                                                                          \n' +
                    '            text-align: center; padding: 0 10px;                                                                                                                        \n' +
                    '        }                                                                                                                                           \n' +
                    '    </style>                                                                                                                                        \n' +
                    '        <div>                                                                                                                                       \n' +
                    '            <p>Customer Service,</p>                                                                                                              \n' +
                    '                                                                                                                                                    \n' +
                    '            <p>Abaixo, segue a ordem de venda criada no ERP que precisa de tratativa manual.</p> \n' +
                    '        </div>                                                                                                                                      \n' +
                    '                                                                                                                                                    \n' +
                    '        <div>                                                                                                                                       \n' +
                    '            <table style="border-spacing: 0px; border-collapse: collapse" class="items-table">                                                                                                             \n' +
                    '                <thead>                                                                                                                             \n' +
                    '                    <tr>                                                                                                                            \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">Nº da Oportunidade</th>                                                                                  \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">Nº Ordem de venda</th>                                                                                              \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 25%">Cliente</th>                                                                                               \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">Tipo de Ordem</th>                                                                                                 \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 5%" >Valor total</th>                                                                             \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 25%">RTV</th>                                                                          \n' +
                    '                        <th style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 15%">Gerente Regional</th>                                                                           \n' +
                    '                    </tr>                                                                                                                           \n' +
                    '                </thead>                                                                                                                            \n' +
                    '                                                                                                                                                    \n' +
                    '                <tbody>                                                                                                                             \n' +
                    '                   <tr>                                                                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">' + order.OpportunityId != null ? String.valueOf(order.opportunity.name).remove('OPT-')  : ''                              + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">' + newRecordsMap.get(order.id).OVSAP__c                                                 + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 25%">' + (String.isBlank(order.clienteEmissor__r.name)? '-' : order.clienteEmissor__r.name)   + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 10%">' + order.tipoOrdem__c                                                                   + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 5%" >' + OpportunityPDFController.getFormattedValue(valorTotalPedidoBRLUSD)                   + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 25%">' + (String.isBlank(order.rtv__r.name)? '-' : order.rtv__r.name)                         + '</td>                                                                             \n' +
                    '                       <td style="border: 1px solid #000; text-align: center; padding: 0 10px; width: 15%">' + (String.isBlank(order.gerenteRegional__r.name)? '-' : order.gerenteRegional__r.name) + '</td>                                                                             \n' +
                    '                   </tr>                                                                                                                            \n' +
                    '                </tbody>                                                                                                                            \n' +
                    '            </table>                                                                                                                                \n' +
                    '        </div>                                                                                                                                      \n' +
                    '                                                                                                                                                    \n' +
                    '        <div>                                                                                                                                       \n' +
                    '        <p><b>Observações:</b></p>                                                                                                                  \n' +
                    '        <p>Conta Ordem = Emissão de Remessa</p>                                                                                                     \n' +
                    '        <p>Venda Futura = Emissão de Remessa</p>                                                                                                    \n' +
                    '        <p>Remanejamento = Emissão de NF sem produto</p>                                                                                            \n' +
                    '        <p>Bonificação</p>                                                                                                                          \n' +
                    '        </div>                                                                                                                                      \n' +
                    '    </body>                                                                                                                                         \n' +
                    '</html>                                                                                                                                             \n'
                );

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                mail.setHtmlBody(emailHtmlBody);
                mail.setToAddresses(new List<String>(emailIntegration));
                mail.setSubject('Salesforce - Ordens de Venda integradas para tratativa no ERP');

                mailList.add(mail);

                opportunityIdsToUpdate.add(order.opportunityId);
            }

            if(!mailList.isEmpty()){
                Messaging.sendEmail(mailList);
            }
        }
    }

    public static void refreshOVSapCountFields(Map<Id, Order> oldRecordsMap, Map<Id, Order> newRecordsMap){
        
        Set<Id> opportunitiesIdsToRefreshCountField = new Set<Id>();

        for(Order order : newRecordsMap.values()){
            // System.debug('order.OVSAP__c => ' + order.OVSAP__c);
            // System.debug('oldRecordsMap.get(order.id).OVSAP__c => ' + oldRecordsMap.get(order.id).OVSAP__c);
            if(order.OVSAP__c != oldRecordsMap.get(order.id).OVSAP__c){
                opportunitiesIdsToRefreshCountField.add(order.opportunityId);
            }
        }

        List<Opportunity> opportunitiesToRefreshCountField = [
            SELECT id, quantidadeOrdensVendas__c,
                (
                    SELECT id
                    FROM Orders
                    WHERE OVSap__c != null
                )
            FROM Opportunity 
            WHERE id IN :opportunitiesIdsToRefreshCountField
        ];

        for(Opportunity opportunity : opportunitiesToRefreshCountField){
            opportunity.quantidadeOrdensVendas__c = opportunity.orders.size();
        }

        OpportunityHelper.disableTrigger();
            update opportunitiesToRefreshCountField;
        OpportunityHelper.enableTrigger();

    }
}