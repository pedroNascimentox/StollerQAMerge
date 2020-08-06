public without sharing class EmailClientToApprove {
    public static void sendEmail(List<Opportunity> OppList) {     
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 

        Map<String, EmailTemplate> searchEmailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate email :[SELECT id, name, subject, htmlvalue, markup, Body, developerName
				                  FROM   EmailTemplate
				                  WHERE  (developerName =  'ClientApproval' OR DeveloperName = 'RTVApproval')]){
            searchEmailTemplateMap.put(email.DeveloperName, email);
        }     
        Map<Id, Territorio__c> terrMap = new Map<Id, Territorio__c>([SELECT id, RTV__r.Email, RTV__r.Name FROM Territorio__c WHERE Id IN: Collection.of(OppList).pluckIds(Opportunity.Territorio__c)]);
        
        Map<Id, List<String>> oppToMailList = new Map<Id, List<String>>();        
        Map<Id, List<String>> oppToCCAddressList = new Map<Id, List<String>>();        
        for(Opportunity opp : OppList){
            if(opp.EMailAprovacaoPedidoCliente__c != null){
                oppToMailList.put(opp.Id, new List<String>{opp.EMailAprovacaoPedidoCliente__c});
                if(terrMap.containsKey(opp.Territorio__c)){
                    oppToCCAddressList.put(opp.Id, new List<String>{terrMap.get(opp.Territorio__c).RTV__r.Email});
                }
            }else if(terrMap.containsKey(opp.Territorio__c)){
                oppToMailList.put(opp.Id, new List<String>{terrMap.get(opp.Territorio__c).RTV__r.Email});
            }
        }

        Map<Id, Id> linkedIdMap = new Map<Id, Id>();
        for(ContentDocumentLink contentLink : [SELECT id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId  IN : Collection.of(OppList).pluckIds()]){
            linkedIdMap.put(contentLink.ContentDocumentId, contentLink.LinkedEntityId);
        }
        Map<Id, ContentVersion> versionOppMap  = new Map<Id, ContentVersion>();
        for(ContentVersion ctV : [SELECT ContentDocumentId, Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN :linkedIdMap.keySet()]){
            versionOppMap.put(linkedIdMap.get(ctV.ContentDocumentId), ctV);
        }
                
        Map<string,String> siteUrlMap = getSiteUrl();
        for(Opportunity opp : OppList){
            List<Messaging.EmailFileAttachment> attchList = new List<Messaging.EmailFileAttachment>();
            if(versionOppMap.containsKey(opp.Id)){
                ContentVersion ctv = versionOppMap.get(opp.Id);
                attchList.add(createAttachment(ctv.Title, ctV.VersionData));
            }
            
            string externalURL = siteUrlMap.containsKey('ValidaAprovacao') ? siteUrlMap.get('ValidaAprovacao') : '';

            EmailTemplate searchEmailTemplate = null;
            if(opp.EMailAprovacaoPedidoCliente__c == null){
                searchEmailTemplate = searchEmailTemplateMap.get('RTVApproval');
            }else{
                searchEmailTemplate = searchEmailTemplateMap.get('ClientApproval');
            }
            String body =  searchEmailTemplate.Body;



            body = body.replace('{OppNumber}', opp.numeroOportunidade__c);
            if(opp.EMailAprovacaoPedidoCliente__c != null){
                body = body.replace('{ApprovalLink}', '<font color="green"><b>Aprovar: </b></font><a href="' +  externalURL + '?id='+opp.Id+'&Action=Approve">Clique aqui</a><br><br>');
                body = body.replace('{RejectedLink}', '<font color="red"><b>Reprovar: </b></font><a href="' +  externalURL + '?id='+opp.Id+'&Action=Reject">Clique aqui</a><br><br>');
                body = body.replace('{ClientName}', opp.NomeCliente__c);
            }else if(terrMap.containsKey(opp.Territorio__c)){
                body = body.replace('{RTVNAME}', terrMap.get(opp.Territorio__c).RTV__r.Name);
            }
                   
            mails.add(composeEmail(oppToMailList.get(opp.Id), 
                                   'Stoller', 
                                   searchEmailTemplate.Subject.replace('{OppNumber}', opp.numeroOportunidade__c).replace('{ClientNumber}', opp.NomeCliente__c),
                                   body,
                                   attchList,
                                   (oppToCCAddressList.containsKey(opp.id) ? oppToCCAddressList.get(opp.id) : null)));      
                                  
                 
        }
        if(!Test.isRunningTest()) Messaging.sendEmail(mails);
    }
    
	public static map<string,String> getSiteUrl(){ 
	    Map<String,String> sitesURL = new Map<String,String>();
		for(RemoteSiteEmail__c remote : [SELECT Name, Site__c FROM RemoteSiteEmail__c]){
            sitesURL.put(remote.Name, remote.Site__c);
        }	        
        return sitesURL;
    }
    public static Messaging.SingleEmailMessage composeEmail(List<string> toAddresses, string displayName, string subject, string htmlBody, List<Messaging.EmailFileAttachment> anexos, List<String> ccAddress){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);        
        mail.setSenderDisplayName(displayName);        
        mail.setSubject(subject);        
        mail.setUseSignature(false);
        mail.setHtmlBody (htmlBody);
        
        if(!anexos.isEmpty()) mail.setFileAttachments(anexos);
        
        return mail;
    }
    
    public static Messaging.EmailFileAttachment createAttachment(string fileName, Blob b){
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(fileName);
        efa.setBody(b);
        return efa;
    }
}