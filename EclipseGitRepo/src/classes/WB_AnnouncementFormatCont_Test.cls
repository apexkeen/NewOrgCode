/******************
Created By : Navjyoti
Purpose : Code coverage for WB_AnnouncementFormatController class
myUnitTest1 : for positive senario
myUnitTest2 ; for negative senario
******************/
@isTest 
private class WB_AnnouncementFormatCont_Test{

    static testMethod void myUnitTest1(){
        Account acctGoogle = new Account(Name='TestGoogle');
        insert acctGoogle;
        
        Country__c countryFrance =new Country__c(Name ='TestFrance',Country_Code2__c ='TR',Country_Code__c='TF');
        insert countryFrance;
        
        Country_Groups__c countryGrp1 = new Country_Groups__c(Name = 'NewGrp',NameUnique__c ='UniqueNameTest');
        insert countryGrp1;
        
        Profile p = [select id from profile where name='System Administrator']; 
        User u = new User(alias = 'standt', email='testuser@testorg.com', 
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
        localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='superUser@testorg.com',profileid = p.Id);     
        insert u;
        
        Announcement_Rule__c newRule = new Announcement_Rule__c (Account__c = acctGoogle.Id,Announcement_Type__c ='NewType',DesignatedApprover__c =u.Id ,Country_Group__c = countryGrp1.Id);
        insert newRule;
        
         Test.startTest(); 
      
            PageReference pageRef = Page.WB_AnnouncementFormat;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', newRule.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(newRule);
            WB_AnnouncementFormatController controller = new WB_AnnouncementFormatController(sc);
            
            controller.getSelectedEmailTemp();
            controller.getSelectedRepTemp();
            controller.saveSelection();
            
            
            Test.stopTest();
        
        
    }
    static testMethod void myUnitTest2(){
        Account acctGoogle = new Account(Name='TestGoogle');
        insert acctGoogle;
        
        Country__c countryFrance =new Country__c(Name ='TestFrance',Country_Code2__c ='TR',Country_Code__c='TF');
        insert countryFrance;
        
        Country_Groups__c countryGrp1 = new Country_Groups__c(Name = 'NewGrp',NameUnique__c ='UniqueNameTest');
        insert countryGrp1;
        
        Profile p = [select id from profile where name='System Administrator']; 
        User u = new User(alias = 'standt', email='testuser@testorg.com', 
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
        localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='superUser@testorg.com',profileid = p.Id);     
        insert u;
        
        
        
        Announcement_Rule__c newRule = new Announcement_Rule__c (Account__c = acctGoogle.Id,Announcement_Type__c ='NewType',DesignatedApprover__c =u.Id ,Country_Group__c = countryGrp1.Id,Report_ID__c = 'NewReport' );
        insert newRule;
        
         Test.startTest(); 
      
            PageReference pageRef = Page.WB_AnnouncementFormat;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', newRule.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(newRule);
            WB_AnnouncementFormatController controller = new WB_AnnouncementFormatController(sc);
            
            
            controller.getSelectedEmailTemp();
            controller.getSelectedRepTemp();
            try{
            controller.saveSelection();
            }
            catch(Exception e){
            }
            
            
            Test.stopTest();
        
        
    }

}