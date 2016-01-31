/*******************************************************************************************************************************************
* File Name     :   WB_Batch_ClientAvailUpdateTest
* Description   :   A batch job for marking Confirmed Client Avails with no predefined price tiers
* @author       :   CTS
* Modification Log
===================================================================================================
* Ver.    Date              Author              Modification
---------------------------------------------------------------------------------------------------
* 1.0     8 Oct.2015        CTS					ER-000015 : Created the class.
* 2.0		
********************************************************************************************************************************************/

@isTest
public class WB_Batch_ClientAvailUpdateTest {
    
    private static testMethod void testBatch_ValidPriceTier() {
        
        Account acctGoogle = TestUtil.initAccount();
        insert acctGoogle;
        
        Announcement_Rule__c annType = TestUtil.initAnnouncementType(acctGoogle.id);
        
        Title__c title1 = TestUtil.initTitle('TestGoogle', '6000047545');
        insert title1;
        
        Country__c countryFrance = TestUtil.initCountry('TestFrance', 'TR', 'TF');
        insert countryFrance;
        
        Language__c languageFrench = TestUtil.initLanguage('TestFrench', '', 1);
        insert languageFrench;
        
        Local_Title__c localTitle = TestUtil.initLocalTitle(languageFrench.Id, countryFrance.Id);
        insert localTitle;
        
        Commercial_Avail__c CommercialAvail = TestUtil.initReleasePlan(title1.Id, localTitle.Id, countryFrance.Id, languageFrench.Id);
        insert CommercialAvail;
        
        Agreement__c storefrontGoogle1 = TestUtil.initStoreFront(acctGoogle.Id, countryFrance.Id, CommercialAvail, title1);
        insert storefrontGoogle1;
        
        Pricing__c pricing = TestUtil.initPricing(acctGoogle.Id, countryFrance.Id);
        insert pricing;
        
        Client_Avail__c clientAvail = TestUtil.initClientAvail(acctGoogle.Id, CommercialAvail, localTitle.Id);
        insert clientAvail;
        
        Client_Avail__c clientAvailInserted = [SELECT Name, Local_Title__r.Price_Code__c FROM Client_Avail__c];
        
        Local_Title__c localT = [Select Id,Price_Code__c from Local_Title__c where Id =: clientAvailInserted.Local_Title__c];
        localT.Price_Code__c = 'Direct To Video Catalog';
        update localT;
		 
		clientAvail.Status__c = 'Confirmed';
        update clientAvail;
        
        List<Client_Avail__c> clientAvailList = new List<Client_Avail__c>();
        clientAvailList.add(clientAvail);
        
        clientAvailList = [SELECT Client__c, Release_Plan_Country__c, Release_Plan_Format__c, Release_Plan_Channel__c, End_Date__c, Price_Tier_Text__c, 
                                               Title_Content_Type__c, Local_Title__r.Price_Code__c, Status__c, Validation_Failures__c 
                                        FROM Client_Avail__c where Id IN: clientAvailList];
        
		Test.startTest();
		WB_Batch_ClientAvailUpdate b = new WB_Batch_ClientAvailUpdate();
		Database.BatchableContext bc;
        b.start(bc);
        b.execute(bc,clientAvailList);
        b.finish(bc);
		Test.stopTest();
		
		List<Client_Avail__c> clientAvailUpdatedList = [SELECT Name, Validation_Failures__c FROM Client_Avail__c];
		system.assertEquals(Label.Valid_Price_Tier, clientAvailUpdatedList[0].Validation_Failures__c);
    }
    
