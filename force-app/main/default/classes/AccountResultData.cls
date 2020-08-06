public class AccountResultData{
    public String id;
    public String name;
    public String clientType;
    public String resale;
    public String paymentRating;
    public Boolean block;
    public String shippingState;
    public String shippingCity;
    public String usedName;
    public Boolean icmsPayer;
    public String parentId;
    public String cnpj;
    public String externalId;
    public String priceList;
    public TerritoryData[] territories;
    public LocalNegocio__c businessPlace;

    public AccountResultData(Account a){
        this.id            = a.id;
        this.name          = a.Name;
        this.clientType    = a.TipoCliente__c;
        this.resale        = a.RevendaAgenciadora__c;
        this.paymentRating = a.RatingPagamento__c;
        this.block         = a.parentId != null ? a.parent.bloqueadoCredito__c : a.BloqueadoCredito__c;
        this.shippingState = a.ShippingState;
        this.shippingCity  = a.ShippingCity;
        this.usedName      = a.NomeFazenda__c;
        this.icmsPayer     = a.ContribuinteICMS__c;
        this.parentId      = a.ParentId;
        this.cnpj          = a.CNPJ__c;
        this.externalId    = a.ExternalId__c;
        this.territories   = new List<TerritoryData>();
        this.businessPlace = a.localNegocio__r;

        for(TerritorioCliente__c accountTerritory : a.territoriosClientesConta__r){
            this.territories.add(new TerritoryData(accountTerritory.territorio__r));
        }
    }

    public void setPriceList(String priceList){
        this.priceList = priceList;
    }
}