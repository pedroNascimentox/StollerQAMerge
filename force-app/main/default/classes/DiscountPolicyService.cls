public class DiscountPolicyService {
    
    public Date                          rangeDate;
    public Set<String>                   remanescentProductIds;
    public DiscountPolicyOpportunityData discountPolicyOpportunityData;

    public DiscountPolicyService(Opportunity opportunity){
        this.discountPolicyOpportunityData = new DiscountPolicyOpportunityData(opportunity);
        this.rangeDate                     = opportunity.closeDate;
    }

    public DiscountPolicyService(DiscountPolicyOpportunityData discountPolicyOpportunityData){
        this.rangeDate                     = Date.today();
        this.discountPolicyOpportunityData = discountPolicyOpportunityData;
    }

    public DiscountPolicyService(DiscountPolicyOpportunityData discountPolicyOpportunityData, Date rangeDate){
        this.rangeDate                     = rangeDate;
        this.discountPolicyOpportunityData = discountPolicyOpportunityData;
    }

    public DiscountPolicyServiceReturnedData getDiscountPolicy(Set<String> productIds){

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            this.remanescentProductIds = productIds;

            returnedData.putAllFrom(getDiscountPolicyByCustomerHierarchy(remanescentProductIds, returnedData));
            
            returnedData.putAllFrom(getDiscountPolicyByCustomer(remanescentProductIds, returnedData));
            
            returnedData.putAllFrom(getDiscountPolicyByRegional(remanescentProductIds, returnedData));

            returnedData.putAllFrom(getDiscountPolicyByTerritory(remanescentProductIds, returnedData));
            
            returnedData.putAllFrom(getDiscountPolicyByGenericKey(remanescentProductIds, returnedData));

            if(returnedData.data != null){
                remanescentProductIds.removeAll(returnedData.data.keySet());
            }

            for(String productId : remanescentProductIds){
                returnedData.data.put(productId, new DiscountPolicyServiceData('Não existe politica de desconto cadastrada para este item, favor entrar em contato com o departamento de Marketing.'));
            }
        
        } catch (Exception e){
            returnedData = new DiscountPolicyServiceReturnedData(e.getMessage());
        }

        return returnedData;
    
    }

    private DiscountPolicyServiceReturnedData getDiscountPolicyByCustomerHierarchy(Set<String> remanescentProductIds, DiscountPolicyServiceReturnedData lastReturnedData){
        

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            List<PoliticaDesconto__c> discountPolicies = [
                SELECT id, produto__c, maximo__c, minimo__c, recomendado__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM PoliticaDesconto__c
                WHERE organizacaoVenda__c =: this.discountPolicyOpportunityData.salesOrganization
                AND dataVigenciaInicial__c <= :this.rangeDate
                AND dataVigenciaFinal__c >= :this.rangeDate
                AND produto__c IN : remanescentProductIds
                AND produto__c NOT IN : (lastReturnedData.data != null? lastReturnedData.data.keySet() : new Set<String>())
                AND hierarquia__c =: this.discountPolicyOpportunityData.customersHierarchy
                AND hierarquia__c != NULL
                ORDER BY createdDate DESC
            ];


            for(PoliticaDesconto__c discountPolicy : discountPolicies){
                returnedData.putAllFrom(new DiscountPolicyServiceReturnedData(discountPolicy));
            }

        } catch (Exception e){
            throw new DiscountPolicyException(e.getMessage());
        }

        return returnedData;

    }

    private DiscountPolicyServiceReturnedData getDiscountPolicyByCustomer(Set<String> remanescentProductIds, DiscountPolicyServiceReturnedData lastReturnedData){
        

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            List<PoliticaDesconto__c> discountPolicies = [
                SELECT id, produto__c, maximo__c, minimo__c, recomendado__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM PoliticaDesconto__c
                WHERE organizacaoVenda__c =: this.discountPolicyOpportunityData.salesOrganization
                AND dataVigenciaInicial__c <= :this.rangeDate
                AND dataVigenciaFinal__c >= :this.rangeDate
                AND produto__c IN : remanescentProductIds
                AND produto__c NOT IN : (lastReturnedData.data != null? lastReturnedData.data.keySet() : new Set<String>())
                AND conta__c =: this.discountPolicyOpportunityData.customer
                AND conta__c != NULL
                ORDER BY createdDate DESC
            ];


            for(PoliticaDesconto__c discountPolicy : discountPolicies){
                returnedData.putAllFrom(new DiscountPolicyServiceReturnedData(discountPolicy));
            }

        } catch (Exception e){
            throw new DiscountPolicyException(e.getMessage());
        }

        return returnedData;

    }

    private DiscountPolicyServiceReturnedData getDiscountPolicyByRegional(Set<String> remanescentProductIds, DiscountPolicyServiceReturnedData lastReturnedData){
        

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            List<PoliticaDesconto__c> discountPolicies = [
                SELECT id, produto__c, maximo__c, minimo__c, recomendado__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM PoliticaDesconto__c
                WHERE organizacaoVenda__c =: this.discountPolicyOpportunityData.salesOrganization
                AND dataVigenciaInicial__c <= :this.rangeDate
                AND dataVigenciaFinal__c >= :this.rangeDate
                AND produto__c IN : remanescentProductIds
                AND produto__c NOT IN : (lastReturnedData.data != null? lastReturnedData.data.keySet() : new Set<String>())
                AND regional__c =: this.discountPolicyOpportunityData.regional
                AND regional__c != NULL
                ORDER BY createdDate DESC
            ];


            for(PoliticaDesconto__c discountPolicy : discountPolicies){
                returnedData.putAllFrom(new DiscountPolicyServiceReturnedData(discountPolicy));
            }

        } catch (Exception e){
            throw new DiscountPolicyException(e.getMessage());
        }

        return returnedData;

    }

    private DiscountPolicyServiceReturnedData getDiscountPolicyByTerritory(Set<String> remanescentProductIds, DiscountPolicyServiceReturnedData lastReturnedData){
        

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            List<PoliticaDesconto__c> discountPolicies = [
                SELECT id, produto__c, maximo__c, minimo__c, recomendado__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM PoliticaDesconto__c
                WHERE organizacaoVenda__c =: this.discountPolicyOpportunityData.salesOrganization
                AND dataVigenciaInicial__c <= :this.rangeDate
                AND dataVigenciaFinal__c >= :this.rangeDate
                AND produto__c IN : remanescentProductIds
                AND produto__c NOT IN : (lastReturnedData.data != null? lastReturnedData.data.keySet() : new Set<String>())
                AND territorio__c =: this.discountPolicyOpportunityData.territory
                AND territorio__c != NULL
                ORDER BY createdDate DESC
            ];


            for(PoliticaDesconto__c discountPolicy : discountPolicies){
                returnedData.putAllFrom(new DiscountPolicyServiceReturnedData(discountPolicy));
            }

        } catch (Exception e){
            throw new DiscountPolicyException(e.getMessage());
        }

        return returnedData;

    }

    private DiscountPolicyServiceReturnedData getDiscountPolicyByGenericKey(Set<String> remanescentProductIds, DiscountPolicyServiceReturnedData lastReturnedData){
        

        DiscountPolicyServiceReturnedData returnedData = new DiscountPolicyServiceReturnedData();

        try {

            List<PoliticaDesconto__c> discountPolicies = [
                SELECT id, produto__c, maximo__c, minimo__c, recomendado__c, dataVigenciaInicial__c, dataVigenciaFinal__c
                FROM PoliticaDesconto__c
                WHERE organizacaoVenda__c =: this.discountPolicyOpportunityData.salesOrganization
                AND dataVigenciaInicial__c <= :this.rangeDate
                AND dataVigenciaFinal__c >= :this.rangeDate
                AND produto__c IN : remanescentProductIds
                AND hierarquia__c = NULL
                AND conta__c = NULL
                AND regional__c = NULL
                AND territorio__c = NULL
                AND produto__c NOT IN : (lastReturnedData.data != null? lastReturnedData.data.keySet() : new Set<String>())
                ORDER BY createdDate DESC
            ];

            for(PoliticaDesconto__c discountPolicy : discountPolicies){
                returnedData.putAllFrom(new DiscountPolicyServiceReturnedData(discountPolicy));
            }

        } catch (Exception e){
            throw new DiscountPolicyException(e.getMessage());
        }

        return returnedData;

    }

    public class DiscountPolicyException extends Exception {}
}