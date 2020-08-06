@isTest
public with sharing class TerritorioHelperTest {
    @isTest
    public static void testTerritorioHelper() {

        Map<Id, String> lookups = new Map<Id, String>();

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporteDestino = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteDestino;

        ZonaTransporte__c zonaTransporteOrigem = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporteOrigem;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporteOrigem.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile ORDER BY CreatedDate ASC LIMIT 1];
        Id userId = UserInfo.getUserId();
        User user1 = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user1;

        Territorio__c territorio = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user1.Id,
            Gerente__c  = user1.Id,
            Diretor__c  = user1.Id,
            Regional__c = regional.Id
        ));
        insert territorio;

        Territorio__c territorio1 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user1.Id,
            Gerente__c  = user1.Id,
            Diretor__c  = user1.Id,
            Regional__c = regional.Id
        ));
        insert territorio1;

        Account parentAccount = (Account)TestFactory.createSObject(
            new Account(
                OwnerId             = user1.Id,
                GerenteRegional__c  = user1.Id,
                DiretorComercial__c = user1.Id,
                ZonaTransporte__c   = zonaTransporteDestino.Id,
                LocalNegocio__c     = localNegocio.Id,
                RegionalVendas__c   = regional.Id,
                RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
            )
        );
        insert parentAccount;

        Account account = (Account)TestFactory.createSObject(
            new Account(
                OwnerId               = user1.Id,
                GerenteRegional__c    = user1.Id,
                DiretorComercial__c   = user1.Id,
                ZonaTransporte__c     = zonaTransporteDestino.Id,
                LocalNegocio__c       = localNegocio.Id,
                RegionalVendas__c     = regional.Id,
                RevendaAgenciadora__c = parentAccount.Id,
                ParentId              = parentAccount.Id,
                RecordTypeId          = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId()
            )
        );
        insert account;
        
        User user2 = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            ));
        insert user2;

        TerritorioCliente__c territorioCliente1 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio.Id
        );
        insert territorioCliente1;

        territorio.RTV__c = user2.Id;

        update territorio;

        update territorioCliente1;
        
        delete territorioCliente1;

    }
}