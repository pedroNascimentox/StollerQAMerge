public without sharing class ApprovalClientController {
    
    public Boolean isAprovacao {get; set;}
    public String idOpp {get; set;}
    
    public ApprovalClientController(){
        this.idOpp = ApexPages.currentPage().getParameters().get('id');
        this.isAprovacao = ApexPages.currentPage().getParameters().get('Action') == 'Approve';
    }

     
    public PageReference ValidaAprovacao(){
        try{
            String ipAprovacao;        
            ipAprovacao = ApexPages.currentPage().getHeaders().get('True-Client-IP');        
            if(String.isBlank(ipAprovacao)) ipAprovacao = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
            // get IP address when no caching (sandbox, dev, secure urls)        
            System.debug('USER IP ADDRESS: ' + ipAprovacao);
            Opportunity opp = [SELECT id, StageName FROM Opportunity WHERE id  = :idOpp];
            opp.IPCliente__c = ipAprovacao;
            if(opp.StageName == 'Em Aprovação Cliente'){
                if(isAprovacao){
                    opp.StatusAprovacoes__c = 'Aprovado - Cliente';
                    opp.stageName = 'Aprovado Cliente';
                    opp.AprovadoCliente__c = true;
                    opp.DontChangeStageName__c = true;
                    update opp;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Oportunidade Aprovada com Sucesso.'));
                }else{
                    opp.StatusAprovacoes__c = 'Rejeitado - Cliente';
                    opp.stageName = 'Reprovado Cliente';
                    opp.AprovadoComercial__c = false;
                    opp.DontChangeStageName__c = true;
                    update opp;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Oportunidade Reprovada com Sucesso.'));
                }            
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Oportunidade já processada pelo cliente.'));
                return null;
            }
        }catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage());
            System.debug('Erro: Cause->'+e.getMessage() + ' Message->'+e.getMessage() + ' StackTracing->'+e.getStackTraceString());
        }
        return null;
    }
}