public virtual class OpportunityAppBaseData {

    public List<PicklistEntryData>    shipmentConditions;
    public List<PicklistEntryData>    currencies;
    public List<PaymentConditionData> paymentConditions;
    public List<PicklistEntryData>    orderTypes;
    public List<PicklistEntryData>    salesClassifications;
    public List<PicklistEntryData>    orderReasons;
    public List<PicklistEntryData>    changeTypes;
    public List<CultureData>          cultures;
    public List<FreightTypeData>      freightTypes;
    public DollarAppData              dollarData;
    public List<Holiday>              holidays;
    public Decimal                    confirmationDeadlineDays;
    public Integer                    deliveryQuantityLimit;
    
    public OpportunityAppBaseData(List<PicklistEntryData> shipmentConditionsEntryDataList, List<PicklistEntryData> currenciesEntryDataList, List<PaymentConditionData> paymentConditionsDataList, List<PicklistEntryData> recordTypeDataList, List<PicklistEntryData> salesClassificationsDataList, List<PicklistEntryData> orderReasonsDataList, List<CultureData> cultureDataList){
        this.shipmentConditions   = shipmentConditionsEntryDataList;
        this.currencies           = currenciesEntryDataList;
        this.paymentConditions    = paymentConditionsDataList;
        this.orderTypes           = recordTypeDataList;
        this.salesClassifications = salesClassificationsDataList;
        this.orderReasons         = orderReasonsDataList;
        this.cultures             = cultureDataList;
        this.freightTypes         = new List<FreightTypeData>{
            new FreightTypeData('CIF', 'CIF', true),
            new FreightTypeData('FOB', 'FOB')
        };
    }

    public OpportunityAppBaseData(List<PicklistEntryData> shipmentConditionsEntryDataList, List<PicklistEntryData> currenciesEntryDataList, List<PaymentConditionData> paymentConditionsDataList, List<PicklistEntryData> recordTypeDataList, List<PicklistEntryData> salesClassificationsDataList, List<PicklistEntryData> orderReasonsDataList, List<CultureData> cultureDataList, DollarAppData dollarData){
        this.shipmentConditions   = shipmentConditionsEntryDataList;
        this.currencies           = currenciesEntryDataList;
        this.paymentConditions    = paymentConditionsDataList;
        this.orderTypes           = recordTypeDataList;
        this.salesClassifications = salesClassificationsDataList;
        this.orderReasons         = orderReasonsDataList;
        this.cultures             = cultureDataList;
        this.freightTypes         = new List<FreightTypeData>{
            new FreightTypeData('CIF', 'CIF', true),
            new FreightTypeData('FOB', 'FOB')
        };
        this.dollarData            = dollarData;
    }
    
    public OpportunityAppBaseData(List<PicklistEntryData> recordTypeDataList, List<CultureData> cultureDataList){
        this.orderTypes           = recordTypeDataList;
        this.cultures             = cultureDataList;
    }

    public OpportunityAppBaseData(){
        this.freightTypes         = new List<FreightTypeData>{
            new FreightTypeData('CIF', 'CIF', true),
            new FreightTypeData('FOB', 'FOB')
        };
    }

    public void setOrderReasons(List<PicklistEntryData> orderReasonsDataList){
        this.orderReasons = orderReasonsDataList;
    }

    public void setChangeTypes(List<PicklistEntryData> changeTypesDataList){
        this.changeTypes = changeTypesDataList;
    }

    public void setHolidays(List<Holiday> holidays){
        this.holidays = holidays;
    }

    public void setConfirmationDeadline(Decimal days){
        this.confirmationDeadlineDays = days;
    }

    public void setDeliveryQuantityLimit(Integer quantityLimit){
        this.deliveryQuantityLimit = quantityLimit;
    }
    

}