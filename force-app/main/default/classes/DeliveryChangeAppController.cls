public class DeliveryChangeAppController {
    
    public String opportunityId   {get; set;}
    public String opportunityName {get; set;}
    public String opportunityCity {get; set;}
    
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

    public DeliveryChangeAppController() {}

    public DeliveryChangeAppController(ApexPages.StandardController standardController) {
        this.isCustomerService = isCustomerService();
        this.isRTV             = isRTV();
        
        Id deliveryId = ApexPages.currentPage().getParameters().get('Id');
        if(deliveryId != null){
            for(AlteracaoDataEntrega__c delivery : [SELECT IdOportunidade__c, IdOportunidade__r.numeroOportunidade__c FROM AlteracaoDataEntrega__c WHERE Id = :deliveryId]){
                this.opportunityId = delivery.IdOportunidade__r.numeroOportunidade__c;
                this.opportunityName = delivery.IdOportunidade__c;
            }
        }
    }

    public static Boolean isCustomerService(){
        return (userProfile.name.containsIgnoreCase(CUSTOMER_SERVICE_PROFILE_TERM) || userProfile.name.containsIgnoreCase(GERENTE_REGIONAL_PROFILE_TERM) || userProfile.name.containsIgnoreCase(DIRETOR_COMERCIAL_PROFILE_TERM) || userProfile.name.containsIgnoreCase(ADMINISTRATOR_PROFILE_TERM));
    }

    public static Boolean isRTV(){
        return userProfile.name.containsIgnoreCase(RTV_PROFILE_TERM);
    }

    // public static String getProfile(){
    //     if(userProfile.name.containsIgnoreCase(CUSTOMER_SERVICE_PROFILE_TERM)){
    //         return 'CS';
    //     }else if(userProfile.name.containsIgnoreCase(GERENTE_REGIONAL_PROFILE_TERM)){
    //         return 'GR';
    //     }else if(userProfile.name.containsIgnoreCase(DIRETOR_COMERCIAL_PROFILE_TERM)){
    //         return 'DC';
    //     }else if(userProfile.name.containsIgnoreCase(ADMINISTRATOR_PROFILE_TERM)){
    //         return 'AD';
    //     }else{
    //         return 'RT';
    //     }
    // } 

    private static void fillMaps(List<ProgramacaoEntrega__c> listDelivery, List<ProgramacaoEntrega__c> listAllDelivery, Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory){

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

        List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                   Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                   QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                   Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                   Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                   RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                   EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                   EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                   ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                   ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                   IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.Moeda__c,
                                                   IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                   DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, TaxaDolar__c, CreatedDate
                                                   FROM ProgramacaoEntrega__c 
                                                   WHERE Confirmado__c    = true
                                                   AND   IdOportunidade__c<> null
                                                   AND   Integrado__c     = true
                                                   AND   Status__c        = 'Integrado'
                                                   AND   StatusSAP__c    != 'Cancelado' 
                                                   AND   StatusSAP__c    != 'Faturado'
                                                   AND   StatusSAP__c    != 'Bloqueio de Remessa'
                                                   AND   StatusSAP__c    != 'Em Remessa'
                                                   ORDER BY CreatedDate DESC, Id DESC
                                                   LIMIT 2500];

        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);                                           

        system.debug(listAllDelivery);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataOpp(String numOpp) {

        String currentProfileName;             
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();

        system.debug(currentProfileName);

        List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                   Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                   QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                   Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                   Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                   RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                   EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                   EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                   ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                   ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                   IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.Moeda__c,
                                                   IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                   DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, TaxaDolar__c, CreatedDate
                                                   FROM ProgramacaoEntrega__c 
                                                   WHERE Confirmado__c    = true
                                                   AND   IdOportunidade__c<> null
                                                   AND   Integrado__c     = true
                                                   AND   Status__c        = 'Integrado'
                                                   AND   StatusSAP__c    != 'Cancelado' 
                                                   AND   StatusSAP__c    != 'Faturado'
                                                   AND   StatusSAP__c    != 'Bloqueio de Remessa'
                                                   AND   StatusSAP__c    != 'Em Remessa'
                                                   AND   idOportunidade__r.NumeroOportunidade__c LIKE :numOpp
                                                   ORDER BY CreatedDate DESC, Id DESC
                                                   LIMIT 2500];

        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);                                           

        system.debug(listAllDelivery);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataChunk(RequestChunk req) {
          
        String currentProfileName;             
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();

        Long data = Long.valueof(req.today);
        Datetime dt = Datetime.newInstance(data);

        system.debug(currentProfileName);

        List<ProgramacaoEntrega__c> listDelivery= [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                                  Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                                  QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                                  Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                                  Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                                  RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.ParentId,
                                                  EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                                  EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, EmissorOrdem__r.ParentId,
                                                  ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                                  ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.ParentId, 
                                                  IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.Moeda__c,
                                                  IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, 
                                                  DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c, TaxaDolar__c, CreatedDate
                                                  FROM ProgramacaoEntrega__c 
                                                  WHERE (CreatedDate =: dt AND Id <: req.idDelivery 
                                                  AND   (Confirmado__c    = true)
                                                  AND   (IdOportunidade__c<> null)
                                                  AND   (Integrado__c     = true)
                                                  AND   (Status__c        = 'Integrado')
                                                  AND   (StatusSAP__c    != 'Cancelado') 
                                                  AND   (StatusSAP__c    != 'Faturado')
                                                  AND   (StatusSAP__c    != 'Bloqueio de Remessa')
                                                  AND   (StatusSAP__c    != 'Em Remessa')
                                                  AND   (idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp))

                                                  OR    (CreatedDate <: dt 
                                                  AND   (Confirmado__c    = true)
                                                  AND   (IdOportunidade__c<> null)
                                                  AND   (Integrado__c     = true)
                                                  AND   (Status__c        = 'Integrado')
                                                  AND   (StatusSAP__c    != 'Cancelado') 
                                                  AND   (StatusSAP__c    != 'Faturado')
                                                  AND   (StatusSAP__c    != 'Bloqueio de Remessa')
                                                  AND   (StatusSAP__c    != 'Em Remessa')
                                                  AND   (idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp))
                                                  ORDER BY CreatedDate DESC, Id DESC
                                                  LIMIT 500];

        fillMaps(listDelivery, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);                                       
        
        system.debug(listAllDelivery);

        return getReturn(listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory);

    }

    private static ResponseOpportunityListData getReturn(List<ProgramacaoEntrega__c> listAllDelivery,  Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory ){

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
            // else if(getProfile() == 'DC'){

            //     Territorio__c territory = [SELECT Id, Diretor__c FROM Territorio__c WHERE Diretor__c =: UserInfo.getUserId() LIMIT 1];
            //     List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
            //     if(mapTerritoryToDelivery.containsKey(territory.Id)){
            //         listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id));
            //     }
            //     responseData = new ResponseOpportunityListData();  
            //     if (!listDelivery.isEmpty()){
                
            //         Collection deliveryCollection = Collection.of(listDelivery);
                    
            //         deliveryRecordsIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.Id);
            //         oppItemIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.IdOpportunityLineItem__c);

            //         List<OrderItem> orderItems = [SELECT id, order.createdDate, order.OVSAP__c, orderId, programacaoEntrega__c 
            //                                       FROM OrderItem 
            //                                       WHERE programacaoEntrega__c IN :deliveryRecordsIds
            //                                       AND   MOtivoRecusaItem__c != 'Z1'
            //                                       AND   MOtivoRecusaItem__c != 'Z2'
            //                                       AND   MOtivoRecusaItem__c != 'ZS'];
                    
            //         Map<Id, OrderItem> deliveryIdToOrderItem = new Map<Id, OrderItem>();

            //         for(OrderItem orderItem : orderItems){
            //             deliveryIdToOrderItem.put(orderItem.programacaoEntrega__c, orderItem);
            //         }

            //         responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, deliveryIdToOrderItem, oppItemIds);
            //     }
            // }
            // else if (getProfile() == 'GR'){

            //     Territorio__c territory = [SELECT Id, Gerente__c FROM Territorio__c WHERE Gerente__c =: UserInfo.getUserId() LIMIT 1];
            //     List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
            //     if(mapTerritoryToDelivery.containsKey(territory.Id)){
            //         listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id));
            //     }
            //     responseData = new ResponseOpportunityListData();  
            //     if (!listDelivery.isEmpty()){
                
            //         Collection deliveryCollection = Collection.of(listDelivery);
                    
            //         deliveryRecordsIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.Id);
            //         oppItemIds = deliveryCollection.pluckIds(ProgramacaoEntrega__c.IdOpportunityLineItem__c);

            //         List<OrderItem> orderItems = [SELECT id, order.createdDate, order.OVSAP__c, orderId, programacaoEntrega__c 
            //                                       FROM OrderItem 
            //                                       WHERE programacaoEntrega__c IN :deliveryRecordsIds
            //                                       AND   MOtivoRecusaItem__c != 'Z1'
            //                                       AND   MOtivoRecusaItem__c != 'Z2'
            //                                       AND   MOtivoRecusaItem__c != 'ZS'];
                    
            //         Map<Id, OrderItem> deliveryIdToOrderItem = new Map<Id, OrderItem>();

            //         for(OrderItem orderItem : orderItems){
            //             deliveryIdToOrderItem.put(orderItem.programacaoEntrega__c, orderItem);
            //         }

            //         responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, deliveryIdToOrderItem, oppItemIds);
            //     }

            // }
            else {                
                
                Territorio__c territory = [SELECT Id, RTV__c FROM Territorio__c WHERE RTV__c =: UserInfo.getUserId() LIMIT 1];
                List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
                if(mapTerritoryToDelivery.containsKey(territory.Id)){
                    listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id));
                }
                responseData = new ResponseOpportunityListData();  
                if (!listDelivery.isEmpty()){
                
                    Collection deliveryCollection = Collection.of(listDelivery);
                    
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

        system.debug(responseData);
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

        Map<String, OpportunityLineItem> mapOppItem = new Map<String, OpportunityLineItem>();

        for (OpportunityLineItem oppItem : [SELECT Id, TaxaDolar__c FROM OpportunityLineItem WHERE Id IN :oppItemIds]) {
            mapOppItem.put(oppItem.id, oppItem);
        }

        for (ProgramacaoEntrega__c delivery : listDelivery){  
            if(deliveryIdToOrderItem.containsKey(delivery.id)){ 
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
                productData.deliveryName           = delivery.Name;
                productData.orderCreatedDate       = Date.valueOf(deliveryIdToOrderItem.get(delivery.id).Order.createdDate);
                productData.orderItemId            = deliveryIdToOrderItem.get(delivery.id).Id;
                productData.oppId                  = delivery.IdOportunidade__r.Id;
                productData.oppNumber              = delivery.IdOportunidade__r.NumeroOportunidade__c;
                productData.dolar                  = IntegrationUtils.checkDecimal(delivery.TaxaDolar__c); // (mapOppItem.containsKey(delivery.IdOpportunityLineItem__c) ? mapOppItem.get(delivery.IdOpportunityLineItem__c).TaxaDolar__c : delivery.TaxaDolar__c);
                productData.oppCurrency            = delivery.IdOportunidade__r.Moeda__c;
                productData.orderNumber            = deliveryIdToOrderItem.get(delivery.id).order.OVSAP__c;
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
                productData.pricePerLiter          = delivery.PrecoLitro__c;
                productData.quantity               = delivery.QuantidadeProgramada__c;
                productData.priceList              = delivery.PrecoListaReferencia__c;
                productData.salesPrice             = delivery.PrecoVenda__c;
                productData.salesPriceWithInterest = delivery.PrecoVendaJuros__c;
                productData.discount               = delivery.DescontoConcedido__c;
                productData.interest               = delivery.Juros__c;
                productData.confirmed              = delivery.Confirmado__c;
                productData.receiver               = accountDataProd;
                productData.culture                = cultureData;
                productData.confirmedDate          = delivery.DataConfirmacao__c;

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

                listProductData = new List<ProdData>();
                if (delivery.Confirmado__c){
                    listProductData.add(productData);
                }

                if(!mapIdToListProdData.ContainsKey(deliveryIdToOrderItem.get(delivery.id).orderId) && delivery.Confirmado__c){
                    mapIdToListProdData.put(deliveryIdToOrderItem.get(delivery.id).orderId, listProductData);
                    mapIdToDelivery.put(deliveryIdToOrderItem.get(delivery.id).orderId, delivery);
                }else if (delivery.Confirmado__c){
                    mapIdToListProdData.get(deliveryIdToOrderItem.get(delivery.id).orderId).add(productData);
                }
            }
        }        

        for (id idOpp : mapIdToDelivery.keySet()){
            ProgramacaoEntrega__c delivery     = mapIdToDelivery.get(idOpp);
            if(deliveryIdToOrderItem.containsKey(delivery.Id)){
                accountDataOpp                     = new AccData();
                accountDataOpp.id                  = delivery.EmissorOrdem__r.Id;
                accountDataOpp.parentId            = delivery.EmissorOrdem__r.ParentId;
                accountDataOpp.name                = delivery.EmissorOrdem__r.Name;
                accountDataOpp.cnpj                = delivery.EmissorOrdem__r.CNPJ__c;
                accountDataOpp.city                = delivery.EmissorOrdem__r.ShippingCity;
                accountDataOpp.state               = delivery.EmissorOrdem__r.ShippingState;
                accountDataOpp.farm                = delivery.EmissorOrdem__r.NomeFazenda__c;

                opportunityData                    = new OppData();
                opportunityData.id                 = deliveryIdToOrderItem.get(delivery.id).orderId;
                opportunityData.name               = deliveryIdToOrderItem.get(delivery.id).order.OVSAP__c;
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

                listOpportunityData.add(opportunityData);         
            } 
        }

        system.debug(listOpportunityData);

        return listOpportunityData;
    }

    @RemoteAction
    public static ResponseDeliveryChangeData createChangeDelivery(RequestDeliveryChangeData request) {
        Savepoint savepoint = null;
        Boolean hasSend = false;
        Boolean hasError = false;
        ResponseDeliveryChangeData responseData;
        List<AlteracaoDataEntregaItem__c> listChangeDelivery = new List<AlteracaoDataEntregaItem__c>();
        Map<Id, ProgramacaoEntrega__c> mapIdToDelivery   = new Map<Id, ProgramacaoEntrega__c>();
        AlteracaoDataEntrega__c deliveryChangeHeader = null;
        Set<id> orderItemIdSet = new Set<Id>();
        try {
            responseData = new ResponseDeliveryChangeData();

            for (DeliveryChangeData deliveryData : request.listDeliveryChangeData) {
                orderItemIdSet.add(deliveryData.orderItemId);
            }

            String responseOut = '';
            try{
                if (Test.isRunningTest()) {
                    TemplateDataIntegrationFields.DocumentSAP responseOutObject = new TemplateDataIntegrationFields.DocumentSAP();
                    responseOutObject.document = 'This is a Test';
                    responseOutObject.response = new List<TemplateDataIntegrationFields.ResponseSAP>();
                    responseOut = JSON.serialize(responseOutObject);
                }else {
                    responseOut = IntegrationOutboundCancellation.sendCancellation(orderItemIdSet, 'Z1');
                }
            }catch(Exception ex){
                throw new DeliveryChangeAppControllerException(Label.ErrorConnectingSAP);
            }
            hasSend = true;

            System.debug(responseOut);
            if(responseOut != ''){
                TemplateDataIntegrationFields.DocumentSAP responseDocument = (TemplateDataIntegrationFields.DocumentSAP)JSON.deserialize(responseOut, TemplateDataIntegrationFields.DocumentSAP.class);

                for(TemplateDataIntegrationFields.ResponseSAP resp : responseDocument.response){
                    if(resp.message.contains(Label.DocumentoEmUsoSAP) || resp.message.contains(Label.DocumentoEmBloqueadoSAP)){
                        hasError = true;

                        throw new DeliveryChangeAppControllerException(resp.message);
                    }
                }
            }else{
                // throw new DeliveryChangeAppControllerException(Label.ErrorConnectingSAP);
            }

            savepoint = Database.setSavepoint();
            Decimal taxaMedia = 1;
            CotacaoMoeda__c[] cotacoesMoeda = [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c < :Date.today() ORDER BY Data__c DESC LIMIT 1];
            taxaMedia = cotacoesMoeda[0].TaxaMedia__c;

            for (ProgramacaoEntrega__c delivery: [SELECT Id, cultura__c,DataIntegracao__c, IdOportunidade__r.Moeda__C, dataFaturamento__c, descontoConcedido__c, descontoTipoCliente__c, PrecoVendasComJurosUSDBRL__c,
                                                  diretorComercial__c, diretorNegocios__c, juros__c, litros__c, localNegocio__c, nomeRTV__c, numeroPedidoCliente__c, 
                                                  precoListaReferencia__c, precoVenda__c, precoVendaJuros__c, precoLitro__c, produto__c, regional__c, 
                                                  saldoLimiteCredito__c, territorio__c, tipoOrdem__c, valorFrete__c, valorTotal__c, ValorTotalUSD__c, valorUnitario__c,
                                                  idOpportunityLineItem__c, Status__c, StatusSAP__c, idOportunidade__c, idOportunidade__r.account.name, 
                                                  idOportunidade__r.account.tipoCliente__c, confirmado__c, dataEntrega__c, emissorOrdem__c, recebedorOrdem__c,
                                                  quantidadeProgramada__c, clienteOrigemRemanejamento__c, gerenteRegional__c, dataConfirmacao__c, nomeUsuarioConfirmacao__c, TaxaDolar__c
                                                  FROM ProgramacaoEntrega__c WHERE Id IN :request.listId AND confirmado__c = true]){
                mapIdToDelivery.put(delivery.id, delivery);
                if (deliveryChangeHeader == null) {
                    deliveryChangeHeader = new AlteracaoDataEntrega__c();
                    deliveryChangeHeader.DataSolicitacao__c                 = Date.today();
                    deliveryChangeHeader.DescricaoMotivo__c                 = request.description;
                    deliveryChangeHeader.DiretorComercial__c                = delivery.diretorComercial__c;
                    // deliveryChangeHeader.diretorNegocios__c                 = delivery.diretorNegocios__c;
                    deliveryChangeHeader.EmissorOrdem__c                    = delivery.EmissorOrdem__c;
                    deliveryChangeHeader.GerenteRegional__c                 = delivery.GerenteRegional__c;
                    deliveryChangeHeader.IdOportunidade__c                  = delivery.IdOportunidade__c;
                    deliveryChangeHeader.Pedido__c                          = request.orderId;
                    deliveryChangeHeader.Motivo__c                          = request.changeReason;
                    deliveryChangeHeader.NomeRTV__c                         = delivery.NomeRTV__c;
                    deliveryChangeHeader.NomeUsuarioConfirmacao__c          = delivery.NomeUsuarioConfirmacao__c;
                    deliveryChangeHeader.Moeda__c                           = delivery.IdOportunidade__r.Moeda__c;
                    deliveryChangeHeader.RecebedorOrdem__c                  = delivery.RecebedorOrdem__c;
                    deliveryChangeHeader.Status__c                          = 'Iniciado';
                    deliveryChangeHeader.TipoAlteracao__c                   = request.changeType;
                    deliveryChangeHeader.ValorTotalUSD__c                   = 0;
                    deliveryChangeHeader.ValorTotalBRL__c                   = 0;
                }
            }
            

            for (DeliveryChangeData deliveryData : request.listDeliveryChangeData) {
                deliveryChangeHeader.ValorTotalUSD__c += deliveryData.totalValueDolar;
                deliveryChangeHeader.ValorTotalBRL__c += deliveryData.totalValue;
                orderItemIdSet.add(deliveryData.orderItemId);
            }


            insert deliveryChangeHeader;
            Map<Id, DeliveryChangeWrapper> deliveryChangeMap = new Map<Id, DeliveryChangeWrapper>();
            List<ProgramacaoEntrega__c> listNewDeliveryDate = new List<ProgramacaoEntrega__c>();
            for (DeliveryChangeData deliveryData : request.listDeliveryChangeData) {
                ProgramacaoEntrega__c deliveryInfo               = mapIdToDelivery.get(deliveryData.id);
                AlteracaoDataEntregaItem__c deliveryChangeItem   = new AlteracaoDataEntregaItem__c();


                deliveryChangeItem.AlteracaoDataEntrega__c  = deliveryChangeHeader.Id;
                deliveryChangeItem.DataEntregaNova__c       = Date.valueOf(deliveryData.deliveryDate);
                deliveryChangeItem.DataFaturamento__c       = Date.valueOf(deliveryData.billingDate);
                deliveryChangeItem.DataEntregaOriginal__c   = deliveryInfo.dataEntrega__c;
                deliveryChangeItem.ItemPedido__c            = deliveryData.orderItemId;
                deliveryChangeItem.Moeda__c                 = deliveryData.oppCurrency;
                deliveryChangeItem.ValorBRL__c              = deliveryData.totalValue;
                deliveryChangeItem.ValorUSD__c              = deliveryData.totalValueDolar;
                deliveryChangeItem.Produto__c               = deliveryInfo.Produto__c;
                deliveryChangeItem.ProgramacaoEntrega__c    = deliveryInfo.id;
                deliveryChangeItem.QuantidadeAlterada__c    = deliveryData.quantity;
                deliveryChangeItem.QuantidadeProgramada__c  = deliveryInfo.QuantidadeProgramada__c;

                deliveryChangeItem.programacaoEntrega__c = deliveryInfo.id;
                deliveryInfo.Status__c = 'Solicitação alteração data de entrega';

                listChangeDelivery.add(deliveryChangeItem);

            }
            
            update mapIdToDelivery.values();
            insert listChangeDelivery;

            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setComments('submit by createChangeDelivery');
            submitRequest.setObjectId(deliveryChangeHeader.Id);

            submitRequest.setProcessDefinitionNameOrId('SoliAltDataProgramacaEntrega');

            System.debug('submitRequest => ' + submitRequest);

            Approval.ProcessResult processResult = Approval.process(submitRequest);

        } catch (Exception ex) {
            if(savepoint != null)
                Database.rollback(savepoint);
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
            responseData = new ResponseDeliveryChangeData(ex);
        }

        return responseData;
    }

    private class DeliveryChangeWrapper{
        private AlteracaoDataEntregaItem__c changeRecord;
        private ProgramacaoEntrega__c deliveryRecord;
    }
    @RemoteAction
    public static OpportunityAppReturnedBaseData getBaseData(){

        OpportunityAppReturnedBaseData opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData();
        
        try {
         
            OpportunityAppBaseData opportunityAppBaseData = new OpportunityAppBaseData();
            opportunityAppBaseData.setOrderReasons(getOrderReasons());
            opportunityAppBaseData.setChangeTypes(getChangeTypes());

            opportunityAppBaseData.setHolidays(OpportunityAppController.getHolidays());

            Decimal confirmationDeadlineDays = 0;

            List<PrazoConfirmacaoEntrega__c> confirmationDeadlineList = [SELECT dias__c FROM PrazoConfirmacaoEntrega__c ORDER BY CreatedDate DESC LIMIT 1];

            if (confirmationDeadlineList.size() > 0) {
                confirmationDeadlineDays = confirmationDeadlineList[0].dias__c;
            }

            opportunityAppBaseData.setConfirmationDeadline(confirmationDeadlineDays);

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(opportunityAppBaseData);

        } catch (Exception e){

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(e.getMessage());

        }

        return opportunityAppReturnedBaseData;
    }

    private static List<PicklistEntryData> getOrderReasons(){
        
        Schema.DescribeFieldResult orderReasonsFieldResult = AlteracaoDataEntrega__c.Motivo__c.getDescribe();
        List<Schema.PicklistEntry> orderReasonsPickListEntry = orderReasonsFieldResult.getPickListValues();

        List<PicklistEntryData> orderReasonsonsValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : orderReasonsPickListEntry){
            orderReasonsonsValuesList.add(new PicklistEntryData(value));
        }

        return orderReasonsonsValuesList;
    }

    private static List<PicklistEntryData> getChangeTypes(){
        
        Schema.DescribeFieldResult changeTypesFieldResult = AlteracaoDataEntrega__c.TipoAlteracao__c.getDescribe();
        List<Schema.PicklistEntry> changeTypesPickListEntry = changeTypesFieldResult.getPickListValues();

        List<PicklistEntryData> changeTypesValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : changeTypesPickListEntry){
            changeTypesValuesList.add(new PicklistEntryData(value));
        }

        return changeTypesValuesList;
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

    private static List<CultureData> getAllCultures(){

        List<CultureData> cultures = new List<CultureData>();

        for(Cultura__c culture : [SELECT id, descricao__c FROM Cultura__c]){
            cultures.add(new CultureData(culture));
        }

        return cultures;
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
                    ExternalId__c,
                    ContribuinteICMS__c,
                    ParentId,
                    BloqueadoCredito__c,
                    Parent.BloqueadoCredito__c,
                    CNPJ__c,
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
                            territorio__r.diretor__r.manager.name,
                        	territorio__r.regional__r.ACS__c
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
                            territorio__r.diretor__r.manager.name,
                        	territorio__r.regional__r.ACS__c
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
            System.debug(oppId);
            List<Opportunity> oppList = [
                SELECT Id, AccountId FROM Opportunity WHERE Id =: oppId
            ];

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
                                    territorio__r.diretor__r.name
                                FROM TerritoriosClientesConta__r
                            )
                     FROM   Account
                    WHERE   (Id =: accId OR ParentId =: accId) 
                      AND Status__c != 'bloqueado' 
                      AND   (Name LIKE :clientNameFilter OR CNPJ__c LIKE :clientNameFilter OR NomeFazenda__c LIKE :clientNameFilter)
                ];

                for(Account a : targetAccounts){
                    result.add(new AccountResultData(a));
                }

                return result;

            }else {
                throw new DeliveryChangeAppControllerException('Não é possível encontrar a oportunidade.');
            }

        } else {
            throw new DeliveryChangeAppControllerException('Não é possível procurar contas dentro da hierarquia do cliente.');
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

        System.debug('query');
        System.debug(String.format('SELECT {0} FROM {1} WHERE ({2}) {3} LIMIT 900', new List<String> {
                fieldsJoined, request.tableName, nameFilterClause, queryAdditionalFilters
            }));
        
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

    public class DeliveryChangeAppControllerException extends Exception{}

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

    public class ResponseDeliveryChangeData extends ResultTemplate {
        String type;

        public ResponseDeliveryChangeData() {
            this.hasErrors      = false;
            this.message        = 'Success';
            this.type           = null;
        }       
        public ResponseDeliveryChangeData(Exception error) {
            this.hasErrors      = true;
            this.message        = error.getMessage();
            this.stackStrace    = error.getStackTraceString();
            this.type           = null;
        }
        public ResponseDeliveryChangeData(String htmlReturn, String type){
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
        String orderNumber;
        String orderId;
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

        String orderType;               // ProgramacaoEntrega__c.TipoOrdem__c
        String regionalName;            // ProgramacaoEntrega__c.Regional__r.Name
        String directorName;            // ProgramacaoEntrega__c.DiretorComercial__r.Name
        String rtvName;                 // ProgramacaoEntrega__c.NomeRTV__c
        AccData selectedAccount;        // ProgramacaoEntrega__c.EmissorOrdem__c
        TerritoryData territoryData;    // ProgramacaoEntrega__c.Territory__c
        Date orderCreatedDate;
        String orderItemId;
        String oppId;
        String orderNumber;
        String oppNumber;
        String oppCurrency;
        Decimal dolar;
        String deliveryName;
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

    public class DeliveryChangeData {
        public String id;
        public String orderItemId;
        public String oppCurrency;
        public String deliveryDate;            // ProgramacaoEntrega__c.dataEntrega__c
        public Decimal quantity;               // ProgramacaoEntrega__c.quantidadeProgramada__c
        public String billingDate;
        public Decimal totalValue;
        public Decimal totalValueDolar;
    }

    public class RequestDeliveryChangeData {
        public String orderId;
        public String changeType;
        public String changeReason;
        public String description;
        public List<String> listId = new List<String>();
        public List<DeliveryChangeData> listDeliveryChangeData = new List<DeliveryChangeData>();
    }

    public class RequestChunk{
        public String today;
        public String idDelivery;
        public String numOpp;
    }

}