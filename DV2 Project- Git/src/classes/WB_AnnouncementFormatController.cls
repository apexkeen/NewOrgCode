public with sharing class WB_AnnouncementFormatController {
    //Save1 - git 1
    
    public string selectedEmailTemplate{get;set;}
    public string selectedRepTemplate{get;set;}    
    public boolean saveMessageFlag{get;set;} 
    public boolean saveFailedMsgFlag {get;set;}
    String annTypeIds;
    Announcement_Rule__c annTypeList = new Announcement_Rule__c();
    
    public WB_AnnouncementFormatController(ApexPages.StandardController controller) {
                 annTypeIds = ApexPages.currentPage().getParameters().get('ID');
                 //defaultTemp();
                 saveMessageFlag=false;
                 saveFailedMsgFlag=false;
                 annTypeList = [select id,Email_Template__c,Email_Template_Id__c,Report_ID__c,Report_Template__c from Announcement_Rule__c where Id =: annTypeIds];
        }

    public List<EmailTemplate> EmailTemp = new List<EmailTemplate>();
    public List<Report> ReportTemp = new List<Report>();
    public WB_AnnouncementFormatController()
    {
   
    }
    
    public List<SelectOption> eTemplateList
    {
        get {   
            EmailTemp = [Select Id, Name From EmailTemplate where folder.name =:System.Label.Email_Template_Folder Order by Name ASC];
            
            eTemplateList = new List<SelectOption>(); 
            
            if(annTypeList.Email_Template_Id__c == NULL || annTypeList.Email_Template_Id__c == ''){
                //eTemplateList.add(new SelectOption('None','--None--')); 
                eTemplateList.add(new SelectOption('None',System.Label.Default_Email_Template));             
            
            }else eTemplateList.add(new SelectOption(annTypeList.Email_Template_Id__c,annTypeList.Email_Template__c));
            
            for(EmailTemplate temp : EmailTemp) {
                integer countEmailTemp = 0;
                for(SelectOption emailTempSelected: eTemplateList){                    
                    if(emailTempSelected.getLabel() == temp.Name){
                        countEmailTemp++;
                    }
                    
                }   
                if(countEmailTemp ==0 ){
                    eTemplateList.add(new SelectOption(temp.Id, temp.Name)); 
                    
                }
                    
               
            }   
            return eTemplateList;
        } set;
    }
    
    public List<SelectOption> rTemplateList
    {
        get
        {
            
            ReportTemp = [SELECT id,Name FROM Report WHERE OwnerId in (
                          SELECT ID FROM Folder WHERE name =:System.Label.Announcement_Report_Folder and Type = 'Report') ORDER BY Name ASC];
            
            rTemplateList = new List<SelectOption>();
            
            if(annTypeList.Report_ID__c == NULL || annTypeList.Report_ID__c == ''){
                //rTemplateList.add(new SelectOption('None','--None--'));
                rTemplateList.add(new SelectOption('None',System.Label.Default_Report_Template));             
             
            }else rTemplateList.add(new SelectOption(annTypeList.Report_ID__c,annTypeList.Report_Template__c));
                
            
            for(Report temp : ReportTemp) {
                integer countRepTemp = 0;
                for(SelectOption repTempSelected: rTemplateList){
                    
                    if(repTempSelected.getLabel() == temp.Name){
                        countRepTemp++;
                        
                    }
                }
                if(countRepTemp == 0){
                    rTemplateList.add(new SelectOption(temp.Id, temp.Name));                    
                }
                
            }
            return rTemplateList;
        }
        set;
    }
   public String getSelectedEmailTemp()
    {
           
            return selectedEmailTemplate ;
           
    }
    public String getSelectedRepTemp()
    {
           
            return selectedRepTemplate ;
           
    }
        
        public void saveSelection() {           
                saveMessageFlag=false; 
                saveFailedMsgFlag= false;
                string repTempName = '';
                string emailTempName = '';
                for(SelectOption repTempSelected: rTemplateList){
                    if(repTempSelected.getValue() == selectedRepTemplate){
                        repTempName = repTempSelected.getLabel(); 
                    }
                }
                for(SelectOption emailTempSelected: eTemplateList){
                    if(emailTempSelected.getValue() == selectedEmailTemplate){
                        emailTempName = emailTempSelected.getLabel(); 
                    }
                }
               
                
                Announcement_Rule__c annTypeUpdated= new Announcement_Rule__c(id = annTypeIds,Email_Template__c = emailTempName,
                                                                                Email_Template_Id__c =selectedEmailTemplate, Report_Template__c = repTempName,
                                                                                Report_ID__c = selectedRepTemplate);
                try{
                        Database.Saveresult updateResult  = Database.update(annTypeUpdated, false); 
                        if(updateResult.isSuccess()){
                                saveMessageFlag=true;
                        }  else{
                                saveMessageFlag=false; 
                                saveFailedMsgFlag= true;
                        }              
                                                
                        
                }
            catch(exception e){
                
            }
        }
    public void defaultTemp(){
    //Updating default vaues for format 
    if(annTypeList.Email_Template_Id__c == NULL || annTypeList.Email_Template_Id__c == ''){
        EmailTemplate EmailTemplateRec = [Select Id, Name From EmailTemplate where Name =:System.Label.Default_Email_Template ];
        Report ReportTempRec = [SELECT id,Name FROM Report WHERE OwnerId in (
                          SELECT ID FROM Folder WHERE name =:System.Label.Announcement_Report_Folder and Type = 'Report') and name =:System.Label.Default_Report_Template];
        Announcement_Rule__c annTypeUpdated= new Announcement_Rule__c(id = annTypeIds,Email_Template__c = EmailTemplateRec.name,
                                                                                    Email_Template_Id__c =EmailTemplateRec.Id, Report_Template__c = ReportTempRec.Name,
                                                                                    Report_ID__c = ReportTempRec.Id);
                    try{
                            Database.Saveresult updateResult  = Database.update(annTypeUpdated, false); 
                            if(updateResult.isSuccess()){
                                    saveMessageFlag=true;
                            }  else{
                                    saveMessageFlag=false; 
                                    saveFailedMsgFlag= true;
                            }              
                                                    
                            
                    }
                catch(exception e){
                    
                }            
            }  
    }   
   

}