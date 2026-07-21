import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_provider.dart';

/// Every user-facing string in the app, in one place, so a language
/// switch (Profile → Language) actually changes what's on screen instead
/// of just saving a preference nobody reads.
abstract class AppStrings {
  factory AppStrings.of(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return _TaStrings();
      default:
        return _EnStrings();
    }
  }

  // Common
  String get save;
  String get cancel;
  String get delete;
  String get retry;

  // Splash
  String get appTagline;

  // Onboarding
  String get skip;
  String get next;
  String get getStarted;
  String get onboardSlide1Title;
  String get onboardSlide1Desc;
  String get onboardSlide2Title;
  String get onboardSlide2Desc;
  String get onboardSlide3Title;
  String get onboardSlide3Desc;

  // Login
  String get welcomeBack;
  String get loginSubtitle;
  String get mobileNumber;
  String get phoneHint;
  String get phoneValidationError;
  String get sendOtp;
  String get termsText;
  String get somethingWentWrong;

  // OTP
  String get verifyYourNumber;
  String otpSubtitle(String phone);
  String resendIn(String mmss);
  String get didntGetCode;
  String get resend;
  String get sendingEllipsis;
  String get verifyAndContinue;
  String get invalidCode;
  String get newCodeSent;

  // Profile setup
  String get tellUsAboutYou;
  String get profileSetupSubtitle;
  String get fullName;
  String get fullNameHint;
  String get enterYourName;
  String get state;
  String get selectYourState;
  String get district;
  String get districtOptional;
  String get districtHint;
  String get continueToDashboard;
  String get addFarmAfterThisNote;

  // Nav / shell
  String get navDashboard;
  String get navFarms;
  String get navMarket;
  String get navAiChat;
  String get navProfile;

  // Dashboard
  String namaste(String name);
  String get farmLooksToday;
  String get farmerFallback;
  String get noFarmsYet;
  String get addFirstFarmDesc;
  String get addAFarm;
  String get landHealthScore;
  String get organicCarbon;
  String get npkBalance;
  String get phSuitability;
  String get erosionRisk;
  String get viewEditSoilReport;
  String get addYourSoilTestReport;
  String get weather7Day;
  String avgHumidity(int pct);
  String rainfallThisWeek(String mm);
  String get today;
  String get fetchingLiveData;
  String get couldNotLoadFarmData;
  String get cropRecommendations;
  String get compareAll;
  String marketPredictionTitle(String commodity);
  String bestSellingMonth(String month);
  String get demoDataNotice;
  String get lowRisk;
  String get mediumRisk;
  String get highRisk;
  String riskLabel(String level);

  // Farms
  String get myFarms;
  String get addFarm;
  String get noFarmsListDesc;
  String get removeThisFarm;
  String removeConfirmDesc(String name);
  String get remove;
  String get viewDashboard;
  String get editFarmNameArea;
  String get viewEditSoilReportMenu;
  String get addSoilReportMenu;
  String get deleteFarm;
  String removedFarm(String name);
  String get labTested;
  String couldNotLoadFarms(String error);

  // Add farm
  String get addAFarmTitle;
  String get howToIdentify;
  String get chooseEasiest;
  String get gpsCoordinates;
  String get useCurrentLocation;
  String get googleMapsLocation;
  String get searchAndPin;
  String get drawFarmBoundary;
  String get traceField;
  String get surveyNumber;
  String get enterSurveyNumber;
  String get locationHierarchyMethodTitle;
  String get searchByAdminArea;
  String get uploadLandDocument;
  String get autoDetectBoundary;
  String get soon;
  String willConnectToService(String methodTitle);
  String get turnOnLocationServices;
  String get locationPermissionNeeded;
  String couldNotGetLocation(String error);

  // Location hierarchy
  String get findYourLand;
  String get country;
  String get india;
  String get cityVillageOptional;
  String get villageHint;
  String get findThisLocation;
  String get locationFound;
  String get continueLabel;
  String couldNotFindLocation(String query);
  String locationLookupFailed(String error);

  // Confirm farm sheet
  String get confirmYourFarm;
  String locationCoords(String lat, String lon);
  String get farmName;
  String get enterFarmName;
  String get approximateAreaAcres;
  String get enterValidArea;
  String get iHaveSoilReport;
  String get soilReportSwitchSubtitle;
  String get ph;
  String get ecDsPerM;
  String get organicCarbonPercent;
  String get nitrogenKgHa;
  String get phosphorusKgHa;
  String get potassiumKgHa;
  String get fetchFarmInsights;
  String alreadyHaveFarmHere(String name);

  // Edit farm sheet
  String get editFarm;

  // Soil report sheet
  String get soilTestReport;
  String get addSoilTestReportTitle;
  String get soilReportUsingInsteadOfEstimate;
  String get soilReportEnterLabValues;
  String get addReport;
  String get removeReportUseEstimate;

  // Weather
  String get weatherTitle;
  String get sevenDayForecast;
  String get forecastConfidenceNote;
  String rainChance(int pct);

  // Market
  String get marketIntelligenceTitle;
  String get predictedPriceRange;
  String get nearbyMandis;

  // Chat
  String get aiAdvisor;
  String get askAboutFarm;
  String get chatGreeting;
  String get chatSuggestion1;
  String get chatSuggestion2;
  String get chatSuggestion3;
  String get chatSuggestion4;
  String get chatReplyRain;
  String get chatReplyCoconut;
  String get chatReplyProfit;
  String get chatReplyDisease;
  String get chatReplyIrrigation;
  String get chatReplyFallback;

  // Profile
  String get profileTitle;
  String get account;
  String get editProfile;
  String get language;
  String get notificationPreferences;
  String get support;
  String get helpFaqs;
  String get termsPrivacy;
  String get about;
  String get signOut;
  String get chooseLanguage;
  String get languageSavedNoTranslationYet;
  String get languagePreferenceSaved;
  String get saveChanges;

  // Crop comparison
  String get compareCrops;
  String get colCrop;
  String get colTerm;
  String get colSuitability;
  String get colYield;
  String get colWater;
  String get colInvestment;
  String get colMaintenance;
  String get colProfit;
  String get colRoi;
  String get colHarvestDays;
  String get colRisk;
  String get colRank;

  // Units
  String acresValue(String value);

  // Diagnose crop disease
  String get diagnoseTitle;
  String get diagnoseSubtitle;
  String get addPhoto;
  String get retakePhoto;
  String get takePhoto;
  String get chooseFromGallery;
  String get cropLabel;
  String get cropHint;
  String get symptomsLabel;
  String get symptomsHint;
  String get enterSymptomsError;
  String get treatmentPreference;
  String get organicOption;
  String get chemicalOption;
  String get getGuidance;
  String get photoUploadedNote;
  String get symptomsSectionTitle;
  String get organicTreatmentSectionTitle;
  String get preventionSectionTitle;
  String get sourcesSectionTitle;
  String matchPercent(int pct);
  String get otherPossibleMatches;
  String get diagnoseCardSubtitle;

  // Water Resources
  String get waterResourcesTitle;
  String get waterResourcesCardSubtitle;
  String get nearbyWaterSources;
  String get noWaterFeaturesFound;
  String get groundwaterStatus;
  String get borewellFeasibility;
  String get irrigationFeasibilitySection;
  String distanceAway(String km);
  String depthBelowGround(String m);
  String waterFeatureType(String type);
  String seasonalAvailability(String value);
  String waterAvailabilityLevel(String value);
  String groundwaterCategory(String value);
  String irrigationMethod(String value);
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final languageCode = ref.watch(languageProvider);
  return AppStrings.of(languageCode);
});

