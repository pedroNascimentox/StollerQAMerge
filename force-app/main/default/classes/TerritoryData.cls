public class TerritoryData {
    
    public String regional;
    public String name;
    public String territoryName;
    public String territory;
    public String rtvId;
    public String rtvName;
    public String managerId;
    public String acsId;
    public String managerName;
    public String directorId;
    public String directorName;
    public String businessDirectorId;
    public String businessDirectorName;
    public String externalId;
    public Boolean vendaDireta;

    public TerritoryData() {}

    public TerritoryData(Territorio__c territory) {
        this.name                 = territory.name;
        this.territoryName        = territory.nomeTerritorio__c;
        this.regional             = territory.regional__c;
        this.territory            = territory.id;
        this.rtvId                = territory.rtv__c;
        this.rtvName              = territory.rtv__r.name;
        this.managerId            = territory.gerente__c;
        this.acsId                = territory.regional__r.ACS__c;
        this.managerName          = territory.gerente__r.name;
        this.directorId           = territory.diretor__c;
        this.directorName         = territory.diretor__r.name;
        this.businessDirectorId   = territory.diretor__r.managerId;
        this.businessDirectorName = territory.diretor__r.manager.name;
    }

    public void addExternalIdToTerritoryData(String externalId){
        this.externalId = externalId;
    }
    
    public TerritoryData(TerritorioCliente__c territoryAccount) {
        this.name                 = territoryAccount.territorio__r.name;
        this.territoryName        = territoryAccount.territorio__r.nomeTerritorio__c;
        this.regional             = territoryAccount.territorio__r.regional__c;
        this.territory            = territoryAccount.territorio__r.id;
        this.rtvId                = territoryAccount.territorio__r.rtv__c;
        this.rtvName              = territoryAccount.territorio__r.rtv__r.name;
        this.managerId            = territoryAccount.territorio__r.gerente__c;
        this.acsId                = territoryAccount.territorio__r.regional__r.ACS__c;
        this.managerName          = territoryAccount.territorio__r.gerente__r.name;
        this.directorId           = territoryAccount.territorio__r.diretor__c;
        this.directorName         = territoryAccount.territorio__r.diretor__r.name;
        this.businessDirectorId   = territoryAccount.territorio__r.diretor__r.managerId;
        this.businessDirectorName = territoryAccount.territorio__r.diretor__r.manager.name;
    }

    public void addvendaDiretaToTerritoryData(Boolean vendaDireta){
        this.vendaDireta = vendaDireta;
    }
    
}