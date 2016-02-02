public with sharing class WB_Announcement_Confirmation_Controller {
    
    // Save 1 - GIT
    //save 2 -GIT -2
    //Save 3 Git 3
    //
    public string announcementTypeIds{get;set;}
    public List<String> lstAnnouncementTypeId;
    public List<Announcement_Rule__c> announcementRuleList{set;get;}   // list of selected Announcement Types list
    public List<Announcement__c> announcementRecordCreateList = new List<Announcement__c>();        //list to use to create Announcements
    public List<Announcement_Rule__c> announcementRuleFinalList{set;get;}        //final list to use to create Announcements
    public transient List<User> currentUser = new list<User>();
    public transient Set<Id> accountSet= new Set<Id>();        // set of Account ids from selected Announcement Rules records
    public transient List<Account_Role__c> accountAnnouncerList = new List<Account_Role__c>();
    public boolean announcementRuleDisplay{get;set;}
    public string announcementRuleMessage{get;set;}
    public boolean announcementRuleRendered{get;set;}
    public boolean InternalOnlyCheck{get;set;}    
    public string announcementName;
    public string accountIdRedir{get;set;}
    public String param{get;set;}
       public String param{get;set;}  // added to learn Git
    public list<Id> annoucementIds = new list<Id>();// added to learn GIT
    public transient map<Id, Announcement_Record__c> clientAvailAnnRecordMap = new map<Id, Announcement_Record__c>();
    public transient map<Id,set< ID >> announcementRecordMap = new map<Id,set< ID >>();
    
    public WB_Announcement_Confirmation_Controller() {
    } 
    public WB_Announcement_Confirmation_Controller(ApexPages.StandardSetController controller) {
        announcementRuleDisplay = true;
        announcementRuleRendered = false;
        accountIdRedir = '';
        announcementRuleFinalList = new List<Announcement_Rule__c>();
        announcementTypeIds = ApexPages.currentPage().getParameters().get('ID');
        if(announcementTypeIds !=null){
            lstAnnouncementTypeId = announcementTypeIds.split(',');
        }
        try{
                announcementRuleList= [SELECT id, name,Announcement_Type__c,Selection_Criteria__c,Date_Last_Run__c,
                                        Account__c,Content_Type__c,Statuses__c,Channels__c,Country_Group__c,Report_ID__c,
                                        Report_Template__c,Email_Template__c,createdDate,Account__r.Name,File_Format__c,
                                        (select id,From_Date__c,Run_Date__c from Announcements__r order by createddate desc)
                                        FROM Announcement_Rule__c
                                        WHERE Id IN: lstAnnouncementTypeId];
        }
        catch(QueryException qe) {
            System.debug('The following exception has occurred: ' + qe.getMessage());    
        }
        
        
         param= ApexPages.currentPage().getParameters().get('param');
         
         if(param == null){
           accountIdRedir= announcementRuleList[0].Account__c;
        }
        
        for(Announcement_Rule__c annRuleList: announcementRuleList){
            accountSet.add(annRuleList.Account__c);
        }
        try{
                accountAnnouncerList = [SELECT id,Account__c
                                        FROM Account_Role__c
                                        WHERE Account__c IN: accountSet
                                        AND Role__c includes( 'Announcer' )
                                        AND User__c=: Userinfo.getUserId()];
        }
        catch(QueryException qe) {
            System.debug('The following exception has occurred: ' + qe.getMessage());    
        }
        
        for(Announcement_Rule__c AnnRule: announcementRuleList){
            for(Account_Role__c acctAnnouncer:accountAnnouncerList ){
                if(AnnRule.Account__c == acctAnnouncer.Account__c){
                    announcementRuleFinalList.add(AnnRule);
                }
            }
        }  
 
       
        if(accountAnnouncerList != null && accountAnnouncerList.size() > 0){
            if(announcementRuleList.size() > announcementRuleFinalList.size()){
                integer announcementRuleCount= announcementRuleList.size()- announcementRuleFinalList.size();
                announcementRuleRendered = true;
                announcementRuleMessage ='Out of '+' '+announcementRuleList.size()+' '+'selected Announcement Rules,'+' '+ announcementRuleCount+' '+'cannot create Announcement' ;
                
            }
        }
        else{
            announcementRuleDisplay = false;
            
        }
        
                
    }
    
    
    public pagereference cancel(){
        
         pageReference PageRef= new Pagereference('');
         
         if(param=='AnnocementTypeListView'){
            PageRef = new Pagereference(System.Label.Announcement_Type_Home_Page);
            
        }
        else if (param=='AccountListView')
        {
            PageRef = new Pagereference(System.Label.Announcement_Type_Home_Page);
        }
        else{
            PageRef = new Pagereference('/'+accountIdRedir);
        }
         
         return PageRef;
    }
    
   
   public void GenerateAnnouncements(){
        announcementCreation(); // This function is used to create Announcements
        
   }
   
   public pagereference announcementCreation() {
    
       
        for(Announcement_Rule__c announcementRule: announcementRuleFinalList){
            Announcement__c announcementRecord = new Announcement__c();
            announcementRecord.Announcement_Type__c     = announcementRule.Id;
            announcementRecord.Account__c               = announcementRule.Account__c;
            announcementRecord.Selection_Criteria__c    = announcementRule.Selection_Criteria__c;
            announcementRecord.Content_Type__c          = announcementRule.Content_Type__c;
            announcementRecord.Status__c                = announcementRule.Statuses__c;
            announcementRecord.Channels__c              = announcementRule.Channels__c;
            announcementRecord.File_Format__c           = announcementRule.File_Format__c;
            announcementRecord.File_Status__c           = 'TBD';
            announcementRecord.Country_Group__c         = announcementRule.Country_Group__c;
            announcementRecord.Report_Id__c             = announcementRule.Report_ID__c;
            announcementRecord.Report_Name__c           = announcementRule.Report_Template__c;
            announcementRecord.Email_Template__c        = announcementRule.Email_Template__c;
            announcementRecord.Job_Run_Status__c        = 'In Progress';
                
            //dateTime dt                               = announcementRule.Date_Last_Run__c;   
            dateTime dt                               = Datetime.now(); 
            
            if(dt != null){
                String strConvertedDate = dt.format('yyyy-MM-dd');             
                announcementName   = announcementRule.Announcement_Type__c + ' ' + strConvertedDate; //-- commented by Rashmi*/
            }
            else
                announcementName   = announcementRule.Announcement_Type__c;

            if(InternalOnlyCheck == true){
                announcementName = announcementName + ' Internal';
                announcementRecord.Internal__c = true;      
                announcementRecord.Announced_User__c = UserInfo.getUserId();         
            }    

            announcementRecord.Name__c = announcementName;
            announcementRecordCreateList.add(announcementRecord);
       }
      

       if(announcementRecordCreateList != null && announcementRecordCreateList.size() > 0){
           try{
              Database.Saveresult[] saveResult  = Database.insert(announcementRecordCreateList, false);
              
              for(Database.Saveresult annInsertedRec: saveResult)
              {
                if(annInsertedRec.isSuccess())
                        //annoucementIds.add(annInsertedRec.id); 
                     //Create client activity
                      Id batchInstanceId = Database.executeBatch(new WB_ClientActivitiesBatchProcess (annInsertedRec.id,announcementRuleList), 1000);  
                     //** Rashmi .. its me Milon commented the below line. When you start working please change it
                     // Id batchInstanceId = Database.executeBatch(new WB_ClientActivitiesBatchProcessTestLimit (annInsertedRec.id,announcementRuleList), 1000);  
              }
              
              //Create client activity
              
              //Id batchInstanceId = Database.executeBatch(new WB_ClientActivitiesBatchProcess (annoucementIds,announcementRuleList), 200); 
              
              
           }
           catch(DmlException dmlex){
               System.debug('The following exception has occurred: ' + dmlex.getMessage());
           }
           
           
           pageReference  PageRef = new Pagereference(System.Label.Announcement_Type_Home_Page);
          
           return PageRef;
              
       } // if block where checking announcementRecordCreateList list is not empty     
       
       return null;
       
   }    //announcementCreation() end
   
    
    
}