/**
*  Description    :   Extention Class to create available language records for titles.
*  Author         :   Shekhar
   Emp ID         :   364679
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

public  with sharing class WB_Available_LangNew {

   public string titleId;
   public list<Available_Languages__c > availList;
   
   public list<WrapperLangWithObject> listofWrapper{get;set;}
  
   
   public WB_Available_LangNew(ApexPages.StandardController controller) {
     titleId = ApexPages.currentPage().getParameters().get('titleId');  
      listofWrapper = new list<WrapperLangWithObject>();
      list<Language__c> lanList = [select id, name from Language__c order by name asc]; 
      
      if(titleId !=null && lanlist.size() > 0)
       {
          availList = [select id, name,Language__c, Language_Types__c ,Clear_to_Avail__c ,GPP_status__c  from Available_Languages__c  where  Title__c = :titleId ];
       }
       
       system.debug('availListSize=' + availList.size());
        system.debug('availList=' + availList);
       
       Map<String, Available_Languages__c> mptwoAvailLangwithEachLang =  new  Map<String, Available_Languages__c>();
       
       if (availList.size() > 0 ) 
         {
           for(Available_Languages__c av : availList) 
            {
              if(av.Language_Types__c == 'Sub')
                { 
                  system.debug('COMBINATIONVALUE=' + av.Language__c + 'Sub');
                  mptwoAvailLangwithEachLang.put(av.Language__c + 'Sub', av);
                 
                 }
                 
              if(av.Language_Types__c == 'Audio')
                 {
                  system.debug('COMBINATIONVALUE2=' + av.Language__c + 'Audio');
                 mptwoAvailLangwithEachLang.put(av.Language__c + 'Audio', av);
                  }
            
            }
         }
       
        For(Language__c l : lanlist)
          {
            if(mptwoAvailLangwithEachLang.get(l.id+'Sub') !=null)
            {
             system.debug('COMBINATION3=' + l.id+'Sub');
             listofWrapper.add( new WrapperLangWithObject(l.name, 'Sub', l.id, mptwoAvailLangwithEachLang.get(l.id + 'Sub')));
             
            }
            else
             listofWrapper.add( new WrapperLangWithObject(l.name, 'Sub', l.id, new Available_Languages__c()));
             
           if(mptwoAvailLangwithEachLang.get(l.id+'Audio') !=null)
             {
              system.debug('COMBINATION4=' + l.id+'Audio');
             listofWrapper.add( new WrapperLangWithObject(l.name, 'Audio',l.id,  mptwoAvailLangwithEachLang.get(l.id + 'Audio')));
             }
            else
             listofWrapper.add( new WrapperLangWithObject(l.name, 'Audio',l.id, new Available_Languages__c()));
          }
      
    }
    
    public Class WrapperLangWithObject
   {
      public string  langType{get;set;} 
      public string LangName{get;set;}
      public string langId;
      public Available_Languages__c avlanguage {get ; set;}
      
      public WrapperLangWithObject(string lname , string lType , string lnId, Available_Languages__c avlan)
       {
         this.LangName = lname;
         this.avlanguage= avlan;  
         this.langType = lType;
         this.langId = lnId;
       }
   
   }


 public void saveRecords(){
 
  list<Available_Languages__c> AvailableLangtoUpdate  = new list<Available_Languages__c>();
  list<Available_Languages__c> AvailableLangtoDelete  = new list<Available_Languages__c>();

   For(WrapperLangWithObject w : listofWrapper) 
      {
         if (w.avlanguage.Clear_to_Avail__c == false  &&  w.avlanguage.GPP_status__c == null)
         {
            system.debug('NOWNOW');
            if (w.avlanguage.id != null)
             {
               system.debug('NOWIDNOTNULL');
               Available_Languages__c avNew =  new Available_Languages__c();
               avNew.Id = w.avlanguage.id ;
              AvailableLangtoDelete.add(avNew);
             }
         
         }
       
        else If (w.avlanguage.Clear_to_Avail__c != false  || w.avlanguage.GPP_status__c != null)
          { 
            system.debug('HEREHERE');
            Available_Languages__c avNew =  new Available_Languages__c();
            
             if (w.avlanguage.id != null)
                {                
                   system.debug('ExistingRecordNOTNULL');
                  avNew.id =w.avlanguage.id ;
                }
             
             if(w.avlanguage.id ==null )
               {
                system.debug('ExistingRecordNULL');
               avNew.Title__c = titleId ;
               avNew.Language__c  = w.langId ;
               }
             
              
              avNew.Language_Types__c= w.langType;
              avNew.Clear_to_Avail__c  =w.avlanguage.Clear_to_Avail__c;
              avNew.GPP_status__c = w.avlanguage.GPP_status__c ;
              
              AvailableLangtoUpdate.add(avNew);
               system.debug('RecordAddedForUpdateorInsert');
          }
      }
      
       try{
          If(AvailableLangtoDelete.size() > 0)
              { 
               system.debug('DeletedRecordSize=' + AvailableLangtoDelete.size());
               delete AvailableLangtoDelete;
               
              }
               
           If(AvailableLangtoUpdate.size() > 0)     
            {
              system.debug('InsertupdatedRecordSize=' + AvailableLangtoUpdate.size());
             upsert AvailableLangtoUpdate ;
            }
          }
        catch(exception e)
         { 
           
          
         }
       
     
 
 }
 
 public void cancel(){
 
 }
 
  
 
}