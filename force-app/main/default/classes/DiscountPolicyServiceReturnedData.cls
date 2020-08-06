public class DiscountPolicyServiceReturnedData extends ResultTemplate{

    public Map<String, DiscountPolicyServiceData> data;

    public DiscountPolicyServiceReturnedData(){
        this.data = new Map<String, DiscountPolicyServiceData>();
    }
    
    public DiscountPolicyServiceReturnedData(PoliticaDesconto__c discountPolicy) {
        this.data    = new Map<String, DiscountPolicyServiceData>{discountPolicy.produto__c => new DiscountPolicyServiceData(discountPolicy)};
        this.hasErrors = false;
        this.message   = 'Success';
    }

    public DiscountPolicyServiceReturnedData(String message) {
        this.data    = null;
        this.hasErrors = true;
        this.message   = message;
    }

    public void putAllFrom(DiscountPolicyServiceReturnedData mapToAddResultFrom){
        if(mapToAddResultFrom.data != null){
            for(Id id : mapToAddResultFrom.data.keySet()){
                if(this.data != null & this.data.containsKey(id)){
                    mapToAddResultFrom.data.remove(id);
                }
            }
            this.data.putAll(mapToAddResultFrom.data);
        }
    }
}