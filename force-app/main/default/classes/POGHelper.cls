public class POGHelper extends TriggerContext {

    public static void updateHistory(Map<Id, POG__c> oldMap, Map<Id, POG__c> newMap) {

        LogImportacao__c[] logImportacaoToInsert = new List<LogImportacao__c>();

        for (Id id : oldMap.keySet()) {

            POG__c oldPOG = oldMap.get(id);
            POG__c newPOG = newMap.get(id);
            Set<String> diffFields = new Set<String>();

            Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get('POG__c').getDescribe().fields.getMap();
            for(Schema.SObjectField sfield : fieldMap.values())
            {
                Schema.Describefieldresult dfield = sfield.getDescribe();

                String oldValue = String.valueOf(oldPOG.get(dfield.getName()));
                String newValue = String.valueOf(newPOG.get(dfield.getName()));

                if (differ(String.isBlank(oldValue) ? '' : oldValue, String.isBlank(newValue) ? '' : newValue)) {
                    diffFields.add(dfield.getName());
                }
            }

            if (!diffFields.isEmpty()) {

                String oldText = '';
                String newText = '';

                for (String field : diffFields) {
                    String fieldName = field + ' => ';
                    oldText += fieldName + oldPOG.get(field) + '\n';
                    newText += fieldName + newPOG.get(field) + '\n';
                }
                LogImportacao__c log = new LogImportacao__c(
                    RecordTypeId          = SObjectType.LogImportacao__c.getRecordTypeInfosByDeveloperName().get('POG').getRecordTypeId(),
                    CriadoPor__c          = oldPOG.CreatedById,
                    UltimaModificacao__c  = newPOG.LastModifiedById,
                    DataHoraImportacao__c = System.now(),
                    ValoresAntigos__c     = oldText,
                    ValoresNovos__c       = newText
                );
                logImportacaoToInsert.add(log);
            }
        }

        insert logImportacaoToInsert;
    }

    private static Boolean differ(String oldValue, String newValue) {
        return oldValue.equals(newValue) ? false : true;
    }

}