public class DollarAppData {
    
    public Decimal rate;
    public Decimal averageRate;
    public String  rateDate;
    
    public DollarAppData() {}

    public void setDollarData(CotacaoMoeda__c dollarExchangeRate){
        this.rate        = dollarExchangeRate.taxaMedia__c;
        this.averageRate = dollarExchangeRate.taxaMedia__c;
        this.rateDate    = String.valueOf(dollarExchangeRate.data__c);
    }
}