class _EnStrings implements AppStrings {
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get retry => 'Retry';

  @override
  String get appTagline => 'Smarter farming, grounded in data';

  @override
  String get skip => 'Skip';
  @override
  String get next => 'Next';
  @override
  String get getStarted => 'Get started';
  @override
  String get onboardSlide1Title => 'Know your land';
  @override
  String get onboardSlide1Desc =>
      'Locate your farm by GPS, map, or village and instantly see boundary, soil, water and land health — backed by satellite and government data.';
  @override
  String get onboardSlide2Title => 'AI crop recommendations';
  @override
  String get onboardSlide2Desc =>
      'Get ranked crop suggestions with expected yield, cost, profit and risk — every recommendation explained, with a confidence score.';
  @override
  String get onboardSlide3Title => 'Market & weather intelligence';
  @override
  String get onboardSlide3Desc =>
      'Track price forecasts, mandi demand, weather risk and disease/pest alerts for your crops, all in one dashboard.';

  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get loginSubtitle =>
      "Enter your mobile number to continue. We'll text you a one-time code — no password needed.";
  @override
  String get mobileNumber => 'Mobile number';
  @override
  String get phoneHint => '98765 43210';
  @override
  String get phoneValidationError => 'Enter a valid 10-digit mobile number';
  @override
  String get sendOtp => 'Send OTP';
  @override
  String get termsText => 'By continuing, you agree to the Terms of Service and Privacy Policy.';
  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get verifyYourNumber => 'Verify your number';
  @override
  String otpSubtitle(String phone) => 'Enter the 6-digit code sent to $phone';
  @override
  String resendIn(String mmss) => 'Resend code in $mmss';
  @override
  String get didntGetCode => "Didn't get a code?";
  @override
  String get resend => 'Resend';
  @override
  String get sendingEllipsis => 'Sending…';
  @override
  String get verifyAndContinue => 'Verify & continue';
  @override
  String get invalidCode => 'Invalid code';
  @override
  String get newCodeSent => 'A new code has been sent.';

  @override
  String get tellUsAboutYou => 'Tell us about you';
  @override
  String get profileSetupSubtitle =>
      'This helps us tailor recommendations to your region. You can add your farm details next.';
  @override
  String get fullName => 'Full name';
  @override
  String get fullNameHint => 'e.g. Ramesh Kumar';
  @override
  String get enterYourName => 'Enter your name';
  @override
  String get state => 'State';
  @override
  String get selectYourState => 'Select your state';
  @override
  String get district => 'District';
  @override
  String get districtOptional => 'District (optional)';
  @override
  String get districtHint => 'e.g. Nashik';
  @override
  String get continueToDashboard => 'Continue to dashboard';
  @override
  String get addFarmAfterThisNote => 'You can add your first farm right after this.';

  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navFarms => 'Farms';
  @override
  String get navMarket => 'Market';
  @override
  String get navAiChat => 'AI Chat';
  @override
  String get navProfile => 'Profile';

  @override
  String namaste(String name) => 'Namaste, $name 👋';
  @override
  String get farmLooksToday => "Here's how your farm looks today";
  @override
  String get farmerFallback => 'Farmer';
  @override
  String get noFarmsYet => 'No farms yet';
  @override
  String get addFirstFarmDesc => 'Add your first farm to get a live land health, weather and crop recommendation report.';
  @override
  String get addAFarm => 'Add a farm';
  @override
  String get landHealthScore => 'Land Health Score';
  @override
  String get organicCarbon => 'Organic carbon';
  @override
  String get npkBalance => 'NPK balance';
  @override
  String get phSuitability => 'pH suitability';
  @override
  String get erosionRisk => 'Erosion risk';
  @override
  String get viewEditSoilReport => 'View / edit soil report';
  @override
  String get addYourSoilTestReport => 'Add your soil test report';
  @override
  String get weather7Day => 'Weather (7-day)';
  @override
  String avgHumidity(int pct) => 'Avg humidity $pct%';
  @override
  String rainfallThisWeek(String mm) => 'Rainfall this week ${mm}mm';
  @override
  String get today => 'Today';
  @override
  String get fetchingLiveData => 'Fetching live soil, weather and crop data…';
  @override
  String get couldNotLoadFarmData => "Couldn't load your farm data";
  @override
  String get cropRecommendations => 'Crop Recommendations';
  @override
  String get compareAll => 'Compare all';
  @override
  String marketPredictionTitle(String commodity) => 'Market Prediction · $commodity';
  @override
  String bestSellingMonth(String month) => 'Best selling month: $month';
  @override
  String get demoDataNotice => "Market prediction below is sample data — that service isn't built yet.";
  @override
  String get lowRisk => 'low';
  @override
  String get mediumRisk => 'medium';
  @override
  String get highRisk => 'high';
  @override
  String riskLabel(String level) => '$level risk';

  @override
  String get myFarms => 'My Farms';
  @override
  String get addFarm => 'Add farm';
  @override
  String get noFarmsListDesc => 'No farms yet. Tap "Add farm" to identify your land and get a live report.';
  @override
  String get removeThisFarm => 'Remove this farm?';
  @override
  String removeConfirmDesc(String name) => '"$name" and its cached report will be removed from this device.';
  @override
  String get remove => 'Remove';
  @override
  String get viewDashboard => 'View dashboard';
  @override
  String get editFarmNameArea => 'Edit farm name / area';
  @override
  String get viewEditSoilReportMenu => 'View / edit soil report';
  @override
  String get addSoilReportMenu => 'Add soil report';
  @override
  String get deleteFarm => 'Delete farm';
  @override
  String removedFarm(String name) => 'Removed "$name"';
  @override
  String get labTested => 'Lab-tested';
  @override
  String couldNotLoadFarms(String error) => 'Could not load farms: $error';

