public with sharing class AccountHelper extends TriggerContext {
    public static void getCredit(List<Account> context, Map<Id, Account> oldMap, Boolean isInsert) {
        /*Set<Id> accIdSet = new Set<Id>();
        for(Account acc : context){
            if(acc.MatrizCredito__c != null && (isInsert || ((acc.MatrizCredito__c != oldMap.get(acc.Id).MatrizCredito__c)))){
                accIdSet.add(acc.MatrizCredito__c);
            }
        }
        Map<Id, Account> parentMap = new Map<Id, Account>([SELECT id, SaldoLimiteCredito__c, LimiteCreditoTotal__c FROM Account WHERE id IN : accIdSet]);
        for(Account acc : context){
            if(accIdSet.contains(acc.MatrizCredito__c) && parentMap.containsKey(acc.MatrizCredito__c)){
                acc.SaldoLimiteCredito__c = parentMap.get(acc.MatrizCredito__c).SaldoLimiteCredito__c;
                acc.LimiteCreditoTotal__c = parentMap.get(acc.MatrizCredito__c).LimiteCreditoTotal__c;
            }
        }*/
    }
    public static void updateCredit(Map<Id, Account> context, Map<Id, Account> oldMap) {
        /*Set<Id> accIdSet = new Set<Id>();
        for(Account acc : context.values()){
            if(acc.SaldoLimiteCredito__c != oldMap.get(acc.Id).SaldoLimiteCredito__c){
                accIdSet.add(acc.Id);
            }
        }
        Map<Id, Account> parentMap = new Map<Id, Account>([SELECT id, SaldoLimiteCredito__c, LimiteCreditoTotal__c, MatrizCredito__c FROM Account WHERE MatrizCredito__c IN : accIdSet]);
        List<Account> accList = new List<Account>();
        for(Account acc : parentMap.values()){
            if(accIdSet.contains(acc.MatrizCredito__c)){
                acc.SaldoLimiteCredito__c = context.get(acc.MatrizCredito__c).SaldoLimiteCredito__c;
                acc.LimiteCreditoTotal__c = context.get(acc.MatrizCredito__c).LimiteCreditoTotal__c;
                accList.add(acc);
            }
        }
        if(!accList.isEmpty()){
            AccountHelper.disableTrigger();
            update accList;
            AccountHelper.enableTrigger();
        }*/
    }
}