    private static testMethod void testBatch_PriceTierNotFound() {
        
        Account acctGoogle = TestUtil.initAccount();
        insert acctGoogle;
        
        Title__c title1 = TestUtil.initTitle('TestGoogle', '6000047545');
        insert title1;
        
        Country__c countryFrance = TestUtil.initCountry('TestFrance', 'TR', 'TF');
        insert countryFrance;
        
        Language__c languageFrench = TestUtil.initLanguage('TestFrench', '', 1);
        insert languageFrench;
        
        Local_Title__c localTitle = TestUtil.initLocalTitle(languageFrench.Id, countryFrance.Id);
        insert localTitle;
        
        Commercial_Avail__c CommercialAvail = TestUtil.initReleasePlan(title1.Id, localTitle.Id, countryFrance.Id, languageFrench.Id);
        insert CommercialAvail;
        
        Agreement__c storefrontGoogle1 = TestUtil.initStoreFront(acctGoogle.Id, countryFrance.Id, CommercialAvail, title1);
        insert storefrontGoogle1;
        
        Pricing__c pricing = TestUtil.initPricing(acctGoogle.Id, countryFrance.Id);
        insert pricing;
        
        Client_Avail__c clientAvail = TestUtil.initClientAvail(acctGoogle.Id, CommercialAvail, localTitle.Id);
        insert clientAvail;
        
        Client_Avail__c clientAvailInserted = [SELECT Name, Local_Title__r.Price_Code__c FROM Client_Avail__c];
        
        Local_Title__c localT = [Select Id,Price_Code__c from Local_Title__c where Id =: clientAvailInserted.Local_Title__c];
        localT.Price_Code__c = 'Direct To Video Catalog';
        update localT;
		
		clientAvail.Status__c = 'Confirmed';
        update clientAvail;
        delete pricing;
        
        List<Client_Avail__c> clientAvailList = new List<Client_Avail__c>();
        clientAvailList.add(clientAvail);
        
        clientAvailList = [SELECT Client__c, Release_Plan_Country__c, Release_Plan_Format__c, Release_Plan_Channel__c, End_Date__c, Price_Tier_Text__c, 
                                               Title_Content_Type__c, Local_Title__r.Price_Code__c, Status__c, Validation_Failures__c 
                                        FROM Client_Avail__c where Id IN: clientAvailList];
        
		Test.startTest();
		WB_Batch_ClientAvailUpdate b = new WB_Batch_ClientAvailUpdate();
		Database.BatchableContext bc;
        b.start(bc);
        b.execute(bc,clientAvailList);
        b.finish(bc);
		Test.stopTest();
		
		List<Client_Avail__c> clientAvailUpdatedList = [SELECT Name, Validation_Failures__c FROM Client_Avail__c];
		system.assertEquals(Label.Price_Tier_Not_Found, clientAvailUpdatedList[0].Validation_Failures__c);
    }
    
    
        private static testMethod void testBatch_InvalidPriceTier() {
        
        Account acctGoogle = TestUtil.initAccount();
        insert acctGoogle;
        
        Title__c title1 = TestUtil.initTitle('TestGoogle', '6000047545');
        insert title1;
        
        Country__c countryFrance = TestUtil.initCountry('TestFrance', 'TR', 'TF');
        insert countryFrance;
        
        Language__c languageFrench = TestUtil.initLanguage('TestFrench', '', 1);
        insert languageFrench;
        
        Local_Title__c localTitle = TestUtil.initLocalTitle(languageFrench.Id, countryFrance.Id);
        insert localTitle;
        
        Commercial_Avail__c CommercialAvail = TestUtil.initReleasePlan(title1.Id, localTitle.Id, countryFrance.Id, languageFrench.Id);
        insert CommercialAvail;
        
        Agreement__c storefrontGoogle1 = TestUtil.initStoreFront(acctGoogle.Id, countryFrance.Id, CommercialAvail, title1);
        insert storefrontGoogle1;
        
        Pricing__c pricing = TestUtil.initPricing(acctGoogle.Id, countryFrance.Id);
        pricing.Price_Tier__c = 'test12345';
        insert pricing;
        
        Client_Avail__c clientAvail = TestUtil.initClientAvail(acctGoogle.Id, CommercialAvail, localTitle.Id);
        insert clientAvail;
        
        Client_Avail__c clientAvailInserted = [SELECT Name, Local_Title__r.Price_Code__c FROM Client_Avail__c];
        
        Local_Title__c localT = [Select Id,Price_Code__c from Local_Title__c where Id =: clientAvailInserted.Local_Title__c];
        localT.Price_Code__c = 'Direct To Video Catalog';
        update localT;
		
		clientAvail.Status__c = 'Tentative';
        update clientAvail;
        
        List<Client_Avail__c> clientAvailList = new List<Client_Avail__c>();
        clientAvailList.add(clientAvail);
        
        clientAvailList = [SELECT Client__c, Release_Plan_Country__c, Release_Plan_Format__c, Release_Plan_Channel__c, End_Date__c, Price_Tier_Text__c, 
                                               Title_Content_Type__c, Local_Title__r.Price_Code__c, Status__c, Validation_Failures__c 
                                        FROM Client_Avail__c where Id IN: clientAvailList];
        
		Test.startTest();
		WB_Batch_ClientAvailUpdate b = new WB_Batch_ClientAvailUpdate();
		Database.BatchableContext bc;
        b.start(bc);
        b.execute(bc,clientAvailList);
        b.finish(bc);
		Test.stopTest();
		
		List<Client_Avail__c> clientAvailUpdatedList = [SELECT Name, Validation_Failures__c FROM Client_Avail__c];
		system.assertEquals('Invalid Price Tier', clientAvailUpdatedList[0].Validation_Failures__c);
    }
    
}