  @override
  String get addAFarmTitle => 'Add a farm';
  @override
  String get howToIdentify => 'How would you like to identify your land?';
  @override
  String get chooseEasiest => 'Choose whichever is easiest — you can refine the exact boundary afterwards.';
  @override
  String get gpsCoordinates => 'GPS Coordinates';
  @override
  String get useCurrentLocation => 'Use your current location';
  @override
  String get googleMapsLocation => 'Google Maps Location';
  @override
  String get searchAndPin => 'Search and pin a location';
  @override
  String get drawFarmBoundary => 'Draw farm boundary';
  @override
  String get traceField => 'Trace your field on the map';
  @override
  String get surveyNumber => 'Survey number';
  @override
  String get enterSurveyNumber => 'Enter your land survey/SF number';
  @override
  String get locationHierarchyMethodTitle => 'Country / State / District / Village';
  @override
  String get searchByAdminArea => 'Search by administrative area';
  @override
  String get uploadLandDocument => 'Upload land document';
  @override
  String get autoDetectBoundary => 'Auto-detect boundary from a document';
  @override
  String get soon => 'Soon';
  @override
  String willConnectToService(String methodTitle) => '$methodTitle flow will connect to the Land Identification service.';
  @override
  String get turnOnLocationServices => 'Please turn on Location services and try again.';
  @override
  String get locationPermissionNeeded => 'Location permission is needed to use this method.';
  @override
  String couldNotGetLocation(String error) => 'Could not get your location: $error';

  @override
  String get findYourLand => 'Find your land';
  @override
  String get country => 'Country';
  @override
  String get india => 'India';
  @override
  String get cityVillageOptional => 'City / Village (optional)';
  @override
  String get villageHint => 'e.g. Wadgaon';
  @override
  String get findThisLocation => 'Find this location';
  @override
  String get locationFound => 'Location found';
  @override
  String get continueLabel => 'Continue';
  @override
  String couldNotFindLocation(String query) =>
      'Could not find "$query". Try a slightly different spelling, or use GPS Coordinates instead.';
  @override
  String locationLookupFailed(String error) => 'Location lookup failed: $error';

  @override
  String get confirmYourFarm => 'Confirm your farm';
  @override
  String locationCoords(String lat, String lon) => 'Location: $lat, $lon';
  @override
  String get farmName => 'Farm name';
  @override
  String get enterFarmName => 'Enter a farm name';
  @override
  String get approximateAreaAcres => 'Approximate area (acres)';
  @override
  String get enterValidArea => 'Enter a valid area in acres';
  @override
  String get iHaveSoilReport => 'I have a soil test report';
  @override
  String get soilReportSwitchSubtitle => 'Enter your Soil Health Card / lab values for a far more accurate score';
  @override
  String get ph => 'pH';
  @override
  String get ecDsPerM => 'EC (dS/m)';
  @override
  String get organicCarbonPercent => 'Organic carbon (%)';
  @override
  String get nitrogenKgHa => 'N (kg/ha)';
  @override
  String get phosphorusKgHa => 'P (kg/ha)';
  @override
  String get potassiumKgHa => 'K (kg/ha)';
  @override
  String get fetchFarmInsights => 'Fetch farm insights';
  @override
  String alreadyHaveFarmHere(String name) =>
      'You already have a farm here: "$name". Delete it first if you want to re-add this spot.';

  @override
  String get editFarm => 'Edit farm';

  @override
  String get soilTestReport => 'Soil test report';
  @override
  String get addSoilTestReportTitle => 'Add soil test report';
  @override
  String get soilReportUsingInsteadOfEstimate =>
      'These values are being used instead of the satellite estimate. Update or remove them below.';
  @override
  String get soilReportEnterLabValues =>
      'Enter your Soil Health Card / lab values for a far more accurate Land Health Score.';
  @override
  String get addReport => 'Add report';
  @override
  String get removeReportUseEstimate => 'Remove report (use satellite estimate)';

  @override
  String get weatherTitle => 'Weather';
  @override
  String get sevenDayForecast => '7-day forecast';
  @override
  String get forecastConfidenceNote =>
      'Forecast confidence decreases with horizon — 7-day figures are high confidence; 90-day and seasonal outlooks are indicative only.';
  @override
  String rainChance(int pct) => 'Rain chance $pct%';

  @override
  String get marketIntelligenceTitle => 'Market Intelligence';
  @override
  String get predictedPriceRange => 'Predicted price range';
  @override
  String get nearbyMandis => 'Nearby mandis';

  @override
  String get aiAdvisor => 'AI Advisor';
  @override
  String get askAboutFarm => 'Ask about your farm…';
  @override
  String get chatGreeting =>
      "Namaste! I'm your AI farm advisor. Ask me about weather, crops, market prices, or anything else about your farm.";
  @override
  String get chatSuggestion1 => 'Will it rain this week?';
  @override
  String get chatSuggestion2 => 'What should I grow?';
  @override
  String get chatSuggestion3 => 'Should I irrigate today?';
  @override
  String get chatSuggestion4 => 'Why are my leaves turning yellow?';
  @override
  String get chatReplyRain =>
      "There's a 20% chance of rain today, rising to 65% by Thursday. I'd hold off on irrigation until we're past the wetter mid-week window.";
  @override
  String get chatReplyCoconut =>
      "Coconut needs more consistent water availability and a warmer, humid climate than your farm currently shows — suitability is estimated at 38%, so I wouldn't recommend it here without added irrigation.";
  @override
  String get chatReplyProfit =>
      "Based on your soil, water and this season's price outlook, Cotton currently ranks highest — 88% suitability and an estimated ₹42,000/acre profit, though medium risk from price volatility.";
  @override
  String get chatReplyDisease =>
      "Yellowing leaves can mean nitrogen deficiency, overwatering, or early blight. Could you share the crop and how long you've noticed it? A photo would help narrow this down.";
  @override
  String get chatReplyIrrigation =>
      "Soil moisture is currently adequate and rain is likely by Thursday — I'd skip irrigation today and re-check after the rain passes.";
  @override
  String get chatReplyFallback =>
      "I don't have a confident, data-backed answer for that yet — this is a demo response. Once connected to the live services I'll ground this in your farm's real data.";

