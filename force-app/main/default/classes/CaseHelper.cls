public with sharing class CaseHelper  extends TriggerContext {
    public static void sendEmail(List<Case> context, Map<Id, Case> oldMap, Boolean isInsert) {

        List<Case> caseAfterContext = [
            SELECT  id, caseNumber, account.id, account.name, problemas__c,
                    territorio__r.nomeTerritorio__c, description, nomeProduto__c, 
                    nomeProduto__r.name, quantidade__c, lote__c, quantidade_Lote_2__c, 
                    lote_2__c, quantidade_Lote_3__c, lote_3__c, quantidade_Lote_4__c, 
                    lote_4__c, quantidade_Lote_5__c, lote_5__c, reclama_o_verificada_no_local__c,
                    o_local_coberto_seco_e_ventilado__c, a_embalagem_est_amassada__c, 
                    a_embalagem_est_sem_r_tulo__c, qnt_minima_por_lote_verificada_5_bd__c, 
                    empilhamento_m_ximo_adequado__c, a_embalagem_est_vazando__c,
                    contactId, contact.Name, status
            FROM Case
            WHERE id IN :oldMap.keySet()
        ];

        Map<String, TemplateToEmails__c> templateToEmail = TemplateToEmails__c.getAll();
        System.debug(templateToEmail);
        
        Map<String, EmailTemplate> searchEmailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate email :[SELECT id, name, subject, htmlvalue, markup, Body, developerName
				                  FROM   EmailTemplate
				                  WHERE  DeveloperName IN ('AlteracaoNovoEmAnalise', 'EmAnaliseParaFechadoNovo', 'CasoFechadoQualidadeNovo')]){
            searchEmailTemplateMap.put(email.DeveloperName, email);
        }  
		Set<Id> contactIdSet= new Set<Id>();
        Map<Id, Case> csAnaliseMap= new Map<Id, Case>();
        Map<Id, Case> csFechadoMap= new Map<Id, Case>();
        for(Case cs : caseAfterContext){
            if(cs.Status == 'Escalado' && (isInsert || (cs.Status != oldMap.get(cs.Id).Status))){
                csAnaliseMap.put(cs.id, cs);
            }
            if(cs.Status == 'Fechado' && (isInsert || (cs.Status != oldMap.get(cs.Id).Status))){
                csFechadoMap.put(cs.id, cs);
            }
            contactIdSet.add(cs.COntactId);
        }
        System.debug(csAnaliseMap);
        System.debug(csFechadoMap);
        Map<Id, List<Id>> linkedIdMap = new Map<Id, List<Id>>();
        Set<Id> contentDocumentIdSet = new Set<Id>();
        for(ContentDocumentLink contentLink : [SELECT id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId  IN : Collection.of(context).pluckIds()]){
            if(!linkedIdMap.containsKey(contentLink.LinkedEntityId))
                linkedIdMap.put(contentLink.LinkedEntityId, new List<Id>());
            linkedIdMap.get(contentLink.LinkedEntityId).add(contentLink.ContentDocumentId);    
            
            contentDocumentIdSet.add(contentLink.ContentDocumentId);

        }

        Map<Id, ContentVersion> versionOppMap  = new Map<Id, ContentVersion>();
        for(ContentVersion ctV : [SELECT ContentDocumentId, Title, VersionData, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIdSet]){
            versionOppMap.put(ctV.ContentDocumentId, ctV);
        }
		Map<Id, Contact> mapContact = new Map<Id, Contact>([SELECT id, Email FROM Contact WHERE id IN : contactIdSet]);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 
        for(Case cs : context){
            if(csAnaliseMap.containsKey(cs.Id) || csFechadoMap.containsKey(cs.Id)){
                List<EmailTemplate> modelList = new List<EmailTemplate>();
                if(csAnaliseMap.containsKey(cs.Id)){
                System.debug(modelList);
                    modelList.add(searchEmailTemplateMap.get('AlteracaoNovoEmAnalise'));
                }else if(csFechadoMap.containsKey(cs.Id)){
                System.debug(modelList);
                    modelList.add(searchEmailTemplateMap.get('EmAnaliseParaFechadoNovo'));
                    modelList.add(searchEmailTemplateMap.get('CasoFechadoQualidadeNovo'));
                }
                System.debug(modelList);

                List<Messaging.EmailFileAttachment> attchList = new List<Messaging.EmailFileAttachment>();
                if(linkedIdMap.containsKey(cs.Id)){
                    for(Id cdId : linkedIdMap.get(cs.Id)){
                        if(versionOppMap.containsKey(cdId)){
                            ContentVersion ctv = versionOppMap.get(cdId);
                            
                            Messaging.EmailFileAttachment emailAttch = new Messaging.EmailFileAttachment();
                            // emailAttch.setContentType('application/vnd.ms-excel');
                            emailAttch.setFileName(ctv.Title+'.'+ctv.FileExtension);
                            emailAttch.setBody(ctv.VersionData);

                            attchList.add(emailAttch);
                        }
                    }
                }
        System.debug(modelList);
                for(EmailTemplate emailTemplate : modelList){
                    List<String> emailList  = templateToEmail.get(emailTemplate.DeveloperName).Email__c.split(';');
                    emailList.add(mapContact.get(cs.COntactId).Email);
	                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	       	        mail.setToAddresses(emailList); 
                    mail.setTargetObjectId(cs.ContactId);
	                mail.setTemplateId(emailTemplate.Id);
	                mail.setWhatId(cs.Id);
                    mail.setFileAttachments(attchList);
	                mails.add(mail);
                }
            }
        }   
        System.debug(mails);
        if(!Test.isRunningTest()) Messaging.sendEmail(mails);
    }

    public static void changeCaseOwner(List<Case> newRecordsList){
        
        List<Id> territoryIds = Collection.of(newRecordsList).pluckIds(Case.Territorio__c);

        Map<Id, Territorio__c> territories = new Map<Id, Territorio__c>([SELECT id, rtv__c FROM Territorio__c WHERE id IN :territoryIds AND rtv__c != null]);

        List<Case> opportunitiesToUpdateOwner = new List<Case>();

        for(Case caseRecord : newRecordsList){
            if(caseRecord.territorio__c != null && territories.containsKey(caseRecord.territorio__c) && caseRecord.ownerId != territories.get(caseRecord.territorio__c).rtv__c){
                caseRecord.ownerId = territories.get(caseRecord.territorio__c).rtv__c;
            }
        }
    }
}

// Tatiane, Reclamação
//AlteracaoNovoEmAnalise, AlteracaoEmAnaliseFechado => Email do Contato
//CasoFechadoQualidade => Aline Santos