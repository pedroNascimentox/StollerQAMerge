public class ReSendOrderController {
    @AuraEnabled
    public static String sendIntegrationOrder(String recordId) {
        try{
            Order ord = [SELECT id, OVSAP__c FROM Order WHERE id = :recordId LIMIT 1];
            if(ord.OVSAP__C == null){
                BatchSendFailedIntegration.sendIntegration(new List<Order>{ord});
                return 'SUCCESS';
            }else{
                return Label.IntegratedOrder;
            }
        }catch(Exception ex){
            return ex.getMessage();
        }
    }
}