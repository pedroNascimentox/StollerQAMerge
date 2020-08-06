public class RecordTypeData {

    public String id;
    public String name;
    public String developerName;
    
    public RecordTypeData(Schema.RecordTypeInfo recordTypeInfo) {
        this.id            = recordTypeInfo.getRecordTypeId();
        this.name          = recordTypeInfo.getName();
        this.developerName = recordTypeInfo.getDeveloperName();
    }
}