  @override
  String get profileTitle => 'Profile';
  @override
  String get account => 'Account';
  @override
  String get editProfile => 'Edit profile';
  @override
  String get language => 'Language';
  @override
  String get notificationPreferences => 'Notification preferences';
  @override
  String get support => 'Support';
  @override
  String get helpFaqs => 'Help & FAQs';
  @override
  String get termsPrivacy => 'Terms & Privacy Policy';
  @override
  String get about => 'About';
  @override
  String get signOut => 'Sign out';
  @override
  String get chooseLanguage => 'Choose language';
  @override
  String get languageSavedNoTranslationYet =>
      'Saved. Full app translation for this language is still being built — screens will remain in English for now.';
  @override
  String get languagePreferenceSaved => 'Language preference saved.';
  @override
  String get saveChanges => 'Save changes';

  @override
  String get compareCrops => 'Compare crops';
  @override
  String get colCrop => 'Crop';
  @override
  String get colTerm => 'Term';
  @override
  String get colSuitability => 'Suitability';
  @override
  String get colYield => 'Yield (qtl)';
  @override
  String get colWater => 'Water (mm)';
  @override
  String get colInvestment => 'Investment';
  @override
  String get colMaintenance => 'Maintenance';
  @override
  String get colProfit => 'Profit';
  @override
  String get colRoi => 'ROI';
  @override
  String get colHarvestDays => 'Harvest (days)';
  @override
  String get colRisk => 'Risk';
  @override
  String get colRank => 'Rank';

  @override
  String acresValue(String value) => '$value acres';

  @override
  String get diagnoseTitle => 'Diagnose a crop problem';
  @override
  String get diagnoseSubtitle => "Add a photo (optional) and describe what you're seeing";
  @override
  String get addPhoto => 'Add photo';
  @override
  String get retakePhoto => 'Change photo';
  @override
  String get takePhoto => 'Take photo';
  @override
  String get chooseFromGallery => 'Choose from gallery';
  @override
  String get cropLabel => 'Crop';
  @override
  String get cropHint => 'e.g. Rice, Cotton, Tomato';
  @override
  String get symptomsLabel => 'Describe the symptoms';
  @override
  String get symptomsHint => 'e.g. yellow spots with brown edges on older leaves';
  @override
  String get enterSymptomsError => 'Describe the symptoms first';
  @override
  String get treatmentPreference => 'Treatment preference';
  @override
  String get organicOption => 'Organic / natural';
  @override
  String get chemicalOption => 'Chemical / conventional';
  @override
  String get getGuidance => 'Get guidance';
  @override
  String get photoUploadedNote =>
      "Photo received — describe symptoms below for guidance (automatic photo analysis isn't available yet).";
  @override
  String get symptomsSectionTitle => 'Symptoms';
  @override
  String get organicTreatmentSectionTitle => 'Organic treatment';
  @override
  String get preventionSectionTitle => 'Prevention';
  @override
  String get sourcesSectionTitle => 'Sources';
  @override
  String matchPercent(int pct) => '$pct% match';
  @override
  String get otherPossibleMatches => 'Other possible matches';
  @override
  String get diagnoseCardSubtitle => 'Photo + organic treatment guidance';

  @override
  String get waterResourcesTitle => 'Water Resources';
  @override
  String get waterResourcesCardSubtitle => 'Nearby water sources & irrigation feasibility';
  @override
  String get nearbyWaterSources => 'Nearby Water Sources';
  @override
  String get noWaterFeaturesFound => 'No nearby water features found in the estimate.';
  @override
  String get groundwaterStatus => 'Groundwater Status';
  @override
  String get borewellFeasibility => 'Borewell Feasibility';
  @override
  String get irrigationFeasibilitySection => 'Irrigation Feasibility';
  @override
  String distanceAway(String km) => '$km km away';
  @override
  String depthBelowGround(String m) => '$m m below ground';
  @override
  String waterFeatureType(String type) => switch (type) {
        'river' => 'River',
        'canal' => 'Canal',
        'lake' => 'Lake',
        'pond' => 'Pond',
        'well' => 'Well',
        'borewell' => 'Borewell',
        'reservoir' => 'Reservoir',
        'check_dam' => 'Check Dam',
        'irrigation_channel' => 'Irrigation Channel',
        _ => type,
      };
  @override
  String seasonalAvailability(String value) => switch (value) {
        'perennial' => 'Perennial (year-round)',
        'seasonal' => 'Seasonal',
        'monsoon_only' => 'Monsoon only',
        _ => value,
      };
  @override
  String waterAvailabilityLevel(String value) => switch (value) {
        'low' => 'Low',
        'moderate' => 'Moderate',
        'high' => 'High',
        _ => value,
      };
  @override
  String groundwaterCategory(String value) => switch (value) {
        'safe' => 'Safe',
        'semi_critical' => 'Semi-Critical',
        'critical' => 'Critical',
        'over_exploited' => 'Over-Exploited',
        _ => value,
      };
  @override
  String irrigationMethod(String value) => switch (value) {
        'gravity_fed' => 'Gravity-fed',
        'pumped' => 'Pumped',
        'limited' => 'Limited',
        _ => value,
      };
}

class _TaStrings implements AppStrings {
  @override
  String get save => 'சேமி';
  @override
  String get cancel => 'ரத்து செய்';
  @override
  String get delete => 'நீக்கு';
  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get appTagline => 'தரவின் அடிப்படையில் புத்திசாலி விவசாயம்';

  @override
  String get skip => 'தவிர்';
  @override
  String get next => 'அடுத்து';
  @override
  String get getStarted => 'தொடங்குவோம்';
  @override
  String get onboardSlide1Title => 'உங்கள் நிலத்தை அறியுங்கள்';
  @override
  String get onboardSlide1Desc =>
      'GPS, வரைபடம் அல்லது கிராமம் மூலம் உங்கள் பண்ணையைக் கண்டறிந்து, எல்லை, மண், நீர் மற்றும் நில ஆரோக்கியத்தை உடனடியாகப் பாருங்கள் — செயற்கைக்கோள் மற்றும் அரசு தரவுகளின் அடிப்படையில்.';
  @override
  String get onboardSlide2Title => 'AI பயிர் பரிந்துரைகள்';
  @override
  String get onboardSlide2Desc =>
      'எதிர்பார்க்கப்படும் மகசூல், செலவு, லாபம் மற்றும் இடர் ஆகியவற்றுடன் தரவரிசைப்படுத்தப்பட்ட பயிர் பரிந்துரைகளைப் பெறுங்கள் — ஒவ்வொரு பரிந்துரையும் நம்பகத்தன்மை மதிப்பெண்ணுடன் விளக்கப்படும்.';
  @override
  String get onboardSlide3Title => 'சந்தை மற்றும் வானிலை நுண்ணறிவு';
  @override
  String get onboardSlide3Desc =>
      'உங்கள் பயிர்களுக்கான விலை முன்னறிவிப்புகள், சந்தை தேவை, வானிலை இடர் மற்றும் நோய்/பூச்சி எச்சரிக்கைகளை ஒரே டாஷ்போர்டில் கண்காணியுங்கள்.';

