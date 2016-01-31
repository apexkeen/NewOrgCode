/*******************************************************************************************************************************************
* File Name     :   WB_Batch_ClientAvailUpdate
* Description   :   A batch job for marking Confirmed Client Avails with no predefined price tiers
* @author       :   CTS
* Modification Log
===================================================================================================
* Ver.    Date              Author          Modification
---------------------------------------------------------------------------------------------------
* 1.0     8 Oct.2015        CTS             ER-000015 : Created the class.
*                                           a.  Create a batch job to select “Price Tier Not Found” (of ‘Validation Failures’ field) 
                                                for the Client Avail records that are in ‘Confirmed’ Status with a future Client avail 
                                                end date (including a blank end date) with price tier populated and has no pricing data. 
                                            b.  Also select “Invalid Price Tier” (of ‘Validation Failures’ field) for the Client Avail 
                                                records that are in ‘Confirmed’ status with a future Client Avail end date (including a blank 
                                                end date) with predefined price tier values and the value on the price tier is not the one among those predefined.                                                              
********************************************************************************************************************************************/

global class WB_Batch_ClientAvailUpdate implements Database.Batchable<sObject>{
    
    
    String query = '';
    Date dt = Date.today();
    List<Client_Avail__c> lstClientAvail;
    
    global WB_Batch_ClientAvailUpdate(){
    }
   
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        query = 'SELECT Client__c, Release_Plan_Country__c, Release_Plan_Format__c, Release_Plan_Channel__c, End_Date__c, '
                +' Price_Tier_Text__c, Title_Content_Type__c, Local_Title__r.Price_Code__c, Status__c, Validation_Failures__c '
                +' FROM Client_Avail__c '
                +' WHERE Status__c = \'Confirmed\' '
                +' and (Price_Tier_Text__c != null or Price_Tier_Text__c != \'\') '
                +' and Validation_Failures__c = null '
                +' and Price__c = null '
                +' and Title_Content_Type__c = \'Feature\' '
                +' and (End_Date__c > :dt or End_Date__c = null)';

        return Database.getQueryLocator(query);
    }
  
    // Execute Logic
    global void execute(Database.BatchableContext BC, List<Client_Avail__c>scope){
        
        List<Client_Avail__c> clientAvailUpdateList = new List<Client_Avail__c>();
        system.debug('------scope----------'+scope);
        
        Map<Id,Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>> mapPricingRecords = WB_Update_Price_Tier_Handler.getPricingRecords(scope);
        system.debug('----------mapPricingRecords-----******-----'+mapPricingRecords);
        
        for(Client_Avail__c clientAvail : scope) {
            
            Boolean flag = false;
            if(mapPricingRecords != null && mapPricingRecords.size() > 0)
            {       
                if(mapPricingRecords.get(clientAvail.Client__c) != null 
                && mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c) != null 
                && mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c).get(clientAvail.Release_Plan_Format__c) != null 
                && mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c).get(clientAvail.Release_Plan_Format__c).get(clientAvail.Release_Plan_Channel__c) != null 
                && mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c).get(clientAvail.Release_Plan_Format__c).get(clientAvail.Release_Plan_Channel__c).get(clientAvail.Title_Content_Type__c) != null)
                //&& mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c).get(clientAvail.Release_Plan_Format__c).get(clientAvail.Release_Plan_Channel__c).get(clientAvail.Title_Content_Type__c).get(clientAvail.Local_Title__r.Price_Code__c) != null)
                {
                    
                     Map<String,Pricing__c> allPriceTiers = mapPricingRecords.get(clientAvail.Client__c).get(clientAvail.Release_Plan_Country__c).get(clientAvail.Release_Plan_Format__c).get(clientAvail.Release_Plan_Channel__c).get(clientAvail.Title_Content_Type__c); //.get(mapClientAvail.get(clientAvail.id).Local_Title__r.Price_Code__c);
                     Boolean isPriceTierFound = false;
                     for(Pricing__c pricingRecords : allPriceTiers.values())                            
                         if(pricingRecords != null && clientAvail.Price_Tier_Text__c == pricingRecords.Price_Tier__c)
                             isPriceTierFound = true;
                     
                     if(isPriceTierFound)
                         clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Valid_Price_Tier));
                     else
                         clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Invalid_Price_Tier));
                    
                    
                    /*                    
                    Pricing__c pricingrecord = mapPricingRecords.get(clientAvail.Client__c)
                                                                .get(clientAvail.Release_Plan_Country__c)
                                                                .get(clientAvail.Release_Plan_Format__c)
                                                                .get(clientAvail.Release_Plan_Channel__c)
                                                                .get(clientAvail.Title_Content_Type__c)
                                                                .get(clientAvail.Local_Title__r.Price_Code__c);
                    system.debug('----------pricingrecord----------'+pricingrecord);
                    
                    if(pricingrecord != null) {
                        flag = true;
                        if(pricingrecord.Price_Tier__c == clientAvail.Price_Tier_text__c)
                            clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Valid_Price_Tier));
                        else
                            clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Invalid_Price_Tier));
                    }
                    */
                } else
                    clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Price_Tier_Not_Found));    
            } else
                    clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Price_Tier_Not_Found));    
            /*
            if(!flag) {
                clientAvailUpdateList.add(new Client_Avail__c(Id=clientAvail.Id, Validation_Failures__c=Label.Price_Tier_Not_Found));
            }*/
        }
        system.debug('----------clientAvailUpdateList----------'+clientAvailUpdateList);
        
        Database.Saveresult[] saveResult_CA  = Database.update(clientAvailUpdateList, false);
        system.debug('----------saveResult_CA----------'+saveResult_CA);
    }
 
    global void finish(Database.BatchableContext BC){
        // Logic to be Executed at finish
        WB_Batch_SendReportTPlannerUser batchInstance = new WB_Batch_SendReportTPlannerUser();
        Database.executebatch(batchInstance,1);
    }
}