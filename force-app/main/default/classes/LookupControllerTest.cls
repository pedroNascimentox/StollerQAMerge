@IsTest
public class LookupControllerTest {
    @IsTest
    static void searchLookupTest() {

        Account account = (Account)TestFactory.createSObject(new Account(
            Name = 'Reginaldo Basílio'
        ));
        insert account;

        String searchTerm = 'Reginaldo';
        String tableName  = 'Account';
        String fieldName  = 'Name';
        String queryFilterJSON = '{"Name" : "Reginaldo Basílio"}';

        LookupController.searchLookupByName('Account','Account');
        LookupController.searchLookupByField(searchTerm,tableName,fieldName,queryFilterJSON);

    }
}