public with sharing class TemplateDefaultFields {
    
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

    public interface FieldDefaults { 
        Map<String, Object> getFieldDefaults();
    }

    public class AccountDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'           => GuidGenerator.generate(),
                'Name'                    => GuidGenerator.generate(),
                'ShippingPostalCode'      => 'ShippingPostalCode',
                'ShippingStreet'          => 'ShippingStreet',
                'ShippingCity'            => 'ShippingCity',
                'ShippingState'           => 'SP',
                'ShippingCountry'         => 'ShippingCountry',
                'BillingPostalCode'       => 'BillingPostalCode',
                'BillingStreet'           => 'BillingStreet',
                'BillingCity'             => 'BillingCity',
                'BillingState'            => 'BillingState',
                'BillingCountry'          => 'BillingCountry',
                'CodigoIBGE__c'           => 'testCodigoIBGE',
                'ListaPreco__c'           => 'Z1',
                'Filial__c'               => 'testFilial',
                'Status__c'               => 'Ativo',
                'Potencial__c'            => 10.00,
                'LimiteCreditoTotal__c'   => 10.00,
                'SaldoLimiteCredito__c'   => 10.00,
                'RatingPagamento__c'      => 'A',
                'PlanoIncentivos__c'      => 'testPlanoIncentivos',
                'EMailAprovacaoPedido__c' => 'test@test.com',
                'NomeFazenda__c'          => 'testNomeFazenda',
                'Suframa__c'              => 'testSuframa',
                'TipoCliente__c'          => 'ZC',
                'BlitzObrigatoria__c'     => true,
                'EMailComercial__c'       => 'test@test.com',
                'RestricaoTransporte__c'  => 'testRestricaoTransporte',
                'ContribuinteICMS__c'     => true,
                'DataUltimaCompra__c'     => Date.today(),
                'ValorUltimaCompra__c'    => 10.00,
                'Agenciamento__c'         => true,
                'CNPJ__c'                 => 'testCnpj',
                'CPF__c'                  => 'testCpf',
                'InscricaoMunicipal__c'   => 'InscricaoMunicipal',
                'InscricaoEstadual__c'    => 'InscricaoEstadua'
            };
        }
    }
    
    public class CampanhaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'DataInicioJuros__c'          => Date.today(),
                'DataVigenciaInicial__c'      => Date.today(),
                'DataVigenciaFinal__c'        => Date.today() + 10,
                'Descricao__c'                => 'Só hoje nas Casas Bahia',
                'Expirado__c'                 => false,
                'LiberadoUsoOportunidades__c' => true,
                'Moeda__c'                    => 'BRL',
                'Motivo__c'                   => 'test'
            };
        }
    }

    public class CancelamentoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'QuantidadeProgramada__c'    => 10,
                'ValorUnitario__c'           => 10.00,
                // 'Moeda__c'                   => 'BRL',
                'ValorTotal__c'              => 10.00,
                'Descricao__c'               => 'test',
                'DataEntrega__c'             => Date.today(),
                'QuantidadeProgramada__c'    => 10,
                'QuantidadeDisponivelSAP__c' => 10,
                'Status__c'                  => 'Liberado',
                'MotivoCancelamento__c'      => 'Solicitação da Stoller',
                'NomeRTV__c'                 => 'test',
                'TipoOrdem__c'               => 'Normal'
            };
        }
    }

    public class CondicaoPagamentoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'               => 'CR' + IntegrationUtils.randomNumber(2),
                'Descricao__c'                => 'testDescricao',
                'Moeda__c'                    => 'BRL',
                'JurosComercialFinanceiro__c' => 10.0,
                'DataVigenciaDe__c'           => Date.today() - 10,
                'DataVigenciaAte__c'          => Date.today() + 10,
                'Dias__c'                     => 20
            };
        }
    }

    public class CotacaoMoedaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c' => GuidGenerator.generate(),
                'Moeda__c'      => 'BRL',
                'Data__c'       => Date.today() - 1,
                'Taxa__c'       => 10.0000
            };
        }
    }

    public class CulturaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c' => GuidGenerator.generate(),
                'Descricao__c'  => 'Cultura - Teste'
            };
        }
    }

    public class DescontoTipoClienteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'IdSAP__c'               => GuidGenerator.generate(),
                'OrganizacaoVenda__c'    => '1000',
                'TipoCliente__c'         => 'ZC',
                'Desconto__c'            => 1.0,
                'DataVigenciaInicial__c' => Date.today() - 10,
                'DataVigenciaFinal__c'   => Date.today() + 10
            };
        }
    }

    public class EscoamentoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                // 'CNPJCPF__c'      => IntegrationUtils.randomNumber(18),
                'DataApuracao__c' => Date.today(),
                'Concluido__c'    => false
            };
        }
    }
    
    public class ItinerarioDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'    => GuidGenerator.generate(),
                'TipoExpedicao__c' => 'Fracionado',
                'Dias__c'          => 3
            };
        }
    }

    public class LancamentoContabilDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'           => GuidGenerator.generate(),
                'OrganizacaoVendas__c'    => 'OrganizacaoVendas',
                'Moeda__c'                => 'BRL',
                'Montante__c'             => 10.00,
                'MontanteInterno__c'      => 10.00,
                'MontanteInternoDolar__c' => 10.00,
                'DataLancamento__c'       => Date.today()
            };
        }
    }

    public class LocalNegocioDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Codigo__c'    => GuidGenerator.generate(),
                'Descricao__c' => 'Descrição'
            };
        }
    }

    public class MetaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'IDMetaSAP__c'      => IntegrationUtils.randomNumber(20),
                'Data__c'           => Date.today(),
                'OrcamentoDolar__c' => 10.00,
                'OrcamentoReal__c'  => 10.00,
                'Litros__c'         => 10
            };
        }
    }

    public class NotaFiscalDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'          => IntegrationUtils.randomNumber(15),
                'NrNF__c'                => 123,
                'Agenciamento__c'        => true,
                'ArmazemGeral__c'        => 'test',
                'CanalVenda__c'          => 'XD',
                'Centro__c'              => 'test',
                'CondPagto__c'           => 'test',
                'DataNF__c'              => Date.today(),
                'DescricaoTipoFatura__c' => 'test',
                'DiretoriaEscritorio__c' => 'test',
                'EMailGerente__c'        => 'test',
                'EMailVendedor__c'       => 'test',
                'EstadoCliente__c'       => 'SP',
                'Gerente__c'             => 'test',
                'HoraNF__c'              => Time.newInstance(0, 0, 0, 0),
                'IncotermoTipoFrete__c'  => 'test',
                'NomeCliente__c'         => 'test',
                'NomeTransportador__c'   => 'test',
                'NrDocumentoNF__c'       => 'test',
                'OrganizacaoVendas__c'   => 'test',
                'Pais__c'                => 'BR',
                'SerieNF__c'             => 10,
                'TipoFat__c'             => 'test',
                'TipoNota__c'            => 'ZA',
                'Transportador__c'       => 'test'
            };
        }
    }

    public class NotaFiscalItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'NrItemOrdemNossonr__c' => GuidGenerator.generate(),
                'DescricaoMaterial__c'  => 'test',
                'Familia__c'            => 'test',
                'NrItemNF__c'           => 1,
                'QuantidadeNota__c'     => 100,
                'SubFamilia__c'         => 'test',
                'TipoMaterial__c'       => 'test',
                'UnidadeMedida__c'      => 'test',
                'ValorIPI__c'           => 10.0000,
                'ValorTotalItem__c'     => 10.0000,
                'ValorTotalUSD__c'      => 10.0000,
                'ValorUnitarioItem__c'  => 10.0000,
                'ValorTotalLiquido__c'  => 10.00
            };
        }
    }

    public class OrderDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'OVSAP__c'               => GuidGenerator.generate(),
                'Status'                 => 'Draft',
                'Pricebook2Id'           => STANDARD_PRICEBOOK_ID,
                'ListaPreco__c'          => 'Z1',
                'OrganizacaoVendas__c'   => '1000',
                'CanalDistribuicao__c'   => '10',
                'SetorAtividade__c'      => '10',
                'PedidoCliente__c'       => 'PURCH_NO_C',
                'EffectiveDate'          => Date.today(),
                'DataInicioJuros__c'     => Date.today(),
                'MotivoOrdem__c'         => 'Z10',
                'Agenciamento__c'        => true,
                'Moeda__c'               => 'BRL',
                'Description'            => 'testDescription',
                'StatusCredito__c'       => 'A',
                'BloqueioRemessa__c'     => '01'
            };
        }
    }

    public class OrderItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'UnitPrice'                       => 0,
                'NumeroPedidoCliente__c'          => '123',
                'DataEntrega__c'                  => Date.today(),
                'Quantity'                        => 10,
                'QuantidadeConfirmada__c'         => 10,
                'PrecoLista__c'                   => 10.00,
                'ValorJuros__c'                   => 10.00,
                'PrecoVendaSemJuros__c'           => 10.00,
                'PrecoListaReferencia__c'         => 10.00,
                'Unidade__c'                      => 'AAA',
                'SaldoLitros__c'                  => 10.00,
                'DataFaturamento__c'              => Date.today(),
                'StatusGlobalItem__c'             => 'A',
                'MotivoRecusaItem__c'             => 'Z2',
                'Status__c'                       => 'Liberado',
                'StatusSAP__c'                    => 'Confirmado',
                'StatusFornecItem__c'             => 'A',
                'BloqueioDocumentoFaturamento__c' => '00',
                'ValorTotal__c'                   => 10.00,
                'NrItem__c'                       => '10',
                'NumeroRemessa__c'                => '1010',
                'QuantidadeTotal__c'              => 10,
                'DataInicioExpedicao__c'          => Date.today(),
                'LinhaDivisaoRemessa__c'          => '1',
                'ValorUnitarioComJuros__c'        => 10.00,
                'DescontoConcedido__c'            => 0
            };
        }
    }

    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'                                => 'test',
                'StageName'                           => 'Iniciado',
                'CloseDate'                           => Date.today() + 10,
                'DataReferenciaPreco__c'              => Date.today() + 10,
                'DataValidade__c'                     => Date.today() + 10,
                'NumeroPedidoCliente__c'              => '123',
                'EMailAprovacaoPedidoCliente__c'      => 'demo@nescara.com',
                'OrganizacaoVenda__c'                 => '1000',
                'SetorAtividade__c'                   => '10- Produtos',
                'Moeda__c'                            => 'BRL',
                'TipoOrdem__c'                        => 'Normal',
                'ClassificacaoVenda__c'               => 'Normal',
                'DataInicioJuros__c'                  => Date.today() + 10,
                'MotivoOrdem__c'                      => 'CML Acertos comerciais',
                'VencimentoVendor__c'                 => Date.today() + 10,
                'TipoFrete__c'                        => 'CIF',
                'CondicaoExpedicao__c'                => 'Fracionado',
                'Agenciamento__c'                     => true,
                'DataVencimento__c'                   => Date.today() + 10,
                'ObservacaoInterna__c'                => 'test',
                'ObservacaoLogistica__c'              => 'test',
                'ObservacaoPDF__c'                    => 'test',
                'ObservacaoImpressaNF__c'             => 'test',
                'ObservacaoRizotec__c'                => 'test',
                'NomeRTV__c'                          => 'test',
                'ValorTotalIPI__c'                    => 100.00,
                'ValorTotalIPIDolar__c'               => 100.00,
                'ValorTotalMercadoriasDolar__c'       => 100.00,
                'ValorTotalMercadoriasDolarSemIPI__c' => 100.00,
                'ValorTotalMercadoriasReal__c'        => 100.00,
                'ValorTotalMercadoriasRealSemIPI__c'  => 100.00
            };
        }
    }

    public class OpportunityLineItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Confirmado__c'              => true,
                'DataEntrega__c'             => Date.today(),
                'ValorJurosItemUSD__c'       => 10.00,
                'PrecoListaReferenciaUSD__c' => 10.00,
                'PrecoVendaSemJurosUSD__c'   => 10.00,
                'DataFaturamento__c'         => Date.today(),
                'DataConfirmacao__c'         => Date.today(),
                'Discount'                   => 10.00,
                'DescontoTipoCliente__c'     => 10.00,
                'Juros__c'                   => 10.00,
                'NumeroPedidoCliente__c'     => '123',
                'Litros__c'                  => 10.00,
                'PrecoListaReferencia__c'    => 10.00,
                'PrecoLista__c'              => 10.00,
                'PrecoVendasJuros__c'        => 10.00,
                'PrecoVendaSemJuros__c'      => 10.00,
                'PrecoLitro__c'              => 10.00,
                'ValorFrete__c'              => 10.00,
                'UnitPrice'                  => 10.00,
                'Quantity'                   => 10,
                'TotalItemComJuros__c'       => 10.00,
                'ValorJurosItem__c'          => 10.00,
                'TotalItemComJurosUSD__c'    => 10.00,
                'PrecoVendasJurosUSD__c'     => 10.00,
                'PrazoInterno__c'            => 10,
                'TaxaDolar__c'               => 10.00,
                'Itinerario__c'              => 3,
                'DescontoMaximo__c'          => 10.00,
                'DescontoMinimo__c'          => 10.00,
                'DescontoRecomendado__c'     => 10.00,
                // 'PrecoVendasJurosBRLUSD__c'  => 10.00,
                'DescontoExcedente__c'       => 1.00
            };
        }
    }

    public class POGDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'CNPJCPF__c'      => IntegrationUtils.randomNumber(18),
                'DataApuracao__c' => Date.today(),
                'Concluido__c'    => false
            };
        }
    }

    public class PoliticaDescontoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'          => GuidGenerator.generate(),
                'OrganizacaoVenda__c'    => '1000',
                'Maximo__c'              => 10.00,
                'Minimo__c'              => 10.00,
                'Recomendado__c'         => 10.00,
                'DataVigenciaInicial__c' => Date.today() - 10,
                'DataVigenciaFinal__c'   => Date.today() + 10
            };
        }
    }

    // public class PricebookEntryDefaults implements FieldDefaults {
    //     public Map<String, Object> getFieldDefaults() {
    //         return new Map<String, Object>{
    //             'UnitPrice' => 100
    //         };
    //     }
    // }

    public class Product2Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'           => GuidGenerator.generate(),
                'Name'                    => 'Product2 - Teste',
                'Description'             => 'testDescription',
                'SKU__c'                  => 'testSKU',
                'Multiplicidade__c'       => 1,
                'Litragem__c'             => 10.00,
                'Tipo__c'                 => 'Biológico',
                'Family'                  => 'ADJUST',
                'SubFamily__c'            => 'AZOKOP',  
                'IsActive'                => true,
                'IPI__c'                  => 10,
                'Embalagem__c'            => 'testEmbalagem',
                'ClassificacaoProduto__c' => 'B'
            };
        }
    }

    public class ProgramacaoEntregaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'DataEntrega__c'             => Date.today(),
                'QuantidadeProgramada__c'    => 10,
                'QuantidadeDisponivelSAP__c' => 10,
                'Status__c'                  => 'Liberado',
                'PrecoVenda__c'              => 10.00,
                'PrecoVendaJuros__c'         => 10.00,
                'PrecoVendasJurosUSD__c'     => 10.00,
                'Confirmado__c'              => true
            };
        }
    }

    public class RegionalDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'   => GuidGenerator.generate(),
                'NomeRegional__c' => 'Regional - Teste'
            };
        }
    }

    public class TabelaFreteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'IdSAP__c'               => GuidGenerator.generate(),
                'OrganizacaoVenda__c'    => '1000',
                'RegiaoUF__c'            => 'SP',
                'TipoFrete__c'           => 'Fracionado',
                'Frete__c'               => 10.00,
                'DataVigenciaInicial__c' => Date.today() - 10,
                'DataVigenciaFinal__c'   => Date.today() + 10
            };
        }
    }
    
    public class TabelaPrecoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'          => GuidGenerator.generate(),
                'TabelaPreco__c'         => 'TP1',
                'OrganizacaoVenda__c'    => '1000',
                'ListaPreco__c'          => 'Z1',
                'TipoCliente__c'         => 'ZC',
                'Valor__c'               => 10.00,
                'DataVigenciaInicial__c' => Date.today() - 10,
                'DataVigenciaFim__c'     => Date.today() + 10
            };
        }
    }

    public class TerritorioDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c'     => GuidGenerator.generate(),
                'NomeTerritorio__c' => 'Território - Teste'
            };
        }
    }

    public class UserDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'BusinessPartnerSAP__c' => GuidGenerator.generate(),
                'Username'              => 'john' + GuidGenerator.generate() + '@nhoj.com',
                'LastName'              => 'stoller',
                'Alias'                 => 'stoller',
                'Email'                 => 'stoller@stoller.com',
                'CommunityNickname'     => GuidGenerator.generate(),
                'TimeZoneSidKey'        => 'America/Sao_Paulo',
                'LocaleSidKey'          => 'pt_BR',
                'EmailEncodingKey'      => 'ISO-8859-1',
                'LanguageLocaleKey'     => 'pt_BR'
            };
        }
    }

    public class VigenciaCondicaoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{                
                'ExternalId__c'               => GuidGenerator.generate(),
                'JurosComercialFinanceiro__c' => 10.00,
                'DataVigenciaDe__c'           => Date.today() - 10,
                'DataVigenciaAte__c'          => Date.today() + 10
            };
        }
    }

    public class VigenciaTabelaFreteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{                
                'ExternalId__c'      => GuidGenerator.generate(),
                'Frete__c'           => 10.00,
                'DataVigenciaDe__c'  => Date.today() - 10,
                'DataVigenciaAte__c' => Date.today() + 10
            };
        }
    }
    
    public class ZonaTransporteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ExternalId__c' => IntegrationUtils.randomNumber(4),
                'Descricao__c'  => 'Descrição'
            };
        }
    }
    public class SolicitacaoCancelamentoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'TaxaMedia__c'                     => 3534.00,
                'TipoOrdem__c'                     => 'Normal',
                'Status__c'	                       => 'Integrado',
                'StatusSAP__c'                     => 'Confirmado',
                'MotivoCancelamento__c'            => 'Solicitação do Cliente',
                'AprovadoGerenteRegional__c'       => true,
                'AprovadoDiretorNegocios__c'       => true,
                'AprovadoDiretorComercial__c'      => true
            };
        }
    }
}