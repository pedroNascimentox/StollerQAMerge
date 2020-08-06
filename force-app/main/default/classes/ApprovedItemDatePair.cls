public class ApprovedItemDatePair {
    
    public Date previousBillingDate;
    public Date previousDeliveryDate;
    
    public Date updatedBillingDate;
    public Date updatedDeliveryDate;
    
    public Boolean hasValueChanges;
    
    public Id itemId;
    public OpportunityLineItem item;

    public ApprovedItemDatePair(OpportunityLineItem item){
        this.item    = item;
        this.itemId  = item.id;
        this.previousBillingDate  = item.dataFaturamento__c;
        this.previousDeliveryDate = item.dataEntrega__c;

        this.calcUpdatedDates();

        this.hasValueChanges = this.updatedBillingDate != this.previousBillingDate || 
                               this.updatedDeliveryDate != this.previousDeliveryDate;
    }

    public void calcUpdatedDates(){

        System.debug('Integer.valueOf(item.itinerario__c) => ' + Integer.valueOf(item.itinerario__c));

        this.updatedDeliveryDate = OpportunityAppController.getMinimumDate(
            Integer.valueOf(item.itinerario__c)
        );

        System.debug('this.updatedDeliveryDate => ' + this.updatedDeliveryDate);
        
        this.updatedBillingDate = OpportunityAppController.getBillingDate(
            this.updatedDeliveryDate,
            Integer.valueOf(item.itinerario__c)
        );

        System.debug('updatedBillingDate => ' + updatedBillingDate);

        if (this.previousBillingDate >= this.updatedBillingDate){
            this.updatedBillingDate = this.previousBillingDate;
        }

        if (this.previousDeliveryDate >= this.updatedDeliveryDate){
            this.updatedDeliveryDate = this.previousDeliveryDate;
        }
    }

    public OpportunityLineItem updateItem(){
        this.item.dataFaturamento__c = this.updatedBillingDate;
        this.item.dataEntrega__c = this.updatedDeliveryDate;

        return this.item;
    }
}