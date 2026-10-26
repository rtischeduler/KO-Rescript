 return{


Ranks = {
		{4,	"Owner", 	{"l0tzie", 3882403525, "riotfan1223",4190983061}	};
		{3,	"HeadAdmin",	{"mr_bolde2", 7797782638, "DenisTheCheeseKing", 459870224, "EclipsedFormula",392381235, "BlueEnderCookie_2",274893778,"Player1",-1} };
	{2,	"Admin",		{"",0},	};
	{1,	"Mod",			{"",0}	};
	{1,	"VIP",			{"",0},	};
	{0,	"NonAdmin",		};
};




Gamepasses = {
	
	

};



Assets = {
	[0] = "VIP";
};



Groups = {
	[0] = {
		[254] = "Admin";
		[1] = "VIP";
		};
};



Friends = "NonAdmin";



VipServerOwner = "NonAdmin";



FreeAdmin = "NonAdmin";









Banned = {"",0};









Prefix				= ";";			
SplitKey 			= " ";			
BatchKey 			= "";			
QualifierBatchKey 	= ",";			

AppFont				= Enum.Font.SourceSans; 
AppTheme			= "Blurple";	
AppThemes = {
	{"Blurple", Color3.fromRGB(94, 86, 213),	};
	{"Red", 	Color3.fromRGB(199, 80, 82),	};
	{"Orange", 	Color3.fromRGB(152, 114, 69),	};
	{"Green", 	Color3.fromRGB(73, 148, 104),	};
	{"Blue", 	Color3.fromRGB(91, 122, 189),	};
	{"Pink",	Color3.fromRGB(172, 121, 167),	};
	{"Black", 	Color3.fromRGB(35, 39, 47),		};
};

ShowOnlyUsableAndBuyableCommands	= true; 	
DisableBoosterBundles				= false;	
RankRequiredToViewCommandsIcon		= 999; 		
RankRequiredToViewDashboardIcon		= 999; 		

NoticeSoundId		= 2865227271;	
NoticeVolume		= 0.1;			
NoticePitch			= 1;			
ErrorSoundId		= 2865228021;	
ErrorVolume			= 0.1;			
ErrorPitch			= 1;			
AlertSoundId		= 9161622880;	
AlertVolume			= 0.5;			
AlertPitch			= 1;			

WelcomeBadgeId		= 0;			

CommandDebounce		= true;			
SaveRank			= true;			
LoopCommands		= 3;			

Colors = {							
	{"r", 		"Red",		 		Color3.fromRGB(255, 0, 0)		};
	{"o", 		"Orange",	 		Color3.fromRGB(250, 100, 0)		};
	{"y", 		"Yellow",			Color3.fromRGB(255, 255, 0)		};
	{"g", 		"Green"	,			Color3.fromRGB(0, 255, 0)		};
	{"dg", 		"DarkGreen"	, 		Color3.fromRGB(0, 125, 0)		};
	{"b", 		"Blue",		 		Color3.fromRGB(0, 255, 255)		};
	{"db", 		"DarkBlue",			Color3.fromRGB(0, 50, 255)		};
	{"p", 		"Purple",	 		Color3.fromRGB(150, 0, 255)		};
	{"pk",		"Pink",		 		Color3.fromRGB(255, 85, 185)	};
	{"bk",		"Black",		 	Color3.fromRGB(0, 0, 0)			};
	{"w",		"White",	 		Color3.fromRGB(255, 255, 255)	};
};

Cmdbar						= 1;			
Cmdbar2						= 1;			
ViewBanland					= 4;			
RankRequiredToViewPage		= {				
	["Commands"]		= 0;
	["Moderation"]		= 3;
	["Revenue"]			= 3;
	["Settings"]		= 1;
};

WelcomeRankNotice			= false;			
ChartsNotice				= false;			
WarnIncorrectPrefix			= false;			
DisableAllNotices			= false;		
HideWarningsIfBelowRank		= 1; 			

ScaleLimit					= 3;			
IgnoreScaleLimit			= 3;			
CommandLimits				= {				
	["fly"]	= {
		Limit 				= 70;
		IgnoreLimit 		= 3;
	};
	["health"]	= {
		Limit 				= 999999999;
		IgnoreLimit 		= 3;
	};
	["fly2"]	= {
		Limit 				= 70;
		IgnoreLimit 		= 3;
	};
	["noclip"]	= {
		Limit 				= 10000;
		IgnoreLimit 		= 3;
	};
	["noclip2"]	= {
		Limit 				= 10000;
		IgnoreLimit 		= 3;
	};
	["speed"]	= {
		Limit 				= 60;
		IgnoreLimit 		= 3;
	};
	["jumpPower"]	= {
		Limit 				= 0;
		IgnoreLimit 		= 3;
	};
};

VIPServerCommandBlacklist	= {};	
GearBlacklist				= {67798397};	
IgnoreGearBlacklist			= 4;			

PlayerDataStoreVersion		= "V1.0";		
SystemDataStoreVersion		= "V1.0";		

CoreNotices					= {				
	
};

AutoSaveMap					= false;		 


-- hey fucker i see you change these settings and i remove you dev rank

SetCommandRankByName = {
		
		["disco"] = "Owner";
		["music"] = "Owner";
	["add"] = "HeadAdmin";
	["resetstats"] = "HeadAdmin";
		["subtract"] = "HeadAdmin";
		["buildingtools"] = "HeadAdmin";
		["logs"] = "HeadAdmin";
		["damage"] = "HeadAdmin";
		["god"] = "HeadAdmin";
		["health"] = "HeadAdmin";
		["r15"] = "HeadAdmin";
		["heal"] = "HeadAdmin";
		["gear"] = "HeadAdmin";
		["bring"] = "HeadAdmin";
		["teleport"] = "HeadAdmin";
		["r6"] = "HeadAdmin";
		["explode"] = "HeadAdmin";
		["change"] = "HeadAdmin";
		["chathijacker"] = "HeadAdmin";
		["control"] = "HeadAdmin";
	
	["shutdown"] = "HeadAdmin";
	["permRank"] = "HeadAdmin";
	["permBan"] = "Owner";
	["permUnban"] = "Owner";
	["ban"] = "Owner";
	["unban"] = "Owner";
	["banland"] = "Owner";
	["globalAnnouncement"] = "HeadAdmin";
	["makeAdmin"] = "HeadAdmin";
	["makeHeadAdmin"] = "HeadAdmin";
	["makeOwner"] = "HeadAdmin";
	["unRank"] = "HeadAdmin";
	["serverLock"] = "HeadAdmin";
	["debug"] = "HeadAdmin";
	["place"] = "HeadAdmin";
	["maxPlayers"] = "HeadAdmin";
	["private"] = "HeadAdmin";
	["unPrivate"] = "HeadAdmin";
	["vipServer"] = "HeadAdmin";
	["unVipServer"] = "HeadAdmin";
	["script"] = "HeadAdmin";
	["unScript"] = "HeadAdmin";
	["run"] = "HeadAdmin";
	["unRun"] = "HeadAdmin";
	["load"] = "HeadAdmin";
	["unLoad"] = "HeadAdmin";
	["save"] = "HeadAdmin";
	["unSave"] = "HeadAdmin";
	["export"] = "HeadAdmin";
	["import"] = "HeadAdmin";
	["backup"] = "HeadAdmin";
	["restore"] = "HeadAdmin";
	["reset"] = "HeadAdmin";
	["settings"] = "HeadAdmin";
	["theme"] = "HeadAdmin";
	["prefix"] = "HeadAdmin";
	["splitKey"] = "HeadAdmin";
	["batchKey"] = "HeadAdmin";
	["qualifierBatchKey"] = "HeadAdmin";
	["commandDebounce"] = "HeadAdmin";
	["saveRank"] = "HeadAdmin";
	["loopCommands"] = "HeadAdmin";
	["scaleLimit"] = "HeadAdmin";
	["ignoreScaleLimit"] = "HeadAdmin";
	["commandLimits"] = "HeadAdmin";
	["vipServerCommandBlacklist"] = "HeadAdmin";
	["gearBlacklist"] = "HeadAdmin";
	["ignoreGearBlacklist"] = "HeadAdmin";
	["playerDataStoreVersion"] = "HeadAdmin";
	["systemDataStoreVersion"] = "HeadAdmin";
	["coreNotices"] = "HeadAdmin";
	["autoSaveMap"] = "HeadAdmin";
	["welcomeBadgeId"] = "HeadAdmin";
	["noticeSoundId"] = "HeadAdmin";
	["noticeVolume"] = "HeadAdmin";
	["noticePitch"] = "HeadAdmin";
	["errorSoundId"] = "HeadAdmin";
	["errorVolume"] = "HeadAdmin";
	["errorPitch"] = "HeadAdmin";
	["alertSoundId"] = "HeadAdmin";
	["alertVolume"] = "HeadAdmin";
	["alertPitch"] = "HeadAdmin";
	["appFont"] = "HeadAdmin";
	["appTheme"] = "HeadAdmin";
	["appThemes"] = "HeadAdmin";
	["showOnlyUsableAndBuyableCommands"] = "HeadAdmin";
	["disableBoosterBundles"] = "HeadAdmin";
	["rankRequiredToViewCommandsIcon"] = "HeadAdmin";
	["rankRequiredToViewDashboardIcon"] = "HeadAdmin";
	["welcomeRankNotice"] = "HeadAdmin";
	["chartsNotice"] = "HeadAdmin";
	["warnIncorrectPrefix"] = "HeadAdmin";
	["disableAllNotices"] = "HeadAdmin";
	["hideWarningsIfBelowRank"] = "HeadAdmin";
	["cmdbar"] = "HeadAdmin";
	["cmdbar2"] = "HeadAdmin";
	["viewBanland"] = "Owner";
	["rankRequiredToViewPage"] = "HeadAdmin";
};	








};