public with sharing class FactoryDataIntegration {
    
    public static void convertSObject(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldData> fieldDataList, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> listToUpsert, Map<String, Id> lookups) {

        Map<String, TemplateDataIntegrationFields.Response> responseMap = new Map<String, TemplateDataIntegrationFields.Response>();

        convertSObject(sObj, service, fieldDataList, responseMap, listToUpsert, lookups);

        for (TemplateDataIntegrationFields.Response response : responseMap.values()) {
            responseList.add(response);
        }

    }

    public static void convertSObject(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldData> fieldDataList, Map<String, TemplateDataIntegrationFields.Response> responseMap, List<SObject> listToUpsert, Map<String, Id> lookups) {

        String sObjectName = String.valueOf(sObj.getSObjectType());

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|__mdt|__|_', '') +service+ 'Data');

        if (t == null) {
            throw new FactoryDataIntegrationException('Invalid defaults class.');
        }

        TemplateDataIntegrationFields.FieldData defaults = (TemplateDataIntegrationFields.FieldData) t.newInstance();

        for (TemplateDataIntegrationFields.FieldData obj : fieldDataList) {
            validateObject(defaults.getFieldId(), defaults.getFieldKey(), obj.serialize(lookups), listToUpsert, responseMap, defaults.getRequiredFields(obj));
        }
    }

    @TestVisible
    private static void validateObject(String fieldId, String fieldKey, SObject data, List<SObject> listToUpsert, Map<String, TemplateDataIntegrationFields.Response> responseMap, List<String> requiredField) {

        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        
        for (String field : requiredField) {
            // System.debug('field => ' + field);
            // System.debug('is empty? => ' + IntegrationUtils.convertEmptyString(String.valueOf(data.get(field))));
            // System.debug('value => ' + String.valueOf(data.get(field)));
            if (IntegrationUtils.convertEmptyString(String.valueOf(data.get(field)))){
                if (responseMap.containsKey((String)data.get(fieldKey))) {
                    responseMap.get((String)data.get(fieldKey)).error(
                        String.valueOf(data.get(fieldKey)),
                        ' | Valor inválido para o campo obrigatório: ' + field,
                        String.valueOf(listToUpsert.getSObjectType())
                    );
                } else {
                    if (String.isNotEmpty((String)data.get(fieldId))){
                        response.error(
                            String.valueOf(data.get(fieldId)),
                            String.valueOf(data.get(fieldKey)),
                            'Valor inválido para o campo obrigatório: ' + field,
                            String.valueOf(listToUpsert.getSObjectType())
                        );
                    } else {
                        response.error(
                            String.valueOf(data.get(fieldKey)),
                            'Valor inválido para o campo obrigatório: ' + field,
                            String.valueOf(listToUpsert.getSObjectType())
                        );
                    }
                    responseMap.put(String.valueOf(data.get(fieldKey)), response);
                }
            }
        }
        
        if(response.status) {
            listToUpsert.add(data);
        }
    }

    public static void addLookup(String objectType, String externalKey, String fieldKey, List<String> externalIdList, Map<String, Id> lookups) {

        if (!IntegrationUtils.getAllFieldsFromObject(objectType).contains(externalKey)) {
            throw new FactoryDataIntegrationException('O campo ' + externalKey + ' não existe no objeto ' + objectType);
        }

        List<SObject> receivedLookups = Database.query(String.format('SELECT Id '+(externalKey != 'Id' ? ', {0}': '')+' FROM {1} WHERE {0} IN :externalIdList AND {0} != NULL', 
                                                                    new List<String>{externalKey, objectType}));

        for (SObject obj : receivedLookups){
            if (!String.isBlank((String)obj.get(externalKey))) {
                lookups.put(fieldKey + obj.get(externalKey), obj.Id);
            }
        }
    }

    public class FactoryDataIntegrationException extends Exception {
    }
}