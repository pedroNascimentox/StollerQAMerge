public class ShippingPolicyService {

    public Date                          referenceDate;
    public ShippingPolicyOpportunityData shippingPolicyOpportunityData;

    public ShippingPolicyService(Opportunity opportunity){
        this.shippingPolicyOpportunityData = new ShippingPolicyOpportunityData(opportunity);
        this.referenceDate = Date.today();
    }

    public ShippingPolicyService(OpportunityData opportunityData){
        this.shippingPolicyOpportunityData = new ShippingPolicyOpportunityData(opportunityData);
        this.referenceDate = Date.today();
    }

    public void setReferenceDate(Date referenceDate){
        this.referenceDate = referenceDate;
    }

    public ShippingPolicyServiceReturnedData getShippingTable(){

        ShippingPolicyServiceReturnedData returnedData = new ShippingPolicyServiceReturnedData();

        try{

            TabelaFrete__c shippingTable = getShippingTableByShipmentCondition();

            returnedData = new ShippingPolicyServiceReturnedData(shippingTable);

        } catch (Exception e){

            returnedData = new ShippingPolicyServiceReturnedData(e);

            // throw new ShippingPolicyException();

        }

        return returnedData;

    }

    public TabelaFrete__c getShippingTableByShipmentCondition(){

        TabelaFrete__c shippingTable = null;
        List<TabelaFrete__c> shippingTables;

        System.debug('this.shippingPolicyOpportunityData.shipmentCondition => ' + this.shippingPolicyOpportunityData.shipmentCondition);
        System.debug('this.shippingPolicyOpportunityData.businessLocation => ' + this.shippingPolicyOpportunityData.businessLocation);
        System.debug('this.shippingPolicyOpportunityData.uf => ' + this.shippingPolicyOpportunityData.uf);
        System.debug('this.referenceDate => ' + this.referenceDate);
        System.debug('this.shippingPolicyOpportunityData.exportFreight => ' + this.shippingPolicyOpportunityData.exportFreight);

        shippingTables = [
            SELECT id,
                (
                    SELECT id, frete__c
                    FROM VigenciaTabelaFrete__r
                    WHERE dataVigenciaDe__c <= :this.referenceDate
                    AND dataVigenciaAte__c >= :this.referenceDate
                    ORDER BY createdDate DESC
                    LIMIT 1
                )
                FROM TabelaFrete__c
                WHERE localNegocio__c = :this.shippingPolicyOpportunityData.businessLocation
                AND regiaoUF__c = :this.shippingPolicyOpportunityData.uf
                AND tipoFrete__c = :this.shippingPolicyOpportunityData.shipmentCondition
                AND id IN (
                    SELECT tabelaFrete__c
                    FROM VigenciaTabelaFrete__c
                    WHERE dataVigenciaDe__c <= :this.referenceDate
                    AND dataVigenciaAte__c >= :this.referenceDate
                )
        ];

        if (shippingTables.isEmpty()) {
            if (!this.shippingPolicyOpportunityData.exportFreight) {
                throw new ShippingPolicyException('Não foi encontrada uma tabela de frete apropriada!');
            }
        }else {
            shippingTable = shippingTables[0];
        }

        return shippingTable;

    }

    public class ShippingPolicyException extends Exception{}

}