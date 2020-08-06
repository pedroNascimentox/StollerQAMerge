global class BatchDeliveryNotification implements Database.Batchable<SObject>{
    
    String query;
    
    private BatchDeliveryNotification() {}

    public static void run(){
        Database.executeBatch(new BatchDeliveryNotification(), 2000);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        Date dateBase = getNotificationDate(Date.today());
        String data   = String.valueOf(dateBase);
        //Na query é realizado o filtro de dados onde só buscará a programação de entrega que esteja no Status X
        query = 'SELECT IdOpportunityLineItem__c, Produto__r.Id, Status__c, StatusSAP__c, Produto__r.Embalagem__c, ' +
                'Produto__r.Name, Produto__r.Sku__c, Litros__c, DataEntrega__c, NumeroPedidoCliente__c, PrecoLitro__c, ' +
                'QuantidadeProgramada__c, PrecoListaReferencia__c, PrecoVenda__c, PrecoVendaJuros__c, DescontoConcedido__c, ' +
                'Juros__c, Confirmado__c, RecebedorOrdem__c, Cultura__c, Territorio__c, IdOportunidade__r.StageName, ' +
                'Cultura__r.Id, Cultura__r.Name, RecebedorOrdem__r.Id, RecebedorOrdem__r.Name, RecebedorOrdem__r.CNPJ__c, ' +
                'RecebedorOrdem__r.ShippingCity, RecebedorOrdem__r.ShippingState, RecebedorOrdem__r.NomeFazenda__c, ' +
                'EmissorOrdem__r.Id, EmissorOrdem__r.Name, EmissorOrdem__r.CNPJ__c, EmissorOrdem__r.ShippingCity, ' +
                'EmissorOrdem__r.ShippingState, EmissorOrdem__r.NomeFazenda__c, IdOportunidade__r.Id, DataConfirmacao__c, ' +
                'IdOportunidade__r.NumeroOportunidade__c, TipoOrdem__c, DataFaturamento__c, Regional__r.Name, ' +
                'DiretorComercial__r.Name, NomeRTV__c, IdOportunidade__c, Produto__r.Multiplicidade__c, EnviarNotificacao__c ' +
                'FROM ProgramacaoEntrega__c WHERE DataFaturamento__c > ' +String.valueOf(Date.today())+' AND DataFaturamento__c <=' +data+ ' AND Confirmado__c = false';

        return Database.getQueryLocator(query);
    }    

    global void execute(Database.BatchableContext BC, List<ProgramacaoEntrega__c> scope){
        //No metodo execute será realizada o update do campo EnviarNotificacao__c caso esteja dentro dos critérios.
        List<ProgramacaoEntrega__c> listDeliveryToUpdate = new List<ProgramacaoEntrega__c>();
        
        system.debug('scope: '+ scope);

        List<Holiday> holidays = OpportunityAppController.getHolidays();

        List<Date> allHolidaysDates = new List<Date>();
        
        if(!holidays.isEmpty()){
            allHolidaysDates = Collection.of(holidays).pluckDates(Holiday.activityDate);
        }        
            
        Set<String> weekendDays = new Set<String>{'Saturday', 'Sunday'};

        if (!scope.isEmpty()){  
            for (ProgramacaoEntrega__c delivery: scope){
                Datetime today  = System.Now();

                if (!weekendDays.contains(OpportunityAppController.returnDayInWeek(today)) && !allHolidaysDates.contains(today.Date())){                
                    if (OpportunityAppController.isBusinessDay(today.Date())){
                        delivery.EnviarNotificacao__c = true;
                        listDeliveryToUpdate.add(delivery);
                    }
                }
            }
        }    
        if (!listDeliveryToUpdate.isEmpty()){
            update listDeliveryToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {}

    public static Date getNotificationDate(Date dateAux){
        Integer a = 0; 
        Date targetDate = dateAux;        

        Map<String, PrazoNotificacaoConfirmacaoEntrega__c> mapDescToDias = new Map<String, PrazoNotificacaoConfirmacaoEntrega__c>();
        mapDescToDias = PrazoNotificacaoConfirmacaoEntrega__c.getall();

        if (mapDescToDias.get('Dias') != null) {
            Integer dias = Integer.valueOf(mapDescToDias.get('Dias').dias__c);
            
            while(a < dias){
                System.debug('a => ' + a);
                System.debug('targetDate => ' + targetDate);

                targetDate = targetDate.addDays(1);

                System.debug('(targetDate - 1) => ' + targetDate);
                System.debug('new date is business day? ' + OpportunityAppController.isBusinessDay(targetDate));

                if (!OpportunityAppController.isBusinessDay(targetDate)){
                    continue;
                }

                a++;
                System.debug('a => ' + a);
            }
        }

        return targetDate;
    }
}