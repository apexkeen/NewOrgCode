/*******************************************************************************************************************************************
* File Name     :   WB_Batch_CA_Upload_Test
* Description   :   Test class for WB_Batch_CA_Upload batch
* @author       :   CTS
* Modification Log
===================================================================================================
* Ver.    Date              Author              Modification
---------------------------------------------------------------------------------------------------
* 1.0     23 Nov.2015        CTS					ER-000069 : Created the class.
********************************************************************************************************************************************/

@isTest
public class WB_Batch_CA_Upload_Test {
    
    public static Account objAccount;
    public static CA_Upload__c caUpload;
    //public static Country__c countryFrance;
    //public static Language__c languageFrench;
    public static Local_Title__c localTitle;
    public static Agreement__c storefrontGoogle1;
    public static List<Pricing__c> pricingList;
    public static List<Client_Avail__c> clientAvailList;
    public static List<Title__c> titleList;
    public static List<Country__c> countryList;
    public static List<Language__c> languageList;
    public static List<Available_Languages__c> availLanguageList;
    public static List<Commercial_Avail__c> releasePlanList;
    
    static void setUpdata() {
        
        objAccount = TestUtil.initAccount();
        insert objAccount;
        
        titleList = new List<Title__c>();
        Title__c title1 = TestUtil.initTitle('Batman Begins', '6000047545');
        title1.Formats__c = 'SD; 4K UHD';
        titleList.add(title1);
        
        Title__c title2 = TestUtil.initTitle('Dark Knight', '6000047547');
        title2.Formats__c = 'SD; 4K UHD';
        title2.Content_Type__c = 'Season';
        titleList.add(title2);
        
        Title__c title3 = TestUtil.initTitle('Quantico', '6000047550');
        title3.Formats__c = 'SD;';
        title3.Content_Type__c = 'Episode';
        titleList.add(title3);
        insert titleList;
        
        countryList = new List<Country__c>();
        Country__c country1 = TestUtil.initCountry('USA', 'TR', 'TF');
        countryList.add(country1);
        Country__c country2 = TestUtil.initCountry('UK', 'TK', 'UF');
        countryList.add(country2);
        insert countryList;
        
        languageList = new List<Language__c>();
        Language__c language1 = TestUtil.initLanguage('English', '', 1);
        languageList.add(language1);
        insert languageList;
        
        availLanguageList = new List<Available_Languages__c>();
        Available_Languages__c availLang1 = TestUtil.initAvailableLang(languageList[0].Id, 'Sub', titleList[0].Id);
        Available_Languages__c availLang2 = TestUtil.initAvailableLang(languageList[0].Id, 'Audio', titleList[0].Id);
        availLanguageList.add(availLang1);
        availLanguageList.add(availLang2);
        insert availLanguageList;
        
        localTitle = TestUtil.initLocalTitle(languageList[0].Id, countryList[0].Id);
        insert localTitle;
        /*
        List<Local_Title__c> localData = [Select Id, Price_Code__c from Local_Title__c];
        system.debug('----------localData------------'+localData);
        
        if(localData.size() > 0) {
            localData[0].Price_Code__c = 'Direct To Video Catalog';
        }
        update localData[0];
        system.debug('----------localData-------2-----'+localData);
        */
        releasePlanList = new List<Commercial_Avail__c>();
        Commercial_Avail__c releasePlan1 = TestUtil.initReleasePlan(titleList[0].Id, localTitle.Id, countryList[0].Id, languageList[0].Id);
            releasePlan1.Channel__c = 'VODi';
            releasePlan1.Format__c = 'SD';
            releasePlan1.Language_Type__c = 'Sub & Audio';
            releasePlan1.Exclusive_Date__c = date.today()-200;
            releasePlan1.Start_Date__c = date.today()-100;
            releasePlan1.End_Date__c = date.today()+100;
            releasePlan1.Rights_End__c=date.today()+200;
        releasePlanList.add(releasePlan1);
        
        Commercial_Avail__c releasePlan2 = TestUtil.initReleasePlan(titleList[0].Id, localTitle.Id, countryList[0].Id, languageList[0].Id);
            releasePlan2.Channel__c = 'VODi';
            releasePlan2.Format__c = '4K UHD';
            releasePlan2.Language_Type__c = 'Sub & Audio';
            releasePlan2.Exclusive_Date__c = date.today()-200;
            releasePlan2.Start_Date__c = date.today()-100;
            releasePlan2.End_Date__c = date.today()+100;
            releasePlan2.Rights_End__c=date.today()+200;
        releasePlanList.add(releasePlan2);
        
        Commercial_Avail__c releasePlan3 = TestUtil.initReleasePlan(titleList[1].Id, localTitle.Id, countryList[0].Id, languageList[0].Id);
            releasePlan3.Channel__c = 'VODi';
            releasePlan3.Format__c = '4K UHD';
            releasePlan3.Language_Type__c = 'Sub & Audio';
            releasePlan3.Exclusive_Date__c = date.today()-200;
            releasePlan3.Start_Date__c = date.today()-100;
            releasePlan3.End_Date__c = date.today()+100;
            releasePlan3.Rights_End__c=date.today()+200;
        releasePlanList.add(releasePlan3);
        
        Commercial_Avail__c releasePlan4 = TestUtil.initReleasePlan(titleList[2].Id, localTitle.Id, countryList[0].Id, languageList[0].Id);
            releasePlan4.Channel__c = 'VODi';
            releasePlan4.Format__c = 'SD';
            releasePlan4.Language_Type__c = 'Sub & Audio';
            releasePlan4.Exclusive_Date__c = date.today()-200;
            releasePlan4.Start_Date__c = date.today()-100;
            releasePlan4.End_Date__c = date.today()+100;
            releasePlan4.Rights_End__c=date.today()+200;
        releasePlanList.add(releasePlan4);
        insert releasePlanList;
        
        List<Commercial_Avail__c> CommercialAvailList = [Select Id, Local_Title__c, Local_Title__r.Price_Code__c from Commercial_Avail__c where Id=: releasePlanList[0].Id];
        system.debug('----------CommercialAvailList------------'+CommercialAvailList);
        
        List<Local_Title__c> localData = [Select Id, Price_Code__c from Local_Title__c where Id=: CommercialAvailList[0].Local_Title__c];
        system.debug('----------localData------------'+localData);
        
        if(localData.size() > 0) {
            localData[0].Price_Code__c = 'Direct To Video Catalog';
            localData[0].Local_Rating__c = 'test | PG 2';
            localData[0].Local_Edit_Required__c = 'Yes';
            localData[0].Num_Local_Episodes__c = 10;
        }
        
        update localData[0];
        system.debug('----------localData-------2-----'+localData);


        storefrontGoogle1 = TestUtil.initStoreFront2(objAccount.Id, countryList[0].Id);
        insert storefrontGoogle1;
        
        pricingList = new List<Pricing__c>();
        Pricing__c pricing1 = TestUtil.initPricing(objAccount.Id, countryList[0].Id);
            pricing1.Channel__c = 'VODi';
            pricing1.Format__c = 'SD';
            pricing1.Price_Tier__c = 'test';
        pricingList.add(pricing1);
        insert pricingList;
        
        system.debug('--------pricingList-----------'+pricingList);
        
        caUpload = new CA_Upload__c(Upload_Status__c='Waiting To Process');
        insert caUpload;
    }
    static testmethod void myUnitTest1() {
        setUpdata();
         
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord(objAccount.name, 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord(objAccount.name, 'Catalog', caUpload, 'VODi', 'USA', System.today()-50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio','5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR3 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'India', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545'); 
        CA_Upload_Record__c objCAUR4 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'Hindi', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR5 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');        
        CA_Upload_Record__c objCAUR6 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'Hindi', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047546'); 
        CA_Upload_Record__c objCAUR7 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'HD', 'Episode Price Tier', 'English', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR8 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, '4K UHD', 'Episode Price Tier', 'English', 'Sub & Audio', '', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), '', System.today(), 'Draft', System.today()+50, '6000047547'); 
        CA_Upload_Record__c objCAUR9 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, '4K UHD', 'Episode Price Tier', 'English', 'Sub & Audio', '-5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');                                                                    
        CA_Upload_Record__c objCAUR10 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, '4K UHD', 'Episode Price Tier', 'English', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047550');
                                                                   
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        listCAUploadRecords.add(objCAUR3);
        listCAUploadRecords.add(objCAUR4);
        listCAUploadRecords.add(objCAUR5);
        listCAUploadRecords.add(objCAUR6);
        listCAUploadRecords.add(objCAUR7);
        listCAUploadRecords.add(objCAUR8);
        listCAUploadRecords.add(objCAUR9);
        listCAUploadRecords.add(objCAUR10);
        insert listCAUploadRecords;
        
