public class ProgramacaoEntregaHelper {

    private static Boolean isEnabled;

    static{
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }
        
    @TestVisible
    private static final Id DEFAULT_PRICEBOOK_ID;

    @TestVisible
    private static Set<String> invalidOrderStatus;

    static{
        DEFAULT_PRICEBOOK_ID = Test.isRunningTest()?
            Test.getStandardPricebookId():
            [
                SELECT id 
                FROM Pricebook2 
                WHERE isStandard = true 
                LIMIT 1
            ].id;
        invalidOrderStatus = new Set<String>{'Solicitado Cancelamento', 'Solicitação alteração data de entrega',  'Em aprovação de crédito'};
    }

    
    public static void updateApuracaoRelation(Map<Id, ProgramacaoEntrega__c> newContextMap) {

        Map<Id, ProgramacaoEntrega__c> updateDeliveryMap = new Map<Id, ProgramacaoEntrega__c>();

        Map<String, List<ProgramacaoEntrega__c>> criterioApuracaoToItemListMap = new Map<String, List<ProgramacaoEntrega__c>>();

        for (ProgramacaoEntrega__c item : newContextMap.values()) {

            if(item.TipoOrdem__c != 'Bonificação' && item.TipoOrdem__c != 'Devolução com NF Cliente' && item.TipoOrdem__c != 'Devolução com Nossa NF'){

                updateDeliveryMap.put(item.id, new ProgramacaoEntrega__c(id = item.id));

                if (!criterioApuracaoToItemListMap.containsKey(item.CriterioApuracao__c)) {
                    criterioApuracaoToItemListMap.put(item.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                }
                criterioApuracaoToItemListMap.get(item.CriterioApuracao__c).add(item);
            }
        }

        Map<String, Apuracao__c> criterioToApuracaoMap = new Map<String, Apuracao__c>();
        if(!criterioApuracaoToItemListMap.isEmpty()){
            for (Apuracao__c apuracao : [SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN :criterioApuracaoToItemListMap.keySet() FOR UPDATE]) {
                criterioToApuracaoMap.put(apuracao.CriterioApuracao__c, apuracao);
            }
        }

        Map<String, Apuracao__c> apuracoesToInsertMap = new Map<String, Apuracao__c>();

        for (String key : criterioApuracaoToItemListMap.keySet()) {
            if (criterioToApuracaoMap.containsKey(key)) {
                criterioToApuracaoMap.get(key).Atualizado__c = false;
                for (ProgramacaoEntrega__c item : criterioApuracaoToItemListMap.get(key)) {
                    updateDeliveryMap.get(item.Id).Apuracao__c = criterioToApuracaoMap.get(key).Id;
                }
            } else {
                ProgramacaoEntrega__c item = criterioApuracaoToItemListMap.get(key)[0];

                if (item.EmissorOrdem__C != null && 
                    item.Produto__c != null && 
                    item.DataFaturamento__c != null && 
                    item.Territorio__c != null && 
                    !apuracoesToInsertMap.containsKey(key)) {
                    apuracoesToInsertMap.put(key,
                        new Apuracao__c(
                            NomeConta__c       = item.EmissorOrdem__C,
                            Territorio__c      = item.Territorio__c,
                            Produto__c         = item.Produto__c,
                            DataFaturamento__c = Date.newInstance(item.DataFaturamento__c.year(), item.DataFaturamento__c.month(), 01),
                            Atualizado__c      = false
                        )
                    );
                }
            }
        }

        if(!criterioToApuracaoMap.isEmpty())
            update criterioToApuracaoMap.values();

        if (!apuracoesToInsertMap.isEmpty()) {
            insert apuracoesToInsertMap.values();
        }

        List<Id> apuracaoIds = new List<Id>();
        for (Apuracao__c a : apuracoesToInsertMap.values()) {
            apuracaoIds.add(a.Id);
        }

        for (Apuracao__c apuracao : [SELECT Id, CriterioApuracao__c FROM Apuracao__c WHERE Id IN :apuracaoIds FOR UPDATE]) {
            if(criterioApuracaoToItemListMap.containsKey(apuracao.CriterioApuracao__c)){
                for (ProgramacaoEntrega__c item : criterioApuracaoToItemListMap.get(apuracao.CriterioApuracao__c)) {
                    updateDeliveryMap.get(item.Id).Apuracao__c = apuracao.Id;
                }
            }
        }

        ProgramacaoEntregaHelper.disableTrigger();
        update updateDeliveryMap.values();

        //Atualizar Apurações antigas
        List<ProgramacaoEntrega__c> oldDelivery =  new List<ProgramacaoEntrega__c>();

        for (ProgramacaoEntrega__c delivery : newContextMap.values()) {
            oldDelivery.add(delivery);
        }

        updateApuracaoField(oldDelivery);

        ProgramacaoEntregaHelper.enableTrigger();

    }

    public static void updateTotalPrice(Map<Id, ProgramacaoEntrega__c> newContextMap, Map<Id, ProgramacaoEntrega__c> oldContextMap){
        Set<Id> correctContext = new Set<Id>();
        Set<Id> productIdset = new Set<Id>();
        for(ProgramacaoEntrega__c context : newContextMap.values()){
            ProgramacaoEntrega__c oldProgramacao = oldContextMap.get(context.Id);
            if(context.QuantidadeProgramada__c != oldProgramacao.QuantidadeProgramada__c){
                correctContext.add(context.id);
                productIdset.add(context.Produto__c);
            }
        }    
        Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();    
        for (Product2 prod : [SELECT Id, Embalagem__c, Litragem__c  FROM Product2 WHERE Id IN:productIdset]){
            mapIdToProduct.put(prod.Id, prod);
        }
        for(ProgramacaoEntrega__c delivery : newContextMap.values()){
            if(correctContext.contains(delivery.Id)){
                delivery.ValorTotal__c = delivery.QuantidadeProgramada__c * delivery.PrecoVendaJuros__c;
                delivery.ValorTotalUSD__c = (delivery.moeda__c == 'BRL' ? delivery.ValorTotal__c * delivery.TaxaDolar__c : delivery.ValorTotal__c / delivery.TaxaDolar__c);
                if(mapIdToProduct.containsKey(delivery.Produto__c))
                    delivery.Litros__c = (mapIdToProduct.get(delivery.Produto__c).Litragem__c * delivery.QuantidadeProgramada__c);
            }
        }

    }

    public static void statusCenterAgro(ProgramacaoEntrega__c[] deliveryList, Map<Id, ProgramacaoEntrega__c> oldContextMap, Boolean isInsert){
        Set<Id> accountIdSet = new Set<Id>();
        Set<String> cliNotToIntegrate = new Set<String>();
        Map<String, CentroDelAgro__c> mapDescToCli = new Map<String, CentroDelAgro__c>();
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
        mapDescToCli = CentroDelAgro__c.getAll();

        for (ProgramacaoEntrega__c delivery : deliveryList){
            if (delivery.EmissorOrdem__c != null){
                accountIdSet.add(delivery.EmissorOrdem__c);
            }          
        }

        for (String exIds : mapDescToCli.KeySet()){
             cliNotToIntegrate.add(mapDescToCli.get(exIds).ExternalId__c);
        }

        for (Account acc : [SELECT Id, Name, ListaPreco__c, GerenteRegional__c, SetorAtividade__c, Agenciamento__c, ExternalId__c FROM Account WHERE Id IN: accountIdSet]){
            mapIdToAccount.put(acc.Id, acc);
        }
        for (ProgramacaoEntrega__c delivery : deliveryList){
            Boolean Confirmed = (isInsert  && delivery.Confirmado__c) || 
                                (!isInsert && (delivery.Confirmado__c && !oldContextMap.get(delivery.Id).Confirmado__c));
            if(Confirmed){
                Account acc = mapIdToAccount.get(delivery.EmissorOrdem__c);
                if (cliNotToIntegrate.contains(acc.ExternalId__c)) {
                    delivery.Status__c = 'Integrado Manual';
                }
            }
        }

    }
    
    public static void checkTotalAmount(ProgramacaoEntrega__c[] newDeliveryList, Map<Id, ProgramacaoEntrega__c> oldDeliveryMap){
        Map<Id, Decimal> ordItemMap = new Map<Id, Decimal>();
        for(ProgramacaoEntrega__c delivery : newDeliveryList){
            ProgramacaoEntrega__c oldDelivery = oldDeliveryMap.get(delivery.Id);
            if(delivery.IdOrderItem__c != null && delivery.ValorTotal__c != oldDelivery.ValorTotal__c){
                ordItemMap.put(delivery.IdOrderItem__c, delivery.ValorTotal__c - oldDelivery.ValorTotal__c);
            }
        }
        Map<Id, Order> ordUpdatMap = new Map<Id, Order>();
        for(OrderItem ordItem : [SELECT id, OrderId, Order.ValorProgramacao__c FROM OrderItem WHERE ID IN :ordItemMap.keySet()]){
            if(!ordUpdatMap.containsKey(ordItem.OrderId))
                ordUpdatMap.put(ordItem.OrderId, new Order(Id = ordItem.OrderId, ValorProgramacao__c = ordItem.Order.ValorProgramacao__c));
            
                if(ordItemMap.containsKey(ordItem.Id)){
                    if(ordUpdatMap.get(ordItem.OrderId).ValorProgramacao__c != null)
                        ordUpdatMap.get(ordItem.OrderId).ValorProgramacao__c += ordItemMap.get(ordItem.Id);
                    else
                        ordUpdatMap.get(ordItem.OrderId).ValorProgramacao__c = ordItemMap.get(ordItem.Id);
                }
            }
        if(!ordUpdatMap.isEmpty()){
            OrderHelper.disableTrigger();
            update ordUpdatMap.values();
            OrderHelper.enableTrigger();
        }

    }
    public static void insertOrder(ProgramacaoEntrega__c[] newDeliveryList){
        insertOrder(newDeliveryList, new Map<Id, ProgramacaoEntrega__c>(), true);
    }
    public static void insertOrder(ProgramacaoEntrega__c[] newDeliveryList, Map<Id, ProgramacaoEntrega__c> oldContextMap, Boolean isInsert){

    List<ProgramacaoEntrega__c> deliveryList    = newDeliveryList;
    List<Order> orderList                       = new List<Order>();
    List<Order> orderListToUpsert               = new List<Order>();
    List<OrderItem> orderItemList               = new List<OrderItem>();
    List<Order> orderItemListRVT            = new List<Order>();

    List<Id> orderIdList   = new List<Id>();
    Set<Id> accountIdSet = new Set<Id>();//RECEBE EMISSORORDER__C DE CADA ITEM DA TRIGGER.NEW (LIST DELIVERYLIST)
    Set<Id> productIdSet = new Set<Id>();//RECEBE PROCUCT__C DE CADA ITEM DA LIST DELIVERYLIST
    Set<Id> businessPlaceIdSet = new Set<Id>();
    Set<String> cliNotToIntegrate = new Set<String>();

    Map<String, List<ProgramacaoEntrega__c>> mapExIdToDeliveryList = new Map<String, List<ProgramacaoEntrega__c>>();
    Map<String, Order> mapExIdToOrderList = new Map<String, Order>();
    Map<String, Order> mapExIdToOrder = new Map<String, Order>();
    Map<Id, Opportunity> mapIdToOpportunity = new Map<Id, Opportunity>();//RECEBE UMA LISTA DE ITEMS PARA CADA KEY EM NEWCONTEXTMAP
    Map<Id, List<OpportunityLineItem>> mapIdToOpportunityLineItem = new Map<Id, List<OpportunityLineItem>>();
    Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();
    Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
    Map<Id, LocalNegocio__c> businessPlaceMap = new Map<Id, LocalNegocio__c>();
    Map<Id, Id> mapExIdToPriceBookEntry = new Map<Id, Id>();

    Map<String, Order> rtvMapforInsert = new Map<String, Order>();
    
    Map<Id, List<ProgramacaoEntrega__c>> newContextMap = new Map<Id, List<ProgramacaoEntrega__c>>();
    
    Map<String, String> mapDeParaSetorAtividade = new Map<String, String>();

    mapDeParaSetorAtividade = IntegrationUtils.getMetadataDePara(new List<String>{'SetorAtividade'});

    String currentKey = '';

    Map<String, CentroDelAgro__c> mapDescToCli = new Map<String, CentroDelAgro__c>();
    mapDescToCli = CentroDelAgro__c.getAll();
    
    for (String exIds : mapDescToCli.KeySet()){
         cliNotToIntegrate.add(mapDescToCli.get(exIds).ExternalId__c);
    }

    Decimal taxaMedia = 1;
    for(CotacaoMoeda__c cotacoesMoeda : [SELECT Id, TaxaMedia__c FROM CotacaoMoeda__c WHERE Data__c <= :Date.today() ORDER BY Data__c DESC LIMIT 1]){
        taxaMedia = cotacoesMoeda.TaxaMedia__c;
    }

    for (ProgramacaoEntrega__c delivery : deliveryList){
        if (delivery.EmissorOrdem__c != null){
            accountIdSet.add(delivery.EmissorOrdem__c);//ADICIONA EMISSORORDER__C DE CADA ITEM NA LIST DELIVERYLIST)
        }
        if (delivery.Produto__c != null){
            productIdSet.add(delivery.Produto__c);//ADICIONA PRODUCT__C DE CADA ITEM NA LIST DELIVERYLIST)
        }
        if (!newContextMap.containsKey(delivery.IdOportunidade__c))
            newContextMap.put(delivery.IdOportunidade__c, new List<ProgramacaoEntrega__c>());
        newContextMap.get(delivery.IdOportunidade__c).add(delivery);

        businessPlaceIdSet.add(delivery.LocalNegocio__c);
    }
    
    Map<String, List<ProgramacaoEntrega__c>> mapExIdToEmailList = new Map<String, List<ProgramacaoEntrega__c>>();

    for (Account acc : [SELECT Id, Name, ListaPreco__c, GerenteRegional__c, SetorAtividade__c, Agenciamento__c, ExternalId__c FROM Account WHERE Id IN: accountIdSet]){
        mapIdToAccount.put(acc.Id, acc);
    }

    for (LocalNegocio__c bussPlace : [SELECT Id, Descricao__c FROM LocalNegocio__c WHERE Id IN: businessPlaceIdSet]){
        businessPlaceMap.put(bussPlace.Id, bussPlace);
    }
    
    for (Opportunity opp : [SELECT Id, NomeRTV__C, Regional__r.NomeRegional__c, Regional__c, Agenciamento__c, MotivoOrdem__c, DataReferenciaPreco__c, LocalNegocio__r.Descricao__c, VencimentoVendor__c, ObservacaoInterna__c, CondicaoPagamento__c, Cultura__C, Cultura__r.ExternalId__c, AccountID, Regional__r.Name, OrganizacaoVenda__c, NumeroOportunidade__c, DataVencimento__C, Campanha__r.Descricao__c, dataInicioJuros__c, CreatedDate, CondicaoPagamento__r.Descricao__C, Moeda__c, ObservacaoLogistica__c, ObservacaoImpressaNF__c,ListaPreco__c FROM Opportunity WHERE Id IN:newContextMap.keySet()]){
        mapIdToOpportunity.put(opp.Id, opp);//ITERA CADA ITEM DA QUERY RELACIONADA A CADA KEY DE NEWCONTEXTMAP E ADD PARA CADA ITEM ID UM OPP  NO MAPIDTOOPPORTUNITY
    }
    
    Map<String, OpportunityLineItem> oppHeaderToLineMap = new Map<String, OpportunityLineItem>();

    for (OpportunityLineItem oppLineItem : [SELECT Id, idTabelaPreco__r.ListaPreco__c, Cultura__r.Descricao__c, PrecoVendaSemJurosBRLUSD__c, OpportunityId, Product2.SKU__C, Product2.Description, PrazoInterno__c, PrazoTotal__c, Itinerario__c, PrecoLista__c FROM OpportunityLineItem WHERE OpportunityId IN: newContextMap.keySet()]){

        if(!mapIdToOpportunityLineItem.containsKey(oppLineITem.OpportunityId))
            mapIdToOpportunityLineItem.put(oppLineItem.OpportunityId, new List<OpportunityLineItem>());
        mapIdToOpportunityLineItem.get(oppLineItem.OpportunityId).add(oppLineItem);
        oppHeaderToLineMap.put(oppLineItem.OpportunityId+'_'+oppLineItem.id, oppLineItem);
    }
    Map<String, String> deParaOrderMap = IntegrationUtils.getMetadataDePara(new List<String>{'TipoOrdemSAPAcertos',
            'TipoOrdemSAPEstrategia',
            'TipoOrdemSAPPagamento',
            'TipoOrdemSAPReclamacao'});

    Datetime todayDt = Datetime.now();
    
    for(Id oppId : newContextMap.KeySet()){
        for (ProgramacaoEntrega__c delivery : newContextMap.get(oppId)){
            Boolean Confirmed = (!invalidOrderStatus.contains(delivery.Status__c)) && 
                                ((isInsert  && delivery.Confirmado__c) || (!isInsert && (delivery.Confirmado__c && !oldContextMap.get(delivery.Id).Confirmado__c)) );
            Account acc = mapIdToAccount.get(delivery.EmissorOrdem__c);     
            if(Confirmed){
                if (!cliNotToIntegrate.contains(acc.ExternalId__c)) {
                    String extKey = getCurrentKey(delivery, todayDt);
                    if (!mapExIdToOrderList.ContainsKey(extKey)){
                        Opportunity opp             = mapIdToOpportunity.get(delivery.IdOportunidade__c);
                        OpportunityLineItem oppItem = mapIdToOpportunityLineItem.get(delivery.IdOportunidade__c)[0];
                        Order ord                   = new Order();
                        ord.ExternalId__c           = extKey;
                        ord.Moeda__c                = delivery.Moeda__c;
                        ord.OpportunityId           = delivery.IdOportunidade__c;
                        ord.EffectiveDate           = delivery.DataEntrega__c;
                        ord.DataEntrega__c          = delivery.DataEntrega__c;
                        ord.DataFaturamento__c      = delivery.DataFaturamento__c;
                        ord.RecebedorMercadoria__c  = delivery.RecebedorOrdem__c;
                        ord.Territorio__c           = delivery.Territorio__c;
                        ord.TipoOrdem__c            = delivery.TipoOrdem__c;
                        ord.ClienteEmissor__c       = delivery.EmissorOrdem__c;
                        ord.DataIntegracao__c       = delivery.DataIntegracao__c;
                        ord.UsuarioConfirmacao__c   = delivery.NomeUsuarioConfirmacao__c;
                        ord.DataConfirmacao__c      = delivery.DataConfirmacao__c;
                        ord.RTV__c                  = delivery.RTV__c;
                        ord.LocalNegocioItem__c     = businessPlaceMap.get(delivery.LocalNegocio__c).Descricao__c;
                        ord.AccountId               = acc.Id;
                        ord.ListaPreco__c           = oppItem.IdTabelaPreco__r.ListaPreco__c;
                        ord.GerenteRegional__c      = delivery.GerenteRegional__c;
                        ord.Agenciamento__c         = opp.Agenciamento__c;
                        ord.Moeda__c                = opp.Moeda__c;
                        ord.Regional__c             = delivery.Regional__c;
                        ord.ObservacaoLogistica__c  = opp.ObservacaoLogistica__c;
                        ord.ObservacaoNF__c         = opp.ObservacaoImpressaNF__c;
                        ord.OrganizacaoVendas__c    = opp.OrganizacaoVenda__c;
                        ord.CondicaoPagamento__c    = opp.CondicaoPagamento__c;
                        ord.DataFixacaoPreco__c     = opp.DataReferenciaPreco__c;
                        ord.PrazoInterno__c         = oppItem.PrazoInterno__c;
                        ord.PrazoItinerario__c      = delivery.PrazoItinerario__c;
                        ord.Itinerario__c           = delivery.Itinerario__c;
                        ord.PrazoTotal__c           = delivery.PrazoItinerario__c + oppItem.PrazoInterno__c ;
                        ord.MotivoOrdem__c          = (opp.MotivoOrdem__c != null && deParaOrderMap.containsKey(opp.MotivoOrdem__c) ? deParaOrderMap.get(opp.MotivoOrdem__c) : null); 
                        ord.Status__c               = 'Confirmado';
                        ord.PriceBook2Id            = DEFAULT_PRICEBOOK_ID;
                        ord.DataINicioJuros__c      = (String.isBlank(String.valueOf(opp.VencimentoVendor__c)) ? opp.DataINicioJuros__c : opp.VencimentoVendor__c);
                        ord.Status                  = 'Draft';
                        ord.SetorAtividade__c       = mapDeParaSetorAtividade.ContainsKey(acc.SetorAtividade__c) ? mapDeParaSetorAtividade.get(acc.SetorAtividade__c) : '10- Produtos';
                        ord.TaxaMedia__c            = taxamedia;

                        ord.ValorProgramacao__c = delivery.ValorTotal__c;
                        system.debug('antes do if');
                        if(DeliveryAppController.isRTV() == True && rtvMapforInsert.size() <= 5){
                            rtvMapforInsert.put(extKey, ord);
                        }
                        mapExIdToDeliveryList.put(extKey, new List<ProgramacaoEntrega__c>{delivery});
                        mapExIdToOrderList.put(extKey, ord);
                        
                    }else{
                        Order oldOrd = mapExIdToOrderList.get(extKey);
                        oldOrd.ValorProgramacao__c += delivery.ValorTotal__c;
                        system.debug('antes do if');
                        if(DeliveryAppController.isRTV() == True && rtvMapforInsert.size() <= 5){
                        	rtvMapforInsert.put(extKey, oldOrd);
                        }
                        mapExIdToOrderList.put(extKey, oldOrd);
                        mapExIdToDeliveryList.get(extKey).add(delivery);
                    }
                
                }else{
                    String extId = getCurrentKey(delivery, todayDt);
                    if (!mapExIdToEmailList.containsKey(extId+'_'+oppId)){
                        mapExIdToEmailList.put(extId+'_'+oppId, new List<ProgramacaoEntrega__c>{delivery});
                    }else{
                        mapExIdToEmailList.get(extId+'_'+oppId).add(delivery);
                    }
                
                }
            }
        }
    } 

    orderListToUpsert = mapExIdToOrderList.Values();
    orderItemListRVT = rtvMapforInsert.Values();

    system.debug(orderListToUpsert);

    if (!orderListToUpsert.isEmpty()){
        upsert orderListToUpsert ExternalId__c;
    }
   
    for (Order ord: orderListToUpsert){
        mapExIdToOrder.put(ord.ExternalId__c, ord);
        if (ord.Status__c == 'Confirmado'){
            orderIdList.add(ord.Id);
        }
    }
    system.debug('antes do if');
     if(orderItemListRVT.size() <= 5){
        upsert orderItemListRVT ExternalId__c;
    }

        
        for (PriceBookEntry pb : [SELECT Id, Product2Id, Pricebook2Id FROM PriceBookEntry WHERE PriceBook2Id =:DEFAULT_PRICEBOOK_ID]){
            mapExIdToPriceBookEntry.put(pb.Product2Id, pb.Id);
        }

        for (Product2 prod : [SELECT Id, Embalagem__c, LItragem__c FROM Product2 WHERE Id IN:productIdSet]){
            mapIdToProduct.put(prod.Id, prod);
        }

        for (String externalId : mapExIdToDeliveryList.KeySet()){
            for (ProgramacaoEntrega__c delivery : mapExIdToDeliveryList.get(externalId)){
                Boolean Confirmed = (!invalidOrderStatus.contains(delivery.Status__c)) && ((isInsert  && delivery.Confirmado__c) || 
                                    (!isInsert && (delivery.Confirmado__c && !oldContextMap.get(delivery.Id).Confirmado__c)));
                if (Confirmed){
                    Opportunity opp = mapIdToOpportunity.get(delivery.IdOportunidade__c);
                    OrderItem ordItem  = new OrderItem();
                    ordItem.OrderId                  = mapExIdToOrder.get(externalId).Id;
                    orditem.DescontoConcedido__c     = delivery.DescontoConcedido__c;
                    ordItem.NumeroPedidoCliente__c   = delivery.NumeroPedidoCliente__c;
                    ordItem.Cultura__c               = delivery.Cultura__c; 
                    ordItem.DataEntrega__c           = delivery.DataEntrega__c;
                    ordItem.LocalNegocio__c          = delivery.LocalNegocio__c;
                    ordItem.PrecoLista__c            = (oppHeaderToLineMap.containsKey(delivery.IdOportunidade__c+'_'+delivery.IdOpportunityLineItem__c) ? oppHeaderToLineMap.get(delivery.IdOportunidade__c+'_'+delivery.IdOpportunityLineItem__c).PrecoLista__c : delivery.PrecoLista__c);
                    ordItem.PrecoListaReferencia__c  = delivery.PrecoListaReferencia__c;
                    ordItem.PrecoVendaSemJuros__c    = delivery.PrecoVenda__c;
                    ordItem.ValorJuros__c            = delivery.Juros__c;
                    ordItem.Product2Id               = delivery.Produto__c;
                    ordItem.ProgramacaoEntrega__c    = delivery.Id;
                    ordItem.QuantidadeTotal__c       = delivery.QuantidadeProgramada__c;
                    ordItem.Quantity                 = delivery.QuantidadeProgramada__c;
                    ordItem.UnitPrice                = delivery.PrecoVendasComJurosUSDBRL__c;
                    ordItem.ValorTotal__c            = delivery.ValorTotal__c;
                    ordItem.ValorTotalUSD__c         = delivery.ValorTotalUSD__c;
                    if(delivery.Moeda__c == 'BRL'){
                        ordItem.ValorTotal__c       = delivery.PrecoVendasComJurosUSDBRL__c * delivery.QuantidadeProgramada__c;
                        ordItem.ValorTotalUSD__c    = ordItem.ValorTotal__c / taxamedia;
                        ordItem.ValorTotalReaisDolar__c  = ordItem.ValorTotal__c;
                        ordItem.ValorTotalComJuros__c    = ordItem.ValorTotal__c;
                    }else{
                        ordItem.ValorTotalUSD__c    = delivery.PrecoVendasComJurosUSDBRL__c * delivery.QuantidadeProgramada__c;
                        ordItem.ValorTotal__c       = ordItem.ValorTotalUSD__c * taxamedia;                        
                        ordItem.ValorTotalReaisDolar__c  = ordItem.ValorTotalUSD__c;
                        ordItem.ValorTotalComJuros__c    = ordItem.ValorTotalUSD__c;
                    }                    
                    ordItem.ValorUnitarioComJuros__c = delivery.PrecoVendasComJurosUSDBRL__c;
                    ordItem.Litros__c                = mapIdToProduct.get(delivery.Produto__c).Litragem__c;
                    ordItem.Embalagem__c             = mapIdToProduct.get(delivery.Produto__c).Embalagem__c;
                    ordItem.PricebookEntryId         = mapExIdToPriceBookEntry.get(delivery.Produto__c);
                    ordItem.Itinerario__c            = delivery.Itinerario__c;

                    orderItemList.add(ordItem);
                }
            }
        }
        Map<Id, Id> progToOrdItemMap = new Map<Id, Id>();
        if (!orderItemList.isEmpty()){            
            insert orderItemList;                        
            for(OrderITem ordItem : orderItemList){
                progToOrdItemMap.put(ordItem.ProgramacaoEntrega__c, ordItem.Id);
            }
        }      
        
        if(isInsert){
            List<ProgramacaoEntrega__c> updtRelatedDeliveryList = new List<ProgramacaoEntrega__c>();
            for(ProgramacaoEntrega__c prog : [SELECT id FROM ProgramacaoEntrega__c WHERE id IN : Collection.of(newDeliveryList).pluckIds()]){
                if(progToOrdItemMap.containsKey(prog.Id)){
                    updtRelatedDeliveryList.add(new ProgramacaoEntrega__c(Id = prog.Id, IdOrderItem__c = progToOrdItemMap.get(prog.Id)));
                }
            }  

            if(!updtRelatedDeliveryList.isEmpty()){
                ProgramacaoEntregaHelper.disableTrigger();
                update updtRelatedDeliveryList;
                ProgramacaoEntregaHelper.enableTrigger();
            }

        }else{
            for(ProgramacaoEntrega__c prog : newDeliveryList){
                if(progToOrdItemMap.containsKey(prog.Id)){
                    prog.IdOrderItem__c = progToOrdItemMap.get(prog.Id);
                }
            }
        }

        if (!orderIdList.isEmpty() && !Test.isRunningTest()){
            IntegrationOutboundOrder.sendOrderTrigger(orderIdList);
        }    
        
        if(!mapExIdToEmailList.isEmpty()){           
            sendEmailCentroDelAgro(JSON.serialize(mapExIdToEmailList), accountIdSet, newContextMap.keySet()); 
        }
        
    }

    @future(callout = true)
    public static void sendEmailCentroDelAgro(String extIdsData, Set<Id> accIdSet, Set<Id> oppIdSet){

        Map<String, List<ProgramacaoEntrega__c>> mapExIdToEmailList = (Map<String, List<ProgramacaoEntrega__c>>)JSON.deserialize(extIdsData,Map<String, List<ProgramacaoEntrega__c>>.class );

        String CUSTOMER_EMAIL = [SELECT id, Queue.Email, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName = 'CustomerService' LIMIT 1].Queue.Email;
        Map<String, EmailTemplate> searchEmailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate email :[SELECT id, name, subject, htmlvalue, markup, Body, developerName
				                  FROM   EmailTemplate
				                  WHERE  developerName IN ('CentroDelAgroPedido', 'StollerParaguayPedido')]){
            searchEmailTemplateMap.put(email.DeveloperName, email);
        }  
        
        Map<Id, Opportunity> mapIdToOpportunity = new Map<Id, Opportunity>();
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
        
        for (Account acc : [SELECT Id, Name, ListaPreco__c, GerenteRegional__c, SetorAtividade__c, Agenciamento__c, ExternalId__c FROM Account WHERE Id IN: accIdSet]){
            mapIdToAccount.put(acc.Id, acc);
        }

        for (Opportunity opp : [SELECT Id, NomeRTV__C, Regional__r.NomeRegional__c, Agenciamento__c, MotivoOrdem__c, DataReferenciaPreco__c, LocalNegocio__r.Descricao__c, VencimentoVendor__c, ObservacaoInterna__c, CondicaoPagamento__c, Cultura__C, Cultura__r.ExternalId__c, AccountID, Regional__r.Name, OrganizacaoVenda__c, NumeroOportunidade__c, DataVencimento__C, Campanha__r.Descricao__c, dataInicioJuros__c, CreatedDate, CondicaoPagamento__r.Descricao__C, Moeda__c, ObservacaoLogistica__c, ObservacaoImpressaNF__c FROM Opportunity WHERE Id IN:oppIdSet]){
            mapIdToOpportunity.put(opp.Id, opp);
        }
        
        Map<String, CentroDelAgro__c> mapDescToCli = new Map<String, CentroDelAgro__c>();
        Map<String, String> cliToDevEmailMap = new Map<String, String>();
        mapDescToCli = CentroDelAgro__c.getAll();

        for (String exIds : mapDescToCli.KeySet()){
             cliToDevEmailMap.put(mapDescToCli.get(exIds).ExternalId__c, mapDescToCli.get(exIds).EmailTemplate__c);
        }
        List<Messaging.EmailFileAttachment> attch = new List<Messaging.EmailFileAttachment>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 
        for(String extId : mapExIdToEmailList.keySet()){

            List<ProgramacaoEntrega__c> prograEntregaList = mapExIdToEmailList.get(extId);
            Opportunity opp = mapIdToOpportunity.get(prograEntregaList[0].IdOportunidade__c);
            Account acc = mapIdToAccount.get(prograEntregaList[0].EmissorOrdem__c);

            Blob excelData; 
            PageReference generateExl = Page.ExcelGeneratorPage;
            generateExl.getParameters().put('Id', prograEntregaList[0].IdOportunidade__c);
            generateExl.getParameters().put('Pe', String.join(Collection.of(prograEntregaList).pluckIds(), ';'));
            excelData = generateExl.getContent();

            Messaging.EmailFileAttachment emailAttch = new Messaging.EmailFileAttachment();
            // emailAttch.setContentType('application/vnd.ms-excel');
            emailAttch.setFileName('Dados Oportunidade.xls');
            emailAttch.setBody(excelData);
            attch.add(emailAttch);
            
            EmailTemplate searchEmailTemplate = searchEmailTemplateMap.get(cliToDevEmailMap.containskey(acc.ExternalId__c) ? cliToDevEmailMap.get(acc.ExternalId__c) :  'CentroDelAgroPedido');
            mails.add(EmailClientToApprove.composeEmail(new List<String>{CUSTOMER_EMAIL}, 
                            'Pedido Centro del Agro', 
                            searchEmailTemplate.Subject.replace('{ClientName}', acc.Name),
                            searchEmailTemplate.Body.replace('{ClientName}', acc.Name).replace('{OppLInk}', '<a href="' +Label.EmailOrgUrl+'/'+opp.Id+'">'+opp.NumeroOportunidade__c+'</a>'),
                            attch,
                            new List<String>()));
        }

        if(!Test.isRunningTest() && !mails.isEmpty()) Messaging.sendEmail(mails);
    }

