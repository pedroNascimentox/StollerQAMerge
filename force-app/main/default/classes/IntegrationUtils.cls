global without sharing class IntegrationUtils {

    public static final Date MAX_DATE = Date.newInstance(4000, 12, 31);
    public static final Date MIN_DATE = Date.newInstance(1700, 01, 01);

    public static final Boolean SUCCESS_RESPONSE = true;
    public static final Boolean ERROR_RESPONSE   = false;

    public static Map<String, Boolean> booleanConversionTable;
    public static Map<String, ID> logRecordTypeIDMap;

    // --------------------------------------------------------------------------------------------------------------
    // --------------------------------------- UTILS METHODS --------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------

    public static void setTestRequest(String body) {

        body = '{ "request": ' + body + '}';
        
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        
        RestContext.request = request;

    }

    public static void setWrongTestRequest() {

        String body = 'XDzada';
        
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        
        RestContext.request = request;

    }

    public static TemplateDataIntegrationFields.ResponseList getStandardException(Exception e) {

        String errorMessage = 'MESSAGE: ' + e.getMessage() + ' \n STACK TRACE: ' + e.getStackTraceString();

        return new TemplateDataIntegrationFields.ResponseList(new List<TemplateDataIntegrationFields.Response>{(new TemplateDataIntegrationFields.Response()).error(errorMessage)});

    }

    public static List<String> getAllFieldsFromObject(String obj) {

        List<String> fieldList = new List<String>();

        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(obj).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.values())
        {
            Schema.Describefieldresult dfield = sfield.getDescribe();
            fieldList.add(dfield.getName());
        }
        
        return fieldList;

    }

    public static void checkDuplicity(Map<Id, SObject> newContextMap, String field) { // used on insert without message

        checkDuplicity(newContextMap, field, null);

    }

    public static void checkDuplicity(Map<Id, SObject> newContextMap, String field, String message) { // used on insert with message

        validateDuplicity(newContextMap, null, field, message);

    }

    public static void checkDuplicity(Map<Id, SObject> newContextMap, Map<Id, SObject> oldContextMap, String field) { // used on update without message

        checkDuplicity(newContextMap, oldContextMap, field, null);

    }

    public static void checkDuplicity(Map<Id, SObject> newContextMap, Map<Id, SObject> oldContextMap, String field, String message) { // used on update with message

        Map<Id, SObject> objectsToCheck = new Map<Id, SObject>();
        for (Id id : newContextMap.keySet()) {
            if ((String)newContextMap.get(id).get(field) != (String)oldContextMap.get(id).get(field)) {
                objectsToCheck.put(id, newContextMap.get(id));
            }
        }

        validateDuplicity(newContextMap, objectsToCheck, field, message);
        
    }

    private static void validateDuplicity(Map<Id, SObject> newContextMap, Map<Id, SObject> objectsToCheck, String field, String message) {

        List<String> objectKeyList = new List<String>();
        Set<String> invalidKeys = new Set<String>();

        if (objectsToCheck != null) {
            for (SObject obj : objectsToCheck.values()) {
                if (objectKeyList.contains((String)obj.get(field))) {
                    invalidKeys.add((String)obj.get(field));
                } else {
                    objectKeyList.add((String)obj.get(field));
                }
            }
        } else {
            for (SObject obj : newContextMap.values()) {
                if (objectKeyList.contains((String)obj.get(field))) {
                    invalidKeys.add((String)obj.get(field));
                } else {
                    objectKeyList.add((String)obj.get(field));
                }
            }
        }

        System.debug(invalidKeys);
        System.debug(objectKeyList);

        List<Id> idList = new List<Id>(newContextMap.keySet());
        SObject[] objList = Database.query('SELECT Id, ' + field + ' FROM ' + newContextMap.getSObjectType() + ' WHERE Id NOT IN :idList AND ' + field + ' IN :objectKeyList');
        if (!objList.isEmpty()) {
            for (SObject obj : objList) {
                invalidKeys.add((String)obj.get(field));
            }
        }

        if (String.isBlank(message)) {
            for (SObject obj : newContextMap.values()) {
                if (invalidKeys.contains((String)obj.get(field))) {
                    obj.addError('A chave em ' + field + ' => ' + (String)obj.get(field) + ' já existe na base!');
                }
            }
        } else {
            for (SObject obj : newContextMap.values()) {
                if (invalidKeys.contains((String)obj.get(field))) {
                    obj.addError(message);
                }
            }
        }
    }

    public static String randomNumber(Integer length) {
        if (length != null && length > 0) {
            String convertedRandom = '';
            for (Integer i = 0; i < length; i++) {
                Double rnd = Math.random();
                convertedRandom += String.valueOf(rnd).substring(String.valueOf(rnd).length() - 1);
            }
            return convertedRandom;
        } else { 
            return null;
        }
    }

    public static Map<String, String> getPicklistValues(Schema.DescribeFieldResult sObjectPickList) {
        Map<String, String> values = new Map<String, String>();
        List<Schema.PicklistEntry> pickListValues = sObjectPickList.getPicklistValues();
        for (Schema.PicklistEntry pickListValue : pickListValues) {
            values.put(pickListValue.getValue(), pickListValue.getLabel());
        }
        return values;
    }

    public static Map<String, String> getMetadataDePara(List<String> metadataNames) {
        DePara__mdt[] deParaList = [SELECT ObjectName__c, De__c, Para__c FROM DePara__mdt WHERE DeveloperName IN :metadataNames];
        Map<String, String> metadataMap = new Map<String, String>();
        for (DePara__mdt dePara : deParaList) {
            metadataMap.put(dePara.De__c, dePara.Para__c);
        }
        return metadataMap;
    }

    public static Boolean convertEmptyString(String str) {
        return ((String.isBlank(str) || str == 'null' || str == null || str == '')?true:false); 
    }
    
    public static Decimal checkDecimal(Decimal data) {
        try {
            return (data != null ? data : 0);
        } catch(TypeException e){
            return 0;
        }
    }
    
    public static Decimal stringToDecimal(String data) {
        try {
            return (data != null && String.isNotBlank(data)? Decimal.valueOf(data) : 0);
        } catch(TypeException e){
            return 0;
        }
    }

    public static Integer stringToInteger(String data) {
        return (data != null && String.isNotBlank(data) && data.isNumeric() ? Integer.valueOf(data) : null);
    }

    public static String dateToStringSAP(Date data) {
        if (data == null) return null;
        return String.valueOf(data).replace('-', '');
    }

    public static Map<String, String> reverseMapKey(Map<String, String> oldMap) {
        Map<String, String> reversedMap = new Map<String, String>();
        for (String key : oldMap.keySet()) {
            reversedMap.put(oldMap.get(key), key);
        }
        return reversedMap;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field) {

        Map<String, TemplateDataIntegrationFields.Response> responseMap = new Map<String, TemplateDataIntegrationFields.Response>();
        for (TemplateDataIntegrationFields.Response response : responseList) {
            responseMap.put(response.codigoSap, response);
        } 

        Boolean hasError = upsertRecords(upsResults, responseMap, sObjectListToUpsert, field);

        responseList.clear();

        for (TemplateDataIntegrationFields.Response response : responseMap.values()) {
            responseList.add(response);
        }

        return hasError;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, Map<String, TemplateDataIntegrationFields.Response> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field) {
        TemplateDataIntegrationFields.Response responseData;
        Boolean hasError = false;

        for(String key : responseMap.keySet()) {
            if(responseMap.get(key).status == false)
				hasError = true;
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(),
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            } else {
                hasError = true;
                List<String> errorList = new List<String>();
                for (Database.Error error : upsResult.getErrors()) {
                    errorList.add(error.getMessage().replaceAll('Campos obrigatórios ausentes|Required fields are missing', 'Valor inválido para o campo')
                                                    .replace('bad value for restricted picklist field', 'valor incorreto para campo de lista de opções restrita'));
                }

                if (responseMap.containsKey((String)objResult.get(field))) {
                    responseMap.get((String)objResult.get(field)).error(
                        String.valueOf(objResult.get(field)),
                        ' | ' + String.join(errorList, ' - '),
                        String.valueOf(objResult.getSObjectType())
                    );
                } else {
                    responseData.error(
                        String.valueOf(objResult.get(field)),
                        String.join(errorList, ' - '), 
                        String.valueOf(objResult.getSObjectType())
                    );
                }
            }
            if (!responseMap.containsKey((String)objResult.get(field))) {
                responseMap.put((String)objResult.get(field), responseData);
            }
        }
        return hasError;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field) {
        TemplateDataIntegrationFields.Response responseData;
        Boolean hasError = false;

        for(String key : responseMap.keySet()) {
            for(TemplateDataIntegrationFields.Response template : responseMap.get(key)){
                if(template.status == false)
				    hasError = true;
            }
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            } else {
                hasError = true;
                List<String> errorList = new List<String>();
                for (Database.Error error : upsResult.getErrors()) {
                    errorList.add(error.getMessage().replaceAll('Campos obrigatórios ausentes|Required fields are missing', 'Valor inválido para o campo')
                                                    .replace('bad value for restricted picklist field', 'valor incorreto para campo de lista de opções restrita'));
                }

                if (responseMap.containsKey((String)objResult.get(field))) {
                    responseData.error(
                        String.valueOf(objResult.get(field)),
                        ' | ' + String.join(errorList, ' - '),
                        String.valueOf(objResult.getSObjectType()));

                    responseMap.get((String)objResult.get(field)).add(responseData);
                } else {
                    responseData.error(
                        String.valueOf(objResult.get(field)),
                        String.join(errorList, ' - '), 
                        String.valueOf(objResult.getSObjectType())
                    );
                }
            }
            if (!responseMap.containsKey((String)objResult.get(field))) {
                responseMap.put((String)objResult.get(field), new list<TemplateDataIntegrationFields.Response>());
            }
            responseMap.get((String)objResult.get(field)).add(responseData);
        }
        return hasError;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, Map<String, IntegrationInboundOrder.Response> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field) {
        IntegrationInboundOrder.Response responseData;
        Boolean hasError = false;

        for(String key : responseMap.keySet()) {
            if(responseMap.get(key).status == false) {
				hasError = true;
            }
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new IntegrationInboundOrder.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            } else {
                hasError = true;
                List<String> errorList = new List<String>();
                for (Database.Error error : upsResult.getErrors()) {
                    errorList.add(error.getMessage().replaceAll('Campos obrigatórios ausentes|Required fields are missing', 'Valor inválido para o campo')
                                                    .replace('bad value for restricted picklist field', 'valor incorreto para campo de lista de opções restrita'));
                }

                if (responseMap.containsKey((String)objResult.get(field))) {
                    responseMap.get((String)objResult.get(field)).error(
                        String.valueOf(objResult.get(field)),
                        ' | ' + String.join(errorList, ' - '),
                        String.valueOf(objResult.getSObjectType())
                    );
                } else {
                    responseData.error(
                        String.valueOf(objResult.get(field)),
                        String.join(errorList, ' - '), 
                        String.valueOf(objResult.getSObjectType())
                    );
                }
            }
            if (!responseMap.containsKey((String)objResult.get(field))) {
                responseMap.put((String)objResult.get(field), responseData);
            }
        }
        return hasError;
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, Map<String, IntegrationInboundNotaFiscal.Response> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field) {
        IntegrationInboundNotaFiscal.Response responseData;
        Boolean hasError = false;

        for(String key : responseMap.keySet()) {
            if(responseMap.get(key).status == false) {
				hasError = true;
            }
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new IntegrationInboundNotaFiscal.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            } else {
                hasError = true;
                List<String> errorList = new List<String>();
                for (Database.Error error : upsResult.getErrors()) {
                    errorList.add(error.getMessage().replaceAll('Campos obrigatórios ausentes|Required fields are missing', 'Valor inválido para o campo')
                                                    .replace('bad value for restricted picklist field', 'valor incorreto para campo de lista de opções restrita'));
                }

                if (responseMap.containsKey((String)objResult.get(field))) {
                    responseMap.get((String)objResult.get(field)).error(
                        String.valueOf(objResult.get(field)),
                        ' | ' + String.join(errorList, ' - '),
                        String.valueOf(objResult.getSObjectType())
                    );
                } else {
                    responseData.error(
                        String.valueOf(objResult.get(field)),
                        String.join(errorList, ' - '), 
                        String.valueOf(objResult.getSObjectType())
                    );
                }
            }
            if (!responseMap.containsKey((String)objResult.get(field))) {
                responseMap.put((String)objResult.get(field), responseData);
            }
        }
        return hasError;
    }

    public static Boolean isNullOrEmpty(String str){
        return ((String.isBlank(str) || str.toLowerCase() == 'null'));
    }

    public static List<SObject> serializeToObjectList(List<TemplateDataIntegrationFields.Response> responseList) {
        
        String sObjectName = responseList[0].sObjectType;

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|__mdt|__|_', '') + 'INData');

        TemplateDataIntegrationFields.FieldData defaults = (TemplateDataIntegrationFields.FieldData) t.newInstance();

        List<SObject> sObjectList = new List<SObject>();
        for (TemplateDataIntegrationFields.Response response : responseList) {
            sObject obj = Schema.getGlobalDescribe().get(sObjectName).newSObject();
            if (!String.isBlank(response.idSalesforce)) {
                obj.Id = response.idSalesforce;
            }
            obj.put(defaults.getFieldKey(), response.codigoSap);
            sObjectList.add(obj);
        }
        return sObjectList;

    }

    public static void WSLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors) {
        WSLog(integrationName, recordTypeName, payloadIN, payloadOUT, hasAnyErrors, null);
    }

    public static void WSLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors, List<SObject> objsToUpdate) {

        Boolean shouldUseAttachmentIN  = String.isBlank(payloadIN) ? false : (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = String.isBlank(payloadOUT) ? false : (payloadOUT.length() > 100000);

        Datetime tNow = System.now();

        List<Id> sfIds = new List<Id>();
        List<String> externalIds = new List<String>();

        List<String> externalKeyFields = new List<String>{
            'OVSAP__c',
            'ExternalId__c',
            'Codigo__c',
            'IdSAP__c',
            'IDMetaSAP__c'
        };

        String externalKeyField;

        if (objsToUpdate != null && objsToUpdate.size() != 0) {
            for (String field : externalKeyFields) {
                try {
                    objsToUpdate[0].getSObjectType().newSObject().get(field);
                    externalKeyField = field;
                    break;
                } catch (Exception e) {}
            }

            for (SObject obj : objsToUpdate) {
                sfIds.add(obj.Id);
            }
            if (!String.isEmpty(externalKeyField)) {
                for (SObject obj : objsToUpdate) {
                    externalIds.add(String.valueOf(obj.get(externalKeyField)));
                }
            }
        }

        IntegrationLog__c log = new IntegrationLog__c(
            RecordTypeId      = Schema.SObjectType.IntegrationLog__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
            Integration__c    = integrationName,
            HasAttachment__c  = (shouldUseAttachmentIN || shouldUseAttachmentOUT),
            Payload_IN__c     = (shouldUseAttachmentIN  ? '' : payloadIN),
            Payload_OUT__c    = (shouldUseAttachmentOUT ? '' : payloadOUT),
            Status__c         = (hasAnyErrors ? 'ERROR' : 'SUCCESS'),
            ExecuteDate__c    = tNow,
            SalesforceId__c   = String.join(sfIds, '-'),
            ExternalId__c     = String.join(externalIds, '-')
        );

        try {
            insert log;

            if (objsToUpdate != null && objsToUpdate.size() != 0) {
                List<SObject> correctSObjects = new List<SObject>();
                for (SObject obj : objsToUpdate) {
                    // System.debug('obj => ' + obj);
                    if (!String.isBlank(obj.Id)) {
                        obj.put('IntegrationLog__c', log.Id);
                    }
                }

                Database.update(objsToUpdate, false);
            }

            // Maximum Size for a String
            
            Boolean shouldUseAttachment = shouldUseAttachmentIN || shouldUseAttachmentOUT;
            
            if (shouldUseAttachment){
                createAttachment(log.Id, integrationName, shouldUseAttachmentIN? 'IN' : 'OUT', log.Name, String.valueOf(tNow), shouldUseAttachmentIN? payloadIN : payloadOUT);
            }
            
        } catch(Exception e) {
            System.debug('EXCEPTION ON LOG - Please review parameters - ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static void createAttachment(String recordId, String integrationName, String inOrOut, String logName, String timeAsString, String payload){    	
    	insert new Attachment(Name = 'LOG-' + integrationName + '-' + inOrOut + '-' + timeAsString + '.txt', Body = Blob.valueOf(payload), ParentId = recordId);
    }

    public static boolean WSLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors, IntegrationLog__c log, Attachment att, SObject obj) {

        Boolean shouldUseAttachmentIN  = String.isBlank(payloadIN) ? false : (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = String.isBlank(payloadOUT) ? false : (payloadOUT.length() > 100000);

        Datetime tNow = System.now();

        log.RecordTypeId      = Schema.SObjectType.IntegrationLog__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        log.Integration__c    = integrationName;
        log.HasAttachment__c  = (shouldUseAttachmentIN || shouldUseAttachmentOUT);
        log.Payload_IN__c     = (shouldUseAttachmentIN  ? '' : payloadIN);
        log.Payload_OUT__c    = (shouldUseAttachmentOUT ? '' : payloadOUT);
        log.Status__c         = (hasAnyErrors ? 'ERROR' : 'SUCCESS');
        log.ExecuteDate__c    = tNow;
        log.SalesforceId__c   = obj.Id;
        log.ExternalId__c     = String.valueOf(obj.get('ExternalId__c'));

        try {

            // Maximum Size for a String
            
            Boolean shouldUseAttachment = shouldUseAttachmentIN || shouldUseAttachmentOUT;
            
            if (shouldUseAttachment){
                createAttachment(log.Id, integrationName, shouldUseAttachmentIN? 'IN' : 'OUT', log.Name, String.valueOf(tNow), shouldUseAttachmentIN? payloadIN : payloadOUT, att);
                return true;
            }
            
        } catch(Exception e) {
            System.debug('EXCEPTION ON LOG - Please review parameters - '+e.getMessage()+' - '+e.getStackTraceString());
        }
        return false;
    }

    @TestVisible
    private static void createAttachment(String recordId, String integrationName, String inOrOut, String logName, String timeAsString, String payload, Attachment att){
        att.Name = 'LOG-' + integrationName + '-' + inOrOut + '-' + timeAsString + '.txt';
        att.Body = Blob.valueOf(payload);
        att.ParentId = recordId;
    }

    public static String clearNonDigits(String data){
        if (data == null) return null;

        return data.replaceAll('\\D', '');
    }

    public static HttpResponse sendAuthRequest(SAPCredential__mdt data, String body) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setEndpoint(data.URL__c);
        Blob headerInfo = Blob.valueOf(data.Username__c + ':' + data.Password__c);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerInfo));
        request.setBody(body);
        // System.debug('INFO => ' + data);
        // System.debug('INFO.USERNAME => ' + data.Username__c);
        // system.debug('ENDPOINT => ' + request.getEndpoint());
        // system.debug('BODY => ' + request.getBody());
        // system.debug('HEADER => ' + request.getHeader('Authorization'));
        return http.send(request);

    }

    public static Boolean isStatusSuccess(Integer value) {
        if (value == 200 || value == 201) {
            return true;
        }
        return false;
    }

    public static String formatCNPJ(String str){
        if (str == null) return null;

        // Clear anything that's not a number
        str = str.replaceAll('\\D', '');
        if (str.length() != 14){
            return null;
        }

        return String.format('{0}.{1}.{2}/{3}-{4}', new List<String>{
            str.substring(0, 2),
            str.substring(2, 5),
            str.substring(5, 8),
            str.substring(8, 12),
            str.substring(12)
        });
    }

    // public static String formatCPF(String str) {
    //     if (str == null) return null;

    //     // Clear anything that's not a number
    //     str = str.replaceAll('\\D', '');
    //     if (str.length() != 11){
    //         return null;
    //     }
    //     return String.format('{0}.{1}.{2}-{3}', new List<String>{
    //         str.substring(0, 2),
    //         str.substring(2, 5),
    //         str.substring(5, 8),
    //         str.substring(8, 10)
    //     });
    // }
    
    public static Double stringToDouble(String data){
        return (data != null && String.isNotBlank(data) ? Double.valueOf(data) : null);
    }
    
    public static Long stringToLong(String data){
        return (data != null && String.isNotBlank(data) ? Long.valueOf(data) : null);
    }

    private static void createConversionTable(){
        if (booleanConversionTable == null || booleanConversionTable.size() <= 0){
            booleanConversionTable = new Map<String, Boolean>{
                'TRUE'  => true,
                'X'     => true,
                '1'     => true,
                '2'     => false,
                'S'     => true,
                'Sim'   => true,
                'FALSE' => false,
                ''      => false,
                '0'     => false,
                'N'     => false,
                'Não'   => false
            };
        }
    }

    public static Boolean stringToBoolean(String data){
        if (data == null){
            return false;
        }else{
            // Making sure the table is instantiated.
            createConversionTable();

            Boolean bool = booleanConversionTable.get(data.toUpperCase());
            if (bool != null){
                return bool;
            }else{
                throw new ConversionException('Invalid value for Boolean conversion: "'+data+'" || Possible values for Boolean are: '+booleanConversionTable.keySet());
            }
        }
    }
    
    public static Date stringToDate(String data) {
        
        if (String.isBlank(data) || data.containsOnly('0')) return null;

        data = data.replaceAll('\\s(\\w|\\W)+', ''); // deletes anything after whitespace (hours, minutes and seconds)

        if (data.length() == 10) {
            if ((data.substring(4, 5) != '-' || data.substring(7, 8) != '-') && data.replace('-', '').length() != 8) {
                throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
            } else {
                data = data.replace('-', '');
            }
        }

        if (!data.isNumeric() || data.length() != 8){
            throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
        }

        // if (data.length() == 8 && data.isNumeric()) {
            try {
                Date dt = Date.newInstance(
                    Integer.valueOf(data.substring(0,4)),
                    Integer.valueOf(data.substring(4,6)),
                    Integer.valueOf(data.substring(6,8))
                );
                return ((dt > MAX_DATE) ? MAX_DATE : (dt < MIN_DATE ? MIN_DATE : dt));
            } catch(Exception e) {
                throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
            }
        // } else {
        //     throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
        // }
    }

    public static Time stringToTime(String str){
        if (String.isBlank(str)) return null;
        
        if (str.length() == 8){
            if (str.substring(2, 3) != ':' || str.substring(5, 6) != ':') {
                throw new ConversionException('Invalid value for Time conversion: "'+str+'"');
            } else {
                str = str.replace(':', '');
            }
        }

        if (str.length() != 6 || !str.isNumeric()){
            throw new ConversionException('Invalid value for Time conversion: "'+str+'"');
        }

        return Time.newInstance(
            Integer.valueOf(str.substring(0, 2)),
            Integer.valueOf(str.substring(2, 4)),
            Integer.valueOf(str.substring(4, 6)),
            0
        );
    }

    // IntegrationUtils.getPicklistValues(Account.Status__c)
    // public static Set<String> getPicklistValues(SObjectField field) {
    //     Set<String> options = new Set<String>();
    //     for(Schema.PicklistEntry picklist : field.getDescribe().getPicklistValues()) {
    //         options.add(picklist.getValue());
    //     }
    //     return options;
    // }

    public static String createXmlTag(String tagName, String tagValue){
        return createXmlTag(tagName, tagValue, null, false);
    }

    public static String createXmlTag(String tagName, String tagValue, String namespace) {
        return createXmlTag(tagName, tagValue, namespace, false);
    }

    public static String createXmlTag(String tagName, String tagValue, Boolean upperCase) {
        return createXmlTag(tagName, tagValue, null, upperCase);
    }

    // IntegrationUtils.createXmlTag(AccountName, 'Teste LTDA', 'xsi')
    // returns <xsi:AccountName>Teste LTDA</xsi:AccountName>
    // IntegrationUtils.createXmlTag(AccountName, '', 'xsi')
    // returns <xsi:AccountName/>
    public static String createXmlTag(String tagName, String tagValue, String namespace, Boolean upperCase){
        Boolean isEmptyValue = String.isBlank(tagValue);
        String xmlTag = '<'+((namespace != null && namespace.length() > 0) ? namespace+':' : '')+tagName+(isEmptyValue ? '/' : '')+'>';

        // In case we have an empty value to send
        if (isEmptyValue) return xmlTag;

        xmlTag += escapeXmlSpecialChars(upperCase ? tagValue.toUpperCase() : tagValue);
        xmlTag += '</'+((namespace != null && namespace.length() > 0) ? namespace+':' : '')+tagName+'>';
        return xmlTag;

        // return '<'+((namespace != null && namespace.length() > 0) ? namespace+':' : '')+tagName+'>'+(upperCase ? replaceSpecialChars(tagValue.toUpperCase()) : replaceSpecialChars(tagValue))+'</'+((namespace != null && namespace.length() > 0) ? namespace+':' : '')+tagName+'>';
    }

    public static String fetchDBErrorMessages(List<Database.Error> errList){
        String fullErrorMessage = '';
        for (Database.Error err : errList){
            fullErrorMessage += (fullErrorMessage.length() > 0 ? '; ': '')+'Error on field(s):'+err.getFields()+' | Error description: '+err.getMessage();
        }

        return fullErrorMessage;
    }

    public static String escapeXmlSpecialChars(String str){
        return (str != null ? str.escapeXml() : '');
    }
    
    public static String leftZeroesTrim(String str){
        if(str == null) return null;
        Integer index = str.indexOfAnyBut('0');
        if (index == -1 || index == null){
            return str;
        }else{
            return str.substring(index);
        }
    }
    
    public static String leftZeroesFix(Long it, Integer zeroesToTheLeft){
        String num = String.valueOf(it);
		Integer size = num.length() + zeroesToTheLeft;
        while (num.length() < size){
            num = '0'+num;
        }

        return num;
    }
    
    public static String leftZeroesFill(Long it, Integer numberLength){
        String num = String.valueOf(it);
        while (num.length() < numberLength){
            num = '0'+num;
        }

        return num;
    }

    public static String fileSizeToString(Long value){
    	/* Converts integer bytes into KB, MB or GB metric */
        if (value < 1024){
          return string.valueOf(value) + ' Bytes';
        }else{
        	if (value >= 1024 && value < (1024*1024)){
		        //KB
		        Decimal kb = Decimal.valueOf(value);
		        kb = kb.divide(1024,2);
		        return string.valueOf(kb) + ' KB';
        	}else{
        		if (value >= (1024*1024) && value < (1024*1024*1024)){
		        	//MB
		        	Decimal mb = Decimal.valueOf(value);
		        	mb = mb.divide((1024*1024),2);
		        	return string.valueOf(mb) + ' MB';
		        }else{
			        //GB
			        Decimal gb = Decimal.valueOf(value);
			        gb = gb.divide((1024*1024*1024),2);
			        return string.valueOf(gb) + ' GB';
		        }
    		}
    	}
    }

    public class ConversionException extends Exception{}

    public static List<Messaging.SendEmailResult> sendMailWithContentVersion(List<ContentVersion> cVersionList, String title, String email){
        try{

            List<Messaging.SingleEmailMessage> semList = new List<Messaging.SingleEmailMessage>();
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(new List<String>{email});
            
            mail.setSenderDisplayName(title);

            if (cVersionList != null && !cVersionList.isEmpty()) {
                //anexando arquivos
                List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
                String[] titleList = new List<String>();
                for(ContentVersion item : cVersionList){
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    titleList.add(item.Title);
                    efa.setFileName((item.Title.contains('.') ? item.Title : item.Title+'.'+item.FileExtension));
                    efa.setBody(item.VersionData);
                    efaList.add(efa);
                }

                mail.setPlainTextBody(String.join(titleList, ' - '));
                
                mail.setFileAttachments(efaList);
            }

            semList.add(mail);
            
            if(semList.size() > 0){
                return Messaging.sendEmail(semList);
            }

            return null;
        }catch(Exception ex){
            System.debug(ex);
            return null;
        }
    }

    public static Messaging.SendEmailResult sendEmail(String bodyText, String title, String addressToSend){
        try{

            List<Messaging.SingleEmailMessage> semList = new List<Messaging.SingleEmailMessage>();
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(new List<String>{addressToSend});
            
            mail.setSubject(title);

            mail.setPlainTextBody(bodyText);

            semList.add(mail);
            
            if(semList.size() > 0){
                return Messaging.sendEmail(semList)[0];
            }

            return null;
        }catch(Exception ex){
            System.debug(ex);
            return null;
        }
    }
}