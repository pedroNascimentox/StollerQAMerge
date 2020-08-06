public class PricingSimulationAppController {

    public Profile userProfile; 
    public Boolean hasCustomerServiceAccess {get; set;}
    public Boolean isRTV {get; set;}

    @RemoteAction
    public static OpportunityAppReturnedData getPrices(PriceSimulationDataRequest request){
        try {
            if (request.isCustomerSpecific){
                OpportunitySimulationDataRequest requestData = request.data;

                CondicaoPagamento__c defaultCondition = [SELECT id FROM CondicaoPagamento__c WHERE descricao__c LIKE '%VISTA%' LIMIT 1];
                String defaultCurrencyCode = OpportunityAppController.DEFAULT_CURRENCY_CODE;

                Cultura__c[] cultures = [
                    SELECT 
                        id 
                    FROM Cultura__c 
                    LIMIT 500
                ];

                requestData.cultures = Collection.of(cultures).pluckIds();
                // requestData.currencyName = defaultCurrencyCode;
                System.debug('requestData.currencyName => ' + requestData.currencyName);

                OpportunityAppReturnedData priceData = OpportunityAppController.getOppReturnedData(requestData);

                if (priceData.hasErrors){
                    throw new PricingSimulationAppControllerException(priceData.message);
                } else {
                    if (priceData.data.productsData.size() == 0){
                        throw new PricingSimulationAppControllerException('Não foram encontrados produtos com estes parâmetros.');
                    }
                    return priceData;
                }
            }
        } catch (Exception e){
            return new OpportunityAppReturnedData(e);
        }

        return new OpportunityAppReturnedData(); //?
    }
    
    @RemoteAction
    public static SimulationResult getPdfDocument(OpportunityAppReturnedData request){
        try {
            Folder targetFolder = [SELECT id FROM Folder WHERE name = 'Documentos compartilhados' OR name = 'Shared Documents' LIMIT 1];
                
            Document targetDocument = new Document();
            targetDocument.folderId = targetFolder.id;
            targetDocument.Body = Blob.valueOf(JSON.serialize(request));
            targetDocument.ContentType = 'text/json';
            targetDocument.Name = 'SIMULACAO' + '_' + UserInfo.getUserId() + '_' + Datetime.now();
            targetDocument.Type = 'text';
            insert targetDocument;

            return new SimulationResult(targetDocument);
        } catch (Exception e){
            return new SimulationResult(e);
        }
    }

    @RemoteAction
    public static SimulationAppReturnedBaseData getBaseData(){
        SimulationAppReturnedBaseData simulationAppReturnedBaseData;
        
        try {
         
            SimulationAppBaseData simulationAppBaseData = new SimulationAppBaseData();
            simulationAppReturnedBaseData = new SimulationAppReturnedBaseData(simulationAppBaseData);

        } catch (Exception e){
            simulationAppReturnedBaseData = new SimulationAppReturnedBaseData(e.getMessage());
        }

        return simulationAppReturnedBaseData;
    }

    public PricingSimulationAppController() {
        Apexpages.currentPage().getHeaders().put('Content-Disposition', 'inline;filename=PDF.pdf');
        
        this.userProfile = [
            SELECT 
                id, name
            FROM Profile 
            WHERE id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        //this.isCustomerService = isCustomerService();

        this.hasCustomerServiceAccess = (
            this.userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM)  ||
            this.userProfile.name.containsIgnoreCase(OpportunityAppController.GERENTE_REGIONAL_PROFILE_TERM)  ||
            this.userProfile.name.containsIgnoreCase(OpportunityAppController.DIRETOR_COMERCIAL_PROFILE_TERM) ||
            this.userProfile.name.containsIgnoreCase(OpportunityAppController.ADMINISTRATOR_PROFILE_TERM)     
        );
        this.isRTV                    = this.userProfile.name.containsIgnoreCase('RTV');

        System.debug('this.userProfile.name => ' + this.userProfile.name);

        System.debug('this.hasCustomerServiceAccess => ' + this.hasCustomerServiceAccess);

        System.debug('this.userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM) => ' + this.userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM));
    }

    // public Boolean isCustomerService(){
    //     return this.userProfile.name.containsIgnoreCase(OpportunityAppController.CUSTOMER_SERVICE_PROFILE_TERM);
    // }

    public class SimulationResult extends ResultTemplate{
        public SimulationResult(){}

        public Id documentId;

        public SimulationResult(Document doc) {
            this.documentId = doc.id;
            this.hasErrors  = false;
            this.message    = 'Success';
            this.stackStrace = null;
        }

        public SimulationResult(Exception error) {
            this.documentId  = null;
            this.hasErrors   = true;
            this.message     = error.getMessage();
            this.stackStrace = error.getStackTraceString();
        }

        public SimulationResult(String message) {
            this.documentId  = null;
            this.hasErrors   = true;
            this.message     = message;
            this.stackStrace = null;
        }
    }

    public class PricingSimulationAppControllerException extends Exception{}
}