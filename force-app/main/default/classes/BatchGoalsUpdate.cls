global class BatchGoalsUpdate implements Database.Batchable<SObject>{
    string query;
    
    public BatchGoalsUpdate() {}

    public static void run(){
        Database.executeBatch(new BatchGoalsUpdate(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        //Na query é realizado o filtro de dados onde só buscará a Apuração que esteja com Status X
        query = 'SELECT Id, AnoFaturamento__c, CarteiraDolar__c, CarteiraLitros__c, CarteiraReais__c, Classificacao__c, CodigoAgrupamento__c, '+
                'CodigoCliente__c, CodigoProduto__c, CodigoTerritorio__c, DataFaturamento__c, Embalagem__c, FaturadoDolar__c, CriterioApuracao__c, '+
                'FaturadoLitros__c, FaturadoReais__c, ForecastDolar__c, ForecastLitros__c, ForecastReais__c, GerenteUnidadeNegocios__c, StatusItemPedido__c, '+
                'MesFaturamento__c, Meta__c, NomeConta__c, OrcamentoDolar__c, OrcamentoReais__c, PrevisaoDolar__c, PrevisaoLitros__c, '+
                'PrevisaoReais__c, Produto__c, ProdutoPedido__c, Territorio__c, Territorio__r.Regional__c, MetaFilial__c, CriterioCDA__c, VendidoLitros__c '+
                'FROM Apuracao__c WHERE Atualizado__c = false';

        return Database.getQueryLocator(query);
    } 

    global void execute(Database.BatchableContext BC, List<Apuracao__c> scope){   

        Boolean atualizar = false;

        List<NotaFiscalItem__c> nfItemList = new List<NotaFiscalItem__c>();
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
        // List<OrderItem> ordItemList = new List<OrderItem>();
        List<Escoamento__c> escoamentoList = new List<Escoamento__c>();
        // List<LancamentoContabil__c> lancamentoContabilList = new List<LancamentoContabil__c>();

        Map<String, List<Apuracao__c>> mapCritToApuracao                         = new Map<String, List<Apuracao__c>>();
        Map<String, Apuracao__c> mapCritCDAToApuracao                            = new Map<String, Apuracao__c>();

        Map<String, List<NotaFiscalItem__c>> mapCritToNfItemList                 = new Map<String, List<NotaFiscalItem__c>>();
        Map<String, List<ProgramacaoEntrega__c>> mapCritToDeliveryList           = new Map<String, List<ProgramacaoEntrega__c>>();
        // Map<String, List<OrderItem>> mapCritToOrderItemList                      = new Map<String, List<OrderItem>>();
        Map<String, List<Escoamento__c>> mapCritToEscoamentoList                 = new Map<String, List<Escoamento__c>>();
        Map<String, List<LancamentoContabil__c>> mapCritToLancamentoContabilList = new Map<String, List<LancamentoContabil__c>>();

        List<Apuracao__c> apuracaoList = new List<Apuracao__c>();

        // system.debug(scope);

        if (!scope.isEmpty()){
            for (Apuracao__c apuracao : scope){
                mapCritToApuracao.put(apuracao.CriterioApuracao__c, new List<Apuracao__c>{apuracao});
                mapCritCDAToApuracao.put(apuracao.CriterioCDA__c, apuracao);
                mapCritToDeliveryList.put(apuracao.CriterioApuracao__c, new List<ProgramacaoEntrega__c>());
            }
        }

        for (NotaFiscalItem__c nfItem : [SELECT Id, NotaFiscal__c, Notafiscal__r.CodigoCliente__c, NotaFiscal__r.TerritorioGerencial__c, NotaFiscal__r.Regional__c, CriterioApuracao__c,
                                         NotaFiscal__r.DataNF__c, NotaFiscal__r.TipoFat__c, CodigoMaterial__c, ValorUnitarioItem__c, ValorTotalUSD__c, Litros__c, Apuracao__c, ValorTotalItem__c 
                                         FROM NotaFiscalItem__c
                                         WHERE CriterioApuracao__c IN: mapCritToApuracao.keySet() AND NotaFiscal__r.TipoFat__c != 'ZBON' AND NotaFiscal__r.TipoFat__c != 'ZEXP' AND NotaFiscal__r.StatusCancelado__C = false]) { 
            if (!mapCritToNfItemList.containsKey(nfItem.CriterioApuracao__c)){
                mapCritToNfItemList.put(nfItem.CriterioApuracao__c, new List<NotaFiscalItem__c>{nfItem});
            }else{
                mapCritToNfItemList.get(nfItem.CriterioApuracao__c).add(nfItem);
            }
        }

        // system.debug(mapCritToNfItemList);

        List<ProgramacaoEntrega__c> programacoesEntregaToDisassociate = new List<ProgramacaoEntrega__c>();

        for (ProgramacaoEntrega__c delivery : [SELECT Id, 
                                                      Apuracao__c
                                               FROM ProgramacaoEntrega__c 
                                               WHERE CriterioApuracao__c IN: mapCritToApuracao.keySet() 
                                               AND Apuracao__c != null
                                               AND (Status__c = 'Cancelado'
                                               OR StatusGlobalItem__c = 'C'
                                               OR StatusSAP__c = 'Faturado'
                                               OR StatusSAP__c = 'Faturado Parcial')]) {
            delivery.Apuracao__c = null;
            programacoesEntregaToDisassociate.add(delivery);
        }

        ProgramacaoEntregaHelper.disableTrigger();
        update programacoesEntregaToDisassociate;
        ProgramacaoEntregaHelper.enableTrigger();

        //2020.05.08 - William Leite - Adicionado campo para valor à vista (Reais/Dólar)

        for (ProgramacaoEntrega__c delivery : [SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c, StatusGlobalItem__c, ValorTotalSemJurosReais__c, ValorTotalSemJurosDolar__c
                                               FROM ProgramacaoEntrega__c WHERE CriterioApuracao__c IN: mapCritToApuracao.keySet() AND Status__c != 'Cancelado' 
                                               //AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' AND TipoOrdem__c != 'Bonificação'
                                               AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' AND TipoOrdem__c NOT IN ('Bonificação', 'Devolução com NF Cliente', 'Devolução com Nossa NF')
                                               AND StatusGlobalItem__c != 'C' AND StatusSAP__c != 'Faturado' AND StatusSAP__c != 'Faturado Parcial']) {
            mapCritToDeliveryList.get(delivery.CriterioApuracao__c).add(delivery);
        }

        // system.debug(mapCritToDeliveryList);

        // for (OrderItem ordItem : [SELECT Id, Litros__c, ValorTotal__c, ValorTotalUSD__c, Apuracao__c, CriterioApuracao__c
                                //   FROM OrderItem WHERE CriterioApuracao__c IN: mapCritToApuracao.keySet()]){
            // if (!mapCritToOrderItemList.containsKey(ordItem.CriterioApuracao__c)){
                // mapCritToOrderItemList.put(ordItem.CriterioApuracao__c, new List<OrderItem>{ordItem});
            // }else{
                // mapCritToOrderItemList.get(ordItem.CriterioApuracao__c).add(ordItem);
        //     }
        // }

        for (Escoamento__c escoamento : [SELECT Id, ValorBrutoReais__c, ValorUnitarioUSD__c, QuantidadeLitros__c, CriterioApuracao__c
                                         FROM Escoamento__c WHERE CriterioApuracao__c IN: mapCritToApuracao.keySet()]){
            if (!mapCritToEscoamentoList.containsKey(escoamento.CriterioApuracao__c)){
                mapCritToEscoamentoList.put(escoamento.CriterioApuracao__c, new List<Escoamento__c>{escoamento});
            }else{
                mapCritToEscoamentoList.get(escoamento.CriterioApuracao__c).add(escoamento);
            }
        }

        for (LancamentoContabil__c lancamentoContabil : [SELECT Id, Moeda__c, CriterioCDA__c, Montante__c, MontanteInterno__c, MontanteInternoDolar__c 
                                                         FROM LancamentoContabil__c WHERE CriterioCDA__c IN: mapCritCDAToApuracao.keySet()]){
            if (!mapCritToLancamentoContabilList.containsKey(lancamentoContabil.CriterioCDA__c)){
                mapCritToLancamentoContabilList.put(lancamentoContabil.CriterioCDA__c, new List<LancamentoContabil__c>{lancamentoContabil});
            }else{
                mapCritToLancamentoContabilList.get(lancamentoContabil.CriterioCDA__c).add(lancamentoContabil);
            }
        }

        Map<String, Faturados> mapCritToFaturados = new Map<String, Faturados>();

        for (String Crit : mapCritToNfItemList.keySet()){
            Faturados fat = new Faturados();
            fat.somaFaturaReal  = 0; 
            fat.somaFaturaDolar = 0;
            fat.somaFaturaLitro = 0;

            for (NotaFiscalItem__c nfItem: mapCritToNfItemList.get(Crit)){
                fat.somaFaturaReal  += IntegrationUtils.checkDecimal(nfItem.ValorTotalItem__c);
                fat.somaFaturaDolar += IntegrationUtils.checkDecimal(nfItem.ValorTotalUSD__c);
                fat.somaFaturaLitro += IntegrationUtils.checkDecimal(nfItem.Litros__c);
            }            
            mapCritToFaturados.put(Crit, fat);
        }

        Map<String, CarteirasProgEntrega> mapCritToCartProgEntrega = new Map<String, CarteirasProgEntrega>();

        for (String Crit : mapCritToDeliveryList.keySet()){
            CarteirasProgEntrega cart = new CarteirasProgEntrega();
            cart.somaCarteiraReal  = 0; 
            cart.somaCarteiraDolar = 0;
            cart.somaCarteiraLitro = 0;

            if (!mapCritToDeliveryList.get(Crit).isEmpty()) {
                for (ProgramacaoEntrega__c delivery: mapCritToDeliveryList.get(Crit)){
                    if (delivery.StatusGlobalItem__c == 'C') {
                        cart.somaCarteiraReal  += IntegrationUtils.checkDecimal(delivery.SaldoSemJurosReais__c);
                        cart.somaCarteiraDolar += IntegrationUtils.checkDecimal(delivery.SaldoSemJurosDolar__c);
                        cart.somaCarteiraLitro += IntegrationUtils.checkDecimal(delivery.saldoLitros__c);
                    } else {
                        cart.somaCarteiraReal  += IntegrationUtils.checkDecimal(delivery.ValorTotalSemJurosReais__c);
                        cart.somaCarteiraDolar += IntegrationUtils.checkDecimal(delivery.ValorTotalSemJurosDolar__c);
                        cart.somaCarteiraLitro += IntegrationUtils.checkDecimal(delivery.Litros__c);
                    }
                }
            }
            mapCritToCartProgEntrega.put(Crit, cart);
        }

        // Map<String, CarteirasOrderItem> mapCritToCartOrderItem = new Map<String, CarteirasOrderItem>();

        // for (String Crit : mapCritToOrderItemList.keySet()){
            // CarteirasOrderItem cart = new CarteirasOrderItem();
            // cart.somaCarteiraReal  = 0; 
            // cart.somaCarteiraDolar = 0;
            // cart.somaCarteiraLitro = 0;

            // for (OrderItem ordItem: mapCritToOrderItemList.get(Crit)){
            //     cart.somaCarteiraReal  += ordItem.ValorTotal__c;
            //     cart.somaCarteiraDolar += ordItem.ValorTotalUSD__c;
            //     cart.somaCarteiraLitro += ordItem.Litros__c;
            // }
            // mapCritToCartOrderItem.put(Crit, cart);
        // }        

        Map<String, CarteirasEscoamento> mapCritToCartEscoamento = new Map<String, CarteirasEscoamento>();

        for (String Crit : mapCritToEscoamentoList.keySet()){
            CarteirasEscoamento cart = new CarteirasEscoamento();
            cart.somaValorBrutoReais  = 0;
            cart.somaValorUnitarioUSD = 0;
            cart.somaQuantidadeLitros = 0;

            for (Escoamento__c escoamento: mapCritToEscoamentoList.get(Crit)){
                cart.somaValorBrutoReais  += IntegrationUtils.checkDecimal(escoamento.ValorBrutoReais__c);
                cart.somaValorUnitarioUSD += IntegrationUtils.checkDecimal(escoamento.ValorUnitarioUSD__c);
                cart.somaQuantidadeLitros += IntegrationUtils.checkDecimal(escoamento.QuantidadeLitros__c);
            }
            mapCritToCartEscoamento.put(Crit, cart);
        }

        for (String Crit: mapCritToApuracao.keySet()){
            for (Apuracao__c apuracao : mapCritToApuracao.get(Crit)){
                if (mapCritToNfItemList.get(Crit) != null){
                    for(NotaFiscalItem__c nfItem : mapCritToNfItemList.get(Crit)) {
                        nfItem.Apuracao__c = apuracao.Id;

                        nfItemList.add(nfItem);
                    }
                }
                if (mapCritToDeliveryList.get(Crit) != null){
                    for(ProgramacaoEntrega__c delivery : mapCritToDeliveryList.get(Crit)){
                        delivery.Apuracao__c = apuracao.Id;

                        deliveryList.add(delivery);
                    }
                }
                // if (mapCritToOrderItemList.get(Crit) != null){
                    // for(OrderItem ordItem : mapCritToOrderItemList.get(Crit)){
                //         ordItem.Apuracao__c = apuracao.Id;

                //         ordItemList.add(ordItem);
                //     }
                // }                
                if (mapCritToEscoamentoList.get(Crit) != null){
                    for(Escoamento__c escoamento : mapCritToEscoamentoList.get(Crit)){
                        escoamento.Apuracao__c = apuracao.Id;

                        escoamentoList.add(escoamento);
                    }
                }
            }
        }

        // 16-06-2020 - Iago Richard
        List<NotaFiscalItem__c> itemNotaFiscal = [SELECT Id, Apuracao__c, NotaFiscal__r.TipoFat__c
                                                    FROM NotaFiscalItem__c
                                                    WHERE Apuracao__c IN : scope];

        Map<Id, List<String>> mapApNotaFiscal = new Map<Id, List<String>>();

        for(NotaFiscalItem__c inf : itemNotaFiscal){
            if(mapApNotaFiscal.containsKey(inf.Apuracao__c)){
                mapApNotaFiscal.get(inf.Apuracao__c).add(inf.NotaFiscal__r.TipoFat__c);
            }
            else{
                mapApNotaFiscal.put(inf.Apuracao__c, new List<String>{inf.NotaFiscal__r.TipoFat__c});
            }
        }

        TipoNotaFiscalCS__c customTipoNota = TipoNotaFiscalCS__c.getOrgDefaults();

        for (String Crit: mapCritToApuracao.keySet()){
            for (Apuracao__c apuracao: mapCritToApuracao.get(Crit)){                

                Faturados fat = mapCritToFaturados.get(Crit);
                CarteirasProgEntrega cartProgEntrega = mapCritToCartProgEntrega.get(Crit);
                // CarteirasOrderItem cartOrdItem = mapCritToCartOrderItem.get(Crit);
                CarteirasEscoamento cartEscoamento = mapCritToCartEscoamento.get(Crit);

                atualizar = (fat != null || cartProgEntrega != null || /*cartOrdItem != null ||*/ cartEscoamento != null);

                 if(mapApNotaFiscal.containsKey(apuracao.Id)){

                    for(String nf : mapApNotaFiscal.get(apuracao.Id)){

                        if (customTipoNota.Tipo__c.contains(nf)){
                            if (atualizar){
                                if (fat != null && cartEscoamento != null) {
                                    apuracao.FaturadoReais__c  = fat.somaFaturaReal + cartEscoamento.somaValorBrutoReais;
                                    apuracao.FaturadoDolar__c  = fat.somaFaturaDolar + cartEscoamento.somaValorUnitarioUSD;
                                    apuracao.FaturadoLitros__c = fat.somaFaturaLitro + cartEscoamento.somaQuantidadeLitros;
                                } else if (fat != null) {
                                    apuracao.FaturadoReais__c  = fat.somaFaturaReal;
                                    apuracao.FaturadoDolar__c  = fat.somaFaturaDolar;
                                    apuracao.FaturadoLitros__c = fat.somaFaturaLitro;
                                } else if (cartEscoamento != null) {
                                    apuracao.FaturadoReais__c  = cartEscoamento.somaValorBrutoReais;
                                    apuracao.FaturadoDolar__c  = cartEscoamento.somaValorUnitarioUSD;
                                    apuracao.FaturadoLitros__c = cartEscoamento.somaQuantidadeLitros;
                                } else {
                                    apuracao.FaturadoReais__c  = 0;
                                    apuracao.FaturadoDolar__c  = 0;
                                    apuracao.FaturadoLitros__c = 0;
                                }
                                // if (cartProgEntrega != null && cartOrdItem != null){
                                //     apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal  + cartOrdItem.somaCarteiraReal;
                                //     apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar + cartOrdItem.somaCarteiraDolar;
                                //     apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro + cartOrdItem.somaCarteiraLitro;                    
                                // }else{
                                    if (cartProgEntrega != null){
                                        apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal;
                                        apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar;
                                        apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro;                        
                                    }/*else if(cartOrdItem != null){
                                        apuracao.CarteiraReais__c  = cartOrdItem.somaCarteiraReal;
                                        apuracao.CarteiraDolar__c  = cartOrdItem.somaCarteiraDolar;
                                        apuracao.CarteiraLitros__c = cartOrdItem.somaCarteiraLitro;
                                    }*/
                                // }     
                            }else{
                                apuracao.FaturadoReais__c  = 0;
                                apuracao.FaturadoDolar__c  = 0;
                                apuracao.FaturadoLitros__c = 0;
                                apuracao.CarteiraReais__c  = 0;
                                apuracao.CarteiraDolar__c  = 0;
                                apuracao.CarteiraLitros__c = 0;
                            }
                            
                            apuracao.CarteiraReais__c  = (-1) * apuracao.CarteiraReais__c;
                            apuracao.CarteiraDolar__c  = (-1) * apuracao.CarteiraDolar__c;
                            apuracao.CarteiraLitros__c = (-1) * apuracao.CarteiraLitros__c;
                            apuracao.ForecastDolar__c  = (-1) * apuracao.ForecastDolar__c;
                            apuracao.ForecastLitros__c = (-1) * apuracao.ForecastLitros__c;
                            apuracao.ForecastReais__c  = (-1) * apuracao.ForecastReais__c;

                    
                        }
                        else {
                            if (atualizar){
                                if (fat != null && cartEscoamento != null) {
                                    apuracao.FaturadoReais__c  = fat.somaFaturaReal + cartEscoamento.somaValorBrutoReais;
                                    apuracao.FaturadoDolar__c  = fat.somaFaturaDolar + cartEscoamento.somaValorUnitarioUSD;
                                    apuracao.FaturadoLitros__c = fat.somaFaturaLitro + cartEscoamento.somaQuantidadeLitros;
                                } else if (fat != null) {
                                    apuracao.FaturadoReais__c  = fat.somaFaturaReal;
                                    apuracao.FaturadoDolar__c  = fat.somaFaturaDolar;
                                    apuracao.FaturadoLitros__c = fat.somaFaturaLitro;
                                } else if (cartEscoamento != null) {
                                    apuracao.FaturadoReais__c  = cartEscoamento.somaValorBrutoReais;
                                    apuracao.FaturadoDolar__c  = cartEscoamento.somaValorUnitarioUSD;
                                    apuracao.FaturadoLitros__c = cartEscoamento.somaQuantidadeLitros;
                                } else {
                                    apuracao.FaturadoReais__c  = 0;
                                    apuracao.FaturadoDolar__c  = 0;
                                    apuracao.FaturadoLitros__c = 0;
                                }
                                // if (cartProgEntrega != null && cartOrdItem != null){
                                //     apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal  + cartOrdItem.somaCarteiraReal;
                                //     apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar + cartOrdItem.somaCarteiraDolar;
                                //     apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro + cartOrdItem.somaCarteiraLitro;                    
                                // }else{
                                    if (cartProgEntrega != null){
                                        apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal;
                                        apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar;
                                        apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro;                        
                                    }/*else if(cartOrdItem != null){
                                        apuracao.CarteiraReais__c  = cartOrdItem.somaCarteiraReal;
                                        apuracao.CarteiraDolar__c  = cartOrdItem.somaCarteiraDolar;
                                        apuracao.CarteiraLitros__c = cartOrdItem.somaCarteiraLitro;
                                    }*/
                                // }     
                            }else{
                                apuracao.FaturadoReais__c  = 0;
                                apuracao.FaturadoDolar__c  = 0;
                                apuracao.FaturadoLitros__c = 0;
                                apuracao.CarteiraReais__c  = 0;
                                apuracao.CarteiraDolar__c  = 0;
                                apuracao.CarteiraLitros__c = 0;
                            }
                        }
                    }
                }
                
                if (atualizar){
                    if (fat != null && cartEscoamento != null) {
                        apuracao.FaturadoReais__c  = fat.somaFaturaReal + cartEscoamento.somaValorBrutoReais;
                        apuracao.FaturadoDolar__c  = fat.somaFaturaDolar + cartEscoamento.somaValorUnitarioUSD;
                        apuracao.FaturadoLitros__c = fat.somaFaturaLitro + cartEscoamento.somaQuantidadeLitros;
                    } else if (fat != null) {
                        apuracao.FaturadoReais__c  = fat.somaFaturaReal;
                        apuracao.FaturadoDolar__c  = fat.somaFaturaDolar;
                        apuracao.FaturadoLitros__c = fat.somaFaturaLitro;
                    } else if (cartEscoamento != null) {
                        apuracao.FaturadoReais__c  = cartEscoamento.somaValorBrutoReais;
                        apuracao.FaturadoDolar__c  = cartEscoamento.somaValorUnitarioUSD;
                        apuracao.FaturadoLitros__c = cartEscoamento.somaQuantidadeLitros;
                    } else {
                        apuracao.FaturadoReais__c  = 0;
                        apuracao.FaturadoDolar__c  = 0;
                        apuracao.FaturadoLitros__c = 0;
                    }
                    // if (cartProgEntrega != null && cartOrdItem != null){
                    //     apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal  + cartOrdItem.somaCarteiraReal;
                    //     apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar + cartOrdItem.somaCarteiraDolar;
                    //     apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro + cartOrdItem.somaCarteiraLitro;                    
                    // }else{
                        if (cartProgEntrega != null){
                            apuracao.CarteiraReais__c  = cartProgEntrega.somaCarteiraReal;
                            apuracao.CarteiraDolar__c  = cartProgEntrega.somaCarteiraDolar;
                            apuracao.CarteiraLitros__c = cartProgEntrega.somaCarteiraLitro;                        
                        }/*else if(cartOrdItem != null){
                            apuracao.CarteiraReais__c  = cartOrdItem.somaCarteiraReal;
                            apuracao.CarteiraDolar__c  = cartOrdItem.somaCarteiraDolar;
                            apuracao.CarteiraLitros__c = cartOrdItem.somaCarteiraLitro;
                        }*/
                    // }     
                }else{
                    apuracao.FaturadoReais__c  = 0;
                    apuracao.FaturadoDolar__c  = 0;
                    apuracao.FaturadoLitros__c = 0;
                    apuracao.CarteiraReais__c  = 0;
                    apuracao.CarteiraDolar__c  = 0;
                    apuracao.CarteiraLitros__c = 0;
                }        
                        
                apuracao.Atualizado__c = true;                    
                apuracaoList.add(apuracao);
            }
        }

        for (Apuracao__c apuracao : apuracaoList) {
            if (mapCritToLancamentoContabilList.containsKey(apuracao.CriterioCDA__c)) {
                // System.debug('apuracao => ' + JSON.serializePretty(apuracao));
                for (LancamentoContabil__c lancamentoContabil : mapCritToLancamentoContabilList.get(apuracao.CriterioCDA__c)) {
                    // System.debug('lancamentoContabil => ' + JSON.serializePretty(lancamentoContabil));
                    apuracao.FaturadoReais__c += IntegrationUtils.checkDecimal(lancamentoContabil.MontanteInterno__c);
                    apuracao.FaturadoDolar__c += IntegrationUtils.checkDecimal(lancamentoContabil.MontanteInternoDolar__c);
                    // lancamentoContabilList.add(lancamentoContabil);
                }
            }
        }

        // if (!lancamentoContabilList.isEmpty()) {
        //     LancamentoContabilHelper.disableTrigger();
        //     update lancamentoContabilList;
        //     LancamentoContabilHelper.enableTrigger();
        // }

        // system.debug(nfItemList);
        // system.debug(deliveryList);
        // system.debug(ordItemList);
        // system.debug(apuracaoList);

        if (!nfItemList.isEmpty()){
            update nfItemList;
        }
        if (!deliveryList.isEmpty()){
            update deliveryList;
        }
        // if (!ordItemList.isEmpty()){
        //     update ordItemList;
        // }
        if (!escoamentoList.isEmpty()) {
            update escoamentoList;
        }
        if (!apuracaoList.isEmpty()){
            update apuracaoList;
        }

        List<Apuracao__c> apuracaoPaiToUpdate = new List<Apuracao__c>();
        List<Meta__c> metaList = new List<Meta__c>();

        Set<Id> metaIdSet = new Set<Id>();
        Set<Id> metaFilialIdSet = new Set<Id>();

        Map<Id, Meta__c> mapIdToMeta = new Map<Id, Meta__c>();

        Map<Id, List<MetaFilial__c>> mapMetaIdToMetaFilialList = new Map<Id, List<MetaFilial__c>>();

        Map<Id, Apuracao__c> mapMetaIdToApuracaoPai = new Map<Id, Apuracao__c>();
        Map<Id, List<Apuracao__c>> mapMetaIdToApuracaoList = new Map<Id, List<Apuracao__c>>();

        for (Meta__c meta : [SELECT Id FROM Meta__c WHERE Atualizado__c = false]){
            mapIdToMeta.put(meta.Id, meta); 
        }

        // system.debug('mapIdToMeta: '+mapIdToMeta);

        for (MetaFilial__c metaFilial : [SELECT Id, MetaMatriz__c FROM MetaFilial__c WHERE MetaMatriz__c IN: mapIdToMeta.keySet()]){
            metaFilialIdSet.add(metaFilial.Id);
            if (!mapMetaIdToMetaFilialList.containsKey(metaFilial.MetaMatriz__c)){
                mapMetaIdToMetaFilialList.put(metaFilial.MetaMatriz__c, new List<MetaFilial__c>{metaFilial});
            }else{
                mapMetaIdToMetaFilialList.get(metaFilial.MetaMatriz__c).add(metaFilial);
            }
        }

        // for (Apuracao__c apuracao: [SELECT Id, FaturadoReais__c, FaturadoDolar__c, FaturadoLitros__c, CarteiraReais__c, CarteiraDolar__c, CarteiraLitros__c, Meta__c, MetaFilial__c, ApuracaoPai__c 
        //                             FROM Apuracao__c WHERE Meta__c IN : mapMetaIdToMetaFilialList.keySet()]){
        //     if (apuracao.ApuracaoPai__c){
        //         // system.debug('hmm pai');
        //         mapMetaIdToApuracaoPai.put(apuracao.Meta__c, apuracao);
        //     }else{
        //         // system.debug('hmm');
        //         if (!mapMetaIdToApuracaoList.containsKey(apuracao.Meta__c)){
        //             mapMetaIdToApuracaoList.put(apuracao.Meta__c, new List<Apuracao__c>{apuracao});
        //         }else{
        //             mapMetaIdToApuracaoList.get(apuracao.Meta__c).add(apuracao);
        //         }   
        //     }
        // }

        // system.debug('mapMetaIdToApuracaoPai: '+mapMetaIdToApuracaoPai);
        // system.debug('mapMetaIdToApuracaoList: '+mapMetaIdToApuracaoList);

        // for (Id metaId: mapMetaIdToApuracaoPai.KeySet()){            
        //     Apuracao__c apuracaoPai = mapMetaIdToApuracaoPai.get(metaId);
        //     if (mapMetaIdToApuracaoList.containsKey(metaId)){
        //         for (Apuracao__c apuracaoFilho: mapMetaIdToApuracaoList.get(metaId)){
        //             // system.debug(apuracaoFilho);
        //             if (apuracaoFilho != null){
        //                 apuracaoPai.FaturadoReais__c  += apuracaoFilho.FaturadoReais__c  == null ? 0 : apuracaoFilho.FaturadoReais__c;
        //                 apuracaoPai.FaturadoDolar__c  += apuracaoFilho.FaturadoDolar__c  == null ? 0 : apuracaoFilho.FaturadoDolar__c;
        //                 apuracaoPai.FaturadoLitros__c += apuracaoFilho.FaturadoLitros__c == null ? 0 : apuracaoFilho.FaturadoLitros__c;
        //                 apuracaoPai.CarteiraReais__c  += apuracaoFilho.CarteiraReais__c  == null ? 0 : apuracaoFilho.CarteiraReais__c;
        //                 apuracaoPai.CarteiraDolar__c  += apuracaoFilho.CarteiraDolar__c  == null ? 0 : apuracaoFilho.CarteiraDolar__c;
        //                 apuracaoPai.CarteiraLitros__c += apuracaoFilho.CarteiraLitros__c == null ? 0 : apuracaoFilho.CarteiraLitros__c;
        //             }
        //         }
        //         apuracaoPaiToUpdate.add(apuracaoPai);
        //     }
        // }
        
        for (Id metaId : mapIdToMeta.keySet()){
            Meta__c meta = mapIdToMeta.get(metaId);
            meta.Atualizado__c = true;
            metaList.add(meta);
        }

        if (!metaList.isEmpty()){
            GoalsHelper.disableTrigger();
            update metaList;
            GoalsHelper.enableTrigger();
        }        

        // if (!apuracaoPaiToUpdate.isEmpty()){
        //     update apuracaoPaiToUpdate;
        // }
                    
    }

    global void finish(Database.BatchableContext BC) {}

    public class Faturados{
        public Decimal somaFaturaReal;
        public Decimal somaFaturaDolar;
        public Decimal somaFaturaLitro;
    }

    public class CarteirasProgEntrega{
        public Decimal somaCarteiraReal;
        public Decimal somaCarteiraDolar;
        public Decimal somaCarteiraLitro;
    }

    // public class CarteirasOrderItem{
    //     public Decimal somaCarteiraReal;
    //     public Decimal somaCarteiraDolar;
    //     public Decimal somaCarteiraLitro;
    // }

    public class CarteirasEscoamento {
        public Decimal somaValorBrutoReais;
        public Decimal somaValorUnitarioUSD;
        public Decimal somaQuantidadeLitros;
    }
}