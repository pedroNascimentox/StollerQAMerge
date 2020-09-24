public class NotaFiscalHelper extends TriggerContext {
    public static void addTaxToNotaFiscal(List<NotaFiscal__c> notasFiscais) {

        Date dtToday = Date.today().addDays(-1);
           
        Date baseDate = (dtToday).addDays(-7);

        Set<Date> holidaySet = new Set<Date>();

        for (Holiday h : [SELECT ActivityDate FROM Holiday WHERE ActivityDate >= :baseDate]){
            holidaySet.add(h.ActivityDate);
        }

        Date endDate = (dtToday).addDays(-1);
        Date lastDate = endDate;
        Date iterationDate = lastDate;

        do {
            Integer dayOfTheWeek = getDayOfTheWeek(iterationDate);

            if (dayOfTheWeek != 0 && dayOfTheWeek != 6 && !holidaySet.contains(iterationDate)){
                iterationDate = endDate;

            }else{
                lastDate = lastDate.addDays(-1);
                iterationDate = iterationDate.addDays(-1);
            }
        
        }while (!iterationDate.isSameDay(endDate));
        //List<CotacaoMoeda__c> cotacaoMoeda = new List<CotacaoMoeda__c>([SELECT Id, Data__c, Taxa__c FROM CotacaoMoeda__c WHERE Data__c =: lastDate LIMIT 1]);
        // Changing the way that select works
        List<CotacaoMoeda__c> cotacaoMoeda = new List<cotacaoMoeda__c>([select id, data__C, taxa__c from cotacaomoeda__c order by createddate desc Limit 1]);
        system.debug('lastDate = ' + lastDate);
        system.debug('cotacaoMoeda = ' + cotacaoMoeda);
        for (NotaFiscal__c nota : notasFiscais) {
            if(cotacaoMoeda.size() > 0)
                nota.TaxaDolarFaturamento__c = cotacaoMoeda[0].Taxa__c;
        }

        /*

        Date[] dateList = new List<Date>();
        for (NotaFiscal__c nota : notasFiscais) {
            dateList.add(nota.DataNF__c.addDays(-1));
        }
        
        Map<Date, Decimal> dateToTaxaMap = new Map<Date, Decimal>();
        CotacaoMoeda__c[] cotacaoMoedaList = [SELECT Id, Data__c, Taxa__c FROM CotacaoMoeda__c WHERE Data__c IN :dateList];
        for (CotacaoMoeda__c cotacaoMoeda : cotacaoMoedaList) {
            dateToTaxaMap.put(cotacaoMoeda.Data__c, cotacaoMoeda.Taxa__c);
        }

        Decimal taxaMedia = 1;
        for(CotacaoMoeda__c cotacoesMoeda : [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < : dateList ORDER BY Data__c DESC LIMIT 1]){
            taxaMedia = cotacoesMoeda.TaxaMedia__c;
        }

        for (NotaFiscal__c nota : notasFiscais) {
            nota.TaxaDolarFaturamento__c = taxaMedia;
        }

        */
    }

    public static void addDateToFields(Map<Id, NotaFiscal__c> notasFiscais) {

        String[] orderIds = new List<String>();
        Map<Id, Id> orderIdToNotaFiscalId = new Map<Id, Id>();
        Map<Id, List<String>> orderIdToNotaFiscalExternalId = new Map<Id, List<String>>();
        for (NotaFiscal__c nota : notasFiscais.values()) {
            if (orderIdToNotaFiscalExternalId.containsKey(nota.NrOrdem__c)) {
                orderIdToNotaFiscalExternalId.get(nota.NrOrdem__c).add(String.valueOf(Integer.valueOf(nota.NrNF__c)));
            } else {
                orderIdToNotaFiscalExternalId.put(nota.NrOrdem__c, new List<String>{String.valueOf(Integer.valueOf(nota.NrNF__c))});
            }
            orderIds.add(nota.NrOrdem__c);
            orderIdToNotaFiscalId.put(nota.NrOrdem__c, nota.Id);
        }

        List<Order> orderList = [SELECT Id, NotaFiscal__c FROM Order WHERE Id IN :orderIdToNotaFiscalExternalId.keySet() FOR UPDATE];
        for (Order order : orderList) {
            order.NotaFiscal__c = String.join(orderIdToNotaFiscalExternalId.get(order.Id), '-');
        }
        if (!orderList.isEmpty()) {
            update orderList;
        }

        Map<Id, OrderItem> orderitemMap = new Map<Id, OrderItem>([SELECT Id, OrderId, DataNotaFiscal__c, ProgramacaoEntrega__c FROM OrderItem WHERE OrderId IN :orderIds]);
        Map<Id, OrderItem> programacaoIdToItem = new Map<Id, OrderItem>();
        String[] programacaoEntregaIds = new List<String>();
        for (OrderItem oi : orderitemMap.values()) {
            oi.DataNotaFiscal__c = notasFiscais.get(orderIdToNotaFiscalId.get(oi.OrderId)).DataNF__c;
            programacaoIdToItem.put(oi.ProgramacaoEntrega__c, oi);
        }
        if (!orderitemMap.isEmpty()) {
            OrderItemHelper.disableTrigger();
            update orderitemMap.values();
            OrderItemHelper.enableTrigger();
        }

        ProgramacaoEntrega__c[] programacaoEntregaList = [SELECT Id, DataNotaFiscal__c FROM ProgramacaoEntrega__c WHERE Id IN :programacaoIdToItem.keySet()];
        for (ProgramacaoEntrega__c pe : programacaoEntregaList) {
            pe.DataNotaFiscal__c = notasFiscais.get(orderIdToNotaFiscalId.get(programacaoIdToItem.get(pe.Id).OrderId)).DataNF__c;
        }
        if (!programacaoEntregaList.isEmpty()) {
            ProgramacaoEntregaHelper.disableTrigger();
            update programacaoEntregaList;
            ProgramacaoEntregaHelper.enableTrigger();
        }
        
    }

    public static void updateCliPlanoIncentivo(Map<Id, NotaFiscal__c> newContextMap, Map<Id, NotaFiscal__c> oldContextMap){
        List<ClientesPlanoIncentivos__c> cliPlanoIncentivoList = new List<ClientesPlanoIncentivos__c>();

        Map<Id, NotaFiscal__c> mapCliIdToNfAdd = new Map<Id, NotaFiscal__c>();
        Map<Id, NotaFiscal__c> mapCliIdToNfMin = new Map<Id, NotaFiscal__c>();

        for (NotaFiscal__c nf : [SELECT Id, ClientePlanoIncentivo__c, ValorTotalNota__c, ValorTotalNotaUSD__c FROM NotaFiscal__c WHERE Id IN: oldContextMap.keySet()]){
            NotaFiscal__c nfOld = oldContextMap.get(nf.Id);
            if (nf.ClientePlanoIncentivo__c != null){
                mapCliIdToNfAdd.put(nf.ClientePlanoIncentivo__c, nf);
                mapCliIdToNfMin.put(nf.ClientePlanoIncentivo__c, nfOld);
            }
        }
        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, Carteira__c, Moeda__c FROM ClientesPlanoIncentivos__c WHERE Id IN: mapCliIdToNfAdd.keySet()]){
            NotaFiscal__c newNf = mapCliIdToNfAdd.get(cliPlan.Id);
            NotaFiscal__c oldNf = mapCliIdToNfMin.get(cliPlan.Id);
            if (newNf.ValorTotalNota__c != oldNf.ValorTotalNota__c || newNf.ValorTotalNotaUSD__c != oldNf.ValorTotalNotaUSD__c){
                if (cliPlan.Moeda__c == 'BRL'){
                    cliPlan.Carteira__c = cliPlan.Carteira__c - oldNf.ValorTotalNota__c    + newNf.ValorTotalNota__c;
                }else{
                    cliPlan.Carteira__c = cliPlan.Carteira__c - oldNf.ValorTotalNotaUSD__c + newNf.ValorTotalNotaUSD__c;
                }
                cliPlanoIncentivoList.add(cliPlan);
            }
        }

        // system.debug('cliPlanoIncentivoList: '+ cliPlanoIncentivoList);

        if (!cliPlanoIncentivoList.isEmpty()){
            update cliPlanoIncentivoList;
        }
    }

    public static void updatePlanoIncentivo(NotaFiscal__c[] nfList){
        Set<Id> clienteEmissorSet = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();
        List<PlanoIncentivo__c> planoIncentivoToUpdate = new List<PlanoIncentivo__c>();

        for (NotaFiscal__c nf : nfList){
            if (nf.CodigoCliente__c != null){
                clienteEmissorSet.add(nf.CodigoCliente__c);
            }
        }

        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, PlanoIncentivo__c FROM ClientesPlanoIncentivos__c WHERE NomeCliente__c IN: clienteEmissorSet]){
            system.debug(cliPlan.PlanoIncentivo__c);
            planoIncentivoSet.add(cliPlan.PlanoIncentivo__c);
        }

        for (ClienteFamilia__c cliFam : [SELECT Id, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__c FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: clienteEmissorSet]){
            system.debug(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
            planoIncentivoSet.add(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
        }

        for (PlanoIncentivo__c planoIncentivo : [SELECT Id, Atualizado__c FROM PlanoIncentivo__c WHERE Id IN: planoIncentivoSet]){
            planoIncentivo.Atualizado__c = false;
            planoIncentivoToUpdate.add(planoIncentivo);
        }

        if (!planoIncentivoToUpdate.isEmpty()){
            PlanoIncentivoHelper.disableTrigger();
            update planoIncentivoToUpdate;
            PlanoIncentivoHelper.enableTrigger();
        }
    }

    public static void withdrawBalance(Map<Id, NotaFiscal__c> newContextMap, Map<Id, NotaFiscal__c> oldContextMap) {

        Map<Id, NotaFiscalItem__c> notaFiscalItemToWithdrawMap = new Map<Id, NotaFiscalItem__c>();

        for (Id id : oldContextMap.keySet()) {

            NotaFiscal__c newNota = newContextMap.get(id);
            NotaFiscal__c oldNota = oldContextMap.get(id);

            Boolean filtersToIgnore = oldNota.TipoFat__c != 'ZBON' && oldNota.TipoFat__c != 'ZREB' && !oldNota.StatusCancelado__c;

            if (filtersToIgnore && (oldNota.TipoFat__c != 'ZBON' && newNota.TipoFat__c == 'ZBON' ||
                                    oldNota.TipoFat__c != 'ZREB' && newNota.TipoFat__c == 'ZREB' ||
                                    !oldNota.StatusCancelado__c && newNota.StatusCancelado__c )) {
                notaFiscalItemToWithdrawMap.put(id, null);
            }
        }

        notaFiscalItemToWithdrawMap = new Map<Id, NotaFiscalItem__c>([
            SELECT Id, QuantidadeNota__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c FROM NotaFiscalItem__c 
            WHERE NotaFiscal__c IN :notaFiscalItemToWithdrawMap.keySet() 
        ]);

        NotaFiscalItemHelper.withdrawBalanceWithoutSelect(notaFiscalItemToWithdrawMap);

    }

    public static void fillOpportunityLookup(List<NotaFiscal__c> newContext){
        
        List<Id> orderIds = Collection.of(newContext).pluckIds(NotaFiscal__c.NrOrdem__c);

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT id, opportunityId
            FROM Order
            WHERE id IN :orderIds
            AND opportunityId != null
        ]);
        
        for(NotaFiscal__c notaFiscal : newContext){
            if(notaFiscal.oportunidade__c == null && orderMap.containsKey(notaFiscal.nrOrdem__c)){
                notaFiscal.oportunidade__c = orderMap.get(notaFiscal.nrOrdem__c).opportunityId;
            }
        }
    }

    public static void changeNotaFiscalOwner(List<NotaFiscal__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(NotaFiscal__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(NotaFiscal__c notaFiscal : newRecordsList){
            if(notaFiscal.territorio__c != null && territories.containsKey(notaFiscal.territorio__c) && notaFiscal.ownerId != territories.get(notaFiscal.territorio__c).rtv__c){
                notaFiscal.ownerId = territories.get(notaFiscal.territorio__c).rtv__c;
            }
        }
    }

    private static Integer getDayOfTheWeek(Date dt){
        return Math.mod(Date.newInstance(1900, 1, 7).daysBetween(dt),7);
    }

    public static void changeManagerialTerritory(List<NotaFiscal__c> newRecordsList){

        Map<String,Id> mapCustomerTerritory = new Map<String,Id>();

        Set<Id> territoriesIds = new Set<Id>();

        Set<Id> notasIds = new Set<Id>();

        for(NotaFiscal__c nota : newRecordsList){
            territoriesIds.add(nota.territorio__c);
            notasIds.add(nota.Id);
        }

        for(TerritorioCliente__c customerTerritory : [SELECT Id, territorio__c, TerritorioGerencial__c,Conta__c FROM TerritorioCliente__c WHERE Territorio__c IN : territoriesIds]){
            mapCustomerTerritory.put(customerTerritory.territorio__c + '-' + customerTerritory.conta__c, customerTerritory.TerritorioGerencial__c);
        }

        for(NotaFiscal__c nota : newRecordsList){
            if(mapCustomerTerritory.containsKey(nota.territorio__c + '-' + nota.CodigoCliente__c)){
                nota.TerritorioGerencial__c =  mapCustomerTerritory.get(nota.territorio__c + '-' + nota.CodigoCliente__c);
            }
        }
    }

}