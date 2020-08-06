public class ClientesPlanoIncentivoHelper extends TriggerContext{
    public static void checkBeforeInsert(ClientesPlanoIncentivos__c[] clientesList) {
        Set<Id> cliExistentes = new Set<Id>();
        Set<Id> cliFamExistentes = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();

        Map<Id, ClientesPlanoIncentivos__c> mapIdToPlanoIncentivo = new Map<Id, ClientesPlanoIncentivos__c>();

        Boolean cliRepetido = false;
        Boolean registroBloqueado = false;

        for (ClientesPlanoIncentivos__c cli : clientesList){
            mapIdToPlanoIncentivo.put(cli.PlanoIncentivo__c, cli);
        }

        for (ClienteFamilia__c cliFam : [SELECT id, ClienteFamlia__c, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__r.Status__c, FamiliaClientes__r.PlanoIncentivo__c FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: mapIdToPlanoIncentivo.keySet()]){
            if (mapIdToPlanoIncentivo.containsKey(cliFam.FamiliaClientes__r.PlanoIncentivo__c)){
                if (cliFam.ClienteFamlia__c == mapIdToPlanoIncentivo.get(cliFam.FamiliaClientes__r.PlanoIncentivo__c).NomeCliente__c){
                    cliRepetido = true;
                    cliFamExistentes.add(cliFam.ClienteFamlia__c);
                } 
            }
        }

        for (ClientesPlanoIncentivos__c cli : [SELECT id, NomeCliente__c, PlanoIncentivo__c, PlanoIncentivo__r.Status__c FROM ClientesPlanoIncentivos__c WHERE PlanoIncentivo__c IN: mapIdToPlanoIncentivo.keySet()]){
            if (mapIdToPlanoIncentivo.containsKey(cli.PlanoIncentivo__c)){
                if (cli.PlanoIncentivo__r.Status__c == 'Em apuração' || cli.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(cli.PlanoIncentivo__c);
                }
                if (cli.NomeCliente__c == mapIdToPlanoIncentivo.get(cli.PlanoIncentivo__c).NomeCliente__c){
                    cliRepetido = true;
                    cliExistentes.add(cli.NomeCliente__c);
                } 
            }
        }

        for (ClientesPlanoIncentivos__c cli : clientesList){
            if (registroBloqueado && planoIncentivoSet.contains(cli.PlanoIncentivo__c)){
                cli.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');     
            }
            if (cliRepetido && (cliExistentes.contains(cli.NomeCliente__c) || cliFamExistentes.contains(cli.NomeCliente__c))){
                cli.addError('Cliente ja existente no Plano de Incentivo.');           
            }            
        }        
    }

    public static void checkBeforeDelete(ClientesPlanoIncentivos__c[] clientesList){
        Boolean registroBloqueado = false;        
        Set<Id> planoIncentivoSet = new Set<Id>();
        Map<Id, ClientesPlanoIncentivos__c> mapIdToPlanoIncentivo = new Map<Id, ClientesPlanoIncentivos__c>();

        for (ClientesPlanoIncentivos__c cli : clientesList){
            mapIdToPlanoIncentivo.put(cli.id, cli);
        }

        for (ClientesPlanoIncentivos__c cli : [SELECT id, NomeCliente__c, PlanoIncentivo__c, PlanoIncentivo__r.Status__c FROM ClientesPlanoIncentivos__c WHERE id IN: mapIdToPlanoIncentivo.keySet()]){
            // system.debug(cli);
            if (mapIdToPlanoIncentivo.containsKey(cli.id)){
                if (cli.PlanoIncentivo__r.Status__c == 'Em apuração' || cli.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(cli.id);
                }
            }
        }

        for (ClientesPlanoIncentivos__c cli : clientesList){
            if (registroBloqueado && planoIncentivoSet.contains(cli.id)){
                cli.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');     
            }
        }
    }

    public static void calcAfterInsert(ClientesPlanoIncentivos__c[] clientesList){
        List<ClientesPlanoIncentivos__c> cliPlanoIncentivoList = new List<ClientesPlanoIncentivos__c>();
        List<OrderItem> ordItemList = new List<OrderItem>();
        List<NotaFiscal__c> notaFiscalList = new List<NotaFiscal__c>();
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();
        List<NotaFiscalItem__c> notaFsicalItemList = new List<NotaFiscalItem__c>();

        decimal faturadoAnual;
        decimal faturadoGlobal;
        decimal totalLiquido;
        decimal totalLitros;
        decimal carteira;

        Set<Id> ordIdSet = new Set<Id>();
        Set<Id> deliveryIdSet = new Set<Id>();
        Set<Id> notaFiscalSet = new Set<Id>();
        Set<Id> planIncentivoIdSet = new Set<Id>();

        Map<Id, Id> mapIdNfToIdCliPIncentivo = new Map<Id, Id>();
        
        Map<Id, ClientesPlanoIncentivos__c> mapIdCliToCliPIncentivo = new Map<Id, ClientesPlanoIncentivos__c>();
        Map<Id, ClientesPlanoIncentivos__c> mapIdCliToUpdateCliPI = new Map<Id, ClientesPlanoIncentivos__c>();
        
        Map<Id, List<OrderItem>> mapIdToOrderItemList = new Map<Id, List<OrderItem>>();
        Map<Id, List<ProgramacaoEntrega__c>> mapIdToDeliveryList = new Map<Id, List<ProgramacaoEntrega__c>>();
        Map<Id, List<NotaFiscal__c>> mapIdNotaFiscalList = new Map<Id, List<NotaFiscal__c>>();

        Integer year;
        Date data = System.Today();

        if (data.Month() >= 4){
            year = data.Year();
        }else{
            year = data.Year() - 1;
        }

        Date dataInicio = Date.newInstance(year, 4, 1);
        Date dataFimAnual = Date.newInstance(year, 12, 31);
        Date dataFimGlobal = Date.newInstance(year + 1, 3, 31);

        // system.debug('Meta Anual: '+dataInicio + ' até ' + dataFimAnual);
        // system.debug('Meta Global: '+dataInicio + ' até ' + dataFimGlobal);
        
        for (ClientesPlanoIncentivos__c cli : clientesList){
            mapIdCliToCliPIncentivo.put(cli.NomeCliente__c, cli);
            planIncentivoIdSet.add(cli.PlanoIncentivo__c);
        }

        for (Order ord: [SELECT Id FROM Order WHERE ClienteEmissor__c IN: mapIdCliToCliPIncentivo.keySet()]){
            ordIdSet.add(ord.Id);
        }

        for (NotaFiscal__c nf : [SELECT Id, NrOrdem__c, RemoverPlanoIncentivo__c, CodigoCliente__c, DataNF__c, ValorTotalNota__c, ValorTotalNotaUSD__c, ValorTotalNotaLiquido__c, ValorTotalLitros__c FROM NotaFiscal__c WHERE NrOrdem__c IN: ordIdSet AND RemoverPlanoIncentivo__c = false AND DataNF__c >=: dataInicio AND DataNF__c <=: dataFimGlobal]){
            if (!mapIdNotaFiscalList.containsKey(nf.CodigoCliente__c)){
                mapIdNotaFiscalList.put(nf.CodigoCliente__c, new List<NotaFiscal__c>{nf});
            }else{
                mapIdNotaFiscalList.get(nf.CodigoCliente__c).add(nf);
            }

            if (mapIdCliToCliPIncentivo.containsKey(nf.CodigoCliente__c)){
                nf.ClientePlanoIncentivo__c = mapIdCliToCliPIncentivo.get(nf.CodigoCliente__c).Id;
                notaFiscalList.add(nf);
                
                mapIdNfToIdCliPIncentivo.put(nf.Id, mapIdCliToCliPIncentivo.get(nf.CodigoCliente__c).Id);
            }
            
        }

        for (OrderItem ordItem : [SELECT Id, ProgramacaoEntrega__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, Apuracao__c, CriterioApuracao__c, Order.ClienteEmissor__c FROM OrderItem WHERE OrderId IN: ordIdSet]){
            deliveryIdSet.add(ordItem.ProgramacaoEntrega__c);
            if (!mapIdToOrderItemList.containsKey(ordItem.Order.ClienteEmissor__c)){
                mapIdToOrderItemList.put(ordItem.Order.ClienteEmissor__c, new List<OrderItem>{ordItem});
            }else { 
                mapIdToOrderItemList.get(ordItem.Order.ClienteEmissor__c).add(ordItem);
            }

            if (mapIdCliToCliPIncentivo.containsKey(ordItem.Order.ClienteEmissor__c)){
                ordItem.ClientePlanoIncentivo__c = mapIdCliToCliPIncentivo.get(ordItem.Order.ClienteEmissor__c).Id;
                ordItemList.add(ordItem);
            }
        }

        for (ProgramacaoEntrega__c delivery : [SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c, EmissorOrdem__c FROM ProgramacaoEntrega__c WHERE Id IN: deliveryIdSet
                                               AND Status__c != 'Cancelado' AND StatusGlobalItem__c != 'Faturado completamente'//AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' AND TipoOrdem__c != 'Bonificação'
                                               ]){
            if (!mapIdToDeliveryList.containsKey(delivery.EmissorOrdem__c)){
                mapIdToDeliveryList.put(delivery.EmissorOrdem__c, new List<ProgramacaoEntrega__c>{delivery});
            }else { 
                mapIdToDeliveryList.get(delivery.EmissorOrdem__c).add(delivery);
            }
            if (mapIdCliToCliPIncentivo.containsKey(delivery.EmissorOrdem__c)){
                delivery.ClientePlanoIncentivo__c = mapIdCliToCliPIncentivo.get(delivery.EmissorOrdem__c).Id;
                deliveryList.add(delivery);
            }
        }

        Set<Id> prodIdSet = new Set<Id>();        

        List<ProdutosClientes__c> prodClientesList = new List<ProdutosClientes__c>();

        for (NotaFiscalItem__c nfItem : [SELECT Id, NotaFiscal__c, CodigoMaterial__c FROM NotaFiscalItem__c WHERE NotaFiscal__c IN: mapIdNfToIdCliPIncentivo.keySet() 
                                         AND NotaFiscal__r.NrOrdem__c IN: ordIdSet AND NotaFiscal__r.RemoverPlanoIncentivo__c = false AND NotaFiscal__r.DataNF__c >=: dataInicio 
                                         AND NotaFiscal__r.DataNF__c <=: dataFimGlobal AND NotaFiscal__r.TipoFat__c != 'ZBON' AND NotaFiscal__r.TipoFat__c != 'ZEXP']){
            // system.debug('chinelo: '+ nfItem);
            prodIdSet.add(nfItem.CodigoMaterial__c);

            ProdutosClientes__c prodCli = new ProdutosClientes__c();
            prodCli.Relativo__c        = mapIdNfToIdCliPIncentivo.get(nfItem.NotaFiscal__c);
            prodCli.NomeProduto__c     = nfItem.CodigoMaterial__c;
            prodCli.IdNotaFicalItem__c = nfItem.Id;

            prodClientesList.add(prodCli);
        }

        Map<Id, String> mapIdProdToFamilyProd = new Map<Id, String>();

        Set<String> prodFamilySet = new Set<String>();

        for (Product2 prod : [SELECT Id, Family FROM Product2 WHERE Id IN: prodIdSet]){
            if (prod.Family != null){
                prodFamilySet.add(prod.Family);
            }
        }

        for (ProdutoFoco__c prodFoco: [SELECT Id, ProdutoFoco__c, FamiliaProdutos__c, PlanoIncentivo__c FROM ProdutoFoco__c WHERE PlanoIncentivo__c IN : planIncentivoIdSet]){            
            for (ProdutosClientes__c prodCli: prodClientesList){
                // system.debug(prodIdSet);
                // system.debug(prodFamilySet);
                if (prodIdSet.contains(prodFoco.ProdutoFoco__c)){
                    prodCli.ProdutoFoco__c = true;
                } else if (prodFamilySet.contains(prodFoco.FamiliaProdutos__c)){
                    prodCli.ProdutoFoco__c = true;
                }
            }
        }


        for (ClientesPlanoIncentivos__c cliPlanIncentivo : [SELECT Id, NomeCliente__c, Moeda__c, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, Carteira__c FROM ClientesPlanoIncentivos__c WHERE NomeCliente__c IN: mapIdCliToCliPIncentivo.keySet()]){
            mapIdCliToUpdateCliPI.put(cliPlanIncentivo.NomeCliente__c, CliPlanIncentivo);
        }

        for (Id cliId: mapIdCliToCliPIncentivo.keySet()){
            faturadoAnual  = 0;
            faturadoGlobal = 0;
            totalLiquido   = 0;
            totalLitros    = 0;
            carteira       = 0;
            if (mapIdNotaFiscalList.containsKey(cliId)){
                for (NotaFiscal__c nf: mapIdNotaFiscalList.get(cliId)){
                    totalLiquido += nf.ValorTotalNotaLiquido__c;
                    totalLitros += nf.ValorTotalLitros__c;
                    if (mapIdCliToUpdateCliPI.get(cliId).Moeda__c == 'Real'){
                        if (nf.ValorTotalNota__c != null){
                            if (nf.DataNF__c <= dataFimAnual){
                                faturadoAnual  += nf.ValorTotalNota__c;  
                                faturadoGlobal += nf.ValorTotalNota__c;
                            }else{
                                faturadoGlobal += nf.ValorTotalNota__c;
                            }
                        }
                    }else{
                        if (nf.ValorTotalNotaUSD__c != null){
                            if (nf.DataNF__c <= dataFimAnual){                                
                                faturadoAnual  += nf.ValorTotalNotaUSD__c;  
                                faturadoGlobal += nf.ValorTotalNotaUSD__c;
                            }else{
                                faturadoGlobal += nf.ValorTotalNotaUSD__c;
                            }
                        }
                    }
                }
            }
            if (mapIdToDeliveryList.containsKey(cliId)){
                for (ProgramacaoEntrega__c delivery: mapIdToDeliveryList.get(cliId)){
                    if (mapIdCliToUpdateCliPI.get(cliId).Moeda__c == 'Real'){
                        if (delivery.ValorTotal__c != null){
                            carteira += delivery.ValorTotal__c;
                        }
                    }else{
                        if (delivery.ValorTotalUSD__c != null){
                            carteira += delivery.ValorTotalUSD__c;
                        }
                    }
                }
            }
            if (mapIdToOrderItemList.containsKey(cliId)){
                for (OrderItem ordItem : mapIdToOrderItemList.get(cliId)){
                     if (mapIdCliToUpdateCliPI.get(cliId).Moeda__c == 'Real'){
                        if (ordItem.ValorTotal__c != null){
                            carteira += ordItem.ValorTotal__c;
                        }
                    }else{
                        if (ordItem.ValorTotalUSD__c != null){
                            carteira += ordItem.ValorTotalUSD__c;
                        }
                    }                    
                }
            }

            // system.debug(faturadoAnual);
            // system.debug(faturadoGlobal);
            // system.debug(carteira);
            // system.debug(mapIdCliToUpdateCliPI);
            // system.debug('HMM...');

            if (mapIdCliToUpdateCliPI.containsKey(cliId)){
                // system.debug('Entrou!');
                ClientesPlanoIncentivos__c cliPlanoIncentivo = mapIdCliToUpdateCliPI.get(cliId);  
                cliPlanoIncentivo.ValorFaturamentoAnual__c     = faturadoAnual;
                cliPlanoIncentivo.ValorFaturamentoGlobal__c    = faturadoGlobal;
                cliPlanoIncentivo.FaturamentoGlobalLiquido__c  = totalLiquido;
                cliPlanoIncentivo.ValorFaturadoLitrosGlobal__c = totalLitros;
                cliPlanoIncentivo.Carteira__c                  = carteira;                    
                cliPlanoIncentivoList.add(cliPlanoIncentivo);
            }
        }

        // system.debug('cliPlanoIncentivoList: '+ cliPlanoIncentivoList);
        // system.debug('notaFiscalList: '+ notaFiscalList);
        // system.debug('deliveryList: '+ deliveryList);
        // system.debug('ordItemList: '+ ordItemList);
        // system.debug('prodClientesList' + prodClientesList);

        if (!notaFiscalList.isEmpty()){
            NotaFiscalHelper.disableTrigger();
            update notaFiscalList;
            NotaFiscalHelper.enableTrigger();
        }

        if (!deliveryList.isEmpty()){
            ProgramacaoEntregaHelper.disableTrigger();
            update deliveryList;
            ProgramacaoEntregaHelper.enableTrigger();
        }

        if (!ordItemList.isEmpty()){
            OrderItemHelper.disableTrigger();
            update ordItemList;
            OrderItemHelper.enableTrigger();
        }

        if (!cliPlanoIncentivoList.isEmpty()){
            update cliPlanoIncentivoList;
        }

        if (!prodClientesList.isEmpty()){
            insert prodClientesList;
        }
    }
}