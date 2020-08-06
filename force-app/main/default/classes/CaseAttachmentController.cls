public class CaseAttachmentController {

    public String CaseId {
        get{
            if(CaseId == null && ApexPages.currentPage().getParameters().get('CaseId') != null){
                CaseId = ApexPages.currentPage().getParameters().get('CaseId');
            }
            
            return CaseId;
        }
        set;
    }

    public String CaseImagens {
        get{
            return [SELECT imagens__c FROM Case WHERE id = :CaseId LIMIT 1].imagens__c;

            // String caseImagens = [SELECT imagens__c FROM Case WHERE id = :CaseId LIMIT 1].imagens__c;

            // System.debug('caseImagens => ' + caseImagens);
            
            // Integer altIndex = caseImagens.indexOf('" alt="');
            // System.debug('altIndex => ' + caseImagens);
            // System.debug('caseImagens.mid(13, (altIndex - 13)) => ' + caseImagens.mid(13, (altIndex - 13)));
            // return '\'' + caseImagens.mid(13, (altIndex - 13)) + '\'';
        }
        set;
    }
}