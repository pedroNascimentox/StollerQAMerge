public class LookupController{

    @RemoteAction
    public static List<ResultData> searchLookupByField(String searchTerm, String tableName, String fieldName, String queryFilterJSON){
        String columnWhereClause = '%' + searchTerm + '%';
        Map<String, String> columnToValue;
        String queryFilter = '';
        if (queryFilterJSON != null){
            columnToValue = (Map<String, String>) JSON.deserialize(queryFilterJSON, Map<String, String>.class);
            List<String> queryFilterList = new List<String>();
            for(String key : columnToValue.keySet()){
                if (columnToValue.get(key) == 'true' ||
                    columnToValue.get(key) == 'false')
                    queryFilterList.add(key + ' = ' +  columnToValue.get(key));
                else
                    queryFilterList.add(key + ' = ' + '\'' + columnToValue.get(key) + '\'');
            }
            queryFilter = String.join(queryFilterList, ' AND ') + ' AND ';
        }
        List<SObject> queryResult = Database.query(
            String.format('SELECT id, name FROM {0} WHERE {1} {2} LIKE : columnWhereClause LIMIT 900', new List<String> {
                tableName, queryFilter, fieldName
            })
        );
        return parseRowsToResult(queryResult, tableName);
    }
 
    @RemoteAction
    public static List<ResultData> searchLookupByName(String searchTerm, String tableName){
        return searchLookupByField(searchTerm, tableName, 'name', null);
    }


    private static List<ResultData> parseRowsToResult(List<SObject> selectResult, String tableName){
        List<ResultData> toReturn = new List<ResultData>();
        for(SObject row : selectResult){
            toReturn.add(new ResultData(row, tableName));
        }
        return toReturn;
    }
    public class ResultData{
        public String id;
        public String name;
        public List<String> returningFields;
        public ResultData(SObject row, String tableName){
            String name = (String) row.get('name');
            this.id = row.id;
            this.name = name;
            this.returningFields = new List<String>{
                Schema.getGlobalDescribe().get(tableName).getDescribe().getLabel(), name
            };
        }
    }
}