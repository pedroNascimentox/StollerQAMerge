public class FreightTypeData {
    
    public String name;
    public String value;
    public Boolean isDefault;

    public FreightTypeData(String name, String value) {
        this.name = name;
        this.value = value;
    }
    
    public FreightTypeData(String name, String value, Boolean isDefault) {
        this.name = name;
        this.value = value;
        this.isDefault = isDefault;
    }
}