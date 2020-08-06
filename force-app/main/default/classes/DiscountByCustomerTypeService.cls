public class DiscountByCustomerTypeService {
    
    public String customerType;
    public Date   rangeDate;

    public DiscountByCustomerTypeService(String customerType, Date rangeDate){
        this.customerType = customerType;
        this.rangeDate    = rangeDate;
    }

    public DiscountByCustomerTypeReturnedData getDiscountByCustomerType(){

        DiscountByCustomerTypeReturnedData returnedData = new DiscountByCustomerTypeReturnedData();

        try{
            //
            List<DescontoTipoCliente__c> customerTypeDiscounts = [
                SELECT id, desconto__c, tipoCliente__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM DescontoTipoCliente__c
                WHERE tipoCliente__c =: this.customerType
                AND dataVigenciaInicial__c <= : this.rangeDate
                AND dataVigenciaFinal__c >=: this.rangeDate
                ORDER BY createdDate DESC
                LIMIT 1
            ];
            
            if(customerTypeDiscounts.isEmpty()){
                throw new DiscountByCustomerTypeServiceException('Não existe desconto por tipo de cliente cadastrado para esse cliente.');//
            } else {
                returnedData = new DiscountByCustomerTypeReturnedData(customerTypeDiscounts[0]);
            }
            
        } catch (Exception e){

            returnedData = new DiscountByCustomerTypeReturnedData(e);

        }

        return returnedData;
    }

    public class DiscountByCustomerTypeServiceException extends Exception{}//
}