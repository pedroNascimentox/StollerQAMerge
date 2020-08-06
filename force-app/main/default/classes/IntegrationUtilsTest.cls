@isTest
public with sharing class IntegrationUtilsTest {
    @isTest
    public static void isNullOrEmptyTest() {

        System.assertEquals(true, IntegrationUtils.isNullOrEmpty(''));
        System.assertEquals(false, IntegrationUtils.isNullOrEmpty('test'));

    }
    
    @isTest
    public static void stringToDecimalTest() {

        System.assertEquals(0, IntegrationUtils.stringToDecimal(null));
        System.assertEquals(10.00, IntegrationUtils.stringToDecimal('10.00'));

    }

    @isTest
    public static void upsertRecordsTest() {

        Account acc = new Account(
            Name = 'testName',
            ExternalId__c = '123'
        );
        List<Account> accountListToUpsert = new List<Account>{acc};
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        Boolean hasError = IntegrationUtils.upsertRecords(Database.upsert(accountListToUpsert, Account.ExternalId__c, false), responseList, accountListToUpsert, Account.ExternalId__c);

        Account a = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];

        // System.debug('account => ' + a);
        System.assertEquals(false, hasError);

    }
    
    @isTest
    public static void WSLogTest() {

        String payloadIN = 'TestPayloadIN';
        String payloadOUT = 'TestPayloadOUT';
        for(Integer i = 0; i < 10001; i++) {
            payloadIN += 'TestPayloadIN';
            payloadOUT += 'TestPayloadOUT';
        }

        IntegrationUtils.WSLog('Account', 'Inbound', payloadIN, payloadOUT, false);

        List<IntegrationLog__c> logs = [SELECT Id FROM IntegrationLog__c WHERE Integration__c = 'Account'];

        System.assertEquals(1, logs.size());

    }
    
    @isTest
    public static void clearNonDigitsTest() {

        System.assertEquals('0123', IntegrationUtils.clearNonDigits('0123'));
        System.assertEquals('023', IntegrationUtils.clearNonDigits('0i23'));

    }
    
    @isTest
    public static void formatCNPJTest() {

        // System.debug(IntegrationUtils.formatCNPJ('12345678912345'));
        System.assertEquals('12.345.678/9123-45', IntegrationUtils.formatCNPJ('12345678912345'));
        System.assertEquals(null, IntegrationUtils.formatCNPJ('error'));

    }
    
    @isTest
    public static void stringToIntegerTest() {

        System.assertEquals(null, IntegrationUtils.stringToInteger(null));
        System.assertEquals(10, IntegrationUtils.stringToInteger('10'));

    }
    
    @isTest
    public static void stringToDoubleTest() {

        System.assertEquals(null, IntegrationUtils.stringToDouble(null));
        System.assertEquals(10.00, IntegrationUtils.stringToDouble('10.00'));

    }

    @isTest
    public static void stringToLongTest() {

        System.assertEquals(null, IntegrationUtils.stringToLong(null));
        System.assertEquals(Long.valueOf('123456789123456789'), IntegrationUtils.stringToLong('123456789123456789'));

    }

    @isTest
    public static void stringToBooleanTest() {

        System.assertEquals(true, IntegrationUtils.stringToBoolean('x'));
        System.assertEquals(false, IntegrationUtils.stringToBoolean(''));

    }

    @isTest
    public static void stringToDateTest() {

        Boolean hasError1 = false;
        try {
            IntegrationUtils.stringToDate('201901011');
        }
        catch(Exception e) {
            hasError1 = true;
        }
        System.assertEquals(true, hasError1);

        Boolean hasError2 = false;
        try {
            IntegrationUtils.stringToDate('2019a01901');
        }
        catch(Exception e) {
            hasError2 = true;
        }
        System.assertEquals(true, hasError2);

        System.assertEquals(Date.newInstance(2019, 01, 01), IntegrationUtils.stringToDate('2019-01-01'));

    }

    @isTest
    public static void stringToTimeTest() {

        Boolean hasError1 = false;
        try {
            System.debug(IntegrationUtils.stringToTime('00'));
        }
        catch(Exception e) {
            hasError1 = true;
        }
        System.assertEquals(true, hasError1);

        Boolean hasError2 = false;
        try {
            System.debug(IntegrationUtils.stringToTime('00:0000o'));
        }
        catch(Exception e) {
            hasError2 = true;
        }
        System.assertEquals(true, hasError2);

        System.assertEquals(null, IntegrationUtils.stringToTime(''));
        System.assertEquals(Time.newInstance(00, 00, 00, 0), IntegrationUtils.stringToTime('000000'));
        System.assertEquals(Time.newInstance(00, 00, 00, 0), IntegrationUtils.stringToTime('00:00:00'));

    }

    @isTest
    public static void createXmlTagTest() {

        System.assertEquals('<namespaceTest:tagNameTest>TAGVALUETEST</namespaceTest:tagNameTest>',
                            IntegrationUtils.createXmlTag('tagNameTest', 'tagValueTest', 'namespaceTest', true));
        
        System.assertEquals('<tagNameTest>TAGVALUETEST</tagNameTest>', 
                            IntegrationUtils.createXmlTag('tagNameTest', 'tagValueTest', true));

        System.assertEquals('<namespaceTest:tagNameTest>tagValueTest</namespaceTest:tagNameTest>',
                            IntegrationUtils.createXmlTag('tagNameTest', 'tagValueTest', 'namespaceTest'));

        System.assertEquals('<tagNameTest>tagValueTest</tagNameTest>',
                            IntegrationUtils.createXmlTag('tagNameTest', 'tagValueTest'));

    }

    @isTest
    public static void fetchDBErrorMessagesTest() {

        List<Database.Error> errList = Database.insert(new Account(), false).getErrors();

        System.assertEquals('Error on field(s):(Name, ExternalId__c) | Error description: Campos obrigatórios ausentes: [Name, ExternalId__c]', IntegrationUtils.fetchDBErrorMessages(errList));

    }

    @isTest
    public static void escapeXmlSpecialCharsTest() {

        System.assertEquals('', IntegrationUtils.escapeXmlSpecialChars(null));

        System.assertEquals('&lt;test&gt;', IntegrationUtils.escapeXmlSpecialChars('<test>'));

    }

    @isTest
    public static void leftZeroesTrimTest() {
        
        System.assertEquals(null, IntegrationUtils.leftZeroesTrim(null));
        
        System.assertEquals('', IntegrationUtils.leftZeroesTrim(''));

        System.assertEquals('1', IntegrationUtils.leftZeroesTrim('00001'));

    }

    @isTest
    public static void leftZeroesFixTest() {

        System.assertEquals('0123456789', IntegrationUtils.leftZeroesFix(Long.valueOf('123456789'), 1));

    }

    @isTest
    public static void leftZeroesFillTest() {

        System.assertEquals('00123456789', IntegrationUtils.leftZeroesFill(Long.valueOf('123456789'), 11));

    }

    @isTest
    public static void fileSizeToStringTest() {

        System.assertEquals('9 Bytes', IntegrationUtils.fileSizeToString(Long.valueOf('9')));
        
        System.assertEquals('9.76 KB', IntegrationUtils.fileSizeToString(Long.valueOf('9999')));
        
        System.assertEquals('9.54 MB', IntegrationUtils.fileSizeToString(Long.valueOf('9999999')));

        System.assertEquals('9.31 GB', IntegrationUtils.fileSizeToString(Long.valueOf('9999999999')));

    }
    
}