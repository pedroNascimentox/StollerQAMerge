@isTest
public with sharing class BatchDeliveryNotificationTest {
    @isTest
    public static void DeliveryNotificationTest() {

        Date dataBase = BatchDeliveryNotification.getNotificationDate(Date.today());  
        
        system.debug('dataBase: '+ dataBase);

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            )
        );
        insert user;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert account;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio;


        Opportunity opportunity = (Opportunity)TestFactory.createSObject(
            new Opportunity(
                Territorio__c        = territorio.id,
                StageName            = 'Iniciado',
                CloseDate            = Date.today(),
                Name                 = 'Test Opportunity',
                AccountId            = account.id,
                AprovadoComercial__c = true,
                ListaPreco__c        = 'Z1'
            )
        );

        insert opportunity;

        ProgramacaoEntrega__c delivery = new ProgramacaoEntrega__c(
            Confirmado__c      = false,
            DataFaturamento__c = dataBase,
            Territorio__c      = territorio.Id,
            IdOportunidade__c = opportunity.Id,
            QuantidadeProgramada__c = 25
        );       

        insert delivery;

        BatchDeliveryNotification.run();
    }
    @isTest
    public static void testSchedule() {

        Test.startTest();

        BatchDeliveryNotificationSchedulable schedule = new BatchDeliveryNotificationSchedulable();
        schedule.execute(null);

        Test.stopTest();

    }
}