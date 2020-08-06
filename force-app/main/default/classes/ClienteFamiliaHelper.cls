public class ClienteFamiliaHelper extends TriggerContext{
    public static void checkBeforeInsert(ClienteFamilia__c[] clientesList) {
        Set<Id> cliExistentes = new Set<Id>();
        Set<Id> planIncentivoSet = new Set<Id>();
        Set<Id> familiaCliSet = new Set<Id>();        
        Set<Id> cliPlanExistentes = new Set<Id>();
        Set<Id> planoIncentivoSet = new Set<Id>();

        Map<Id, Id> mapIdFamToIdPlan = new Map<Id, Id>();
        Map<Id, ClienteFamilia__c> mapIdToPlanoIncentivo = new Map<Id, ClienteFamilia__c>();
        Map<Id, ClienteFamilia__c> mapIdToClienteFamilia = new Map<Id, ClienteFamilia__c>();
        Boolean cliRepetido = false;
        Boolean registroBloqueado = false;

        for (ClienteFamilia__c cli : clientesList){
            familiaCliSet.add(cli.FamiliaClientes__c);
        }

        for (FamiliaClientes__c famCli : [SELECT Id, PlanoIncentivo__c FROM FamiliaClientes__c WHERE Id IN: familiaCliSet]){
            mapIdFamToIdPlan.put(famCli.Id, famCli.PlanoIncentivo__c);
            planIncentivoSet.add(famCli.PlanoIncentivo__c);
        }

        for (ClienteFamilia__c cli : clientesList){        
            mapIdToPlanoIncentivo.put(mapIdFamToIdPlan.get(cli.FamiliaClientes__c), cli);
        }       

        for (ClienteFamilia__c cli : [SELECT id, ClienteFamlia__c, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__r.Status__c, FamiliaClientes__r.PlanoIncentivo__c FROM ClienteFamilia__c WHERE FamiliaClientes__r.PlanoIncentivo__c IN: planIncentivoSet]){
            // system.debug(cli);
            if (mapIdToPlanoIncentivo.containsKey(cli.FamiliaClientes__r.PlanoIncentivo__c)){
                // system.debug('cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c: '+ cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c);
                if (cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c == 'Em apuração' || cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(cli.FamiliaClientes__r.PlanoIncentivo__c);
                }
                if (cli.ClienteFamlia__c == mapIdToPlanoIncentivo.get(cli.FamiliaClientes__r.PlanoIncentivo__c).ClienteFamlia__c){
                    cliRepetido = true;
                    cliExistentes.add(cli.ClienteFamlia__c);
                } 
            }
        }

        for (ClientesPlanoIncentivos__c cli : [SELECT id, NomeCliente__c, PlanoIncentivo__c, PlanoIncentivo__r.Status__c FROM ClientesPlanoIncentivos__c WHERE PlanoIncentivo__c IN: planIncentivoSet]){
            // system.debug(cli);
            if (mapIdToPlanoIncentivo.containsKey(cli.PlanoIncentivo__c)){
                if (cli.NomeCliente__c == mapIdToPlanoIncentivo.get(cli.PlanoIncentivo__c).ClienteFamlia__c){
                    cliRepetido = true;
                    cliPlanExistentes.add(cli.NomeCliente__c);
                } 
            }
        }

        for (ClienteFamilia__c cli : clientesList){
            if (registroBloqueado && planoIncentivoSet.contains(mapIdFamToIdPlan.get(cli.FamiliaClientes__c))){
                cli.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');     
            }
            if (cliRepetido && (cliExistentes.contains(cli.ClienteFamlia__c) || cliPlanExistentes.contains(cli.ClienteFamlia__c))){
                cli.addError('Cliente ja existente no Plano de Incentivo.');           
            }      
        }        
    }

    public static void checkBeforeDelete(ClienteFamilia__c[] clientesList){
        Boolean registroBloqueado = false;        
        Set<Id> planoIncentivoSet = new Set<Id>();
        Map<Id, ClienteFamilia__c> mapIdToClienteFamilia = new Map<Id, ClienteFamilia__c>();

        for (ClienteFamilia__c cli : clientesList){
            mapIdToClienteFamilia.put(cli.id, cli);
        }

        for (ClienteFamilia__c cli : [SELECT id, ClienteFamlia__c, FamiliaClientes__c, FamiliaClientes__r.PlanoIncentivo__r.Status__c FROM ClienteFamilia__c WHERE id IN: mapIdToClienteFamilia.keySet()]){
            if (mapIdToClienteFamilia.containsKey(cli.id)){
                if (cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c == 'Em apuração' || cli.FamiliaClientes__r.PlanoIncentivo__r.Status__c == 'Encerrado'){
                    registroBloqueado = true;
                    planoIncentivoSet.add(cli.id);
                }
            }
        }

        for (ClienteFamilia__c cli : clientesList){
            if (registroBloqueado && planoIncentivoSet.contains(cli.id)){
                cli.addError('Plano de Incentivo relacionado está "Em apuração" ou "Encerrado". Não é possível realizar alteração.');     
            }
        }
    }

    public static void calcAfterInsert(ClienteFamilia__c[] clientesList){
        List<ClienteFamilia__c> cliFamiliaList = new List<ClienteFamilia__c>();
        List<OrderItem> ordItemList = new List<OrderItem>();
        List<NotaFiscal__c> notaFiscalList = new List<NotaFiscal__c>();
        List<ProgramacaoEntrega__c> deliveryList = new List<ProgramacaoEntrega__c>();

        decimal faturadoAnual;
        decimal faturadoGlobal;
        decimal totalLiquido;
        decimal totalLitros;
        decimal carteira;

        Set<Id> ordIdSet = new Set<Id>();
        Set<Id> famClientes = new Set<Id>();
        Set<Id> deliveryIdSet = new Set<Id>();
        Set<Id> familiaCliSet = new Set<Id>();
        
        Map<Id, Id> mapIdFamToIdPlan = new Map<Id, Id>();
        
        Map<Id, ClienteFamilia__c> mapIdCliToCliFamilia = new Map<Id, ClienteFamilia__c>();
        Map<Id, ClienteFamilia__c> mapIdCliToUpdateCliF = new Map<Id, ClienteFamilia__c>();
        
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

        for (ClienteFamilia__c cli : clientesList){
            mapIdCliToCliFamilia.put(cli.ClienteFamlia__c, cli);
            familiaCliSet.add(cli.FamiliaClientes__c);
        }
        
        for (FamiliaClientes__c famCli : [SELECT Id, PlanoIncentivo__c FROM FamiliaClientes__c WHERE Id IN: familiaCliSet]){
            mapIdFamToIdPlan.put(famCli.Id, famCli.PlanoIncentivo__c);
        }   

        for (Order ord: [SELECT Id FROM Order WHERE ClienteEmissor__c IN: mapIdCliToCliFamilia.keySet()]){
            ordIdSet.add(ord.Id);
        }

        List<Id> notaFiscalIdList = new List<Id>();
        Map<Id, Id> mapIdNfToIdCliPIncentivo = new Map<Id, Id>();

        for (NotaFiscal__c nf : [SELECT Id, NrOrdem__c, RemoverPlanoIncentivo__c, CodigoCliente__c, DataNF__c, ValorTotalNota__c, ValorTotalNotaUSD__c, ValorTotalNotaLiquido__c, ValorTotalLitros__c FROM NotaFiscal__c WHERE NrOrdem__c IN: ordIdSet AND RemoverPlanoIncentivo__c = false AND DataNF__c >=: dataInicio AND DataNF__c <=: dataFimGlobal]){
            if (!mapIdNotaFiscalList.containsKey(nf.CodigoCliente__c)){
                mapIdNotaFiscalList.put(nf.CodigoCliente__c, new List<NotaFiscal__c>{nf});
            }else{
                mapIdNotaFiscalList.get(nf.CodigoCliente__c).add(nf);
            }
            notaFiscalIdList.add(nf.Id);

            if (mapIdCliToCliFamilia.containsKey(nf.CodigoCliente__c)){
                nf.ClienteFamilia__c = mapIdCliToCliFamilia.get(nf.CodigoCliente__c).Id;
                notaFiscalList.add(nf);

                mapIdNfToIdCliPIncentivo.put(nf.Id, mapIdCliToCliFamilia.get(nf.CodigoCliente__c).Id);
            }
        }

        Set<Id> prodIdSet = new Set<Id>();        

        List<ProdutosClientesFamilia__c> prodClientesList = new List<ProdutosClientesFamilia__c>();

        for (NotaFiscalItem__c nfItem : [SELECT Id, NotaFiscal__c, CodigoMaterial__c FROM NotaFiscalItem__c WHERE NotaFiscal__c IN: mapIdNfToIdCliPIncentivo.keySet() AND NotaFiscal__r.NrOrdem__c IN: ordIdSet AND NotaFiscal__r.RemoverPlanoIncentivo__c = false AND NotaFiscal__r.DataNF__c >=: dataInicio AND NotaFiscal__r.DataNF__c <=: dataFimGlobal]){
            // system.debug('chinelo: '+ nfItem);
            prodIdSet.add(nfItem.CodigoMaterial__c);

            ProdutosClientesFamilia__c prodCli = new ProdutosClientesFamilia__c();
            prodCli.Relativo__c         = mapIdNfToIdCliPIncentivo.get(nfItem.NotaFiscal__c);
            prodCli.NomeProduto__c      = nfItem.CodigoMaterial__c;
            prodCli.IdNotaFiscalItem__c = nfItem.Id;

            prodClientesList.add(prodCli);
        }
        
        Map<Id, String> mapIdProdToFamilyProd = new Map<Id, String>();

        Set<String> prodFamilySet = new Set<String>();

        for (Product2 prod : [SELECT Id, Family FROM Product2 WHERE Id IN: prodIdSet]){
            if (prod.Family != null){
                prodFamilySet.add(prod.Family);
            }
        }

        for (ProdutoFoco__c prodFoco: [SELECT Id, ProdutoFoco__c, FamiliaProdutos__c, PlanoIncentivo__c FROM ProdutoFoco__c WHERE PlanoIncentivo__c IN : mapIdFamToIdPlan.values()]){            
            for (ProdutosClientesFamilia__c prodCli: prodClientesList){
                // system.debug(prodIdSet);
                // system.debug(prodFamilySet);
                if (prodIdSet.contains(prodFoco.ProdutoFoco__c)){
                    prodCli.ProdutoFoco__c = true;
                } else if (prodFamilySet.contains(prodFoco.FamiliaProdutos__c)){
                    prodCli.ProdutoFoco__c = true;
                }
            }
        }

        for (OrderItem ordItem : [SELECT Id, ProgramacaoEntrega__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, Apuracao__c, CriterioApuracao__c, Order.ClienteEmissor__c FROM OrderItem WHERE OrderId IN: ordIdSet]){
            deliveryIdSet.add(ordItem.ProgramacaoEntrega__c);
            if (!mapIdToOrderItemList.containsKey(ordItem.Order.ClienteEmissor__c)){
                mapIdToOrderItemList.put(ordItem.Order.ClienteEmissor__c, new List<OrderItem>{ordItem});
            }else { 
                mapIdToOrderItemList.get(ordItem.Order.ClienteEmissor__c).add(ordItem);
            }

            if (mapIdCliToCliFamilia.containsKey(ordItem.Order.ClienteEmissor__c)){
                ordItem.ClienteFamilia__c = mapIdCliToCliFamilia.get(ordItem.Order.ClienteEmissor__c).Id;
                ordItemList.add(ordItem);
            }
        }

        for (ProgramacaoEntrega__c delivery : [SELECT Id, Apuracao__c, Litros__c, ValorTotal__c, ValorTotalUSD__c, CriterioApuracao__c, EmissorOrdem__c FROM ProgramacaoEntrega__c WHERE Id IN: deliveryIdSet
                                               AND Status__c != 'Cancelado' AND Status__c != 'Solicitado Cancelamento' AND StatusSAP__c != 'Bloqueado Crédito' AND TipoOrdem__c != 'Bonificação']){
            if (!mapIdToDeliveryList.containsKey(delivery.EmissorOrdem__c)){
                mapIdToDeliveryList.put(delivery.EmissorOrdem__c, new List<ProgramacaoEntrega__c>{delivery});
            }else { 
                mapIdToDeliveryList.get(delivery.EmissorOrdem__c).add(delivery);
            }
            if (mapIdCliToCliFamilia.containsKey(delivery.EmissorOrdem__c)){
                delivery.ClienteFamilia__c = mapIdCliToCliFamilia.get(delivery.EmissorOrdem__c).Id;
                deliveryList.add(delivery);
            }
        }

        for (ClienteFamilia__c cliFamilia : [SELECT Id, ClienteFamlia__c, ValorFaturamentoAnual__c, ValorFaturamentoGlobal__c, ValorCarteira__c, FamiliaClientes__c, FamiliaClientes__r.Moeda__c FROM ClienteFamilia__c WHERE ClienteFamlia__c IN: mapIdCliToCliFamilia.keySet()]){
            mapIdCliToUpdateCliF.put(cliFamilia.ClienteFamlia__c, cliFamilia);
        }

        for (Id cliId: mapIdCliToCliFamilia.keySet()){
            faturadoAnual  = 0;
            faturadoGlobal = 0;
            totalLiquido   = 0;
            totalLitros    = 0;
            carteira       = 0;
            if (mapIdNotaFiscalList.containsKey(cliId)){
                for (NotaFiscal__c nf: mapIdNotaFiscalList.get(cliId)){
                    totalLiquido += nf.ValorTotalNotaLiquido__c;
                    totalLitros += nf.ValorTotalLitros__c;
                    if (mapIdCliToUpdateCliF.get(cliId).FamiliaClientes__r.Moeda__c == 'Real'){
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
                    if (mapIdCliToUpdateCliF.get(cliId).FamiliaClientes__r.Moeda__c == 'Real'){
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
                     if (mapIdCliToUpdateCliF.get(cliId).FamiliaClientes__r.Moeda__c == 'Real'){
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
            // system.debug(mapIdCliToUpdateCliF);
            // system.debug('HMM...');

            if (mapIdCliToUpdateCliF.containsKey(cliId)){
                // system.debug('Entrou!');
                ClienteFamilia__c cliFamilia = mapIdCliToUpdateCliF.get(cliId);  
                cliFamilia.ValorFaturamentoAnual__c     = faturadoAnual;
                cliFamilia.ValorFaturamentoGlobal__c    = faturadoGlobal;
                cliFamilia.FaturamentoGlobalLiquido__c  = totalLiquido;
                cliFamilia.ValorFaturadoLitrosGlobal__c = totalLitros;
                cliFamilia.ValorCarteira__c             = carteira;                    
                cliFamiliaList.add(cliFamilia);
            }
        }

        // system.debug('cliFamiliaList: '+ cliFamiliaList);
        // system.debug('notaFiscalList: '+ notaFiscalList);
        // system.debug('deliveryList: '+ deliveryList);
        // system.debug('ordItemList: '+ ordItemList);

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

        if (!cliFamiliaList.isEmpty()){
            ClienteFamiliaHelper.disableTrigger();
            update cliFamiliaList;
            ClienteFamiliaHelper.enableTrigger();
        }
        
        if (!prodClientesList.isEmpty()){
            insert prodClientesList;
        }
    }
}