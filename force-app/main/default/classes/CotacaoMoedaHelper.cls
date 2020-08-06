public class CotacaoMoedaHelper extends TriggerContext{
    public static void updateAverageQuote(CotacaoMoeda__c[] newRecords){
        Map<String, CotacaoMoeda__c[]> quotesGroupedByPeriodAndCurrency = new Map<String, CotacaoMoeda__c[]>();

        Set<String> currencySet = new Set<String>();
        Set<Integer> monthSet = new Set<Integer>();
        Set<Integer> yearSet  = new Set<Integer>();

        for(CotacaoMoeda__c currencyQuote : newRecords){
            String quoteKey = getCurrencyKey(currencyQuote);

            if (!quotesGroupedByPeriodAndCurrency.containsKey(quoteKey)){
                quotesGroupedByPeriodAndCurrency.put(quoteKey, new List<CotacaoMoeda__c>());
            }

            quotesGroupedByPeriodAndCurrency.get(quoteKey).add(currencyQuote);

            currencySet.add(currencyQuote.moeda__c);
            monthSet.add(currencyQuote.data__c.month());
            yearSet.add(currencyQuote.data__c.year());
        }

        Map<String, CotacaoMoeda__c[]> quotesOfSamePeriodAndCurrencyGrouped = new Map<String, CotacaoMoeda__c[]>();

        for(CotacaoMoeda__c currencyQuote : [
            SELECT 
                id, 
                data__c,
                taxa__c,
                moeda__c
            FROM CotacaoMoeda__c
            WHERE CALENDAR_MONTH(data__c) IN :monthSet
            AND   CALENDAR_YEAR(data__c)  IN :yearSet
            AND   Moeda__c                IN :currencySet
            ORDER BY data__c ASC
        ]){
            String quoteKey = getCurrencyKey(currencyQuote);

            if (!quotesOfSamePeriodAndCurrencyGrouped.containsKey(quoteKey)){
                quotesOfSamePeriodAndCurrencyGrouped.put(quoteKey, new List<CotacaoMoeda__c>());
            }
            quotesOfSamePeriodAndCurrencyGrouped.get(quoteKey).add(currencyQuote);
        }

        CotacaoMoeda__c[] quotesWithUpdatedAverage = new CotacaoMoeda__c[]{};

        for(String monthAndYear : quotesGroupedByPeriodAndCurrency.keySet()){
            for(CotacaoMoeda__c currencyQuote : quotesGroupedByPeriodAndCurrency.get(monthAndYear)){
                
                Decimal quoteSum = 0;
                Integer quoteQuantity = 0;

                for(CotacaoMoeda__c samePeriodQuote : quotesOfSamePeriodAndCurrencyGrouped.get(monthAndYear) ){
                    
                    if (samePeriodQuote.data__c <= currencyQuote.data__c){
                        quoteSum += samePeriodQuote.taxa__c;
                        ++quoteQuantity;

                    } else {
                        break;
                    }
                }
                CotacaoMoeda__c updatedCurrencyQuote = new CotacaoMoeda__c(
                    id = currencyQuote.id,
                    taxaMedia__c = quoteSum / quoteQuantity
                );
                quotesWithUpdatedAverage.add(updatedCurrencyQuote);
            }
        }

        CotacaoMoedaHelper.disableTrigger();
            update quotesWithUpdatedAverage;
        CotacaoMoedaHelper.enableTrigger();
    }

    private static String getCurrencyKey(CotacaoMoeda__c currencyQuote){
        return currencyQuote.moeda__c + '-' + getDatePeriod(currencyQuote.data__c);
    }

    private static String getDatePeriod(Date d){
        Datetime datetimeCasted = ((Datetime) d);
        
        Integer month = Integer.valueOf(datetimeCasted.formatGmt('MM'));
        Integer year = Integer.valueOf(datetimeCasted.formatGmt('yyyy'));

        return month + '-' + year; 
    }
}