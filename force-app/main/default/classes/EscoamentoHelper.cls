public class EscoamentoHelper extends TriggerContext {

    public static void sendToSAP(Map<Id, Escoamento__c> escoamentos) {

        if(Test.isRunningTest()) {
            Test.setMock(HttpCalloutMock.class, new IntegrationOutboundEscoamentoMock());
        }
        
        IntegrationOutboundEscoamento.sendEscoamentoTrigger(escoamentos.keySet());

    }

    public static void setSaldoLitrosEscoamento(List<Escoamento__c> escoamentos) {
        for (Escoamento__c escoamento : escoamentos) {
            escoamento.SaldoLitrosEscoamento__c = escoamento.Quantidade__c;
        }
    }

    public static void calculateBalance(Map<Id, Escoamento__c> escoamentoMap) {

        Map<Id, Escoamento__c> newEscoamentoMap = new Map<Id, Escoamento__c>([SELECT Id, QuantidadeLitros__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c, Quantidade__c FROM Escoamento__c WHERE Id IN :escoamentoMap.KeySet()]);

        Integer notaFiscalItemBalance = 0;

        Map<String, List<Escoamento__c>> criterioToEscoamentoList = new Map<String, List<Escoamento__c>>();
        for (Escoamento__c escoamento : newEscoamentoMap.values()) {
            if (!criterioToEscoamentoList.containsKey(escoamento.CriterioEscoamento__c)) {
                criterioToEscoamentoList.put(escoamento.CriterioEscoamento__c, new List<Escoamento__c>());
            }
            criterioToEscoamentoList.get(escoamento.CriterioEscoamento__c).add(escoamento);
        }
		
        Map<Id, NotaFiscalItem__c> notaFiscalItemMap = new Map<Id, NotaFiscalItem__c>(
            [
                SELECT Id, Litros__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c 
                FROM NotaFiscalItem__c 
                WHERE CriterioEscoamento__c IN :criterioToEscoamentoList.keySet() 
                AND SaldoLitrosEscoamento__c != 0 
                AND NotaFiscal__r.TipoFat__c != 'ZBON' 
                AND NotaFiscal__r.TipoFat__c != 'ZREB' 
                AND NotaFiscal__r.TipoNota__c = 'ZA' 
                AND NotaFiscal__r.StatusCancelado__c = false 
                ORDER BY CreatedDate
            ]);
   
        if (!notaFiscalItemMap.isEmpty()) {
            Map<Id, Integer> itemIdToQuantity = new Map<Id, Integer>();
            Integer escoamentoQuantity = 0;
            for (NotaFiscalItem__c item : notaFiscalItemMap.values()) {
                notaFiscalItemBalance += Integer.valueOf(item.SaldoLitrosEscoamento__c);
                itemIdToQuantity.put(item.Id, Integer.valueOf(item.SaldoLitrosEscoamento__c));
            }

            for (Escoamento__c escoamento : newEscoamentoMap.values()) {
                escoamentoQuantity += Integer.valueOf(escoamento.SaldoLitrosEscoamento__c);
                notaFiscalItemBalance -= Integer.valueOf(escoamento.Quantidade__c);
                if (notaFiscalItemBalance < 0) {
                    escoamento.SaldoLitrosEscoamento__c = notaFiscalItemBalance * -1;
                    break;
                }
                escoamento.SaldoLitrosEscoamento__c = 0;
            }

            System.debug(' itemIdToQuantity = ' + itemIdToQuantity);
            for (Id id : itemIdToQuantity.keySet()) {

                Integer result = escoamentoQuantity - itemIdToQuantity.get(id);
                if (result > 0 || result == 0) {
                    itemIdToQuantity.put(id, 0);
                    escoamentoQuantity = result;
                } else if (result < 0) {
                    Integer invertedResult = result * -1;
                    itemIdToQuantity.put(id, invertedResult);
                    break;
                }
            }
            for (Id id : itemIdToQuantity.keySet()) {
                notaFiscalItemMap.get(id).SaldoLitrosEscoamento__c = itemIdToQuantity.get(id);
            }
            
            NotaFiscalItemHelper.disableTrigger();
            update notaFiscalItemMap.values();
            NotaFiscalItemHelper.enableTrigger();
            EscoamentoHelper.disableTrigger();
            update newEscoamentoMap.values();
            EscoamentoHelper.enableTrigger();
        }
    }

    public static void updateEscoamentoRelationship(Map<Id, Escoamento__c> escoamentoMap) {

        String[] criterioList = new List<String>();
        for (Escoamento__c Escoamento : escoamentoMap.values()) {
            criterioList.add(Escoamento.CriterioPrecificacao__c);
        }

        Map<Id, NotaFiscalItem__c> notaFiscalItemMap = new Map<Id, NotaFiscalItem__c>([SELECT Id, CriterioPrecificacao__c FROM NotaFiscalItem__c WHERE CriterioPrecificacao__c IN :criterioList]);

        Map<String, List<NotaFiscalItem__c>> criterioToItemMap = new Map<String, List<NotaFiscalItem__c>>();
        for (NotaFiscalItem__c item : notaFiscalItemMap.values()) {
            if (!criterioToItemMap.containsKey(item.CriterioPrecificacao__c)) {
                criterioToItemMap.put(item.CriterioPrecificacao__c, new List<NotaFiscalItem__c>());
            }
            criterioToItemMap.get(item.CriterioPrecificacao__c).add(item);
        }

        for (Escoamento__c escoamento : escoamentoMap.values()) {
            if (criterioToItemMap.containsKey(escoamento.CriterioPrecificacao__c)) {
                for (NotaFiscalItem__c item : criterioToItemMap.get(escoamento.CriterioPrecificacao__c)) {
                    notaFiscalItemMap.get(item.Id).Escoamento__c = escoamento.Id;
                }
            }
        }

        NotaFiscalItemHelper.disableTrigger();
        update notaFiscalItemMap.values();
        NotaFiscalItemHelper.enableTrigger();

    }

    public static void withdrawBalance(Map<Id, Escoamento__c> escoamentoMap) {

        Map<String, List<Escoamento__c>> criterioToEscoamentoList = new Map<String, List<Escoamento__c>>();

        Integer escoamentoBalance = 0;

        for (Escoamento__c escoamento : escoamentoMap.values()) {
            escoamentoBalance += Integer.valueOf(escoamento.Quantidade__c) - Integer.valueOf(Escoamento.SaldoLitrosEscoamento__c);
            if (!criterioToEscoamentoList.containsKey(escoamento.CriterioEscoamento__c)) {
                criterioToEscoamentoList.put(escoamento.CriterioEscoamento__c, new List<Escoamento__c>());
            }
            criterioToEscoamentoList.get(escoamento.CriterioEscoamento__c).add(escoamento);
        }

        Map<Id, NotaFiscalItem__c> notaFiscalItemMap = new Map<Id, NotaFiscalItem__c>(
            [
                SELECT Id, Litros__c, SaldoLitrosEscoamento__c, CriterioEscoamento__c, QuantidadeNota__c 
                FROM NotaFiscalItem__c 
                WHERE CriterioEscoamento__c IN :criterioToEscoamentoList.keySet() 
                AND NotaFiscal__r.TipoFat__c != 'ZBON' 
                AND NotaFiscal__r.TipoFat__c != 'ZREB' 
                AND NotaFiscal__r.TipoNota__c = 'ZA' 
                AND NotaFiscal__r.StatusCancelado__c = false 
                ORDER BY CreatedDate
            ]);
        
        for (Integer i = notaFiscalItemMap.values().size() - 1; i >= 0; i--) {
            Integer balanceToWithdraw = Integer.valueOf(notaFiscalItemMap.values()[i].QuantidadeNota__c - notaFiscalItemMap.values()[i].SaldoLitrosEscoamento__c);
            
            if (escoamentoBalance == 0) {
                break;
            }
            if (escoamentoBalance >= balanceToWithdraw) {
                escoamentoBalance -= balanceToWithdraw;
                balanceToWithdraw = 0;
            } else {
                balanceToWithdraw -= escoamentoBalance;
                escoamentoBalance = 0;
            }

            notaFiscalItemMap.values()[i].SaldoLitrosEscoamento__c = notaFiscalItemMap.values()[i].QuantidadeNota__c - balanceToWithdraw;
        }
        NotaFiscalItemHelper.disableTrigger();
        update notaFiscalItemMap.values();
        NotaFiscalItemHelper.enableTrigger();
    }

    public static void updateHistory(Map<Id, Escoamento__c> oldMap, Map<Id, Escoamento__c> newMap) {

        LogImportacao__c[] logImportacaoToInsert = new List<LogImportacao__c>();

        for (Id id : oldMap.keySet()) {

            Escoamento__c oldEscoamento = oldMap.get(id);
            Escoamento__c newEscoamento = newMap.get(id);
            Set<String> diffFields = new Set<String>();

            for(String field : IntegrationUtils.getAllFieldsFromObject('Escoamento__c')) {

                String oldValue = String.valueOf(oldEscoamento.get(field));
                String newValue = String.valueOf(newEscoamento.get(field));

                if (differ(String.isBlank(oldValue) ? '' : oldValue, String.isBlank(newValue) ? '' : newValue)) {
                    diffFields.add(field);
                }
            }

            if (!diffFields.isEmpty()) {

                String oldText = '';
                String newText = '';

                for (String field : diffFields) {
                    String fieldName = field + ' => ';
                    oldText += fieldName + oldEscoamento.get(field) + '\n';
                    newText += fieldName + newEscoamento.get(field) + '\n';
                }
                LogImportacao__c log = new LogImportacao__c(
                    RecordTypeId          = SObjectType.LogImportacao__c.getRecordTypeInfosByDeveloperName().get('Escoamento').getRecordTypeId(),
                    CriadoPor__c          = oldEscoamento.CreatedById,
                    UltimaModificacao__c  = newEscoamento.LastModifiedById,
                    DataHoraImportacao__c = System.now(),
                    ValoresAntigos__c     = oldText,
                    ValoresNovos__c       = newText
                );
                logImportacaoToInsert.add(log);
            }
        }

        insert logImportacaoToInsert;
    }

    private static Boolean differ(String oldValue, String newValue) {
        return oldValue.equals(newValue) ? false : true;
    }

    public static void changeEscoamentoOwner(List<Escoamento__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Escoamento__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(Escoamento__c escoamento : newRecordsList){
            if(escoamento.territorio__c != null && territories.containsKey(escoamento.territorio__c) && escoamento.ownerId != territories.get(escoamento.territorio__c).rtv__c){
                escoamento.ownerId = territories.get(escoamento.territorio__c).rtv__c;
            }
        }
    }

    public static void fillApuracaoRelation(List<Escoamento__c> newRecordsList){

        List<Escoamento__c> withoutApuracao = new List<Escoamento__c>();
        Map<String, Apuracao__c> apuracaoToInsert = new Map<String, Apuracao__c>();
        List<String> criterioEscoamentoList = new List<String>();

        for(Escoamento__c escoamentoRecord : newRecordsList){
            if(escoamentoRecord.CriterioApuracao__c != null){
                criterioEscoamentoList.add(escoamentoRecord.CriterioApuracao__c);
            }
        }

        //Gets Apuracao__c records with the same CriterioApuracao__c field value
        Map<String, Apuracao__c> apuracaoMap = new Map<String, Apuracao__c>();
        for(Apuracao__c apuracao : [SELECT CriterioApuracao__c, Id FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioEscoamentoList]){
            apuracaoMap.put(apuracao.CriterioApuracao__c, apuracao);
        }

        System.debug('SELECT = ' + [SELECT CriterioApuracao__c, Id FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioEscoamentoList]);
        
        //Iterates over Escoamento__c records and compares them with apuracaoMap
        //If already has an Apuracao__c record with the same CriterioApuracao__c fill the relationship on Escoamento__c record, else creates a new Apuracao__c
        for(Escoamento__c escoamentoRecord : newRecordsList){
            System.debug('escoamentoRecord.CriterioApuracao__c ' + escoamentoRecord.CriterioApuracao__c);
            if(apuracaoMap.containsKey(escoamentoRecord.CriterioApuracao__c)){
                escoamentoRecord.Apuracao__c = apuracaoMap.get(escoamentoRecord.CriterioApuracao__c).Id;
            }else{
                Apuracao__c newApuracao = new Apuracao__c(
                    NomeConta__c = escoamentoRecord.NomeCliente__c,
                    Territorio__c = escoamentoRecord.TerritorioGerencial__c,
                    Produto__c = escoamentoRecord.Produto__c,
                    DataFaturamento__c = escoamentoRecord.DataApuracao__c,
                    // temporary attribute for set tipoApuracao1__c
                    tipoApuracao1__c = 'Escoamento'
                );
                withoutApuracao.add(escoamentoRecord);
                apuracaoToInsert.put(escoamentoRecord.CriterioApuracao__c, newApuracao);
            }
        }

        System.debug('apuracaoToInsert ' + apuracaoToInsert);

        if(apuracaoToInsert.size() > 0){
            insertApuracao(withoutApuracao, apuracaoToInsert);
        }
        
    }

    //Inserts the Apuracao__c record to get the Id and updates the CriterioApuracao__c field from Escoamento__c with the related Id
    public static void insertApuracao(List<Escoamento__c> withoutApuracao, Map<String, Apuracao__c> apuracaoToInsert){

        insert apuracaoToInsert.values();

        for(Escoamento__c escoamento : withoutApuracao){
            if(apuracaoToInsert.containsKey(escoamento.CriterioApuracao__c)){
                escoamento.Apuracao__c = apuracaoToInsert.get(escoamento.CriterioApuracao__c).Id;
            }else{
                escoamento.Apuracao__c = apuracaoToInsert.get(escoamento.CriterioApuracao__c).Id;
            }
        }

    }

    public static void changeManagerialTerritory(List<Escoamento__c> newRecordsList){

        Map<String,Id> mapCustomerTerritory = new Map<String,Id>();

        Set<Id> territoriesIds = new Set<Id>();

        for(Escoamento__c escoamento : newRecordsList){
            territoriesIds.add(escoamento.territorio__c);
        }

        for(TerritorioCliente__c customerTerritory : [SELECT Id, territorio__c, TerritorioGerencial__c, Conta__c FROM TerritorioCliente__c WHERE Territorio__c IN : territoriesIds]){
            mapCustomerTerritory.put(customerTerritory.territorio__c + '-' + customerTerritory.conta__c, customerTerritory.TerritorioGerencial__c);
        }

        for(Escoamento__c escoamento : newRecordsList){
            if(mapCustomerTerritory.containsKey(escoamento.territorio__c + '-' + escoamento.NomeCliente__c)){
                escoamento.TerritorioGerencial__c =  mapCustomerTerritory.get(escoamento.territorio__c + '-' + escoamento.NomeCliente__c);
            }
        }
    }
	/*
    public static void updatePrecificaoEscoamento(List<Escoamento__c> newRecordsList){
        Map<Id, Escoamento__c> escoamentoWithoutNotaItemMap = new Map<Id, Escoamento__c>();
        Map<Id, List<NotaFiscalItem__c>> escoamentoNotaItemMap = new Map<Id, List<NotaFiscalItem__c>>();
        Map<String, List<NotaFiscalItem__c>> keyToNotaItemMap = new Map<String, List<NotaFiscalItem__c>>();
        List<Id> clientList = Collection.of(newRecordsList).pluckIds(Escoamento__c.NomeCliente__c);
        List<Id> territorioList = Collection.of(newRecordsList).pluckIds(Escoamento__c.Territorio__c);
        List<Id> productList = Collection.of(newRecordsList).pluckIds(Escoamento__c.Produto__c);

        // Gets all NotaFiscalItem records with same CodigoCliente__c, Territorio__c and Product as the Escoamento__c records
        List<NotaFiscalItem__c> notaFiscalItemList = new List<NotaFiscalItem__c>([  SELECT Id, 
                                                                                        ValorTotalItem__c, 
                                                                                        NotaFiscal__r.CodigoCliente__c, 
                                                                                        NotaFiscal__r.Territorio__c, 
                                                                                        CodigoMaterial__c 
                                                                                    FROM NotaFiscalItem__c 
                                                                                    WHERE NotaFiscal__r.NomeCliente__c IN :clientList 
                                                                                    AND NotaFiscal__r.Territorio__c IN :territorioList 
                                                                                    AND CodigoMaterial__c IN :productList
                                                                                    AND CreatedDate >= LAST_N_DAYS:365]);

        //Iterates over query result and populates keyToNotaItemMap. Key being ClientId + TerritorioId + ProductId
        for(NotaFiscalItem__c notaItem : notaFiscalItemList){
            if(!keyToNotaItemMap.containsKey((String) notaItem.NotaFiscal__r.CodigoCliente__c + (String) notaItem.NotaFiscal__r.Territorio__c + (String) notaItem.CodigoMaterial__c)){
                keyToNotaItemMap.put((String) notaItem.NotaFiscal__r.CodigoCliente__c + (String) notaItem.NotaFiscal__r.Territorio__c + (String) notaItem.CodigoMaterial__c, new List<NotaFiscalItem__c>{notaItem});
            }
            keyToNotaItemMap.get((String) notaItem.NotaFiscal__r.CodigoCliente__c + (String) notaItem.NotaFiscal__r.Territorio__c + (String) notaItem.CodigoMaterial__c).add(notaItem);
            
        }

        //Iterates over Escoamento__c new records list, compare key values from keyToNotaItemMap to get the NotaFiscalItem values. 
        
        for(Escoamento__c escoamento : newRecordsList){
            String escoamentoKey = (String) escoamento.NomeCliente__c + (String) escoamento.Territorio__c + (String) escoamento.Produto__c;
            if(keyToNotaItemMap.containsKey(escoamentoKey)){
                for(NotaFiscalItem__c nota : keyToNotaItemMap.get(escoamentoKey)){
                    escoamento.PrecificacaoEscoamento__c += nota.ValorTotalItem__c;
                }
                // Verifies if PrecificacoEscoamento is greater than 0, if there are NotaFiscalItem__c records for that key and than calculates average
                if(escoamento.PrecificacaoEscoamento__c > 0 && keyToNotaItemMap.get(escoamentoKey).size() > 0){
                    escoamento.PrecificacaoEscoamento__c = escoamento.PrecificacaoEscoamento__c / keyToNotaItemMap.get(escoamentoKey).size(); 
                }
            }else{
                escoamentoWithoutNotaItemMap.put(escoamento.Id, escoamento);
            }
        }

        //If theres no NotaFiscalItem with same key, will query TabelaPreco__c object for PrecificacaoEscoamento__c value
        if(escoamentoWithoutNotaItemMap.size() > 0 ){
            List<Id> acctList = Collection.of(escoamentoWithoutNotaItemMap.values()).pluckIds(Escoamento__c.NomeCliente__c);
            List<Id> terrList = Collection.of(escoamentoWithoutNotaItemMap.values()).pluckIds(Escoamento__c.Territorio__c);
            List<Id> prodList = Collection.of(escoamentoWithoutNotaItemMap.values()).pluckIds(Escoamento__c.Produto__c);
            List<TabelaPreco__c> tabelaPrecoList = new List<TabelaPreco__c>([   SELECT Id, 
                                                                                    Cliente__c
                                                                                FROM TabelaPreco__c
                                                                                WHERE Cliente__c IN :acctList]);

        }


    }
*/
}