/**
*  Description    :   Test Class for WB_Available_Language_RL_Controller
*  Author         :   Prachi Gadewar
   Emp ID         :   458725
*  Date           :   31 – Aug- 2015
*  
* =============================================================================================  
*                                     Change History
* =============================================================================================
*  Author                          Date                         Comment
*  Prachi Gadewar                  31/8/2015                    
*                                                               
*            
*  
*/

@isTest(seeAllData=false)
public with sharing class WB_Available_Language_RL_Controller_Test {

 public static UtilityClass_Test  utilClass = new UtilityClass_Test(); 
 
 testmethod  static void  testMethod1() {
        test.starttest();
        System.runAs(utilClass.getUserFromProfile('System Administrator')) {
             
             List<Available_Languages__c> resAvailList = new List<Available_Languages__c>();
             Language__c lang  = (Language__c)utilClass.createTestRecord(utilClass.setUpData(new Language__c (),0));
             Title__c titles  = (Title__c )utilClass.createTestRecord(utilClass.setUpData(new Title__c (),0));
             List<Available_Languages__c> availList = (list<Available_Languages__c>)utilClass.addMultiTestRecordsinList(new Available_Languages__c(), 1);
             availList[0].Title__c = titles.Id;
             availList[0].Clear_to_Avail__c = true;
             availList[0].Language__c = lang.id;
             
             /*availList[1].Title__c = titles.Id;
             availList[1].Clear_to_Avail__c = true;
             availList[1].Language__c = lang.id;
             
             availList[2].Title__c = titles.Id;
             availList[2].Clear_to_Avail__c = true;
             availList[2].Language__c = lang.id;*/
             
             insert availList;
            
             System.assertNotEquals(null, availList,'');
             
             Test.setCurrentPageReference(Page.WB_Available_Language_RL);
             ApexPages.CurrentPage().getparameters().put('Id', titles.id);
             ApexPages.StandardController sc = new ApexPages.standardController(titles);
             WB_Available_Language_RL_Controller availLangCtrl = new WB_Available_Language_RL_Controller(sc);
             Id langId = availLangCtrl.LangAvailId;
             String message = availLangCtrl.message;
             resAvailList = availLangCtrl.getAvailablelang_lst();
             System.assertNotEquals(null, resAvailList ,'');
             
             Pagereference pg = availLangCtrl.NewAvailLanguage();
             System.assertNotEquals(null,pg,'');
             
             
        
        }
        test.stoptest();
    }

}