public class CancellingTypeData {
    
    public String name;
    public String value;
    public Boolean isDefault;

    public CancellingTypeData(String name, String value) {
        this.name = name;
        this.value = value;
    }
    
    public CancellingTypeData(String name, String value, Boolean isDefault) {
        this.name = name;
        this.value = value;
        this.isDefault = isDefault;
    }
}