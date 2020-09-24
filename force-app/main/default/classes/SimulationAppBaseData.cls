public class SimulationAppBaseData {
    
    public List<PicklistEntryData> customerTypes;
    public List<PicklistEntryData> regions;
    public List<TerritoryData> territories;
    public List<RegionalData> regionals;
    public List<PicklistEntryData> priceLists;
    public List<BusinessPlaceData> businessPlaces;

    public SimulationAppBaseData(){
        this.customerTypes = getValues(Account.TipoCliente__c);
        this.regions = getValues(TabelaFrete__c.RegiaoUF__c);
        
        getBusinessPlacesData();
        getTerritoryData();
        getPriceLists();
    }

    public void getBusinessPlacesData(){

        List<BusinessPlaceData> businessPlaceResult = new List<BusinessPlaceData>();

        List<LocalNegocio__c> allBusinessPlaces = [
            SELECT id, descricao__c, name, codigo__c
            FROM LocalNegocio__c
        ];

        for(LocalNegocio__c businessPlace : allBusinessPlaces){
            businessPlaceResult.add(new BusinessPlaceData(businessPlace));
        }

        this.businessPlaces = businessPlaceResult;

    }

    public void getPriceLists(){
        
        List<PicklistEntryData> priceListsPickList = new List<PicklistEntryData>();

        priceListsPickList.add(new PicklistEntryData('Z1 - 07% ICMS', 'Z1', false));
        priceListsPickList.add(new PicklistEntryData('Z2 - 12% ICMS', 'Z2', false));
        priceListsPickList.add(new PicklistEntryData('Z3 - 18% ICMS', 'Z3', false));
        priceListsPickList.add(new PicklistEntryData('Z4 - Dólar'   , 'Z4', false));

        this.priceLists = priceListsPickList;

    }

    public void getTerritoryData(){
        List<TerritoryData> territoryResult = new List<TerritoryData>();
        Map<Id, RegionalData> regionalResultMap = new Map<Id, RegionalData>();
        
        Territorio__c[] allTerritories = OpportunityAppController.isCustomerService()? [
            SELECT
                regional__r.name,
                regional__r.nomeRegional__c,
                regional__r.externalId__c,
                regional__r.ACS__c,
                name,
                nomeTerritorio__c,
                regional__c,
                id,
                rtv__c,
                rtv__r.name,
                gerente__c,
                gerente__r.name,
                diretor__c,
                diretor__r.name,
                diretor__r.managerId,
                diretor__r.manager.name,
                externalId__c
            FROM Territorio__c
        ] : [
            SELECT
                regional__r.name,
                regional__r.nomeRegional__c,
                regional__r.externalId__c,
                regional__r.ACS__c,
                name,
                nomeTerritorio__c,
                regional__c,
                id,
                rtv__c,
                rtv__r.name,
                gerente__c,
                gerente__r.name,
                diretor__c,
                diretor__r.name,
                diretor__r.managerId,
                diretor__r.manager.name,
                externalId__c
            FROM Territorio__c
            WHERE RTV__c = :UserInfo.getUserId()
        ];

        for(Territorio__c t : allTerritories){
            TerritoryData territoryData = new TerritoryData(t);
            territoryData.addExternalIdToTerritoryData(t.externalId__c);
            territoryResult.add(territoryData);
            regionalResultMap.put(t.regional__r.id, new RegionalData(t.regional__r));
        }

        this.territories = territoryResult;
        this.regionals = regionalResultMap.values();
    }

    public List<PicklistEntryData> getValues(Schema.SObjectField f){
        Schema.DescribeFieldResult typesFieldResult = f.getDescribe();
        List<Schema.PicklistEntry> typesPickListEntry = typesFieldResult.getPickListValues();

        List<PicklistEntryData> typesValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : typesPickListEntry){
            typesValuesList.add(new PicklistEntryData(value, true));
        }

        return typesValuesList;
    }

    public class RegionalData{
        public String id;
        public String autoNumber;
        public String name;
        public String externalId;

        public RegionalData(Regional__c regional){
            this.id         = regional.id;
            this.autoNumber = regional.name;
            this.name       = regional.nomeRegional__c;
            this.externalId = regional.externalId__c;
        }
    }
}