    public static void updateClienteFamiliaCarteira(Map<Id, ProgramacaoEntrega__c> newContextMap, Map<Id, ProgramacaoEntrega__c> oldContextMap) {

        // Map<Id, List<ProgramacaoEntrega__c>> clienteIdToPEList = new Map<Id, List<ProgramacaoEntrega__c>>();

        // for (ProgramacaoEntrega__c deliveryNew : newContextMap.values()) {

        //     if (!clienteIdToPEList.containsKey(deliveryNew.EmissorOrdem__c)) {
        //         clienteIdToPEList.put(deliveryNew.EmissorOrdem__c, new List<ProgramacaoEntrega__c>());
        //     }
        //     clienteIdToPEList.get(deliveryNew.EmissorOrdem__c).add(deliveryNew);
        // }

        // Map<Id, List<Account>> planoIncentivosIdToAccountList = (Map<Id, List<Account>>)Collection.of([SELECT Id, PlanoIncentivos__c FROM Account WHERE Id IN :clienteIdToPEList.keySet()]).groupByIds(Account.PlanoIncentivos__c, List<Account>.class);

        // Map<Id, List<FamiliaClientes__c>> planoIncentivosIdToFamiliaClientesList = (Map<Id, List<FamiliaClientes__c>>)Collection.of([SELECT Id, PlanoIncentivo__c FROM FamiliaClientes__c WHERE PlanoIncentivo__c IN :planoIncentivosIdToAccountList.keySet()]).groupByIds(FamiliaClientes__c.PlanoIncentivo__c, List<FamiliaClientes__c>.class);

        // Map<Id, List<ClienteFamilia__c>> familiaClientesIdToClienteFamiliaList = (Map<Id, List<ClienteFamilia__c>>)Collection.of([SELECT Id, FamiliaClientes__c FROM ClienteFamilia__c WHERE FamiliaClientes__c IN :planoIncentivosIdToFamiliaClientesList.keySet()]).groupByIds(ClienteFamilia__c.FamiliaClientes__c, List<ClienteFamilia__c>.class);

        // ClienteFamiliaHelper.calcAfterInsert(Trigger.new);
    }