        Test.startTest();
        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('schedule CA upload records', CRON_EXP, new WB_Batch_CA_Upload());
        /*WB_Batch_CA_Upload b = new WB_Batch_CA_Upload();
		Database.BatchableContext bc;
        b.start(bc);
        b.execute(bc,listCAUploadRecords);
        b.finish(bc);*/
        /*
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        */
        Test.stopTest();
    }
    
    
    static testmethod void myUnitTest2() {
        setUpdata();
        
        List<Pricing__c> pricingList1 = [Select Id, Format__c from Pricing__c];
        pricingList1[0].Price_Tier__c = 'Test PT';
        update pricingList1[0];
        
        Client_Avail__c clientAvail1 = TestUtil.initClientAvail(objAccount.Id, releasePlanList[0], localTitle.Id);
        insert clientAvail1;
        /*
        Client_Avail__c clientAvail2 = TestUtil.initClientAvail(objAccount.Id, releasePlanList[0], localTitle.Id);
        clientAvail2.Start_Date__c = System.today();
        clientAvail2.End_Date__c = System.today()+50;
        insert clientAvail2;
        */
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), '', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio','5', '10',
                                                                   '-2', 'test | PG 2', 'Yes', null, 'test', System.today(), 'Confirmed', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR3 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio','5', '10',
                                                                   '-2', 'test | PG 2', 'Yes', System.today()+60, 'test', System.today()+100, 'Confirmed', System.today()+50, '6000047545');                                                            
        CA_Upload_Record__c objCAUR8 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, '4K UHD', 'Episode Price Tier', 'English', 'Sub & Audio', '', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'Test Price Tier', System.today(), 'Confirmed', System.today()+50, '6000047547'); 
        CA_Upload_Record__c objCAUR9 = TestUtil.initCAUploadRecord('TestAccount', '', caUpload, 'VODi', 'USA', System.today()+50, '4K UHD', 'Episode Price Tier', 'English', 'Sub & Audio', '-5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');          
        objCAUR9.Change_Context__c='test123';
        CA_Upload_Record__c objCAUR10 = TestUtil.initCAUploadRecord(null, 'Catalog',caUpload , null, null, null, null, 'Episode Price Tier', null, null, '5$', null,
                                                                   '2', 'test | PG 2', 'Yes', null, 'test', null, null, null, null);
        
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        listCAUploadRecords.add(objCAUR3);
        listCAUploadRecords.add(objCAUR8);
        listCAUploadRecords.add(objCAUR9);
        listCAUploadRecords.add(objCAUR10);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
    }
    
    static testmethod void myUnitTest3() {
        setUpdata();
        
        List<Commercial_Avail__c> CAList = [Select Id, Status__c from Commercial_Avail__c where Id=: releasePlanList[0].Id];
        if(CAList.size() > 0) {
            CAList[0].Status__c = 'Draft';
        }
        update CAList[0];
        
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), '', System.today(), 'Draft', System.today()+50, '6000047545');
        
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), '', System.today(), 'Draft', System.today()+50, '6000047550');
                                                                   
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
    }
    
    static testmethod void myUnitTest4() {
        setUpdata();
        objAccount.Customer_Focus__c='Active';
        update objAccount;
        
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 
                                                                    'English', 'Sub & Audio', '5', '10', '10', 'test | PG 2', 'Yes', System.today(), '', 
                                                                    System.today(), 'Draft', System.today()+50, '6000047545');
               
        listCAUploadRecords.add(objCAUR1);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
    }
    
    
    static testmethod void myUnitTest5() {
        setUpdata();
        
        List<Title__c> titleListNew = [Select Id, Content_Type__c, Name from Title__c where Video_Version__c =: '6000047545'];
        if(titleListNew.size() > 0) {
            titleListNew[0].Content_Type__c = 'Episode';
            update titleListNew[0];
        }
        
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', 'Episode Price Tier', 'English', 'Sub & Audio', '5', '10',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord('TestAccount', 'Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 'English', 'Sub & Audio', '5', '',
                                                                   '2', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
                                                                   
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
    }
    
    static testmethod void myUnitTest6() {
        setUpdata();
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount', 'Direct To Video - Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 'English', 'Sub & Audio', '', '',
                                                                   '', 'test | PG 2', 'Yes', System.today(), 'test', System.today()+25, 'Draft', System.today()+23, '6000047545');
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord('TestAccount', 'Direct To Video - Catalog', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 'English', 'Sub & Audio', '', '',
                                                                   '', 'test | PG 2', 'Yes', System.today(), 'test', System.today()+25, 'Draft', System.today()+23, '6000047545');
    
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
        System.debug('********'+[select id,name,Errors__c from CA_Upload_Record__c]);
    }
    
    static testmethod void myUnitTest7() {
        setUpdata();
        List<CA_Upload_Record__c> listCAUploadRecords = new List<CA_Upload_Record__c>();
        objAccount.Customer_Focus__c = '';
        update objAccount;
        /* Account_Name, Category, CA_Upload, Channel, Country, End_Date, Format, Episode_Price_Tier, Language, Language_Type, WS_Cost, Episode_WSCost, Local_Data_No_Of_Episodes, 
        Local_Data_Rating, Local_Edit_Required, Pre_Order_Date, Price_Tier, Start_Date, Status, Suppression_Date, Video_Version */
        
        CA_Upload_Record__c objCAUR1 = TestUtil.initCAUploadRecord('TestAccount1', '-', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 'English', 'Sub & Audio', '', '',
                                                                   '', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
        CA_Upload_Record__c objCAUR2 = TestUtil.initCAUploadRecord('TestAccount', '-', caUpload, 'VODi', 'USA', System.today()+50, 'SD', '', 'English', 'Sub & Audio', '', '',
                                                                   '', 'test | PG 2', 'Yes', System.today(), 'test', System.today(), 'Draft', System.today()+50, '6000047545');
    
        listCAUploadRecords.add(objCAUR1);
        listCAUploadRecords.add(objCAUR2);
        insert listCAUploadRecords;
        
        Test.startTest();
        WB_Batch_CA_Upload batch = new WB_Batch_CA_Upload();
        Database.executebatch(batch,10);
        Test.stopTest();
        System.debug('********'+[select id,name,Errors__c from CA_Upload_Record__c]);
    }
}