@IsTest
public class RecordTypeDataTest {
    @IsTest
    public static void simpleTest(){

        Schema.DescribeSObjectResult recordTypeInfo = Account.SObjectType.getDescribe();
        RecordTypeData recordTypeData = new RecordTypeData(recordTypeInfo.getRecordTypeInfos()[0]);
    }
}