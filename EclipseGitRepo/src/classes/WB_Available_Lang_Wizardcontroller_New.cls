/**
*  Description    :   Extention Class to create available language records for titles.
*  Author         :   Prachi Gadewar
   Emp ID         :   489635
*  Date           :   28 – Aug- 2015
*  
*  =============================================================================================  
*                                     Change History
* =============================================================================================
*  Author                               Date                                       Comment
*                                                                                   CHO1
*            
*  
*/

public  with sharing class WB_Available_Lang_Wizardcontroller_New {

    public list <Language__c> allLangLst {get;set;}
    public String titleName {get;set;}
    public list <availableLangDispalyWrapper> availableLangDispLst{get;set;}
    public Boolean showField{get;set;}
    Map<id,Map<String,Available_Languages__c>> mapLangAndTypeAvailLang = new Map<id,Map<String,Available_Languages__c>>();
    String titleId;
    public string SearchVal{get;set;}

    public WB_Available_Lang_Wizardcontroller_New(ApexPages.StandardSetController controller) {
        titleid = ApexPages.currentPage().getParameters().get('id');   
       /// ApexPages.currentPage().getParameters().put('inline','0');
        // Get title name for selected title.
        titleName = [Select name from Title__c where id=: titleid limit 1].Name;
        
        // Get all existing Available Languages for selected title.
        for(Available_Languages__c availLang : [SELECT id,name,Language__c,Language__r.Name,Language_Types__c,Clear_to_Avail__c,Mastering_Cost__c,GPP_status__c,Mastering_Reason_Code__c,GPP_Notes__c,Mastering_IDS_Notes__c
                               FROM Available_Languages__c
                               WHERE Title__c = :titleid order by Name
                              ])
        {
            system.debug('availLang ******'+availLang);
            if(!mapLangAndTypeAvailLang.containskey(availLang.Language__c))
                mapLangAndTypeAvailLang.put(availLang.Language__c,new Map<String,Available_Languages__c>());
            mapLangAndTypeAvailLang.get(availLang.Language__c).put(availLang.Language_Types__c,availLang);            
        }  
        allLangLst = new list <Language__c>();
        availableLangDispLst = new list <availableLangDispalyWrapper>();
        
        // Fetch all Languages available in Language object and create wrapper class list which contains existing/New records for Language with respective of type.
        allLangLst = [SELECT id,name from Language__c order by Name];
        for(Language__c l: allLangLst){
           // Create Instance for Audio Language Type
           availableLangDispalyWrapper avlObj;
           if(mapLangAndTypeAvailLang.containskey(l.id) && mapLangAndTypeAvailLang.get(l.id).containskey('Audio'))
           {
               avlObj = new availableLangDispalyWrapper(mapLangAndTypeAvailLang.get(l.id).get('Audio'));
           }    
           else
           {
               avlObj = new availableLangDispalyWrapper(null);
           }
           
           // Create Instance for Sub Language Type            
           avlObj.langName = l.name;
           avlObj.avlLang.Language_Types__c = 'Audio';
           avlObj.langId = l.id;  
           availableLangDispLst.add(avlObj);
           
           availableLangDispalyWrapper avlObj1 ;
           if(mapLangAndTypeAvailLang.containskey(l.id) && mapLangAndTypeAvailLang.get(l.id).containskey('Sub'))
           {
               avlObj1 = new availableLangDispalyWrapper(mapLangAndTypeAvailLang.get(l.id).get('Sub'));
           }    
           else
           {
               avlObj1 = new availableLangDispalyWrapper(null);
           }         
           avlObj1.langName = l.name;
           avlObj1.avlLang.Language_Types__c = 'Sub';
           avlObj1.langId = l.id;  
           availableLangDispLst.add(avlObj1);
        }
    }
  
     
     
    //Wrapper Class
    public class availableLangDispalyWrapper{
    
         public Available_Languages__c avlLang{get;set;}
         public string langName{get;set;}
         public Id langId{get; set;}
     
         availableLangDispalyWrapper(Available_Languages__c availLang)
         {
             if(availLang == null)
             {
                 avlLang =new Available_Languages__c();
                 avlLang.Clear_to_Avail__c = false;
             }
             else
                 avlLang =availLang;
         }
     } 
    
    public pageReference Cancel(){
        
        pageReference pageRef= new pageReference('/'+titleId);          
        return pageRef;
    
    }
    
    public pageReference SaveRecords(){
    
        List<Available_Languages__c> toUpsertAvailLang = new List<Available_Languages__c>();
        List<Available_Languages__c> toDeleteAvailLang = new List<Available_Languages__c>();
        pageReference pageRef= new pageReference('/'+titleId);

        List<string> LangSelectedNew = New list<String>();
             
         For(availableLangDispalyWrapper Wr: availableLangDispLst)
          {
          LangSelectedNew.add(Wr.langName);
          }
       system.debug('AlllanguagesAre ****' + LangSelectedNew);
       
        for(availableLangDispalyWrapper wrapperInstance : availableLangDispLst)
        {
           
            // Check if it is existing available language record.
            if(wrapperInstance.avlLang.id != null)
            {
                // Check if user wants to delete the record
                system.debug('CurrentLangInloop****' + wrapperInstance.langName);
                if(wrapperInstance.avlLang.Clear_to_Avail__c == false && 
                 wrapperInstance.avlLang.Mastering_Cost__c == null &&
                 wrapperInstance.avlLang.GPP_status__c == null &&         
                 wrapperInstance.avlLang.Mastering_Reason_Code__c == null &&
                 wrapperInstance.avlLang.GPP_Notes__c == null &&
                 wrapperInstance.avlLang.Mastering_IDS_Notes__c == null)
                {
                     system.debug('LanguageInDelete****' + wrapperInstance.langName);
                    toDeleteAvailLang .add(wrapperInstance.avlLang);
                }
                // Otherwise update the record
                else
                {
                    system.debug('LanguageInUpdate****' + wrapperInstance.langName);
                    toUpsertAvailLang.add(wrapperInstance.avlLang);
                }
            }
            // Else if Create a new record for Available Language.
            
            else if(wrapperInstance.avlLang.Clear_to_Avail__c != false || 
                wrapperInstance.avlLang.Mastering_Cost__c != null ||
                wrapperInstance.avlLang.GPP_status__c != null || 
                wrapperInstance.avlLang.Mastering_Reason_Code__c != null ||
                wrapperInstance.avlLang.GPP_Notes__c != null ||
                wrapperInstance.avlLang.Mastering_IDS_Notes__c != null)
            {
            
                system.debug('LanguageInAdd****' + wrapperInstance.langName);
                wrapperInstance.avlLang.Title__c = Id.valueOf(titleId);
                wrapperInstance.avlLang.Language__c=wrapperInstance.langId;
                toUpsertAvailLang.add(wrapperInstance.avlLang);
            }
        }
        // DML operations.
        try
        {   
            upsert toUpsertAvailLang;     
            delete toDeleteAvailLang;            
            return pageRef;
        }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
            system.debug('An exception occured'+e);
            return null;
        }
    
    }
        
}