  @override
  String get welcomeBack => 'மீண்டும் வரவேற்கிறோம்';
  @override
  String get loginSubtitle => 'தொடர உங்கள் மொபைல் எண்ணை உள்ளிடவும். ஒரு முறை பயன்படும் குறியீட்டை அனுப்புவோம் — கடவுச்சொல் தேவையில்லை.';
  @override
  String get mobileNumber => 'மொபைல் எண்';
  @override
  String get phoneHint => '98765 43210';
  @override
  String get phoneValidationError => 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';
  @override
  String get sendOtp => 'OTP அனுப்பு';
  @override
  String get termsText => 'தொடர்வதன் மூலம், சேவை விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கிறீர்கள்.';
  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get verifyYourNumber => 'உங்கள் எண்ணை சரிபார்க்கவும்';
  @override
  String otpSubtitle(String phone) => '$phone க்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்';
  @override
  String resendIn(String mmss) => '$mmss இல் குறியீட்டை மீண்டும் அனுப்பு';
  @override
  String get didntGetCode => 'குறியீடு கிடைக்கவில்லையா?';
  @override
  String get resend => 'மீண்டும் அனுப்பு';
  @override
  String get sendingEllipsis => 'அனுப்புகிறது…';
  @override
  String get verifyAndContinue => 'சரிபார்த்து தொடரவும்';
  @override
  String get invalidCode => 'தவறான குறியீடு';
  @override
  String get newCodeSent => 'புதிய குறியீடு அனுப்பப்பட்டது.';

  @override
  String get tellUsAboutYou => 'உங்களைப் பற்றி சொல்லுங்கள்';
  @override
  String get profileSetupSubtitle =>
      'இது உங்கள் பகுதிக்கு ஏற்ப பரிந்துரைகளை வடிவமைக்க உதவும். அடுத்ததாக உங்கள் பண்ணை விவரங்களைச் சேர்க்கலாம்.';
  @override
  String get fullName => 'முழு பெயர்';
  @override
  String get fullNameHint => 'உதா. ரமேஷ் குமார்';
  @override
  String get enterYourName => 'உங்கள் பெயரை உள்ளிடவும்';
  @override
  String get state => 'மாநிலம்';
  @override
  String get selectYourState => 'உங்கள் மாநிலத்தைத் தேர்ந்தெடுக்கவும்';
  @override
  String get district => 'மாவட்டம்';
  @override
  String get districtOptional => 'மாவட்டம் (விருப்பம்)';
  @override
  String get districtHint => 'உதா. நாசிக்';
  @override
  String get continueToDashboard => 'டாஷ்போர்டுக்கு தொடரவும்';
  @override
  String get addFarmAfterThisNote => 'இதற்குப் பிறகு உங்கள் முதல் பண்ணையைச் சேர்க்கலாம்.';

  @override
  String get navDashboard => 'டாஷ்போர்டு';
  @override
  String get navFarms => 'பண்ணைகள்';
  @override
  String get navMarket => 'சந்தை';
  @override
  String get navAiChat => 'AI அரட்டை';
  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String namaste(String name) => 'வணக்கம், $name 👋';
  @override
  String get farmLooksToday => 'இன்று உங்கள் பண்ணை எப்படி இருக்கிறது';
  @override
  String get farmerFallback => 'விவசாயி';
  @override
  String get noFarmsYet => 'இன்னும் பண்ணைகள் இல்லை';
  @override
  String get addFirstFarmDesc =>
      'நேரடி நில ஆரோக்கியம், வானிலை மற்றும் பயிர் பரிந்துரை அறிக்கையைப் பெற உங்கள் முதல் பண்ணையைச் சேர்க்கவும்.';
  @override
  String get addAFarm => 'பண்ணை சேர்க்கவும்';
  @override
  String get landHealthScore => 'நில ஆரோக்கிய மதிப்பெண்';
  @override
  String get organicCarbon => 'கரிம கார்பன்';
  @override
  String get npkBalance => 'NPK சமநிலை';
  @override
  String get phSuitability => 'pH பொருத்தம்';
  @override
  String get erosionRisk => 'மண் அரிப்பு இடர்';
  @override
  String get viewEditSoilReport => 'மண் அறிக்கையைப் பார்க்க / திருத்த';
  @override
  String get addYourSoilTestReport => 'உங்கள் மண் பரிசோதனை அறிக்கையைச் சேர்க்கவும்';
  @override
  String get weather7Day => 'வானிலை (7-நாள்)';
  @override
  String avgHumidity(int pct) => 'சராசரி ஈரப்பதம் $pct%';
  @override
  String rainfallThisWeek(String mm) => 'இந்த வாரம் மழைப்பொழிவு ${mm}mm';
  @override
  String get today => 'இன்று';
  @override
  String get fetchingLiveData => 'நேரடி மண், வானிலை மற்றும் பயிர் தரவைப் பெறுகிறது…';
  @override
  String get couldNotLoadFarmData => 'உங்கள் பண்ணை தரவை ஏற்ற முடியவில்லை';
  @override
  String get cropRecommendations => 'பயிர் பரிந்துரைகள்';
  @override
  String get compareAll => 'அனைத்தையும் ஒப்பிடு';
  @override
  String marketPredictionTitle(String commodity) => 'சந்தை முன்னறிவிப்பு · $commodity';
  @override
  String bestSellingMonth(String month) => 'சிறந்த விற்பனை மாதம்: $month';
  @override
  String get demoDataNotice => 'கீழே உள்ள சந்தை முன்னறிவிப்பு மாதிரி தரவு — அந்த சேவை இன்னும் உருவாக்கப்படவில்லை.';
  @override
  String get lowRisk => 'குறைந்த';
  @override
  String get mediumRisk => 'நடுத்தர';
  @override
  String get highRisk => 'அதிக';
  @override
  String riskLabel(String level) => '$level இடர்';

