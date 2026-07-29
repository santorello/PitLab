// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PitLap';

  @override
  String get appTagline => 'Where modeling meets';

  @override
  String get tracksTitle => 'Tracks';

  @override
  String get menuOpen => 'Open menu';

  @override
  String get menuClose => 'Close menu';

  @override
  String get homeHeadline => 'Where modeling meets';

  @override
  String get homeSubheadline =>
      'Discover tracks, events, shops and people who keep the most real side of the hobby alive.';

  @override
  String get homeExploreTitle => 'Quick entry points';

  @override
  String get homeExploreBody =>
      'Three key areas to orient yourself quickly across tracks, events and useful shops.';

  @override
  String get loginCtaButton => 'Log in';

  @override
  String get loginCtaHint =>
      'Log in to save favorites, report your track attendance and complete your profile later.';

  @override
  String get accountActiveNow => 'Signed in';

  @override
  String get guestModeLabel => 'Guest mode';

  @override
  String get searchTracksHint => 'Search track or place...';

  @override
  String get filterNearby => 'Near you';

  @override
  String get filterBuggy => 'Buggy';

  @override
  String get filterMiniZ => 'Mini-Z';

  @override
  String get filterIndoor => 'Indoor';

  @override
  String get filterOutdoor => 'Outdoor';

  @override
  String get nearbyTitle => 'Nearby';

  @override
  String get spotsTitle => 'Spots';

  @override
  String get eventsTitle => 'Events';

  @override
  String get shopsTitle => 'Shops';

  @override
  String get garageTitle => 'Garage';

  @override
  String get profileTitle => 'Profile';

  @override
  String get managerTitle => 'Manager';

  @override
  String get submitPlaceTitle => 'Report a place';

  @override
  String get spotsDescription =>
      'Community map of informal places to drive together with buggies, scalers, drones and other vehicles outside conventional tracks.';

  @override
  String get spotsHeroTitle => 'Find and share unconventional spots';

  @override
  String get spotsHeroBody =>
      'Riverbanks, quarries, trails, open lots, flying fields and other useful places, with map point, photos and practical notes for the community.';

  @override
  String get spotsHeroChipMap => 'Map point';

  @override
  String get spotsHeroChipPhotos => 'Place photos';

  @override
  String get spotsHeroChipCommunity => 'Shared use';

  @override
  String get spotsSubmitAction => 'Report a spot';

  @override
  String get spotsWhyTitle => 'Why it matters';

  @override
  String get spotsWhyBody =>
      'Not everything happens on official tracks or in shops: this area collects real, informal places that help the community plan lighter meetups.';

  @override
  String get spotsBestForLabel => 'Best for';

  @override
  String get spotsSurfaceLabel => 'Surface';

  @override
  String spotsPhotosCount(int count) {
    return '$count photos';
  }

  @override
  String get spotsSuggestEditAction => 'Suggest an update';

  @override
  String get signupButton => 'Sign me up';

  @override
  String get comingButton => 'I\'m coming';

  @override
  String get trackArrivalConfirmed => 'Arrival set';

  @override
  String get favoriteTrackButton => 'Favorite';

  @override
  String get favoritedTrackButton => 'Saved';

  @override
  String get followTrackButton => 'Follow track';

  @override
  String get followingTrackButton => 'In favorites';

  @override
  String get viewTrackButton => 'View track';

  @override
  String get galleryButton => 'Gallery';

  @override
  String get openMapButton => 'Open map';

  @override
  String get statusOpen => 'OPEN';

  @override
  String get statusWet => 'WET';

  @override
  String get statusClosed => 'CLOSED';

  @override
  String get statusUnknown => 'CHECK NEEDED';

  @override
  String get arrivalsSoonAvailable => 'Arrivals available soon';

  @override
  String get servicesComingSoon => 'Services coming soon';

  @override
  String get noTracksAvailable => 'No tracks available at the moment.';

  @override
  String tracksLoadError(Object error) {
    return 'Error loading tracks: $error';
  }

  @override
  String get trackDetailTitle => 'Track details and current conditions';

  @override
  String get trackNotFound => 'Track not found or not public.';

  @override
  String trackLoadError(Object error) {
    return 'Error loading track: $error';
  }

  @override
  String trackBreadcrumb(Object name) {
    return 'Tracks / $name';
  }

  @override
  String get trackStatusUpdated => 'Track status updated';

  @override
  String get weatherLabel => 'Weather';

  @override
  String get servicesLabel => 'Services';

  @override
  String servicesConfirmedCount(Object count) {
    return '$count confirmed';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get weatherOk => 'OK';

  @override
  String get weatherWarning => 'Warning';

  @override
  String get weatherNo => 'No';

  @override
  String get weatherTrackTitle => 'Track weather';

  @override
  String get weatherQuickVerdict => 'Quick verdict';

  @override
  String weatherTodayVerdict(Object verdict) {
    return '$verdict today';
  }

  @override
  String get weatherDataSourceAttribution =>
      'Weather data provided by Open-Meteo.';

  @override
  String get weatherDaySun => 'Sun';

  @override
  String get weatherDayMon => 'Mon';

  @override
  String get weatherOutdoorOkNote => 'Dry and stable';

  @override
  String get weatherOutdoorWarningNote => 'Cloudy, chance of rain';

  @override
  String get weatherOutdoorNoNote => 'Rain expected';

  @override
  String get weatherIndoorOkNote => 'Indoor, weather impact is low';

  @override
  String get weatherIndoorRegularNote => 'Regular session';

  @override
  String get weatherIndoorWarningNote => 'Traffic and humidity';

  @override
  String get weatherLiveBadge => 'Live weather';

  @override
  String get weatherMockBadge => 'Local fallback';

  @override
  String weatherApiStableDay(Object temp) {
    return 'Stable, high of $temp°C';
  }

  @override
  String weatherApiMixedConditions(Object chance) {
    return 'Mixed, rain up to $chance%';
  }

  @override
  String weatherApiRainExpected(Object chance) {
    return 'Rain likely, up to $chance%';
  }

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryPreviewBody =>
      'Visual preview of the track and surrounding context.';

  @override
  String get galleryCoverTrack => 'Track cover';

  @override
  String get galleryBox => 'Pit area';

  @override
  String get galleryTypicalDay => 'Typical day';

  @override
  String get todayAtTrackTitle => 'Today at the track';

  @override
  String get todayAtTrackStateLabel => 'Today\'s status';

  @override
  String get todayAtTrackUpdatedLabel => 'Last update';

  @override
  String get signInForArrivalStatus =>
      'Sign in to report your arrival and see your status for today.';

  @override
  String get noArrivalForToday =>
      'You have not reported your arrival for today yet.';

  @override
  String get arrivalConfirmed => 'Confirmed: you\'re coming';

  @override
  String get arrivalMaybe => 'Marked as: maybe';

  @override
  String get arrivalCancelled => 'Arrival cancelled';

  @override
  String get arrivalStatusUpdated => 'Arrival status updated';

  @override
  String arrivalRegisteredAt(Object time) {
    return 'Registered at $time';
  }

  @override
  String get arrivalValidForToday =>
      'This attendance only applies to today and clears on the following day.';

  @override
  String get loadingTodayArrival => 'Checking today\'s arrival...';

  @override
  String arrivalReadError(Object error) {
    return 'Unable to read your arrival for today: $error';
  }

  @override
  String get arrivalSheetTitle => 'I\'m coming';

  @override
  String arrivalSheetBody(Object trackName) {
    return 'First UI flow to confirm your arrival for $trackName.';
  }

  @override
  String get arrivalConfirmTitle => 'Confirm';

  @override
  String get arrivalConfirmSubtitle => 'I\'m planning to come.';

  @override
  String get arrivalMaybeTitle => 'Maybe';

  @override
  String get arrivalMaybeSubtitle => 'I might stop by, but I\'m not sure yet.';

  @override
  String get arrivalCancelTitle => 'Cancel';

  @override
  String get arrivalCancelSubtitle =>
      'Mark that you are no longer coming today.';

  @override
  String arrivalSavedMessage(Object selection, Object trackName) {
    return '$selection saved for today at $trackName.';
  }

  @override
  String followTrackSaved(Object trackName) {
    return '$trackName added to favorites.';
  }

  @override
  String followTrackRemoved(Object trackName) {
    return '$trackName removed from favorites.';
  }

  @override
  String get loginTitle => 'Log in to PitLap';

  @override
  String get loginBody =>
      'Enter your email and we\'ll send you a quick sign-in link to access PitLap.';

  @override
  String get loginExistingAccountHint =>
      'If you already have an account, you will use the same access. If this is your first time, PitLap will prepare your basic profile.';

  @override
  String get loginAccountTypeTitle => 'Initial account type';

  @override
  String get loginAccountTypeBody =>
      'Choose how you want to enter PitLap. You can complete and refine the profile later.';

  @override
  String get loginAccountTypeUser => 'Modeler';

  @override
  String get loginAccountTypeShopOwner => 'Shop';

  @override
  String get loginAccountTypeTrackOrganizer => 'Track organizer';

  @override
  String get emailLabel => 'Email';

  @override
  String get loginSendLink => 'Receive sign-in link';

  @override
  String get loginSending => 'Sending...';

  @override
  String get loginTermsConsentLabel => 'I accept the Terms of Service';

  @override
  String get loginTermsConsentHint =>
      'Required to create or use a PitLap account.';

  @override
  String get loginPrivacyNoticeLabel => 'I have read the Privacy Notice';

  @override
  String get loginPrivacyNoticeHint =>
      'Required to continue and understand how we process personal data.';

  @override
  String get loginMarketingConsentLabel =>
      'I agree to receive marketing emails';

  @override
  String get loginMarketingConsentHint =>
      'Optional. Not required to use PitLap and can be withdrawn later.';

  @override
  String get loginLegalDocsHint =>
      'Base legal documents are now available in the project: Privacy Policy, Terms of Service, Cookie Policy and consent register.';

  @override
  String get loginRequiredConsentsError =>
      'To continue, you must accept the Terms of Service and confirm that you have read the Privacy Notice.';

  @override
  String get loginExpiredLinkError =>
      'This sign-in link is no longer valid or has expired. Request a new one.';

  @override
  String get loginGenericAuthError =>
      'We couldn\'t complete sign-in. Please try again with a new link.';

  @override
  String loginRedirectHint(Object path) {
    return 'After login you will return to $path.';
  }

  @override
  String get legalPrivacyTitle => 'Privacy Notice';

  @override
  String get legalPrivacyDescription =>
      'Information on the processing of personal data pursuant to Arts. 13-14 of EU Regulation 2016/679 (GDPR).';

  @override
  String get legalPrivacySectionCollectedTitle => 'Collected data';

  @override
  String get legalPrivacySectionCollectedBody =>
      'PitLap processes account data (email address and user identifier), profile data (display name, language), preferences, saved tracks, daily track attendance, garage or public profile content made visible at the user\'s discretion, and minimal technical data required for security, authentication and correct service operation.';

  @override
  String get legalPrivacySectionPurposeTitle => 'Purposes of processing';

  @override
  String get legalPrivacySectionPurposeBody =>
      'Data is processed to: create and manage the account; provide secure access via magic link; save preferences (language, followed tracks); enable requested features such as track attendance; ensure technical security and prevent abuse; send service-related communications. Only with a separate and specific consent: send marketing communications by email.';

  @override
  String get legalPrivacySectionLegalBasisTitle => 'Legal bases';

  @override
  String get legalPrivacySectionLegalBasisBody =>
      'Contract performance (Art. 6(1)(b) GDPR): account management, authentication and essential features. Legitimate interest (Art. 6(1)(f) GDPR): technical security, abuse prevention and service integrity. Consent (Art. 6(1)(a) GDPR): marketing emails and other optional purposes. Legal obligation (Art. 6(1)(c) GDPR): compliance with applicable law where required.';

  @override
  String get legalPrivacySectionRightsTitle => 'Data subject rights';

  @override
  String get legalPrivacySectionRightsBody =>
      'Under Arts. 15-22 GDPR, users have the right to: access their personal data; obtain rectification or erasure; request restriction of processing; object to processing based on legitimate interest; receive data in a structured format (portability); withdraw consent at any time without affecting the lawfulness of prior processing. To exercise these rights: privacy@pitlap.app. Users may also lodge a complaint with the competent supervisory authority.';

  @override
  String get legalPrivacySectionControllerTitle => 'Data controller';

  @override
  String get legalPrivacySectionControllerBody =>
      'The data controller is PitLap (pre-launch project). Full controller details will be provided before public launch. For any privacy-related enquiry: privacy@pitlap.app.';

  @override
  String get legalPrivacySectionProcessorsTitle =>
      'Processors and sub-processors';

  @override
  String get legalPrivacySectionProcessorsBody =>
      'PitLap uses Supabase Inc. (USA) as provider for database, authentication and storage services, hosted on AWS infrastructure in the eu-west-2 region (Ireland). Data is physically stored within the European Union. Supabase acts as a data processor under Art. 28 GDPR; the Data Processing Agreement is available at supabase.com/privacy. No other third-party providers with access to users\' personal data are currently in use.';

  @override
  String get legalPrivacySectionTransfersTitle => 'International transfers';

  @override
  String get legalPrivacySectionTransfersBody =>
      'Data is stored on servers located in the EU (AWS eu-west-2, Ireland). Supabase Inc. is a US company: any transfer to the USA takes place under the safeguards required by the GDPR (Standard Contractual Clauses adopted by Supabase). No transfers to countries without an adequate level of data protection take place without the guarantees required by applicable law.';

  @override
  String get legalPrivacySectionRetentionTitle => 'Retention periods';

  @override
  String get legalPrivacySectionRetentionBody =>
      'Account data is retained for the duration of the service relationship. Upon account deletion, personal data is erased within 30 days, unless retention is required by law. Track attendance records are automatically deleted after 1 day. Technical security logs are retained for a maximum of 90 days.';

  @override
  String get legalPrivacySectionSecurityTitle => 'Security';

  @override
  String get legalPrivacySectionSecurityBody =>
      'PitLap implements appropriate technical and organisational measures to protect data against unauthorised access, alteration or disclosure. Authentication relies on magic links (no password to store); data is transmitted over HTTPS; infrastructure services are subject to Supabase\'s security controls. In the event of a personal data breach, notification procedures under Arts. 33-34 GDPR will be applied.';

  @override
  String get legalTermsTitle => 'Terms of Service';

  @override
  String get legalTermsDescription =>
      'Conditions governing the use of PitLap. By using the service, users accept these terms.';

  @override
  String get legalTermsSectionServiceTitle => 'Service scope';

  @override
  String get legalTermsSectionServiceBody =>
      'PitLap is a platform to consult tracks, shops, events, profiles, garages and track attendance, with simplified access by email. Some areas may be made public only at the user\'s explicit choice and, depending on product rules, may be visible only to other authenticated users.';

  @override
  String get legalTermsSectionUseTitle => 'Permitted use';

  @override
  String get legalTermsSectionUseBody =>
      'Users agree to use the service lawfully and respectfully, providing accurate data and avoiding abuse of community, profile, garage or attendance features. The following are prohibited: using the service for unlawful purposes, harassing other users, spreading false or misleading content, attempting unauthorised access. PitLap reserves the right to suspend or remove accounts that violate these terms.';

  @override
  String get legalTermsSectionContentTitle => 'User content';

  @override
  String get legalTermsSectionContentBody =>
      'Users are responsible for the content they upload (text, images, builds) and for holding the rights required for its publication. By uploading content, users grant PitLap a non-exclusive licence to display it within the service according to the chosen visibility settings. PitLap may restrict or remove unlawful, misleading, harmful or incompatible material without prior notice.';

  @override
  String get legalTermsSectionAvailabilityTitle =>
      'Availability and moderation';

  @override
  String get legalTermsSectionAvailabilityBody =>
      'The service is provided \'as is\' and may evolve, change or face temporary interruptions. Information about tracks, events, shops, services or attendance may depend on data entered by users, managers or third parties; PitLap does not guarantee that it is always complete, up to date or error-free.';

  @override
  String get legalTermsSectionIPTitle => 'Intellectual property';

  @override
  String get legalTermsSectionIPBody =>
      'The PitLap brand, design, code and content produced by the team are the exclusive property of the owner or respective authors. Unauthorised reproduction, distribution or commercial use is prohibited. Content submitted by users remains the property of its respective authors; PitLap holds only the licence strictly necessary for service operation.';

  @override
  String get legalTermsSectionLiabilityTitle => 'Limitation of liability';

  @override
  String get legalTermsSectionLiabilityBody =>
      'To the extent permitted by law, PitLap is not liable for direct or indirect damages arising from use of or inability to use the service, errors in information provided by users or third parties, service interruptions, or unauthorised access due to events beyond PitLap\'s reasonable control. This limitation does not apply in cases of wilful misconduct or gross negligence.';

  @override
  String get legalTermsSectionGoverningTitle =>
      'Governing law and jurisdiction';

  @override
  String get legalTermsSectionGoverningBody =>
      'These terms are governed by Italian law. For any dispute relating to the use of the service, and where permitted by applicable law, the exclusive jurisdiction shall be that of the court of the user-consumer\'s place of residence or domicile. For professional users, the exclusive forum will be specified in dedicated service conditions.';

  @override
  String get legalCookiesTitle => 'Cookie Policy';

  @override
  String get legalCookiesDescription =>
      'Information on the use of cookies and equivalent technologies on the PitLap website.';

  @override
  String get legalCookiesSectionWhatTitle => 'What are cookies';

  @override
  String get legalCookiesSectionWhatBody =>
      'Cookies are small text files that websites save on a user\'s device during browsing. They are used to make pages work correctly, remember preferences and, in some cases, collect statistical or profiling data. In addition to traditional cookies, this policy applies to equivalent technologies such as session tokens, local identifiers and web storage.';

  @override
  String get legalCookiesSectionTechnicalTitle =>
      'Technical and session cookies';

  @override
  String get legalCookiesSectionTechnicalBody =>
      'PitLap uses only technical cookies strictly necessary for service operation: authentication tokens (user session after magic link login), language preferences and interface settings. These cookies do not require user consent under applicable EU law.';

  @override
  String get legalCookiesSectionAnalyticsTitle => 'Analytics cookies';

  @override
  String get legalCookiesSectionAnalyticsBody =>
      'PitLap does not currently install third-party analytics cookies. Should analytics tools be introduced in the future, this policy will be updated with details of the tools, data collected, purposes and how to give or withdraw consent.';

  @override
  String get legalCookiesSectionMarketingTitle =>
      'Marketing and profiling cookies';

  @override
  String get legalCookiesSectionMarketingBody =>
      'PitLap does not install marketing or profiling cookies. Should they be introduced, they will be preceded by an explicit, specific and freely revocable consent request, in accordance with applicable law.';

  @override
  String get legalCookiesSectionStatusTitle => 'Managing preferences';

  @override
  String get legalCookiesSectionStatusBody =>
      'Since PitLap uses only necessary technical cookies, no mandatory consent banner is required. Users may nevertheless delete stored cookies via their browser or device settings. Removing technical cookies may prevent the service from working correctly (e.g. keeping the login session active).';

  @override
  String get magicLinkSent => 'Magic link sent. Check your email.';

  @override
  String get nearbyDescription =>
      'Discover open tracks, useful shops and nearby events with a quick, grounded read of what is happening around you.';

  @override
  String get nearbyPlaceholderTitle => 'Mixed discovery';

  @override
  String get nearbyPlaceholderBody =>
      'This screen will host a distance-sorted list, basic filters and a secondary map view.';

  @override
  String get nearbyHeroTitle => 'Choose where to go with less friction';

  @override
  String get nearbyHeroBody =>
      'Geolocation should support the decision, not complicate it: useful list first, map only when it really helps.';

  @override
  String get nearbyFlagTracks => 'Nearby tracks';

  @override
  String get nearbyFlagShops => 'Useful shops';

  @override
  String get nearbyFlagOutdoorFirst => 'Outdoor and indoor';

  @override
  String get nearbyHowItWorksTitle => 'How it should work';

  @override
  String get nearbyStepOneTitle => 'Location or city';

  @override
  String get nearbyStepOneBody =>
      'Start from current location or a user-selected city, without forcing the map into the main flow.';

  @override
  String get nearbyStepTwoTitle => 'List before map';

  @override
  String get nearbyStepTwoBody =>
      'Users should immediately see useful tracks and shops, sorted by distance and context.';

  @override
  String get nearbyStepThreeTitle => 'Fast decision';

  @override
  String get nearbyStepThreeBody =>
      'Track status, services and specialization should explain in seconds where it makes sense to go.';

  @override
  String get nearbyPreviewTitle => 'Close to you now';

  @override
  String get nearbyPreviewTrackTitle => 'Offroad Parma';

  @override
  String get nearbyPreviewTrackSubtitle => 'Outdoor track · 9 km';

  @override
  String get nearbyPreviewTrackBadge => 'Track';

  @override
  String get nearbyPreviewTrackNote =>
      'Dry surface, key services available, solid choice for today\'s session.';

  @override
  String get nearbyPreviewShopTitle => 'RC Parts Parma';

  @override
  String get nearbyPreviewShopSubtitle => 'Shop · 11 km';

  @override
  String get nearbyPreviewShopBadge => 'Shop';

  @override
  String get nearbyPreviewShopNote =>
      'Parts and pit support if you need something before heading to the track.';

  @override
  String get eventsDescription => 'All PitLap events';

  @override
  String get eventsPlaceholderTitle => 'MVP events';

  @override
  String get eventsPlaceholderBody =>
      'Events will stay lightweight: list, basic detail and simple RSVP where needed.';

  @override
  String get eventsHeroTitle => 'See what is happening at the track';

  @override
  String get eventsHeroBody =>
      'Races, open practice, demos and community meetups collected in a calendar that is easy to browse and ready to share.';

  @override
  String get eventsPreviewTitle => 'Example event cards';

  @override
  String get eventsDemoOneDate => 'Sat 9 Apr';

  @override
  String get eventsDemoOneTitle => 'Evening open practice';

  @override
  String get eventsDemoOneLocation => 'MiniZ Hub Modena';

  @override
  String get eventsDemoOneNote =>
      'Informal indoor session focused on tire testing and setup work.';

  @override
  String get eventsDemoTwoDate => 'Sun 17 Apr';

  @override
  String get eventsDemoTwoTitle => 'Offroad club day';

  @override
  String get eventsDemoTwoLocation => 'Offroad Parma';

  @override
  String get eventsDemoTwoNote =>
      'Long opening day with expected drivers and active pit area.';

  @override
  String get eventsBadgePractice => 'Practice';

  @override
  String get eventsBadgeRace => 'Club day';

  @override
  String get eventsDirectionTitle => 'Recommended direction';

  @override
  String get eventsDirectionBody =>
      'Start with a clean list showing date, track and context. Richer RSVP and detailed flows should come later, only if truly useful.';

  @override
  String get eventsDetailTitle => 'Event detail';

  @override
  String get eventsDetailDescription =>
      'Reference view for reading an event without losing the context of the day.';

  @override
  String get eventsDetailOverviewTitle => 'Event overview';

  @override
  String get eventsDetailTrackContext => 'Track context';

  @override
  String get eventsDetailCommunity => 'Community';

  @override
  String get eventsDetailLightRsvp => 'Light RSVP';

  @override
  String get garageDescription =>
      'Personal area for models, photos and optional public visibility.';

  @override
  String get garagePlaceholderTitle => 'Personal garage';

  @override
  String get garagePlaceholderBody =>
      'This area will host model lists, images, notes and visibility controls.';

  @override
  String get garageHeroTitle => 'Your featured builds';

  @override
  String get garageHeroBody =>
      'A personal showcase for your models, with photos, light technical details and optional public visibility.';

  @override
  String get garageVisibilityPrivate => 'Private by default';

  @override
  String get garageVisibilityPublic => 'Make it public';

  @override
  String get garageBuildsTitle => 'Recent builds';

  @override
  String garageBuildsCount(Object count) {
    return '$count showcase models';
  }

  @override
  String get garageVisibilityTitle => 'Garage visibility';

  @override
  String get garageVisibilityBody =>
      'The garage starts private, but each build can become public whenever the user wants to show it.';

  @override
  String get garageTogglePrivate => 'Private';

  @override
  String get garageTogglePublic => 'Public';

  @override
  String get garageBuildVisibilityTitle => 'Build visibility';

  @override
  String get garageBuildVisibilityBody =>
      'Each model can have its own visibility, so the user decides what stays personal and what gets shown to others.';

  @override
  String get garageBuildVisibilityPrivate => 'Private build';

  @override
  String get garageBuildVisibilityPublic => 'Public build';

  @override
  String get garageBuildOneName => 'XB8 nitro';

  @override
  String get garageBuildOneMeta => '1/8 buggy · dirt setup';

  @override
  String get garageBuildTwoName => 'Mini-Z MR-03';

  @override
  String get garageBuildTwoMeta => 'Mini-Z · indoor setup';

  @override
  String get garageBuildThreeName => 'Crawler TRX-4';

  @override
  String get garageBuildThreeMeta => 'Scaler · weekend trail';

  @override
  String garagePhotoCount(Object count) {
    return '$count photos';
  }

  @override
  String get garageSpecMotor => 'Motor';

  @override
  String get garageSpecBattery => 'Battery';

  @override
  String get garageSpecSurface => 'Surface';

  @override
  String get garageNextStepTitle => 'Recommended direction';

  @override
  String get garageNextStepBody =>
      'Start with a private garage holding 3-5 builds, cover photos, quick notes and a public toggle for each build.';

  @override
  String get managerScreenTitle => 'Track management';

  @override
  String get managerDescription =>
      'Owner/manager area for track status, services and key data.';

  @override
  String get managerPlaceholderTitle => 'Manager panel';

  @override
  String get managerPlaceholderBody =>
      'Status updates, quick messages, services and basic event management will arrive here.';

  @override
  String get managerHeroTitle => 'Few tools, very clear';

  @override
  String get managerHeroBody =>
      'The manager panel should enable quick and reliable updates, without turning club owners into backoffice operators.';

  @override
  String get managerTodayTitle => 'Main operations';

  @override
  String get managerActionStatusTitle => 'Update track status';

  @override
  String get managerActionStatusBody =>
      'Quickly change status, message and visibility of the update.';

  @override
  String get managerActionServicesTitle => 'Services and availability';

  @override
  String get managerActionServicesBody =>
      'Confirm useful services, pit conditions and small operational details.';

  @override
  String get managerActionEventsTitle => 'Events and special days';

  @override
  String get managerActionEventsBody =>
      'Publish practice sessions, races or special openings with minimal friction.';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminDescription =>
      'Central control panel for categories, users, tracks, shops and monitoring.';

  @override
  String get adminHeroTitle => 'PitLap control center';

  @override
  String get adminHeroBody =>
      'Administrative area to manage catalog, roles, taxonomies, moderation and operational monitoring without relying on manual SQL queries.';

  @override
  String get adminAccessDeniedBody =>
      'This area is reserved for administrator accounts. The real role model will be used to enable or block sensitive tools.';

  @override
  String get adminAccessDeniedCard =>
      'If you are not an admin you can still see that this area exists, but the real actions stay protected. Once ownership is more mature, access will also be enforced on the backend.';

  @override
  String get adminUsersChip => 'Users';

  @override
  String get adminTracksChip => 'Tracks';

  @override
  String get adminShopsChip => 'Shops';

  @override
  String get adminModerationChip => 'Moderation';

  @override
  String get adminOverviewTitle => 'Operational overview';

  @override
  String get adminOverviewBody =>
      'Compact view of the key entities the real admin dashboard will need to monitor.';

  @override
  String get adminUsersMetric => 'Users';

  @override
  String get adminTracksMetric => 'Tracks';

  @override
  String get adminShopsMetric => 'Shops';

  @override
  String get adminEventsMetric => 'Events';

  @override
  String get adminCategoriesMetric => 'Track categories';

  @override
  String get adminOverviewFallback =>
      'Real metrics are not available yet in this instance.';

  @override
  String get adminCategoriesTitle => 'Categories and taxonomies';

  @override
  String get adminCategoriesBody =>
      'First draft of the configurator to expand hobbies and track labels without touching SQL by hand.';

  @override
  String get adminHobbyCategoriesTitle => 'Hobby categories';

  @override
  String get adminHobbyCategoriesBody =>
      'Local draft used to validate the structure and tone of the hobby configurator before the final database model.';

  @override
  String get adminTrackLabelCategoriesTitle => 'Track label categories';

  @override
  String get adminTrackCategoriesBody =>
      'This section is connected to the real track categories stored in the database when the remote schema is aligned.';

  @override
  String get adminAddHobbyCategory => 'New hobby category';

  @override
  String get adminAddTrackLabelCategory => 'New track label category';

  @override
  String get adminAddGenericAction => 'Add';

  @override
  String get adminTrackCategoriesEmpty => 'No track categories available.';

  @override
  String get adminTrackCategoriesUnavailable =>
      'Track categories are not available from this instance yet.';

  @override
  String get adminCategorySaved => 'Category saved.';

  @override
  String get adminCategoryDeleted => 'Category removed.';

  @override
  String adminCategorySaveError(Object error) {
    return 'Unable to save category: $error';
  }

  @override
  String adminCategoryDeleteError(Object error) {
    return 'Unable to remove category: $error';
  }

  @override
  String get adminEntitiesTitle => 'Managed entities';

  @override
  String get adminEntitiesBody =>
      'Blocks that will evolve into dedicated panels for users, tracks, shops, media and moderation.';

  @override
  String get adminShopsCardTitle => 'Shops';

  @override
  String get adminShopsCardBody =>
      'Create, edit, deactivate and connect shops to tracks or owners.';

  @override
  String get adminTracksCardTitle => 'Tracks';

  @override
  String get adminTracksCardBody =>
      'Manage track records, ownership, services, labels and media.';

  @override
  String get adminUsersCardTitle => 'Users';

  @override
  String get adminUsersCardBody =>
      'Inspect profiles, roles, garages, events and overall account state.';

  @override
  String get adminMonitoringTitle => 'Dashboard and monitoring';

  @override
  String get adminMonitoringBody =>
      'Space for the data the admin will actually need: volume, funnel, moderation, media and visited pages.';

  @override
  String get adminVisitedPagesMetric => 'Visited pages';

  @override
  String get adminVisitedPagesPending => 'To connect';

  @override
  String get adminCompletedLoginsMetric => 'Completed logins';

  @override
  String get adminModerationQueueMetric => 'Media to moderate';

  @override
  String get adminOpenReportsMetric => 'Open reports';

  @override
  String get adminUsersPreviewTitle => 'Recent users';

  @override
  String get adminUsersPreviewBody =>
      'First compact look at the active user catalog in this instance.';

  @override
  String get adminUsersPreviewEmpty => 'No users available.';

  @override
  String get adminUsersPreviewUnavailable =>
      'User preview is not available right now.';

  @override
  String get adminImpersonationTitle => 'Impersonate role';

  @override
  String get adminImpersonationBody =>
      'Local testing tool to simulate permissions behavior without actually changing your account in the database.';

  @override
  String get adminImpersonationInactive => 'You are using your real role.';

  @override
  String adminImpersonationActive(Object role) {
    return 'You are testing the app as $role.';
  }

  @override
  String adminImpersonationBanner(Object role) {
    return 'Impersonation active: you are using role $role for UI testing.';
  }

  @override
  String get adminImpersonationStop => 'Stop';

  @override
  String get adminRoleUser => 'User';

  @override
  String get adminRoleShopOwner => 'Shop owner';

  @override
  String get adminRoleTrackOrganizer => 'Track organizer';

  @override
  String get adminRoleAdmin => 'Real admin';

  @override
  String get managerGovernanceTitle => 'Governance principle';

  @override
  String get managerGovernanceBody =>
      'The manager area should stay sober, fast and traceable. Every update should improve user trust, not add operational overhead for the club.';

  @override
  String get profileDescription =>
      'Driver profile with preferences, privacy and garage connection.';

  @override
  String get profilePlaceholderTitle => 'Personal profile';

  @override
  String get profilePlaceholderBody =>
      'We\'ll configure language, identity, avatar and public profile visibility here.';

  @override
  String get profileIdentityTitle => 'Profile identity';

  @override
  String get profileIdentityBody =>
      'A sober account foundation, useful for discovery, garage and future relationships without forcing invasive social patterns.';

  @override
  String get profileFieldFirstName => 'First name';

  @override
  String get profileFieldLastName => 'Last name';

  @override
  String get profileFieldNickname => 'Nickname';

  @override
  String get profileFieldLocation => 'Location';

  @override
  String get profileFieldYearsInHobby => 'Years in the hobby';

  @override
  String get profileVisibleName => 'Visible name';

  @override
  String get profileCurrentEmail => 'Current email';

  @override
  String get profilePreferredLanguage => 'Preferred language';

  @override
  String get profileAccountStatus => 'Account status';

  @override
  String get profileAccountStatusActive => 'Active';

  @override
  String get profileAccountStatusGuest => 'Not signed in';

  @override
  String get profileAccountSnapshotTitle => 'Account snapshot';

  @override
  String get profileAccountSnapshotBody =>
      'A quick account overview before opening more sensitive actions.';

  @override
  String get profileEditBasics => 'Edit basics';

  @override
  String get profileSaveBasics => 'Save basics';

  @override
  String get profileCancelEdit => 'Cancel editing';

  @override
  String get profileSavedMessage => 'Basic profile details saved.';

  @override
  String get profileEditHint =>
      'In this first step you can save visible name and preferred language. The other fields will arrive through onboarding.';

  @override
  String get profileEditableFieldsComingSoon =>
      'First name, last name, nickname, location and years in the hobby will be collected and saved in the next onboarding step.';

  @override
  String get profileNotSignedIn => 'No active email';

  @override
  String get profileSignedIn => 'Signed in';

  @override
  String get profileSignedOut => 'Signed out';

  @override
  String get profileHobbiesTitle => 'Hobbies and interests';

  @override
  String get profileHobbyDrones => 'Drones';

  @override
  String get profileHobbyTrains => 'Trains';

  @override
  String get profilePreferencesHint =>
      'These preferences will support discovery, shops, suggestions and future badges.';

  @override
  String get profilePrivacyTitle => 'Privacy and visibility';

  @override
  String get profilePrivacyBody =>
      'Private by default, with an optional public profile only if the user wants to show up.';

  @override
  String get profileTogglePrivate => 'Private profile';

  @override
  String get profileTogglePublic => 'Public profile';

  @override
  String get profileGarageVisibilityTitle => 'Garage visibility';

  @override
  String get profileGarageVisibilityBody =>
      'The garage can stay fully private or open up selectively, one build at a time.';

  @override
  String get profileConsentTitle => 'Consents and documents';

  @override
  String get profileConsentTerms => 'Terms of Service';

  @override
  String get profileConsentPrivacy => 'Privacy Notice';

  @override
  String get profileConsentMarketing => 'Marketing email';

  @override
  String get profileConsentAccepted => 'Accepted';

  @override
  String get profileConsentNotAccepted => 'Not enabled';

  @override
  String get profileConsentLoading => 'Checking consents...';

  @override
  String get profileConsentUnavailable =>
      'Consent data is not available in this session yet.';

  @override
  String profileConsentVersion(Object version) {
    return 'Recorded document version: $version';
  }

  @override
  String profileConsentUpdatedAt(Object value) {
    return 'Updated on $value';
  }

  @override
  String profileConsentSource(Object source) {
    return 'Source: $source';
  }

  @override
  String get profileSettingsTitle => 'Account settings';

  @override
  String get profileSettingsBody =>
      'Sensitive account operations should live here, separate from the public-facing profile data.';

  @override
  String get profileChangeEmail => 'Change email';

  @override
  String get profileChangeEmailHint =>
      'Guided flow with confirmation on the new email address.';

  @override
  String get profileChangeEmailInfo =>
      'Email change will be connected to a dedicated verified flow with minimal audit.';

  @override
  String get profileResetPassword => 'Reset password';

  @override
  String get profileResetPasswordHint =>
      'Useful for recovery flows when quick sign-in is not enough.';

  @override
  String get profileResetPasswordInfo =>
      'We will shape this as a secure standalone flow, separate from quick sign-in.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutHint =>
      'Closes the session on this browser without touching profile data.';

  @override
  String get profileSignedOutMessage =>
      'You have been signed out successfully.';

  @override
  String get profileCloseAccount => 'Close profile';

  @override
  String get profileCloseAccountHint =>
      'Delicate action to protect with explicit confirmation.';

  @override
  String get profileCloseAccountInfo =>
      'Account closure will require a dedicated flow with data summary, export and final confirmation.';

  @override
  String get profileSummaryTitle => 'Initial proposal';

  @override
  String get profileSummaryBody =>
      'Collect first name, last name, nickname, location, years in RC/modeling, main hobbies, preferred language and garage connection.';

  @override
  String get profileOnboardingAction => 'Open onboarding';

  @override
  String get profileOnboardingActionHint =>
      'Draft of the guided first access flow to decide what should be asked immediately.';

  @override
  String get profileFavoritesTitle => 'Favorites';

  @override
  String get profileFavoritesBody =>
      'Personal hub for followed tracks, saved builds, useful shops and other relevant content.';

  @override
  String get profileFavoriteTracks => 'Saved tracks';

  @override
  String get profileFavoriteBuilds => 'Saved builds';

  @override
  String get profileFavoriteShops => 'Saved shops';

  @override
  String get profileCreatedEventsTitle => 'Created events';

  @override
  String get profileLibraryTitle => 'Digital library';

  @override
  String get profileLibraryBody =>
      'A growing collection of the content that matters to your journey: favorites, events and personal history.';

  @override
  String entitySavedCount(Object count) {
    return '$count saved';
  }

  @override
  String get profileFavoritesHint =>
      'This section will become the cross-product favorites hub, not just a list of tracks.';

  @override
  String get profileFavoriteTracksEmpty => 'No saved tracks yet.';

  @override
  String get profileFavoriteBuildsEmpty => 'No saved builds yet.';

  @override
  String get profileFavoriteShopsEmpty => 'No saved shops yet.';

  @override
  String get profileCreatedEventsEmpty => 'No created events yet.';

  @override
  String get profileArchivedEventsEmpty => 'No past events available.';

  @override
  String get publicProfileTitle => 'Public profile';

  @override
  String publicProfileDescription(Object slug) {
    return 'Public driver profile for $slug';
  }

  @override
  String get publicProfilePlaceholderTitle => 'Opt-in profile';

  @override
  String get publicProfilePlaceholderBody =>
      'The public profile will always stay optional and separate from private account data.';

  @override
  String get shopDetailTitle => 'Shop detail';

  @override
  String shopDetailDescription(Object shopName) {
    return '$shopName';
  }

  @override
  String get shopPlaceholderTitle => 'Shop';

  @override
  String get shopPlaceholderBody =>
      'Identity, distance, main categories and essential contacts will live here.';

  @override
  String get shopsDescription =>
      'Find the nearest shop and discover useful specializations.';

  @override
  String get shopDemoName => 'RC Parts Parma';

  @override
  String get shopDemoSubtitle => 'Spare parts, electronics, pit support';

  @override
  String get shopSecondaryName => 'Mini Garage Modena';

  @override
  String get shopSecondarySubtitle => 'Mini-Z, tires, indoor setup';

  @override
  String shopDistance(Object distance) {
    return '$distance km';
  }

  @override
  String get shopOpenNow => 'Open now';

  @override
  String get shopCallButton => 'Call';

  @override
  String get shopDirectionsButton => 'Directions';

  @override
  String get shopDetailHeroBody =>
      'A practical sheet to quickly find specialties, useful services, contacts and everything you need before stopping by the shop.';

  @override
  String get shopSpecialtiesTitle => 'Specialties';

  @override
  String get shopServicesTitle => 'In-store services';

  @override
  String get shopHoursTitle => 'Hours';

  @override
  String get shopContactsTitle => 'Contacts';

  @override
  String get shopNotesTitle => 'Why it matters';

  @override
  String get shopNotesBody =>
      'Keep the context clean and professional: no promo noise, only clear and reliable information for hobby users.';

  @override
  String get shopEditAction => 'Edit shop';

  @override
  String get shopEditCancel => 'Close edit';

  @override
  String get shopEditSave => 'Save changes';

  @override
  String get shopEditSavedMessage => 'Shop changes saved to the database.';

  @override
  String get shopEditNameLabel => 'Shop name';

  @override
  String get shopEditSubtitleLabel => 'Subtitle';

  @override
  String get shopEditImageUrlLabel => 'Cover image (URL)';

  @override
  String get shopImageUploadAction => 'Upload cover';

  @override
  String get shopGalleryUploadAction => 'Add gallery images';

  @override
  String get shopGalleryFieldLabel => 'Gallery images (one per line)';

  @override
  String shopGalleryLimitHint(Object count, Object max) {
    return 'Gallery: $count/$max images';
  }

  @override
  String get shopEditHoursLabel => 'Hours';

  @override
  String get shopEditContactsLabel => 'Contacts';

  @override
  String get shopEditNotesLabel => 'Operational notes';

  @override
  String get shopImagePreviewUnavailable => 'Image preview unavailable';

  @override
  String get shopProfileModeTitle => 'Shop data';

  @override
  String get shopProfileModeBody =>
      'Fill in the data that will appear on your shop\'s public card.';

  @override
  String get shopServicePickup => 'Quick pickup';

  @override
  String get shopServiceBench => 'Pit support';

  @override
  String get shopServiceElectronics => 'Electronics';

  @override
  String get shopSpecialtyBuggy => '1/8 buggy';

  @override
  String get shopSpecialtyMiniZ => 'Mini-Z';

  @override
  String get shopSpecialtyBatteries => 'Batteries and charging';

  @override
  String get externalLinksTitle => 'Links and channels';

  @override
  String get externalLinksProfileBody =>
      'Add only channels you want to make public on your profile.';

  @override
  String get externalLinksShopBody =>
      'Official shop channels: website, social, videos or operational chats.';

  @override
  String get externalLinksTrackBody =>
      'Official track channels: website, social, race streams or community groups.';

  @override
  String get externalLinksEmpty => 'No public links added yet.';

  @override
  String get externalLinksAddAction => 'Add link';

  @override
  String get externalLinksAddTitle => 'Add an external link';

  @override
  String get externalLinksProviderLabel => 'Channel';

  @override
  String get externalLinksLabelField => 'Alias / visible label';

  @override
  String get externalLinksUrlField => 'URL';

  @override
  String get externalLinksUrlHint =>
      'You can paste the link without https://, we will add it for you.';

  @override
  String get externalLinksInvalidUrlError =>
      'This link does not look valid. Try an address like instagram.com/name or https://yoursite.com.';

  @override
  String get externalLinksPublicToggle => 'Make public';

  @override
  String get externalLinksSaveAction => 'Save link';

  @override
  String get externalLinkProviderWebsite => 'Website';

  @override
  String get externalLinkProviderInstagram => 'Instagram';

  @override
  String get externalLinkProviderFacebook => 'Facebook';

  @override
  String get externalLinkProviderYoutube => 'YouTube';

  @override
  String get externalLinkProviderTiktok => 'TikTok';

  @override
  String get externalLinkProviderWhatsapp => 'WhatsApp';

  @override
  String get externalLinkProviderTelegram => 'Telegram';

  @override
  String get submitPlaceDescription =>
      'Moderated user contribution for tracks, spots, bashing areas or shops.';

  @override
  String get submissionHeroTitle => 'Help expand the real map';

  @override
  String get submissionHeroBody =>
      'User submissions should help surface useful tracks, spots and shops without degrading the public catalog.';

  @override
  String get submissionTypeLabel => 'Type';

  @override
  String get submissionTypeTrack => 'Track';

  @override
  String get submissionTypeSpot => 'Spot / Bashing';

  @override
  String get submissionTypeShop => 'Shop';

  @override
  String get submissionPlaceName => 'Place name';

  @override
  String get submissionCity => 'City';

  @override
  String get submissionDescription => 'Description';

  @override
  String get submissionWhatHelpsTitle => 'What really helps review';

  @override
  String get submissionWhatHelpsBody =>
      'A recognizable name, correct city, concise description and a few practical details greatly improve the quality of the submission.';

  @override
  String get submissionReviewHint =>
      'Submissions do not enter the public catalog automatically: they always go through review.';

  @override
  String get submissionSendButton => 'Send submission';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get onboardingDescription =>
      'Guided first access to decide what to ask immediately and what to keep optional.';

  @override
  String get onboardingHeroTitle => 'A light, but useful first access';

  @override
  String get onboardingHeroBody =>
      'Onboarding should help PitLap understand hobbies, context and preferences without turning registration into a heavy questionnaire.';

  @override
  String get onboardingStepOneTitle => '1. Essential data';

  @override
  String get onboardingStepOneBody =>
      'Email, language, document acceptance and very little else. The first entry should stay frictionless.';

  @override
  String get onboardingStepTwoTitle => '2. Hobby identity';

  @override
  String get onboardingStepTwoBody =>
      'Nickname, location, years in the hobby and an optional short bio.';

  @override
  String get onboardingStepThreeTitle => '3. Hobbies and interests';

  @override
  String get onboardingStepThreeBody =>
      'Preferences such as buggy, Mini-Z, drones or trains help discovery, shops and suggestions.';

  @override
  String get onboardingChecklistTitle => 'Data to collect';

  @override
  String get onboardingChecklistBody =>
      'Initial checklist to decide what to ask immediately, what to make optional and what to postpone.';

  @override
  String get onboardingFieldEmail => 'Account email';

  @override
  String get onboardingFieldLanguage => 'Preferred language';

  @override
  String get onboardingFieldNickname => 'Nickname';

  @override
  String get onboardingFieldLocation => 'Location / city';

  @override
  String get onboardingFieldYears => 'Years in the hobby';

  @override
  String get onboardingFieldHobbies => 'Hobbies and interests';

  @override
  String get onboardingFieldMarketing => 'Optional marketing';

  @override
  String get onboardingFieldAccountType => 'Account type';

  @override
  String onboardingAccountTypeActive(Object role) {
    return 'Active account type: $role';
  }

  @override
  String get onboardingPrinciplesTitle => 'Design principles';

  @override
  String get onboardingPrincipleOne =>
      'Do not ask for everything upfront: start with the minimum that matters.';

  @override
  String get onboardingPrincipleTwo =>
      'Keep optional any data that is not required for the first useful session.';

  @override
  String get onboardingPrincipleThree =>
      'Allow users to complete the profile later without penalizing access.';

  @override
  String get onboardingNextStepTitle => 'Recommended direction';

  @override
  String get onboardingNextStepBody =>
      'Suggested first implementation: login, consent, language, nickname and hobby choice in a maximum 2-step flow.';

  @override
  String get noTracksMatchingFilters => 'No tracks match the active filters.';

  @override
  String get profileBasicsTitle => 'Basics';

  @override
  String get profileBasicsBody =>
      'Here you can already update visible name, language and profile photo. The rest of the profile will land in onboarding.';

  @override
  String get profilePhotoUrl => 'Profile photo (URL)';

  @override
  String get profilePhotoUrlHint =>
      'Paste an image URL to test avatar and preview.';

  @override
  String get profilePhotoUrlSupportHint =>
      'Some sites block direct loading in the browser. In that case PitLap will automatically show the initials fallback.';

  @override
  String get eventsCreateAction => 'Create event';

  @override
  String get eventsCreatedByYouTitle => 'Upcoming public events';

  @override
  String get eventsPublicBadge => 'Public';

  @override
  String get eventsShareAction => 'Share';

  @override
  String get eventsShareCopied =>
      'Event link copied. We can connect it to the full Share panel later.';

  @override
  String get eventsArchiveTitle => 'Event history';

  @override
  String get eventsBadgeCommunity => 'Community';

  @override
  String get eventsBadgeArchived => 'Archive';

  @override
  String get eventsCreateDialogTitle => 'Create a new event';

  @override
  String get eventsCreateTitleLabel => 'Event title';

  @override
  String get eventsCreateLocationLabel => 'Location';

  @override
  String get eventsCreateVenueLabel => 'Venue / track / shop';

  @override
  String get eventsCreateNoteLabel => 'Short note';

  @override
  String get eventsCreateImageAction => 'Upload event photo';

  @override
  String get eventsCreateImageLoaded => 'Event photo ready';

  @override
  String get imageUploadTooLargeMessage =>
      'This image is too heavy for the preview. Try a photo under 5 MB or compress it before uploading.';

  @override
  String get imageUploadUnreadableMessage =>
      'I cannot read this image. Try JPG, PNG, or WebP.';

  @override
  String get mediaUploadNotAuthenticated => 'Sign in to upload images.';

  @override
  String get mediaUploadGenericError =>
      'Image upload failed. Please try again.';

  @override
  String get eventsCreateDateLabel => 'Date';

  @override
  String get eventsCreateSave => 'Save event';

  @override
  String get eventsCreateSuccess =>
      'Public event created. It now appears in the community event list.';

  @override
  String get eventsCreateDefaultNote =>
      'Event created by the PitLap community.';

  @override
  String get eventsEmptyCreatedTitle => 'No created events yet';

  @override
  String get eventsEmptyCreatedBody =>
      'Create your first event to test the community flow and preview how it could appear to other users.';

  @override
  String get clearSearchAction => 'Clear search';

  @override
  String get profileQuickLinksTitle => 'Quick links';

  @override
  String get profileQuickLinksBody =>
      'Fast access to the areas you are already using in the current tests.';

  @override
  String garagePublicBuildsCount(int count) {
    return '$count public builds';
  }

  @override
  String get garageAddBuildAction => 'Add build';

  @override
  String get garageSetPrivateAction => 'Make garage private';

  @override
  String get garageSetPublicAction => 'Make garage public';

  @override
  String get garageBuildsTestingHint =>
      'You can already test build creation, image URL and public/private visibility here.';

  @override
  String get garageBuildTitleLabel => 'Build name';

  @override
  String get garageBuildMetaLabel => 'Category / platform';

  @override
  String get garageBuildImageUrlLabel => 'Build photo (URL)';

  @override
  String get garageImageUploadAction => 'Upload image';

  @override
  String get garageImageLoaded => 'Image ready';

  @override
  String get garageBuildSpecsHint => 'Quick specs separated by commas';

  @override
  String get garageBuildPublicToggle => 'Make this build public';

  @override
  String get garageBuildSaveAction => 'Save build';

  @override
  String get garageBuildCreatedMessage => 'Build added to the garage.';

  @override
  String get garageBuildUpdatedMessage => 'Build updated.';

  @override
  String get garageEditBuildAction => 'Edit build';

  @override
  String garageBuildMaxImagesReached(int max) {
    return 'You can add up to $max images per build.';
  }

  @override
  String garageBuildImagesHelper(int max) {
    return 'You can add up to $max images. The first image is used as the build preview.';
  }

  @override
  String garageBuildImagesCount(int count, int max) {
    return '$count/$max images';
  }

  @override
  String get garageUploadPhotosAction => 'Upload photos';

  @override
  String get processingUploadImages => 'Preparing images';

  @override
  String get processingUploadCover => 'Preparing cover';

  @override
  String get processingUploadGallery => 'Preparing gallery';

  @override
  String get processingUploadEventImage => 'Preparing event photo';

  @override
  String get eventsOpenAction => 'Open event';

  @override
  String get nearbySearchHint => 'Search a nearby track or shop...';

  @override
  String get nearbyFilterAll => 'All';

  @override
  String get nearbyFilterTracks => 'Tracks';

  @override
  String get nearbyFilterShops => 'Shops';

  @override
  String get nearbyNoResults => 'No results for the active filters.';

  @override
  String get nearbyNearMeButton => 'Near me';

  @override
  String get nearbyOpenInMap => 'Open in map';

  @override
  String get nearbyOpenTrack => 'Open track';

  @override
  String get nearbyOpenShop => 'Open shop';

  @override
  String get nearbyNoServices => 'No services';

  @override
  String nearbyServicesCount(int count) {
    return '$count services';
  }

  @override
  String get nearbyShopGeneric => 'RC shop';

  @override
  String get nearbyStatusUpdating => 'Updating';

  @override
  String get shopSearchHint => 'Search a shop or specialty...';

  @override
  String get shopSaveAction => 'Save shop';

  @override
  String get shopSavedAction => 'Shop saved';

  @override
  String get shopOpenDetailsAction => 'Open details';

  @override
  String get shopNoResults => 'No shop matches the current search.';

  @override
  String get managerStatusLabel => 'Today\'s track status';

  @override
  String get managerToggleCompressor => 'Compressed air available';

  @override
  String get managerToggleBathrooms => 'Bathrooms available';

  @override
  String get managerToggleEventReady => 'Evening event confirmed';

  @override
  String get managerStatusMessageLabel => 'Quick message';

  @override
  String get managerSaveAction => 'Save update';

  @override
  String get managerSaveSuccess =>
      'Local update saved. We can use this flow to shape the manager panel.';

  @override
  String managerSaveSuccessTrack(Object trackName) {
    return 'Track update saved for $trackName.';
  }

  @override
  String get managerNoTracksTitle => 'No assigned tracks';

  @override
  String get managerNoTracksBody =>
      'This account can enter the manager area, but it is not currently assigned to any track. The next step is to connect ownership and the real operational panel.';

  @override
  String get managerAssignedTracksTitle => 'Assigned tracks';

  @override
  String get managerAssignedTracksBody =>
      'This list comes from the real `track_managers` relationship, not only from the account global role.';

  @override
  String managerEditingTrack(Object trackName) {
    return 'You are preparing an update for $trackName.';
  }

  @override
  String get submissionImageUrlLabel => 'Photo or cover (URL)';

  @override
  String get submissionMissingFields => 'Fill in at least place name and city.';

  @override
  String submissionSendSuccess(String name, String city) {
    return 'Submission ready: $name in $city.';
  }

  @override
  String get pitcoinBalanceTitle => 'PitCoin';

  @override
  String get pitcoinBalanceSubtitle =>
      'Stack them while you can: sooner or later you\'ll need them.';

  @override
  String pitcoinBalanceDeltaWeek(int count) {
    return '+$count this week';
  }

  @override
  String get pitcoinHistoryAction => 'View activity';

  @override
  String get pitcoinHistoryTitle => 'Activity history';

  @override
  String get pitcoinHistorySubtitle =>
      'All the actions that earned you PitCoin.';

  @override
  String get pitcoinHistoryEmpty =>
      'No activity yet. Start contributing to the community and your PitCoin will appear here.';

  @override
  String get pitcoinHistoryLoadMore => 'Load more';

  @override
  String get pitcoinBadgesTitle => 'Trophies';

  @override
  String get pitcoinBadgesSubtitle => 'Milestones along your PitLap journey.';

  @override
  String get pitcoinBadgesEmpty => 'No trophies unlocked yet.';

  @override
  String get pitcoinBadgeLocked => 'Locked';

  @override
  String pitcoinBadgeUnlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get pitcoinTierBronze => 'Bronze';

  @override
  String get pitcoinTierSilver => 'Silver';

  @override
  String get pitcoinTierGold => 'Gold';

  @override
  String get pitcoinTierSpecial => 'Special';

  @override
  String pitcoinPointsLabel(int count) {
    return '$count PitCoin';
  }

  @override
  String pitcoinPointsShort(int count) {
    return '+$count';
  }

  @override
  String get pitcoinPointsZero => '—';

  @override
  String get trackEditorCategorySection => 'Track category';

  @override
  String get trackEditorCategorySectionBody =>
      'Select the track type — used in search filters.';

  @override
  String get trackEditorServicesSection => 'Available services';

  @override
  String get trackEditorServicesSectionBody =>
      'Select the services confirmed at this track.';

  @override
  String get trackEditorDraftsSection => 'Drafts and pending approval';

  @override
  String get trackEditorDraftsSectionBody =>
      'Tracks you have submitted that are awaiting review or are still in draft.';

  @override
  String get trackEditorDraftEditButton => 'Edit track';

  @override
  String get trackEditorDraftPendingLabel => 'Awaiting admin review';

  @override
  String get shareLinkCopied => 'Link copied to clipboard';

  @override
  String get shareAction => 'Share';

  @override
  String get commentsSectionTitle => 'Comments';

  @override
  String get commentsEmptyTitle => 'No comments yet';

  @override
  String get commentsEmptyBody =>
      'Be the first to leave a comment on this content.';

  @override
  String get commentsLoadMore => 'Load more comments';

  @override
  String get commentsInputHint => 'Write a comment…';

  @override
  String get commentsSubmitAction => 'Send';

  @override
  String get commentsPostError =>
      'Could not post the comment. Please try again.';

  @override
  String get commentsLoadError => 'Error loading comments.';

  @override
  String get commentsDeleteAction => 'Delete';

  @override
  String get commentsDeleteTitle => 'Delete comment';

  @override
  String get commentsDeleteBody =>
      'Are you sure you want to delete this comment? This action cannot be undone.';

  @override
  String get commentsDeleteCancel => 'Cancel';

  @override
  String get commentsDeleteConfirm => 'Delete';

  @override
  String get commentsReportAction => 'Report';

  @override
  String get commentsReportTitle => 'Report comment';

  @override
  String get commentsReportBody =>
      'Do you want to report this comment to the moderation team?';

  @override
  String get commentsReportCancel => 'Cancel';

  @override
  String get commentsReportConfirm => 'Report';

  @override
  String get commentsReportSuccess => 'Comment reported. Thank you.';

  @override
  String get commentsReportError =>
      'Could not send the report. Please try again.';

  @override
  String get commentsGuestCta => 'Sign in to leave a comment.';

  @override
  String get commentsGuestLogin => 'Sign in';

  @override
  String commentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'Comment',
    );
    return '$_temp0';
  }

  @override
  String get profileFollowAction => 'Follow';

  @override
  String get profileFollowingAction => 'Following';

  @override
  String get profileUnfollowAction => 'Unfollow';

  @override
  String get profileFollowerSingular => 'follower';

  @override
  String get profileFollowerPlural => 'followers';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsDescription => 'Your recent notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsLoadMore => 'Load more';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody =>
      'When someone follows you or posts something new, you\'ll see it here.';

  @override
  String get notificationsErrorTitle => 'Could not load notifications.';
}
