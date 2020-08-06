public class GenerateExcelController {
    public Boolean isExport {get;set;}
    public String oppId {get;set;}
    public List<String> progIdSet {get;set;}
    public List<String> excelDataHeaderList{get;set;}
    public List<OppLineItemData> excelDataList {get;set;}
    public String xmlHeader {get;set;}
    public string endfile {get;set;}
    public string dateOutput {get;set;}
    private ApexPages.StandardController std;
    private Blob excelData;

    public GenerateExcelController(ApexPages.StandardController StandardController){
        excelDataList = new List<OppLineItemData>();
        xmlHeader = '<?xml version="1.0"?><?mso-application progId="Excel.Sheet"?>';
        endfile = '</WorkBook>';
        std = StandardController;
        oppId = ApexPages.currentPage().getParameters().get('Id');
        progIdSet = ApexPages.currentPage().getParameters().get('Pe').split(';');

        excelDataHeaderList = new List<String>{ 'Nr. da oportunidade',
                                                'Data de emissão',
                                                'Data de referencia do preço',
                                                'Local de Negócios',
                                                'Nr. da programação',
                                                'Tipo de ordem',
                                                'Lista de preços',
                                                'Condição de pagamento',
                                                'Data de inicio de Juros',
                                                'Vencimento',
                                                'Descrição da Campanha',
                                                'Nome do RTV',
                                                'Regional',
                                                'SKU',
                                                'Descrição do produto',
                                                'Quantidade',
                                                'Preço de venda',
                                                'Cultura',                        
                                                'Desconto / Acréscimo',
                                                'Data de entrega',
                                                'Data de faturamento',
                                                'Observação Logística',
                                                'Campos de observação'};
    }
    public void getExcelData(){
        Set<Id> itinerarioIdSet = new Set<Id>();
        Set<Id> oppLineItemSet = new Set<Id>();
        List<ProgramacaoEntrega__c> progrEntradaList = new List<ProgramacaoEntrega__c>();
        for(ProgramacaoEntrega__c progrEntrada : [SELECT id, Itinerario__c, IdOportunidade__r.NumeroOportunidade__c ,IdOportunidade__r.DataReferenciaPreco__c ,IdOportunidade__r.LocalNegocio__c ,IdOportunidade__r.LocalNegocio__r.Descricao__c ,IdOportunidade__r.CondicaoPagamento__c ,IdOportunidade__r.CondicaoPagamento__r.Descricao__c ,IdOportunidade__r.dataInicioJuros__c ,IdOportunidade__r.DataVencimento__c ,IdOportunidade__r.Campanha__c ,IdOportunidade__r.Campanha__r.Descricao__c ,IdOportunidade__r.NomeRTV__C ,IdOportunidade__r.Regional__c ,IdOportunidade__r.Regional__r.NomeRegional__c ,Produto__r.SKU__C ,Produto__r.Description ,Cultura__c ,Cultura__r.Descricao__c ,IdOportunidade__r.ObservacaoLogistica__c ,IdOportunidade__r.ObservacaoInterna__c ,IdOpportunityLineITem__c, EmissorOrdem__c, Name, TipoOrdem__c, EmissorOrdem__r.ListaPreco__c, QuantidadeProgramada__c, PrecoVendasComJurosUSDBRL__c,  DescontoConcedido__c,  DataEntrega__c,  DataFaturamento__c  FROM ProgramacaoEntrega__c WHERE Id IN : progIdSet]){
            progrEntradaList.add(progrEntrada);
            oppLineItemSet.add(progrEntrada.IdOpportunityLineITem__c);
        }

        Map<Id, OpportunityLineITem> idToOppLineMap = new Map<Id, OpportunityLineITem>([SELECT Id, Opportunity.NumeroOportunidade__c, Opportunity.DataReferenciaPreco__c, Opportunity.LocalNegocio__r.Descricao__c, Opportunity.CondicaoPagamento__r.Descricao__c, Opportunity.dataInicioJuros__c, Opportunity.DataVencimento__C, Opportunity.Campanha__r.Descricao__c, Opportunity.NomeRTV__C, Opportunity.Regional__r.NomeRegional__c, Opportunity.ObservacaoLogistica__c, Opportunity.ObservacaoInterna__c, Product2.SKU__C, Product2.Description, Cultura__r.Descricao__c  FROM OpportunityLineITem WHERE Id IN: oppLineItemSet]);

        for(ProgramacaoEntrega__c progrEntrada : progrEntradaList){
            OpportunityLineITem oppLineItem = (idToOppLineMap.containsKey(progrEntrada.IdOpportunityLineITem__c) ? idToOppLineMap.get(progrEntrada.IdOpportunityLineITem__c) : null);
            if(oppLineItem != null)
                excelDataList.add(new OppLineItemData(progrEntrada, oppLineItem));
            else
                excelDataList.add(new OppLineItemData(progrEntrada));

        }

    }
    public class OppLineItemData{

        public String NrOpp {get;set;}
        public String DataEmissao {get;set;}
        public String DataPreco {get;set;}
        public String LocalNeg {get;set;}
        public String NrProgr {get;set;}
        public String TipoOrdem {get;set;}
        public String ListaPreco {get;set;}
        public String CondiPagto {get;set;}
        public String DataJuros {get;set;}
        public String Vencimento {get;set;}
        public String Campanha {get;set;}
        public String NomeRTV {get;set;}
        public String Regional {get;set;}
        public String SKU {get;set;}
        public String Produto {get;set;}
        public String Quantidade {get;set;}
        public String PrecoVenda {get;set;}
        public String Cultura {get;set;}
        public String DescontoConcedido {get;set;}
        public String DataEntrega {get;set;}
        public String DataFaturamento {get;set;}
        public String ObservacaoLogistica {get;set;}
        public String CamposObservacao {get;set;}

        public OppLineItemData(ProgramacaoEntrega__c progrEntrada, OpportunityLineITem oppLineItem){
            this.NrOpp               = getEscapeVal(oppLineItem.Opportunity.NumeroOportunidade__c);
            this.DataEmissao         = getFormattedDate(Date.Today());
            this.DataPreco           = getFormattedDate(oppLineItem.Opportunity.DataReferenciaPreco__c);
            this.LocalNeg            = escapeValLookup(oppLineItem.Opportunity.LocalNegocio__c, String.valueOf(oppLineItem.Opportunity.LocalNegocio__r.Descricao__c));
            this.NrProgr             = getEscapeVal(progrEntrada.Name);
            this.TipoOrdem           = getEscapeVal(progrEntrada.TipoOrdem__c);
            this.ListaPreco          = escapeValLookup(progrEntrada.EmissorOrdem__c, progrEntrada.EmissorOrdem__r.ListaPreco__c);
            this.CondiPagto          = escapeValLookup(oppLineItem.Opportunity.CondicaoPagamento__c, oppLineItem.Opportunity.CondicaoPagamento__r.Descricao__c);
            this.DataJuros           = getFormattedDate(oppLineItem.Opportunity.dataInicioJuros__c);
            this.Vencimento          = getFormattedDate(oppLineItem.Opportunity.DataVencimento__c);
            this.Campanha            = escapeValLookup(oppLineItem.Opportunity.Campanha__c, oppLineItem.Opportunity.Campanha__r.Descricao__c);
            this.NomeRTV             = getEscapeVal(oppLineItem.Opportunity.NomeRTV__C);
            this.Regional            = escapeValLookup(oppLineItem.Opportunity.Regional__c, oppLineItem.Opportunity.Regional__r.NomeRegional__c);
            this.SKU                 = getEscapeVal(oppLineItem.Product2.SKU__C);
            this.Produto             = getEscapeVal(oppLineItem.Product2.Description);
            this.Quantidade          = getEscapeVal(String.valueOf(progrEntrada.QuantidadeProgramada__c));
            this.PrecoVenda          = getEscapeVal(String.valueOf(progrEntrada.PrecoVendasComJurosUSDBRL__c));
            this.Cultura             = escapeValLookup(oppLineItem.Cultura__c, oppLineItem.Cultura__r.Descricao__c);
            this.DescontoConcedido   = getEscapeVal(String.valueOf(progrEntrada.DescontoConcedido__c));
            this.DataEntrega         = getFormattedDate(progrEntrada.DataEntrega__c);
            this.DataFaturamento     = getFormattedDate(progrEntrada.DataFaturamento__c);
            this.ObservacaoLogistica = getEscapeVal(oppLineItem.Opportunity.ObservacaoLogistica__c);
            this.CamposObservacao    = getEscapeVal(oppLineItem.Opportunity.ObservacaoInterna__c);
        }
        public OppLineItemData(ProgramacaoEntrega__c progrEntrada){
            this.NrOpp               = getEscapeVal(progrEntrada.IdOportunidade__r.NumeroOportunidade__c);
            this.DataEmissao         = getFormattedDate(Date.Today());
            this.DataPreco           = getFormattedDate(progrEntrada.IdOportunidade__r.DataReferenciaPreco__c);
            this.LocalNeg            = escapeValLookup(progrEntrada.IdOportunidade__r.LocalNegocio__c, String.valueOf(progrEntrada.IdOportunidade__r.LocalNegocio__r.Descricao__c));
            this.NrProgr             = getEscapeVal(progrEntrada.Name);
            this.TipoOrdem           = getEscapeVal(progrEntrada.TipoOrdem__c);
            this.ListaPreco          = escapeValLookup(progrEntrada.EmissorOrdem__c, progrEntrada.EmissorOrdem__r.ListaPreco__c);
            this.CondiPagto          = escapeValLookup(progrEntrada.IdOportunidade__r.CondicaoPagamento__c, progrEntrada.IdOportunidade__r.CondicaoPagamento__r.Descricao__c);
            this.DataJuros           = getFormattedDate(progrEntrada.IdOportunidade__r.dataInicioJuros__c);
            this.Vencimento          = getFormattedDate(progrEntrada.IdOportunidade__r.DataVencimento__c);
            this.Campanha            = escapeValLookup(progrEntrada.IdOportunidade__r.Campanha__c, progrEntrada.IdOportunidade__r.Campanha__r.Descricao__c);
            this.NomeRTV             = getEscapeVal(progrEntrada.IdOportunidade__r.NomeRTV__C);
            this.Regional            = escapeValLookup(progrEntrada.IdOportunidade__r.Regional__c, progrEntrada.IdOportunidade__r.Regional__r.NomeRegional__c);
            this.SKU                 = getEscapeVal(progrEntrada.Produto__r.SKU__C);
            this.Produto             = getEscapeVal(progrEntrada.Produto__r.Description);
            this.Quantidade          = getEscapeVal(String.valueOf(progrEntrada.QuantidadeProgramada__c));
            this.PrecoVenda          = getEscapeVal(String.valueOf(progrEntrada.PrecoVendasComJurosUSDBRL__c));
            this.Cultura             = escapeValLookup(progrEntrada.Cultura__c, progrEntrada.Cultura__r.Descricao__c);
            this.DescontoConcedido   = getEscapeVal(String.valueOf(progrEntrada.DescontoConcedido__c));
            this.DataEntrega         = getFormattedDate(progrEntrada.DataEntrega__c);
            this.DataFaturamento     = getFormattedDate(progrEntrada.DataFaturamento__c);
            this.ObservacaoLogistica = getEscapeVal(progrEntrada.IdOportunidade__r.ObservacaoLogistica__c);
            this.CamposObservacao    = getEscapeVal(progrEntrada.IdOportunidade__r.ObservacaoInterna__c);
        }
        public string getEscapeVal(string value){
            return (value == null ? 'Vazio' : value);
        }
        public string escapeValLookup(Id lookup, string value){
            return (lookup == null ? 'Vazio' : getEscapeVal(value));
        }

        public String getFormattedDate(Date dt) {
            if (dt == null) {
                return 'Vazio';
            }
            return sSize(dt.day()) + '/' + sSize(dt.month()) + '/' + sSize(dt.year());
        }

        public String sSize(Decimal s) {
            String prefix = '';
            if (s < 10) {
                prefix = '0';
            }
            return prefix + s;
        }
    }
}