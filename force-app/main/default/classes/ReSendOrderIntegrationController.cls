public class ReSendOrderIntegrationController {
    @AuraEnabled
    public static String ReSendOrderIntegrationController(String recordId) {
        try{
            BatchSendFailedIntegration.sendIntegration(new List<Order>{new Order(id = recordId)});
            return 'SUCCESS';
        }catch(Exception ex){
            return ex.getMessage();
        }
    }
}