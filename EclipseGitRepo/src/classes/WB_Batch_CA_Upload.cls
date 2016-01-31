/*******************************************************************************************************************************************
* File Name     :   WB_Batch_CA_Upload
* Description   :   
* @author       :   CTS
* Modification Log
===================================================================================================
* Ver.    Date              Author              Modification
---------------------------------------------------------------------------------------------------
* 1.0     21 Oct.2015       CTS                 ER-000069 : Created the class.
* 2.0       
********************************************************************************************************************************************/

public with sharing class WB_Batch_CA_Upload implements Database.Batchable<sObject>,Database.Stateful,Schedulable
{
    Map<String,Id> mapCountryMapNameId = new Map<String,Id>();
    Map<String,Id> mapLanguageMapNameId = new Map<String,Id>();
    Map<String,Account> mapAccountMapNameId = new Map<String,Account>();
    set<Id> CAUploadIds = new set<Id>();
    
    public void execute(SchedulableContext ctx) 
    {   
        WB_Batch_CA_Upload CA = new WB_Batch_CA_Upload();
        database.executebatch(CA,10);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){   
         
        Set<String> setAccountName = new set<String>();
        for(Country__c country : [Select id,name from Country__c])
            mapCountryMapNameId.put(country.Name,country.id);
        for(Language__c lang : [Select id,name from Language__c])
            mapLanguageMapNameId .put(lang.Name,lang.id);
        
        String queryString ='SELECT Account_Name__c,Category__c,CA_upload_status__c,CA_Upload__c,Channel__c,Country__c,End_Date__c,Episode_Price_Tier__c,'
        +'Episode_SR_Price__c,Episode_WS_Cost__c,Format__c,Id,Language_Type__c,Language__c,Local_Data_No_Of_Episodes__c,Local_Data_Rating__c,'
        +'Local_Edit_Required__c,Name,Notes__c,Pre_Order_Date__c,Price_Tier__c,SR_Price__c,Start_Date__c,Status__c,Suppression_Date__c,'
        +'Title_Name__c,Errors__c,Video_Version__c,WS_Cost__c,Change_Context__c FROM CA_Upload_Record__c'
        +' Where CA_Upload__r.Upload_Status__c = \'Waiting To Process\' and CA_upload_status__c = null order by CA_Upload__c limit 50000';
        
        /*List<CA_Upload_Record__c> listCARecords = Database.query(queryString);
        
        system.debug('------listCARecords-------'+listCARecords);
        
        if(listCARecords != null)
        for(CA_Upload_Record__c record : listCARecords)
            setAccountName.add(record.Account_Name__c);*/
            
        List<Account> listAccount = [Select id,Name,Customer_Focus__c from Account];
        for(Account accountRec : listAccount)
            mapAccountMapNameId.put(accountRec.name,accountRec);
        
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext BC, List<CA_Upload_Record__c> scope){
    
        Boolean ErrorOcccured = false; 
        // Sets used to get common combination for Query.
        set<String> setTitleName = new Set<String>();
        set<String> setVVNumber = new Set<String>();
        set<String> setLangName = new Set<String>();
        set<String> setLangType = new Set<String>();
        set<String> setChannels = new Set<String>();
        set<String> setFormats = new Set<String>();
        set<String> setCountries = new Set<String>();
        set<String> setAccounts = new Set<String>();
        set<String> setContentTypes = new Set<String>();
        set<String> setPriceCodes = new Set<String>();
        
        // Maps used to compare data in client avail and release plan.
        Map<String,Title__c> mapTitleNameRecord = new Map<String,Title__c>();
        Map<String,Title__c> mapTitleVVCARecord = new Map<String,Title__c>();
        Map<String,Map<String,String>> mapLangAndType = new Map<String,Map<String,String>>();
        Map<String,Map<String,Map<String,set<String>>>> mapFormat = new Map<String,Map<String,Map<String,set<String>>>>();  //Map<Title,Map<Lang,Map<country,Set<Format>>>>
        Map<String,Map<String,Map<String,set<String>>>> mapChannel = new Map<String,Map<String,Map<String,set<String>>>>();  //Map<Title,Map<Lang,Map<country,Set<Channel>>>>
        Map<String,Map<String,Map<String,Map<String,Map<String,List<Commercial_Avail__c>>>>>> mapDates = new Map<String,Map<String,Map<String,Map<String,Map<String,List<Commercial_Avail__c>>>>>>(); //Map<Title,Map<Lang,Map<country,Map<Format,Map<Channel,Commercial_Avail__c>>>>>>
        Map<id,CA_Upload_Record__c> mapCARecords = new Map<id,CA_Upload_Record__c>();
        Map<id,Integer> countErrorMessages = new Map<id,Integer>();
        Map<id,Boolean> flagErrorMessages = new Map<id,Boolean>();
        
        // Map contains newly created client avails to check date overlapping in new client avail
        // VV,Language,Format,Country,Channel,Account,Client Avail 
        Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,List<Client_Avail__c>>>>>>> mapNewClientAvails = new Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,List<Client_Avail__c>>>>>>>();
        
        // Used to create and link Client avail records.
        Map<CA_Upload_Record__c,Commercial_Avail__c> mapCARecordRPRecord = new Map<CA_Upload_Record__c,Commercial_Avail__c>();
        Map<CA_Upload_Record__c,Client_Avail__c> mapClientAvailTobeInsert = new Map<CA_Upload_Record__c,Client_Avail__c>();
        List<CA_Upload_Record__c> listTobeUpdateCARecord = new List<CA_Upload_Record__c>();
        
        // Get alll possible combination for selected CA upload records.
        for(CA_Upload_Record__c record : scope)
        {
            CAUploadIds.add(record.CA_Upload__c);
            if(record.Video_Version__c != null) setVVNumber.add(record.Video_Version__c);
            if(record.Language__c != null) setLangName.add(record.Language__c);
            if(record.Language_Type__c != null) setLangType.add(record.Language_Type__c);
            if(record.Channel__c != null) setChannels.add(record.Channel__c);
            if(record.Format__c != null) setFormats.add(record.Format__c);
            if(record.Country__c != null) setCountries.add(record.Country__c);
            if(record.Account_Name__c != null) setAccounts.add(record.Account_Name__c);
            countErrorMessages.put(record.id,1);
        }

        // Prepare Title Map Name with Id which will used to fetch id based on title Name.
        for(Title__c title : [Select id,Name,Video_Version__c,Content_Type__c from Title__c where Video_Version__c in: setVVNumber])
        {
            mapTitleNameRecord.put(title.Name,title);
            mapTitleVVCARecord.put(title.Video_Version__c,title);
            setTitleName.add(title.Name);
        }
            
        // Prepare map of Title and their related Language and Language Types.
        for(Available_Languages__c availLang : [Select id,Title__r.name,Title__r.Video_Version__c,Language__r.name,Language_Types__c from Available_Languages__c where Title__r.Video_Version__c in: setVVNumber and Language__r.name in: setLangName and Clear_to_avail__c = true])
        {   
            system.debug('****availLang '+availLang);
            //Removed old logic related to lang type - Prachi - 18-12-2015
            if(!mapLangAndType.containskey(availLang.Title__r.Video_Version__c)) 
                mapLangAndType.put(availLang.Title__r.Video_Version__c,new Map<String,String>());
            //mapLangAndType.get(availLang.Title__r.Video_Version__c).add(availLang.Language__r.name);*/
            if(mapLangAndType.get(availLang.Title__r.Video_Version__c).containskey(availLang.Language__r.name))
                mapLangAndType.get(availLang.Title__r.Video_Version__c).put(availLang.Language__r.name,'Sub & Audio');
            else    
                mapLangAndType.get(availLang.Title__r.Video_Version__c).put(availLang.Language__r.name,availLang.Language_Types__c);
            
        }
        system.debug('****mapLangAndType : '+mapLangAndType);
        Map<String,Map<String,Map<String,Local_Title__c>>> mapLocalTitle = new Map<String,Map<String,Map<String,Local_Title__c>>>();
        
        // Prepare Map of Local Data records
        for(Local_Title__c localTitle : [SELECT Language__r.name, Country__r.name,Local_Episodes__c,Local_Edit_Required__c,Num_Local_Episodes__c,Local_Rating__c,Price_Code__c,Rating_Code__c,Title__r.Video_Version__c FROM Local_Title__c where Title__r.Video_Version__c in: setVVNumber])
        {
            if(!mapLocalTitle.containskey(localTitle.Title__r.Video_Version__c))
                mapLocalTitle.put(localTitle.Title__r.Video_Version__c,new Map<String,Map<String,Local_Title__c>>());
            if(!mapLocalTitle.get(localTitle.Title__r.Video_Version__c).containskey(localTitle.Language__r.name))
                mapLocalTitle.get(localTitle.Title__r.Video_Version__c).put(localTitle.Language__r.name,new Map<String,Local_Title__c>());                
            if(!mapLocalTitle.get(localTitle.Title__r.Video_Version__c).get(localTitle.Language__r.name).containskey(localTitle.Country__r.name))
                mapLocalTitle.get(localTitle.Title__r.Video_Version__c).get(localTitle.Language__r.name).put(localTitle.Country__r.name,localTitle);
        }             
        // Prepare Maps which will used to compare the CA upload records with Releas plans records.
        for(Commercial_Avail__c releaseplan : [Select id,Title__r.Video_Version__c,name,Languages__r.Name,Country_Lookup__r.Name,Format__c,Channel__c,Title__r.Content_Type__c,Start_Date__c,
                                End_Date__c,Status__c,Local_Title__r.Price_Code__c,Local_Title__r.Local_Edit_Required__c,Local_Title__r.Num_Local_Episodes__c,Local_Title__r.Local_Rating__c
                                from Commercial_Avail__c where Title__c in: mapTitleNameRecord.values() 
                                AND Languages__r.Name in : setLangName AND Language_Type__c in: setLangType AND Country_Lookup__r.Name in: setCountries])
        {
            if(!mapFormat.containskey(releaseplan.Title__r.Video_Version__c))
            {
                mapFormat.put(releaseplan.Title__r.Video_Version__c,new Map<String,Map<String,set<String>>>());
                mapChannel.put(releaseplan.Title__r.Video_Version__c,new Map<String,Map<String,set<String>>>());
                mapDates.put(releaseplan.Title__r.Video_Version__c,new Map<String,Map<String,Map<String,Map<String,List<Commercial_Avail__c>>>>>());
            }
            if(!mapFormat.get(releaseplan.Title__r.Video_Version__c).containskey(releaseplan.Languages__r.Name))
            {
                mapFormat.get(releaseplan.Title__r.Video_Version__c).put(releaseplan.Languages__r.Name,new Map<String,set<String>>());
                mapChannel.get(releaseplan.Title__r.Video_Version__c).put(releaseplan.Languages__r.Name,new Map<String,set<String>>());
                mapDates.get(releaseplan.Title__r.Video_Version__c).put(releaseplan.Languages__r.Name,new Map<String,Map<String,Map<String,List<Commercial_Avail__c>>>>());
            }
            if(!mapFormat.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).containskey(releaseplan.Country_Lookup__r.Name))
            {
                mapFormat.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).put(releaseplan.Country_Lookup__r.Name,new set<String>());
                mapChannel.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).put(releaseplan.Country_Lookup__r.Name,new set<String>());
                mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).put(releaseplan.Country_Lookup__r.Name,new Map<String,Map<String,List<Commercial_Avail__c>>>());
            }
            mapFormat.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).add(releaseplan.Format__c);
            mapChannel.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).add(releaseplan.Channel__c);
            if(!mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).containskey(releaseplan.Format__c))
                mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).put(releaseplan.Format__c,new Map<String,List<Commercial_Avail__c>>());
            if(!mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).get(releaseplan.Format__c).containskey(releaseplan.Channel__c))
                mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).get(releaseplan.Format__c).put(releaseplan.Channel__c,new List<Commercial_Avail__c>());
            mapDates.get(releaseplan.Title__r.Video_Version__c).get(releaseplan.Languages__r.Name).get(releaseplan.Country_Lookup__r.Name).get(releaseplan.Format__c).get(releaseplan.Channel__c).add(releaseplan);
        }
        
        // Get Storefront records to perform storefront related validation
        Map<String,Map<string,Set<String>>> mapCountryAccountChannelsSF = new Map<String,Map<string,Set<String>>>();
        Map<String,Map<string,Set<String>>> mapCountryAccountFormatsSF = new Map<String,Map<string,Set<String>>>();
        Map<String,Map<string,Set<String>>> mapCountryAccountCTsSF = new Map<String,Map<string,Set<String>>>();
        Map<String,Map<string,Agreement__c>> mapCountryAccountSF = new Map<String,Map<string,Agreement__c>>();
        Map<Id,Id> mapCAUploadRecordIdSFId = new Map<Id,Id>();
        
        for(Agreement__c sf : [Select id,Status__c,Channel_Picklist__c,Format__c,Content_Type__c,Country__r.Name,Account__r.Name from Agreement__c where Country__r.name in: setCountries AND Account__r.Name in: setAccounts])
        {
            if(!mapCountryAccountSF.containskey(sf.Country__r.Name))
                mapCountryAccountSF.put(sf.Country__r.Name,new Map<string,Agreement__c>());
            mapCountryAccountSF.get(sf.Country__r.Name).put(sf.Account__r.Name,sf);
            
            system.debug('--------c-----1------'+mapCountryAccountSF);
            
            if(sf.Channel_Picklist__c != null)
            {
                if(!mapCountryAccountChannelsSF.containskey(sf.Country__c))
                    mapCountryAccountChannelsSF.put(sf.Country__r.Name,new Map<string,Set<String>>());
                if(!mapCountryAccountChannelsSF.get(sf.Country__r.Name).containskey(sf.Account__r.Name))
                    mapCountryAccountChannelsSF.get(sf.Country__r.Name).put(sf.Account__r.Name,new Set<String>());
                mapCountryAccountChannelsSF.get(sf.Country__r.Name).get(sf.Account__r.Name).addall(sf.Channel_Picklist__c.split(';'));
            }
            if(sf.Format__c != null)
            {
                if(!mapCountryAccountFormatsSF.containskey(sf.Country__r.Name))
                    mapCountryAccountFormatsSF.put(sf.Country__r.Name,new Map<string,Set<String>>());
                if(!mapCountryAccountFormatsSF.get(sf.Country__r.Name).containskey(sf.Account__r.Name))
                    mapCountryAccountFormatsSF.get(sf.Country__r.Name).put(sf.Account__r.Name,new Set<String>());
                mapCountryAccountFormatsSF.get(sf.Country__r.Name).get(sf.Account__r.Name).addall(sf.Format__c.split(';'));
            }
            if(sf.Content_Type__c != null)
            {
                if(!mapCountryAccountCTsSF.containskey(sf.Country__r.Name))
                    mapCountryAccountCTsSF.put(sf.Country__r.Name,new Map<string,Set<String>>());
                if(!mapCountryAccountCTsSF.get(sf.Country__r.Name).containskey(sf.Account__r.Name))
                    mapCountryAccountCTsSF.get(sf.Country__r.Name).put(sf.Account__r.Name,new Set<String>());
                mapCountryAccountCTsSF.get(sf.Country__r.Name).get(sf.Account__r.Name).addall(sf.Content_Type__c.split(';'));
            }
        }
        System.debug('-----mapCountryAccountChannelsSF---------'+mapCountryAccountChannelsSF);
        System.debug('-----mapCountryAccountFormatsSF---------'+mapCountryAccountFormatsSF);
        
        System.debug('-----mapCARecordRPRecord---------'+mapCARecordRPRecord);
        
        setTitleName.clear();
        setVVNumber.clear();
        setLangName.clear();
        setLangType.clear();
        
        system.debug('------scope-------'+scope);
        
        // Get all values available in Category Picklist.
        Set<String> setCategogyPicklistValues = new Set<String>();
        for( Schema.PicklistEntry f : Client_Avail__c.Local_Data_Category_Picklist__c.getDescribe().getPicklistValues())
            setCategogyPicklistValues.add(f.getValue());
            
        // Get all values available in Change Context Picklist.
        Set<String> setChangeContextPicklistValues = new Set<String>();
        for( Schema.PicklistEntry f : Client_Avail__c.Change_Context__c.getDescribe().getPicklistValues())
            setChangeContextPicklistValues.add(f.getValue());
            
        // Process All CA upload records and give proper errors if any difference or looks like missing.
        for(CA_Upload_Record__c record : scope)
        {
            String Error_Messages='';
            Integer Count=countErrorMessages.get(record.id);
            flagErrorMessages.put(record.id,false);
            try{
            
            // Check for Country
            if(record.Country__c != null && !mapCountryMapNameId.containskey(record.Country__c))
                Error_Messages += count++ + Label.WB_Batch_Error_Country_Not_Available+'\n';

            // Check for Language
            if(record.Language__c != null && !mapLanguageMapNameId.containskey(record.Language__c))
                Error_Messages += count++ + Label.WB_Batch_Error_Language_Not_Available+'\n';
                
            // Added all Manadatory fields related validations.
            // Give error if Video version is not available.
            if(record.Video_Version__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_VV_Mandatory+'\n';
                
            // Give error if Country is not available.
            if(record.Country__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Country_Mandatory+'\n';
                
            // Give error if Account is not available.
            if(record.Account_Name__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Account_Mandatory+'\n';
            
            // Give error if Start Date is not available.
            if(record.Start_Date__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_StartDate_Mandatory+'\n';
            
            // Give error if End Date is not available.
            if(record.End_Date__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_EndDate_Mandatory+'\n';
            
            // Give error if Status is not available.
            if(record.Status__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Status_Mandatory+'\n';
            
            // Give error if Language Type is not available.
            if(record.Language_Type__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Language_Type_Mandatory+'\n';
            
            // Give error if Format is not available.
            if(record.Format__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Format_Mandatory+'\n';
            
            // Give error if Channel is not available.
            if(record.Channel__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Channel_Mandatory+'\n';
               
            // Check for Account, give error it is active or not
            if(record.Account_Name__c != null && mapAccountMapNameId != null && mapAccountMapNameId.containskey(record.Account_Name__c))  
            {
                if(mapAccountMapNameId.get(record.Account_Name__c).Customer_Focus__c != 'Active')
                    Error_Messages += count++ + Label.WB_Batch_Error_Account_Not_Active+'\n';  
            }
            else if(record.Account_Name__c != null)
                Error_Messages += count++ + Label.WB_Batch_Error_Account_Not_Available+'\n';  
            
            
            // Check for existing Title present in salesforce or not
            if(mapTitleVVCARecord!= null && mapTitleVVCARecord.containskey(record.Video_Version__c) && record.Video_Version__c != null)
            {
                setContentTypes.add(mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c);
                if(mapLangAndType != null && mapLangAndType.containsKey(record.Video_Version__c) && mapLangAndType.get(record.Video_Version__c).containsKey(record.Language__c) )
                {
                    if(mapLangAndType.get(record.Video_Version__c).get(record.Language__c) != record.Language_Type__c && record.Language_Type__c != null && record.Language__c != null)
                        Error_Messages += count++ + Label.WB_Batch_Error_Language_Not_Matching+'\n';
                }
                else if(record.Language_Type__c != null && record.Language__c != null)
                    Error_Messages += count++ + Label.WB_Batch_Error_Language_Not_Matching+'\n';
            }
            else if((mapTitleVVCARecord == null || !mapTitleVVCARecord.containsKey(record.Video_Version__c)) && record.Video_Version__c != null)
                Error_Messages += count++ + Label.WB_Batch_Error_VV_Not_Available+'\n';
            System.debug('-------Error_Messages : '+Error_Messages);
            
            // Check for release plan record
            if(Error_Messages == '')
            {
                System.debug('*****'+mapFormat);
                //System.debug('****'+mapFormat.get(record.Video_Version__c));
                //System.debug('***'+mapFormat.get(record.Video_Version__c).get(record.Language__c));
                /*if(mapFormat != null &&
                    mapFormat.get(record.Video_Version__c) != null &&
                    mapFormat.get(record.Video_Version__c).get(record.Language__c) != null &&
                    mapFormat.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c) != null)
                {
                    if(!mapFormat.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).contains(record.Format__c))
                        Error_Messages += count++ + Label.WB_Batch_Error_RP_Format_Wrong+'\n';
                }
                if(mapChannel != null &&
                    mapChannel.get(record.Video_Version__c) != null &&
                    mapChannel.get(record.Video_Version__c).get(record.Language__c) != null &&
                    mapChannel.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c) != null)
                {
                    if(!mapChannel.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).contains(record.Channel__c))
                        Error_Messages += count++ + Label.WB_Batch_Error_RP_Channel_Wrong+'\n';
                }*/
                
                System.debug('-----mapDates---------'+mapDates);
                /*if(Error_Messages == '')
                {*/
                    Boolean RPStatusVR = false;
                    Boolean RPMatching=false;
                    if(mapDates != null 
                    && mapDates.get(record.Video_Version__c) != null 
                    && mapDates.get(record.Video_Version__c).get(record.Language__c) != null 
                    && mapDates.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c) != null 
                    && mapDates.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).get(record.Format__c) != null 
                    && mapDates.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c) != null
                    && mapDates.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c).size() > 0)
                    {
                        for(Commercial_Avail__c matchingReleasePlan : mapDates.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c))
                        {
                            System.debug('-----matchingReleasePlan---------'+matchingReleasePlan);
                            System.debug('Date condition 1 : '+ (matchingReleasePlan.Start_Date__c <= record.Start_Date__c));
                            System.debug('Date condition 2 : '+ (matchingReleasePlan.End_Date__c >= record.End_Date__c));
                            if(matchingReleasePlan.Start_Date__c <= record.Start_Date__c &&
                               matchingReleasePlan.End_Date__c >= record.End_Date__c)
                            {
                                
                                mapCARecordRPRecord.put(record,matchingReleasePlan); 
                                if(matchingReleasePlan.Status__c == 'Confirmed' || matchingReleasePlan.Status__c == 'Tentative')
                                {
                                    setPriceCodes.add(matchingReleasePlan.Local_Title__r.Price_Code__c);
                                    System.debug('-----setPriceCodes---------'+setPriceCodes);
                                    //record.CA_upload_status__c='Successful';
                                    //mapClientAvailTobeInsert.put(record,new Client_Avail__c(Commercial_Avail__c=matchingReleasePlan.id,Status__c=record.Status__c,Client__c=mapAccountMapNameId.get(record.Account_Name__c)));
                                    RPMatching=true;
                                    //break;
                                }
                                else
                                    RPStatusVR = true;
                            }
                            else if(!(matchingReleasePlan.Status__c == 'Confirmed' || matchingReleasePlan.Status__c == 'Tentative'))
                                RPStatusVR = true;
                            //// Add error for dates not matching with release plan dates. 
                        }
                        if(!RPMatching && !RPStatusVR)
                            Error_Messages += count++ + Label.WB_Batch_Error_CA_Dates_Within_RP_Dates+'\n';
                        if(RPStatusVR)
                            Error_Messages += count++ + Label.WB_Batch_Error_RP_should_Confirmed_or_Tentative+'\n';
                    }   
                    if(!RPMatching && Error_Messages == '')
                        Error_Messages += count++ + Label.WB_Batch_Error_RP_Not_Found+'\n';
                        
                //}
            }
            
            // If release plan not available and local data record present then  preform Validations on comparision of Local Data fields matches
            if(!mapCARecordRPRecord.containsKey(record) && record.Video_Version__c != null && (record.Local_Edit_Required__c != null || record.Local_Data_Rating__c != null || record.Local_Data_No_Of_Episodes__c != null))
            {
                if(mapLocalTitle != null && 
                   mapLocalTitle.containsKey(record.Video_Version__c) && 
                   mapLocalTitle.get(record.Video_Version__c).containsKey(record.Language__c) &&
                   mapLocalTitle.get(record.Video_Version__c).get(record.Language__c).containsKey(record.Country__c))
                {
                    Local_Title__c localTitle = mapLocalTitle.get(record.Video_Version__c).get(record.Language__c).get(record.Country__c);
                    if(record.Local_Edit_Required__c != null && localTitle.Local_Edit_Required__c != record.Local_Edit_Required__c) 
                        Error_Messages += count++ + Label.WB_Batch_Error_Local_Data_Req_not_matching_with_Local_Data+'\n';  
                    if(record.Local_Data_Rating__c != null && localTitle.Local_Rating__c != record.Local_Data_Rating__c) 
                        Error_Messages += count++ + Label.WB_Batch_Error_Local_Data_Rating_not_matching_with_Local_Data+'\n';  
                    if(record.Local_Data_No_Of_Episodes__c != null && localTitle.Num_Local_Episodes__c != Decimal.valueof(record.Local_Data_No_Of_Episodes__c)) 
                        Error_Messages += count++ + Label.WB_Batch_Error_Num_od_Episode_not_matching_with_Local_Data+'\n';
                }
            }
            
            
            // Check status for inserting client avail
            if(record.Status__c != 'Draft')
                Error_Messages += count++ + Label.WB_Batch_Error_CA_Status_must_be_Draft+'\n';
                
            // Validation to check if Active storefront available or not if available then assign storefront to Client Avail to field.
            if(mapCountryAccountSF != null && mapCountryAccountSF.containskey(record.Country__c) && mapCountryAccountSF.get(record.Country__c).containskey(record.Account_Name__c) && mapCountryAccountSF.get(record.Country__c).get(record.Account_Name__c) != null)
            {
                System.debug('========mapCountryAccountFormatsSF==========='+mapCountryAccountFormatsSF);
                // Check channel is available on matching Storefront
                if(record.Channel__c != null && mapCountryAccountChannelsSF == null || mapCountryAccountChannelsSF.size() == 0)
                    Error_Messages += count++ + Label.WB_Batch_Error_Channel_wrong_in_Storefront+'\n';
                else if(record.Channel__c != null && mapCountryAccountChannelsSF != null && mapCountryAccountChannelsSF.containskey(record.Country__c) && mapCountryAccountChannelsSF.get(record.Country__c).containskey(record.Account_Name__c) && !mapCountryAccountChannelsSF.get(record.Country__c).get(record.Account_Name__c).contains(record.Channel__c))
                    Error_Messages += count++ + Label.WB_Batch_Error_Channel_wrong_in_Storefront+'\n';
                
                // Check Format is available on matching Storefront    
                if(record.Format__c != null && mapCountryAccountFormatsSF == null || mapCountryAccountFormatsSF.size() == 0)
                    Error_Messages += count++ + Label.WB_Batch_Error_Format_wrong_in_Storefront+'\n';
                else if(record.Format__c != null && mapCountryAccountFormatsSF != null && mapCountryAccountFormatsSF.containskey(record.Country__c) && mapCountryAccountFormatsSF.get(record.Country__c).containskey(record.Account_Name__c) && !mapCountryAccountFormatsSF.get(record.Country__c).get(record.Account_Name__c).contains(record.Format__c))
                    Error_Messages += count++ + Label.WB_Batch_Error_Format_wrong_in_Storefront+'\n';
                
                // Check content type of VV is available on matching Storefront. 
                if(record.Video_Version__c != null && mapTitleVVCARecord.get(record.Video_Version__c) != null)
                {
                    if(mapCountryAccountCTsSF == null || mapCountryAccountCTsSF.size() == 0)
                        Error_Messages += count++ + Label.WB_Batch_Error_CT_wrong_in_Storefront+'\n';
                    else if(mapCountryAccountCTsSF.containskey(record.Country__c) && mapCountryAccountCTsSF.get(record.Country__c).containskey(record.Account_Name__c) && !mapCountryAccountCTsSF.get(record.Country__c).get(record.Account_Name__c).contains(mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c) )
                        Error_Messages += count++ + Label.WB_Batch_Error_CT_wrong_in_Storefront+'\n';    
                }
                
                if(mapCountryAccountSF != null && mapCountryAccountSF.get(record.Country__c).get(record.Account_Name__c).Status__c == 'Active')
                    mapCAUploadRecordIdSFId.put(record.id,mapCountryAccountSF.get(record.Country__c).get(record.Account_Name__c).id);
                else
                    Error_Messages += count++ + Label.WB_Batch_Error_SF_Status+'\n';
            }
            else if(record.Country__c != null && record.Account_Name__c != null && record.Video_Version__c != null)
                Error_Messages += count++ + Label.WB_Batch_Error_Storefront_Not_Available+'\n';
    
            
            // Add basic validation rules for client avail here.
            if(record.Start_Date__c > record.End_Date__c)
                Error_Messages += count++ + Label.WB_Batch_Error_Start_Date_not_End_Date+'\n';   
                
            // Category picklist value validation
            if(record.Category__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_Category_Field_Mandatory+'\n';
            else if(setCategogyPicklistValues != null && !setCategogyPicklistValues.contains(record.Category__c))
                Error_Messages += count++ + Label.WB_Batch_Error_Category_value_is_wrong+'\n';
            
            // Change Context Picklist value validation
            if(setChangeContextPicklistValues != null && record.Change_Context__c != null && !setChangeContextPicklistValues.contains(record.Change_Context__c))
                Error_Messages += count++ + Label.WB_Batch_Error_Change_Context_value_is_wrong+'\n';
            
            // Need to perform all validations comes through excel sheet.
            if(record.WS_Cost__c != null && record.Price_Tier__c != null)
                Error_Messages += count++ + Label.WB_Batch_Error_Enter_Either_Price_Tier_or_WS_cost+'\n';
            if(record.Episode_Price_Tier__c != null && record.Episode_WS_Cost__c != null)
                Error_Messages += count++ + Label.WB_Batch_Error_Enter_Either_Price_Tier_or_WS_cost_Episode+'\n';
                
            system.debug('---------record.WS_Cost__c-----------'+record.WS_Cost__c);     
            if(record.WS_Cost__c != null && Decimal.valueof(record.WS_Cost__c) < 0)
                Error_Messages += count++ + Label.WB_Batch_Error_WS_cost_should_be_positive_number+'\n';
             
            /* Removed validation as per discussion with Nalin 12-10-2015
            system.debug('---------mapTitleVVCARecord-----------'+mapTitleVVCARecord);    
            if(record.Local_Data_No_Of_Episodes__c == null && mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c != 'Season')
                Error_Messages += count++ + Label.WB_Batch_Error_Season_and_no_of_Episode_validation+'\n';*/
            if(record.Local_Data_No_Of_Episodes__c != null && Decimal.valueof(record.Local_Data_No_Of_Episodes__c) < 0)
                Error_Messages += count++ + Label.WB_Batch_Error_no_of_Episode_Valid_number+'\n';
            
            // Removed this validation - Prachi - 18-12-2015
            /* Episode related validations from Excel sheet
            if(mapTitleVVCARecord.get(record.Video_Version__c) != null && (mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c == 'Episode' || mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c == 'Season' ))
            {
                if(record.Episode_Price_Tier__c == null && record.Episode_WS_Cost__c == null)
                    Error_Messages += count++ + Label.WB_Batch_Error_Episode_VV_should_have_values+'\n';
                if(record.Price_Tier__c != null || record.WS_Cost__c != null)
                    Error_Messages += count++ + Label.WB_Batch_Error_Episode_VV_Validation+'\n';
            }*/
            if(record.Video_Version__c != null && mapTitleVVCARecord.get(record.Video_Version__c) != null)
            {
                /* Changed condition as per validation rule on client avail - Prachi - 18-12-2015
                if(record.Episode_Price_Tier__c != null || record.Episode_WS_Cost__c != null)*/
                if(mapTitleVVCARecord.get(record.Video_Version__c).Content_Type__c != 'Season' && (record.Episode_Price_Tier__c != null || record.Episode_WS_Cost__c != null))
                    Error_Messages += count++ + Label.WB_Batch_Error_VV_not_Episode_Validation+'\n';
                if(record.Price_Tier__c == null && record.WS_Cost__c == null)
                    Error_Messages += count++ + Label.WB_Batch_Error_VV_not_Episode_Validation2+'\n';
                    
            }
            
            // Removed vice versa condition - Prachi - 18-12-2015
            if(record.Suppression_Date__c != null)
            {
                if(record.Pre_Order_Date__c == null)
                Error_Messages += count++ + Label.WB_Batch_Error_APO_Date_Validation+'\n';    
            }
            // Removed else - Prachi - 18-12-2015
            if(record.Pre_Order_Date__c != null && record.Suppression_Date__c != null && record.Suppression_Date__c < record.Pre_Order_Date__c)
                Error_Messages += count++ + Label.WB_Batch_Error_APO_Date_Validation2+'\n';
            
            if(record.Start_Date__c != null && record.Suppression_Date__c != null && record.Start_Date__c < record.Suppression_Date__c)
                Error_Messages += count++ + Label.WB_Batch_Error_APO_Date_Validation3+'\n';
                
            if(Error_Messages != '')
            {
                flagErrorMessages.put(record.id,true);
                CA_Upload_Record__c rec = new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=Error_Messages);
                if(mapTitleVVCARecord.containsKey(record.Video_Version__c))
                    rec.Title_Name__c = mapTitleVVCARecord.get(record.Video_Version__c).Name;
                mapCARecords.put(record.id,rec);
                
                //listTobeUpdateCARecord.add(new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=Error_Messages));
            }
            countErrorMessages.put(record.id,count);
        }catch(Exception e)
        {
            CA_Upload_Record__c rec = new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=e.getmessage()+'\n'+Error_Messages);
            update rec;
            system.debug('Exception : '+e.getmessage());
        }
        
            
        }
        system.debug('*********outside of for loop');
        
        // Get all existing client avails available for matched Release plans
        Map<Id,List<Client_Avail__c>> mapRPClientAvailList = new Map<Id,List<Client_Avail__c>>();
        List<Client_Avail__C> ListAllOtherClientAvails = new List<Client_Avail__C>();
        for(Client_Avail__C oldClientAvail : [Select id,Name,Commercial_Avail__c,Start_Date__c,End_Date__c,Client__r.Name from Client_Avail__c where Commercial_Avail__c in: mapCARecordRPRecord.values()])
        {
            if(!mapRPClientAvailList.containskey(oldClientAvail.Commercial_Avail__c))
                mapRPClientAvailList.put(oldClientAvail.Commercial_Avail__c,new List<Client_Avail__c>());
            mapRPClientAvailList.get(oldClientAvail.Commercial_Avail__c).add(oldClientAvail);
        }
        // Get Matching Pricing records for Validation.
        //Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>> mapPricingRecords = getPricingRecords(setAccounts,setChannels,setFormats,setCountries,setContentTypes,setPriceCodes);
        
        // Validations performed with Existing Client Avails and Passes to create an Client Avail Record.
        for(CA_Upload_Record__c record : mapCARecordRPRecord.keySet())
        {
            String Error_Messages='';
            Integer Count=countErrorMessages.get(record.id);
            Client_Avail__c newClientAvail = new Client_Avail__c();
            try{
            
            // Validations on comparision of Local Data fields matches
            if(record.Local_Edit_Required__c != null || record.Local_Data_Rating__c != null || record.Local_Data_No_Of_Episodes__c != null)
            {
                Commercial_Avail__c matchingReleaseplan = mapCARecordRPRecord.get(record);
                if(record.Local_Edit_Required__c != null && matchingReleaseplan.Local_Title__r.Local_Edit_Required__c != record.Local_Edit_Required__c) 
                    Error_Messages += count++ + Label.WB_Batch_Error_Local_Data_Req_not_matching_with_Local_Data+'\n';  
                if(record.Local_Data_Rating__c != null && matchingReleaseplan.Local_Title__r.Local_Rating__c != record.Local_Data_Rating__c) 
                    Error_Messages += count++ + Label.WB_Batch_Error_Local_Data_Rating_not_matching_with_Local_Data+'\n';  
                if(record.Local_Data_No_Of_Episodes__c != null && matchingReleaseplan.Local_Title__r.Num_Local_Episodes__c != Decimal.valueof(record.Local_Data_No_Of_Episodes__c)) 
                    Error_Messages += count++ + Label.WB_Batch_Error_Num_od_Episode_not_matching_with_Local_Data+'\n';
            }
            
            // Validation regarding Date Overlapping.
            if(mapRPClientAvailList.get(mapCARecordRPRecord.get(record).id) != null && mapRPClientAvailList.get(mapCARecordRPRecord.get(record).id).size() > 0)
            {
                for(Client_Avail__c existingClientAvail : mapRPClientAvailList.get(mapCARecordRPRecord.get(record).id))
                {
                    if(existingClientAvail.Client__r.Name == record.Account_Name__c)
                    {
                        system.debug('existingClientAvail.name'+existingClientAvail.name);
                        if(record.Start_Date__c == existingClientAvail.Start_Date__c || record.End_Date__c == existingClientAvail.End_Date__c)
                        {
                            Error_Messages += Count++ + Label.WB_Batch_Error_CA_available_for_Dates+'\n';
                            break;
                        }
                        else if(!(record.Start_Date__c >= existingClientAvail.End_Date__c || record.End_Date__c <= existingClientAvail.Start_Date__c))
                        {    
                            Error_Messages += Count++ + Label.WB_Batch_Error_CA_dates_Overlapping+'\n';  
                            break;
                        }
                    }
                }
            }
            
            /* Validation if Price Tier is not null and Status is Confirmed. 
            if(record.Price_Tier__c != null && record.Price_Tier__c != '' && record.Status__c=='Confirmed')
            {
                Boolean pricingAvailable = false;
                Pricing__c MatchingPricing;
                String AccountId = String.valueof(mapAccountMapNameId.get(record.Account_Name__c).id);
                // Create Client Avail Record
                
                if(mapPricingRecords != null 
                && mapPricingRecords.get(record.Account_Name__c) != null 
                && mapPricingRecords.get(record.Account_Name__c).get(record.Country__c) != null 
                && mapPricingRecords.get(record.Account_Name__c).get(record.Country__c).get(record.Format__c) != null 
                && mapPricingRecords.get(record.Account_Name__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c) != null 
                && mapPricingRecords.get(record.Account_Name__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c).get(mapCARecordRPRecord.get(record).Title__r.Content_Type__c) != null)
                {
                    MatchingPricing = mapPricingRecords.get(record.Account_Name__c).get(record.Country__c).get(record.Format__c).get(record.Channel__c).get(mapCARecordRPRecord.get(record).Title__r.Content_Type__c).get(mapCARecordRPRecord.get(record).Local_Title__r.Price_Code__c);
                    system.debug('----MatchingPricing------'+MatchingPricing);            
                    if(MatchingPricing.Price_Tier__c != record.Price_Tier__c)
                        Error_Messages += count++ + '. '+Label.WB_Price_Tier_Value_Not_Matching+'.\n';
                    else
                        pricingAvailable=true;
                }
                else
                    Error_Messages += count++ + Label.WB_Batch_Error_No_Pricing_Entry+'\n';
                if(pricingAvailable)
                    newClientAvail.Price_Tier_Text__c=record.Price_Tier__c;
            }*/
            
            // Check for Date overlapping with new Client Avails.   
            // VV,Language,Format,Country,Channel,Account,Client Avail 
            if(mapNewClientAvails != null &&
               mapNewClientAvails.get(record.Video_Version__c) != null &&
               mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c) != null &&
               mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c) != null &&
               mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c) != null &&
               mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c) != null &&
               mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c).get(record.Account_Name__c) != null)
            {
                   for(Client_Avail__c newCA : mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c).get(record.Account_Name__c))
                   {
                        if(record.Start_Date__c == newCA.Start_Date__c || record.End_Date__c == newCA.End_Date__c)
                        {
                            Error_Messages += Count++ + Label.WB_Batch_Error_CA_available_for_Dates+'\n';
                            break;
                        }
                        else if(!(record.Start_Date__c >= newCA.End_Date__c || record.End_Date__c <= newCA.Start_Date__c))
                        {    
                            Error_Messages += Count++ + Label.WB_Batch_Error_CA_dates_Overlapping+'\n';  
                            break;
                        }
                   }
            }
                   
            system.debug('--------Error_Messages-----------'+Error_Messages);
            // Check if any error comes during validation perfor above.
            if(Error_Messages == '' && !flagErrorMessages.get(record.id))
            {
                newClientAvail.Commercial_Avail__c=mapCARecordRPRecord.get(record).id;
                newClientAvail.Start_Date__c=record.Start_Date__c;
                newClientAvail.End_Date__c=record.End_Date__c;
                newClientAvail.APO_Date__c = record.Pre_Order_Date__c;
                newClientAvail.Announce_Date__c = record.Suppression_Date__c;
                newClientAvail.Status__c = record.Status__c;
                newClientAvail.Client__c = mapAccountMapNameId.get(record.Account_Name__c).id;
                newClientAvail.Local_Data_Category_Picklist__c = record.Category__c;
                newClientAvail.Storefront__c = mapCAUploadRecordIdSFId.get(record.id);
                if(record.WS_Cost__c != null) newClientAvail.Price__c = Decimal.valueOf(record.WS_Cost__c);
                if(record.SR_Price__c != null) newClientAvail.SR_Price__c = Decimal.valueOf(record.SR_Price__c);
                if(record.Notes__c != null) newClientAvail.Comments__c = record.Notes__c;
                if(record.Episode_SR_Price__c != null) newClientAvail.SR_Per_Episode__c = Decimal.valueOf(record.Episode_SR_Price__c);
                if(record.Episode_WS_Cost__c != null) newClientAvail.Episode_Price__c = Decimal.valueOf(record.Episode_WS_Cost__c);
                if(record.Episode_Price_Tier__c != null) newClientAvail.Episode_Price_Tier__c = record.Episode_Price_Tier__c;
                if(record.Change_Context__c != null) newClientAvail.Change_Context__c = record.Change_Context__c;
                
                //Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,List<Client_Avail__c>>>>>>>
                if(!mapNewClientAvails.containskey(record.Video_Version__c))
                    mapNewClientAvails.put(record.Video_Version__c,new Map<String,Map<String,Map<String,Map<String,Map<String,List<Client_Avail__c>>>>>>());
                if(!mapNewClientAvails.get(record.Video_Version__c).containskey(record.Language__c))
                    mapNewClientAvails.get(record.Video_Version__c).put(record.Language__c,new Map<String,Map<String,Map<String,Map<String,List<Client_Avail__c>>>>>());
                if(!mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).containskey(record.Format__c))
                    mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).put(record.Format__c,new Map<String,Map<String,Map<String,List<Client_Avail__c>>>>());
                if(!mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).containskey(record.Country__c))
                    mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).put(record.Country__c,new Map<String,Map<String,List<Client_Avail__c>>>());
                if(!mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).containskey(record.Channel__c))
                    mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).put(record.Channel__c,new Map<String,List<Client_Avail__c>>());
                if(!mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c).containskey(record.Account_Name__c))
                    mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c).put(record.Account_Name__c,new List<Client_Avail__c>()); 
                mapNewClientAvails.get(record.Video_Version__c).get(record.Language__c).get(record.Format__c).get(record.Country__c).get(record.Channel__c).get(record.Account_Name__c).add(newClientAvail);
                
                mapClientAvailTobeInsert.put(record,newClientAvail);
            }
            else
                if(mapCARecords.containskey(record.id))
                    mapCARecords.get(record.id).Errors__c += Error_Messages;
                else
                    mapCARecords.put(record.id,new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=Error_Messages,Title_Name__c = mapTitleVVCARecord.get(record.Video_Version__c).Name)); 
        
            countErrorMessages.put(record.id,count);
            }catch(Exception e)
            {
                CA_Upload_Record__c rec = new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=e.getmessage()+'\n'+Error_Messages);
                update rec;
                system.debug('Exception : '+e.getmessage());
            }
        }
        //mapPricingRecords.clear();
        mapCountryAccountChannelsSF.clear();
        mapCountryAccountFormatsSF.clear();
        mapCountryAccountCTsSF.clear();
        mapCountryAccountSF.clear();
        system.debug('****mapClientAvailTobeInsert : '+mapClientAvailTobeInsert);
        Database.Saveresult[] saveResult_CActivity  = Database.insert(mapClientAvailTobeInsert.values(), false);
        Integer i=0;
        set<Id> setLocalTitle = new set<Id>();
        List<Local_Title__c> listToUpdateLocalTitle = new List<Local_Title__c>();
        
        System.debug('******'+saveResult_CActivity);
        for (Database.SaveResult sr : saveResult_CActivity ) {            
            if (sr.isSuccess()) {
                String Message = '';
                system.debug(new List<CA_Upload_Record__c>(mapClientAvailTobeInsert.keyset())[i].id);
                CA_Upload_Record__c record = new List<CA_Upload_Record__c>(mapClientAvailTobeInsert.keyset())[i++];
                mapCARecords.put(record.id,new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Successful',Errors__c='',Client_Avail_Record_Id__c=sr.getId(),Title_Name__c = mapTitleVVCARecord.get(record.Video_Version__c).Name));
                //listTobeUpdateCARecord.add(new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Successful',Errors__c='',Client_Avail_Record_Id__c=sr.getId()));
                /*if(!setLocalTitle.contains(mapCARecordRPRecord.get(record).Local_Title__c) && (record.Local_Edit_Required__c != null || record.Local_Data_Rating__c != null || record.Local_Data_No_Of_Episodes__c != null))
                {
                    setLocalTitle.add(mapCARecordRPRecord.get(record).Local_Title__c);
                    Local_Title__c localTitle = new Local_Title__c();
                    localTitle.id = mapCARecordRPRecord.get(record).Local_Title__c;
                    if(record.Local_Edit_Required__c != null) localTitle.Local_Edit_Required__c = record.Local_Edit_Required__c;
                    if(record.Local_Data_Rating__c != null) localTitle.Local_Rating__c = record.Local_Data_Rating__c;
                    if(record.Local_Data_No_Of_Episodes__c != null) localTitle.Num_Local_Episodes__c = Decimal.valueof(record.Local_Data_No_Of_Episodes__c);
                    listToUpdateLocalTitle.add(localTitle);
                }*/
            }
            else {
                String error ='';
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {     
                    error += err.getMessage();
                }
                CA_Upload_Record__c record = new List<CA_Upload_Record__c>(mapClientAvailTobeInsert.keyset())[i++];
                mapCARecords.put(record.id,new CA_Upload_Record__c(id=record.id,CA_upload_status__c='Failed',Errors__c=error,Title_Name__c = mapTitleVVCARecord.get(record.Video_Version__c).Name));
                //listTobeUpdateCARecord.add(new CA_Upload_Record__c(id=new List<CA_Upload_Record__c>(mapClientAvailTobeInsert.keyset())[i++].id,CA_upload_status__c='Failed',Errors__c=error));   
            }
        }
        /*if(listToUpdateLocalTitle != null && listToUpdateLocalTitle.size()>0)
            Database.Saveresult[] saveResult_CActivity1  = Database.update(listToUpdateLocalTitle);*/
        update mapCARecords.values();
    }
     
    
    public void finish(Database.BatchableContext BC){
        
        List<CA_Upload__c> listCAUploadRecords = [Select id,Upload_Status__c,No_of_Unprocessed_Records__c  from CA_Upload__c where id in: CAUploadIds
                                                  AND No_of_Unprocessed_Records__c = 0];
        for(CA_Upload__c upload : listCAUploadRecords)
            upload.Upload_Status__c = 'Completed';
        Database.update(listCAUploadRecords,false);
    }
    
    /* Get Pricing records for provided set of combination.
    // Method accepts input parameters like : 
    // 1. Set Of Accounts
    // 2. Set Of Channel
    // 3. Set Of Formats
    // 4. Set Of Country
    // 5. Set Of Content Type
    // 6. Set Of Price_Code__c
    public static Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>> getPricingRecords(set<String> setAccounts,
                                                                                                                   set<String> setChannels,
                                                                                                                   set<String> setFormats,
                                                                                                                   set<String> setCountries,
                                                                                                                   set<String> setContentTypes,
                                                                                                                   set<String> setPriceCode)
    {
        // Account Name,Country,Format,Channel,Content Type,PriceCode.
        Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>> mapPricingRecords = new Map<String,Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>>();
        
        system.debug('---------listPricing-------- '+setAccounts+'-'+setChannels+'-'+setFormats+'-'+setCountries +'-'+setContentTypes +'-'+setPriceCode);
        
        List<Pricing__c> listPricing = [SELECT Account__c,Account__r.Name, Channel__c,Format__c,Content_Type__c,Country__c,Country__r.Name,Name,Price_Tier__c FROM Pricing__c
                                        WHERE Account__r.Name in: setAccounts AND Channel__c in: setChannels AND Format__c in: setFormats
                                        AND Country__r.Name in: setCountries AND Content_Type__c in: setContentTypes AND Name in: setPriceCode];
        system.debug('***listPricing&&&&& : '+listPricing); 
        
        if(listPricing != null && listPricing.size() > 0)
        {
            for(Pricing__c pricingRecord : listPricing)
            {
                system.debug('***pricingRecord : '+pricingRecord);
                
                // Add account
                if(!mapPricingRecords.containskey(pricingRecord.Account__r.Name)){
                    system.debug('------------mapPricingRecords.get(pricingRecord.Account__c)-----1--------: '+pricingRecord.Account__r.Name);
                    mapPricingRecords.put(pricingRecord.Account__r.Name,new Map<String,Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>>());
                }
                system.debug('---------mapPricingRecords----1---- '+mapPricingRecords);
                // Add Country Name    
                if(mapPricingRecords != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name)!= null 
                    && !mapPricingRecords.get(pricingRecord.Account__r.Name).containskey(pricingRecord.Country__r.Name)){
                    system.debug('------------mapPricingRecords.get(pricingRecord.Account__c)---2----------: '+mapPricingRecords.get(pricingRecord.Account__r.Name));
                    mapPricingRecords.get(pricingRecord.Account__r.Name).put(pricingRecord.Country__r.Name,new Map<String,Map<String,Map<String,Map<String,Pricing__c>>>>());
                }
                system.debug('---------mapPricingRecords----2---- '+mapPricingRecords);
                // Add Format
                if(mapPricingRecords != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name) != null 
                    && !mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).containskey(pricingRecord.Format__c)){
                    mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).put(pricingRecord.Format__c,new Map<String,Map<String,Map<String,Pricing__c>>>());
                }    
                system.debug('---------mapPricingRecords----3---- '+mapPricingRecords);
                // Add Channel
                if(mapPricingRecords != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get (pricingRecord.Format__c) != null 
                    && !mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).containskey(pricingRecord.Channel__c)){
                    mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).put(pricingRecord.Channel__c,new Map<String,Map<String,Pricing__c>>());
                }
                system.debug('---------mapPricingRecords---4---- '+mapPricingRecords);
                // Add Content Type
                if(mapPricingRecords != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get (pricingRecord.Format__c) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c) != null 
                    && !mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).containskey(pricingRecord.Content_Type__c)){
                    mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).put(pricingRecord.Content_Type__c,new Map<String,Pricing__c>());
                }
                system.debug('---------mapPricingRecords----5---- '+mapPricingRecords);
                // Add Price code
                if(mapPricingRecords != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get (pricingRecord.Format__c) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c) != null 
                    && mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).get(pricingRecord.Content_Type__c)!= null
                    && !mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).get(pricingRecord.Content_Type__c).containskey(pricingRecord.Name)){
                    system.debug('------------mapPricingRecords----6---------: ');
                    mapPricingRecords.get(pricingRecord.Account__r.Name).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).get(pricingRecord.Content_Type__c).put(pricingRecord.Name,pricingRecord);    
                }
                // Add related Price Tier values for related combination.    
                //mapPricingRecords.get(pricingRecord.Account__c).get(pricingRecord.Country__r.Name).get(pricingRecord.Format__c).get(pricingRecord.Channel__c).get(pricingRecord.Content_Type__c).get(pricingRecord.Name).add(pricingRecord.Price_Tier__c);  
            }
        }
        system.debug('------------mapPricingRecords-------------: '+mapPricingRecords);
        return mapPricingRecords;
    }*/
    
}