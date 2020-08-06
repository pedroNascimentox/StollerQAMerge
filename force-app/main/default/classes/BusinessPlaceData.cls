public class BusinessPlaceData {
    
    public String id;
    public String name;
    public String code;
    public String description;
    
    public BusinessPlaceData(LocalNegocio__c businessPlace) {
        this.id          = businessPlace.id;
        this.name        = businessPlace.name;
        this.code        = businessPlace.codigo__c;
        this.description = businessPlace.descricao__c;
    }
}