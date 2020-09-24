public class PriceRepository {

    public static TabelaPreco__c[] getMostSpecificPrices(Account a, Date effectiveDate, String regional){
        List<Id> allProductIds = Collection.of([
            SELECT 
                id 
            FROM Product2 
            LIMIT 10000
        ]).pluckIds();
        return getMostSpecificPrices(a, allProductIds, effectiveDate, regional);
    }
    
    public static TabelaPreco__c[] getMostSpecificPrices(Account a, Id[] productIds, Date effectiveDate, String regional){
        System.debug('a.listaPreco__c  => ' + a.listaPreco__c);
        System.debug('effectiveDate  => ' + effectiveDate);
        System.debug('regional => ' + regional);
        System.debug('a.tipoCliente__c => ' + a.tipoCliente__c);
        System.debug('a.id => ' + a.id);
        System.debug('a.parentId => ' + a.parentId);
        return [
            SELECT 
                id, 
                cliente__c,
                dataVigenciaFim__c,
                dataVigenciaInicial__c,
                externalId__c,
                hierarquiaCliente__c,
                listaPreco__c,
                organizacaoVenda__c,
                produto__c,
                regional__c,
                tipoCliente__c,
                valor__c
            FROM TabelaPreco__c
            WHERE 
                organizacaoVenda__c = '1000' AND
                produto__c IN :productIds    AND
                (listaPreco__c != NULL AND listaPreco__c = :a.listaPreco__c) AND

                (dataVigenciaInicial__c <= :effectiveDate AND dataVigenciaFim__c >= :effectiveDate) AND 
                ( (regional__c          != null AND regional__c          = :regional) OR (regional__c          = NULL) ) AND
                ( (tipoCliente__c       != null AND tipoCliente__c       = :a.tipoCliente__c)    OR (tipoCliente__c       = NULL) ) AND
                ( (cliente__c           != null AND cliente__c           = :a.id)                OR (cliente__c           = NULL) ) AND
                ( (hierarquiaCliente__c != null AND (hierarquiaCliente__c = :a.parentId OR hierarquiaCliente__c = :a.id)) OR (hierarquiaCliente__c = NULL) )

            ORDER BY 
                hierarquiaCliente__c NULLS LAST,
                cliente__c           NULLS LAST, 
                clienteRegiao__c     NULLS LAST,
                tipoCliente__c       ASC,
                regional__c          NULLS LAST,
                createdDate          DESC
        ];
    }

    public static TabelaPreco__c[] getMostSpecificPrices(Account a, String currencyName, Date effectiveDate, String regional){
        System.debug('currencyName => ' + currencyName);
        if (currencyName == 'USD'){
            a.listaPreco__c = 'Z4';
        }

        return getMostSpecificPrices(a, effectiveDate, regional);
    }
    
    public static TabelaPreco__c[] getMostSpecificPrices(Account a, String currencyName, Id[] productIds, Date effectiveDate, String regional){
        System.debug('currencyName => ' + currencyName);
        if (currencyName == 'USD'){
            a.listaPreco__c = 'Z4';
        }

        return getMostSpecificPrices(a, productIds, effectiveDate, regional);
    }

    public static List<TabelaPreco__c> findByProductIds(Set<Id> productIds){
        List<TabelaPreco__c> priceBooks = [
            SELECT 
                id, 
                cliente__c, 
                dataVigenciaFim__c, 
                dataVigenciaInicial__c, 
                externalId__c, 
                hierarquiaCliente__c, 
                listaPreco__c, 
                organizacaoVenda__c, 
                produto__c, 
                regional__c, 
                tipoCliente__c, 
                valor__c
            FROM TabelaPreco__c 
            WHERE
                produto__c IN :productIds AND
                dataVigenciaInicial__c <= :system.today() AND 
                dataVigenciaFim__c >= :system.today()
        ];

        return priceBooks.size() > 0 ? priceBooks : null;
    }
}