  @override
  String get myFarms => 'என் பண்ணைகள்';
  @override
  String get addFarm => 'பண்ணை சேர்';
  @override
  String get noFarmsListDesc => 'இன்னும் பண்ணைகள் இல்லை. உங்கள் நிலத்தை அடையாளம் கண்டு நேரடி அறிக்கையைப் பெற "பண்ணை சேர்" ஐத் தட்டவும்.';
  @override
  String get removeThisFarm => 'இந்த பண்ணையை அகற்றவா?';
  @override
  String removeConfirmDesc(String name) => '"$name" மற்றும் அதன் சேமிக்கப்பட்ட அறிக்கை இந்த சாதனத்திலிருந்து அகற்றப்படும்.';
  @override
  String get remove => 'அகற்று';
  @override
  String get viewDashboard => 'டாஷ்போர்டைப் பார்க்க';
  @override
  String get editFarmNameArea => 'பண்ணை பெயர் / பரப்பளவைத் திருத்த';
  @override
  String get viewEditSoilReportMenu => 'மண் அறிக்கையைப் பார்க்க / திருத்த';
  @override
  String get addSoilReportMenu => 'மண் அறிக்கை சேர்க்க';
  @override
  String get deleteFarm => 'பண்ணையை நீக்கு';
  @override
  String removedFarm(String name) => '"$name" அகற்றப்பட்டது';
  @override
  String get labTested => 'ஆய்வக பரிசோதனை';
  @override
  String couldNotLoadFarms(String error) => 'பண்ணைகளை ஏற்ற முடியவில்லை: $error';

  @override
  String get addAFarmTitle => 'பண்ணை சேர்க்கவும்';
  @override
  String get howToIdentify => 'உங்கள் நிலத்தை எவ்வாறு அடையாளம் காண விரும்புகிறீர்கள்?';
  @override
  String get chooseEasiest => 'எது எளிதோ அதைத் தேர்ந்தெடுக்கவும் — பின்னர் சரியான எல்லையை மேம்படுத்தலாம்.';
  @override
  String get gpsCoordinates => 'GPS ஆயத்தொலைவுகள்';
  @override
  String get useCurrentLocation => 'உங்கள் தற்போதைய இருப்பிடத்தைப் பயன்படுத்தவும்';
  @override
  String get googleMapsLocation => 'Google Maps இருப்பிடம்';
  @override
  String get searchAndPin => 'ஒரு இருப்பிடத்தைத் தேடி குறிக்கவும்';
  @override
  String get drawFarmBoundary => 'பண்ணை எல்லையை வரையவும்';
  @override
  String get traceField => 'வரைபடத்தில் உங்கள் வயலைக் கோடிடவும்';
  @override
  String get surveyNumber => 'சர்வே எண்';
  @override
  String get enterSurveyNumber => 'உங்கள் நில சர்வே/SF எண்ணை உள்ளிடவும்';
  @override
  String get locationHierarchyMethodTitle => 'நாடு / மாநிலம் / மாவட்டம் / கிராமம்';
  @override
  String get searchByAdminArea => 'நிர்வாகப் பகுதி மூலம் தேடவும்';
  @override
  String get uploadLandDocument => 'நில ஆவணத்தைப் பதிவேற்று';
  @override
  String get autoDetectBoundary => 'ஆவணத்திலிருந்து எல்லையை தானாக கண்டறியவும்';
  @override
  String get soon => 'விரைவில்';
  @override
  String willConnectToService(String methodTitle) => '$methodTitle செயல்முறை நில அடையாள சேவையுடன் இணைக்கப்படும்.';
  @override
  String get turnOnLocationServices => 'தயவுசெய்து இருப்பிட சேவைகளை இயக்கி மீண்டும் முயற்சிக்கவும்.';
  @override
  String get locationPermissionNeeded => 'இந்த முறையைப் பயன்படுத்த இருப்பிட அனுமதி தேவை.';
  @override
  String couldNotGetLocation(String error) => 'உங்கள் இருப்பிடத்தைப் பெற முடியவில்லை: $error';

  @override
  String get findYourLand => 'உங்கள் நிலத்தைக் கண்டறியவும்';
  @override
  String get country => 'நாடு';
  @override
  String get india => 'இந்தியா';
  @override
  String get cityVillageOptional => 'நகரம் / கிராமம் (விருப்பம்)';
  @override
  String get villageHint => 'உதா. வட்காவ்';
  @override
  String get findThisLocation => 'இந்த இருப்பிடத்தைக் கண்டறியவும்';
  @override
  String get locationFound => 'இருப்பிடம் கண்டறியப்பட்டது';
  @override
  String get continueLabel => 'தொடரவும்';
  @override
  String couldNotFindLocation(String query) =>
      '"$query" ஐக் கண்டறிய முடியவில்லை. சற்று வேறு எழுத்துப்பிழையை முயற்சிக்கவும், அல்லது GPS ஆயத்தொலைவுகளைப் பயன்படுத்தவும்.';
  @override
  String locationLookupFailed(String error) => 'இருப்பிடத் தேடல் தோல்வியடைந்தது: $error';

  @override
  String get confirmYourFarm => 'உங்கள் பண்ணையை உறுதிப்படுத்தவும்';
  @override
  String locationCoords(String lat, String lon) => 'இருப்பிடம்: $lat, $lon';
  @override
  String get farmName => 'பண்ணை பெயர்';
  @override
  String get enterFarmName => 'பண்ணை பெயரை உள்ளிடவும்';
  @override
  String get approximateAreaAcres => 'தோராயமான பரப்பளவு (ஏக்கர்)';
  @override
  String get enterValidArea => 'சரியான பரப்பளவை ஏக்கரில் உள்ளிடவும்';
  @override
  String get iHaveSoilReport => 'என்னிடம் மண் பரிசோதனை அறிக்கை உள்ளது';
  @override
  String get soilReportSwitchSubtitle => 'மிகவும் துல்லியமான மதிப்பெண்ணுக்கு உங்கள் மண் ஆரோக்கிய அட்டை / ஆய்வக மதிப்புகளை உள்ளிடவும்';
  @override
  String get ph => 'pH';
  @override
  String get ecDsPerM => 'EC (dS/m)';
  @override
  String get organicCarbonPercent => 'கரிம கார்பன் (%)';
  @override
  String get nitrogenKgHa => 'N (kg/ha)';
  @override
  String get phosphorusKgHa => 'P (kg/ha)';
  @override
  String get potassiumKgHa => 'K (kg/ha)';
  @override
  String get fetchFarmInsights => 'பண்ணை நுண்ணறிவைப் பெறவும்';
  @override
  String alreadyHaveFarmHere(String name) =>
      'இங்கே ஏற்கனவே உங்களுக்கு ஒரு பண்ணை உள்ளது: "$name". இந்த இடத்தை மீண்டும் சேர்க்க விரும்பினால் முதலில் அதை நீக்கவும்.';

