/* =============================================================================================
*  Author                               Date                                       Comment
*  Mahesh Hirugade                      27/08/2015                                 Initial Draft
*  Prachi Gadewar                       5/10/2015                                  CH01: Added code to support ER: Language Readiness changes.
*
*/

public class WB_Batch_ReleasePlanWizard implements Database.Batchable<sObject>,Database.Stateful{

    String queryString=''; // Query string used to get scope in Execute method.
    list<String> lstTitleIds;
    list<string> lstCountryIds;
    list<WB_CreateCommercialAvail_Controller.channelWrapper> channelGridList;
    
    list<Available_Languages__c> titleAvailableLangList;
    list<Title__c> titleList;
    public list<Release_Plan_Exceptions__c> releasePlanExceptionList;
    list<Commercial_Avail__c> recordsCreated;
    
    map<Id,set<availablelangType>> titleId_availLangTypeSetMap;
    map<Id,set<string>> countryChannelAvailable;
    map<id, date> firstAvalTitleDateMap;
    map<id, date> expirationDateTitleMap;
    Map<Id,set<string>> titleFormats;
    
    public integer countExcpetionRec = 0;
    User userDetail;
    
    private Integer newRPCount, failedRPCount;
    
    public WB_Batch_ReleasePlanWizard(list<string> pTitleIdList, list<string> pCountryIdList, list<WB_CreateCommercialAvail_Controller.channelWrapper> pChannelGridList){
        newRPCount = 0; failedRPCount = 0;
        userDetail = [SELECT id, ProfileId, Profile.Name, UserType, Territory__c from User where id =: Userinfo.getUserId()];
        
        lstTitleIds = pTitleIdList;
        lstCountryIds = pCountryIdList;
        channelGridList = pChannelGridList;
        
        titleFormats = new map<Id,set<string>>(); 
        firstAvalTitleDateMap= new map<Id,date>(); 
        expirationDateTitleMap = new map<Id,date>();
        releasePlanExceptionList = new list<Release_Plan_Exceptions__c>();
        
        integer noFormatCount=0;
        
        titleList= [
            SELECT id, name,Expiration_Date__c,Abstract_EIDR_formula__c, Title_Type__c,First_Available_Date__c,Production_Year_formula__c, 
                   MPM__c,Video_Version__c,Studio__c,Genre__c,Short_Synopsis__c,Formats__c,(SELECT id FROM Available_Languages__r)
              FROM Title__c 
             WHERE Id IN:pTitleIdList and Digital_Planning__c='Yes'
        ];
        for(Title__c objTitle: titleList){
            
            set<string> formatSet = new set<string>();
            //vvlistString = vvlistString + objTitle.Video_Version__c +',';
            
            if(objTitle.Formats__c != null && objTitle.Formats__c != ''){
                for(String format : objTitle.Formats__c.split(';')){
                    formatSet.add(format);
                }
                titleFormats.put(objTitle.Id, formatSet);
            }
            else{
                noFormatCount++;
                Release_Plan_Exceptions__c rpExceptionRec= new Release_Plan_Exceptions__c();
                countExcpetionRec++;
                rpExceptionRec.name= Userinfo.getUserId() + string.valueof(countExcpetionRec) ;
                rpExceptionRec.Title__c=objTitle.name;
                rpExceptionRec.Reason__c='Title is not available in any formats.';
                rpExceptionRec.User_Detail__c=Userinfo.getUserId(); 
                releasePlanExceptionList.add(rpExceptionRec);
            }
            
            if(objTitle.First_Available_Date__c != null)
                firstAvalTitleDateMap.put(objTitle.Id,objTitle.First_Available_Date__c);
            if(objTitle.Expiration_Date__c != null)
                expirationDateTitleMap.put(objTitle.Id,objTitle.Expiration_Date__c);
        }
        
        if(releasePlanExceptionList != null && releasePlanExceptionList.size() > 0 ){
            Database.Saveresult[] saveExceptionResult  = Database.insert(releasePlanExceptionList, false);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        queryString = 'SELECT Id, Channel__c, Name from Country__c where Id IN: lstCountryIds';
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext BC, List<Country__c> scope){
        
        map<Id, Country__c> countryMap = new map<Id, Country__c>(scope);
        
        map<Id,list<langPriority>> countryLanguagePrefered;
        list<Language_Preference__c> countryPreferedLanguage;
        list<string> noAvailLangtitlesLst= new list<string>();
        
        releasePlanExceptionList = new list<Release_Plan_Exceptions__c>();
        
        /** Started--Map for title, and available language **/
        titleAvailableLangList = new list<Available_Languages__c>([select id,Language_Types__c,Language__c,Title__c,Clear_to_Avail__c from Available_Languages__c where Title__c IN:lstTitleIds]);
        titleId_availLangTypeSetMap = new map<Id,set<availableLangType>>();
        
        for(Available_Languages__c availableLang : titleAvailableLangList){
            availableLangType avLangType = new availableLangType();
            //avLangType.langType = availableLang.language_types__c;
            // CH01 - if Clear to avail check then only add the language type in list. which will needs to create release plan.
            if(availableLang.Clear_to_Avail__c)
                avLangType.langType = availableLang.language_types__c;
            else
                avLangType.langType = null;          
            avLangType.availableLanguage= availableLang.Language__c;
            if(titleId_availLangTypeSetMap != null && titleId_availLangTypeSetMap.containsKey(availableLang.Title__c)){
                titleId_availLangTypeSetMap.get(availableLang.Title__c).add(avLangType);
            }else{
                titleId_availLangTypeSetMap.put(availableLang.Title__c, new set<availableLangType>{avLangType});
            }
        }
        /** Ended--Map for title, and available language **/
        
        /** Started--Map for country, and channel**/
        list<Country__c> selectedCountryList = new list<Country__c>([select id,Channel__c,name from Country__c where ID IN:countryMap.keySet()]);
        countryChannelAvailable = new map<Id,set<string>>();
        
        set<string> channelCountryListUnique = new set<string>();
        for(Country__c availableCountry : scope){
            string channelStr = availableCountry.Channel__c;
            
            if(channelStr!=null && channelStr != ''){
                string[] channelSplit = channelStr.split(';');
                for(integer i=0;i<channelSplit.size();i++){
                    channelCountryListUnique.add(channelSplit[i]);
                }
                countryChannelAvailable.put(availableCountry.Id,channelCountryListUnique);
            }
            else{
                for(Title__c titleRec : titleList){
                    Release_Plan_Exceptions__c rpExceptionRec = new Release_Plan_Exceptions__c();
                    countExcpetionRec++;
                    rpExceptionRec.name = userInfo.getUserId() + string.valueof(countExcpetionRec);
                    rpExceptionRec.Title__c = titleRec.name;
                    rpExceptionRec.Country__c = availableCountry.name;
                    rpExceptionRec.Reason__c = 'Country has not been associated with any channel';
                    rpExceptionRec.User_Detail__c = userInfo.getUserId();
                    releasePlanExceptionList.add(rpExceptionRec);
                }
            }
        }
        /** Ended--Map for country, and channel**/
        
        /** Started--Map for country, and language preference **/
        countryPreferedLanguage = new list<Language_Preference__c>([
            select id,Language__c,Level__c,Country__c
              from Language_Preference__c
             where Country__c IN:countryMap.keySet() order by Level__c
        ]);
        countryLanguagePrefered = new map<Id,list<langPriority>>();
        
        for(Language_Preference__c preferedLanguage : countryPreferedLanguage){
            langPriority langLevel=new langPriority();
            langLevel.priority= preferedLanguage.Level__c;
            langLevel.preferedLang= preferedLanguage.Language__c;
            if(countryLanguagePrefered != null && countryLanguagePrefered.containsKey(preferedLanguage.Country__c)){
                countryLanguagePrefered.get(preferedLanguage.Country__c).add(langLevel);
            }else{
                countryLanguagePrefered.put(preferedLanguage.Country__c, new list<langPriority>{langLevel});
            }
        }
        /** Ended--Map for country, and language preference **/
        
        //Start : Part of clientList method - Need to move this block of code in another method
        system.debug('lstTitleIds ====> ' + lstTitleIds);
        
        recordsCreated= new list<Commercial_Avail__c>();
        
        for(string titleId : lstTitleIds){
            
            //Create release plans here as like Client List method
            //recordsCreated= new list<Commercial_Avail__c>();
            set<availableLangType> titleAvailLangLst = new set<availableLangType>();
            set<string> titleFormatSet= new set<string>();
            titleAvailLangLst = titleId_availLangTypeSetMap.get(titleId);
            
            set<string>titleAvailLang =new set<string>();
            if(titleAvailLangLst!=null){
                for(availableLangType titleLangList:titleAvailLangLst){
                    titleAvailLang.add(titleLangList.availableLanguage);
                }
            }
            else{
                noAvailLangtitlesLst.add(titleId);
            }
            if(titleFormats.get(titleId)!=null){
                titleFormatSet=titleFormats.get(titleId);
            }
            integer countOfPreferedLang=0;
            integer countOfPriorityLang2=0;
            integer countOfPriorityLang3=0;
            
            system.debug('titleId ====> ' + titleId);
            
            for(string countryId : countryMap.keySet()){
                
                set<string> countryChannelSet= new set<string>();
                list<langPriority> countryPreferedLangLst = new list<langPriority>();
                countryPreferedLangLst = countryLanguagePrefered.get(countryId);
                
                countOfPreferedLang = 0;
                countOfPriorityLang2 = 0;
                countOfPriorityLang3 = 0;
                
                if(countryChannelAvailable.get(countryId)!=null){
                    countryChannelSet = countryChannelAvailable.get(countryId);
                }
                if(!countryChannelSet.isEmpty() ){
                    if(countryPreferedLangLst!=null){
                        for(langPriority objLangPriority:countryPreferedLangLst){
                            //pasting code here : Start
                            system.debug(objLangPriority.preferedLang + ' Contains in set ? - ' + titleAvailLang.contains(objLangPriority.preferedLang));
                            if(titleAvailLang.contains(objLangPriority.preferedLang)){
                                    if(objLangPriority.priority=='1'){
                                        set<string> langTypes= new set<string>();
                                        
                                        for(availableLangType titleLangList:titleAvailLangLst){
                                            if(titleLangList.availableLanguage==objLangPriority.preferedLang&& titleLangList.langType != null){ //CH01: && condition added
                                                langTypes.add(titleLangList.langType);
                                            }
                                        }
                                        for(string countryChannel:countryChannelSet){
                                            for(string selectedformat:titleFormatSet){
                                                for(WB_CreateCommercialAvail_Controller.channelWrapper objChannelGrid :channelGridList) {
                                                    if(countryChannel==objChannelGrid.countryChannel) {
                                                        
                                                        Commercial_Avail__c record=new Commercial_Avail__c();
                                                        record.Country_Lookup__c= countryId;
                                                        record.Format__c=selectedformat;
                                                        record.Title__c= titleId;
                                                        //record.language_type__c= availLangTypes;
                                                        if(langTypes.size()==0)
                                                            record.language_type__c=null;
                                                        else if(langTypes.size()==1) {
                                                            if(langTypes.contains('Audio'))
                                                                record.language_type__c='Audio';
                                                            else if(langTypes.contains('Sub'))
                                                                record.language_type__c='Sub';
                                                        }
                                                        else if(langTypes.contains('Audio')&&langTypes.contains('Sub'))
                                                            record.language_type__c='Sub & Audio';
                                                        record.Languages__c= objLangPriority.preferedLang;
                                                        record.channel__c=countryChannel;
                                                        if(objChannelGrid.additionalInfo.Status__c=='Draft'|| objChannelGrid.additionalInfo.Status__c=='Open'){
                                                            if(objChannelGrid.additionalInfo.Start_Date__c==null && objChannelGrid.additionalInfo.End_Date__c==null && objChannelGrid.additionalInfo.Exclusive_Date__c ==null && objChannelGrid.additionalInfo.Rights_End__c ==null){
                                                                if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                    record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                    record.Start_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                }else {
                                                                    record.Exclusive_Date__c=System.Today();
                                                                    record.Start_Date__c=System.Today();
                                                                }
                                                                if(expirationDateTitleMap.get(titleId)!=null){
                                                                    record.Rights_End__c= expirationDateTitleMap.get(titleId);
                                                                }else
                                                                    record.Rights_End__c= date.newInstance(2049, 12, 31);
                                                                record.End_Date__c=record.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            } else if(objChannelGrid.additionalInfo.Exclusive_Date__c ==null && objChannelGrid.additionalInfo.Rights_End__c ==null && objChannelGrid.additionalInfo.Start_Date__c!=null && objChannelGrid.additionalInfo.End_Date__c!=null){
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Start_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.End_Date__c;
                                                                if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                    record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                }else record.Exclusive_Date__c=System.Today();
                                                                date myDate = date.newInstance(2049, 12, 31);
                                                                String dayString = myDate.format();
                                                                
                                                                record.Rights_End__c = (expirationDateTitleMap.get(titleId)!=null) 
                                                                                       ? expirationDateTitleMap.get(titleId)
                                                                                       : date.parse(dayString);
                                                                
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            } 
                                                            else if(objChannelGrid.additionalInfo.Exclusive_Date__c !=null && objChannelGrid.additionalInfo.Rights_End__c !=null && objChannelGrid.additionalInfo.Start_Date__c==null && objChannelGrid.additionalInfo.End_Date__c==null){
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.Exclusive_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.Rights_End__c= objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            }else {
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Start_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.End_Date__c;
                                                                record.Exclusive_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.Rights_End__c= objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            }
                                                        }else if(objChannelGrid.additionalInfo.Status__c!=null && objChannelGrid.additionalInfo.Status__c!='Not Releasing' ){
                                                            if(objChannelGrid.additionalInfo.Start_Date__c==null && objChannelGrid.additionalInfo.End_Date__c==null && objChannelGrid.additionalInfo.Exclusive_Date__c ==null && objChannelGrid.additionalInfo.Rights_End__c ==null){
                                                                if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                    record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                    record.Start_Date__c =firstAvalTitleDateMap.get(titleId);
                                                                }else {
                                                                    record.Exclusive_Date__c=System.Today();
                                                                    record.Start_Date__c =System.Today();
                                                                }
                                                                if(expirationDateTitleMap.get(titleId)!=null){
                                                                    record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                }else
                                                                    record.Rights_End__c=date.parse('12/31/2049'); 
                                                                record.End_Date__c= record.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            } else if(objChannelGrid.additionalInfo.Exclusive_Date__c ==null && objChannelGrid.additionalInfo.Rights_End__c ==null && objChannelGrid.additionalInfo.Start_Date__c!=null && objChannelGrid.additionalInfo.End_Date__c!=null){
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Start_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.End_Date__c;
                                                                if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                    record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                }else
                                                                    record.Exclusive_Date__c=System.Today();
                                                                if(expirationDateTitleMap.get(titleId)!=null){
                                                                  record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                }else
                                                                    record.Rights_End__c= date.parse('12/31/2049');
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            } 
                                                            else if(objChannelGrid.additionalInfo.Exclusive_Date__c !=null && objChannelGrid.additionalInfo.Rights_End__c !=null && objChannelGrid.additionalInfo.Start_Date__c==null && objChannelGrid.additionalInfo.End_Date__c==null){
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.Exclusive_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.Rights_End__c= objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            }
                                                            else {
                                                                record.Start_Date__c=objChannelGrid.additionalInfo.Start_Date__c;
                                                                record.End_Date__c=objChannelGrid.additionalInfo.End_Date__c;
                                                                record.Exclusive_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                                record.Rights_End__c= objChannelGrid.additionalInfo.Rights_End__c;
                                                                record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                            }
                                                        }else if(objChannelGrid.additionalInfo.Status__c=='Not Releasing'){
                                                            record.Start_Date__c=objChannelGrid.additionalInfo.Start_Date__c;
                                                            record.End_Date__c=objChannelGrid.additionalInfo.End_Date__c;
                                                            record.Exclusive_Date__c=objChannelGrid.additionalInfo.Exclusive_Date__c;
                                                            record.Rights_End__c= objChannelGrid.additionalInfo.Rights_End__c;
                                                            record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                        }
                                                        record.reason_code__c=objChannelGrid.additionalInfo.reason_code__c;
                                                        record.Comments__c=objChannelGrid.additionalInfo.Comments__c;
                                                        record.status__c=objChannelGrid.additionalInfo.Status__c;
                                                        recordsCreated.add(record);
                                                        countOfPreferedLang=countOfPreferedLang+1;
                                                        
                                                        system.debug('1. record ====> ' + recordsCreated.size() + ' : ' + record);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    system.debug('recordsCreated size ====> ' + recordsCreated.size());
                                    if(objLangPriority.priority=='2'){
                                        if(countOfPreferedLang==0){
                                            set<string> langTypes= new set<string>();
                                            for(availableLangType titleLangList:titleAvailLangLst){
                                                if(titleLangList.availableLanguage==objLangPriority.preferedLang&& titleLangList.langType != null){ //CH01: && condition added
                                                    langTypes.add(titleLangList.langType);
                                                }
                                            }
                                            
                                            for(string countryChannelRec:countryChannelSet){
                                                for(string selectedformat:titleFormatSet){
                                                    for(WB_CreateCommercialAvail_Controller.channelWrapper channelLst:channelGridList){
                                                        if(countryChannelRec==channelLst.countryChannel){ 
                                                            if(!(channelLst.additionalInfo.Status__c=='Not Releasing' || channelLst.additionalInfo.Status__c=='Moratorium')){
                                                                Commercial_Avail__c record=new Commercial_Avail__c();
                                                                record.Country_Lookup__c= countryId;
                                                                record.Format__c=selectedformat;
                                                                record.Title__c= titleId;
                                                                //record.language_type__c= availLangTypes;
                                                                // CH01- Start - Check types available in set of LangTypes for the selected title.
                                                                if(langTypes.size()==0)
                                                                    record.language_type__c=null;
                                                                else if(langTypes.size()==1) {
                                                                    if(langTypes.contains('Audio'))
                                                                        record.language_type__c='Audio';
                                                                else if(langTypes.contains('Sub'))
                                                                        record.language_type__c='Sub';
                                                                }
                                                                else if(langTypes.contains('Audio')&&langTypes.contains('Sub'))
                                                                    record.language_type__c='Sub & Audio';
                                                                // CH01- End
                                                                record.Languages__c= objLangPriority.preferedLang;
                                                                record.channel__c=countryChannelRec;
                                                                if(channelLst.additionalInfo.Status__c=='Draft'|| channelLst.additionalInfo.Status__c=='Open'){
                                                                    if(channelLst.additionalInfo.Start_Date__c==null && channelLst.additionalInfo.End_Date__c==null && channelLst.additionalInfo.Exclusive_Date__c ==null && channelLst.additionalInfo.Rights_End__c ==null){
                                                                        
                                                                        if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                            record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                            //ER-000053 - Added by shalini
                                                                            record.Start_Date__c =firstAvalTitleDateMap.get(titleId);
                                                                        }else {
                                                                            record.Exclusive_Date__c=System.Today();
                                                                            record.Start_Date__c =System.Today();
                                                                        }
                                                                        
                                                                        date myDate = date.newInstance(2049, 12, 31);
                                                                        String dayString = myDate.format();
                                                                        //ER-000089 - shalini
                                                                        if(expirationDateTitleMap.get(titleId)!=null){
                                                                          record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                        }else
                                                                        record.Rights_End__c= date.parse(dayString);
                                                                        //ER-000053 - Added by shalini
                                                                        record.End_Date__c= record.Rights_End__c;
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    } else if(channelLst.additionalInfo.Exclusive_Date__c ==null && channelLst.additionalInfo.Rights_End__c ==null && channelLst.additionalInfo.Start_Date__c!=null && channelLst.additionalInfo.End_Date__c!=null){
                                                                        record.Start_Date__c=channelLst.additionalInfo.Start_Date__c;
                                                                        record.End_Date__c=channelLst.additionalInfo.End_Date__c;
                                                                        
                                                                        if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                            record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                        }else
                                                                            record.Exclusive_Date__c=System.Today();
                                                                        
                                                                        date myDate = date.newInstance(2049, 12, 31);
                                                                        String dayString = myDate.format();
                                                                        //ER-000089 - shalini
                                                                        if(expirationDateTitleMap.get(titleId)!=null){
                                                                          record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                        }else
                                                                        record.Rights_End__c= date.parse (dayString);
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    } else {
                                                                        record.Start_Date__c=channelLst.additionalInfo.Start_Date__c;
                                                                        record.End_Date__c=channelLst.additionalInfo.End_Date__c;
                                                                        record.Exclusive_Date__c=channelLst.additionalInfo.Exclusive_Date__c;
                                                                        record.Rights_End__c= channelLst.additionalInfo.Rights_End__c;
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    }
                                                                }else if(channelLst.additionalInfo.Status__c!=null && channelLst.additionalInfo.Status__c!='Not Releasing' ){
                                                                    if(channelLst.additionalInfo.Start_Date__c==null && channelLst.additionalInfo.End_Date__c==null && channelLst.additionalInfo.Exclusive_Date__c ==null && channelLst.additionalInfo.Rights_End__c ==null){
                                                                        if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                            record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                            //ER-000053 added by shalini
                                                                            record.Start_Date__c= firstAvalTitleDateMap.get(titleId);
                                                                        }else {
                                                                            record.Exclusive_Date__c=System.Today();
                                                                            //ER-000053 added by shalini
                                                                            record.Start_Date__c= System.Today();
                                                                        }
                                                                        //ER-000089 - shalini
                                                                        if(expirationDateTitleMap.get(titleId)!=null){
                                                                            record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                        }else
                                                                        record.Rights_End__c=date.parse('12/31/2049');
                                                                        //ER-000053 added by shalini
                                                                        record.End_Date__c =record.Rights_End__c;
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    } else if(channelLst.additionalInfo.Exclusive_Date__c ==null && channelLst.additionalInfo.Rights_End__c ==null && channelLst.additionalInfo.Start_Date__c!=null && channelLst.additionalInfo.End_Date__c!=null){
                                                                        record.Start_Date__c=channelLst.additionalInfo.Start_Date__c;
                                                                        record.End_Date__c=channelLst.additionalInfo.End_Date__c;
                                                                        if(firstAvalTitleDateMap.get(titleId) !=null){
                                                                            record.Exclusive_Date__c=firstAvalTitleDateMap.get(titleId);
                                                                        }else record.Exclusive_Date__c=System.Today();
                                                                        //ER-000089 - shalini
                                                                        if(expirationDateTitleMap.get(titleId)!=null){
                                                                          record.Rights_End__c=expirationDateTitleMap.get(titleId);
                                                                        }else
                                                                        record.Rights_End__c= date.parse('12/31/2049');
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    } else {
                                                                        record.Start_Date__c=channelLst.additionalInfo.Start_Date__c;
                                                                        record.End_Date__c=channelLst.additionalInfo.End_Date__c;
                                                                        record.Exclusive_Date__c=channelLst.additionalInfo.Exclusive_Date__c;
                                                                        record.Rights_End__c= channelLst.additionalInfo.Rights_End__c;
                                                                        record.status__c=channelLst.additionalInfo.Status__c;
                                                                    }
                                                                }
                                                                record.reason_code__c=channelLst.additionalInfo.reason_code__c;
                                                                record.Comments__c=channelLst.additionalInfo.Comments__c;
                                                                record.status__c=channelLst.additionalInfo.Status__c;
                                                                recordsCreated.add(record);
                                                                countOfPriorityLang2=countOfPriorityLang2+1;
                                                                system.debug('record ====> ' + record);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    if(objLangPriority.priority=='1'){
                                        set<string> langDiff= new set<string>();
                                        for(string countryChannelRec:countryChannelSet){
                                            for(string selectedformat:titleFormatSet){
                                                for(WB_CreateCommercialAvail_Controller.channelWrapper channelLst :channelGridList) {
                                                    if(countryChannelRec==channelLst.countryChannel){
                                                        if(!(channelLst.additionalInfo.Status__c=='Not Releasing' || channelLst.additionalInfo.Status__c=='Moratorium')){
                                                            
                                                        } else {
                                                            Commercial_Avail__c record=new Commercial_Avail__c();
                                                            record.Country_Lookup__c= countryId;
                                                            record.Start_Date__c=channelLst.additionalInfo.Start_Date__c;
                                                            record.End_Date__c=channelLst.additionalInfo.End_Date__c;
                                                            record.Exclusive_Date__c=channelLst.additionalInfo.Exclusive_Date__c;
                                                            record.Rights_End__c=channelLst.additionalInfo.Rights_End__c;
                                                            record.Format__c=selectedformat;
                                                            record.Title__c= titleId;
                                                            record.Languages__c= objLangPriority.preferedLang;
                                                            record.channel__c=countryChannelRec;
                                                            record.status__c=channelLst.additionalInfo.Status__c;
                                                            record.reason_code__c=channelLst.additionalInfo.reason_code__c;
                                                            record.Comments__c=channelLst.additionalInfo.Comments__c;
                                                            recordsCreated.add(record);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            //pasting code here : End
                        }
                    }
                }
            }
        }
        //End   : Part of clientList method
        list<Commercial_Avail__c> finalInsertList = commAvailLstValidated(recordsCreated);
        
        list<Commercial_Avail__c>  commercialAvailListInsert= new  list<Commercial_Avail__c>();
        commercialAvailListInsert = batchIdGeneration(finalInsertList);
        
        system.debug('releasePlanExceptionList.size() ===: ' + releasePlanExceptionList.size());
        if(commercialAvailListInsert !=null && commercialAvailListInsert.size()>0){// && releasePlanExceptionList.size()==0)
            try{
                Database.Saveresult[] saveResult  = Database.insert(commercialAvailListInsert, false);
                system.debug('1. saveResult ===> ' + saveResult.size());
                Integer successCount = 0, failureCount = 0;
                for(Database.Saveresult SR : saveResult){
                    if(SR.isSuccess())
                        successCount++;
                    else
                        failureCount++;
                }
                
                newRPCount = newRPCount + successCount;
                failedRPCount = failedRPCount + failureCount;
                system.debug('\n1. successCount : ' + successCount + '\n1. failureCount : ' + failureCount);
                
                pageReference PageRef = new Pagereference(System.label.Re_direct_Commercal_Avail_Wizard);
                PageRef.setredirect(false);
                //return PageRef;
            }catch(Exception e){
              System.debug('Exception while Inserting Release Plan ---'+e.getMessage());
            }
        } else if(commercialAvailListInsert !=null && commercialAvailListInsert.size()>0 && releasePlanExceptionList.size()!=0 ){
            try{
                Database.Saveresult[] saveResult  = Database.insert(commercialAvailListInsert, false);
                Database.Saveresult[] saveExceptionResult  = Database.insert(releasePlanExceptionList, false);
                
                Integer successCount = 0, failureCount = 0;
                for(Database.Saveresult SR : saveResult){
                    if(SR.isSuccess())
                        successCount++;
                    else
                        failureCount++;
                }
                newRPCount = newRPCount + successCount;
                failedRPCount = failedRPCount + failureCount;
                system.debug('\n2. successCount : ' + successCount + '\n2. failureCount : ' + failureCount);
                
                pageReference PageRef = new Pagereference('/apex/WB_RP_Redirect');
                PageRef.setredirect(false);
                //return PageRef;
            }catch(Exception e){
                system.debug('Exception caught----'+e.getMessage());
            }
        }else if(releasePlanExceptionList.size()!=0){// && channelGridValidationFlag == true)
            try{
                Database.Saveresult[] saveExceptionResult  = Database.insert(releasePlanExceptionList, false);
            }catch(Exception e){
                system.debug('Exception caught----'+e.getMessage());
            }
            pageReference PageRef = new Pagereference('/apex/WB_RP_Redirect');
            PageRef.setredirect(false);
            //return PageRef;
        }
    }//End : FINISH()
    
    public void finish(Database.BatchableContext BC){
        /*
        AsyncApexJob a = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
              FROM AsyncApexJob WHERE Id = :BC.getJobId()
        ];
        String plainText = '';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email, 'milon.dey@cognizant.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Release Plans batch status: ' + a.Status);
        plainText = 'We have processed total ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n';
        plainText = plainText + '\nTotal Release plans created are : ' + newRPCount;
        plainText = plainText + '\nTotal Release plans failed are : ' + failedRPCount;
        plainText = '\n\nPlease click on the link to view the records : ' + System.label.Re_direct_Commercal_Avail_Wizard;
        mail.setPlainTextBody(plainText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        */
        //--------------------------------------------------------------------------------------------------------------------------
        
        integer clientExceptionCount = [SELECT count() FROM Client_Avail_Exception__c];
        
        string header = 'Title, Avails Start, Avails End, Channel, Country, Language, Language Type, Format, Reason, Release Plan Id, Release Start, Release End, Status, Exception with ExistingRecord, Old RP Records, User Detail  \n';
        string finalstr = header ;
        for(Release_Plan_Exceptions__c rpExceptionOut_lst: releasePlanExceptionList)
        {
            string recordString = '"'+rpExceptionOut_lst.Title__c+'","'
                                     +rpExceptionOut_lst.Avails_Start__c+'","'
                                     +rpExceptionOut_lst.Avails_End__c+'","'
                                     +rpExceptionOut_lst.Channel__c+'","'
                                     +rpExceptionOut_lst.Country__c+'","'
                                     +rpExceptionOut_lst.Language__c+'","'
                                     +rpExceptionOut_lst.Language_Type__c+'","'
                                     +rpExceptionOut_lst.Format__c+'","'
                                     +rpExceptionOut_lst.Reason__c+'","'
                                     +rpExceptionOut_lst.Release_Plan_Id__c+'","'
                                     +rpExceptionOut_lst.Release_Start_Date__c+'","'
                                     +rpExceptionOut_lst.Release_End_Date__c+'","'
                                     +rpExceptionOut_lst.Status__c+'","'
                                     +rpExceptionOut_lst.Exception_with_ExistingRecord__c+'","'
                                     +rpExceptionOut_lst.Old_RP_Records__c+'","'
                                     +rpExceptionOut_lst.User_Detail__c+'","'
                                     +'"\n';
            finalstr = finalstr +recordString;
        }
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= 'RP.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems, CreatedBy.Email, ExtendedStatus
        from AsyncApexJob where Id = :BC.getJobId()];
        // Email the Batch Job's submitter that the Job is finished.
        String[] toAddresses = new String[] {a.CreatedBy.Email, 'milon.dey@cognizant.com'};
        
        String subject ='Release Plan Exception out CSV';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        
        if(failedRPCount == 0){
            email.setPlainTextBody('If you’ve not run the Wizard since you initiated this run, you should be able to see records created by clicking on the link \n'+ System.Label.Re_direct_Commercal_Avail_Wizard + '\n If, however, you’ve created more records since you ran the wizard which initiated this batch process,those records won’t be available.');// You can see this batch’s records by filtering on batch id < ' + myWizardLastRunId + ' > in a Client Avail view');
        }
        else if(failedRPCount == (newRPCount + failedRPCount)){
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            email.setPlainTextBody('Those records which could not be created (exceptions) are included in an attachment to this message for the user to review.');
        }
        else{
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            email.setPlainTextBody('Those records which could not be created (exceptions) are included in an attachment to this message for the user to review. Few records are created successfully, you can see records by clicking on the link \n'+ System.Label.Re_direct_Commercal_Avail_Wizard + '\n If, however, you’ve created more records since you ran the wizard which initiated this batch process,those records won’t be available.');// You can see this batch’s records by filtering on batch id < ' + myWizardLastRunId + ' > in a Client Avail view');
        }
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
    
    public class availableLangType{
        string langType{get;set;}
        string availableLanguage{get;set;}
    }
    
    public class langPriority{
        string priority{get;set;}
        string preferedLang{get;set;}
    }
    public class channelWrapper{
        public string countryChannel{get;set;}
        public Commercial_Avail__c additionalInfo{get;set;}
        public Integer delIndent {get;set;}
        public Integer addIndent {get;set;}
        public boolean renderExclusiveDate{get;set;}
    }
    
    public list<Commercial_Avail__c> commAvailLstValidated (list<Commercial_Avail__c> commercialAvailList){
        
        list<Commercial_Avail__c> finalReleasePlanList= new list<Commercial_Avail__c>();
        list<Commercial_Avail__c> lst_selectedcommercial_aval = new list<Commercial_Avail__c>();
        list <string> lst_selectedtitle = new list<string>();
        //set<string> lst_selectedtitle1 = new set<string>();
        list<string> lst_selectedcountry = new list<string>();
        list<string> lst_selectedchannel = new list<string>();
        list<string> lst_selectedformat = new list<string>();
        list<string> lst_selectedlanguage = new list<string>();
        boolean validationFlag= true;
        
        for(integer i=0;i<commercialAvailList.size();i++){
            lst_selectedtitle.add(commercialAvailList[i].Title__c);
            lst_selectedcountry.add(commercialAvailList[i].Country_Lookup__c);
            lst_selectedchannel.add(commercialAvailList[i].Channel__c);
            lst_selectedformat.add(commercialAvailList[i].Format__c);
            lst_selectedlanguage.add(commercialAvailList[i].Languages__c);
        }
        
        lst_selectedcommercial_aval = [
            SELECT id, name,Title__c,Title__r.name,Country_Lookup__c,Country_Lookup__r.name,Channel__c,Format__c,Languages__c,
                   Languages__r.name,Language_Type__c,End_Date__c,Start_Date__c
              FROM Commercial_Avail__c 
             WHERE Title__c IN :lst_selectedtitle AND Country_Lookup__c IN :lst_selectedcountry AND Channel__c IN :lst_selectedchannel 
               AND Format__c IN :lst_selectedformat
               AND Languages__c IN :lst_selectedlanguage
        ];
        system.debug('lst_selectedcommercial_aval ====: ' + lst_selectedcommercial_aval);
        for(integer i=0;i<commercialAvailList.size();i++){
            integer countOverLap= 0;
            
            for(integer j=0; j < lst_selectedcommercial_aval.size(); j++){
                //started
                Release_Plan_Exceptions__c rpExceptionRec= new Release_Plan_Exceptions__c();
                
                if(commercialAvailList[i].Start_Date__c > commercialAvailList[i].End_Date__c ){
                    // Criteria 1
                    //Apexpages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Start date cannot be greater than End date'));
                    validationFlag=false;
                    countExcpetionRec++;
                    rpExceptionRec.name=userDetail.Id+ string.valueof(countExcpetionRec);
                    rpExceptionRec.Title__c=lst_selectedcommercial_aval[j].Title__r.name;
                    rpExceptionRec.Country__c=lst_selectedcommercial_aval[j].Country_Lookup__r.name;
                    rpExceptionRec.Language__c=lst_selectedcommercial_aval[j].Languages__r.name;
                    rpExceptionRec.Channel__c=commercialAvailList[i].Channel__c;
                    rpExceptionRec.Format__c=commercialAvailList[i].Format__c;
                    rpExceptionRec.Avails_Start__c=commercialAvailList[i].Exclusive_Date__c;
                    rpExceptionRec.Avails_End__c=commercialAvailList[i].Rights_End__c;
                    rpExceptionRec.Release_Start_Date__c=commercialAvailList[i].Start_Date__c;
                    rpExceptionRec.Release_End_Date__c=commercialAvailList[i].End_Date__c;
                    rpExceptionRec.Status__c=commercialAvailList[i].Status__c;
                    rpExceptionRec.Reason__c='Start date is greater than End date';
                    rpExceptionRec.User_Detail__c=userDetail.Id;
                    releasePlanExceptionList.add(rpExceptionRec);
                    countOverLap++;
                    //commercialAvailList.remove(i);
                }//ended
                // added by rashmi on 9th sept
                else if(commercialAvailList[i].channel__c==lst_selectedcommercial_aval[j].channel__c &&  commercialAvailList[i].format__c==lst_selectedcommercial_aval[j].format__c && commercialAvailList[i].country_lookup__c==lst_selectedcommercial_aval[j].country_lookup__c &&  commercialAvailList[i].title__c ==lst_selectedcommercial_aval[j].title__c && commercialAvailList[i].Languages__c==lst_selectedcommercial_aval[j].Languages__c ){
                    
                    if(lst_selectedcommercial_aval[j].Start_Date__c==null && lst_selectedcommercial_aval[j].End_Date__c==null && commercialAvailList[i].Start_Date__c==null && commercialAvailList[i].End_Date__c==null){
                        
                        validationFlag=false;
                        countExcpetionRec++;
                        rpExceptionRec.name=userDetail.Id+ string.valueof(countExcpetionRec);
                        rpExceptionRec.Title__c=lst_selectedcommercial_aval[j].Title__r.name;
                        rpExceptionRec.Country__c=lst_selectedcommercial_aval[j].Country_Lookup__r.name;
                        rpExceptionRec.Language__c=lst_selectedcommercial_aval[j].Languages__r.name;
                        rpExceptionRec.Channel__c=commercialAvailList[i].Channel__c;
                        rpExceptionRec.Format__c=commercialAvailList[i].Format__c;
                        rpExceptionRec.Avails_Start__c=commercialAvailList[i].Exclusive_Date__c;
                        rpExceptionRec.Avails_End__c=commercialAvailList[i].Rights_End__c;
                        rpExceptionRec.Release_Start_Date__c=commercialAvailList[i].Start_Date__c;
                        rpExceptionRec.Release_End_Date__c=commercialAvailList[i].End_Date__c;
                        rpExceptionRec.Status__c=commercialAvailList[i].Status__c;
                        rpExceptionRec.Reason__c='Following overlapping periods  have been found with-'+lst_selectedcommercial_aval[j].name;
                        rpExceptionRec.User_Detail__c=userDetail.Id;
                        releasePlanExceptionList.add(rpExceptionRec);
                        countOverLap++;
                        //commercialAvailList.remove(i);
                    }
                    else if(
                          ((commercialAvailList[i].Start_Date__c >= lst_selectedcommercial_aval[j].Start_Date__c && commercialAvailList[i].Start_Date__c <= lst_selectedcommercial_aval[j].End_Date__c)) 
                        ||((commercialAvailList[i].End_Date__c >=lst_selectedcommercial_aval[j].Start_Date__c && commercialAvailList[i].End_Date__c <= lst_selectedcommercial_aval[j].End_Date__c ))
                        ||(commercialAvailList[i].Start_Date__c < lst_selectedcommercial_aval[j].Start_Date__c && commercialAvailList[i].End_Date__c > lst_selectedcommercial_aval[j].End_Date__c)
                    ){
                        validationFlag=false;
                        //Apexpages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,System.Label.Release_Plan_Date_Overlap+' '+'to'+' '+lst_selectedcommercial_aval[j].name));
                        countExcpetionRec++;
                        rpExceptionRec.name=userDetail.Id+ string.valueof(countExcpetionRec);
                        rpExceptionRec.Title__c=lst_selectedcommercial_aval[j].Title__r.name;
                        rpExceptionRec.Country__c=lst_selectedcommercial_aval[j].Country_Lookup__r.name;
                        rpExceptionRec.Language__c=lst_selectedcommercial_aval[j].Languages__r.name;
                        rpExceptionRec.Channel__c=commercialAvailList[i].Channel__c;
                        rpExceptionRec.Format__c=commercialAvailList[i].Format__c;
                        rpExceptionRec.Avails_Start__c=commercialAvailList[i].Exclusive_Date__c;
                        rpExceptionRec.Avails_End__c=commercialAvailList[i].Rights_End__c;
                        rpExceptionRec.Release_Start_Date__c=commercialAvailList[i].Start_Date__c;
                        rpExceptionRec.Release_End_Date__c=commercialAvailList[i].End_Date__c;
                        rpExceptionRec.Status__c=commercialAvailList[i].Status__c;  
                        rpExceptionRec.Reason__c='Following overlapping periods  have been found with-'+lst_selectedcommercial_aval[j].name;
                        rpExceptionRec.User_Detail__c=userDetail.Id;
                        releasePlanExceptionList.add(rpExceptionRec);
                        countOverLap++;
                    }
                }
            }// End of inner for loop
            if(countOverLap==0){
                finalReleasePlanList.add(commercialAvailList[i]);
            }
        }
        return finalReleasePlanList;
    }
    
    /**batch id  creation method **/
    public list<Commercial_Avail__c> batchIdGeneration(list<Commercial_Avail__c> list_TobeUpdate){
        
        list<Batch_Ids_Customsetting__c> clientAvailBatchId_lst = [
            Select Id,Name,CA_Batch_Id__c,RP_Batch_Id__c,RP_Created_Date__c,CA_User_Detail__c
              from Batch_Ids_Customsetting__c for update
        ];
        
        integer incremnt = integer.ValueOf(clientAvailBatchId_lst[0].RP_Batch_Id__c);
        incremnt++;
        string finalBatchId = String.valueOf(incremnt);
        
        clientAvailBatchId_lst[0].Name = userDetail.Id;
        clientAvailBatchId_lst[0].RP_Batch_Id__c = finalBatchId ;
        clientAvailBatchId_lst[0].RP_Created_Date__c = system.now();
        clientAvailBatchId_lst[0].CA_User_Detail__c = userDetail.Id;
        Database.Upsertresult[] saveBatchResult  = Database.upsert(clientAvailBatchId_lst, false);
        if(saveBatchResult[0].isSuccess()){ 
            userDetail.RP_Batch_Id__c = clientAvailBatchId_lst[0].RP_Batch_Id__c;
            update userDetail;
        }
        
        for(Commercial_Avail__c client :list_TobeUpdate){
            client.Batch_Id__c = clientAvailBatchId_lst[0].RP_Batch_Id__c;
        }
        return list_TobeUpdate ;
    }
}