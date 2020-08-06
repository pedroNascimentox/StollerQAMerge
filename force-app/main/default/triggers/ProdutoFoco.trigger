trigger ProdutoFoco on ProdutoFoco__c (before insert, before update, after insert, before delete) {
    if (ProdutoFocoHelper.IsTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT{
                ProdutoFocoHelper.checkBeforeInsert(Trigger.new);
                ProdutoFocoHelper.checkProdFamilyBeforeInsert(Trigger.new);    
            }
            when AFTER_INSERT {
                ProdutoFocoHelper.insertFamillyProducts(Trigger.new);                                           
            }
            when BEFORE_UPDATE{
                ProdutoFocoHelper.updateFamillyProducts(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE{
                ProdutoFocoHelper.checkBeforeDelete(Trigger.old);
            }
        }
    }
}