  @override
  String get editFarm => 'பண்ணையைத் திருத்து';

  @override
  String get soilTestReport => 'மண் பரிசோதனை அறிக்கை';
  @override
  String get addSoilTestReportTitle => 'மண் பரிசோதனை அறிக்கையைச் சேர்க்கவும்';
  @override
  String get soilReportUsingInsteadOfEstimate =>
      'செயற்கைக்கோள் மதிப்பீட்டிற்குப் பதிலாக இந்த மதிப்புகள் பயன்படுத்தப்படுகின்றன. கீழே புதுப்பிக்கவும் அல்லது அகற்றவும்.';
  @override
  String get soilReportEnterLabValues =>
      'மிகவும் துல்லியமான நில ஆரோக்கிய மதிப்பெண்ணுக்கு உங்கள் மண் ஆரோக்கிய அட்டை / ஆய்வக மதிப்புகளை உள்ளிடவும்.';
  @override
  String get addReport => 'அறிக்கை சேர்க்கவும்';
  @override
  String get removeReportUseEstimate => 'அறிக்கையை அகற்று (செயற்கைக்கோள் மதிப்பீட்டைப் பயன்படுத்து)';

  @override
  String get weatherTitle => 'வானிலை';
  @override
  String get sevenDayForecast => '7-நாள் முன்னறிவிப்பு';
  @override
  String get forecastConfidenceNote =>
      'முன்னறிவிப்பு நம்பகத்தன்மை காலவரம்பு அதிகரிக்க குறையும் — 7-நாள் புள்ளிவிவரங்கள் அதிக நம்பகத்தன்மை கொண்டவை; 90-நாள் மற்றும் பருவகால கணிப்புகள் ஒரு அறிகுறி மட்டுமே.';
  @override
  String rainChance(int pct) => 'மழை வாய்ப்பு $pct%';

  @override
  String get marketIntelligenceTitle => 'சந்தை நுண்ணறிவு';
  @override
  String get predictedPriceRange => 'முன்னறிவிக்கப்பட்ட விலை வரம்பு';
  @override
  String get nearbyMandis => 'அருகிலுள்ள மண்டிகள்';

  @override
  String get aiAdvisor => 'AI ஆலோசகர்';
  @override
  String get askAboutFarm => 'உங்கள் பண்ணையைப் பற்றி கேளுங்கள்…';
  @override
  String get chatGreeting =>
      'வணக்கம்! நான் உங்கள் AI பண்ணை ஆலோசகர். வானிலை, பயிர்கள், சந்தை விலைகள் அல்லது உங்கள் பண்ணை பற்றி எதைப் பற்றியும் என்னிடம் கேளுங்கள்.';
  @override
  String get chatSuggestion1 => 'இந்த வாரம் மழை பெய்யுமா?';
  @override
  String get chatSuggestion2 => 'நான் என்ன பயிரிட வேண்டும்?';
  @override
  String get chatSuggestion3 => 'இன்று நீர்ப்பாசனம் செய்ய வேண்டுமா?';
  @override
  String get chatSuggestion4 => 'ஏன் என் இலைகள் மஞ்சளாக மாறுகின்றன?';
  @override
  String get chatReplyRain =>
      'இன்று 20% மழை வாய்ப்பு உள்ளது, வியாழக்கிழமையளவில் 65% ஆக உயரும். வாரத்தின் நடுப்பகுதியில் மழை கடக்கும் வரை நீர்ப்பாசனத்தை தவிர்ப்பது நல்லது.';
  @override
  String get chatReplyCoconut =>
      'தென்னைக்கு உங்கள் பண்ணையை விட அதிக நிலையான நீர் கிடைப்பும், வெப்பமான ஈரப்பதமான காலநிலையும் தேவை — பொருத்தம் 38% என மதிப்பிடப்படுகிறது, எனவே கூடுதல் நீர்ப்பாசனம் இல்லாமல் இங்கு பரிந்துரைக்க மாட்டேன்.';
  @override
  String get chatReplyProfit =>
      'உங்கள் மண், நீர் மற்றும் இந்த பருவத்தின் விலை கணிப்பின் அடிப்படையில், பருத்தி தற்போது அதிக மதிப்பெண் பெறுகிறது — 88% பொருத்தம் மற்றும் ஏக்கருக்கு ₹42,000 மதிப்பிடப்பட்ட லாபம், எனினும் விலை ஏற்ற இறக்கத்தால் நடுத்தர இடர்.';
  @override
  String get chatReplyDisease =>
      'மஞ்சள் இலைகள் நைட்ரஜன் குறைபாடு, அதிக நீர்ப்பாசனம் அல்லது ஆரம்பகட்ட நோயைக் குறிக்கலாம். பயிர் மற்றும் எவ்வளவு காலமாக இதைக் கவனித்தீர்கள் என்று பகிருங்கள்? ஒரு புகைப்படம் இதைச் சரியாகக் கண்டறிய உதவும்.';
  @override
  String get chatReplyIrrigation =>
      'மண் ஈரப்பதம் தற்போது போதுமானதாக உள்ளது, வியாழக்கிழமையளவில் மழை வாய்ப்புள்ளது — இன்று நீர்ப்பாசனத்தைத் தவிர்த்து மழைக்குப் பிறகு மீண்டும் சரிபார்க்கவும்.';
  @override
  String get chatReplyFallback =>
      'அதற்கு நம்பகமான, தரவு அடிப்படையிலான பதில் என்னிடம் இன்னும் இல்லை — இது ஒரு டெமோ பதில். நேரடி சேவைகளுடன் இணைந்தவுடன், இதை உங்கள் பண்ணையின் உண்மையான தரவின் அடிப்படையில் தருவேன்.';

  @override
  String get profileTitle => 'சுயவிவரம்';
  @override
  String get account => 'கணக்கு';
  @override
  String get editProfile => 'சுயவிவரத்தைத் திருத்து';
  @override
  String get language => 'மொழி';
  @override
  String get notificationPreferences => 'அறிவிப்பு விருப்பங்கள்';
  @override
  String get support => 'ஆதரவு';
  @override
  String get helpFaqs => 'உதவி & அடிக்கடி கேட்கப்படும் கேள்விகள்';
  @override
  String get termsPrivacy => 'விதிமுறைகள் & தனியுரிமைக் கொள்கை';
  @override
  String get about => 'பற்றி';
  @override
  String get signOut => 'வெளியேறு';
  @override
  String get chooseLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';
  @override
  String get languageSavedNoTranslationYet =>
      'சேமிக்கப்பட்டது. இந்த மொழிக்கான முழு மொழிபெயர்ப்பு இன்னும் உருவாக்கப்படுகிறது.';
  @override
  String get languagePreferenceSaved => 'மொழி விருப்பம் சேமிக்கப்பட்டது.';
  @override
  String get saveChanges => 'மாற்றங்களைச் சேமி';

