global with sharing class TemplateDataIntegrationFields {

    @TestVisible
    private static final Id STANDARD_PRICEBOOK_ID;
        
    static {
        STANDARD_PRICEBOOK_ID = 
            Test.isRunningTest()?
            Test.getStandardPricebookId():
            [
                SELECT id 
                FROM Pricebook2 
                WHERE isStandard = true 
                LIMIT 1
            ].id;
    }

    public interface FieldData {
        List<String> getRequiredFields(FieldData obj);
        String getFieldKey();
        String getFieldId();
        SObject serialize(Map<String, Id> lookups);
    }

    public interface FieldDataChild {
        List<String> getRequiredFields(FieldData obj);
        String getFieldKey();
        String getFieldExternal();
        SObject serialize(Map<String, String> lookups);
        String getParentKey();
    }

    global class AccountINData implements FieldData {

        public String externalId;
        public String matrizCredito;
        public String name;
        public String shippingPostalCode;
        public String shippingStreet;
        public String shippingCity;
        public String shippingState;
        public String shippingCountry;
        public String billingPostalCode;
        public String billingStreet;
        public String billingCity;
        public String billingState;
        public String billingCountry;
        public String codigoIBGE;
        public String listaPreco;
        public String filial;
        public String parentId;
        public String status;
        public Decimal potencial;
        public Decimal limiteCreditoTotal;
        public Decimal saldoLimiteCredito;
        public String ratingPagamento;
        public String revendaAgenciadora;
        public String planoIncentivos;
        public String regionalVendas;
        public String rtv;
        public String gerenteRegional;
        public String diretorComercial;
        public String emailAprovacaoPedido;
        public String zonaTransporte;
        public String nomeFazenda;
        public String suframa;
        public String tipoCliente;
        public Boolean blitzObrigatoria;
        public String emailComercial;
        public String restricaoTransporte;
        public Boolean contribuinteICMS;
        public Date dataUltimaCompra;
        public String localNegocio;
        public Decimal valorUltimaCompra;
        public Boolean agenciamento;
        public String cnpj;
        public String cpf;
        public String inscricaoMunicipal;
        //public String clienteEntrega;
        //public String clienteCobranca;
        public String inscricaoEstadual;        
        public Boolean sulfur;
        public Boolean rizotec;
        public Boolean stimulate;
        public Boolean naturOleo;
        public Boolean trianum;
        public Boolean naturalOleo;
        public Boolean Atributo7;
        public Boolean Atributo8;
        public Boolean Atributo9;
        public Boolean Atributo10;
        public Boolean hierarquia;
        public Boolean bloqueado;
        public Boolean bloqueioCredito;
        // public List<String> atributoRestricao;
        public List<String> territorioIds;

        public AccountINData() {
        }

        public AccountINData(Account account, Map<Id, String> lookups, List<Territorio__c> territorioList, List<String> atributoDefensivos) {
            this.externalId           = account.ExternalId__c;
            this.matrizCredito        = lookups.containsKey(account.MatrizCredito__c) ? lookups.get(account.MatrizCredito__c) : null;
            this.name                 = account.Name;
            this.shippingPostalCode   = account.ShippingPostalCode;
            this.shippingStreet       = account.ShippingStreet;
            this.shippingCity         = account.ShippingCity;
            this.shippingState        = account.ShippingState;
            this.shippingCountry      = account.ShippingCountry;
            /*this.billingPostalCode    = account.BillingPostalCode;
            this.billingStreet        = account.BillingStreet;
            this.billingCity          = account.BillingCity;
            this.billingState         = account.BillingState;
            this.billingCountry       = account.BillingCountry;*/
            this.codigoIBGE           = account.CodigoIBGE__c;
            this.listaPreco           = account.ListaPreco__c;
            this.filial               = account.Filial__c;
            this.parentId             = lookups.containsKey(account.ParentId) ? lookups.get(account.ParentId) : null;
            this.status               = account.Status__c;
            this.potencial            = account.Potencial__c;
            this.limiteCreditoTotal   = account.LimiteCreditoTotal__c;
            this.saldoLimiteCredito   = account.SaldoLimiteCredito__c;
            this.ratingPagamento      = account.RatingPagamento__c;
            this.revendaAgenciadora   = lookups.containsKey(account.RevendaAgenciadora__c) ? lookups.get(account.RevendaAgenciadora__c) : null;
            this.planoIncentivos      = account.PlanoIncentivos__c;
            this.regionalVendas       = lookups.containsKey(account.RegionalVendas__c) ? lookups.get(account.RegionalVendas__c) : null;
            this.rtv                  = lookups.containsKey(account.RTV__c) ? lookups.get(account.RTV__c) : null;
            this.gerenteRegional      = lookups.containsKey(account.GerenteRegional__c) ? lookups.get(account.GerenteRegional__c) : null;
            this.diretorComercial     = lookups.containsKey(account.DiretorComercial__c) ? lookups.get(account.DiretorComercial__c) : null;
            this.emailAprovacaoPedido = account.EMailAprovacaoPedido__c;
            this.zonaTransporte       = lookups.containsKey(account.ZonaTransporte__c) ? lookups.get(account.ZonaTransporte__c) : null;
            this.nomeFazenda          = account.NomeFazenda__c;
            this.suframa              = account.Suframa__c;
            this.tipoCliente          = account.TipoCliente__c;
            this.blitzObrigatoria     = account.BlitzObrigatoria__c;
            this.emailComercial       = account.EMailComercial__c;
            this.restricaoTransporte  = account.RestricaoTransporte__c;
            this.contribuinteICMS     = account.ContribuinteICMS__c;
            this.dataUltimaCompra     = account.DataUltimaCompra__c;
            this.localNegocio         = lookups.containsKey(account.LocalNegocio__c) ? lookups.get(account.LocalNegocio__c) : null;
            this.valorUltimaCompra    = account.ValorUltimaCompra__c;
            this.agenciamento         = account.Agenciamento__c;
            this.bloqueado            = account.BloqueadoCredito__c;
            // this.atributoRestricao    = new List<String>(atributoDefensivos);
            this.cnpj                 = account.CNPJ__c;
            this.cpf                  = account.CPF__c;
            this.inscricaoMunicipal   = account.InscricaoMunicipal__c;
            this.inscricaoEstadual    = account.InscricaoEstadual__c;
            //this.ClienteEntrega       = lookups.containsKey(account.ClienteEntrega__c) ? lookups.get(account.ClienteEntrega__c) : null;
            //this.ClienteCobranca      = lookups.containsKey(account.ClienteCobranca__c) ? lookups.get(account.ClienteCobranca__c) : null;
            this.sulfur               = account.sulfur__c;
            this.rizotec              = account.rizotec__c;
            this.stimulate            = account.stimulate__c;
            this.naturOleo            = account.naturOleo__c;
            this.trianum              = account.trianum__c;
            this.naturalOleo          = account.naturalOleo__c;
            this.Atributo7            = account.Atributo7__c;
            this.Atributo8            = account.Atributo8__c;
            this.Atributo9            = account.Atributo9__c;
            this.Atributo10           = account.Atributo10__c;
            this.hierarquia           = lookups.containsKey(account.ParentId) ? false : true;
            this.bloqueado            = account.bloqueado__c;
            this.territorioIds        = new List<String>();
            for (Territorio__c territorio : territorioList) {
                this.territorioIds.add(territorio.ExternalId__c);
            }
        }

        public Account serialize(Map<String, Id> lookups) {
            return new Account(
                ExternalId__c           = this.externalId,
                MatrizCredito__c        = lookups.containsKey('MatrizCredito__c' + this.matrizCredito) ? lookups.get('MatrizCredito__c' + this.matrizCredito) : null,
                AccountNumber           = this.externalId,
                Name                    = this.name,
                ShippingPostalCode      = this.shippingPostalCode,
                ShippingStreet          = this.shippingStreet,
                ShippingCity            = this.shippingCity,
                ShippingState           = this.shippingState,
                ShippingCountry         = this.shippingCountry,
                /*BillingPostalCode       = this.billingPostalCode,
                BillingStreet           = this.billingStreet,
                BillingCity             = this.billingCity,
                BillingState            = this.billingState,
                BillingCountry          = this.billingCountry,*/
                CodigoIBGE__c           = this.codigoIBGE,
                ListaPreco__c           = this.listaPreco,
                Filial__c               = this.filial,
                ParentId                = lookups.containsKey('ParentId' + this.parentId) ? lookups.get('ParentId' + this.parentId) : null,
                Status__c               = this.status,
                Potencial__c            = this.potencial,
                LimiteCreditoTotal__c   = (this.limiteCreditoTotal != null ? this.limiteCreditoTotal : 0),
                SaldoLimiteCredito__c   = (this.limiteCreditoTotal != null ? this.limiteCreditoTotal : 0) - this.saldoLimiteCredito,
                RatingPagamento__c      = this.ratingPagamento,
                BloqueadoCredito__c      = this.bloqueado,
                RevendaAgenciadora__c   = lookups.containsKey('RevendaAgenciadora__c' + this.revendaAgenciadora) ? lookups.get('RevendaAgenciadora__c' + this.revendaAgenciadora) : null,
                PlanoIncentivos__c      = this.planoIncentivos,
                RegionalVendas__c       = lookups.containsKey('RegionalVendas__c' + this.regionalVendas) ? lookups.get('RegionalVendas__c' + this.regionalVendas) : null,
                RTV__c                  = lookups.containsKey('RTV__c' + this.rtv) ? lookups.get('RTV__c' + this.rtv) : null,
                OwnerId                 = lookups.containsKey('RTV__c' + this.rtv) ? lookups.get('RTV__c' + this.rtv) : lookups.containsKey('GerenteRegional__c' + this.gerenteRegional) ? lookups.get('GerenteRegional__c' + this.gerenteRegional) : null,
                GerenteRegional__c      = lookups.containsKey('GerenteRegional__c' + this.gerenteRegional) ? lookups.get('GerenteRegional__c' + this.gerenteRegional) : null,
                DiretorComercial__c     = lookups.containsKey('DiretorComercial__c' + this.diretorComercial) ? lookups.get('DiretorComercial__c' + this.diretorComercial) : null,
                EMailAprovacaoPedido__c = this.emailAprovacaoPedido,
                ZonaTransporte__c       = lookups.containsKey('ZonaTransporte__c' + this.zonaTransporte) ? lookups.get('ZonaTransporte__c' + this.zonaTransporte) : null,
                NomeFazenda__c          = this.nomeFazenda,
                CanalDistribuicao__c    = '10',
                Suframa__c              = this.suframa,
                TipoCliente__c          = this.tipoCliente,
                BlitzObrigatoria__c     = this.blitzObrigatoria,
                EMailComercial__c       = this.emailComercial,
                RestricaoTransporte__c  = this.restricaoTransporte,
                RecordTypeId            = this.hierarquia ? SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Hierarquia').getRecordTypeId() : SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId(),
                ContribuinteICMS__c     = this.contribuinteICMS,
                DataUltimaCompra__c     = this.dataUltimaCompra,
                LocalNegocio__c         = lookups.containsKey('LocalNegocio__c' + this.localNegocio) ? lookups.get('LocalNegocio__c' + this.localNegocio) : null,
                ValorUltimaCompra__c    = this.valorUltimaCompra,
                OrganizacaoVenda__c     = '1000',
                Agenciamento__c         = this.agenciamento,
                SetorAtividade__c       = '10',
                CNPJ__c                 = this.cnpj,
                CPF__c                  = this.cpf,
                InscricaoMunicipal__c   = this.inscricaoMunicipal,
                //ClienteEntrega__c       = (lookups.containsKey('ClienteEntrega__c' +this.ClienteEntrega) ? lookups.get('ClienteEntrega__c' +this.ClienteEntrega) : null),
                //ClienteCobranca__c      = (lookups.containsKey('ClienteCobranca__c' +this.ClienteCobranca) ? lookups.get('ClienteCobranca__c' +this.ClienteCobranca) : null),
                InscricaoEstadual__c    = this.inscricaoEstadual,
                sulfur__c               = this.sulfur,
                rizotec__c              = this.rizotec, 
                stimulate__c            = this.stimulate,   
                naturOleo__c            = this.naturOleo,   
                trianum__c              = this.trianum, 
                naturalOleo__c          = this.naturalOleo,     
                Atributo7__c            = this.Atributo7,   
                Atributo8__c            = this.Atributo8,   
                Atributo9__c            = this.Atributo9,   
                Atributo10__c           = this.Atributo10,
                Bloqueado__c            = this.bloqueado     
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            AccountINData nObj = (AccountINData)obj;
            List<String> listToReturn = new List<String>{
                'ExternalId__c',
                'Name',
                'ShippingPostalCode',
                'ShippingStreet',
                'ShippingCity',
                'ShippingState',
                'Status__c',
                //'LimiteCreditoTotal__c',
                // 'SaldoLimiteCredito__c',
                // 'RatingPagamento__c',
                'RTV__c',
                'OwnerId',
                'GerenteRegional__c',
                'DiretorComercial__c',
                'ZonaTransporte__c',
                'CanalDistribuicao__c',
                'TipoCliente__c',
                'LocalNegocio__c',
                'OrganizacaoVenda__c'
            };
            if (nObj.hierarquia){
                return new List<String>();
            }
            if (!String.isBlank(nObj.parentId)) {
                if(String.isBlank(nObj.Cnpj) && String.isBlank(nObj.Cpf)){
                    listToReturn.add('CPF__c');
                    listToReturn.add('CNPJ__c');
                }
                listToReturn.add('ParentId');
            }
            if (!String.isBlank(nObj.planoIncentivos)) {
                listToReturn.add('PlanoIncentivos__c');
            }
            if (!String.isBlank(nObj.revendaAgenciadora)) {
                listToReturn.add('RevendaAgenciadora__c');
            }
            if (!String.isBlank(nObj.regionalVendas)) {
                listToReturn.add('RegionalVendas__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class CancellationOUTData {
        public String document;
        public String SfId;
        public CancellingItemOUTData[] items;

        public CancellationOUTData() {
        }
        
        public CancellationOUTData(Order order, List<OrderItem> orderItem){
            this.document     = order.OVSAP__c;
            this.SfId         = order.Id;
            this.items = new List<CancellingItemOUTData>();
            for (Integer i = 0; i< orderItem.size(); i++){
                this.items.add(new CancellingItemOUTData(orderItem[i], i));
            }
        }
    }

    global class CancellingItemOUTData {

        public String itmNumber;
        public String itmNumberSF;
        public String motivoRecusa;

        public CancellingItemOUTData() {
        }

        public CancellingItemOUTData(Orderitem orderItem, Integer iteration) {
            this.itmNumber    = orderItem.NrItem__c != null ? orderItem.NrItem__c : ((iteration + 1) + '0');
            this.itmNumberSF  = orderItem.Id;
            this.motivoRecusa = orderItem.MotivoRecusaItem__c;
        }
        
    }
    
    global class CondicaoPagamentoINData implements FieldData {
        
        public String externalId;
        public String externalVigenciaId;
        public String descricao;
        public String moeda;
        public Decimal jurosComercialFinanceiro;
        public Date dataVigenciaDe;
        public Date dataVigenciaAte;
        public String dias;

        public CondicaoPagamentoINData() {
        }

        public CondicaoPagamentoINData(CondicaoPagamento__c condicaoPagamento) {
            this.externalId               = condicaoPagamento.ExternalId__c;
            this.descricao                = condicaoPagamento.Descricao__c;
            this.jurosComercialFinanceiro = condicaoPagamento.JurosComercialFinanceiro__c;
            this.dataVigenciaDe           = condicaoPagamento.DataVigenciaDe__c;
            this.dataVigenciaAte          = condicaoPagamento.DataVigenciaAte__c;
            this.dias                     = String.valueOf(condicaoPagamento.Dias__c);
        }

        public CondicaoPagamento__c serialize(Map<String, Id> lookups) {
            return new CondicaoPagamento__c(
                ExternalId__c               = this.externalId,
                Descricao__c                = this.descricao,
                Moeda__c                    = (this.externalId.startsWith('U') ? 'USD' : 'BRL'),
                JurosComercialFinanceiro__c = this.jurosComercialFinanceiro,
                DataVigenciaDe__c           = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaDe)),
                DataVigenciaAte__c          = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaAte)),
                Dias__c                     = this.dias != null ? Integer.valueOf(this.dias) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'Descricao__c',
                'Moeda__c',
                'Dias__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }
    
    global class VigenciaCondicaoINData implements FieldData {
        
        public String externalId;
        public String condicaoExternal;
        public Decimal jurosComercialFinanceiro;
        public Date dataVigenciaDe;
        public Date dataVigenciaAte;

        public VigenciaCondicaoINData() {
        }

        public VigenciaCondicaoINData(CondicaoPagamentoINData condicaoPagto) {
            // this.externalId               = condicaoPagto.dataVigenciaDe+'_'+condicaoPagto.externalId;
            this.externalId               = condicaoPagto.externalVigenciaId;
            this.jurosComercialFinanceiro = condicaoPagto.jurosComercialFinanceiro;
            this.dataVigenciaDe           = condicaoPagto.dataVigenciaDe;
            this.dataVigenciaAte          = condicaoPagto.dataVigenciaAte;
            this.condicaoExternal         = condicaoPagto.externalId;
        }

        public VigenciaCondicaoINData(VigenciaCondicao__c vigencia) {
            this.externalId               = vigencia.ExternalId__c;
            this.jurosComercialFinanceiro = vigencia.JurosComercialFinanceiro__c;
            this.dataVigenciaDe           = vigencia.DataVigenciaDe__c;
            this.dataVigenciaAte          = vigencia.DataVigenciaAte__c;
            this.condicaoExternal         = vigencia.CondicaoPagamento__r.ExternalId__c;
        }

        public VigenciaCondicao__c serialize(Map<String, Id> lookups) {
            // System.debug(lookups.get('CondicaoPagamento__c'+this.condicaoExternal));
            return new VigenciaCondicao__c(
                ExternalId__c               = this.externalId,
                JurosComercialFinanceiro__c = this.jurosComercialFinanceiro,
                DataVigenciaDe__c           = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaDe)),
                DataVigenciaAte__c          = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaAte)),
                CondicaoPagamento__c        = lookups.get('CondicaoPagamento__c'+this.condicaoExternal)
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'JurosComercialFinanceiro__c',
                'DataVigenciaDe__c',
                'DataVigenciaAte__c',
                'CondicaoPagamento__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class CotacaoMoedaINData implements FieldData {
        
        public String externalId;
        public String moeda;
        public Date data;
        public Decimal taxa;

        public CotacaoMoedaINData() {
        }

        public CotacaoMoedaINData(CotacaoMoeda__c cotacaoMoeda) {
            this.externalId = cotacaoMoeda.ExternalId__c;
            this.moeda      = cotacaoMoeda.Moeda__c;
            this.data       = Date.valueOf(cotacaoMoeda.Data__c);
            this.taxa       = cotacaoMoeda.Taxa__c;
        }

        public CotacaoMoeda__c serialize(Map<String, Id> lookups) {
            return new CotacaoMoeda__c(
                ExternalId__c = this.externalId,
                Moeda__c      = this.moeda,
                Data__c       = this.data,
                Taxa__c       = this.taxa
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'Moeda__c',
                'Data__c',
                'Taxa__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class CulturaINData implements FieldData {

        public String externalId;
        public String descricao;

        public CulturaINData() {
        }

        public CulturaINData(Cultura__c cultura) {
            this.externalId = cultura.ExternalId__c;
            this.descricao  = cultura.Descricao__c;
        }

        public Cultura__c serialize(Map<String, Id> lookups) {
            return new Cultura__c(
                ExternalId__c = this.externalId,
                Descricao__c  = this.descricao
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'Descricao__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class DescontoTipoClienteINData implements FieldData {
        
        public String externalId;
        public String organizacaoVenda;
        public String tipoCliente;
        public Decimal desconto;
        public Date dataVigenciaInicial;
        public Date dataVigenciaFinal;

        public DescontoTipoClienteINData() {
        }

        public DescontoTipoClienteINData(DescontoTipoCliente__c descontoTipoCliente) {
            this.externalId          = descontoTipoCliente.IdSAP__c;
            this.organizacaoVenda    = descontoTipoCliente.OrganizacaoVenda__c;
            this.tipoCliente         = descontoTipoCliente.TipoCliente__c;
            this.desconto            = descontoTipoCliente.Desconto__c;
            this.dataVigenciaInicial = descontoTipoCliente.DataVigenciaInicial__c;
            this.dataVigenciaFinal   = descontoTipoCliente.DataVigenciaFinal__c;
        }

        public DescontoTipoCliente__c serialize(Map<String, Id> lookups) {
            return new DescontoTipoCliente__c(
                IdSAP__c               = this.externalId,
                OrganizacaoVenda__c    = this.organizacaoVenda,
                TipoCliente__c         = this.tipoCliente,
                Desconto__c            = this.desconto,
                DataVigenciaInicial__c = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaInicial)),
                DataVigenciaFinal__c   = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaFinal))
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'IdSAP__c',
                'OrganizacaoVenda__c',
                'TipoCliente__c',
                'Desconto__c',
                'DataVigenciaInicial__c',
                'DataVigenciaFinal__c'
            };
        }

        public String getFieldKey() {
            return 'IdSAP__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class EscoamentoOUTData {

        public String sfId;
        public String dataEscoamento;
        public String cliente;
        public String territorio;
        public String descricaoTerritorio;
        public String fornecedor;
        public String nomeCliente;
        public String nomeFornecedor;
        public String material;
        public String textoBreveMaterial;
        public String quantidadeOrdem;

        public EscoamentoOUTData() {
        }

        public EscoamentoOUTData(Escoamento__c escoamento) {
            this.sfId                = escoamento.Id;
            this.dataEscoamento      = IntegrationUtils.dateToStringSAP(escoamento.DataApuracao__c);
            this.cliente             = escoamento.NomeCliente__r.ExternalId__c;
            this.territorio          = escoamento.Territorio__r.NomeTerritorio__c;
            // this.descricaoTerritorio = escoamento.DescricaoTerritorio__c;
            this.fornecedor          = escoamento.RTV__r.BusinessPartnerSAP__c;
            this.nomeCliente         = escoamento.NomeCliente__r.Name;
            this.nomeFornecedor      = escoamento.RTV__r.Name;
            this.material            = escoamento.Produto__r.ExternalId__c;
            this.textoBreveMaterial  = escoamento.Produto__r.Name;
            this.quantidadeOrdem     = String.valueOf(escoamento.Quantidade__c);
        }

    }

    global class ItinerarioINData implements FieldData {
        
        public String externalId;
        public String internalSFExternalID;
        public String tipoExpedicao;
        public String origemZonaTransporteId;
        public String destinoZonaTransporteId;
        public Integer dias;

        public ItinerarioINData() {
        }

        public ItinerarioINData(Itinerario__c itinerario, Map<Id, String> lookups) {
            this.externalId              = itinerario.ExternalId__c;
            this.tipoExpedicao           = itinerario.TipoExpedicao__c;
            this.origemZonaTransporteId  = lookups.containsKey(itinerario.ZonaTransporteOrigem__c) ? lookups.get(itinerario.ZonaTransporteOrigem__c) : null;
            this.destinoZonaTransporteId = lookups.containsKey(itinerario.ZonaTransporteDestino__c) ? lookups.get(itinerario.ZonaTransporteDestino__c) : null;
            this.dias                    = Integer.valueOf(itinerario.Dias__c);
            this.internalSFExternalID    = this.externalId+'_'+this.origemZonaTransporteId+'_'+this.destinoZonaTransporteId;
        }

        public Itinerario__c serialize(Map<String, Id> lookups) {
            return new Itinerario__c(
                ExternalId__c            = this.externalId,
                InternalExternalId__c    = this.externalId+'_'+this.origemZonaTransporteId+'_'+this.destinoZonaTransporteId,
                TipoExpedicao__c         = this.tipoExpedicao,
                ZonaTransporteOrigem__c  = lookups.containsKey('ZonaTransporteOrigem' + this.origemZonaTransporteId) ? lookups.get('ZonaTransporteOrigem' + this.origemZonaTransporteId) : null,
                ZonaTransporteDestino__c = lookups.containsKey('ZonaTransporteDestino' + this.destinoZonaTransporteId) ? lookups.get('ZonaTransporteDestino' + this.destinoZonaTransporteId) : null,
                Dias__c                  = this.dias
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'TipoExpedicao__c',
                'ZonaTransporteOrigem__c',
                'ZonaTransporteDestino__c',
                'Dias__c'
            };
        }

        public String getFieldKey() {
            return 'InternalExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class LancamentoContabilINData implements FieldData {
        
        public String externalId;
        public String codigoMaterial;
        public Decimal quantidade;
        public String codigoCliente;
        public String organizacaoVendas;
        public String moeda;
        public Decimal montante;
        public Decimal montanteInterno;
        public Decimal montanteInternoDolar;
        public Date dataLancamento;

        public LancamentoContabilINData() {
        }

        public LancamentoContabilINData(LancamentoContabil__c lancamentoContabil) {
            this.externalId           = lancamentoContabil.ExternalId__c;
            this.codigoCliente        = lancamentoContabil.CodigoCliente__c;
            this.organizacaoVendas    = lancamentoContabil.OrganizacaoVendas__c;
            this.moeda                = lancamentoContabil.Moeda__c;
            this.montante             = lancamentoContabil.Montante__c;
            this.montanteInterno      = lancamentoContabil.MontanteInterno__c;
            this.montanteInternoDolar = lancamentoContabil.MontanteInternoDolar__c;
            this.dataLancamento       = lancamentoContabil.DataLancamento__c;
            this.quantidade           = lancamentoContabil.Quantidade__c;
            this.codigoMaterial       = lancamentoContabil.Produto__c;
        }

        public LancamentoContabil__c serialize(Map<String, Id> lookups) {
            return new LancamentoContabil__c(
                ExternalId__c           = this.externalId,
                CodigoCliente__c        = this.codigoCliente,
                NomeConta__c            = lookups.containsKey('ExternalId__c' + this.codigoCliente) ? lookups.get('ExternalId__c' + this.codigoCliente) : null,
                OrganizacaoVendas__c    = this.organizacaoVendas,
                Moeda__c                = this.moeda,
                Montante__c             = this.montante,
                MontanteInterno__c      = this.montanteInterno,
                MontanteInternoDolar__c = this.montanteInternoDolar,
                DataLancamento__c       = this.dataLancamento,
                Quantidade__c           = this.quantidade,
                Produto__c              = lookups.containsKey('CodigoMaterial__c' + this.codigoMaterial) ? lookups.get('CodigoMaterial__c' + this.codigoMaterial) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            LancamentoContabilINData nObj = (LancamentoContabilINData)obj;
            List<String> listToReturn = new List<String>{
                'ExternalId__c',
                'OrganizacaoVendas__c',
                'Moeda__c',
                'Montante__c',
                'MontanteInterno__c',
                'DataLancamento__c'
            };
            if (!String.isBlank(nObj.codigoCliente)) {
                listToReturn.add('NomeConta__c');
            }
            if (!String.isBlank(nObj.codigoMaterial)) {
                listToReturn.add('Produto__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class LocalNegocioINData implements FieldData {
        
        public String externalId;
        public String descricao;
        public String zonaTransporteId;

        public LocalNegocioINData() {
        }

        public LocalNegocioINData(LocalNegocio__c localNegocio, Map<Id, String> lookups) {
            this.externalId        = localNegocio.Codigo__c;
            this.descricao         = localNegocio.Descricao__c;
            this.zonaTransporteId  = lookups.containsKey(localNegocio.ZonaTransporte__c) ? lookups.get(localNegocio.ZonaTransporte__c) : null;
        }

        public LocalNegocio__c serialize(Map<String, Id> lookups) {
            return new LocalNegocio__c(
                Codigo__c         = this.externalId,
                Descricao__c      = this.descricao,
                ZonaTransporte__c = lookups.containsKey('ZonaTransporte__c' + this.zonaTransporteId) ? lookups.get('ZonaTransporte__c' + this.zonaTransporteId) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'Codigo__c',
                'Descricao__c',
                'ZonaTransporte__c'
            };
        }

        public String getFieldKey() {
            return 'Codigo__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class MetaINData implements FieldData {

        public String externalId;
		public String accountId;
		public Date data;
		public String territorioId;
		public String productId;
		public Decimal orcamentoDolar;
		public Decimal orcamentoReal;
        public Integer litros;

        public MetaINData() {
        }

        public MetaINData(Meta__c meta, Map<Id, String> lookups) {
            this.externalId     = meta.IDMetaSAP__c;
            this.accountId      = lookups.containsKey(meta.NomeConta__c) ? lookups.get(meta.NomeConta__c) : null;
            this.data           = meta.Data__c;
            this.territorioId   = lookups.containsKey(meta.Territorio__c) ? lookups.get(meta.Territorio__c) : null;
            this.productId      = lookups.containsKey(meta.Produto__c) ? lookups.get(meta.Produto__c) : null;
            this.orcamentoDolar = meta.OrcamentoDolar__c;
            this.orcamentoReal  = meta.OrcamentoReal__c;
            this.litros         = Integer.valueOf(meta.Litros__c);
        }

        public Meta__c serialize(Map<String, Id> lookups) {
            return new Meta__c(
                IDMetaSAP__c      = this.externalId,
                NomeConta__c      = lookups.containsKey('NomeConta__c' + this.accountId) ? lookups.get('NomeConta__c' + this.accountId) : null,
                Data__c           = this.data,
                Territorio__c     = lookups.containsKey('Territorio__c' + this.territorioId) ? lookups.get('Territorio__c' + this.territorioId) : null,
                Produto__c        = lookups.containsKey('Produto__c' + this.productId) ? lookups.get('Produto__c' + this.productId) : null,
                OrcamentoDolar__c = this.orcamentoDolar,
                OrcamentoReal__c  = this.orcamentoReal,
                Litros__c         = this.litros,
                OwnerId           = lookups.containsKey('OwnerId' + this.territorioId) ? lookups.get('OwnerId' + this.territorioId) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'IDMetaSAP__c',
                'NomeConta__c',
                'Data__c',
                'Territorio__c',
                'Produto__c',
                // 'OrcamentoDolar__c',
                'OrcamentoReal__c',
                'Litros__c'
            };
        }

        public String getFieldKey() {
            return 'IDMetaSAP__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class NotaFiscalINData implements FieldData{

        public String tipo;
        public Date data;
        public Time hora;
        public String centro;
        public String codigoCliente; //Conta
        public String nomeCliente;
        public String estadoCliente;
        public String pais;
        public Decimal numeroNF;
        public Decimal serieNF;
        public String fatura;
        public String documento;
        public String codigoOrdem;//order
        public String sfIdOpp;//oportunidade
        public Boolean agenciamento;
        public String tipoFatura;
        public String descricaoTipoFat;
        public String regional;//regional
        public String diretoriaEscritorio;
        public String organizacaoVendas;
        public String canalVenda;
        public String codigoAgenciador;//conta
        public String gerente;
        public String emailGerente;
        public String territorio;//territorio
        public String armazemGeral;
        public String vendedorRTV;//Usuario
        public String  eMailVendedor;
        public String transportador;
        public String nomeTransportador;
        public String condPagto;
        public String incotermoTipoFrete;
        public Boolean status; //Status Cancelamento
        public String chaveAcesso;
        public Decimal ValorTotal;
        public Date DataVencimento;
        public NotaFiscalItemINData[] items;

        public NotaFiscalINData() {}

        public NotaFiscalINData(NotaFiscal__c nota, Map<Id, String> lookups) { 
            this.tipo                = nota.TipoNota__c;
            this.data                = nota.DataNF__c;
            this.hora                = nota.HoraNF__c;
            this.centro              = nota.Centro__c;
            this.codigoCliente       = lookups.containsKey(nota.CodigoCliente__c) ? lookups.get(nota.CodigoCliente__c) : null;
            this.nomeCliente         = nota.NomeCliente__c;
            this.estadoCliente       = nota.EstadoCliente__c;
            this.pais                = nota.Pais__c;
            this.numeroNF            = nota.NrNF__c;
            this.serieNF             = nota.SerieNF__c;
            this.fatura              = nota.NrFatura__c;
            this.documento           = nota.NrDocumentoNF__c;
            this.codigoOrdem         = lookups.containsKey(nota.NrOrdem__c) ? lookups.get(nota.NrOrdem__c) : null;
            this.sfIdOpp             = String.isNotBlank(nota.Oportunidade__c) ? nota.Oportunidade__c : null;
            this.agenciamento        = nota.Agenciamento__c;
            this.tipoFatura          = nota.TipoFat__c;
            this.descricaoTipoFat    = nota.DescricaoTipoFatura__c;
            this.regional            = lookups.containsKey(nota.Regional__c) ? lookups.get(nota.Regional__c) : null;
            this.diretoriaEscritorio = nota.DiretoriaEscritorio__c;
            this.organizacaoVendas   = nota.OrganizacaoVendas__c;
            this.canalVenda          = nota.CanalVenda__c;
            this.codigoAgenciador    = lookups.containsKey(nota.CodigoAgenciador__c) ? lookups.get(nota.CodigoAgenciador__c) : null;
            this.gerente             = nota.Gerente__c;
            this.emailGerente        = nota.EmailGerente__c;
            this.territorio          = lookups.containsKey(nota.Territorio__c) ? lookups.get(nota.Territorio__c) : null;
            this.armazemGeral        = nota.ArmazemGeral__c;
            this.vendedorRTV         = lookups.containsKey(nota.VendedorRTV__c) ? lookups.get(nota.VendedorRTV__c) : null;
            this.eMailVendedor       = nota.EMailVendedor__c;
            this.transportador       = nota.Transportador__c;
            this.nomeTransportador   = nota.NomeTransportador__c;
            this.condPagto           = nota.CondPagto__c;
            this.incotermoTipoFrete  = nota.IncotermoTipoFrete__c; 
            this.Status              = nota.StatusCancelado__c;
            this.ChaveAcesso         = nota.ChaveAcesso__c; 
            this.ValorTotal          = nota.ValorTotalNota__c;
            this.DataVencimento      = nota.DataVencimento__c;
        }

        public NotaFiscal__c serialize(Map<String, Id> lookups) {
            // System.debug(this.regional);
            // System.debug(lookups);
            NotaFiscal__c nota =  new NotaFiscal__c();
            nota.RecordTypeId            = getRecordType();
            nota.Centro__c               = this.centro;
            nota.NomeCliente__c          = this.nomeCliente;
            nota.EstadoCliente__c        = this.estadoCliente;
            nota.Pais__c                 = this.pais;
            nota.NrNF__c                 = this.numeroNF;
            nota.NrFatura__c             = this.fatura;
            nota.Agenciamento__c         = (this.agenciamento == null ? false: this.agenciamento);
            nota.TipoFat__c           = this.tipoFatura;
            nota.DescricaoTipoFatura__c     = this.descricaoTipoFat;
            nota.DiretoriaEscritorio__c  = this.diretoriaEscritorio;
            nota.OrganizacaoVendas__c    = this.organizacaoVendas;
            nota.CanalVenda__c           = this.canalVenda;
            nota.Gerente__c              = this.gerente;
            nota.EmailGerente__c         = this.emailGerente;
            nota.ArmazemGeral__c         = this.armazemGeral;
            nota.EMailVendedor__c        = this.eMailVendedor;
            nota.Transportador__c        = this.transportador;
            nota.NomeTransportador__c    = this.nomeTransportador;
            nota.CondPagto__c            = this.condPagto;
            nota.StatusCancelado__c      = (this.Status == null? false : this.Status);
            nota.IncotermoTipoFrete__c   = this.incotermoTipoFrete;
            nota.ValorTotalNota__c       = this.ValorTotal;
            nota.DataVencimento__c       = this.DataVencimento;
            nota.Oportunidade__c         = lookups.containsKey('Oportunidade__c'     + this.sfIdOpp)          ? lookups.get('Oportunidade__c'     + this.sfIdOpp) : null;
            nota.CodigoCliente__c        = lookups.containsKey('CodigoCliente__c'    + this.codigoCliente)    ? lookups.get('CodigoCliente__c'    + this.codigoCliente) : null;
            nota.NrOrdem__c              = lookups.containsKey('NrOrdem__c'          + this.codigoOrdem)      ? lookups.get('NrOrdem__c'          + this.codigoOrdem) : null;
            nota.Regional__c             = lookups.containsKey('Regional__c'         + this.regional)         ? lookups.get('Regional__c'         + this.regional) : null;
            nota.CodigoAgenciador__c     = lookups.containsKey('CodigoAgenciador__c' + this.codigoAgenciador) ? lookups.get('CodigoAgenciador__c' + this.codigoAgenciador) : null;
            nota.Territorio__c           = lookups.containsKey('Territorio__c'       + this.territorio)       ? lookups.get('Territorio__c'       + this.territorio) : null;
            nota.VendedorRTV__c          = lookups.containsKey('VendedorRTV__c'      + this.vendedorRTV)      ? lookups.get('VendedorRTV__c'      + this.vendedorRTV) : null;
            nota.OwnerId                 = lookups.containsKey('OwnerId'             + this.territorio)       ? lookups.get('OwnerId'             + this.territorio) : null;
            if(isNF()){
                nota.TipoNota__c         = this.tipo;
                nota.DataNF__c         = this.data;
                nota.HoraNF__c         = this.hora;
                nota.SerieNF__c        = this.serieNF;
                nota.ChaveAcesso__c    = this.ChaveAcesso;
                nota.NrDocumentoNF__c  = this.documento;
                nota.ExternalId__c     = String.valueOf(this.numeroNF);
                nota.codigoExterno__c  = String.valueOf(this.numeroNF) + String.valueOf(this.serieNF);
            }else{
                nota.ExternalId__c     = String.valueOf(this.fatura);
            }
            return nota;
        }

        public id getRecordType(){
            if(isNF()){
                return Schema.SObjectType.NotaFiscal__c.getRecordTypeInfosByDeveloperName().get('NotaFiscal').getRecordTypeId();
            }else{
                return Schema.SObjectType.NotaFiscal__c.getRecordTypeInfosByDeveloperName().get('Fatura').getRecordTypeId();
            }
        }

        public Boolean isNF(){
            return (String.isNotEmpty(String.valueOf(this.numeroNF)));
        }
        
        public List<String> getRequiredFields(FieldData obj) {
             return new List<String>{
                 'CodigoCliente__c',
                 'NrOrdem__c',
                 'Regional__c'
                //  'VendedorRTV__c'
             };
         }
  
         public String getFieldKey() {
            return 'ExternalId__c';
         }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class NotaFiscalItemINData implements FieldData{

        public String nrItem;
        public String itinerario;
        public Decimal valorLista;
        public Decimal descontoCanal;
        public Decimal freteAcrescimo;
        public Decimal descontoPolitica;
        public Decimal jurosAcrescimo;
        public Decimal nrItemNf;
        public Decimal nrNota;
        public String codigoMaterial;
        public String descricaoMaterial;
        public Decimal quantidadeNota;
        public String familia;
        public String unidadeMedida;
        public String subFamilia;
        public String tipoMaterial;
        public Decimal valorUnitarioItem;
        public Decimal valorTotalItem;
        public Decimal valorIPI;
        public String cultura;
        public Decimal descontoConcedido;
        public Decimal valorTotalLiquido;
        public Decimal valorTotalcJuros;

        public NotaFiscalItemINData() {
        }

        public NotaFiscalItemINData(NotaFiscalItem__c notaItem, Map<Id, String> lookups) {
            this.nrItemNf          = notaItem.NrItemNF__c;
            this.nrNota            = notaItem.NotaFiscal__r.NrNF__c;
            this.CodigoMaterial    = lookups.containsKey(notaItem.CodigoMaterial__c) ? lookups.get(notaItem.CodigoMaterial__c) : null;
            this.DescricaoMaterial = notaItem.DescricaoMaterial__c;
            this.QuantidadeNota    = notaItem.QuantidadeNota__c;
            this.Familia           = notaItem.Familia__c;
            this.UnidadeMedida     = notaItem.UnidadeMedida__c;
            this.SubFamilia        = notaItem.SubFamilia__c;
            this.TipoMaterial      = notaItem.TipoMaterial__c;
            this.ValorUnitarioItem = notaItem.ValorUnitarioItem__c;
            this.ValorTotalItem    = notaItem.ValorTotalItem__c;
            this.ValorIPI          = notaItem.ValorIPI__c;
            this.Cultura           = lookups.containsKey(notaItem.Cultura__c) ? lookups.get(notaItem.Cultura__c) : null;
            this.valorLista        = notaItem.Valor_Lista_Z001__c;
            this.descontoCanal     = notaItem.DescontoCanal__c;
            this.freteAcrescimo    = notaItem.FreteAcrescimo__c;
            this.descontoPolitica  = notaItem.DescontoPolitica__c;
            this.jurosAcrescimo    = notaItem.jurosAcrescimo__c;
            this.itinerario        = lookups.containsKey(notaItem.Itinerario__c) ? lookups.get(notaItem.Itinerario__c) : null;
            this.nrItem            = notaItem.NrItemOrdemNossonr__c;
            this.descontoConcedido = notaItem.DescontoConcedido__c;
            this.valorTotalLiquido = notaItem.ValorTotalLiquido__c;
            this.valorTotalcJuros  = notaItem.ValorTotalComJuros__c;
            
        }

        public NotaFiscalItem__c serialize(Map<String, Id> lookups) {
             NotaFiscalItem__c notaItem  = new NotaFiscalItem__c(
                NrItemOrdemNossonr__c = this.nrItem,
                QuantidadeNota__c     = this.QuantidadeNota,
                Familia__c            = this.Familia,
                DescricaoMaterial__c  = this.DescricaoMaterial,
                UnidadeMedida__c      = this.UnidadeMedida,
                SubFamilia__c         = this.SubFamilia,
                TipoMaterial__c       = this.TipoMaterial,
                ValorUnitarioItem__c  = this.ValorUnitarioItem,
                ValorTotalItem__c     = this.ValorTotalItem,
                Valor_Lista_Z001__c   = this.valorLista,
                DescontoCanal__c      = this.descontoCanal,
                FreteAcrescimo__c     = this.freteAcrescimo,
                DescontoPolitica__c   = this.descontoPolitica,
                jurosAcrescimo__c     = this.jurosAcrescimo,
                DescontoConcedido__c  = this.descontoConcedido,
                ValorTotalComJuros__c = this.valorTotalcJuros,
                ValorTotalLiquido__c  = this.valorTotalLiquido,
                itinerario__c         = (lookups.containsKey('Itinerario__c' +this.itinerario)              ? lookups.get('Itinerario__c'+this.itinerario) : null),
                CodigoMaterial__c     = (lookups.containsKey('CodigoMaterial__c'      +this.CodigoMaterial)          ? lookups.get('CodigoMaterial__c'+this.CodigoMaterial) : null),
                Cultura__c            = (lookups.containsKey('Cultura__c'    +this.Cultura)                 ? lookups.get('Cultura__c'+this.Cultura) : null)
            );
            if(isNF()){ 
                notaItem.NrItemNF__c           = this.nrItemNf;
                notaItem.ValorIPI__c           = this.ValorIPI;
            }
            return notaItem;
        }
        public NotaFiscalItem__c serialize(Map<String, Id> lookups, NotaFiscal__c notResult) {
             NotaFiscalItem__c notaItem = this.serialize(lookups);
             notaItem.NrItemOrdemNossonr__c = notResult.ExternalId__c+'-'+this.nrItem;
             notaItem.NotaFiscal__c = notResult.Id;
            return notaItem;
        }

        public Boolean isNF(){
            return (!String.isEmpty(String.valueOf(this.nrItemNf)));
        }
        
         public List<String> getRequiredFields(FieldData obj) {
             return new List<String>{
                 'NrItemOrdemNossonr__c',
                 //'NotaFiscal__c',
                 //'Cultura__c',
                 'CodigoMaterial__c'
             };
         }
  
         public String getFieldKey() {
             return 'NrItemOrdemNossonr__c';
         }
        
        public String getFieldFatherId() {
            return 'NotaFiscal__c';
        }

        public String getFieldId() {
            return 'Id';
        }

    }

    global class OrderINData implements FieldData {

        public String sapId;
        public Id sfId;
        public String organizacaoVendas;
        public String listaPreco;
        public String canalDistribuicao;
        public String setorAtividade;
        public String pedidoCliente;
        public Date dataInicioJuros;
        public String motivoOrdem;
        public String condicaoPagamentoId;
        public String opportunityId;
        public Boolean agenciamento;
        public String description;
        public String moeda;
        public String accountId;
        public String recebedorMercadoriaId;
        public String territorioId;
        public String rtvId;
        public String gerenteRegionalId;
        public String clienteAgenciadorId;
        public String statusCredito;
        public String bloqueioRemessa;
        public String orderType;
        public Date createdDateSAP;
        public Date pricingDate;
        public String salesPlace;
        public OrderItemINData[] items;

        public OrderINData() {
        }

        public OrderINData(Order order, Map<Id, String> lookups) {
            this.sapId                 = order.OVSAP__c;
            this.listaPreco            = order.ListaPreco__c;
            this.organizacaoVendas     = order.OrganizacaoVendas__c;
            this.canalDistribuicao     = order.CanalDistribuicao__c;
            this.setorAtividade        = order.SetorAtividade__c;
            this.pedidoCliente         = order.PedidoCliente__c;
            this.dataInicioJuros       = order.DataInicioJuros__c;
            this.motivoOrdem           = order.MotivoOrdem__c;
            this.condicaoPagamentoId   = lookups.containsKey(order.CondicaoPagamento__c) ? lookups.get(order.CondicaoPagamento__c) : null;
            this.opportunityId         = lookups.containsKey(order.OpportunityId) ? lookups.get(order.OpportunityId) : null;
            this.agenciamento          = order.Agenciamento__c;
            this.moeda                 = order.Moeda__c;
            this.accountId             = lookups.containsKey(order.AccountId) ? lookups.get(order.AccountId) : null;
            this.recebedorMercadoriaId = lookups.containsKey(order.RecebedorMercadoria__c) ? lookups.get(order.RecebedorMercadoria__c) : null;
            this.territorioId          = lookups.containsKey(order.Territorio__c) ? lookups.get(order.Territorio__c) : null;
            this.rtvId                 = lookups.containsKey(order.RTV__c) ? lookups.get(order.RTV__c) : null;
            this.gerenteRegionalId     = lookups.containsKey(order.GerenteRegional__c) ? lookups.get(order.GerenteRegional__c) : null;
            this.clienteAgenciadorId   = lookups.containsKey(order.ClienteAgenciador__c) ? lookups.get(order.ClienteAgenciador__c) : null;
            this.description           = order.Description;
            this.statusCredito         = order.StatusCredito__c;
            this.bloqueioRemessa       = order.BloqueioRemessa__c;
            this.orderType             = order.TipoOrdem__c;
            this.createdDateSAP        = order.DataCriacaoSAP__c;
            this.pricingDate           = order.DataFixacaoPreco__c;
            this.salesPlace            = order.EscritorioVendas__c;
        }

        public Order serialize(Map<String, Id> lookups) {
            this.statusCredito = String.isBlank(this.statusCredito) ? 'Z' : this.statusCredito;
            // System.debug(this.accountId);
            // System.debug(lookups);
            return new Order(
                OVSAP__c               = this.sapId,
                Status                 = 'Draft',
                Pricebook2Id           = STANDARD_PRICEBOOK_ID,
                ListaPreco__c          = this.listaPreco,
                OrganizacaoVendas__c   = this.organizacaoVendas,
                ClienteEmissor__c      = lookups.containsKey('AccountId' + this.accountId) ? lookups.get('AccountId' + this.accountId) : null,
                Regional__C            = lookups.containsKey('Regional__c' + this.territorioId) ? lookups.get('Regional__c' + this.territorioId) : null,
                CanalDistribuicao__c   = this.canalDistribuicao,
                SetorAtividade__c      = this.setorAtividade,
                PedidoCliente__c       = this.pedidoCliente,
                DataInicioJuros__c     = this.dataInicioJuros,
                MotivoOrdem__c         = this.motivoOrdem,
                CondicaoPagamento__c   = lookups.containsKey('CondicaoPagamento__c' + this.condicaoPagamentoId) ? lookups.get('CondicaoPagamento__c' + this.condicaoPagamentoId) : null,
                OpportunityId          = lookups.containsKey('OpportunityId' + this.opportunityId) ? lookups.get('OpportunityId' + this.opportunityId) : null,
                Agenciamento__c        = this.agenciamento,
                Moeda__c               = this.moeda,
                AccountId              = lookups.containsKey('AccountId' + this.accountId) ? lookups.get('AccountId' + this.accountId) : null,
                RecebedorMercadoria__c = lookups.containsKey('RecebedorMercadoria__c' + this.recebedorMercadoriaId) ? lookups.get('RecebedorMercadoria__c' + this.recebedorMercadoriaId) : null,
                Territorio__c          = lookups.containsKey('Territorio__c' + this.territorioId) ? lookups.get('Territorio__c' + this.territorioId) : null,
                RTV__c                 = lookups.containsKey('RTV__c' + this.rtvId) ? lookups.get('RTV__c' + this.rtvId) : null,
                GerenteRegional__c     = lookups.containsKey('GerenteRegional__c' + this.gerenteRegionalId) ? lookups.get('GerenteRegional__c' + this.gerenteRegionalId) : null,
                ClienteAgenciador__c   = lookups.containsKey('ClienteAgenciador__c' + this.clienteAgenciadorId) ? lookups.get('ClienteAgenciador__c' + this.clienteAgenciadorId) : null,
                Description            = this.description,                
                StatusCredito__c       = this.statusCredito,
                BloqueioRemessa__c     = this.bloqueioRemessa,
                TipoOrdem__c           = this.orderType,
                EffectiveDate          = Date.Today(),
                DataCriacaoSAP__c      = this.createdDateSAP,
                DataFixacaoPreco__c    = this.PricingDate,
                EscritorioVendas__c    = this.salesPlace,
                Diretor__c             = lookups.containsKey('Diretor__c' + this.salesPlace) ? lookups.get('Diretor__c' + this.salesPlace) : null,
                OwnerId                = lookups.containsKey('OwnerId' + this.territorioId) ? lookups.get('OwnerId' + this.territorioId) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            OrderINData nObj = (OrderINData)obj;
            List<String> listToReturn = new List<String>{
                'OVSAP__c',
                'OrganizacaoVendas__c',
                'SetorAtividade__c',
                'CanalDistribuicao__c',
                'CondicaoPagamento__c',
                'Moeda__c'
                // 'NrItem__c',
                // 'NumeroRemessa__c'
            };
            if (!String.isBlank(nObj.accountId)) {
                listToReturn.add('AccountId');
            }
     
            if (!String.isBlank(nObj.recebedorMercadoriaId)) {
                listToReturn.add('RecebedorMercadoria__c');
            }
            if (!String.isBlank(nObj.territorioId)) {
                listToReturn.add('Territorio__c');
            }
            if (!String.isBlank(nObj.rtvId)) {
                listToReturn.add('RTV__c');
            }
            if (!String.isBlank(nObj.gerenteRegionalId)) {
                listToReturn.add('GerenteRegional__c');
            }
            if (!String.isBlank(nObj.clienteAgenciadorId)) {
                listToReturn.add('ClienteAgenciador__c');
            }
            if (!String.isBlank(nObj.statusCredito)) {
                listToReturn.add('StatusCredito__c');
            }
            if (!String.isBlank(nObj.bloqueioRemessa)) {
                listToReturn.add('BloqueioRemessa__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'OVSAP__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class OrderItemINData implements FieldData {

        public Id sfId;
        public String numeroPedidoCliente;
        public String product2Id;
        public String culturaId;
        public String localNegocioId;
        public String programacaoId;
        public Date dataEntrega;
        public Decimal precoLista;
        public Decimal valorJuros;
        public Decimal precoVendaSemJuros;
        public Decimal precoListaReferencia;
        public String unidade;
        public Decimal saldoLitros;
        public String StatusFaturamento;
        public String motivoRecusaItem;
        public String statusFornecItem;
        public String statusSAP;
        public String itinerarioId;
        public String bloqueioDocumentoFaturamento;
        public String nrItem;
        public Date dataRemSolictReal;
        public Integer quantidadeFornecida;
        public Decimal saldoFornecer;
        public Decimal salesforcePrice;
        public Decimal descontoConcedido;
        public Integer quantity;
        transient public Integer litros;
        //public String numeroRemessa;
        public String[] numeroRemessa;
        public ScheduleSAPIN[] schedules;

        transient public Integer quantidade;
        transient public OrderINData orderData;
        transient public Integer quantidadeConfirmada;
        transient public Date dataFaturamento;
        transient public Date dataInicioExpedicao;
        transient public String linhaDivisaoRemessa;
        transient public String orderId;
        transient public String pricebookEntryId;
        transient public String ovSAPID; 

        public OrderItemINData() {
        }

        public OrderItemINData(OrderItem orderItem, Map<Id, String> lookups) {
            this.sfId                         = orderItem.Id;
            this.numeroPedidoCliente          = orderItem.NumeroPedidoCliente__c;
            this.product2Id                   = lookups.containsKey(orderItem.Product2Id) ? lookups.get(orderItem.Product2Id) : null;
            this.programacaoId                = lookups.containsKey(orderItem.ProgramacaoEntrega__c) ? lookups.get(orderItem.ProgramacaoEntrega__c) : null;
            this.culturaId                    = lookups.containsKey(orderItem.Cultura__c) ? lookups.get(orderItem.Cultura__c) : null;
            this.localNegocioId               = lookups.containsKey(orderItem.LocalNegocio__c) ? lookups.get(orderItem.LocalNegocio__c) : null;
            this.precoLista                   = orderItem.PrecoLista__c;
            this.valorJuros                   = orderItem.ValorJuros__c;
            this.precoVendaSemJuros           = orderItem.PrecoVendaSemJuros__c;
            this.precoListaReferencia         = orderItem.PrecoListaReferencia__c;
            this.unidade                      = orderItem.Unidade__c;
            this.saldoLitros                  = orderItem.SaldoLitros__c;
            this.StatusFaturamento            = orderItem.StatusGlobalItem__c;
            this.motivoRecusaItem             = orderItem.MotivoRecusaItem__c;
            this.statusFornecItem             = orderItem.StatusFornecItem__c;
            this.statusSAP                    = orderItem.StatusSAP__c;
            this.bloqueioDocumentoFaturamento = orderItem.BloqueioDocumentoFaturamento__c;
            this.nrItem                       = orderItem.NrItem__c;
            this.dataRemSolictReal            = orderItem.DataRemSolicitReal__c;
            this.quantidadeFornecida          = Integer.valueOf(orderItem.QuantidadeFornecida__c);
            this.saldoFornecer                = orderItem.SaldoFornecer__c;
            this.salesforcePrice              = orderItem.ValorUnitarioComJuros__c;
            this.itinerarioId                 = lookups.containsKey(orderItem.Itinerario__c) ? lookups.get(orderItem.Itinerario__c) : null;
            this.numeroRemessa                = (orderItem.numeroRemessa__c != null  ? orderItem.numeroRemessa__c.split('\n') : new List<String>());
            //this.numeroRemessa                = orderItem.numeroRemessa__c;
            this.quantity                     = Integer.valueOf(orderItem.QuantidadeTotal__c);
            this.descontoConcedido            = orderItem.DescontoConcedido__c;
            this.litros                       = Integer.valueOf(orderItem.Litros__c);

            ScheduleSAPIN sch = new ScheduleSAPIN();
            sch.scheduleNumber    = orderItem.LinhaDivisaoRemessa__c;
            sch.scheduleDate      = orderItem.DataEntrega__c;
            sch.quantity          = Integer.valueOf(orderItem.Quantity);
            sch.confirmedQuantity = Integer.valueOf(orderItem.QuantidadeConfirmada__c);
            sch.expeditionDate    = orderItem.DataInicioExpedicao__c;
            sch.invoiceDate       = orderItem.DataFaturamento__c;

            this.schedules = new List<ScheduleSAPIN>{sch};
        }

        public OrderItem serialize(Map<String, Id> lookups) {
            this.StatusFaturamento = String.isBlank(this.StatusFaturamento) ? 'Z' : this.StatusFaturamento;
            System.debug('this.product2Id => ' + this.product2Id);
            System.debug('lookups.containsKey(PricebookEntry + this.product2Id) => ' + lookups.containsKey('PricebookEntry' + this.product2Id));
            System.debug('lookups.get(PricebookEntry + this.product2Id) => ' + lookups.get('PricebookEntry' + this.product2Id));
            // System.debug(this.itinerarioId);
            // System.debug(lookups);
            OrderItem ordItem = new OrderItem(
                Id                              = String.isEmpty(this.sfId) ? null : this.sfId,
                ExternalId__c                   = this.ovSAPID + '-' + this.nrItem + '-' + this.linhaDivisaoRemessa,
                UnitPrice                       = this.salesforcePrice,
                PricebookEntryId                = lookups.containsKey('PricebookEntry' + this.product2Id) ? lookups.get('PricebookEntry' + this.product2Id) : null,
                NumeroPedidoCliente__c          = this.numeroPedidoCliente,
                Product2Id                      = lookups.containsKey('Product2Id' + this.product2Id) ? lookups.get('Product2Id' + this.product2Id) : null,
                Cultura__c                      = lookups.containsKey('Cultura__c' + this.culturaId) ? lookups.get('Cultura__c' + this.culturaId) : null,
                LocalNegocio__c                 = lookups.containsKey('LocalNegocio__c' + this.localNegocioId) ? lookups.get('LocalNegocio__c' + this.localNegocioId) : null,
                Itinerario__c                   = lookups.containsKey('Itinerario__c' + this.itinerarioId) ? lookups.get('Itinerario__c' + this.itinerarioId) : null,
                DataEntrega__c                  = this.dataEntrega,
                Quantity                        = this.quantidade,
                QuantidadeConfirmada__c         = this.quantidadeConfirmada,
                PrecoLista__c                   = this.precoLista,
                ValorJuros__c                   = this.valorJuros,
                PrecoVendaSemJuros__c           = this.precoVendaSemJuros,
                PrecoListaReferencia__c         = this.precoListaReferencia,
                Unidade__c                      = this.unidade,
                SaldoLitros__c                  = this.saldoLitros,
                DataFaturamento__c              = this.dataFaturamento,
                StatusGlobalItem__c             = this.StatusFaturamento,
                MotivoRecusaItem__c             = this.motivoRecusaItem,
                // StatusSAP__c                    = this.statusSAP,
                StatusFornecItem__c             = this.statusFornecItem,
                BloqueioDocumentoFaturamento__c = this.bloqueioDocumentoFaturamento,
                NrItem__c                       = this.nrItem,
                NumeroRemessa__c                = String.join((this.numeroRemessa != null ? this.numeroRemessa : new List<String>()), '\n'),
                //NumeroRemessa__c                = this.numeroRemessa,
                DataRemSolicitReal__c           = this.dataRemSolictReal,
                QuantidadeFornecida__c          = this.quantidadeFornecida,
                SaldoFornecer__c                = this.saldoFornecer,
                DataInicioExpedicao__c          = this.dataInicioExpedicao,
                ValorUnitarioComJuros__c        = this.salesforcePrice,
                ValorTotal__c                   = IntegrationUtils.checkDecimal(this.quantidade) * IntegrationUtils.checkDecimal(this.salesforcePrice),
                ValorTotalComJuros__c           = IntegrationUtils.checkDecimal(this.quantidade) * IntegrationUtils.checkDecimal(this.salesforcePrice),
                QuantidadeTotal__c              = this.quantity,
                LinhaDivisaoRemessa__c          = this.linhaDivisaoRemessa,
                DescontoConcedido__c            = this.descontoConcedido != null ? this.descontoConcedido.setScale(3, System.RoundingMode.DOWN) : 0,
                Litros__c                       = this.litros
            );
            if(this.ProgramacaoId != null){
                ordItem.ProgramacaoEntrega__c = lookups.containsKey('ProgramacaoEntrega__c' + this.ProgramacaoId) ? lookups.get('ProgramacaoEntrega__c' + this.ProgramacaoId) : null;
            }
            return ordItem;
        }

        public OrderItemINData generateCopy(OrderItemINData orderItemINData) {
            OrderItemINData oi = new OrderItemINData();
            oi.sfId                         = orderItemINData.sfId;
            oi.product2Id                   = orderItemINData.product2Id;
            oi.descontoConcedido         = orderItemINData.descontoConcedido;
            oi.numeroPedidoCliente          = orderItemINData.numeroPedidoCliente;
            oi.culturaId                    = orderItemINData.culturaId;
            oi.localNegocioId               = orderItemINData.localNegocioId;
            oi.ProgramacaoId                = orderItemINData.ProgramacaoId;
            // oi.dataEntrega                  = orderItemINData.dataEntrega;
            // oi.quantity                     = orderItemINData.quantity;
            // oi.quantidadeConfirmada         = orderItemINData.quantidadeConfirmada;
            oi.precoLista                   = orderItemINData.precoLista;
            oi.valorJuros                   = orderItemINData.valorJuros;
            oi.precoVendaSemJuros           = orderItemINData.precoVendaSemJuros;
            oi.precoListaReferencia         = orderItemINData.precoListaReferencia;
            oi.unidade                      = orderItemINData.unidade;
            oi.saldoLitros                  = orderItemINData.saldoLitros;
            // oi.dataFaturamento              = orderItemINData.dataFaturamento;
            oi.StatusFaturamento             = orderItemINData.StatusFaturamento;
            oi.motivoRecusaItem             = orderItemINData.motivoRecusaItem;
            oi.statusSAP                    = orderItemINData.statusSAP;
            oi.statusFornecItem             = orderItemINData.statusFornecItem;
            oi.bloqueioDocumentoFaturamento = orderItemINData.bloqueioDocumentoFaturamento;
            oi.nrItem                       = orderItemINData.nrItem;
            oi.numeroRemessa                = orderItemINData.numeroRemessa;
            oi.dataRemSolictReal            = orderItemINData.dataRemSolictReal;
            oi.quantidadeFornecida          = orderItemINData.quantidadeFornecida;
            oi.saldoFornecer                = orderItemINData.saldoFornecer;
            // oi.dataInicioExpedicao          = orderItemINData.dataInicioExpedicao;
            oi.salesforcePrice              = orderItemINData.salesforcePrice;
            oi.itinerarioId                 = orderItemINData.itinerarioId;
            oi.schedules                    = orderItemINData.schedules;
            oi.quantity                     = orderItemINData.quantity;
            oi.StatusFaturamento            = orderItemINData.StatusFaturamento;
            oi.litros                       = orderItemINData.litros;
            return oi;
        }

        public OrderItemINData[] sapToSalesforce(ScheduleSAPIN[] schedules, String sapId) {
            OrderItemINData[] orderItemINDataList = new List<OrderItemINData>();
            if(schedules != null){
                for (ScheduleSAPIN sch : schedules) {

                    OrderItemINData oi = generateCopy(this);

                    oi.linhaDivisaoRemessa = sch.scheduleNumber;
                    oi.dataEntrega = sch.scheduleDate;
                    if(sch.quantity != 0)
                        oi.quantidade = sch.quantity;
                    else{
                        oi.quantity = this.quantity;
                        oi.quantidade = this.quantity;
                    }
                    oi.quantidadeConfirmada = sch.confirmedQuantity;
                    oi.dataInicioExpedicao = sch.expeditionDate;
                    oi.dataFaturamento = sch.invoiceDate;
                    oi.ovSAPID = sapId;

                    orderItemINDataList.add(oi);
                }
            }else{
                OrderItemINData oi = generateCopy(this);
                oi.quantity = this.quantity;
                oi.linhaDivisaoRemessa = '1';
                oi.quantidade = this.quantity;
                oi.ovSAPID = sapId;
                orderItemINDataList.add(oi);
            }
            return orderItemINDataList;
        }


        public void setStatusSAP(Order currentOrd){            
            if(this.statusFaturamento == 'B' || this.statusFaturamento == 'C' ){
                this.statusSAP = (this.statusFaturamento == 'B' ?  'Faturado Parcial' : (this.statusFaturamento == 'C' ? 'Faturado' : ''));
            }else{            
                //Status Bloqueio Remessa
                if(!String.isBlank(currentOrd.BloqueioRemessa__c)){
                    if(this.saldoFornecer != 0){
                        this.statusSAP = 'Bloqueio de Remessa';
                    }else if(this.numeroRemessa != null && (!this.numeroRemessa.isEmpty() && !String.isBlank(this.numeroRemessa[0]))){
                        this.statusSAP = 'Em Remessa';
                    }
                }else if(!String.isBlank(this.motivoRecusaItem)){
                    if(this.saldoFornecer != 0){
                        this.statusSAP = 'Cancelado';
                    }
                }else if(this.numeroRemessa != null && (!this.numeroRemessa.isEmpty() && !String.isBlank(this.numeroRemessa[0]))){
                    this.statusSAP = 'Em Remessa';
                }else if (this.quantidadeConfirmada != null){
                    if (this.quantidadeConfirmada == 0){
                        this.statusSAP = 'Produto Indisponível';
                    }
                    else if (this.quantidadeConfirmada == this.quantidade){
                        this.statusSAP = 'Confirmado';
                    }
                    else if (this.quantidadeConfirmada < this.quantidade){
                        this.statusSAP = 'Confirmado Parcial';
                    }
                }
            }
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            OrderItemINData nObj = (OrderItemINData)obj;
            List<String> listToReturn = new List<String>{
                'NrItem__c',
                //'NumeroRemessa__c',
                'Product2Id',
                //'Cultura__c',
                'LocalNegocio__c',
                'Unidade__c',
                'SaldoLitros__c',
                // 'StatusSAP__c',
                'QuantidadeTotal__c'
            };
            if(nObj.orderData != null && nObj.orderData.orderType != 'CRB'){
                listToReturn.add('LinhaDivisaoRemessa__c');
                listToReturn.add('Quantity');
                listToReturn.add('DataEntrega__c');
                listToReturn.add('QuantidadeConfirmada__c');
                listToReturn.add('DataFaturamento__c');
                listToReturn.add('DataInicioExpedicao__c');
                listToReturn.add('PrecoLista__c');
                listToReturn.add('ValorJuros__c');
                listToReturn.add('PrecoVendaSemJuros__c');
                listToReturn.add('PrecoListaReferencia__c');
            }
            if (!String.isBlank(nObj.StatusFaturamento)) {
                listToReturn.add('StatusGlobalItem__c');
            }
            if (!String.isBlank(nObj.statusFornecItem)) {
                listToReturn.add('StatusFornecItem__c');
            }
            if (!String.isBlank(nObj.bloqueioDocumentoFaturamento)) {
                listToReturn.add('BloqueioDocumentoFaturamento__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'NumeroPedidoCliente__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }

    }

    global class ScheduleSAPIN {
        
        public String  scheduleNumber;
        public Date    scheduleDate;
        public Integer quantity;
        public Integer confirmedQuantity;
        public Date    expeditionDate;
        public Date    invoiceDate;

    }

    global class OrderOUTData {

        transient public String sapId;
        public String sfId;
        public String docType;
        public String salesOrg;
        public String distrChan;
        public String division;
        public String salesOff;
        public String purchNoC;
        public String fixValDy;
        public String ordReason;
        public String pmnttrms;
        public String priceDate;
        public String name;
        public String custGrp1;
        public TextData text;
        public String REQ_DATE_H;
        public String PYMT_METH;
        public String priceList;
        public Date pricingDate;
        public String salesDist;
        public String observacaoNF;
        public String observacaoLogistica;
        public String observacaoInterna;
        transient public PartnersData partners;
        transient public OrderItemOUTData[] items;

        public OrderOUTData() {
        }

        public OrderOUTData(Order order, List<OrderItem> items, Map<String, String> metadataMap) {
            this.sapId               = order.OVSAP__c;
            this.sfId                = order.Id;
            this.docType             = metadataMap.containsKey(order.TipoOrdem__c) ? metadataMap.get(order.TipoOrdem__c) : order.Opportunity.TipoOrdem__c;
            this.salesOrg            = order.OrganizacaoVendas__c;
            this.distrChan           = order.CanalDistribuicao__c;
            this.division            = metadataMap.containsKey(order.SetorAtividade__c) ? metadataMap.get(order.SetorAtividade__c) : order.SetorAtividade__c;
            this.salesOff            = order.Territorio__r.Diretor__r.BusinessPartnerSAP__c;
            this.priceList           = order.ListaPreco__c;
            this.purchNoC            = order.PedidoCliente__c;
            this.fixValDy            = IntegrationUtils.dateToStringSAP(order.DataInicioJuros__c);
            this.ordReason           = order.MotivoOrdem__c;
            this.pmnttrms            = order.CondicaoPagamento__r.ExternalId__c;
            this.priceDate           = IntegrationUtils.dateToStringSAP(order.Opportunity.DataReferenciaPreco__c);
            this.name                = order.Opportunity.NumeroOportunidade__c;
            this.custGrp1            = order.Agenciamento__c == true ? 'AGE' : ' ';
            this.text                = new TextData(order.Description);
            this.pricingDate         = order.DataFixacaoPreco__c;
            this.salesDist            = order.Regional__r.ExternalId__c;
            this.REQ_DATE_H          = items.isEmpty() ? null : IntegrationUtils.dateToStringSAP(items[0].DataEntrega__c);
            this.PYMT_METH           = (order.Opportunity.ClassificacaoVenda__c.contains('Barter') ? 'L' : null);
            this.observacaoNF        = order.opportunity.observacaoImpressaNF__c;
            this.observacaoLogistica = order.opportunity.observacaoLogistica__c;
            this.observacaoInterna   = order.opportunity.observacaoInterna__c + '\n'+ order.Opportunity.DescricaoCampanha__c;

            this.partners = new PartnersData();
            partners.orderIssuer     = order.Account.ExternalId__c;
            partners.recipient       = order.RecebedorMercadoria__r.ExternalId__c;
            partners.territory       = order.Territorio__r.ExternalId__c;
            partners.vendor          = order.RTV__r.BusinessPartnerSAP__c;
            partners.regionalManager = order.GerenteRegional__r.BusinessPartnerSAP__c;
            partners.agency          = order.ClienteAgenciador__r.ExternalId__c;

            this.items = new List<OrderItemOUTData>();
            for (Integer i = 0; i < items.size(); i++) {
                this.items.add(new OrderItemOUTData(order, items[i], i));
            }
        }
    }

    global class OrderItemOUTData {

        public String itmNumber;
        public String itmNumberSF;
        public String purchNoS;
        public String material;
        public String prcGroup1;
        public String plant;
        public String route;
        public String text;
        public Schedule schedule;
        public ConditionsData[] conditions;

        public OrderItemOUTData() {
        }

        public OrderItemOUTData(Order order, OrderItem item, Integer iteration) {
            this.itmNumber   = ((iteration + 1) + '0');
            this.itmNumberSF = item.Id;
            this.purchNoS    = item.NumeroPedidoCliente__c;
            this.material    = item.Product2.ExternalId__c;
            this.prcGroup1   = item.Cultura__r.ExternalId__c;
            this.plant       = item.LocalNegocio__r.Codigo__c;
            this.route       = order.Itinerario__r.ExternalId__c;
            this.schedule    = new Schedule(
                IntegrationUtils.dateToStringSAP(item.DataEntrega__c),
                String.valueOf(IntegrationUtils.stringToDecimal(String.valueOf(item.QuantidadeTotal__c == 0? item.quantity : item.quantidadeTotal__c)))
            );

            String convertedCurrency = order.Moeda__c;
            Decimal convertedValorUnitarioComJuros = item.ValorUnitarioComJuros__c;
            Decimal convertedPrecoLista = item.PrecoLista__c;
            Decimal convertedValorJuros = item.ValorJuros__c;
            Decimal convertedPrecoVendaSemJuros = item.PrecoVendaSemJuros__c;
            Decimal convertedPrecoListaReferencia = item.PrecoListaReferencia__c;

            if (order.CanalDistribuicao__c == '10' && order.Moeda__c == 'USD' && order.ListaPreco__c != 'Z4') {
                convertedCurrency = 'BRL';
                convertedValorUnitarioComJuros = item.ValorUnitarioComJuros__c * order.TaxaMedia__c;
                convertedPrecoLista = item.PrecoLista__c * order.taxaMedia__c;
                convertedValorJuros = item.ValorJuros__c * order.taxaMedia__c;
                convertedPrecoVendaSemJuros = item.PrecoVendaSemJuros__c * order.taxaMedia__c;
                convertedPrecoListaReferencia = item.PrecoListaReferencia__c * order.taxaMedia__c;
            }
            
            this.conditions = new List<ConditionsData>{
                new ConditionsData('ZS01', checkDecimal(convertedPrecoLista), convertedCurrency),
                new ConditionsData('ZS02', checkDecimal(convertedValorJuros), convertedCurrency),
                new ConditionsData('ZS03', checkDecimal(convertedPrecoVendaSemJuros), convertedCurrency),
                new ConditionsData('ZS04', checkDecimal(convertedPrecoListaReferencia), convertedCurrency),
                new ConditionsData('ZS05', item.DescontoConcedido__c * 10, order.Moeda__c),
                new ConditionsData('Z006', checkDecimal(convertedValorUnitarioComJuros), convertedCurrency)
            };
        }
        
        public Decimal checkDecimal(Decimal value){
            return value == null ? value : value.setScale(2);
        }
    }
    
    global class Schedule {

        public String reqDate;
        public String reqQty;

        public Schedule(String reqDate, String reqQty) {
            this.reqDate = reqDate;
            this.reqQty = reqQty;
        }

    }

    global class ConditionsData {

        public String condType;
        public Decimal condValue;
        public String currencyType;

        public ConditionsData(String condType, Decimal condValue, String currencyType) {
            this.condType  = condType;
            this.condValue = condValue;
            this.currencyType  = currencyType;
        }

    }

    global class PoliticaDescontoINData implements FieldData {

        public String externalId;
        public String organizacaoVenda;
        public String territorioId;
        public String hierarquiaClienteId;
        public String accountId;
        public String regionalId;
        public String productId;
        public Decimal maximo;
        public Decimal minimo;
        public Decimal recomendado;
        public Date dataVigenciaInicial;
        public Date dataVigenciaFim;

        public PoliticaDescontoINData() {
        }

        public PoliticaDescontoINData(PoliticaDesconto__c politicaDesconto, Map<Id, String> lookups) {
            this.externalId          = politicaDesconto.ExternalId__c;
            this.organizacaoVenda    = politicaDesconto.OrganizacaoVenda__c;
            this.territorioId        = lookups.containsKey(politicaDesconto.Territorio__c) ? lookups.get(politicaDesconto.Territorio__c) : null;
            this.hierarquiaClienteId = lookups.containsKey(politicaDesconto.Hierarquia__c) ? lookups.get(politicaDesconto.Hierarquia__c) : null;
            this.accountId           = lookups.containsKey(politicaDesconto.Conta__c) ? lookups.get(politicaDesconto.Conta__c) : null;
            this.regionalId          = lookups.containsKey(politicaDesconto.Regional__c) ? lookups.get(politicaDesconto.Regional__c) : null;
            this.productId           = lookups.containsKey(politicaDesconto.Produto__c) ? lookups.get(politicaDesconto.Produto__c) : null;
            this.maximo              = politicaDesconto.Maximo__c;
            this.minimo              = politicaDesconto.Minimo__c;
            this.recomendado         = politicaDesconto.Recomendado__c;
            this.dataVigenciaInicial = politicaDesconto.DataVigenciaInicial__c;
            this.dataVigenciaFim     = politicaDesconto.DataVigenciaFinal__c;
        }

        public PoliticaDesconto__c serialize(Map<String, Id> lookups) {
            return new PoliticaDesconto__c(
                ExternalId__c          = this.externalId,
                OrganizacaoVenda__c    = this.organizacaoVenda,
                Territorio__c          = lookups.containsKey('Territorio__c' + this.territorioId) ? lookups.get('Territorio__c' + this.territorioId) : null,
                Hierarquia__c          = lookups.containsKey('Hierarquia__c' + this.hierarquiaClienteId) ? lookups.get('Hierarquia__c' + this.hierarquiaClienteId) : null,
                Conta__c               = lookups.containsKey('Conta__c' + this.accountId) ? lookups.get('Conta__c' + this.accountId) : null,
                Regional__c            = lookups.containsKey('Regional__c' + this.regionalId) ? lookups.get('Regional__c' + this.regionalId) : null,
                Produto__c             = lookups.containsKey('Produto__c' + this.productId) ? lookups.get('Produto__c' + this.productId) : null,
                Maximo__c              = this.maximo,
                Minimo__c              = this.minimo,
                Recomendado__c         = this.recomendado,
                DataVigenciaInicial__c = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaInicial)),
                DataVigenciaFinal__c   = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaFim))
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            PoliticaDescontoINData nObj = (PoliticaDescontoINData)obj;
            List<String> listToReturn = new List<String>{
                'ExternalId__c',
                'OrganizacaoVenda__c',
                'Produto__c',
                'Maximo__c',
                'Minimo__c',
                'Recomendado__c',
                'DataVigenciaInicial__c',
                'DataVigenciaFinal__c'
            };
            if (!String.isBlank(nObj.territorioId)) {
                listToReturn.add('Territorio__c');
            }
            if (!String.isBlank(nObj.hierarquiaClienteId)) {
                listToReturn.add('Hierarquia__c');
            }
            if (!String.isBlank(nObj.accountId)) {
                listToReturn.add('Conta__c');
            }
            if (!String.isBlank(nObj.regionalId)) {
                listToReturn.add('Regional__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class Product2INData implements FieldData {

        public String externalId;
        public String name;
        public String descricao;
        public String sku;
        public Integer multiplicidade;
        public Decimal litragem;
        public String tipoProduto;
        public String family;
        public String subFamily;
        public String maraMTART;
        public Integer ipi;
        public String embalagem;
        public String produtoSubstituto;
        public Boolean isActive;
        // public List<String> atributoRestricao;
        public Boolean sulfur;
        public Boolean rizotec;
        public Boolean stimulate;
        public Boolean naturOleo;
        public Boolean trianum;
        public Boolean naturalOleo;
        public Boolean Atributo7;
        public Boolean Atributo8;
        public Boolean Atributo9;
        public Boolean Atributo10;
        public String classificacaoProduto;
        // public List<String> culturaIds;

        public Product2INData() {
        }

        public Product2INData(Product2 product, Map<Id, String> lookups, List<String> atributoDefensivos) {
            this.externalId           = product.ExternalId__c;
            this.name                 = product.Name;
            this.descricao            = product.Description;
            this.multiplicidade       = Integer.valueOf(product.Multiplicidade__c);
            this.litragem             = product.Litragem__c;
            this.tipoProduto          = product.Tipo__c;
            this.family               = product.Family;
            this.subFamily            = product.SubFamily__c;  
            this.maraMTART            = product.TipoDeMaterial__c;
            //this.ipi                  = Integer.valueOf(product.IPI__c);
            this.embalagem            = product.Embalagem__c;
            this.produtoSubstituto    = lookups.containsKey(product.ProdutoSubstituto__c) ? lookups.get(product.ProdutoSubstituto__c) : null;
            this.isActive             = product.IsActive;
            this.classificacaoProduto = product.ClassificacaoProduto__c;
            this.sulfur               = product.sulfur__c;
            this.rizotec              = product.rizotec__c;
            this.stimulate            = product.stimulate__c;
            this.naturOleo            = product.naturOleo__c;
            this.trianum              = product.trianum__c;
            this.naturalOleo          = product.naturalOleo__c;
            this.Atributo7            = product.Atributo7__c;
            this.Atributo8            = product.Atributo8__c;
            this.Atributo9            = product.Atributo9__c;
            this.Atributo10           = product.Atributo10__c;
            // this.atributoRestricao    = new List<String>(atributoDefensivos);
        }

        public Product2 serialize(Map<String, Id> lookups) {
            return new Product2(
                ExternalId__c           = this.externalId,
                Name                    = this.name,
                Description             = this.descricao,
                SKU__c                  = this.externalId,
                ProductCode             = this.externalId,
                Multiplicidade__c       = this.multiplicidade,
                Litragem__c             = this.litragem,
                Tipo__c                 = this.tipoProduto,
                Family                  = this.family,
                SubFamily__c            = this.subFamily,
                TipoDeMaterial__c       = this.maraMTART,
                //IPI__c                  = this.ipi,
                IsActive                = this.isActive,
                Embalagem__c            = this.embalagem,
                ProdutoSubstituto__c    = lookups.containsKey('Product2' + this.produtoSubstituto) ? lookups.get('Product2' + this.produtoSubstituto) : null,
                ClassificacaoProduto__c = this.classificacaoProduto,
                sulfur__c               = this.sulfur,
                rizotec__c              = this.rizotec,
                stimulate__c            = this.stimulate,
                naturOleo__c            = this.naturOleo,
                trianum__c              = this.trianum,
                naturalOleo__c          = this.naturalOleo,
                Atributo7__c            = this.Atributo7,
                Atributo8__c            = this.Atributo8,
                Atributo9__c            = this.Atributo9,
                Atributo10__c           = this.Atributo10
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            Product2INData nObj = (Product2INData)obj;
            List<String> listToReturn = new List<String>{
                'ExternalId__c',
                'Name',
                'Description',
                'Multiplicidade__c',
                'Embalagem__c'
            };
            if (!String.isBlank(nObj.family)) {
                listToReturn.add('Family');
            }
            if (!String.isBlank(nObj.produtoSubstituto)) {
                listToReturn.add('ProdutoSubstituto__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class RegionalINData implements FieldData {

        public String externalId;
        public String nomeRegional;

        public RegionalINData() {
        }

        public RegionalINData(Regional__c regional) {
            this.externalId    = regional.ExternalId__c;
            this.nomeRegional  = regional.NomeRegional__c;
        }

        public Regional__c serialize(Map<String, Id> lookups) {
            return new Regional__c(
                ExternalId__c    = this.externalId,
                NomeRegional__c  = this.nomeRegional
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'NomeRegional__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }
	
	global class TabelaFreteINData implements FieldData {

        public String externalId;
        public String organizacaoVenda;
        public String regiaoUF;
        public String tipoFrete;
        public Decimal frete;
        public Date dataVigenciaInicial;
        public Date dataVigenciaFinal;
        public String localNegocioId;

        public TabelaFreteINData() {
        }

        public TabelaFreteINData(TabelaFrete__c tabelaFrete, Map<Id, String> lookups) {
            this.externalId           = tabelaFrete.IdSAP__c;
            this.organizacaoVenda     = tabelaFrete.OrganizacaoVenda__c;
            this.regiaoUF             = tabelaFrete.RegiaoUF__c;
            this.tipoFrete            = tabelaFrete.TipoFrete__c;
            this.frete                = tabelaFrete.Frete__c;
            this.dataVigenciaInicial  = tabelaFrete.DataVigenciaInicial__c;
            this.dataVigenciaFinal    = tabelaFrete.DataVigenciaFinal__c;
            this.localNegocioId       = lookups.containsKey(tabelaFrete.LocalNegocio__c) ? lookups.get(tabelaFrete.LocalNegocio__c) : null;
        }

        public TabelaFrete__c serialize(Map<String, Id> lookups) {
            return new TabelaFrete__c(
                IdSAP__c               = this.externalId,
                OrganizacaoVenda__c    = this.organizacaoVenda,
                RegiaoUF__c            = this.regiaoUF,
                TipoFrete__c           = this.tipoFrete,
                Frete__c               = this.frete,
                DataVigenciaInicial__c = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaInicial)),
                DataVigenciaFinal__c   = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaFinal)),
                LocalNegocio__c        = lookups.containsKey('LocalNegocio__c' + this.localNegocioId) ? lookups.get('LocalNegocio__c' + this.localNegocioId) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'IdSAP__c',
                'RegiaoUF__c',
                'TipoFrete__c',
                'Frete__c',
                'DataVigenciaInicial__c',
                'DataVigenciaFinal__c',
                'LocalNegocio__c'
            };
        }

        public String getFieldKey() {
            return 'IdSAP__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }
    
    global class VigenciaTabelaFreteINData implements FieldData {
        
        public String externalId;
        public String tabelaExternal;
        public Decimal frete;
        public Date dataVigenciaDe;
        public Date dataVigenciaAte;

        public VigenciaTabelaFreteINData() {
        }

        public VigenciaTabelaFreteINData(TabelaFreteInData tabelaFrete) {
            this.externalId               = tabelaFrete.externalId;
            this.frete                    = tabelaFrete.frete;
            this.dataVigenciaDe           = tabelaFrete.dataVigenciaInicial;
            this.dataVigenciaAte          = tabelaFrete.dataVigenciaFinal;
            this.tabelaExternal           = tabelaFrete.externalId;
        }

        public VigenciaTabelaFreteINData(VigenciaTabelaFrete__c vigencia) {
            this.externalId               = vigencia.ExternalId__c;
            this.frete                    = vigencia.Frete__c;
            this.dataVigenciaDe           = vigencia.DataVigenciaDe__c;
            this.dataVigenciaAte          = vigencia.DataVigenciaAte__c;
            this.tabelaExternal           = vigencia.TabelaFrete__r.IdSap__C;
        }

        public VigenciaTabelaFrete__c serialize(Map<String, Id> lookups) {
            // System.debug(lookups.get('TabelaFrete__c'+this.tabelaExternal));
            return new VigenciaTabelaFrete__c(
                ExternalId__c               = this.tabelaExternal,
                Frete__c                    = this.frete,
                DataVigenciaDe__c           = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaDe)),
                DataVigenciaAte__c          = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaAte)),
                TabelaFrete__c              = lookups.get('TabelaFrete__c'+this.tabelaExternal)
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'Frete__c',
                'DataVigenciaDe__c',
                'DataVigenciaAte__c',
                'TabelaFrete__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class TabelaPrecoINData implements FieldData {

        public String externalId;
        public String tabelaPreco;
        public String organizacaoVenda;
        public String listaPreco;
        public String hierarquiaClienteId;
        public String clienteId;
        public String regionalId;
        public String tipoCliente;
        public Decimal valor;
        public Date dataVigenciaInicial;
        public Date dataVigenciaFim;
        public String product2Id;

        public TabelaPrecoINData() {
        }

        public TabelaPrecoINData(TabelaPreco__c tabelaPreco, Map<Id, String> lookups) {
            this.externalId          = tabelaPreco.ExternalId__c;
            this.tabelaPreco         = tabelaPreco.TabelaPreco__c;
            this.organizacaoVenda    = tabelaPreco.OrganizacaoVenda__c;
            this.listaPreco          = tabelaPreco.ListaPreco__c;
            this.hierarquiaClienteId = lookups.containsKey(tabelaPreco.HierarquiaCliente__c) ? lookups.get(tabelaPreco.HierarquiaCliente__c) : null;
            this.clienteId           = lookups.containsKey(tabelaPreco.Cliente__c) ? lookups.get(tabelaPreco.Cliente__c) : null;
            this.regionalId          = lookups.containsKey(tabelaPreco.Regional__c) ? lookups.get(tabelaPreco.Regional__c) : null;
            this.tipoCliente         = tabelaPreco.TipoCliente__c;
            this.valor               = tabelaPreco.Valor__c;
            this.dataVigenciaInicial = tabelaPreco.DataVigenciaInicial__c;
            this.dataVigenciaFim     = tabelaPreco.DataVigenciaFim__c;
            this.product2Id          = lookups.containsKey(tabelaPreco.Produto__c) ? lookups.get(tabelaPreco.Produto__c) : null;
        }

        public TabelaPreco__c serialize(Map<String, Id> lookups) {
            return new TabelaPreco__c(
                ExternalId__c          = this.externalId,
                TabelaPreco__c         = this.tabelaPreco,
                OrganizacaoVenda__c    = this.organizacaoVenda,
                ListaPreco__c          = this.listaPreco,
                HierarquiaCliente__c   = lookups.containsKey('HierarquiaCliente__c' + this.hierarquiaClienteId) ? lookups.get('HierarquiaCliente__c' + this.hierarquiaClienteId) : null,
                Cliente__c             = lookups.containsKey('Cliente__c' + this.clienteId) ? lookups.get('Cliente__c' + this.clienteId) : null,
                Regional__c            = lookups.containsKey('Regional__c' + this.regionalId) ? lookups.get('Regional__c' + this.regionalId) : null,
                TipoCliente__c         = this.tipoCliente,
                Valor__c               = this.valor,
                DataVigenciaInicial__c = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaInicial)),
                DataVigenciaFim__c     = IntegrationUtils.stringToDate(String.valueOf(this.dataVigenciaFim)),
                Produto__c             = lookups.containsKey('Produto__c' + this.product2Id) ? lookups.get('Produto__c' + this.product2Id) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            TabelaPrecoINData nObj = (TabelaPrecoINData)obj;
            List<String> listToReturn = new List<String>{
                'ExternalId__c',
                'TabelaPreco__c',
                'OrganizacaoVenda__c',
                'ListaPreco__c',
                'Valor__c',
                'DataVigenciaInicial__c',
                'DataVigenciaFim__c',
                'Produto__c'
            };
            if (!String.isBlank(nObj.hierarquiaClienteId)) {
                listToReturn.add('HierarquiaCliente__c');
            }
            if (!String.isBlank(nObj.clienteId)) {
                listToReturn.add('Cliente__c');
            }
            if (!String.isBlank(nObj.regionalId)) {
                listToReturn.add('Regional__c');
            }
            if (!String.isBlank(nObj.tipoCliente)) {
                listToReturn.add('TipoCliente__c');
            }
            return listToReturn;
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class TerritorioINData implements FieldData {

        public String externalId;
        public String nomeTerritorio;
        public String codigoBPRtv;
        public String emailRtv;
        public String codigoBPGerente;
        public String emailGerente;
        public String codigoBPDiretor;
        public String regionalId;

        public TerritorioINData() {
        }

        public TerritorioINData(Territorio__c territorio, Map<Id, String> lookups) {
            this.externalId      = territorio.ExternalId__c;
            this.nomeTerritorio  = territorio.NomeTerritorio__c;
            this.codigoBPRtv     = territorio.Diretor__c;
            this.emailRtv        = lookups.containsKey(territorio.RTV__c) ? lookups.get(territorio.RTV__c) : null;
            this.codigoBPGerente = territorio.Gerente__c;
            this.emailGerente    = lookups.containsKey(territorio.Gerente__c) ? lookups.get(territorio.Gerente__c) : null;
            this.codigoBPDiretor = lookups.containsKey(territorio.Diretor__c) ? lookups.get(territorio.Diretor__c) : null;
            this.regionalId      = lookups.containsKey(territorio.Regional__c) ? lookups.get(territorio.Regional__c) : null;
        }

        public Territorio__c serialize(Map<String, Id> lookups) {
            return new Territorio__c(
                ExternalId__c     = this.externalId,
                NomeTerritorio__c = this.nomeTerritorio,
                RTV__c            = lookups.containsKey('RTV__c' + this.emailRtv) ? lookups.get('RTV__c' + this.emailRtv) : null,
                Gerente__c        = lookups.containsKey('Gerente__c' + this.emailGerente) ? lookups.get('Gerente__c' + this.emailGerente) : null,
                Diretor__c        = lookups.containsKey('Diretor__c' + this.codigoBPDiretor) ? lookups.get('Diretor__c' + this.codigoBPDiretor) : null,
                Regional__c       = lookups.containsKey('Regional__c' + this.regionalId) ? lookups.get('Regional__c' + this.regionalId) : null
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'NomeTerritorio__c',
                'RTV__c',
                'Gerente__c',
                'Diretor__c',
                'Regional__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class ZonaTransporteINData implements FieldData {
        
        public String externalId;
        public String descricao;

        public ZonaTransporteINData() {
        }

        public ZonaTransporteINData(ZonaTransporte__c zonaTransporte) {
            this.externalId = zonaTransporte.ExternalId__c;
            this.descricao  = zonaTransporte.Descricao__c;
        }

        public ZonaTransporte__c serialize(Map<String, Id> lookups) {
            return new ZonaTransporte__c(
                ExternalId__c = this.externalId,
                Name = this.externalID,
                Descricao__c  = this.descricao
            );
        }
        
        public List<String> getRequiredFields(FieldData obj) {
            return new List<String>{
                'ExternalId__c',
                'Descricao__c'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        
        public String getFieldId() {
            return 'Id';
        }
    }

    global class ResponseList {

        List<Response> response;

        public ResponseList(List<Response> response) {

            this.response = response;
            
        }
    }
    
    global virtual class Response {
        public String idSalesforce;
        public String codigoSap;
        public Boolean status;
        public String errorMessage;
        public String sObjectType;

        public Response () {
            this.errorMessage = '';
            this.status = true;
        }
        
        public virtual Response success(String idSalesforce, String codigoSap, String sObjectType) {
            this.idSalesforce = idSalesforce;
            this.codigoSap    = codigoSap;
            this.status       = true;
            this.SObjectType  = sObjectType;
            return this;
        }
        
        public virtual Response error(String codigoSap, String errorMessage, String sObjectType) {
            this.codigoSap    = codigoSap;
            this.status       = false;
            this.errorMessage += errorMessage;
            this.SObjectType  = sObjectType;
            return this;
        }

        public virtual Response error(String idSalesforce, String codigoSap, String errorMessage, String sObjectType) {
            this.idSalesforce = idSalesforce;
            this.codigoSap    = codigoSap;
            this.status       = false;
            this.errorMessage += errorMessage;
            this.SObjectType  = sObjectType;
            return this;
        }

        public virtual Response error(String errorMessage) {
            this.status       = false;
            this.errorMessage = errorMessage;
            return this;
        }
    }

    global class TextData {

        public String textLine;

        public TextData(String textLine) {
            this.textLine = textLine;
        }
    }

    global class PartnersData {

        public String orderIssuer;
        public String recipient;
        public String territory;
        public String vendor;
        public String regionalManager;
        public String agency;

    }

    global class ReturnedSAP {

        public DocumentSAP defaultResponse;
        public ScheduleSAP[] schedule;

    }

    global class DocumentSAP {

        public String document;
        public ResponseSAP[] response;

    }
    
    global class ResponseSAP {

        public String type;
        public String id;
        public String num;
        public String message;

    }

    global class ScheduleSAP {

        public String itmNumber;
        public String itmNumberSF;
        public String scheduleNumber;
        public Integer scheduleDate;
        public String quantity;
        public String confirmedQuantity;
        public Integer expeditionDate;
        public Integer invoiceDate;

    }

    public abstract class ExternalModel {

        public FieldData[] request;

        public ExternalModel() {
        }

        public ExternalModel(SObject[] sobjectList) {
        }

    }
}