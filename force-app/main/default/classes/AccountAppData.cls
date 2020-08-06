public class AccountAppData {

    public String id;
    public String name;
    public Boolean block;
    public ReturningAccountDataFields returningFields;
    
    public AccountAppData() {}
    
    public AccountAppData(Account account) {
        this.id = account.id;
        this.block = account.BloqueadoCredito__c;
        this.name = account.name;
        this.returningFields = new ReturningAccountDataFields(account);
    }

    public class ReturningAccountDataFields{
        public String  id;
        public String  name;
        public Boolean  block;
        public String  customerType;
        public String  resaleAgent;
        public String  paymentRating;
        public String  shippingState;
        public String  shippingCity;
        public String  farmName;
        public Boolean ICMScontributor;

        public ReturningAccountDataFields(Account account){
            this.id              = account.id;
            this.name            = account.name;
            this.block            = account.BloqueadoCredito__c;
            this.customerType    = account.tipoCliente__c;
            this.resaleAgent     = account.revendaAgenciadora__c;
            this.paymentRating   = account.ratingPagamento__c;
            this.shippingState   = account.shippingState;
            this.shippingCity    = account.shippingCity;
            this.farmName        = account.nomeFazenda__c;
            this.ICMScontributor = account.contribuinteICMS__c;
        }
    }
}