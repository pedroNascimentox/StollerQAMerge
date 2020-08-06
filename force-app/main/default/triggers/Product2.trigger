trigger Product2 on Product2 (after insert) {
    if (ProductHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                ProductHelper.createStandardEntries(Trigger.new);
            }
        }
    } 
}