public class DeliveryAppController {
    
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

    public DeliveryAppController() {}

    public DeliveryAppController(ApexPages.StandardController standardController) {
        this.isCustomerService = isCustomerService();
        this.isRTV             = isRTV();
        
        Id deliveryId = ApexPages.currentPage().getParameters().get('Id');
        if(deliveryId != null){
            for(ProgramacaoEntrega__c delivery : [SELECT IdOportunidade__c, IdOportunidade__r.numeroOportunidade__c FROM ProgramacaoEntrega__c WHERE Id = :deliveryId]){
                this.opportunityId = delivery.IdOportunidade__r.numeroOportunidade__c;
                this.opportunityName = delivery.IdOportunidade__c;
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

    public static void fillMaps(List<ProgramacaoEntrega__c> listDelivery, List<ProgramacaoEntrega__c> listAllDelivery, Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory, Set<Id> opportunityIds){

        for(ProgramacaoEntrega__c delivery : listDelivery){

            if(!mapTerritoryToDelivery.containsKey(delivery.Territorio__c)) {
                mapTerritoryToDelivery.put(delivery.Territorio__c, new List<ProgramacaoEntrega__c>());
            }
            mapTerritoryToDelivery.get(delivery.Territorio__c).add(delivery);
            listAllDelivery.add(delivery);

            if (!mapAccToTerritory.containsKey(delivery.EmissorOrdem__r.Id)) {
                mapAccToTerritory.put(delivery.EmissorOrdem__r.Id, new List<TerritoryData>());
            }

            opportunityIds.add(delivery.idOportunidade__c);
        }
    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataOpp(String numOpp){

        ResponseOpportunityListData responseData;
        String currentProfileName;          
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();
        Set<Id> opportunityIds = new Set<Id>();   
        
        // system.debug(currentProfileName);

        List<ProgramacaoEntrega__c> listDeliverys = [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                              Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                              QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                              Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                              Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                              RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.BloqueadoCredito__c, 
                                              RecebedorOrdem__r.ParentId, RecebedorOrdem__r.Parent.BloqueadoCredito__c,
                                              EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                              EmissorOrdem__r.ShippingState, EmissorOrdem__r.BloqueadoCredito__c, EmissorOrdem__r.NomeFazenda__c, 
                                              EmissorOrdem__r.ParentId, EmissorOrdem__r.Parent.BloqueadoCredito__c,
                                              ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                              ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.BloqueadoCredito__c, 
                                              ClienteOrigemRemanejamento__r.ParentId, ClienteOrigemRemanejamento__r.Parent.BloqueadoCredito__c,
                                              IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.condicaoExpedicao__c,
                                              IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name,
                                              DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c,
                                              LocalNegocio__c, LocalNegocio__r.Name, LocalNegocio__r.Codigo__c, LocalNegocio__r.Descricao__c, CreatedDate
                                              FROM ProgramacaoEntrega__c 
                                              WHERE idOportunidade__c != null 
                                              AND (idOportunidade__r.NumeroOportunidade__c LIKE :numOpp)
                                              AND (Status__c = 'Faturado Parcial' OR Status__c = 'Bloqueado Crédito' OR Status__c = 'Liberado')
                                              AND (StatusSAP__c = 'Não confirmado' OR StatusSAP__c = 'Parcial' OR StatusSAP__c = 'Indisponível')
                                              ORDER BY CreatedDate ASC
                                              LIMIT 2500];

        fillMaps(listDeliverys, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory, opportunityIds);

        Map<Id, List<ProgramacaoEntrega__c>> opportunityIdToDeliveriesWithOVs = Collection.of([
            SELECT id, idOportunidade__c FROM ProgramacaoEntrega__c 
            WHERE  idOportunidade__c IN :opportunityIds 
            AND idOrderItem__c != null
            AND status__c = 'Integrado'
            AND statusSap__c = 'Confirmado'
        ]).groupByIds(ProgramacaoEntrega__c.IdOportunidade__c);

        try {
            if (isCustomerService()){
                responseData = new ResponseOpportunityListData();
                if (!listAllDelivery.isEmpty()){
                    responseData.data = fillResponseOpportunityListData(listAllDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);   
                }
            }
            else {
                List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
                for (Territorio__c territory : [SELECT Id, RTV__c FROM Territorio__c WHERE RTV__c =: UserInfo.getUserId()]){
                    if(mapTerritoryToDelivery.containsKey(territory.Id)){
                        listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id)); //retorna ProgramacaoEntrega__c
                    }
                }
                responseData = new ResponseOpportunityListData();  
                if (!listDelivery.isEmpty()){          
                    responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);
                }
            }
        } catch (Exception ex) {
            responseData = new ResponseOpportunityListData(ex);
            System.debug('Exception e ' + ex );
        }

        system.debug('responseData: ' + responseData);

        return responseData;
    
    }
    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListDataChunk(RequestChunk req){

        Long data = Long.valueof(req.today);

        Datetime dt = Datetime.newInstance(data);

        ResponseOpportunityListData responseData;
        String currentProfileName;          
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();
        Set<Id> opportunityIds = new Set<Id>();  

        List<ProgramacaoEntrega__c> listDeliverys = [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                              Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                              QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                              Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                              Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                              RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.BloqueadoCredito__c, 
                                              RecebedorOrdem__r.ParentId, RecebedorOrdem__r.Parent.BloqueadoCredito__c,
                                              EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                              EmissorOrdem__r.ShippingState, EmissorOrdem__r.BloqueadoCredito__c, EmissorOrdem__r.NomeFazenda__c, 
                                              EmissorOrdem__r.ParentId, EmissorOrdem__r.Parent.BloqueadoCredito__c,
                                              ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                              ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.BloqueadoCredito__c, 
                                              ClienteOrigemRemanejamento__r.ParentId, ClienteOrigemRemanejamento__r.Parent.BloqueadoCredito__c,
                                              IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.condicaoExpedicao__c,
                                              IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name,
                                              DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c,
                                              LocalNegocio__c, LocalNegocio__r.Name, LocalNegocio__r.Codigo__c, LocalNegocio__r.Descricao__c, CreatedDate
                                              FROM ProgramacaoEntrega__c 
                                              WHERE (CreatedDate =: dt AND Id <: req.idDelivery AND idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp
                                              AND (idOportunidade__c != null)
                                              AND (Status__c = 'Faturado Parcial' OR Status__c = 'Bloqueado Crédito' OR Status__c = 'Liberado')
                                              AND (StatusSAP__c = 'Não confirmado' OR StatusSAP__c = 'Parcial' OR StatusSAP__c = 'Indisponível'))

                                              OR (CreatedDate <: dt AND idOportunidade__r.NumeroOportunidade__c LIKE :req.numOpp
                                              AND (idOportunidade__c != null)
                                              AND (Status__c = 'Faturado Parcial' OR Status__c = 'Bloqueado Crédito' OR Status__c = 'Liberado')
                                              AND (StatusSAP__c = 'Não confirmado' OR StatusSAP__c = 'Parcial' OR StatusSAP__c = 'Indisponível'))
                                              
                                              ORDER BY CreatedDate DESC, Id DESC
                                              LIMIT 500];                                                                 

        fillMaps(listDeliverys, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory, opportunityIds);

         Map<Id, List<ProgramacaoEntrega__c>> opportunityIdToDeliveriesWithOVs = Collection.of([
            SELECT id, idOportunidade__c FROM ProgramacaoEntrega__c 
            WHERE  idOportunidade__c IN :opportunityIds 
            AND idOrderItem__c != null
            AND status__c = 'Integrado'
            AND statusSap__c = 'Confirmado'
        ]).groupByIds(ProgramacaoEntrega__c.IdOportunidade__c);

        try {
            if (isCustomerService()){
                responseData = new ResponseOpportunityListData();
                if (!listAllDelivery.isEmpty()){
                    responseData.data = fillResponseOpportunityListData(listAllDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);   
                }
            }
            else {
                List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
                for (Territorio__c territory : [SELECT Id, RTV__c FROM Territorio__c WHERE RTV__c =: UserInfo.getUserId()]){
                    if(mapTerritoryToDelivery.containsKey(territory.Id)){
                        listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id)); //retorna ProgramacaoEntrega__c
                    }
                }
                responseData = new ResponseOpportunityListData();  
                if (!listDelivery.isEmpty()){          
                    responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);
                }
            }
        } catch (Exception ex) {
            responseData = new ResponseOpportunityListData(ex);
            System.debug('Exception e' + ex);
        }

         system.debug('responseData: ' + responseData);

        return responseData;

    }

    @RemoteAction
    public static ResponseOpportunityListData getOpportunityListData(){

        ResponseOpportunityListData responseData;
        String currentProfileName;          
        List<ProgramacaoEntrega__c> listAllDelivery           = new List<ProgramacaoEntrega__c>();           
        Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<TerritoryData>> mapAccToTerritory = new Map<Id, List<TerritoryData>>();
        Set<Id> opportunityIds = new Set<Id>();   
        
        // system.debug(currentProfileName);

        List<ProgramacaoEntrega__c> listDeliverys = [SELECT Id, Name, IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, 
                                              Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, Produto__r.Litragem__c,
                                              QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, 
                                              Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName,
                                              Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, 
                                              RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, RecebedorOrdem__r.BloqueadoCredito__c, 
                                              RecebedorOrdem__r.ParentId, RecebedorOrdem__r.Parent.BloqueadoCredito__c,
                                              EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, 
                                              EmissorOrdem__r.ShippingState, EmissorOrdem__r.BloqueadoCredito__c, EmissorOrdem__r.NomeFazenda__c, 
                                              EmissorOrdem__r.ParentId, EmissorOrdem__r.Parent.BloqueadoCredito__c,
                                              ClienteOrigemRemanejamento__r.Id, ClienteOrigemRemanejamento__r.Name, ClienteOrigemRemanejamento__r.CNPJ__c, ClienteOrigemRemanejamento__r.ShippingCity, 
                                              ClienteOrigemRemanejamento__r.ShippingState, ClienteOrigemRemanejamento__r.NomeFazenda__c, ClienteOrigemRemanejamento__r.BloqueadoCredito__c, 
                                              ClienteOrigemRemanejamento__r.ParentId, ClienteOrigemRemanejamento__r.Parent.BloqueadoCredito__c,
                                              IdOportunidade__r.Id, DataConfirmacao__c, IdOportunidade__r.condicaoExpedicao__c,
                                              IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name,
                                              DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, Regional__r.NomeRegional__c,
                                              LocalNegocio__c, LocalNegocio__r.Name, LocalNegocio__r.Codigo__c, LocalNegocio__r.Descricao__c, CreatedDate
                                              FROM ProgramacaoEntrega__c 
                                              WHERE idOportunidade__c != null
                                              AND (Status__c = 'Faturado Parcial' OR Status__c = 'Bloqueado Crédito' OR Status__c = 'Liberado')
                                              AND (StatusSAP__c = 'Não confirmado' OR StatusSAP__c = 'Parcial' OR StatusSAP__c = 'Indisponível')
                                              ORDER BY CreatedDate DESC, Id DESC
                                              LIMIT 2500];

        fillMaps(listDeliverys, listAllDelivery, mapTerritoryToDelivery, mapAccToTerritory, opportunityIds);

        Map<Id, List<ProgramacaoEntrega__c>> opportunityIdToDeliveriesWithOVs = Collection.of([
            SELECT id, idOportunidade__c FROM ProgramacaoEntrega__c 
            WHERE  idOportunidade__c IN :opportunityIds 
            AND idOrderItem__c != null
            AND status__c = 'Integrado'
            AND statusSap__c = 'Confirmado'
        ]).groupByIds(ProgramacaoEntrega__c.IdOportunidade__c);
        System.debug('mapTerritoryToDelivery = ' + mapTerritoryToDelivery);
        try {
            if (isCustomerService()){
                System.System.debug('isCustomerService = true');
                responseData = new ResponseOpportunityListData();
                if (!listAllDelivery.isEmpty()){
                    responseData.data = fillResponseOpportunityListData(listAllDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);   
                }
            }
            else {
                List<ProgramacaoEntrega__c> listDelivery = new List<ProgramacaoEntrega__c>();
                for (Territorio__c territory : [SELECT Id, RTV__c FROM Territorio__c WHERE RTV__c =: UserInfo.getUserId()]){
                    if(mapTerritoryToDelivery.containsKey(territory.Id)){
                        listDelivery.addAll(mapTerritoryToDelivery.get(territory.Id)); //retorna ProgramacaoEntrega__c
                    }
                }
                system.debug('listDelivery before opp fill: ' + listDelivery);
                responseData = new ResponseOpportunityListData();  
                if (!listDelivery.isEmpty()){
                    responseData.data = fillResponseOpportunityListData(listDelivery, mapAccToTerritory, mapTerritoryToDelivery, opportunityIdToDeliveriesWithOVs);
                }
            }
        } catch (Exception ex) {
            responseData = new ResponseOpportunityListData(ex);
            System.debug('Exception e' + ex);
        }

        system.debug('responseData no filter: ' + responseData);
        return responseData;
    }

    public static List<OppData> fillResponseOpportunityListData(List<ProgramacaoEntrega__c> listDelivery, Map<Id, List<TerritoryData>> mapAccToTerritory, Map<Id, List<ProgramacaoEntrega__c>> mapTerritoryToDelivery, Map<Id, List<ProgramacaoEntrega__c>> opportunityIdToDeliveriesWithOVs){

        List<ProdData> listProductData;    
        List<OppData> listOpportunityData = new List<OppData>();

        Map<Id, List<ProdData>>        mapIdToListProdData = new Map<Id, List<ProdData>>();
        Map<Id, ProgramacaoEntrega__c> mapIdToDelivery     = new Map<Id, ProgramacaoEntrega__c>();

        //export scenario
        Map<String, List<ProdData>>        mapKeyToListProdData = new Map<String, List<ProdData>>();
        Map<String, ProgramacaoEntrega__c> mapKeyToDelivery     = new Map<String, ProgramacaoEntrega__c>();

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
            accountDataProd.block              = delivery.RecebedorOrdem__c != null ? delivery.RecebedorOrdem__r.BloqueadoCredito__c : null;
            
            productData                        = new ProdData();
            productData.id                     = delivery.Id;
            productData.deliveryName           = delivery.Name;
            productData.oppNumber              = delivery.IdOportunidade__r.NumeroOportunidade__c;
            productData.expeditionCondition    = delivery.IdOportunidade__r.condicaoExpedicao__c;
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
            productData.orderNumber            = delivery.NumeroPedidoCliente__c;
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

            if (delivery.LocalNegocio__c != null) {
                ResultData rd = new ResultData();
                rd.id                          = delivery.LocalNegocio__c;
                rd.name                        = delivery.LocalNegocio__r.Name;
                rd.returningFields             = new Map<String, String>();
                rd.returningFields.put('Codigo__c', delivery.LocalNegocio__r.Codigo__c);
                rd.returningFields.put('Descricao__c', delivery.LocalNegocio__r.Descricao__c);                
                productData.businessPlace      = rd;
            }

            accountDataProd                    = new AccData();
            accountDataProd.id                 = delivery.EmissorOrdem__r.Id;
            accountDataProd.parentId           = delivery.EmissorOrdem__r.ParentId;
            accountDataProd.name               = delivery.EmissorOrdem__r.Name;
            accountDataProd.cnpj               = delivery.EmissorOrdem__r.CNPJ__c;
            accountDataProd.city               = delivery.EmissorOrdem__r.ShippingCity;
            accountDataProd.state              = delivery.EmissorOrdem__r.ShippingState;
            accountDataProd.farm               = delivery.EmissorOrdem__r.NomeFazenda__c;
            accountDataProd.block              = delivery.EmissorOrdem__r != null ? (delivery.EmissorOrdem__r.ParentId != null ? delivery.EmissorOrdem__r.Parent.BloqueadoCredito__c : delivery.EmissorOrdem__r.BloqueadoCredito__c) : null;
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
            accountDataProd.block              = delivery.ClienteOrigemRemanejamento__c != null ? delivery.ClienteOrigemRemanejamento__r.BloqueadoCredito__c : null;
            productData.shipper                = accountDataProd;

            listProductData = new List<ProdData>();
            if (!delivery.Confirmado__c){
                listProductData.add(productData);
            }

            if(delivery.tipoOrdem__c == 'Exportação'){
                String key = delivery.IdOportunidade__c + '_' + delivery.EmissorOrdem__r.Id;
                if(!mapKeyToListProdData.containsKey(key) && !delivery.confirmado__c){
                    mapKeyToListProdData.put(key, listProductData);
                    mapKeyToDelivery.put(key, delivery);
                }else if (!delivery.Confirmado__c){
                    mapKeyToListProdData.get(key).add(productData);
                }
            } else {
                if(!mapIdToListProdData.ContainsKey(delivery.IdOportunidade__c) && !delivery.Confirmado__c){
                    mapIdToListProdData.put(delivery.IdOportunidade__c, listProductData);
                    mapIdToDelivery.put(delivery.IdOportunidade__c, delivery);
                }else if (!delivery.Confirmado__c){
                    mapIdToListProdData.get(delivery.IdOportunidade__c).add(productData);
                }
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
            accountDataOpp.block               = delivery.EmissorOrdem__r.ParentId != null ? delivery.EmissorOrdem__r.Parent.BloqueadoCredito__c : delivery.EmissorOrdem__r.BloqueadoCredito__c;
            
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
            opportunityData.ovNumbers          = opportunityIdToDeliveriesWithOVs.containsKey(delivery.idOportunidade__r.id) ? opportunityIdToDeliveriesWithOVs.get(delivery.idOportunidade__r.id).size() : 0;
            opportunityData.key                = idOpp + '_' + delivery.EmissorOrdem__r.Id;
            opportunityData.createdDate        = delivery.CreatedDate;
            opportunityData.deliveryId         = delivery.Id;

            listOpportunityData.add(opportunityData);
        }

        System.debug('mapKeyToDelivery => ' + JSON.serializePretty(mapKeyToDelivery));
        System.debug('mapKeyToListProdData => ' + JSON.serializePretty(mapKeyToListProdData));

        for(String key : mapKeyToDelivery.keySet()){
            ProgramacaoEntrega__c delivery     = mapKeyToDelivery.get(key);
            accountDataOpp                     = new AccData();
            accountDataOpp.id                  = delivery.EmissorOrdem__r.Id;
            accountDataOpp.parentId            = delivery.EmissorOrdem__r.ParentId;
            accountDataOpp.name                = delivery.EmissorOrdem__r.Name;
            accountDataOpp.cnpj                = delivery.EmissorOrdem__r.CNPJ__c;
            accountDataOpp.city                = delivery.EmissorOrdem__r.ShippingCity;
            accountDataOpp.state               = delivery.EmissorOrdem__r.ShippingState;
            accountDataOpp.farm                = delivery.EmissorOrdem__r.NomeFazenda__c;
            accountDataOpp.block               = delivery.EmissorOrdem__r.ParentId != null ? delivery.EmissorOrdem__r.Parent.BloqueadoCredito__c : delivery.EmissorOrdem__r.BloqueadoCredito__c;
            
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
            opportunityData.products           = mapKeyToListProdData.get(key);
            opportunityData.ovNumbers          = opportunityIdToDeliveriesWithOVs.containsKey(delivery.idOportunidade__r.id) ? opportunityIdToDeliveriesWithOVs.get(delivery.idOportunidade__r.id).size() : 0;
            opportunityData.key                = key;
            opportunityData.createdDate        = delivery.CreatedDate;
            opportunityData.deliveryId         = delivery.Id;

            listOpportunityData.add(opportunityData);
        }

        // system.debug(listOpportunityData);

        return listOpportunityData;
    }

    @RemoteAction
    public static ResponseDeliveryData upsertDeliveryData(RequestDeliveryData request) {

        Savepoint savepoint = Database.setSavepoint();
        ResponseDeliveryData responseData;
        List<String> deliveryIdList                             = new List<String>();
        List<Opportunity> listOpp                               = new List<Opportunity>();
        List<ProgramacaoEntrega__c> listDeliveryToDelete        = new List<ProgramacaoEntrega__c>();
        List<ProgramacaoEntrega__c> listDeliveryToUpsert        = new List<ProgramacaoEntrega__c>();
        Map<Id, ProgramacaoEntrega__c> mapIdToDelivery          = new Map<Id, ProgramacaoEntrega__c>();
        Map<String, ProgramacaoEntrega__c> mapKeyToDelivery     = new Map<String, ProgramacaoEntrega__c>();
        Map<String, String> mapIdToKey                          = new Map<String, String>();
        Map<String, List<String>> mapkeyToKey                   = new Map<String, List<String>>();
        Set<String> setItemIdDeliveryData                       = new Set<String>();
        Set<String> requestOpportunityIds                       = new Set<String>();
        Map<Id,ProgramacaoEntrega__c> mapDeleteDelivery         = new Map<Id,ProgramacaoEntrega__c>();
        try {
            responseData = new ResponseDeliveryData();
            Set<Id> productIds = new Set<Id>();

            for (DeliveryData delivery : request.listDeliveryData){
                setItemIdDeliveryData.add(delivery.oppItemId);
                productIds.add(delivery.productId);
                requestOpportunityIds.add(delivery.oppId);
            }

            System.debug('request.listDeliveryId  ' + mapDeleteDelivery);
            Id opportunityIdToValidateRA;
            String customerName;
            Set<Id> businessIdSet = new Set<Id>();

         

            List<ProgramacaoEntrega__c> listDelivery = [SELECT Id, cultura__c, dataFaturamento__c, descontoConcedido__c, descontoTipoCliente__c, 
                                                       diretorComercial__c, diretorNegocios__c, juros__c, litros__c, localNegocio__c, nomeRTV__c, numeroPedidoCliente__c, precoLista__c,
                                                       precoListaReferencia__c, precoVenda__c, precoVendaJuros__c, precoLitro__c, produto__c, regional__c, 
                                                       saldoLimiteCredito__c, territorio__c, territorio__r.RTV__C, tipoOrdem__c, valorFrete__c, valorTotal__c, valorUnitario__c,
                                                       idOpportunityLineItem__c, Status__c, StatusSAP__c, idOportunidade__c, idOportunidade__r.account.name, 
                                                       idOportunidade__r.account.tipoCliente__c, confirmado__c, dataEntrega__c, emissorOrdem__c, recebedorOrdem__c,
                                                       quantidadeProgramada__c, clienteOrigemRemanejamento__c, gerenteRegional__c, itinerario__c, precoVendasJurosUSD__c,
                                                       valorTotalReaisDolar__c, name, TaxaDolar__C, valorTotalUSD__c, Apuracao__c
                                                       FROM ProgramacaoEntrega__c WHERE (Id IN :request.listDeliveryId OR Id IN :request.listToDelete) AND confirmado__c = false];                                      

            for (ProgramacaoEntrega__c delivery: listDelivery){
                if(String.isNotBlank(delivery.idOpportunityLineItem__c)){
                    mapIdToDelivery.put(delivery.idOpportunityLineItem__c, delivery);
                }
                if(!mapDeleteDelivery.containsKey(delivery.Id)){
                    mapDeleteDelivery.put(delivery.Id, delivery);
                }
                businessIdSet.add(delivery.LocalNegocio__c);
                if (request.listToDelete.contains(delivery.id)) {
                    listDeliveryToDelete.add(delivery);
                }else {
                    String key = getDeliveryKey(delivery);
                    String keyWithOut = getDeliveryKeyWithOutConfirm(delivery);
                        System.debug('key => ' + key);
                        System.debug('keyWithOut => ' + keyWithOut);
                    mapIdToKey.put(delivery.id, key);

                    if(!mapKeyToKey.containsKey(keyWithOut)){
                        mapkeyToKey.put(keyWithOut, new List<String> {key});
                    }else{
                        mapkeyToKey.get(keyWithOut).add(key);
                    }

                    if (!mapKeyToDelivery.containsKey(key)) {
                        mapKeyToDelivery.put(key, delivery);

                    }else {
                        ProgramacaoEntrega__c d = mapKeyToDelivery.get(key);
                        System.debug('dJson ' + Json.serializePretty(d));
                        System.debug('deliveryJson ' + Json.serializePretty(delivery));
                        d.quantidadeProgramada__c   += delivery.quantidadeProgramada__c;
                        d.litros__c                 += delivery.litros__c;
                        d.valorTotal__c             += delivery.valorTotal__c;
                        d.valorTotalUSD__c          += delivery.valorTotalUSD__c;
                        d.precoLitro__c              = d.valorTotalReaisDolar__c / d.litros__c;
                        listDeliveryToDelete.add(delivery);
                    }
                    if(delivery.idOportunidade__r.account.tipoCliente__c == 'ZE'){
                        opportunityIdToValidateRA = delivery.idOportunidade__c;
                        customerName = delivery.idOportunidade__r.account.name;
                    }
                }
            }

            System.debug('mapDeleteDelivery ' + mapDeleteDelivery);  

            for(ProgramacaoEntrega__c delivery : listDelivery){

                String keyWithOut = getDeliveryKeyWithOutConfirm(delivery);
                
                String keyConfirm = getDeliveryKey(delivery);

                if(mapKeyToKey.containsKey(keyWithOut)){
                
                    List<String> lstkeyWithOut = mapKeyToKey.get(keyWithOut);

                    if(lstkeyWithOut.size() > 1){

                        for(String key : lstkeyWithOut){
                            
                            if(key == keyConfirm && delivery.Confirmado__c == false){
                            
                                if(mapKeyToDelivery.containsKey(keyConfirm)){
                                    mapKeyToDelivery.remove(keyConfirm);
                                }
                            }
                        }
                    }
                }
            }

            System.debug('mapKeyToKey ' + mapKeyToKey);

            System.debug('listDeliveryToDelete' + listDeliveryToDelete);
            System.debug('mapKeyToDelivery ' + mapKeyToDelivery);

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

            // System.debug('listDeliveryToDelete');
            // System.debug(listDeliveryToDelete);

            Boolean showRAWarning =  false;
            String  htmlReturn    =  '<div class="message-list"><p>O(s) Produto(s): </p>';
                    htmlReturn    += '<ul>';

            Integer internalDeadlineDays = PrazoInterno__c.getOrgDefaults().dias__c == null? 0 : Integer.valueOf(PrazoInterno__c.getOrgDefaults().dias__c);

            Map<Id, Decimal> accIdToQuantityMap = new Map<Id, Decimal>();
            Set<Id> accIdSet = new Set<Id>();
            Set<Id> accIdConfirmedSet = new Set<Id>();
            Set<Id> oppIdSet = new Set<Id>();
            Map<Id, Boolean> isAccValidMap = new Map<Id, Boolean>();
            Map<Id, Opportunity> opportunityIdMap = new Map<Id, Opportunity>([SELECT id, tipoOrdem__c FROM Opportunity WHERE Id IN :requestOpportunityIds]);
            for (DeliveryData delivery : request.listDeliveryData){
                ProgramacaoEntrega__c deliveryInfo              = mapIdToDelivery.get(delivery.oppItemId);
                if(opportunityIdMap.get(delivery.OppId).tipoOrdem__c != 'Bonificação'){
                    accIdSet.add(delivery.selectedAccount);
                }
                if(delivery.confirmed){
                    accIdConfirmedSet.add(delivery.selectedAccount);
                    if(!accIdToQuantityMap.containsKey(delivery.selectedAccount)){
                        accIdToQuantityMap.put(delivery.selectedAccount, 0);
                    }
                    accIdToQuantityMap.put(delivery.selectedAccount, accIdToQuantityMap.get(delivery.selectedAccount)+(deliveryInfo.precoVendaJuros__c * delivery.quantity));
                }
                oppIdSet.add(delivery.OppId);
                businessIdSet.add(delivery.businessPlaceId);
            }
            Map<Id, LocalNegocio__c> businessIdMap = new Map<Id, LocalNegocio__c>([SELECT id, ZonaTransporte__c FROM LocalNegocio__c WHERE Id IN :businessIdSet]);
            Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>([SELECT id, CondicaoExpedicao__c FROM Opportunity WHERE Id IN :oppIdSet]);
            Map<Id, Account> accIdMap = new Map<Id, Account>([SELECT id, LimiteCreditoTotal__C, SaldoLimiteCreditoFormula__c, zonaTransporte__c FROM Account WHERE Id IN :accIdSet]);
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            Map<Id, String> accountZonaMap = new Map<Id, String>();
            for(Id accId : accIdMap.keySet()){
                Account acc = accIdMap.get(accId);
                if(accIdConfirmedSet.contains(accId)){
                    if(acc.SaldoLimiteCreditoFormula__c < accIdToQuantityMap.get(accId)){
                        isAccValidMap.put(accId, false);
                        if(!request.creditValid)
                            throw new DeliveryAppControllerException(Label.ProgramacaoEntregaLimiteAtingido.replace('{{Valor}}', String.format(acc.SaldoLimiteCreditoFormula__c.setScale(2).format(), args)).replace('{{Confirmado}}',String.format(accIdToQuantityMap.get(accId).setScale(2).format(), args)));
                    }else{                    
                        isAccValidMap.put(accId, true);
                    }
                }
                accountZonaMap.put(accId, acc.zonaTransporte__c);
            }
            Set<String> shipmentConditionList = new Set<String>();
            for(Opportunity opp : oppIdMap.values()){
                shipmentConditionList.add(opp.CondicaoExpedicao__c);
            }
            Set<String> businessSet = new Set<String>();
            for(LocalNegocio__c business : businessIdMap.values()){
                businessSet.add(business.ZonaTransporte__c);
            }

            Map<String, itinerario__c> deliveryToItinerario = OpportunityAppController.getItinerary(accountZonaMap.values(), shipmentConditionList, businessSet);

            Set<Id> oppIdToApproveSet = new Set<Id>();
            for (DeliveryDAta deliveryData: request.listDeliveryData) {
                ProgramacaoEntrega__c deliveryInfo              = mapIdToDelivery.get(deliveryData.oppItemId);
                ProgramacaoEntrega__c deliveryToUpsert          = new ProgramacaoEntrega__c();
                Opportunity opp =  oppIdMap.get(deliveryData.oppId);

                String keyItinerario = accountZonaMap.get(deliveryData.selectedAccount)+'_'+opp.CondicaoExpedicao__c;

                // System.debug('***');
                // System.debug(deliveryData);
                // System.debug(deliveryInfo);
                // System.debug('***');

                if (deliveryData.orderType != 'Conta e Ordem') {
                    deliveryData.receiver = deliveryData.selectedAccount;
                }
                // System.debug(isAccValidMap.get(deliveryData.selectedAccount));
                Boolean isValid = true;
                if(isAccValidMap.containsKey(deliveryData.selectedAccount)) 
                    isValid = isAccValidMap.get(deliveryData.selectedAccount);
                if(!isValid){
                    oppIdToApproveSet.add(deliveryData.oppId);
                }

                deliveryToUpsert.Id                             = deliveryData.id;
                deliveryToUpsert.confirmado__c                  = (isValid ? deliveryData.confirmed : false);
                deliveryToUpsert.dataEntrega__c                 = (deliveryData.deliveryDate  != null ? Date.valueOf(deliveryData.deliveryDate) : null);
                deliveryToUpsert.emissorOrdem__c                = deliveryData.selectedAccount;
                deliveryToUpsert.recebedorOrdem__c              = deliveryData.receiver;
                deliveryToUpsert.clienteOrigemRemanejamento__c  = deliveryData.shipper;
                deliveryToUpsert.quantidadeProgramada__c        = deliveryData.quantity;
                deliveryToUpsert.dataConfirmacao__c             = (deliveryToUpsert.confirmado__c && deliveryData.confirmedDate != null ? Date.valueOf(deliveryData.confirmedDate) : null);
                deliveryToUpsert.nomeUsuarioConfirmacao__c      = (deliveryToUpsert.confirmado__c && deliveryData.confirmedDate != null ? UserInfo.getName() : null);

                deliveryToUpsert.idOportunidade__c              = deliveryData.oppId;
                deliveryToUpsert.idOpportunityLineItem__c       = deliveryData.oppItemId;

                deliveryToUpsert.numeroPedidoCliente__c         = deliveryData.orderNumber;
                deliveryToUpsert.tipoOrdem__c                   = deliveryData.orderType;
                deliveryToUpsert.produto__c                     = deliveryData.productId;

                deliveryToUpsert.prazoItinerario__c             = deliveryData.itineraryDays;
                deliveryToUpsert.prazoInterno__c                = internalDeadlineDays;

                LocalNegocio__c business = null;
                
                if (deliveryData.businessPlaceId != null) {
                    if(businessIdMap.containsKey(deliveryData.businessPlaceId)){
                        business = businessIdMap.get(deliveryData.businessPlaceId);
                        keyItinerario += '_'+business.ZonaTransporte__c;
                    }
                    deliveryToUpsert.LocalNegocio__c            = deliveryData.businessPlaceId;                    
                }else {
                    keyItinerario += '_'+deliveryInfo.localNegocio__c;
                    if(businessIdMap.containsKey(deliveryInfo.localNegocio__c)){
                        business = businessIdMap.get(deliveryInfo.localNegocio__c);
                        keyItinerario += '_'+business.ZonaTransporte__c;
                    }
                    deliveryToUpsert.localNegocio__c            = deliveryInfo.localNegocio__c;

                }

                deliveryToUpsert.cultura__c                     = deliveryInfo.cultura__c; 
                deliveryToUpsert.dataFaturamento__c             = OpportunityAppController.getBillingDate(deliveryToUpsert.dataEntrega__c, deliveryData.itineraryDays); 
                deliveryToUpsert.descontoConcedido__c           = deliveryInfo.descontoConcedido__c;
                deliveryToUpsert.descontoTipoCliente__c         = deliveryInfo.descontoTipoCliente__c;
                deliveryToUpsert.juros__c                       = deliveryInfo.juros__c;
                deliveryToUpsert.TaxaDolar__c                   = deliveryInfo.TaxaDolar__c;
                deliveryToUpsert.litros__c                      = deliveryData.baseLiter * deliveryData.quantity;
                deliveryToUpsert.precoListaReferencia__c        = deliveryInfo.precoListaReferencia__c;
                deliveryToUpsert.precoLista__c                  = deliveryInfo.precoLista__c;
                deliveryToUpsert.precoVenda__c                  = deliveryInfo.precoVenda__c;
                deliveryToUpsert.precoVendaJuros__c             = deliveryInfo.precoVendaJuros__c;
                deliveryToUpsert.precoVendasJurosUSD__c         = deliveryInfo.precoVendasJurosUSD__c;
                deliveryToUpsert.saldoLimiteCredito__c          = deliveryInfo.saldoLimiteCredito__c;
                deliveryToUpsert.valorFrete__c                  = deliveryInfo.valorFrete__c; 
                deliveryToUpsert.valorTotal__c                  = deliveryInfo.precoVendaJuros__c * deliveryData.quantity; 
                deliveryToUpsert.valorTotalUSD__c               = deliveryInfo.precoVendasJurosUSD__c * deliveryData.quantity; 
                deliveryToUpsert.precoLitro__c                  = deliveryToUpsert.valorTotal__c / deliveryToUpsert.quantidadeProgramada__c;
                deliveryToUpsert.valorUnitario__c               = deliveryInfo.valorUnitario__c;
                // System.debug(deliveryToItinerario);
                // System.debug(keyItinerario);
                if(deliveryToItinerario.containsKey(keyItinerario)){
                    deliveryToUpsert.itinerario__c                  = deliveryToItinerario.get(keyItinerario).Id;
                    deliveryToUpsert.prazoItinerario__c              = deliveryToItinerario.get(keyItinerario).Dias__c;
                }
                
                deliveryToUpsert.Status__c                      = (isValid  ? 'Liberado' : (deliveryData.confirmed ?  'Em aprovação de crédito'  : 'Liberado'));
                deliveryToUpsert.StatusSAP__c                   = 'Não Confirmado';


                String territorio;
                String nomeRTV;
                String diretorComercial;
                String rtvId;
                String gerenteRegional;
                String regional;
                String diretorNegocios;

                if (deliveryData.territoryData != null) {
                    territorio          = deliveryData.territoryData.territory;
                    nomeRTV             = deliveryData.territoryData.rtvName;
                    diretorComercial    = deliveryData.territoryData.directorId;
                    diretorNegocios     = deliveryData.territoryData.businessDirectorId;
                    gerenteRegional     = deliveryData.territoryData.managerId;
                    regional            = deliveryData.territoryData.regional;  
                    rtvId               = deliveryData.territoryData.rtvId;                  
                }else {
                    territorio          = deliveryInfo.territorio__c;
                    nomeRTV             = deliveryInfo.nomeRTV__c;
                    diretorComercial    = deliveryInfo.diretorComercial__c;
                    diretorNegocios     = deliveryInfo.diretorNegocios__c;
                    gerenteRegional     = deliveryInfo.gerenteRegional__c;
                    regional            = deliveryInfo.regional__c;  
                    rtvId               = deliveryInfo.territorio__r.RTV__C; 
                }

                deliveryToUpsert.Territorio__c          = territorio;
                deliveryToUpsert.RTV__c                 = rtvId;
                deliveryToUpsert.NomeRTV__c             = nomeRTV;
                deliveryToUpsert.DiretorComercial__c    = diretorComercial;
                deliveryToUpsert.GerenteRegional__c     = gerenteRegional;
                deliveryToUpsert.diretorNegocios__c     = diretorNegocios;
                deliveryToUpsert.Regional__c            = regional;

                String key = getDeliveryKey(deliveryToUpsert);
                String keyWithOut = getDeliveryKeyWithOutConfirm(deliveryToUpsert);
                
                // System.debug('key');
                // System.debug(key);
                if (!mapKeyToDelivery.containsKey(key)) {
                     System.debug('não contem');
                    if (mapIdToKey.containsKey(deliveryToUpsert.id)) {
                         System.debug('mapIdToKey => ' + mapIdToKey);
                         System.debug('contem id');
                        deliveryToUpsert.Id = null;
                        // mapKeyToDelivery.remove(mapIdToKey.get(deliveryToUpsert.id));
                    }
                    // System.debug('put');
                    mapKeyToDelivery.put(key, deliveryToUpsert);
                }else {
                    ProgramacaoEntrega__c d = mapKeyToDelivery.get(key);
                    // System.debug('deliveryToUpsert.id');
                    // System.debug('d.id');
                    // System.debug(deliveryToUpsert.id);
                    // System.debug(d.id);
                    if (deliveryToUpsert.id == d.id) {
                        System.debug('Id iguais' + deliveryToUpsert);
                        System.debug('Id iguais' + d);
                        mapKeyToDelivery.put(key, deliveryToUpsert);
                        System.debug(deliveryToUpsert);
                    }else {
                        System.debug('Id diferentes' + deliveryToUpsert);
                        System.debug('Id diferentes' + d);
                        d.quantidadeProgramada__c   += deliveryToUpsert.quantidadeProgramada__c;
                        d.litros__c                 += deliveryToUpsert.litros__c;
                        d.valorTotal__c             += deliveryToUpsert.valorTotal__c;
                        d.precoLitro__c             += deliveryToUpsert.precoLitro__c;
                        if (deliveryToUpsert.id != null) {
                            listDeliveryToDelete.add(deliveryToUpsert);
                        }
                        // System.debug(d);
                    }
                }

                if (deliveryToUpsert.id != null) {
                    deliveryIdList.add(deliveryToUpsert.id);
                }

                if(opportunityIdToValidateRA != null && idToProduct.keySet().contains(deliveryData.productId)){
                    if(deliveryData.confirmed && !opportunitiesWithRADocumentsIds.contains(deliveryData.oppId)){
                        showRAWarning = true;
                        htmlReturn += '<li>' + idToProduct.get(deliveryData.productId).name + '</li>';
                    }
                }
            }

            if(showRAWarning){
                htmlReturn += '</ul><p>Necessita(m) de RA. Favor providenciar o(s) documento(s) para liberação do faturamento.</p><p>Cliente: ' + customerName + '</p></div>';
                responseData = new ResponseDeliveryData(htmlReturn, 'warning');
            }

            for (String deliveryId : mapIdToKey.keySet()) {
                if (!deliveryIdList.contains(deliveryId)) {
                    if(mapDeleteDelivery.containskey(deliveryId)){
                            System.debug('deliveryId => ' + deliveryId);
                        listDeliveryToDelete.add(mapKeyToDelivery.get(mapIdToKey.get(deliveryId)));
                        mapKeyToDelivery.remove(mapIdToKey.get(deliveryId));
                    }
                }
            }

            System.debug('listDeliveryToDelete ' + listDeliveryToDelete);
            System.debug('mapKeyToDelivery.values() ' + mapKeyToDelivery.values());

            // System.debug('---');
            // System.debug('listDeliveryToDelete');
            // System.debug(listDeliveryToDelete);
            // System.debug('---');

            // System.debug('===');
            // System.debug(mapKeyToDelivery);
            // System.debug('===');

            upsert (mapKeyToDelivery.values());
            delete listDeliveryToDelete;

            listDeliveryToDelete = new List<ProgramacaoEntrega__c>();
            mapKeyToDelivery = new Map<String, ProgramacaoEntrega__c>();

            List<ProgramacaoEntrega__c> listaDelivery = [SELECT Id, cultura__c, name, dataFaturamento__c, descontoConcedido__c, descontoTipoCliente__c, 
                                                        diretorComercial__c, diretorNegocios__c, juros__c, litros__c, localNegocio__c, nomeRTV__c, numeroPedidoCliente__c, 
                                                        precoListaReferencia__c, precoVenda__c, precoVendaJuros__c, precoLitro__c, produto__c, regional__c, 
                                                        saldoLimiteCredito__c, territorio__c, tipoOrdem__c, valorFrete__c, valorTotal__c, valorUnitario__c,
                                                        idOpportunityLineItem__c, Status__c, StatusSAP__c, idOportunidade__c, idOportunidade__r.account.name, 
                                                        idOportunidade__r.account.tipoCliente__c, confirmado__c, dataEntrega__c, emissorOrdem__c, recebedorOrdem__c,
                                                        quantidadeProgramada__c, clienteOrigemRemanejamento__c, gerenteRegional__c, itinerario__c, precoVendasJurosUSD__c, valorTotalUSD__c, 
                                                        valorTotalReaisDolar__c, Apuracao__c
                                                        FROM ProgramacaoEntrega__c WHERE idOportunidade__c = :request.oppId AND confirmado__c = false AND Status__c != 'Cancelado'];

            for (ProgramacaoEntrega__c delivery: listaDelivery){
                String key = getDeliveryKey(delivery);
                if (!mapKeyToDelivery.containsKey(key)) {
                    mapKeyToDelivery.put(key, delivery);
                }else {
                    ProgramacaoEntrega__c d      = mapKeyToDelivery.get(key);
                    System.debug('dJson ' + Json.serializePretty(d));
                    System.debug('deliveryJson ' +Json.serializePretty(delivery));
                    d.quantidadeProgramada__c   += delivery.quantidadeProgramada__c;
                    d.litros__c                 += delivery.litros__c;
                    d.valorTotal__c             += delivery.valorTotal__c;
                    d.valorTotalUSD__c          += delivery.valorTotalUSD__c;
                    d.precoLitro__c              = d.valorTotalReaisDolar__c / d.litros__c;

                    listDeliveryToDelete.add(delivery);
                }
            }

             for(ProgramacaoEntrega__c delivery : listaDelivery){

                String keyWithOut = getDeliveryKeyWithOutConfirm(delivery);
                
                String keyConfirm = getDeliveryKey(delivery);

                if(mapKeyToKey.containsKey(keyWithOut)){
                
                    List<String> lstkeyWithOut = mapKeyToKey.get(keyWithOut);

                    if(lstkeyWithOut.size() > 1){

                        for(String key : lstkeyWithOut){
                            
                            if(key == keyConfirm && delivery.Confirmado__c == false){
                            
                                if(mapKeyToDelivery.containsKey(keyConfirm)){
                                    System.debug(mapKeyToDelivery);
                                }
                            }
                        }
                    }
                }
            }

            // System.debug('---');
            // System.debug('listDeliveryToDelete');
            // System.debug(listDeliveryToDelete);
            // System.debug('---');

            // System.debug('===');
            // System.debug(mapKeyToDelivery);
            // System.debug('===');

            System.debug('listDeliveryToDelete ' + listDeliveryToDelete);
            System.debug('mapKeyToDelivery.values() ' + mapKeyToDelivery.values());

            upsert (mapKeyToDelivery.values());
            delete listDeliveryToDelete;

            Map<Id, Set<String>> programacaoNumberMap = new Map<Id, Set<String>>();
            for(ProgramacaoEntrega__c delivery : [SELECT id, idOportunidade__c, Name FROM ProgramacaoEntrega__c WHERE id IN : Collection.of(mapKeyToDelivery.values()).pluckIds() AND Status__c = 'Em aprovação de crédito']){
                if(!programacaoNumberMap.containsKey(delivery.idOportunidade__c)){
                    programacaoNumberMap.put(delivery.idOportunidade__c, new Set<String>());
                }
                programacaoNumberMap.get(delivery.idOportunidade__c).add(delivery.Name);
            }
            if(!oppIdToApproveSet.isEmpty())
                OpportunityHelper.sendApproveCredit(oppIdToApproveSet, programacaoNumberMap);


        } catch (Exception ex) {
            System.debug('Exception e' + ex);
            Database.rollback(savepoint);
            responseData = new ResponseDeliveryData(ex);
        }

        return responseData;
    }

    public static String getDeliveryKey(ProgramacaoEntrega__c delivery) {
        return  ''
            +   delivery.territorio__c 
            +   delivery.tipoOrdem__c  
            +   delivery.idOportunidade__c 
            +   delivery.produto__c 
            +   delivery.confirmado__c 
            +   delivery.Status__c
            +   delivery.dataEntrega__c 
            +   delivery.emissorOrdem__c 
            +   delivery.recebedorOrdem__c
            +   delivery.clienteOrigemRemanejamento__c
        ;
    }

    public static String getDeliveryKeyWithOutConfirm(ProgramacaoEntrega__c delivery) {
        return  ''
            +   delivery.territorio__c 
            +   delivery.tipoOrdem__c  
            +   delivery.idOportunidade__c 
            +   delivery.produto__c 
            +   delivery.Status__c
            +   delivery.dataEntrega__c 
            +   delivery.emissorOrdem__c 
            +   delivery.recebedorOrdem__c
            +   delivery.clienteOrigemRemanejamento__c
        ;
    }

    @RemoteAction
    public static OpportunityAppReturnedBaseData getBaseData(){

        OpportunityAppReturnedBaseData opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData();
        
        try {
         
            OpportunityAppBaseData opportunityAppBaseData = new OpportunityAppBaseData(
                null,
                null,
                null,
                getOrderRecordTypes(),
                null,
                null,
                getAllCultures()
            );

            opportunityAppBaseData.setHolidays(OpportunityAppController.getHolidays());

            Decimal confirmationDeadlineDays = 0;

            List<PrazoConfirmacaoEntrega__c> confirmationDeadlineList = [SELECT dias__c FROM PrazoConfirmacaoEntrega__c ORDER BY CreatedDate DESC LIMIT 1];

            if (confirmationDeadlineList.size() > 0) {
                confirmationDeadlineDays = confirmationDeadlineList[0].dias__c;
            }

            opportunityAppBaseData.setConfirmationDeadline(confirmationDeadlineDays);

            opportunityAppBaseData.setDeliveryQuantityLimit(getDeliveryQuantityLimit());

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(opportunityAppBaseData);

        } catch (Exception e){

            opportunityAppReturnedBaseData = new OpportunityAppReturnedBaseData(e.getMessage());
            System.debug('Exception e' + e);

        }
        return opportunityAppReturnedBaseData;
    }

    public static Integer getDeliveryQuantityLimit(){
        
        LimiteProgramacoesEntrega__c deliveryQuantityCustomSetting = LimiteProgramacoesEntrega__c.getOrgDefaults();

        if(deliveryQuantityCustomSetting.quantidadeMaxima__c == null){
            return 0;
        }

        return Integer.valueOf(deliveryQuantityCustomSetting.quantidadeMaxima__c);
        
    }

    @RemoteAction
    public static ResponseDeliveryAppData getBaseDeliveryData(String oppId) {
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
            System.debug('Exception e' + ex);
        }
        return response;
    }

    @RemoteAction
    public static ResponseDeliveryAppData getDeliveryData(RequestBusinessData req) {
        ResponseDeliveryAppData response;
        try {
            Id accId    = (req.receiverId != null ? req.receiverId : req.emitterId);
            Account acc = [SELECT Id, zonaTransporte__c, localNegocio__c FROM Account WHERE Id = :accId];

            req.businessPlaceId = req.businessPlaceId != null? req.businessPlaceId : acc.localNegocio__c;

            LocalNegocio__c businessPlace = [
                SELECT id, name, zonaTransporte__c
                FROM LocalNegocio__c
                WHERE id = :req.businessPlaceId
            ];
            response        = new ResponseDeliveryAppData(); 
            response.data   = OpportunityAppController.getDeliveryData(acc, req.expeditionCondition, businessPlace);
        } catch (Exception ex) {
            response = new ResponseDeliveryAppData(ex);
            System.debug('Exception e' + ex);
        }
        return response;
    }

    private static List<PicklistEntryData> getOrderRecordTypes(){

        Schema.DescribeFieldResult orderTypesFieldResult = Opportunity.TipoOrdem__c.getDescribe();
        List<Schema.PicklistEntry> orderTypesPickListEntry = orderTypesFieldResult.getPickListValues();

        List<PicklistEntryData> orderTypesValuesList = new List<PicklistEntryData>();

        for(Schema.PicklistEntry value : orderTypesPickListEntry){
            orderTypesValuesList.add(new PicklistEntryData(value));
        }

        return PicklistEntryData.filterInvalidValues(orderTypesValuesList);
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
                    BloqueadoCredito__c,
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
                    ShippingState,
                    ShippingCity,
                    NomeFazenda__c,
                    BloqueadoCredito__c,
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
            // System.debug(oppId);
            List<Opportunity> oppList = [
                SELECT Id, AccountId, Account.ParentId FROM Opportunity WHERE Id =: oppId
            ];

            if (oppList.size() > 0) {

                String accId = oppList[0].Account.ParentId;
                if (String.isBlank(accId)) {
                    accId = oppList[0].AccountId;                    
                }

                Account[] targetAccounts = [
                    SELECT  id,
                            Name,
                            TipoCliente__c,
                            RevendaAgenciadora__c,
                            RatingPagamento__c,
                            ShippingState,
                            ShippingCity,
                            BloqueadoCredito__c,
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
                                    territorio__r.diretor__r.manager.name
                                FROM TerritoriosClientesConta__r
                            )
                     FROM   Account
                    WHERE   (Id =: accId OR ParentId =: accId) 
                      AND Status__c != 'bloqueado'
                      AND   (
                                    CNPJ__c         LIKE :clientNameFilter
                                OR  name            LIKE :clientNameFilter
                                OR  nomeFazenda__c  LIKE :clientNameFilter
                                OR  ShippingCity    LIKE :clientNameFilter
                                OR  ShippingState   LIKE :clientNameFilter
                                OR  ExternalId__c   LIKE :clientNameFilter
                            )
                ];

                for(Account a : targetAccounts){
                    result.add(new AccountResultData(a));
                }

                return result;

            }else {
                System.debug('Não é possível encontrar a oportunidade.');
                throw new DeliveryAppControllerException('Não é possível encontrar a oportunidade.');
            }

        } else {
            System.debug('Não é possível procurar contas dentro da hierarquia do cliente.');
            throw new DeliveryAppControllerException('Não é possível procurar contas dentro da hierarquia do cliente.');    
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

    public class DeliveryAppControllerException extends Exception{}

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
        Integer ovNumbers;
        String key;                     //key used to match by opp id and emissor id
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
        Boolean block;                   // Account.BloqueadoCredito__c
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
        String oppNumber;
        String expeditionCondition;
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
        AccData shipper;                // ProgramacaoEntrega__c.ClienteOrigemRemanejamento__c
        CulData culture;                // ProgramacaoEntrega__c.Cultura__c
        Date confirmedDate;             // ProgramacaoEntrega__c.DataConfirmacao__c
        ResultData businessPlace;       // ProgramacaoEntrega__c.LocalNegocio__c
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
        // String businessPlaceId;                // ProgramacaoEntrega__c.LocalNegocio__c
        public Decimal liter;                  // ProgramacaoEntrega__c.produto__c
        public Decimal baseLiter;              // ProgramacaoEntrega__c.Produto__r.Litros__c
        public TerritoryData territoryData;    // ProgramacaoEntrega__c.territorio__c
        public Integer itineraryDays;          // ProgramacaoEntrega__c.dataFaturamento__c (deliveryDate - itineraryDays)
        public String itineraryId;
        public String businessPlaceId;
    }

    public class RequestDeliveryData {
        public String oppId;
        public Boolean creditValid;
        public List<String> listToDelete           = new List<String>();
        public List<String> listProductsId         = new List<String>();
        public List<String> listDeliveryId         = new List<String>();
        public List<DeliveryData> listDeliveryData = new List<DeliveryData>();
    }
    
    public class RequestBusinessData {
        public String emitterId;
        public String receiverId;
        public String businessPlaceId;
        public String expeditionCondition;
    }

    public class RequestChunk{
        public String today;
        public String idDelivery;
        public String numOpp;
    }

}