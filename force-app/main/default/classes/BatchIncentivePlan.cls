global class BatchIncentivePlan implements Database.Batchable<SObject>{
    String query;

    public static void run(){
        Database.executeBatch(new BatchIncentivePlan(), 2000);
    }

    public BatchIncentivePlan() {}

    global Database.QueryLocator start(Database.BatchableContext BC){
        //Na query é realizado o filtro de dados onde só buscará o Plano de Incentivo que esteja com Status X
        query = 'SELECT Id, Name, Codigo__c, DataFinal__c, DataInicial__c, Descricao__c, '+
                'PremiacaoMeta__c, PremioSuperacaoMeta__c, Status__c, SuperacaoMeta__c, '+
                'MinimoMeta__c, PremioAtingimento__c, PremioMnimo__c FROM PlanoIncentivo__c WHERE Atualizado__c = false AND Status__c != \'Encerrado\'';

        return Database.getQueryLocator(query);
    } 

    global void execute(Database.BatchableContext BC, List<PlanoIncentivo__c> scope){

        Set<Id> planoIncentivoIdSet = new Set<Id>();
        List<ClientesPlanoIncentivos__c> clientesPlanoList = new List<ClientesPlanoIncentivos__c>();
        List<ClienteFamilia__c> clientesFamilia = new List<ClienteFamilia__c>();
        List<PlanoIncentivo__c> planIncentivoList = new List<PlanoIncentivo__c>();

        for (PlanoIncentivo__c pIncentivo : scope){
            planoIncentivoIdSet.add(pIncentivo.Id);
        }

        for (ClientesPlanoIncentivos__c cliPIncentivo : [SELECT Id, Name, Carteira__c, Moeda__c, NomeCliente__c, PlanoIncentivo__c, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, 
                                                         ValorMetaAnual__c, ValorMetaGlobal__c, /*Vendido__c,*/ RegimentoProgramaAssinado__c 
                                                         FROM ClientesPlanoIncentivos__c WHERE PlanoIncentivo__c IN: planoIncentivoIdSet]){
            clientesPlanoList.add(cliPIncentivo);
        }

        for (ClienteFamilia__c cliFamilia : [SELECT Id, Name, FamiliaClientes__c, ClienteFamlia__c, ValorCarteira__c, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, /*ValorVendido__c,*/ 
                                                  RegimentoProgramaAssinado__c, FamiliaClientes__r.PlanoIncentivo__c
                                                  FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: planoIncentivoIdSet]){
            clientesFamilia.add(cliFamilia);
        }

        ClientesPlanoIncentivoHelper.calcAfterInsert(clientesPlanoList);

        ClienteFamiliaHelper.calcAfterInsert(clientesFamilia);

        for (PlanoIncentivo__c planIncentivo : scope){
            planIncentivo.Atualizado__c = true;
            planIncentivoList.add(planIncentivo);
        }

        if (!planIncentivoList.isEmpty()){
            PlanoIncentivoHelper.disableTrigger();
            update planIncentivoList;
            PlanoIncentivoHelper.enableTrigger();
        }
    }

    global void finish(Database.BatchableContext BC) {}
}