  @override
  String get compareCrops => 'பயிர்களை ஒப்பிடு';
  @override
  String get colCrop => 'பயிர்';
  @override
  String get colTerm => 'காலம்';
  @override
  String get colSuitability => 'பொருத்தம்';
  @override
  String get colYield => 'மகசூல் (qtl)';
  @override
  String get colWater => 'நீர் (mm)';
  @override
  String get colInvestment => 'முதலீடு';
  @override
  String get colMaintenance => 'பராமரிப்பு';
  @override
  String get colProfit => 'லாபம்';
  @override
  String get colRoi => 'ROI';
  @override
  String get colHarvestDays => 'அறுவடை (நாட்கள்)';
  @override
  String get colRisk => 'இடர்';
  @override
  String get colRank => 'தரவரிசை';

  @override
  String acresValue(String value) => '$value ஏக்கர்';

  @override
  String get diagnoseTitle => 'பயிர் பிரச்சனையைக் கண்டறியவும்';
  @override
  String get diagnoseSubtitle => 'ஒரு புகைப்படத்தைச் சேர்க்கவும் (விருப்பம்) மற்றும் நீங்கள் காண்பதை விவரிக்கவும்';
  @override
  String get addPhoto => 'புகைப்படம் சேர்';
  @override
  String get retakePhoto => 'புகைப்படத்தை மாற்று';
  @override
  String get takePhoto => 'புகைப்படம் எடு';
  @override
  String get chooseFromGallery => 'கேலரியில் இருந்து தேர்ந்தெடு';
  @override
  String get cropLabel => 'பயிர்';
  @override
  String get cropHint => 'உதா. நெல், பருத்தி, தக்காளி';
  @override
  String get symptomsLabel => 'அறிகுறிகளை விவரிக்கவும்';
  @override
  String get symptomsHint => 'உதா. பழைய இலைகளில் பழுப்பு விளிம்புகளுடன் மஞ்சள் புள்ளிகள்';
  @override
  String get enterSymptomsError => 'முதலில் அறிகுறிகளை விவரிக்கவும்';
  @override
  String get treatmentPreference => 'சிகிச்சை விருப்பம்';
  @override
  String get organicOption => 'இயற்கை / ஆர்கானிக்';
  @override
  String get chemicalOption => 'இரசாயன / வழக்கமான';
  @override
  String get getGuidance => 'வழிகாட்டுதலைப் பெறவும்';
  @override
  String get photoUploadedNote =>
      'புகைப்படம் பெறப்பட்டது — வழிகாட்டுதலுக்கு கீழே அறிகுறிகளை விவரிக்கவும் (தானியங்கி புகைப்பட பகுப்பாய்வு இன்னும் கிடைக்கவில்லை).';
  @override
  String get symptomsSectionTitle => 'அறிகுறிகள்';
  @override
  String get organicTreatmentSectionTitle => 'இயற்கை சிகிச்சை';
  @override
  String get preventionSectionTitle => 'தடுப்பு';
  @override
  String get sourcesSectionTitle => 'ஆதாரங்கள்';
  @override
  String matchPercent(int pct) => '$pct% பொருத்தம்';
  @override
  String get otherPossibleMatches => 'மற்ற சாத்தியமான பொருத்தங்கள்';
  @override
  String get diagnoseCardSubtitle => 'புகைப்படம் + இயற்கை சிகிச்சை வழிகாட்டுதல்';

  @override
  String get waterResourcesTitle => 'நீர் வளங்கள்';
  @override
  String get waterResourcesCardSubtitle => 'அருகிலுள்ள நீர் ஆதாரங்கள் & பாசன சாத்தியக்கூறு';
  @override
  String get nearbyWaterSources => 'அருகிலுள்ள நீர் ஆதாரங்கள்';
  @override
  String get noWaterFeaturesFound => 'அருகில் நீர் ஆதாரங்கள் எதுவும் கிடைக்கவில்லை.';
  @override
  String get groundwaterStatus => 'நிலத்தடி நீர் நிலை';
  @override
  String get borewellFeasibility => 'ஆழ்குழாய் கிணறு சாத்தியக்கூறு';
  @override
  String get irrigationFeasibilitySection => 'பாசன சாத்தியக்கூறு';
  @override
  String distanceAway(String km) => '$km கி.மீ தொலைவில்';
  @override
  String depthBelowGround(String m) => 'தரைக்கு கீழே $m மீ ஆழத்தில்';
  @override
  String waterFeatureType(String type) => switch (type) {
        'river' => 'ஆறு',
        'canal' => 'கால்வாய்',
        'lake' => 'ஏரி',
        'pond' => 'குளம்',
        'well' => 'கிணறு',
        'borewell' => 'ஆழ்குழாய் கிணறு',
        'reservoir' => 'நீர்த்தேக்கம்',
        'check_dam' => 'தடுப்பணை (Check Dam)',
        'irrigation_channel' => 'பாசன கால்வாய்',
        _ => type,
      };
  @override
  String seasonalAvailability(String value) => switch (value) {
        'perennial' => 'வற்றாதது (ஆண்டு முழுவதும்)',
        'seasonal' => 'பருவகாலம்',
        'monsoon_only' => 'பருவமழை காலம் மட்டும்',
        _ => value,
      };
  @override
  String waterAvailabilityLevel(String value) => switch (value) {
        'low' => 'குறைவு',
        'moderate' => 'மிதமானது',
        'high' => 'அதிகம்',
        _ => value,
      };
  @override
  String groundwaterCategory(String value) => switch (value) {
        'safe' => 'பாதுகாப்பானது (Safe)',
        'semi_critical' => 'செமி-கிரிட்டிகல் (கவனம் தேவை)',
        'critical' => 'கிரிட்டிகல் (அதிக அழுத்தம்)',
        'over_exploited' => 'ஓவர்-எக்ஸ்ப்ளாய்டட் (அதிகப் பயன்பாடு)',
        _ => value,
      };
  @override
  String irrigationMethod(String value) => switch (value) {
        'gravity_fed' => 'ஈர்ப்பு விசை பாசனம்',
        'pumped' => 'பம்ப் மூலம்',
        'limited' => 'மட்டுப்படுத்தப்பட்டது',
        _ => value,
      };
}