    public static void updateApWallet(Map<Id, ProgramacaoEntrega__c> newContextMap, Map<Id, ProgramacaoEntrega__c> oldContextMap){

        Set<String> critApuracao = new Set<String>();

        List<Apuracao__c> updateSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> removeSumApuracao = new List<Apuracao__c>();
        List<Apuracao__c> addingToAnotherAp = new List<Apuracao__c>();
        List<ClientesPlanoIncentivos__c> cliPlanoIncentivoList = new List<ClientesPlanoIncentivos__c>();

        Map<Id, ProgramacaoEntrega__c> newDeliveryToCheck = new Map<Id, ProgramacaoEntrega__c>();
        Map<Id, List<ProgramacaoEntrega__c>> mapCliIdToDeliveryMin = new Map<Id, List<ProgramacaoEntrega__c>>();

        Map<String, List<ProgramacaoEntrega__c>> mapCritRemoveToDelivery  = new Map<String, List<ProgramacaoEntrega__c>>();
        Map<String, List<ProgramacaoEntrega__c>> mapCritAddingToAnotherAp = new Map<String, List<ProgramacaoEntrega__c>>();

        Map<String, List<ProgramacaoEntrega__c>> mapCritUpdateToDelivery  = new Map<String, List<ProgramacaoEntrega__c>>();
        Map<String, List<ProgramacaoEntrega__c>> mapSubtractToDelivery    = new Map<String, List<ProgramacaoEntrega__c>>();

        for (ProgramacaoEntrega__c deliveryNew : newContextMap.values()/*[SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c, ClientePlanoIncentivo__c, Status__c FROM ProgramacaoEntrega__c 
                                              WHERE Id IN: oldContextMap.keySet() //AND Status__c != 'Cancelado' 
                                            //   AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' 
                                            //   AND TipoOrdem__c != 'Bonificação',
                                            // AND StatusGlobalItem__c != 'Faturado completamente'
                                              ]*/) {

            ProgramacaoEntrega__c deliveryOld = oldContextMap.get(deliveryNew.Id);

            String newValue = deliveryNew.CriterioApuracao__c;
            String oldValue = deliveryOld.CriterioApuracao__c;
            
            if ((deliveryNew.Status__c == 'Cancelado' && deliveryOld.Status__c != 'Cancelado' && deliveryOld.StatusSAP__c != 'Faturado' && deliveryOld.StatusGlobalItem__c != 'C' && deliveryOld.StatusSAP__c != 'Faturado Parcial') || 
                (deliveryNew.StatusGlobalItem__c == 'C' && deliveryOld.StatusGlobalItem__c != 'C' && deliveryOld.Status__c != 'Cancelado' && deliveryOld.StatusSAP__c != 'Faturado' && deliveryOld.StatusSAP__c != 'Faturado Parcial') ||
                (deliveryNew.StatusSAP__c == 'Faturado' && deliveryOld.StatusSAP__c != 'Faturado' && deliveryOld.Status__c != 'Cancelado' && deliveryOld.StatusGlobalItem__c != 'C' && deliveryOld.StatusSAP__c != 'Faturado Parcial') || 
                (deliveryNew.StatusSAP__c == 'Faturado Parcial' && deliveryOld.StatusSAP__c != 'Faturado Parcial' && deliveryOld.Status__c != 'Cancelado' && deliveryOld.StatusGlobalItem__c != 'C' && deliveryOld.StatusSAP__c != 'Faturado') ||
                 deliveryNew.ValorTotal__c != deliveryOld.ValorTotal__c || 
                 deliveryNew.ValorTotalUSD__c != deliveryOld.ValorTotalUSD__c) {
                
                if (!mapCliIdToDeliveryMin.containsKey(deliveryNew.ClientePlanoIncentivo__c)) {
                    mapCliIdToDeliveryMin.put(deliveryNew.ClientePlanoIncentivo__c, new List<ProgramacaoEntrega__c>());
                }
                mapCliIdToDeliveryMin.get(deliveryNew.ClientePlanoIncentivo__c).add(deliveryNew);

                critApuracao.add(deliveryNew.CriterioApuracao__c);
                critApuracao.add(deliveryOld.CriterioApuracao__c);
                
                if (!mapCritRemoveToDelivery.containsKey(deliveryOld.CriterioApuracao__c)) {
                    mapCritRemoveToDelivery.put(deliveryOld.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                }
                mapCritRemoveToDelivery.get(deliveryOld.CriterioApuracao__c).add(deliveryOld);
            
            } else if (deliveryNew.ValorTotal__c != deliveryOld.ValorTotal__c || deliveryNew.ValorTotalUSD__c != deliveryOld.ValorTotalUSD__c || deliveryNew.Litros__c != deliveryOld.Litros__c || deliveryNew.CriterioApuracao__c != deliveryOld.CriterioApuracao__c){

                // newDeliveryToCheck.put(deliveryNew.Id, deliveryNew);

                if (!mapCliIdToDeliveryMin.containsKey(deliveryNew.ClientePlanoIncentivo__c)) {
                    mapCliIdToDeliveryMin.put(deliveryNew.ClientePlanoIncentivo__c, new List<ProgramacaoEntrega__c>());
                }
                mapCliIdToDeliveryMin.get(deliveryNew.ClientePlanoIncentivo__c).add(deliveryOld);

                critApuracao.add(deliveryNew.CriterioApuracao__c);
                critApuracao.add(deliveryOld.CriterioApuracao__c);

                if (deliveryNew.CriterioApuracao__c != deliveryOld.CriterioApuracao__c) {
                    if (!mapCritAddingToAnotherAp.containsKey(deliveryNew.CriterioApuracao__c)) {
                        mapCritAddingToAnotherAp.put(deliveryNew.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                    }
                    mapCritAddingToAnotherAp.get(deliveryNew.CriterioApuracao__c).add(deliveryNew);

                    if (!mapCritRemoveToDelivery.containsKey(deliveryOld.CriterioApuracao__c)) {
                        mapCritRemoveToDelivery.put(deliveryOld.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                    }
                    mapCritRemoveToDelivery.get(deliveryOld.CriterioApuracao__c).add(deliveryOld);

                } else {

                    if (!mapCritUpdateToDelivery.containsKey(deliveryNew.CriterioApuracao__c)) {
                        mapCritUpdateToDelivery.put(deliveryNew.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                    }
                    mapCritUpdateToDelivery.get(deliveryNew.CriterioApuracao__c).add(deliveryNew);
                    
                    if (!mapSubtractToDelivery.containsKey(deliveryNew.CriterioApuracao__c)) {
                        mapSubtractToDelivery.put(deliveryNew.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
                    }
                    mapSubtractToDelivery.get(deliveryNew.CriterioApuracao__c).add(deliveryOld);
                }
            }
        }

        List<ProgramacaoEntrega__c> programacaoEntregaToUpdate = new List<ProgramacaoEntrega__c>();

        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, Carteira__c, Moeda__c FROM ClientesPlanoIncentivos__c WHERE Id IN: mapCliIdToDeliveryMin.keySet()]){
            for (ProgramacaoEntrega__c oldDelivery : mapCliIdToDeliveryMin.get(cliPlan.Id)) {
                // ProgramacaoEntrega__c newDelivery = newDeliveryToCheck.get(oldDelivery.Id);
                ProgramacaoEntrega__c newDelivery = newContextMap.get(oldDelivery.Id);

                if ((newDelivery.Status__c == 'Cancelado' && oldDelivery.Status__c != 'Cancelado' && oldDelivery.StatusSAP__c != 'Faturado' && oldDelivery.StatusGlobalItem__c != 'C' && oldDelivery.StatusSAP__c != 'Faturado Parcial') || 
                    (newDelivery.StatusGlobalItem__c == 'C' && oldDelivery.StatusGlobalItem__c != 'C' && oldDelivery.Status__c != 'Cancelado' && oldDelivery.StatusSAP__c != 'Faturado' && oldDelivery.StatusSAP__c != 'Faturado Parcial') ||
                    (newDelivery.StatusSAP__c == 'Faturado' && oldDelivery.StatusSAP__c != 'Faturado' && oldDelivery.Status__c != 'Cancelado' && oldDelivery.StatusGlobalItem__c != 'C' && oldDelivery.StatusSAP__c != 'Faturado Parcial') || 
                    (newDelivery.StatusSAP__c == 'Faturado Parcial' && oldDelivery.StatusSAP__c != 'Faturado Parcial' && oldDelivery.Status__c != 'Cancelado' && oldDelivery.StatusGlobalItem__c != 'C' && oldDelivery.StatusSAP__c != 'Faturado')) {

                    programacaoEntregaToUpdate.add(
                        new ProgramacaoEntrega__c(
                            Id          = newDelivery.Id,
                            Apuracao__c = null
                        )
                    );

                    if (cliPlan.Moeda__c == 'BRL') {
                        cliPlan.Carteira__c -= oldDelivery.ValorTotal__c;
                    } else {
                        cliPlan.Carteira__c -= oldDelivery.ValorTotalUSD__c;
                    }
                } else if (newDelivery.ValorTotal__c != oldDelivery.ValorTotal__c || newDelivery.ValorTotalUSD__c != oldDelivery.ValorTotalUSD__c){
                    if (cliPlan.Moeda__c == 'BRL') {
                        cliPlan.Carteira__c = cliPlan.Carteira__c - oldDelivery.ValorTotal__c    + newDelivery.ValorTotal__c;
                    } else {
                        cliPlan.Carteira__c = cliPlan.Carteira__c - oldDelivery.ValorTotalUSD__c + newDelivery.ValorTotalUSD__c;
                    }
                    cliPlanoIncentivoList.add(cliPlan);
                }
            }
        }

        for (Apuracao__c apuracao : [SELECT Id, CarteiraReais__c, CarteiraDolar__c, CarteiraLitros__c, CriterioApuracao__c FROM Apuracao__c WHERE CriterioApuracao__c IN: critApuracao]){

            if (mapCritAddingToAnotherAp.containsKey(apuracao.CriterioApuracao__c)) {
                for (ProgramacaoEntrega__c delivery : mapCritAddingToAnotherAp.get(apuracao.CriterioApuracao__c)) {
                    //2020.05.08 - William Leite - Adicionado campo para valor à vista (Reais/Dólar)
                    /*
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  + delivery.ValorTotal__c    : delivery.ValorTotal__c;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  + delivery.ValorTotalUSD__c : delivery.ValorTotalUSD__c;
					*/
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  + delivery.ValorTotalSemJurosReais__c : delivery.ValorTotalSemJurosReais__c;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  + delivery.ValorTotalSemJurosDolar__c : delivery.ValorTotalSemJurosDolar__c;                    
                    apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null ? apuracao.CarteiraLitros__c + delivery.Litros__c        : delivery.Litros__c;
                }

                addingToAnotherAp.add(apuracao);
            }
            if (mapCritRemoveToDelivery.containsKey(apuracao.CriterioApuracao__c)) {
                for (ProgramacaoEntrega__c delivery : mapCritRemoveToDelivery.get(apuracao.CriterioApuracao__c)) {
                    //2020.05.08 - William Leite - Adicionado campo para valor à vista (Reais/Dólar)
                    /*                    
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - delivery.ValorTotal__c    : null;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - delivery.ValorTotalUSD__c : null;
					*/
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - delivery.ValorTotalSemJurosReais__c : null;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - delivery.ValorTotalSemJurosDolar__c : null;                    
                    apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null ? apuracao.CarteiraLitros__c - delivery.Litros__c        : null;
                }

                removeSumApuracao.add(apuracao);
            }
            if (mapCritUpdateToDelivery.containsKey(apuracao.CriterioApuracao__c)) {

                ProgramacaoEntrega__c[] newList = mapCritUpdateToDelivery.get(apuracao.CriterioApuracao__c);
                ProgramacaoEntrega__c[] oldList = mapSubtractToDelivery.get(apuracao.CriterioApuracao__c);

                for (Integer i = 0; i < newList.size(); i++ ) {
                    ProgramacaoEntrega__c deliveryNew = newList[i];
                    ProgramacaoEntrega__c deliveryOld = oldList[i];
                    //2020.05.08 - William Leite - Adicionado campo para valor à vista (Reais/Dólar)
                    /*
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - deliveryOld.ValorTotal__c    + deliveryNew.ValorTotal__c    : deliveryNew.ValorTotal__c;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - deliveryOld.ValorTotalUSD__c + deliveryNew.ValorTotalUSD__c : deliveryNew.ValorTotalUSD__c;
					*/
                    apuracao.CarteiraReais__c  = apuracao.CarteiraReais__c  != null ? apuracao.CarteiraReais__c  - deliveryOld.ValorTotalSemJurosReais__c + deliveryNew.ValorTotalSemJurosReais__c : deliveryNew.ValorTotalSemJurosReais__c;
                    apuracao.CarteiraDolar__c  = apuracao.CarteiraDolar__c  != null ? apuracao.CarteiraDolar__c  - deliveryOld.ValorTotalSemJurosDolar__c + deliveryNew.ValorTotalSemJurosDolar__c : deliveryNew.ValorTotalSemJurosDolar__c;
                    if(deliveryOld.Litros__c != null)
                        apuracao.CarteiraLitros__c = apuracao.CarteiraLitros__c != null ? apuracao.CarteiraLitros__c - deliveryOld.Litros__c        + deliveryNew.Litros__c        : deliveryNew.Litros__c;
                }

                updateSumApuracao.add(apuracao);
            }
        }

        if (!programacaoEntregaToUpdate.isEmpty()) {
            ProgramacaoEntregaHelper.disableTrigger();
            update programacaoEntregaToUpdate;
            ProgramacaoEntregaHelper.enableTrigger();
        }

        if (!cliPlanoIncentivoList.isEmpty()){
            update cliPlanoIncentivoList;
        }

        if (!addingToAnotherAp.isEmpty()){
            update addingToAnotherAp;
        }

        if (!removeSumApuracao.isEmpty()){
            update removeSumApuracao;
        }

        if (!updateSumApuracao.isEmpty()){
            update updateSumApuracao;
        }               
    }

    public static void updatePlanoIncentivo(ProgramacaoEntrega__c[] deliveryList){
        Set<Id> clienteEmissorSet = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();
        List<PlanoIncentivo__c> planoIncentivoToUpdate = new List<PlanoIncentivo__c>();

        for (ProgramacaoEntrega__c delivery : deliveryList){
            if (delivery.EmissorOrdem__c != null){
                clienteEmissorSet.add(delivery.EmissorOrdem__c);
            }
        }

        for (ClientesPlanoIncentivos__c cliPlan : [SELECT Id, PlanoIncentivo__c FROM ClientesPlanoIncentivos__c WHERE NomeCliente__c IN: clienteEmissorSet]){
            // system.debug(cliPlan.PlanoIncentivo__c);
            planoIncentivoSet.add(cliPlan.PlanoIncentivo__c);
        }

        for (ClienteFamilia__c cliFam : [SELECT Id, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__c FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: clienteEmissorSet]){
            // system.debug(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
            planoIncentivoSet.add(cliFam.FamiliaClientes__r.PlanoIncentivo__c);
        }

        for (PlanoIncentivo__c planoIncentivo : [SELECT Id, Atualizado__c FROM PlanoIncentivo__c WHERE Id IN: planoIncentivoSet]){
            planoIncentivo.Atualizado__c = false;
            planoIncentivoToUpdate.add(planoIncentivo);
        }

        if (!planoIncentivoToUpdate.isEmpty()){
            PlanoIncentivoHelper.disableTrigger();
            update planoIncentivoToUpdate;
            PlanoIncentivoHelper.enableTrigger();
        }
    }

    // public static void updateApDeliveryField(Apuracao__c[] apuracaoList){
    //     List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
    //     Set<String> critApuracaoDeliverySet = new Set<String>();
    //     Map<Id, Apuracao__c> mapIdToApuracao = new Map<Id, Apuracao__c>();

    //     for (Apuracao__c apuracao : apuracaoList){
    //         mapIdToApuracao.put(apuracao.Id, apuracao);
    //         critApuracaoDeliverySet.add(apuracao.CriterioApuracao__c);
    //     }
        
    //     for (ProgramacaoEntrega__c delivery: [SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c FROM ProgramacaoEntrega__c WHERE CriterioApuracao__c IN: critApuracaoDeliverySet AND Status__c != 'Cancelado' 
    //                                           AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' AND TipoOrdem__c != 'Bonificação' AND DataFaturamento__c = null]){
    //         ProgramacaoEntrega__c deliveryUpdate = new ProgramacaoEntrega__c();
    //         deliveryUpdate.Id = delivery.Id;
    //         deliveryUpdate.Apuracao__c = mapIdToApuracao.get(delivery.Id).Id;

    //         deliveryList.add(deliveryUpdate);
    //     }

    //     if (!deliveryList.isEmpty()){
    //         update deliveryList;
    //     }
    // }

    public static String getCurrentKey(ProgramacaoEntrega__c delivery, DateTime todayDt){
        return delivery.IdOportunidade__c + '_' + delivery.TipoOrdem__c + '_' + delivery.EmissorOrdem__c + '_' + delivery.RecebedorOrdem__c + '_' + delivery.DataEntrega__c + '_' + delivery.DataFaturamento__c+'_'+String.valueOf(todayDt);
    }
    /*public static Messaging.EmailFileAttachment getAttchExcel(Opportunity opp, List<ProgramacaoEntrega__c> prograEntregaList, List<OpportunityLineItem> oppItemList, Account acc, Map<Id, Itinerario__c> idToItinerarioMap){
        Messaging.EmailFileAttachment emailAttch = new Messaging.EmailFileAttachment();
        emailAttch.setContentType('application/vnd.ms-excel');
        emailAttch.setFileName('Dados Oportunidade.xls');

        String body = header;
        Map<Id, List<ProgramacaoEntrega__c>> productToProgramaMap = (Map<Id, List<ProgramacaoEntrega__c>>) Collection.of(prograEntregaList).groupByIds(ProgramacaoEntrega__c.Produto__c);
        Map<Id, List<OpportunityLineItem>> productToOppProductMap = (Map<Id, List<OpportunityLineItem>>) Collection.of(oppItemList).groupByIds(OpportunityLineItem.Product2Id);

        //ONLY 1 PRODUCT TO OPP/PROGRAMACAO
        for(Id prodId : productToProgramaMap.keySet()){
            ProgramacaoEntrega__c prog = productToProgramaMap.get(prodId)[0];
            OpportunityLineItem   oppLine = productToOppProductMap.get(prodId)[0];
            body += getBodyAttch(prog, oppLine, acc, itin, opp);
        }

        blob csvBlob = Blob.valueOf('\uFEFF'+body);
        emailAttch.setBody(csvBlob);
        return emailAttch;
    }
    public static String getBodyAttch(ProgramacaoEntrega__c prog, OpportunityLineItem   oppLine, Account acc, Itinerario__C itin, Opportunity opp){
        List<String> valueList = new List<String>{ 
                opp.NumeroOportunidade__c, 
                String.valueOf(Date.Today()), 
                String.valueOf(opp.DataReferenciaPreco__c), 
                String.valueOf(opp.LocalNegocio__r.Descricao__c), 
                prog.Name, 
                prog.TipoOrdem__c, 
                acc.ListaPreco__c, 
                // (itin != null ? itin.TipoExpedicao__C : ' Vazio '), 
                opp.CondicaoPagamento__r.Descricao__c, 
                String.valueOf(opp.dataInicioJuros__c), 
                String.valueOf(opp.DataVencimento__C), 
                opp.Campanha__r.Descricao__c, 
                opp.NomeRTV__C, 
                opp.Regional__r.NomeRegional__c, 
                oppLine.Product2.SKU__C, 
                oppLine.Product2.Description, 
                String.valueOf(prog.QuantidadeProgramada__c), 
                String.valueOf(prog.PrecoVendasComJurosUSDBRL__c), 
                oppLine.Cultura__r.Descricao__c, 
                String.valueOf(prog.DescontoConcedido__c), 
                String.valueOf(prog.DataEntrega__c), 
                String.valueOf(prog.DataFaturamento__c), 
                opp.ObservacaoLogistica__c,
                opp.ObservacaoInterna__c};
        List<String> newValues = new List<String>();
        for(String values : valueList){
            if(values == null){
                newValues.add('Vazio');
            }else{
                newValues.add(values);
            }
        }
        return String.join(newValues, '\t')+'\n';
    }*/

    public static void validateQuantity(List<ProgramacaoEntrega__c> deliveryList){ 

        string email = Label.AlertaQuantidadeErrada;
        EmailTemplate emailTemplate = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'AvisoProgramacaoEntregaErrada'];

        Set<Id> oppIds = new Set<Id>();
        Map<Id, List<ProgramacaoEntrega__c>> mapDeliveryByOpp = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, Decimal> mapProgrammedQuantity = new Map<Id, Decimal>();

        for(ProgramacaoEntrega__c delivery : deliveryList){
            if(!mapDeliveryByOpp.containsKey(delivery.Id)){
                mapDeliveryByOpp.put(delivery.IdOportunidade__c, new List<ProgramacaoEntrega__c> {delivery});
            }else{
                mapDeliveryByOpp.get(delivery.IdOportunidade__c).add(delivery);
            }
        }

        for(String key : mapDeliveryByOpp.keySet()){
            oppIds.add(key);
        }

        List<Opportunity> oppList = [SELECT Id, Name, TotalOpportunityQuantity, AccountId, OwnerId, Owner.Email FROM Opportunity WHERE Id IN : oppIds];

        for(Opportunity opp : oppList){

            Decimal count = 0;

            if(mapDeliveryByOpp.containsKey(opp.Id)){
                for(ProgramacaoEntrega__c delivery : mapDeliveryByOpp.get(opp.Id)){
                    count += delivery.QuantidadeProgramada__c;
                }
            }
            mapProgrammedQuantity.put(opp.Id, count);
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        for(Opportunity opp : oppList){

            if(mapProgrammedQuantity.containsKey(opp.Id)){

                Decimal count = mapProgrammedQuantity.get(opp.Id);

                if(opp.TotalOpportunityQuantity != count){

                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();  
                    String plainBody = emailTemplate.Body;
                    message.setPlainTextBody(plainBody);
                    message.setTemplateID(emailTemplate.Id); 
                    //message.setTargetObjectId(opp.ownerId);
                    message.setSaveAsActivity(false);
                    message.toAddresses = email.split('/');  
                    messages.add(message);
                }
            } 
        }

        if(!messages.isEmpty()){
            Messaging.sendEmail(messages);
        }

        //Opportunity opt = [SELECT Id, Name, TotalOpportunityQuantity, AccountId, OwnerId, Owner.Email FROM Opportunity WHERE Id = :deliveryList[0].IdOportunidade__c];    

        //Decimal count = 0;

        // for (ProgramacaoEntrega__c delivery : deliveryList){
        //     count += delivery.QuantidadeProgramada__c;
        // }
        // if (count != opt.TotalOpportunityQuantity){
        //     Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();                     
        //     EmailTemplate emailTemplate = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'AvisoProgramacaoEntregaErrada']; 
            
        //     String plainBody = emailTemplate.Body;
        //     plainBody = plainBody.replace('{!ProgramacaoEntrega__c.IdOportunidade__c}', opt.Name);            
        //     message.setPlainTextBody(plainBody);

        //     message.setTemplateID(emailTemplate.Id); 
        //     message.setTargetObjectId(opt.ownerId);
        //     message.setSaveAsActivity(false);
        //     message.toAddresses = email.split('/');  
        //     Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage > {message};              
        //     Messaging.sendEmail(messages);
        // }      
    }

    public static void changeProgramacaoEntregaOwner(List<ProgramacaoEntrega__c> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(ProgramacaoEntrega__c.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        for(ProgramacaoEntrega__c delivery : newRecordsList){
            if(delivery.territorio__c != null && territories.containsKey(delivery.territorio__c) && delivery.ownerId != territories.get(delivery.territorio__c).rtv__c){
                delivery.ownerId = territories.get(delivery.territorio__c).rtv__c;
            }
        }
    }

    //Marca o campo Atualizado__c do objeto Apuracao__c como false
    public static void updateApuracaoField(List<ProgramacaoEntrega__c> oldRecordsList){

        Set<Id> apuracaoId = new Set<Id>();

        for(ProgramacaoEntrega__c delivery : oldRecordsList){
            apuracaoId.add(delivery.Apuracao__c);
        }

        List<Apuracao__c> apuracaoToUpdate = [SELECT Id, Atualizado__c FROM Apuracao__c WHERE Id IN : apuracaoId];

        for(Apuracao__c apuracao : apuracaoToUpdate){
            apuracao.Atualizado__c = false;
        }

        if(!apuracaoToUpdate.isEmpty()){
            ProgramacaoEntregaHelper.disableTrigger();
            update apuracaoToUpdate;
            ProgramacaoEntregaHelper.enableTrigger();
        }
    }
    
}