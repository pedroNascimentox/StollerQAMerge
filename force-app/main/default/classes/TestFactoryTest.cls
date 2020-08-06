@IsTest
public class TestFactoryTest {
    @IsTest
    public static void testValidateSObjectError(){
        try{
            TestFactory.validateSObject(null);
        }catch(Exception e){
            System.assert('SObject cannot be null' == e.getMessage());

        }
    }
    @IsTest
    public static void testDispatchSObjectCreationError(){
        try{
            TestFactory.dispatchSObjectCreation(null, '');
        }catch(Exception e){
            System.assert('Invalid defaults class.' == e.getMessage());
        }
    }
}