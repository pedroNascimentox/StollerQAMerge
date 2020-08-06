public class CondicaoPagamentoHelper extends TriggerContext {
    public static void setType(List<CondicaoPagamento__c> paymentConditions){
        List<String> paymentConditionTypeValues = new List<String>(IntegrationUtils.getPicklistValues(CondicaoPagamento__c.Tipo__c.getDescribe()).keySet());

        Pattern paymentConditionPattern = Pattern.compile(
            '(' + String.join(paymentConditionTypeValues, '|') + ')' + '[a-zA-Z0-9]*(\\d{1,})' // (A|B|C)[a-zA-Z0-9]*(\d{1,})
        );
        for(CondicaoPagamento__c paymentCondition : paymentConditions){
            
            Matcher matcher = paymentConditionPattern.matcher(paymentCondition.ExternalId__c);
            if (matcher.matches()){

                String type = matcher.group(1);
                try {
                    paymentCondition.Tipo__c = type;
                } catch(Exception e) {
                    paymentCondition.addError(e.getMessage());
                }
                
            } else {
                paymentCondition.addError('O tipo do registro não foi encontrado no Id Externo: ' + paymentCondition.ExternalId__c);
            }
        }
    }
}