global class WB_Batch_APO_ClientAvailUpdate implements Database.Batchable<sObject>{
    
    
    String query = '';
    List<Client_Avail__c> lstClientAvail;
    
    global WB_Batch_APO_ClientAvailUpdate(){
    }
   
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        query = 'SELECT Client__c, Release_Plan_Country__c, Release_Plan_Format__c, Release_Plan_Channel__c, End_Date__c, '
                +' Price_Tier_Text__c, Title_Content_Type__c, Local_Title__r.Price_Code__c, Status__c, Validation_Failures__c '
                +' FROM Client_Avail__c '
                +' WHERE APO__c = \'\''
                +' and (Commercial_Avail__r.Status__c = \'Confirmed\' OR Commercial_Avail__r.Status__c = \'Tentative\')'
                +' and Commercial_Avail__r.Clear_To_Avail__c = true' ;
                
        system.debug('------query----------'+query);
        return Database.getQueryLocator(query);
    }
  
    // Execute Logic
    global void execute(Database.BatchableContext BC, List<Client_Avail__c>scope){
        
        List<Client_Avail__c> clientAvailUpdateList = new List<Client_Avail__c>();
        system.debug('------scope----------'+scope);
        
        for(Client_Avail__c clientAvail : scope) {
            clientAvail.APO__c = 'No';
            clientAvailUpdateList.add(clientAvail);
        }
        system.debug('----------clientAvailUpdateList----------'+clientAvailUpdateList);
        
        Database.Saveresult[] saveResult_CA  = Database.update(clientAvailUpdateList, false);
        system.debug('----------saveResult_CA----------'+saveResult_CA);
    }
 
    global void finish(Database.BatchableContext BC){
        
    }
}