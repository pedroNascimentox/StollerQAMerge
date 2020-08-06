public with sharing class BatchOrderItemTaxaMedia implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, ValorTotalUSD__c, ValorTotal__c, SaldoBRL__c, SaldoUSD__c FROM OrderItem WHERE ' + 
                                        'StatusSAP__c != \'Faturado\' AND IntegrationUpdate__c = false');
        
    }

    public void execute(Database.BatchableContext bc, List<OrderItem> orderItems) {

        CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
        if (cotacoesMoeda.size() != 0) {
            for (OrderItem oi : orderItems) {
                if (oi.ValorTotal__c != null) {
                    oi.ValorTotalUSD__c = oi.ValorTotal__c / cotacoesMoeda[0].TaxaMedia__c;
                    oi.SaldoUSD__c = oi.SaldoBRL__c / cotacoesMoeda[0].TaxaMedia__c;
                }
            }
            Database.update(orderItems);
        }

    }

    public void finish(Database.BatchableContext bc) {

        BatchProgramacaoEntregaTaxaMedia.run();
        
    }

    public static void run() {

        Database.executeBatch(new BatchOrderItemTaxaMedia(), 10000);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        BatchOrderItemTaxaMedia schedule = new BatchOrderItemTaxaMedia();
        return System.schedule('Update Item do Pedido Taxa Média', '0 0 * * * ? *', schedule);

    }
}