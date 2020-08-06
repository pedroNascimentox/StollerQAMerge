@isTest
public with sharing class TerritorioClienteHelperTest {
    @isTest
    public static void TerritorioClienteHelperTest() {

        Regional__c regional = (Regional__c)TestFactory.createSObject(new Regional__c());
        insert regional;

        ZonaTransporte__c zonaTransporte = (ZonaTransporte__c)TestFactory.createSObject(new ZonaTransporte__c());
        insert zonaTransporte;

        LocalNegocio__c localNegocio = (LocalNegocio__c)TestFactory.createSObject(new LocalNegocio__c(
            ZonaTransporte__c = zonaTransporte.Id
        ));
        insert localNegocio;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador do sistema'];
        User user = (User)TestFactory.createSObject(
            new User(
                ProfileId = profile.Id
            )
        );
        insert user;

        Territorio__c territorio1 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio1;

        TerritoryData territoryData = new TerritoryData(territorio1);

        Territorio__c territorio2 = (Territorio__c)TestFactory.createSObject(new Territorio__c(
            RTV__c      = user.Id,
            Gerente__c  = user.Id,
            Diretor__c  = user.Id,
            Regional__c = regional.Id
        ));
        insert territorio2;

        Account account = (Account)TestFactory.createSObject(new Account(
            OwnerId             = user.Id,
            GerenteRegional__c  = user.Id,
            DiretorComercial__c = user.Id,
            ZonaTransporte__c   = zonaTransporte.Id,
            LocalNegocio__c     = localNegocio.Id,
            RegionalVendas__c   = regional.Id,
            RecordTypeId        = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId()
        ));
        insert account;

        List<TerritorioCliente__c> territoriosClienteToInsert = new List<TerritorioCliente__c>();

        TerritorioCliente__c territorioCliente1 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio1.Id
        );
        
        territoriosClienteToInsert.add(territorioCliente1);

        TerritorioCliente__c territorioCliente2 = new TerritorioCliente__c(
            Conta__c      = account.Id,
            Territorio__c = territorio2.Id
        );

        territoriosClienteToInsert.add(territorioCliente2);

        insert territoriosClienteToInsert;

        String concatenatedExternalIds = territorio1.ExternalId__c + ';' + territorio2.ExternalId__c;

        List<Account> localAccounts = [SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id = :account.Id];
        
        System.assertEquals(territorio1.ExternalId__c + ';' + territorio2.ExternalId__c, localAccounts[0].TerritoriosConcatenados__c);

        delete territorioCliente2;

        localAccounts = [SELECT Id, TerritoriosConcatenados__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(territorio1.ExternalId__c, localAccounts[0].TerritoriosConcatenados__c);

    }
}