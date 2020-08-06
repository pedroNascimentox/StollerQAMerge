@IsTest
public class VisitaHelperTest {

    @IsTest
    public static void updateVisit(){

        Account account = (Account)TestFactory.createSObject(new Account());
        insert account;

        Visita__c visita = new Visita__c(
            Conta__c = account.id,
            dataHorarioVisitaCheckIn__c = Datetime.now(),
            DataHorarioVisitaCheckOut__c = Datetime.now().addDays(1),
            LocalizacaoGeograficaCheckIn__latitude__s = null,
            LocalizacaoGeograficaCheckOut__latitude__s = null,
            LocalizacaoGeograficaCheckIn__longitude__s = null,
            LocalizacaoGeograficaCheckOut__longitude__s = null,
            DataHorarioVisita__c = Datetime.now(),
            MotivoVisita__c = 'Dia de Campo',
            TipoVisita__c = 'Relacionamento'

        );
        insert visita;

        visita.MotivoVisita__c = 'Relacionamento';
        update visita;
    }

    @IsTest
    public static void checkVisitController(){

        Account account = (Account)TestFactory.createSObject(new Account());
        insert account;

        List<Decimal> latLng = new List<Decimal>{13.0429,80.2739};


        Visita__c visita = new Visita__c(
            Conta__c = account.id,
            dataHorarioVisitaCheckIn__c = Datetime.now(),
            DataHorarioVisitaCheckOut__c = Datetime.now().addDays(1),
            LocalizacaoGeograficaCheckIn__latitude__s = null,
            LocalizacaoGeograficaCheckOut__latitude__s = null,
            LocalizacaoGeograficaCheckIn__longitude__s = null,
            LocalizacaoGeograficaCheckOut__longitude__s = null,
            DataHorarioVisita__c = Datetime.now(),
            MotivoVisita__c = 'Dia de Campo',
            TipoVisita__c = 'Relacionamento'

        );
        insert visita;
        
        try{
            VisitController.check(visita.Id, true, latLng);
        }catch(Exception e){}
        
        try{
            VisitController.check(visita.Id, false, latLng);
        }catch(Exception e){}        
    
    }


    @IsTest
    public static void testTriggerControl(){   
        
        System.assertEquals(true, VisitaHelper.enableTrigger());
        System.assertEquals(true, VisitaHelper.isTriggerEnabled());
        System.assertEquals(false, VisitaHelper.disableTrigger());
    }    
}