public class CancellingAppController {
    
    public String opportunityId   {get; set;}
    public String opportunityName {get; set;}
    
    public static final String DEFAULT_CURRENCY_CODE = 'BRL';
    public static String CUSTOMER_SERVICE_PROFILE_TERM;
    public static String GERENTE_REGIONAL_PROFILE_TERM;
    public static String DIRETOR_COMERCIAL_PROFILE_TERM;
    public static String ADMINISTRATOR_PROFILE_TERM;
    public static String RTV_PROFILE_TERM;
    public static Profile userProfile;
    
    public Boolean isCustomerService {get;set;}
    public Boolean isRTV {get;set;}

    static{
        userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ]; 

        CUSTOMER_SERVICE_PROFILE_TERM  = Label.CustomerServiceProfileTerm;
        RTV_PROFILE_TERM               = Label.RTVProfileTerm;
        GERENTE_REGIONAL_PROFILE_TERM  = Label.RegionalManagerProfileTerm;
        DIRETOR_COMERCIAL_PROFILE_TERM = Label.ComercialDirectorProfileTerm;
        ADMINISTRATOR_PROFILE_TERM     = [SELECT Id, name FROM Profile WHERE PermissionsModifyAllData = true AND PermissionsPrivacyDataAccess = true ORDER BY CreatedDate LIMIT 1].name;
    }

    public CancellingAppController() {}

    public CancellingAppController(ApexPages.StandardController standardController) {
        this.isCustomerService = isCustomerService();
        this.isRTV             = isRTV();
        
        Id deliveryId = ApexPages.currentPage().getParameters().get('Id');
        if(deliveryId != null){
            for(SolicitacaoCancelamento__c delivery : [SELECT Oportunidade__c, Oportunidade__r.numeroOportunidade__c FROM SolicitacaoCancelamento__c WHERE Id = :deliveryId]){
                this.opportunityId = delivery.Oportunidade__r.numeroOportunidade__c;
                this.opportunityName = delivery.Oportunidade__c;
            }
        }
    }

    public static Boolean isCustomerService(){
        return (
            userProfile.name.containsIgnoreCase(CUSTOMER_SERVICE_PROFILE_TERM)  || 
            userProfile.name.containsIgnoreCase(GERENTE_REGIONAL_PROFILE_TERM)  || 
            userProfile.name.containsIgnoreCase(DIRETOR_COMERCIAL_PROFILE_TERM) ||
            userProfile.name.containsIgnoreCase(ADMINISTRATOR_PROFILE_TERM)
        );
    }

    public static Boolean isRTV(){
        return userProfile.name.containsIgnoreCase(RTV_PROFILE_TERM);
    }

    public static void fillMaps(List<ProgramacaoEntrega__c> listDelivery, List<ProgramacaoEntrega__c> listAllDelivery, Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory){

         for(ProgramacaoEntrega__c delivery : listDelivery){

            if(!mapTerritoryToDelivery.containsKey(delivery.Territorio__c)) {
                mapTerritoryToDelivery.put(delivery.Territorio__c, new List<ProgramacaoEntrega__c>());
            }
            mapTerritoryToDelivery.get(delivery.Territorio__c).add(delivery);
            listAllDelivery.add(delivery);

            if (!mapAccToTerritory.containsKey(delivery.EmissorOrdem__r.Id)) {
                mapAccToTerritory.put(delivery.EmissorOrdem__r.Id, new List<TerritoryData>());
            }
         }
    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListData() {
               
        String currentProfileName;             
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();

        system.debug(currentProfileName);

        System.debug('RESULT');
        System.debug([SELECT IdOpportunityLineItem__c, Id, StatusSAP__c, status__c FROM ProgramacaoEntrega__c]);

        List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                    Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                    QuantidadeProgramada__c, QuantidadeDisponivelSAP__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                    Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                    Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                    RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                    EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                    EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                    ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                    ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                    IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.CreatedDate,
                                                    IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                    DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, CreatedDate
                                                    FROM ProgramacaoEntrega__c 
                                                    WHERE
                                                        StatusSAP__c NOT IN (
                                                            'Faturado', 'Cancelado', 'Bloqueio de Remessa', 'Em Remessa'
                                                        ) AND (
                                                            status__c = 'Liberado' OR status__c = 'Integrado' 
                                                        ) 
                                                        AND   IdOportunidade__c<> null
                                                        ORDER BY CreatedDate DESC, Id DESC
                                                        LIMIT 2500];

        
        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory); 
    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataChunk(RequestChunk req) {
               
        String currentProfileName;             
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();

        system.debug(currentProfileName);

        Long data = Long.valueof(req.today);
        Datetime dt = Datetime.newInstance(data);

        System.debug('RESULT');
        System.debug([SELECT IdOpportunityLineItem__c, Id, StatusSAP__c, status__c FROM ProgramacaoEntrega__c]);

        List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                    Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                    QuantidadeProgramada__c, QuantidadeDisponivelSAP__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                    Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                    Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                    RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                    EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                    EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                    ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                    ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                    IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.CreatedDate,
                                                    IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                    DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, CreatedDate
                                                    FROM ProgramacaoEntrega__c 
                                                    WHERE (CreatedDate =: dt AND Id <: req.idDelivery 
                                                        AND (StatusSAP__c NOT IN (
                                                            'Faturado', 'Cancelado', 'Bloqueio de Remessa', 'Em Remessa'
                                                        )) 
                                                        AND (
                                                            status__c = 'Liberado' OR status__c = 'Integrado' 
                                                        ) 
                                                        AND   (IdOportunidade__c<> null)
                                                        
                                                        AND   (idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp))

                                                        OR (CreatedDate <: dt
                                                        AND (StatusSAP__c NOT IN (
                                                            'Faturado', 'Cancelado', 'Bloqueio de Remessa', 'Em Remessa'
                                                        )) 
                                                        AND (
                                                            status__c = 'Liberado' OR status__c = 'Integrado')

                                                        AND   (IdOportunidade__c<> null)    

                                                        AND  (idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp))
                                                        ORDER BY CreatedDate DESC, Id DESC
                                                        LIMIT 500];

        
        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory); 
    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataOpp(String numOpp) {
               
        String currentProfileName;             
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();

        system.debug(currentProfileName);

        System.debug('RESULT');
        System.debug([SELECT IdOpportunityLineItem__c, Id, StatusSAP__c, status__c FROM ProgramacaoEntrega__c]);

        List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                    Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                    QuantidadeProgramada__c, QuantidadeDisponivelSAP__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                    Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                    Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                    RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                    EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                    EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                    ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                    ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                    IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.CreatedDate,
                                                    IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                    DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, CreatedDate
                                                    FROM ProgramacaoEntrega__c 
                                                    WHERE
                                                        StatusSAP__c NOT IN (
                                                            'Faturado', 'Cancelado', 'Bloqueio de Remessa', 'Em Remessa'
                                                        ) AND (
                                                            status__c = 'Liberado' OR status__c = 'Integrado' 
                                                        ) 
                                                        AND   IdOportunidade__c <> null
                                                        AND   idOportunidade__r.NumeroOportunidade__c LIKE :numOpp
                                                        ORDER BY CreatedDate DESC, Id DESC
                                                        LIMIT 2500];

        
        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory); 
    }


    public static ResponseOpportunityListData getReturn(List<ProgramacaoEntrega__c> listAllDelivery,  Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory){

        ResponseOpportunityListData responseData; 
        List<Id> deliveryRecordsIds = new List<Id>();
        List<Id> oppItemIds = new List<Id>();

        try {
            if (isCustomerService()){
                responseData = new ResponseOpportunityListData();
                if (!listAllDelivery.isEmpty()){
                    Collection deliveryCollection = Collection.of(listAllDelivery);
                    
                    deliveryRecordsIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.Id);
                    oppItemIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.IdOpportunityLineItem__c);

                    List<OrderItem> orderItems = [SELECT id, order.createdDate, order.OVSAP__c, orderId, programacaoEntrega__c 
                                                  FROM OrderItem 
                                                  WHERE programacaoEntrega__c IN :deliveryRecordsIds
                                                  AND   MOtivoRecusaItem__c != 'Z1'
                                                  AND   MOtivoRecusaItem__c != 'Z2'
                                                  AND   MOtivoRecusaItem__c != 'ZS'];

                    Map<Id, OrderItem> deliveryIdToOrderItem = new Map<Id, OrderItem>();

                    for(OrderItem orderItem : orderItems){
                        deliveryIdToOrderItem.put(orderItem.programacaoEntrega__c, orderItem);
                    }
                    responseData.data = fillResponseOpportunityListData(listAllDelivery, mapAccToTerritory, mapTerritoryToDelivery, deliveryIdToOrderItem, oppItemIds);   
                }
            }
            else {                
                List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
                for (Territorio__c territory : [SELECT Id, RTV__c FROM Territorio__c WHERE RTV__c =: UserInfo.getUserId() LIMIT 1]){
                    if(mapTerritoryToDelivery.containsKey(territory.Id)){
                        listDelivery = mapTerritoryToDelivery.get(territory.Id); //retorna ProgramacaoEntrega__c
                    }
                }
                responseData = new ResponseOpportunityListData();  
                if (!listDelivery.isEmpty()){
                    Collection deliveryCollection = Collection.of(listAllDelivery);
                    
                    deliveryRecordsIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.Id);
                    oppItemIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.IdOpportunityLineItem__c);

                    List<OrderItem> orderItems = [SELECT id, order.createdDate, order.OVSAP__c, orderId, programacaoEntrega__c 
                                                  FROM OrderItem 
                                                  WHERE programacaoEntrega__c IN :deliveryRecordsIds
                                                  AND   MOtivoRecusaItem__c != 'Z1'
                                                  AND   MOtivoRecusaItem__c != 'Z2'
                                                  AND   MOtivoRecusaItem__c != 'ZS'];
                    
                    Map<Id, OrderItem> deliveryIdToOrderItem = new Map<Id, OrderItem>();

                    for(OrderItem orderItem : orderItems){
                        deliveryIdToOrderItem.put(orderItem.programacaoEntrega__c, orderItem);
                    }
                    responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, deliveryIdToOrderItem, oppItemIds);
                }
            }
        } catch (Exception ex) {
            responseData = new ResponseOpportunityListData(ex);
        }

        // system.debug(responseData);

        return responseData;
    }

    public static List<OppData> fillResponseOpportunityListData(List<ProgramacaoEntrega__c> listDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory, Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id,OrderItem> deliveryIdToOrderItem, List<Id> oppItemIds){
        List<ProdData> listProductData;    
        List<OppData> listOpportunityData              = new List<OppData>();

        Map<Id, List<ProdData>> mapIdToListProdData    = new Map<Id, List<ProdData>>();
        Map<Id, ProgramacaoEntrega__c> mapIdToDelivery = new Map<Id, ProgramacaoEntrega__c>();

        AccData accountDataOpp;
        AccData accountDataProd;
        CulData cultureData;
        OppData opportunityData;
        ProdData productData;

        for (TerritorioCliente__c t : [
            SELECT 
                conta__c,
                territorio__c,
                territorio__r.name,
                territorio__r.nomeTerritorio__c,
                territorio__r.regional__c,
                territorio__r.id,
                territorio__r.rtv__c,
                territorio__r.rtv__r.name,
                territorio__r.gerente__c,
                territorio__r.gerente__r.name,
                territorio__r.diretor__c,
                territorio__r.diretor__r.name,
                territorio__r.diretor__r.managerId,
                territorio__r.diretor__r.manager.name
            FROM TerritorioCliente__c
            WHERE conta__c IN :mapAccToTerritory.keySet()
        ]) {
            mapAccToTerritory.get(t.conta__c).add(new TerritoryData(t));
        }

        Map<Id, TerritoryData> mapTerritoryToData = new Map<Id, TerritoryData>();

        for (Territorio__c territory : [
            SELECT 
                Id, 
                name,
                nomeTerritorio__c,
                regional__c,
                rtv__c,
                rtv__r.name,
                gerente__c,
                gerente__r.name,
                diretor__c,
                diretor__r.name,
                diretor__r.managerId,
                diretor__r.manager.name
            FROM Territorio__c WHERE Id IN :mapTerritoryToDelivery.keySet()
        ]) {
            mapTerritoryToData.put(territory.id, new TerritoryData(territory));
        }

        for (ProgramacaoEntrega__c delivery : listDelivery){   
            if (delivery.statusSAP__c == 'Faturado Parcial' && (delivery.QuantidadeDisponivelSAP__c == null || delivery.QuantidadeDisponivelSAP__c == 0)){
                continue;
            } else if (delivery.statusSAP__c != 'Faturado Parcial' && (delivery.QuantidadeProgramada__c == null || delivery.QuantidadeProgramada__c == 0)){
                continue;
            }

            cultureData                        = new CulData();
            cultureData.id                     = delivery.Cultura__r.Id;
            cultureData.name                   = delivery.Cultura__r.Name;
            
            accountDataProd                    = new AccData();
            accountDataProd.id                 = delivery.RecebedorOrdem__r.Id;
            accountDataProd.parentId           = delivery.RecebedorOrdem__r.ParentId;
            accountDataProd.name               = delivery.RecebedorOrdem__r.Name;
            accountDataProd.cnpj               = delivery.RecebedorOrdem__r.CNPJ__c;
            accountDataProd.city               = delivery.RecebedorOrdem__r.ShippingCity;
            accountDataProd.state              = delivery.RecebedorOrdem__r.ShippingState;
            accountDataProd.farm               = delivery.RecebedorOrdem__r.NomeFazenda__c;
            
            productData                        = new ProdData();
            productData.id                     = delivery.Id;
            productData.territoryData          = mapTerritoryToData.get(delivery.Territorio__c);
            productData.itemId                 = delivery.IdOpportunityLineItem__c;
            productData.billingDate            = delivery.DataFaturamento__c;
            productData.status                 = delivery.Status__c;
            productData.multiplicity           = delivery.Produto__r.Multiplicidade__c;
            productData.statusSAP              = delivery.StatusSAP__c;
            productData.productId              = delivery.Produto__r.Id;
            productData.packing                = delivery.Produto__r.Embalagem__c;
            productData.name                   = delivery.Produto__r.Name;
            productData.sku                    = delivery.Produto__r.Sku__c;
            productData.liter                  = delivery.Litros__c;
            productData.baseLiter              = delivery.Produto__r.Litragem__c;
            productData.deliveryDate           = delivery.DataEntrega__c;
            productData.orderNumber            = (deliveryIdToOrderItem.get(delivery.id) != null ? deliveryIdToOrderItem.get(delivery.id).order.OVSAP__c : '');
            productData.pricePerLiter          = delivery.PrecoLitro__c;
            productData.quantity               = (delivery.statusSAP__c == 'Faturado Parcial'? delivery.QuantidadeDisponivelSAP__c : delivery.QuantidadeProgramada__c);
            productData.priceList              = delivery.PrecoListaReferencia__c;
            productData.salesPrice             = delivery.PrecoVenda__c;
            productData.salesPriceWithInterest = delivery.PrecoVendaJuros__c;
            productData.discount               = delivery.DescontoConcedido__c;
            productData.interest               = delivery.Juros__c;
            productData.confirmed              = delivery.Confirmado__c;
            productData.receiver               = accountDataProd;
            productData.culture                = cultureData;
            productData.confirmedDate          = delivery.DataConfirmacao__c;
            
            productData.oppNumber              = delivery.IdOportunidade__r.NumeroOportunidade__c;
            productData.oppCreatedDate         = delivery.IdOportunidade__r.CreatedDate;
            productData.orderType              = delivery.TipoOrdem__c;
            productData.regionalName           = delivery.Regional__r.NomeRegional__c;
            productData.directorName           = delivery.DiretorComercial__r.Name;
            productData.rtvName                = delivery.NomeRTV__c;

            accountDataProd                    = new AccData();
            accountDataProd.id                 = delivery.EmissorOrdem__r.Id;
            accountDataProd.parentId           = delivery.EmissorOrdem__r.ParentId;
            accountDataProd.name               = delivery.EmissorOrdem__r.Name;
            accountDataProd.cnpj               = delivery.EmissorOrdem__r.CNPJ__c;
            accountDataProd.city               = delivery.EmissorOrdem__r.ShippingCity;
            accountDataProd.state              = delivery.EmissorOrdem__r.ShippingState;
            accountDataProd.farm               = delivery.EmissorOrdem__r.NomeFazenda__c;
            accountDataProd.territories        = mapAccToTerritory.get(delivery.EmissorOrdem__r.Id);
            productData.selectedAccount        = accountDataProd;

            accountDataProd                    = new AccData();
            accountDataProd.id                 = delivery.ClienteOrigemRemanejamento__r.Id;
            accountDataProd.parentId           = delivery.ClienteOrigemRemanejamento__r.ParentId;
            accountDataProd.name               = delivery.ClienteOrigemRemanejamento__r.Name;
            accountDataProd.cnpj               = delivery.ClienteOrigemRemanejamento__r.CNPJ__c;
            accountDataProd.city               = delivery.ClienteOrigemRemanejamento__r.ShippingCity;
            accountDataProd.state              = delivery.ClienteOrigemRemanejamento__r.ShippingState;
            accountDataProd.farm               = delivery.ClienteOrigemRemanejamento__r.NomeFazenda__c;
            productData.shipper                = accountDataProd;

            listProductData = new List<ProdData>{productData};

            if(!mapIdToListProdData.ContainsKey(delivery.IdOportunidade__c) ){
                mapIdToListProdData.put(delivery.IdOportunidade__c, listProductData);
                mapIdToDelivery.put(delivery.IdOportunidade__c, delivery);
            }else{
                mapIdToListProdData.get(delivery.IdOportunidade__c).add(productData);
            }
        }        

        for (id idOpp : mapIdToDelivery.keySet()){
            ProgramacaoEntrega__c delivery     = mapIdToDelivery.get(idOpp);
            accountDataOpp                     = new AccData();
            accountDataOpp.id                  = delivery.EmissorOrdem__r.Id;
            accountDataOpp.parentId            = delivery.EmissorOrdem__r.ParentId;
            accountDataOpp.name                = delivery.EmissorOrdem__r.Name;
            accountDataOpp.cnpj                = delivery.EmissorOrdem__r.CNPJ__c;
            accountDataOpp.city                = delivery.EmissorOrdem__r.ShippingCity;
            accountDataOpp.state               = delivery.EmissorOrdem__r.ShippingState;
            accountDataOpp.farm                = delivery.EmissorOrdem__r.NomeFazenda__c;
            
            opportunityData                    = new OppData();
            opportunityData.id                 = delivery.IdOportunidade__r.Id;
            opportunityData.name               = delivery.IdOportunidade__r.NumeroOportunidade__c;
            opportunityData.orderType          = delivery.TipoOrdem__c;
            opportunityData.billingDate        = delivery.DataFaturamento__c;
            opportunityData.regionalName       = delivery.Regional__r.NomeRegional__c;
            opportunityData.directorName       = delivery.DiretorComercial__r.Name;
            opportunityData.status             = delivery.IdOportunidade__r.StageName;
            opportunityData.rtvName            = delivery.NomeRTV__c;
            opportunityData.selectedAccount    = accountDataOpp;
            opportunityData.products           = mapIdToListProdData.get(idOpp);
            opportunityData.createdDate        = delivery.CreatedDate;
            opportunityData.deliveryId         = delivery.Id;
            opportunityData.key                = idOpp + '_' + delivery.EmissorOrdem__r.Id;

            listOpportunityData.add(opportunityData);          
        }

        // system.debug(listOpportunityData);

        return listOpportunityData;
    }

    @RemoteAction
    public static ResponseDeliveryData upsertDeliveryData(RequestDeliveryData request) {
        ResponseDeliveryData responseData;
        List<Opportunity> listOpp = new List<Opportunity>();
        List<ProgramacaoEntrega__c> listDeliveryToDelete = new List<ProgramacaoEntrega__c>();
        List<ProgramacaoEntrega__c> listDeliveryToUpsert = new List<ProgramacaoEntrega__c>();
        Map<Id, ProgramacaoEntrega__c> mapIdToDelivery   = new Map<Id, ProgramacaoEntrega__c>();
        Set<String> setItemIdDeliveryData = new Set<String>();
        try {
            responseData = new ResponseDeliveryData();
            Set<Id> productIds = new Set<Id>();

            for (DeliveryData delivery : request.listDeliveryData){
                setItemIdDeliveryData.add(delivery.oppItemId);
                productIds.add(delivery.productId);
            }
            Id opportunityIdToValidateRA;
            String customerName;

            for (ProgramacaoEntrega__c delivery: [SELECT Id, cultura__c, dataFaturamento__c, descontoConcedido__c, descontoTipoCliente__c, 
                                                  diretorComercial__c, diretorNegocios__c, juros__c, litros__c, localNegocio__c, nomeRTV__c, numeroPedidoCliente__c, 
                                                  precoListaReferencia__c, precoVenda__c, precoVendaJuros__c, precoLitro__c, produto__c, regional__c, 
                                                  saldoLimiteCredito__c, territorio__c, tipoOrdem__c, valorFrete__c, valorTotal__c, valorUnitario__c,
                                                  idOpportunityLineItem__c, Status__c, StatusSAP__c, idOportunidade__c, idOportunidade__r.account.name, 
                                                  idOportunidade__r.account.tipoCliente__c
                                                  FROM ProgramacaoEntrega__c WHERE idOpportunityLineItem__c IN: setItemIdDeliveryData OR Id IN :request.listToDelete]){
                if (request.listToDelete.contains(delivery.id)) {
                    listDeliveryToDelete.add(delivery);
                }else {
                    mapIdToDelivery.put(delivery.idOpportunityLineItem__c, delivery);
                    if(delivery.idOportunidade__r.account.tipoCliente__c == 'ZE'){
                        opportunityIdToValidateRA = delivery.idOportunidade__c;
                        customerName = delivery.idOportunidade__r.account.name;
                    }
                }
            }

            Set<Id> opportunitiesWithRADocumentsIds = new Set<Id>();
            Map<Id, Product2> idToProduct;
            if(opportunityIdToValidateRA != null){
                for(DocumentoOportunidade__c opportunityDocument : [SELECT id, oportunidade__c FROM DocumentoOportunidade__c 
                                                                    WHERE oportunidade__c = :opportunityIdToValidateRA
                                                                    AND tipoDocumento__c = 'Receita agronômica']){
                    opportunitiesWithRADocumentsIds.add(opportunityDocument.oportunidade__c);
                }
                idToProduct = new Map<Id, Product2>(getRAValidationProducts(new List<Id>(productIds))); 

            }

            // System.debug(listDeliveryToDelete);

            Boolean showRAWarning =  false;
            String  htmlReturn    =  '<div class="message-list"><p>O(s) Produto(s): </p>';
                    htmlReturn    += '<ul>';

            for (DeliveryDAta deliveryData: request.listDeliveryData ){ 
                ProgramacaoEntrega__c deliveryInfo              = mapIdToDelivery.get(deliveryData.oppItemId);
                ProgramacaoEntrega__c deliveryToUpsert          = new ProgramacaoEntrega__c();
                deliveryToUpsert.Id                             = deliveryData.id;
                deliveryToUpsert.confirmado__c                  = deliveryData.confirmed;
                deliveryToUpsert.dataEntrega__c                 = (deliveryData.deliveryDate  != null ? Date.valueOf(deliveryData.deliveryDate) : null);
                deliveryToUpsert.emissorOrdem__c                = deliveryData.selectedAccount;
                deliveryToUpsert.recebedorOrdem__c              = deliveryData.receiver;
                deliveryToUpsert.clienteOrigemRemanejamento__c  = deliveryData.shipper;
                deliveryToUpsert.quantidadeProgramada__c        = deliveryData.quantity;
                deliveryToUpsert.dataConfirmacao__c             = (deliveryData.confirmedDate != null ? Date.valueOf(deliveryData.confirmedDate) : null);
                deliveryToUpsert.nomeUsuarioConfirmacao__c      = UserInfo.getName();

                deliveryToUpsert.idOportunidade__c              = deliveryData.oppId;
                deliveryToUpsert.idOpportunityLineItem__c       = deliveryData.oppItemId;

                deliveryToUpsert.numeroPedidoCliente__c         = deliveryData.orderNumber;
                deliveryToUpsert.tipoOrdem__c                   = deliveryData.orderType;
                deliveryToUpsert.produto__c                     = deliveryData.productId; 

                deliveryToUpsert.cultura__c                     = deliveryInfo.cultura__c; 
                deliveryToUpsert.dataFaturamento__c             = OpportunityAppController.getBillingDate(deliveryToUpsert.dataEntrega__c, deliveryData.itineraryDays); 
                deliveryToUpsert.descontoConcedido__c           = deliveryInfo.descontoConcedido__c;
                deliveryToUpsert.descontoTipoCliente__c         = deliveryInfo.descontoTipoCliente__c;
                deliveryToUpsert.juros__c                       = deliveryInfo.juros__c;
                deliveryToUpsert.litros__c                      = deliveryData.baseLiter * deliveryData.quantity; 
                deliveryToUpsert.localNegocio__c                = deliveryInfo.localNegocio__c;                          // oportunidade__r.localNegocio__c
                deliveryToUpsert.precoListaReferencia__c        = deliveryInfo.precoListaReferencia__c;
                deliveryToUpsert.precoVenda__c                  = deliveryInfo.precoVenda__c;
                deliveryToUpsert.precoVendaJuros__c             = deliveryInfo.precoVendaJuros__c;
                deliveryToUpsert.precoLitro__c                  = deliveryInfo.precoLitro__c;
                deliveryToUpsert.saldoLimiteCredito__c          = deliveryInfo.saldoLimiteCredito__c;                    // oportunidade__r.saldoLimiteCredito__c
                deliveryToUpsert.valorFrete__c                  = deliveryInfo.valorFrete__c; 
                deliveryToUpsert.valorTotal__c                  = deliveryInfo.precoVenda__c * deliveryData.quantity; 
                deliveryToUpsert.valorUnitario__c               = deliveryInfo.valorUnitario__c;

                if (deliveryData.territoryData != null) {
                    deliveryToUpsert.Territorio__c                  = deliveryData.territoryData.territory;
                    deliveryToUpsert.NomeRTV__c                     = deliveryData.territoryData.rtvName;
                    deliveryToUpsert.DiretorComercial__c            = deliveryData.territoryData.directorId;
                    deliveryToUpsert.diretorNegocios__c             = deliveryData.territoryData.businessDirectorId;
                    deliveryToUpsert.GerenteRegional__c             = deliveryData.territoryData.managerId;
                    deliveryToUpsert.Regional__c                    = deliveryData.territoryData.regional;                    
                }
                

                deliveryToUpsert.Status__c                      = 'Liberado';
                deliveryToUpsert.StatusSAP__c                   = 'Não Confirmado';

                listDeliveryToUpsert.add(deliveryToUpsert);

                if(opportunityIdToValidateRA != null && idToProduct.keySet().contains(deliveryData.productId)){
                    if(!opportunitiesWithRADocumentsIds.contains(deliveryData.oppId)){
                        showRAWarning = true;
                        htmlReturn += '<li>' + idToProduct.get(deliveryData.productId).name + '</li>';
                    }
                }
            }

            if(showRAWarning){
                htmlReturn += '</ul><p>Necessita(m) de RA. Favor providenciar o(s) documento(s) para liberação do faturamento.</p><p>Cliente: ' + customerName + '</p></div>';
                responseData = new ResponseDeliveryData(htmlReturn, 'warning');
            }

            upsert listDeliveryToUpsert;
            delete listDeliveryToDelete;

        } catch (Exception ex) {
            responseData = new ResponseDeliveryData(ex);
        }

        return responseData;
    }

    @RemoteAction
    public static CancellingAppReturnedBaseData getBaseData(){

        CancellingAppReturnedBaseData opportunityAppReturnedBaseData = new CancellingAppReturnedBaseData();
        
        try {
         
            CancellingAppBaseData opportunityAppBaseData = new CancellingAppBaseData();

            opportunityAppBaseData.fetchCancellingReasons();
            opportunityAppBaseData.setHolidays(OpportunityAppController.getHolidays());

            Decimal confirmationDeadlineDays = 0;

            List<PrazoConfirmacaoEntrega__c> confirmationDeadlineList = [SELECT dias__c FROM PrazoConfirmacaoEntrega__c ORDER BY CreatedDate DESC LIMIT 1];

            if (confirmationDeadlineList.size() > 0) {
                confirmationDeadlineDays = confirmationDeadlineList[0].dias__c;
            }

            opportunityAppBaseData.setConfirmationDeadline(confirmationDeadlineDays);

            opportunityAppReturnedBaseData = new CancellingAppReturnedBaseData(opportunityAppBaseData);

        } catch (Exception e){

            opportunityAppReturnedBaseData = new CancellingAppReturnedBaseData(e.getMessage());

        }

        return opportunityAppReturnedBaseData;
    }

    @RemoteAction
    public static CancellingResultReturnedData insertCancelling(List<CancellingData> deliveryRequests){
        Savepoint sp = null;
        Boolean hasSend = false;
        Boolean hasError = false;
        Set<Id> orderItemIdSet = new Set<Id>();
        try {
            Map<Id, CancellingData> deliveryRequestMap = new Map<Id, CancellingData>();

            for(CancellingData deliveryRequest : deliveryRequests){
                deliveryRequestMap.put(deliveryRequest.deliveryRequestId, deliveryRequest);
            }
            
            Cancelamento__c[] cancellings = new List<Cancelamento__c>();
            ProgramacaoEntrega__c[] targetDeliveryRequests = [
                SELECT  
                    Confirmado__c, 
                    TaxaDolar__c,
                    Moeda__c, 
                    Cultura__c, 
                    DataConfirmacao__c, 
                    DataEntrega__c, 
                    DataEntregaSAP__c, 
                    DataFaturamento__c, 
                    DataIntegracao__c, 
                    DescontoConcedido__c, 
                    DescontoTipoCliente__c, 
                    DiretorComercial__c, 
                    DiretorNegocios__c,
                    GerenteRegional__c, 
                    EmissorOrdem__c, 
                    IdDivisaoEntregaSAP__c, 
                    id,
                    IdOportunidade__c, 
                    IdOpportunityLineItem__c, 
                    Juros__c, 
                    LimiteCreditoTotal__c, 
                    Litros__c, 
                    LocalNegocio__c, 
                    // MotivoCancelamento__c, 
                    NomeRTV__c, 
                    NomeUsuarioConfirmacao__c, 
                    NumeroPedidoCliente__c, 
                    PrecoListaReferencia__c, 
                    PrecoLitro__c, 
                    Produto__r.Litragem__c,
                    PrecoVenda__c, 
                    PrecoVendaJuros__c, 
                    Produto__c, 
                    // ProgramacaoEntrega__c, 
                    QuantidadeDisponivelSAP__c, 
                    QuantidadeProgramada__c, 
                    RecebedorOrdem__c, 
                    Regional__c, 
                    SaldoLimiteCredito__c, 
                    StatusSAP__c, 
                    Territorio__c, 
                    TipoOrdem__c, 
                    ValorFrete__c, 
                    ValorTotal__c, 
                    ValorTotalUSD__c, 
                    ValorUnitario__c,
                    PrecoVendasComJurosUSDBRL__C,
                    PrecoVendasJurosUSD__c
                FROM ProgramacaoEntrega__c
                WHERE id IN :deliveryRequestMap.keySet()
            ];

            List<OrderItem> orderItems = [SELECT id, order.createdDate, order.OVSAP__c, orderId, programacaoEntrega__c FROM OrderItem WHERE programacaoEntrega__c IN :deliveryRequestMap.keySet()];
            
            Map<Id, String> deliveryIdToOrder = new Map<Id, String>();
            Map<Id, String> deliveryIdToOrderItem = new Map<Id, String>();

            for(OrderItem orderItem : orderItems){
                deliveryIdToOrder.put(orderItem.programacaoEntrega__c, orderItem.orderId);
                deliveryIdToOrderItem.put(orderItem.programacaoEntrega__c, orderItem.Id);
                orderItemIdSet.add(orderItem.Id);
            }


            Decimal taxaMedia = 1;
            CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
            if(!cotacoesMoeda.isEmpty())    
                taxaMedia = cotacoesMoeda[0].TaxaMedia__c;

            ProgramacaoEntrega__c[] newDeliveryRequests = new List<ProgramacaoEntrega__c>();
            Map<Id, CancellingWrapper> cancellingMap = new Map<Id, CancellingWrapper>();

            for(ProgramacaoEntrega__c deliveryRequest : targetDeliveryRequests){

                Decimal deliveryTax = 1;
                if(deliveryRequest.TaxaDolar__c != null){
                    deliveryTax = deliveryRequest.TaxaDolar__c;
                }else{
                    deliveryTax = taxaMedia;
                }
                
                Cancelamento__c cancellingItem = new Cancelamento__c();
                CancellingData cancellingDataRequest = deliveryRequestMap.get(deliveryRequest.id);

                for(String fieldName : deliveryRequest.getPopulatedFieldsAsMap().keySet()){
                    
                    if(fieldName != 'PrecoVendasComJurosUSDBRL__c' && fieldName != 'Moeda__c' && fieldName != 'TaxaDolar__c' && fieldName != 'Produto__r' && fieldName != 'PrecoVendasJurosUSD__c'){
                        Object value = deliveryRequest.get(fieldName);
                        cancellingItem.put(fieldName, value);
                    }
                }

                if(deliveryIdToOrder.containsKey(deliveryRequest.id)){
                    cancellingItem.pedido__c = deliveryIdToOrder.get(deliveryRequest.id);
                }
                if(deliveryIdToOrderItem.containsKey(deliveryRequest.id)){
                    cancellingItem.itemPedido__c = deliveryIdToOrderItem.get(deliveryRequest.id);
                }
                cancellingItem.motivoCancelamento__c = cancellingDataRequest.cancellingReason;
                cancellingItem.TipoCancelamento__c = cancellingDataRequest.cancellingType;
                cancellingItem.QuantidadeProgramada__c = cancellingDataRequest.quantity;
                cancellingItem.descricao__c = cancellingDataRequest.cancellingDescription;
                cancellingItem.DataSolicitacao__C = Date.Today();
                cancellingItem.ValorTotal__c = cancellingDataRequest.quantity * (deliveryRequest.Moeda__C == 'USD' ? deliveryRequest.PrecoVendasJurosUSD__c : deliveryRequest.PrecoVendaJuros__c);
                cancellingItem.ValorTotalUSD__c = cancellingDataRequest.quantity * deliveryRequest.PrecoVendasJurosUSD__c;
                // cancellingItem.ValorTotal__c = cancellingDataRequest.quantity * (deliveryRequest.Moeda__C == 'USD' ? deliveryRequest.PrecoVendasJurosUSD__c : deliveryRequest.PrecoVendaJuros__c);
                // cancellingItem.ValorTotalUSD__c = cancellingDataRequest.quantity * (deliveryRequest.Moeda__C == 'USD' ? deliveryRequest.PrecoVendasJurosUSD__c :  deliveryRequest.PrecoVendasJurosUSD__c * deliveryTax);
                cancellingItem.diretorNegocios__c = deliveryRequest.diretorNegocios__c;

                cancellingItem.id = null;
                cancellingItem.status__c = 'Solicitado Cancelamento';
                cancellingItem.programacaoEntrega__c = deliveryRequest.id;

                deliveryRequest.status__c = 'Solicitado Cancelamento';

                cancellings.add(cancellingItem);
            }
            
            String responseOut = '';
            try{
                if (Test.isRunningTest()) {
                    TemplateDataIntegrationFields.DocumentSAP responseOutObject = new TemplateDataIntegrationFields.DocumentSAP();
                    responseOutObject.document = 'This is a Test';
                    responseOutObject.response = new List<TemplateDataIntegrationFields.ResponseSAP>();
                    responseOut = JSON.serialize(responseOutObject);
                }else {
                    responseOut = IntegrationOutboundCancellation.sendCancellation(orderItemIdSet, 'ZS');
                }
            }catch(Exception ex){
                throw new CancellingAppControllerException(Label.ErrorConnectingSAP);
            }
            hasSend = true; 

            System.debug(responseOut);
            if(responseOut != ''){
                TemplateDataIntegrationFields.DocumentSAP responseDocument = (TemplateDataIntegrationFields.DocumentSAP)JSON.deserialize(responseOut, TemplateDataIntegrationFields.DocumentSAP.class);

                for(TemplateDataIntegrationFields.ResponseSAP resp : responseDocument.response){
                    if(resp.message.contains(Label.DocumentoEmUsoSAP) || resp.message.contains(Label.DocumentoEmBloqueadoSAP)){
                        haserror = true;
                        throw new CancellingAppControllerException(resp.message);
                    }
                }
            }else{
                // throw new CancellingAppControllerException(Label.ErrorConnectingSAP);
            }
            sp = Database.setSavepoint();


            insert cancellings;
            callApprovalProcess(cancellings);

            update targetDeliveryRequests;

            String processNumber = '';
            for(Cancelamento__c cs : [SELECT SolicitacaoCancelamento__r.Name FROM Cancelamento__c WHERE Id IN : Collection.of(cancellings).pluckIds()]){
                processNumber += ' '+cs.SolicitacaoCancelamento__r.Name+', ';
            }
            return new CancellingResultReturnedData(processNumber);
            
        } catch(Exception e){
            if(sp != null)
                Database.rollback(sp);
            //Se caso ocorreu um erro de processamento e a integração já enviou o motivo de recusa para o sap, ocorrerá um Rollback na base
            //E o item sera enviado novamente, porem agora com o motivo de recusa em branco.
            if(hasSend){
                if(!orderItemIdSet.isEmpty()){
                    List<OrderITem> ordUpdateList = new List<OrderITem>();
                    for(id OrdId : orderItemIdSet){
                        ordUpdateList.add(new OrderItem(id = ordId, MOtivoRecusaItem__c = ''));
                    }
                    if(!ordUpdateList.isEmpty()){
                        OrderItemHelper.disableTrigger();
                        update ordUpdateList;
                        OrderItemHelper.enableTrigger();
                    }
                }
                if(hasError)
                    IntegrationOutboundCancellation.sendCancellationFuture(orderItemIdSet, '');
            }
            return new CancellingResultReturnedData(e);
        }
        
    }

    private static void callApprovalProcess(Cancelamento__c[] requests){
        Approval.ProcessSubmitRequest[] cancelApprovalRequests = new List<Approval.ProcessSubmitRequest>();
        for(Cancelamento__c cancelRequest : requests){
            
            String targetProcess = cancelRequest.statusSAP__c == 'Confirmado'? 'CancelamentoIntegradoSAPV2' : 'CancelamentoNaoIntegradoSAPV2';

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setComments('Cancelamento realizado pela tela de cancelamento.');
            request.setObjectId(cancelRequest.id);
            request.setSubmitterId(UserInfo.getUserId()); 
            request.setProcessDefinitionNameOrId(targetProcess);

            cancelApprovalRequests.add(request);
        }

        //Approval.process(cancelApprovalRequests);
    }

    private class CancellingWrapper{
        private Cancelamento__c cancellingRecord;
        private ProgramacaoEntrega__c deliveryRecord;
    }

    @RemoteAction
    public static ResponseDeliveryAppData getDeliveryData(String oppId) {
        ResponseDeliveryAppData response;
        try {
            Opportunity opp = [SELECT Id, accountId, recebedorMercadoria__c, condicaoExpedicao__c, localNegocio__c FROM Opportunity WHERE Id = :oppId];

            Id accId    = (opp.recebedorMercadoria__c != null ? opp.recebedorMercadoria__c : opp.accountId);
            Account acc = [SELECT Id, zonaTransporte__c FROM Account WHERE Id = :accId];
            
            LocalNegocio__c businessPlace = [SELECT Id, zonaTransporte__c FROM LocalNegocio__c WHERE Id = :opp.localNegocio__c];
            
            response        = new ResponseDeliveryAppData(); 
            response.data   = OpportunityAppController.getDeliveryData(acc, opp.condicaoExpedicao__c, businessPlace);
        } catch (Exception ex) {
            response = new ResponseDeliveryAppData(ex);
        }
        return response;
    }

    @RemoteAction
    public static List<AccountResultData> searchAccount(RecordQueryRequest request){

        Boolean iSRTV = isRTV();

        List<Id> allowedAccountIds = new List<Id>();

        if(isRTV){

            List<AccountShare> rtvAccountShareList = [SELECT accountId, userOrGroupId FROM AccountShare WHERE userOrGroupId = :UserInfo.getUserId()];

            allowedAccountIds = Collection.of(rtvAccountShareList).pluckIds(AccountShare.AccountId);
            
        }

        return searchAccountLookup(request, allowedAccountIds);

    }

    @RemoteAction
    public static List<AccountResultData> searchAccountLookup(RecordQueryRequest request, List<Id> allowedAccountIds){

        List<AccountResultData> result = new List<AccountResultData>();

        String accountNameFilter = '%' + request.searchTerm + '%';

        Map<String, LookupComponentRecordFilter> filterMap = new Map<String, LookupComponentRecordFilter>();

        Account[] targetAccounts;

        if(allowedAccountIds.isEmpty()){

            targetAccounts = [
                SELECT 
                    id,
                    Name,
                    TipoCliente__c,
                    RevendaAgenciadora__c,
                    RatingPagamento__c,
                    ShippingState,
                    ShippingCity,
                    NomeFazenda__c,
                    ContribuinteICMS__c,
                    ParentId,
                    Parent.BloqueadoCredito__c,
                    BloqueadoCredito__c,
                    CNPJ__c,
                    ExternalId__c,
                    localNegocio__c, 
                    localNegocio__r.id, 
                    localNegocio__r.name,
                    localNegocio__r.Descricao__c,
                    localNegocio__r.Codigo__c,
                    (
                        SELECT 
                            territorio__c,
                            territorio__r.name,
                            territorio__r.nomeTerritorio__c,
                            territorio__r.regional__c,
                            territorio__r.id,
                            territorio__r.rtv__c,
                            territorio__r.rtv__r.name,
                            territorio__r.gerente__c,
                            territorio__r.gerente__r.name,
                            territorio__r.diretor__c,
                            territorio__r.diretor__r.name,
                            territorio__r.diretor__r.managerId,
                            territorio__r.diretor__r.manager.name
                        FROM TerritoriosClientesConta__r
                    )
                FROM Account
                WHERE 
                    (
                            CNPJ__c         LIKE :accountNameFilter
                        OR  name            LIKE :accountNameFilter
                        OR  nomeFazenda__c  LIKE :accountNameFilter
                        OR  ShippingCity    LIKE :accountNameFilter
                        OR  ShippingState   LIKE :accountNameFilter
                        OR  ExternalId__c   LIKE :accountNameFilter
                    )
                    AND Status__c != 'bloqueado' 
                    AND RecordType.DeveloperName != 'Hierarquia' 
            ];
        
        } else {

            targetAccounts = [
                SELECT 
                    id,
                    Name,
                    TipoCliente__c,
                    RevendaAgenciadora__c,
                    RatingPagamento__c,
                    BloqueadoCredito__c,
                    ShippingState,
                    ShippingCity,
                    NomeFazenda__c,
                    ExternalId__c,
                    ContribuinteICMS__c,
                    ParentId,
                    Parent.BloqueadoCredito__c,
                    CNPJ__c,
                    localNegocio__c, 
                    localNegocio__r.id, 
                    localNegocio__r.name,
                    localNegocio__r.Descricao__c,
                    localNegocio__r.Codigo__c,
                    listaPreco__c,
                    recordType.developerName,
                    (
                        SELECT 
                            territorio__c,
                            territorio__r.name,
                            territorio__r.nomeTerritorio__c,
                            territorio__r.regional__c,
                            territorio__r.id,
                            territorio__r.rtv__c,
                            territorio__r.rtv__r.name,
                            territorio__r.gerente__c,
                            territorio__r.gerente__r.name,
                            territorio__r.diretor__c,
                            territorio__r.diretor__r.name,
                            territorio__r.diretor__r.managerId,
                            territorio__r.diretor__r.manager.name
                        FROM TerritoriosClientesConta__r
                    )
                FROM Account
                WHERE 
                    (
                            CNPJ__c         LIKE :accountNameFilter
                        OR  name            LIKE :accountNameFilter
                        OR  nomeFazenda__c  LIKE :accountNameFilter
                        OR  ShippingCity    LIKE :accountNameFilter
                        OR  ShippingState   LIKE :accountNameFilter
                        OR  ExternalId__c   LIKE :accountNameFilter
                    )
                    AND Status__c != 'bloqueado' 
                    AND RecordType.DeveloperName != 'Hierarquia'
                    AND id IN :allowedAccountIds
            ];

        }


        for(Account a : targetAccounts){
            result.add(new AccountResultData(a));
        }

        return result;

    }

    @RemoteAction
    public static List<AccountResultData> searchClientOpp(RecordQueryRequest request){

        List<AccountResultData> result = new List<AccountResultData>();

        String clientNameFilter = '%' + request.searchTerm + '%';

        Map<String, LookupComponentRecordFilter> filterMap = new Map<String, LookupComponentRecordFilter>();

        for(LookupComponentRecordFilter filter : request.filters){
            filterMap.put(filter.fieldApiName.toLowerCase(), filter);
        }
        
        if (filterMap.containsKey('opportunityid') && filterMap.get('opportunityid') != null){
            String oppId = filterMap.get('opportunityid').value;
            // System.debug('oppId => ' + oppId);
            List<Opportunity> oppList = [
                SELECT Id, AccountId FROM Opportunity WHERE Id =: oppId
            ];
            // System.debug('oppList => ' + oppList);

            if (oppList.size() > 0) {

                String accId = oppList[0].AccountId;

                Account[] targetAccounts = [
                    SELECT  id,
                            Name,
                            TipoCliente__c,
                            RevendaAgenciadora__c,
                            RatingPagamento__c,
                            ShippingState,
                            ShippingCity,
                            NomeFazenda__c,
                            ContribuinteICMS__c,
                            ParentId,
                            Parent.BloqueadoCredito__c,
                            CNPJ__c,
                            ExternalId__c,
                            localNegocio__c, 
                            localNegocio__r.id, 
                            localNegocio__r.name,
                            localNegocio__r.Descricao__c,
                            localNegocio__r.Codigo__c,
                            (
                                SELECT 
                                    territorio__c,
                                    territorio__r.name,
                                    territorio__r.nomeTerritorio__c,
                                    territorio__r.regional__c,
                                    territorio__r.id,
                                    territorio__r.rtv__c,
                                    territorio__r.rtv__r.name,
                                    territorio__r.gerente__c,
                                    territorio__r.gerente__r.name,
                                    territorio__r.diretor__c,
                                    territorio__r.diretor__r.name,
                                    territorio__r.diretor__r.managerId,
                                    territorio__r.diretor__r.manager.name
                                FROM TerritoriosClientesConta__r
                            )
                     FROM   Account
                    WHERE   (Id =: accId OR ParentId =: accId) 
                      AND Status__c != 'bloqueado' 
                      AND   (Name LIKE :clientNameFilter OR CNPJ__c LIKE :clientNameFilter)
                ];

                for(Account a : targetAccounts){
                    result.add(new AccountResultData(a));
                }

                return result;

            }else {
                throw new CancellingAppControllerException('Não é possível encontrar a oportunidade.');
            }

        } else {
            throw new CancellingAppControllerException('Não é possível procurar contas dentro da hierarquia do cliente.');
        }
    }

    @RemoteAction
    public static List<ResultData> searchLookup(RecordQueryRequest request){

        String targetColumnWhereClause = '%' + request.searchTerm + '%';
        String[] queryFilterList = new String[]{};

        String[] fieldsToQuery = new List<String>{
            'id', 
            'name'
        };

        if (request.filters != null){
            for(LookupComponentRecordFilter filter : request.filters){
                queryFilterList.add(
                    String.format('{0} {1} {2}', 
                    new List<String>{ 
                        filter.fieldApiName,
                        filter.operator,
                        filter.value
                    })
                );
            }
        }

        String queryAdditionalFilters = (
            !queryFilterList.isEmpty()?
            ' AND ' + String.join(queryFilterList, ' AND '):
            ''
        );

        String nameFilterClause;

        // must be API 32.0 or higher
        if (request.searchTarget != null){
            List<String> targets = request.searchTarget.split(';');

            if (targets.size() > 1){
                List<String> clauses = new List<String>();

                for(String targetField : targets){
                    clauses.add(targetField + ' LIKE :targetColumnWhereClause');
                }

                nameFilterClause = String.join(clauses, ' OR ');

            } else {
                nameFilterClause = request.searchTarget + ' LIKE :targetColumnWhereClause';
            }
        } else {
            nameFilterClause = 'name LIKE :targetColumnWhereClause';
        }

        if (request.returnedFields != null){
            for(String returnedField : request.returnedFields){
                fieldsToQuery.add(returnedField);
            }
        }

        String fieldsJoined = String.join(fieldsToQuery, ', ');

        // System.debug('query');
        // System.debug(String.format('SELECT {0} FROM {1} WHERE ({2}) {3} LIMIT 900', new List<String> {
        //         fieldsJoined, request.tableName, nameFilterClause, queryAdditionalFilters
        //     }));
        
        List<SObject> queryResult = Database.query(
            String.format('SELECT {0} FROM {1} WHERE ({2}) {3} LIMIT 900', new List<String> {
                fieldsJoined, request.tableName, nameFilterClause, queryAdditionalFilters
            })
        );

        return parseRowsToResult(queryResult, request);
    }
    
    private static List<ResultData> parseRowsToResult(List<SObject> selectResult, RecordQueryRequest request){
        List<ResultData> toReturn = new List<ResultData>();

        for(SObject row : selectResult){
            toReturn.add(new ResultData(row, request));
        }

        return toReturn;
    }

    // method can be invocated after checking if the customer type field is set as "Produtor Rural"
    public static Map<Id, Product2> getRAValidationProducts(Id[] productIds){
        return new Map<Id, Product2>([
            SELECT 
                id, name
            FROM Product2
            WHERE tipo__c = 'Defensivo'
            AND id IN :productIds
        ]);
    }

    public virtual class ResultData{
        public String id;
        public String name;
        public Map<String, String> returningFields;

        protected ResultData(){}
        public ResultData(SObject row, RecordQueryRequest request){

            String name = (String) row.get('name');

            this.id = row.id;
            this.name = name;

            Map<String, String> targetFields = new Map<String, String>{ 
                'name' => name, 
                'id'   => id 
            };

            if (request.returnedFields != null){
                for(String field : request.returnedFields){
                    targetFields.put(field, String.valueOf(
                        row.get(field) 
                    ));
                }
            }

            this.returningFields = new Map<String, String>(targetFields);
        }
    }

    public class RecordQueryRequest{
        public String searchTerm;
        public String tableName;
        public String searchTarget;
        public String[] returnedFields;
        public LookupComponentRecordFilter[] filters;
    }

    public class LookupComponentRecordFilter{
        public String fieldApiName;
        public String operator;
        public String value;
    }

    public class CancellingAppControllerException extends Exception{}

    public class ResponseOpportunityListData extends ResultTemplate {
        List<OppData> data = new List<OppData>();
        
        public ResponseOpportunityListData() {
            this.hasErrors      = false;
            this.message        = 'Success';
        }
        public ResponseOpportunityListData(Exception error) {
            this.data           = null;
            this.hasErrors      = true;
            this.message        = error.getMessage();
            this.stackStrace    = error.getStackTraceString();
        }
    }

    public class ResponseDeliveryData extends ResultTemplate {
        String type;

        public ResponseDeliveryData() {
            this.hasErrors      = false;
            this.message        = 'Success';
            this.type           = null;
        }       
        public ResponseDeliveryData(Exception error) {
            this.hasErrors      = true;
            this.message        = error.getMessage();
            this.stackStrace    = error.getStackTraceString();
            this.type           = null;
        }
        public ResponseDeliveryData(String htmlReturn, String type){
            this.type      = type;
            this.message   = htmlReturn;
            this.hasErrors = false;
        }
    }
    
    public class ResponseDeliveryAppData extends ResultTemplate {     
        DeliveryAppData data;   
        public ResponseDeliveryAppData() {
            this.hasErrors      = false;
            this.message        = 'Success';
        }       
        public ResponseDeliveryAppData(Exception error) {
            this.hasErrors      = true;
            this.message        = error.getMessage();
            this.stackStrace    = error.getStackTraceString();
        }
    }

    public class OppData {
        String id;                      // ProgramacaoEntrega__c.IdOportunidade__r.Id
        String name;                    // ProgramacaoEntrega__c.IdOportunidade__r.NumeroOportunidade__c
        String orderType;               // ProgramacaoEntrega__c.TipoOrdem__c
        Date billingDate;               // ProgramacaoEntrega__c.DataFaturamento__c
        String regionalName;            // ProgramacaoEntrega__c.Regional__r.Name
        String directorName;            // ProgramacaoEntrega__c.DiretorComercial__r.Name
        String status;                  // ProgramacaoEntrega__c.IdOportunidade__r.Status
        String rtvName;                 // ProgramacaoEntrega__c.NomeRTV__c
        AccData selectedAccount;        // ProgramacaoEntrega__c.EmissorOrdem__c
        DateTime createdDate;
        String deliveryId;
        String key;
        List<ProdData> products = new List<ProdData>();

        public OppData() {}
        
        public OppData(Opportunity opp) {
            this.id     = opp.id;
            this.name   = opp.numeroOportunidade__c;
        }
    }

    public class AccData {
        String id;                      // Account.Id
        String parentId;                // Account.ParentId
        String name;                    // Account.Name
        String cnpj;                    // Account.CNPJ__c
        String city;                    // Account.ShippingCity
        String state;                   // Account.ShippingSate
        String farm;                    // Account.NomeFazenda__c
        TerritoryData[] territories;
    }

    public class ProdData {
        String id;                      // ProgramacaoEntrega__c.Id
        String oppNumber;               // ProgramacaoEntrega__c.IdOportunidade__r.NumeroOportunidade__c
        Datetime oppCreatedDate;
        String orderType;               // ProgramacaoEntrega__c.TipoOrdem__c
        String regionalName;            // ProgramacaoEntrega__c.Regional__r.Name
        String directorName;            // ProgramacaoEntrega__c.DiretorComercial__r.Name
        String rtvName;                 // ProgramacaoEntrega__c.NomeRTV__c
        AccData selectedAccount;        // ProgramacaoEntrega__c.EmissorOrdem__c
        TerritoryData territoryData;    // ProgramacaoEntrega__c.Territory__c

        String itemId;                  // ProgramacaoEntrega__c.IdOpportunityLineItem__c
        Date billingDate;               // ProgramacaoEntrega__c.DataFaturamento__c
        String productId;               // ProgramacaoEntrega__c.Produto__r.Id
        Decimal multiplicity;           // ProgramacaoEntrega__c.Produto__r.Multiplicidade__c
        String status;                  // ProgramacaoEntrega__c.Status
        String statusSAP;               // ProgramacaoEntrega__c.StatusSAP__c
        String packing;                 // ProgramacaoEntrega__c.Produto__r.Embalagem__c
        String name;                    // ProgramacaoEntrega__c.Produto__r.Name
        String sku;                     // ProgramacaoEntrega__c.Produto__r.Sku__c
        Decimal liter;                  // ProgramacaoEntrega__c.Litros__c
        Decimal baseLiter;              // ProgramacaoEntrega__c.Produto__r.Litros__c
        Date deliveryDate;              // ProgramacaoEntrega__c.DataEntrega__c
        String orderNumber;             // ProgramacaoEntrega__c.NumeroPedidoCliente__c
        Decimal pricePerLiter;          // ProgramacaoEntrega__c.PrecoLitro__c
        Decimal quantity;               // ProgramacaoEntrega__c.QuantidadeProgramada__c
        Decimal priceList;              // ProgramacaoEntrega__c.PrecoListaReferencia__c
        Decimal salesPrice;             // ProgramacaoEntrega__c.PrecoVendas__c
        Decimal salesPriceWithInterest; // ProgramacaoEntrega__c.PrecoVendasJuros__c
        Decimal discount;               // ProgramacaoEntrega__c.Desconto__c
        Decimal interest;               // ProgramacaoEntrega__c.Juros__c
        Boolean confirmed;              // ProgramacaoEntrega__c.Confirmado__c
        AccData receiver;               // ProgramacaoEntrega__c.RecebedorOrdem__c
        AccData shipper;               // ProgramacaoEntrega__c.ClienteOrigemRemanejamento__c
        CulData culture;                // ProgramacaoEntrega__c.Cultura__c
        Date confirmedDate;             // ProgramacaoEntrega__c.DataConfirmacao__c
    }   

    public class CulData {
        String id;                      // Cultura__c.Id
        String name;                    // Cultura__c.Name
    }

    public class DeliveryData {
        public String id;
        public String orderType;               // ProgramacaoEntrega__c.tipoOrdem__c
        public Boolean confirmed;              // ProgramacaoEntrega__c.confirmado__c
        public String deliveryDate;            // ProgramacaoEntrega__c.dataEntrega__c
        public String selectedAccount;         // ProgramacaoEntrega__c.emissorOrdem__c
        public String receiver;                // ProgramacaoEntrega__c.recebedorOrdem__c
        public String shipper;                 // ProgramacaoEntrega__c.ClienteOrigemRemanejamento__c
        public Decimal quantity;               // ProgramacaoEntrega__c.quantidadeProgramada__c
        public String confirmedDate;           // ProgramacaoEntrega__c.dataHoraConfirmacao__c
        public String orderNumber;             // ProgramacaoEntrega__c.numeroPedidoCliente__c
        public String oppId;                   // ProgramacaoEntrega__c.idOportunidade__c
        public String oppItemId;               // ProgramacaoEntrega__c.idOpportunityLineItem__c
        public String productId;               // ProgramacaoEntrega__c.produto__c
        public Decimal liter;                  // ProgramacaoEntrega__c.produto__c
        public Decimal baseLiter;              // ProgramacaoEntrega__c.Produto__r.Litros__c
        public TerritoryData territoryData;    // ProgramacaoEntrega__c.territorio__c
        public Integer itineraryDays;          // ProgramacaoEntrega__c.dataFaturamento__c (deliveryDate - itineraryDays)
    }

    public class RequestDeliveryData {
        public List<DeliveryData> listDeliveryData = new List<DeliveryData>();
        public List<String> listToDelete           = new List<String>();
    }

    public class CancellingData{
        public Id deliveryRequestId;
        public String cancellingType;
        public String cancellingReason;
        public String cancellingDescription;
        public Integer quantity;
    }

    public class RequestChunk{
        public String today;
        public String idDelivery;
        public String numOpp;
    }

}