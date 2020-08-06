public with sharing class BatchSendFailedIntegration implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id FROM Order WHERE StatusIntegracao__c = \'Erro no envio\' ORDER BY CreatedDate ASC');
        
    }

    public void execute(Database.BatchableContext bc, List<Order> orders) {
        sendIntegration(orders);
    }

    public static void sendIntegration(List<Order> orders){
        
        Map<Id, Order> orderMap = new Map<Id, Order>();
        for (Order order : orders) {
            orderMap.put(order.Id, order);
        }

        Map<Id, IntegrationOutboundOrder.Response> responseMap = IntegrationOutboundOrder.sendOrder(new List<Id>(orderMap.keySet()));
        for (Id key : orderMap.keySet()) {
            if (responseMap.get(key).hasError) {
                orderMap.get(key).StatusIntegracao__c = Label.TentativaExcedida;
            } else {
                orderMap.remove(key);
            }
        }

        if (orderMap.size() != 0) {
            update orderMap.values();
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void run() {
        
        Database.executeBatch(new BatchSendFailedIntegration(), 100);

    }

    public void execute(SchedulableContext ctx) {
        
        run();

    }

    public static Id setSchedule() {

        BatchSendFailedIntegration schedule30 = new BatchSendFailedIntegration();
        System.schedule('Order Integration 30', '0 30 * * * ? *', schedule30);

        BatchSendFailedIntegration schedule60 = new BatchSendFailedIntegration();
        return System.schedule('Order Integration 60', '0 0 * * * ? *', schedule60);

    }    
}