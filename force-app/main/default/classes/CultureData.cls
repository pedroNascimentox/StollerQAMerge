public class CultureData {

    public String id;
    public String label;
    public String value;

    public CultureData(Cultura__c culture) {
        this.id    = culture.id;
        this.label = culture.descricao__c;
        this.value = culture.descricao__c;
    }

}