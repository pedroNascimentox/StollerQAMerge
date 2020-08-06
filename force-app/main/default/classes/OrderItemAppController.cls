public class OrderItemAppController {
    
    public String orderId   {get; set;}
    public String orderNumber {get; set;}
    
    public static final String DEFAULT_CURRENCY_CODE = 'BRL';
    public static String CUSTOMER_SERVICE_PROFILE_TERM;
    public static String GERENTE_REGIONAL_PROFILE_TERM;
    public static String DIRETOR_COMERCIAL_PROFILE_TERM;
    public static String ADMINISTRATOR_PROFILE_TERM;
    public static Profile userProfile;
    public Boolean isCustomerService {get;set;}

    static{
        userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        CUSTOMER_SERVICE_PROFILE_TERM  = Label.CustomerServiceProfileTerm;
        GERENTE_REGIONAL_PROFILE_TERM  = Label.RegionalManagerProfileTerm;
        DIRETOR_COMERCIAL_PROFILE_TERM = Label.ComercialDirectorProfileTerm;
        ADMINISTRATOR_PROFILE_TERM     = [SELECT Id, name FROM Profile WHERE PermissionsModifyAllData = true AND PermissionsPrivacyDataAccess = true ORDER BY CreatedDate LIMIT 1].name;
    }

    public OrderItemAppController() {}

    public OrderItemAppController(ApexPages.StandardController standardController) {
        
        this.isCustomerService = isCustomerService();
        
        this.orderId = ApexPages.currentPage().getParameters().get('Id');
        if(this.orderId != null){
            this.orderNumber = [SELECT orderNumber FROM Order WHERE id = :orderId].orderNumber;
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

    @RemoteAction
    public static ResponseOrderItemListData getOrderItemListData(String orderId) {
        
        ResponseOrderItemListData responseData = new ResponseOrderItemListData();                     
        Map<Integer, List<OrderItem>> mapItemNumberToOrderItemList = new Map<Integer, List<OrderItem>>();

        for(OrderItem orderItem : [
            SELECT  id, nrItem__c, product2.id, product2.name, product2.embalagem__c, QuantidadeFornecida__c,  
                    product2.sku__c, Quantity, numeroRemessa__c,
                    linhaDivisaoRemessa__c, quantidadeConfirmada__c, valorTotal__c, 
                    valorTotalUSD__c, dataEntrega__c, litros__c, statusSAP__c, dataFaturamento__c, toLabel(MotivoRecusaItem__c), ValorUnitarioComJuros__c, ValorTotalReaisDolar__c, Order.Moeda__c
            FROM OrderItem
            WHERE orderId = :orderId
            AND nrItem__c != null
            ORDER BY linhaDivisaoRemessa__c ASC
        ]){
            if(!mapItemNumberToOrderItemList.containsKey(Integer.valueOf(orderItem.nrItem__c))) {
                mapItemNumberToOrderItemList.put(Integer.valueOf(orderItem.nrItem__c), new List<OrderItem>());
            }
            mapItemNumberToOrderItemList.get(Integer.valueOf(orderItem.nrItem__c)).add(orderItem);
        }

        System.debug('mapItemNumberToOrderItemList.values().size() => ' + mapItemNumberToOrderItemList);

        try {
            if(mapItemNumberToOrderItemList.isEmpty()){
                throw new OrderItemAppControllerException('Não há itens para esse pedido');
            } else {
                responseData.data = fillResponseOrderItemListData(mapItemNumberToOrderItemList);
            }
        } catch (Exception ex) {
            responseData = new ResponseOrderItemListData(ex);
        }

        system.debug(responseData);

        return responseData;
    }

    public static List<OrderItemData> fillResponseOrderItemListData(Map<Integer, List<OrderItem>> mapItemNumberToOrderItemList){
        
        List<OrderItemData> orderItemDataList = new List<OrderItemData>();
        List<ScheduleData>  scheduleDataList;

        Decimal totalBRL;
        Decimal totalUSD;

        for(Integer nrItem : mapItemNumberToOrderItemList.keySet()){

            OrderItemData orderItemData = new OrderItemData(mapItemNumberToOrderItemList.get(nrItem)[0]);
            scheduleDataList = new List<ScheduleData>();
            totalBRL = 0;
            totalUSD = 0;
            
            for(OrderItem orderItem : mapItemNumberToOrderItemList.get(nrItem)){

                ScheduleData scheduleData = new ScheduleData(orderItem);
                scheduleDataList.add(scheduleData);
                
                totalBRL += orderItem.valorTotal__c;
                totalUSD += orderItem.valorTotalUSD__c;

            }

            // orderItemData.setTotalBRL(totalBRL);
            // orderItemData.setTotalUSD(totalUSD);
            // orderItemData.setTotal();
            orderItemData.setScheduleData(scheduleDataList);

            orderItemDataList.add(orderItemData);
        }

        return orderItemDataList;
    }

    public class OrderItemAppControllerException extends Exception{}

    public class ResponseOrderItemListData extends ResultTemplate {
        List<OrderItemData> data = new List<OrderItemData>();
        
        public ResponseOrderItemListData() {
            this.hasErrors      = false;
            this.message        = 'Success';
        }

        public ResponseOrderItemListData(Exception error) {
            this.data           = null;
            this.hasErrors      = true;
            this.message        = error.getMessage();
            this.stackStrace    = error.getStackTraceString();
        }
    }

    public class OrderItemData {

        public String         id;
        public Integer        nrItem; //NrItem__c
        public String         productId; //product2.id
        public String         name; //product2.name
        public String         sku; //product2.sku__c
        public Integer        quantity; //Quantity
        public Integer        confirmedQuantity;
        public Integer        providedQuantity;
        public Decimal        totalBRL; //somatória
        public Decimal        totalUSD; //somatória
        public Decimal        unitPrice;
        public Decimal        totalValue;
        public String         currencySymbol;
        public String         nrSchedule; //numeroRemessa__c
        public Date           scheduleDate;
        // public Date           billingDate;
        public String         packing;
        // public String         statusSAP;
        public String         cancellingReason;
        public ScheduleData[] schedules;
        
        public OrderItemData() {}
        
        public OrderItemData(OrderItem orderItem) {
            this.nrItem             = String.isBlank(orderItem.nrItem__c)? 0 : Integer.valueOf(orderItem.nrItem__c);
            this.id                 = orderItem.id;
            this.productId          = orderItem.product2.id;
            this.name               = orderItem.product2.name;
            this.packing            = orderItem.product2.embalagem__c;
            this.sku                = orderItem.product2.sku__c;
            this.quantity           = orderItem.Quantity == null ? 0 : Integer.valueOf(orderItem.Quantity);
            this.confirmedQuantity  = orderItem.quantidadeConfirmada__c == null ? 0 : Integer.valueOf(orderItem.quantidadeConfirmada__c);
            this.providedQuantity  = orderItem.QuantidadeFornecida__c == null ? 0 : Integer.valueOf(orderItem.QuantidadeFornecida__c);
            this.nrSchedule         = orderItem.numeroRemessa__c;
            this.scheduleDate       = orderItem.dataEntrega__c;
            // this.billingDate        = orderItem.dataFaturamento__c;
            // this.statusSAP          = orderItem.statusSAP__c;
            this.cancellingReason   = orderItem.MotivoRecusaItem__c;
            this.unitPrice          = orderItem.ValorUnitarioComJuros__c;
            this.currencySymbol     = orderItem.Order.Moeda__c;
            this.totalValue         = orderItem.ValorTotalReaisDolar__c;
        }

        public void setTotalBRL(Decimal totalBRL){
            this.totalBRL = totalBRL;
        }

        public void setTotalUSD(Decimal totalUSD){
            this.totalUSD = totalUSD;
        }
        
        public void setTotal(){
            if (this.currencySymbol == 'BRL') {
                this.totalValue = this.totalBRL;                
            }else {
                this.totalValue = this.totalUSD;
            }
        }

        public void setScheduleData(ScheduleData[] schedules){
            this.schedules = schedules;
        }
    }

    public class ScheduleData {

        public String  id;
        public Integer scheduleLine;
        public Integer quantity; 
        public Integer confirmedQuantity;
        public Integer providedQuantity;
        public Decimal totalBRL;
        public Decimal totalUSD;
        public Date    scheduleDate;
        public Integer liter;
        public String  statusSAP;
        public Date    billingDate;

        public ScheduleData(){}

        public ScheduleData(OrderItem schedule) {
            this.id                = schedule.id;
            this.scheduleLine      = String.isBlank(schedule.linhaDivisaoRemessa__c)? 0 : Integer.valueOf(schedule.linhaDivisaoRemessa__c);
            this.quantity          = schedule.quantity == null ? 0 : Integer.valueOf(schedule.quantity);
            this.confirmedQuantity = schedule.quantidadeConfirmada__c == null ? 0 : Integer.valueOf(schedule.quantidadeConfirmada__c);
            this.providedQuantity  = schedule.QuantidadeFornecida__c == null ? 0 : Integer.valueOf(schedule.QuantidadeFornecida__c);
            this.totalBRL          = schedule.valorTotal__c;
            this.totalUSD          = schedule.valorTotalUSD__c;
            this.scheduleDate      = schedule.dataEntrega__c;
            this.liter             = schedule.litros__c == null ? 0 : Integer.valueOf(schedule.litros__c);
            this.statusSAP         = schedule.statusSAP__c;
            this.billingDate       = schedule.dataFaturamento__c;
        }

    }
}