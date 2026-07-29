import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PitLap'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Where modeling meets'**
  String get appTagline;

  /// No description provided for @tracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracksTitle;

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get menuOpen;

  /// No description provided for @menuClose.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get menuClose;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Where modeling meets'**
  String get homeHeadline;

  /// No description provided for @homeSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Discover tracks, events, shops and people who keep the most real side of the hobby alive.'**
  String get homeSubheadline;

  /// No description provided for @homeExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick entry points'**
  String get homeExploreTitle;

  /// No description provided for @homeExploreBody.
  ///
  /// In en, this message translates to:
  /// **'Three key areas to orient yourself quickly across tracks, events and useful shops.'**
  String get homeExploreBody;

  /// No description provided for @loginCtaButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginCtaButton;

  /// No description provided for @loginCtaHint.
  ///
  /// In en, this message translates to:
  /// **'Log in to save favorites, report your track attendance and complete your profile later.'**
  String get loginCtaHint;

  /// No description provided for @accountActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountActiveNow;

  /// No description provided for @guestModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestModeLabel;

  /// No description provided for @searchTracksHint.
  ///
  /// In en, this message translates to:
  /// **'Search track or place...'**
  String get searchTracksHint;

  /// No description provided for @filterNearby.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get filterNearby;

  /// No description provided for @filterBuggy.
  ///
  /// In en, this message translates to:
  /// **'Buggy'**
  String get filterBuggy;

  /// No description provided for @filterMiniZ.
  ///
  /// In en, this message translates to:
  /// **'Mini-Z'**
  String get filterMiniZ;

  /// No description provided for @filterIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get filterIndoor;

  /// No description provided for @filterOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get filterOutdoor;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyTitle;

  /// No description provided for @spotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spots'**
  String get spotsTitle;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @shopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shopsTitle;

  /// No description provided for @garageTitle.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get garageTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @managerTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get managerTitle;

  /// No description provided for @submitPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a place'**
  String get submitPlaceTitle;

  /// No description provided for @spotsDescription.
  ///
  /// In en, this message translates to:
  /// **'Community map of informal places to drive together with buggies, scalers, drones and other vehicles outside conventional tracks.'**
  String get spotsDescription;

  /// No description provided for @spotsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find and share unconventional spots'**
  String get spotsHeroTitle;

  /// No description provided for @spotsHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Riverbanks, quarries, trails, open lots, flying fields and other useful places, with map point, photos and practical notes for the community.'**
  String get spotsHeroBody;

  /// No description provided for @spotsHeroChipMap.
  ///
  /// In en, this message translates to:
  /// **'Map point'**
  String get spotsHeroChipMap;

  /// No description provided for @spotsHeroChipPhotos.
  ///
  /// In en, this message translates to:
  /// **'Place photos'**
  String get spotsHeroChipPhotos;

  /// No description provided for @spotsHeroChipCommunity.
  ///
  /// In en, this message translates to:
  /// **'Shared use'**
  String get spotsHeroChipCommunity;

  /// No description provided for @spotsSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Report a spot'**
  String get spotsSubmitAction;

  /// No description provided for @spotsWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get spotsWhyTitle;

  /// No description provided for @spotsWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Not everything happens on official tracks or in shops: this area collects real, informal places that help the community plan lighter meetups.'**
  String get spotsWhyBody;

  /// No description provided for @spotsBestForLabel.
  ///
  /// In en, this message translates to:
  /// **'Best for'**
  String get spotsBestForLabel;

  /// No description provided for @spotsSurfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get spotsSurfaceLabel;

  /// No description provided for @spotsPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String spotsPhotosCount(int count);

  /// No description provided for @spotsSuggestEditAction.
  ///
  /// In en, this message translates to:
  /// **'Suggest an update'**
  String get spotsSuggestEditAction;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign me up'**
  String get signupButton;

  /// No description provided for @comingButton.
  ///
  /// In en, this message translates to:
  /// **'I\'m coming'**
  String get comingButton;

  /// No description provided for @favoriteTrackButton.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteTrackButton;

  /// No description provided for @favoritedTrackButton.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get favoritedTrackButton;

  /// No description provided for @followTrackButton.
  ///
  /// In en, this message translates to:
  /// **'Follow track'**
  String get followTrackButton;

  /// No description provided for @followingTrackButton.
  ///
  /// In en, this message translates to:
  /// **'In favorites'**
  String get followingTrackButton;

  /// No description provided for @viewTrackButton.
  ///
  /// In en, this message translates to:
  /// **'View track'**
  String get viewTrackButton;

  /// No description provided for @galleryButton.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryButton;

  /// No description provided for @openMapButton.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMapButton;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get statusOpen;

  /// No description provided for @statusWet.
  ///
  /// In en, this message translates to:
  /// **'WET'**
  String get statusWet;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get statusClosed;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'CHECK NEEDED'**
  String get statusUnknown;

  /// No description provided for @arrivalsSoonAvailable.
  ///
  /// In en, this message translates to:
  /// **'Arrivals available soon'**
  String get arrivalsSoonAvailable;

  /// No description provided for @servicesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Services coming soon'**
  String get servicesComingSoon;

  /// No description provided for @noTracksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tracks available at the moment.'**
  String get noTracksAvailable;

  /// No description provided for @tracksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading tracks: {error}'**
  String tracksLoadError(Object error);

  /// No description provided for @trackDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Track details and current conditions'**
  String get trackDetailTitle;

  /// No description provided for @trackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Track not found or not public.'**
  String get trackNotFound;

  /// No description provided for @trackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading track: {error}'**
  String trackLoadError(Object error);

  /// No description provided for @trackBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Tracks / {name}'**
  String trackBreadcrumb(Object name);

  /// No description provided for @trackStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Track status updated'**
  String get trackStatusUpdated;

  /// No description provided for @weatherLabel.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherLabel;

  /// No description provided for @servicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesLabel;

  /// No description provided for @servicesConfirmedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} confirmed'**
  String servicesConfirmedCount(Object count);

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @weatherOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get weatherOk;

  /// No description provided for @weatherWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get weatherWarning;

  /// No description provided for @weatherNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get weatherNo;

  /// No description provided for @weatherTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track weather'**
  String get weatherTrackTitle;

  /// No description provided for @weatherQuickVerdict.
  ///
  /// In en, this message translates to:
  /// **'Quick verdict'**
  String get weatherQuickVerdict;

  /// No description provided for @weatherTodayVerdict.
  ///
  /// In en, this message translates to:
  /// **'{verdict} today'**
  String weatherTodayVerdict(Object verdict);

  /// No description provided for @weatherDataSourceAttribution.
  ///
  /// In en, this message translates to:
  /// **'Weather data provided by Open-Meteo.'**
  String get weatherDataSourceAttribution;

  /// No description provided for @weatherDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weatherDaySun;

  /// No description provided for @weatherDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weatherDayMon;

  /// No description provided for @weatherOutdoorOkNote.
  ///
  /// In en, this message translates to:
  /// **'Dry and stable'**
  String get weatherOutdoorOkNote;

  /// No description provided for @weatherOutdoorWarningNote.
  ///
  /// In en, this message translates to:
  /// **'Cloudy, chance of rain'**
  String get weatherOutdoorWarningNote;

  /// No description provided for @weatherOutdoorNoNote.
  ///
  /// In en, this message translates to:
  /// **'Rain expected'**
  String get weatherOutdoorNoNote;

  /// No description provided for @weatherIndoorOkNote.
  ///
  /// In en, this message translates to:
  /// **'Indoor, weather impact is low'**
  String get weatherIndoorOkNote;

  /// No description provided for @weatherIndoorRegularNote.
  ///
  /// In en, this message translates to:
  /// **'Regular session'**
  String get weatherIndoorRegularNote;

  /// No description provided for @weatherIndoorWarningNote.
  ///
  /// In en, this message translates to:
  /// **'Traffic and humidity'**
  String get weatherIndoorWarningNote;

  /// No description provided for @weatherLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live weather'**
  String get weatherLiveBadge;

  /// No description provided for @weatherMockBadge.
  ///
  /// In en, this message translates to:
  /// **'Local fallback'**
  String get weatherMockBadge;

  /// No description provided for @weatherApiStableDay.
  ///
  /// In en, this message translates to:
  /// **'Stable, high of {temp}°C'**
  String weatherApiStableDay(Object temp);

  /// No description provided for @weatherApiMixedConditions.
  ///
  /// In en, this message translates to:
  /// **'Mixed, rain up to {chance}%'**
  String weatherApiMixedConditions(Object chance);

  /// No description provided for @weatherApiRainExpected.
  ///
  /// In en, this message translates to:
  /// **'Rain likely, up to {chance}%'**
  String weatherApiRainExpected(Object chance);

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @galleryPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Visual preview of the track and surrounding context.'**
  String get galleryPreviewBody;

  /// No description provided for @galleryCoverTrack.
  ///
  /// In en, this message translates to:
  /// **'Track cover'**
  String get galleryCoverTrack;

  /// No description provided for @galleryBox.
  ///
  /// In en, this message translates to:
  /// **'Pit area'**
  String get galleryBox;

  /// No description provided for @galleryTypicalDay.
  ///
  /// In en, this message translates to:
  /// **'Typical day'**
  String get galleryTypicalDay;

  /// No description provided for @todayAtTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Today at the track'**
  String get todayAtTrackTitle;

  /// No description provided for @todayAtTrackStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s status'**
  String get todayAtTrackStateLabel;

  /// No description provided for @todayAtTrackUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get todayAtTrackUpdatedLabel;

  /// No description provided for @signInForArrivalStatus.
  ///
  /// In en, this message translates to:
  /// **'Sign in to report your arrival and see your status for today.'**
  String get signInForArrivalStatus;

  /// No description provided for @noArrivalForToday.
  ///
  /// In en, this message translates to:
  /// **'You have not reported your arrival for today yet.'**
  String get noArrivalForToday;

  /// No description provided for @arrivalConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed: you\'re coming'**
  String get arrivalConfirmed;

  /// No description provided for @arrivalMaybe.
  ///
  /// In en, this message translates to:
  /// **'Marked as: maybe'**
  String get arrivalMaybe;

  /// No description provided for @arrivalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Arrival cancelled'**
  String get arrivalCancelled;

  /// No description provided for @arrivalStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Arrival status updated'**
  String get arrivalStatusUpdated;

  /// No description provided for @arrivalRegisteredAt.
  ///
  /// In en, this message translates to:
  /// **'Registered at {time}'**
  String arrivalRegisteredAt(Object time);

  /// No description provided for @arrivalValidForToday.
  ///
  /// In en, this message translates to:
  /// **'This attendance only applies to today and clears on the following day.'**
  String get arrivalValidForToday;

  /// No description provided for @loadingTodayArrival.
  ///
  /// In en, this message translates to:
  /// **'Checking today\'s arrival...'**
  String get loadingTodayArrival;

  /// No description provided for @arrivalReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read your arrival for today: {error}'**
  String arrivalReadError(Object error);

  /// No description provided for @arrivalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m coming'**
  String get arrivalSheetTitle;

  /// No description provided for @arrivalSheetBody.
  ///
  /// In en, this message translates to:
  /// **'First UI flow to confirm your arrival for {trackName}.'**
  String arrivalSheetBody(Object trackName);

  /// No description provided for @arrivalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get arrivalConfirmTitle;

  /// No description provided for @arrivalConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m planning to come.'**
  String get arrivalConfirmSubtitle;

  /// No description provided for @arrivalMaybeTitle.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get arrivalMaybeTitle;

  /// No description provided for @arrivalMaybeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I might stop by, but I\'m not sure yet.'**
  String get arrivalMaybeSubtitle;

  /// No description provided for @arrivalCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get arrivalCancelTitle;

  /// No description provided for @arrivalCancelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark that you are no longer coming today.'**
  String get arrivalCancelSubtitle;

  /// No description provided for @arrivalSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{selection} saved for today at {trackName}.'**
  String arrivalSavedMessage(Object selection, Object trackName);

  /// No description provided for @followTrackSaved.
  ///
  /// In en, this message translates to:
  /// **'{trackName} added to favorites.'**
  String followTrackSaved(Object trackName);

  /// No description provided for @followTrackRemoved.
  ///
  /// In en, this message translates to:
  /// **'{trackName} removed from favorites.'**
  String followTrackRemoved(Object trackName);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to PitLap'**
  String get loginTitle;

  /// No description provided for @loginBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a quick sign-in link to access PitLap.'**
  String get loginBody;

  /// No description provided for @loginExistingAccountHint.
  ///
  /// In en, this message translates to:
  /// **'If you already have an account, you will use the same access. If this is your first time, PitLap will prepare your basic profile.'**
  String get loginExistingAccountHint;

  /// No description provided for @loginAccountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Initial account type'**
  String get loginAccountTypeTitle;

  /// No description provided for @loginAccountTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to enter PitLap. You can complete and refine the profile later.'**
  String get loginAccountTypeBody;

  /// No description provided for @loginAccountTypeUser.
  ///
  /// In en, this message translates to:
  /// **'Modeler'**
  String get loginAccountTypeUser;

  /// No description provided for @loginAccountTypeShopOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get loginAccountTypeShopOwner;

  /// No description provided for @loginAccountTypeTrackOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Track organizer'**
  String get loginAccountTypeTrackOrganizer;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @loginSendLink.
  ///
  /// In en, this message translates to:
  /// **'Receive sign-in link'**
  String get loginSendLink;

  /// No description provided for @loginSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get loginSending;

  /// No description provided for @loginTermsConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service'**
  String get loginTermsConsentLabel;

  /// No description provided for @loginTermsConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Required to create or use a PitLap account.'**
  String get loginTermsConsentHint;

  /// No description provided for @loginPrivacyNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'I have read the Privacy Notice'**
  String get loginPrivacyNoticeLabel;

  /// No description provided for @loginPrivacyNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'Required to continue and understand how we process personal data.'**
  String get loginPrivacyNoticeHint;

  /// No description provided for @loginMarketingConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to receive marketing emails'**
  String get loginMarketingConsentLabel;

  /// No description provided for @loginMarketingConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Not required to use PitLap and can be withdrawn later.'**
  String get loginMarketingConsentHint;

  /// No description provided for @loginLegalDocsHint.
  ///
  /// In en, this message translates to:
  /// **'Base legal documents are now available in the project: Privacy Policy, Terms of Service, Cookie Policy and consent register.'**
  String get loginLegalDocsHint;

  /// No description provided for @loginRequiredConsentsError.
  ///
  /// In en, this message translates to:
  /// **'To continue, you must accept the Terms of Service and confirm that you have read the Privacy Notice.'**
  String get loginRequiredConsentsError;

  /// No description provided for @loginExpiredLinkError.
  ///
  /// In en, this message translates to:
  /// **'This sign-in link is no longer valid or has expired. Request a new one.'**
  String get loginExpiredLinkError;

  /// No description provided for @loginGenericAuthError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete sign-in. Please try again with a new link.'**
  String get loginGenericAuthError;

  /// No description provided for @loginRedirectHint.
  ///
  /// In en, this message translates to:
  /// **'After login you will return to {path}.'**
  String loginRedirectHint(Object path);

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get legalPrivacyTitle;

  /// No description provided for @legalPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Information on the processing of personal data pursuant to Arts. 13-14 of EU Regulation 2016/679 (GDPR).'**
  String get legalPrivacyDescription;

  /// No description provided for @legalPrivacySectionCollectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Collected data'**
  String get legalPrivacySectionCollectedTitle;

  /// No description provided for @legalPrivacySectionCollectedBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap processes account data (email address and user identifier), profile data (display name, language), preferences, saved tracks, daily track attendance, garage or public profile content made visible at the user\'s discretion, and minimal technical data required for security, authentication and correct service operation.'**
  String get legalPrivacySectionCollectedBody;

  /// No description provided for @legalPrivacySectionPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Purposes of processing'**
  String get legalPrivacySectionPurposeTitle;

  /// No description provided for @legalPrivacySectionPurposeBody.
  ///
  /// In en, this message translates to:
  /// **'Data is processed to: create and manage the account; provide secure access via magic link; save preferences (language, followed tracks); enable requested features such as track attendance; ensure technical security and prevent abuse; send service-related communications. Only with a separate and specific consent: send marketing communications by email.'**
  String get legalPrivacySectionPurposeBody;

  /// No description provided for @legalPrivacySectionLegalBasisTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal bases'**
  String get legalPrivacySectionLegalBasisTitle;

  /// No description provided for @legalPrivacySectionLegalBasisBody.
  ///
  /// In en, this message translates to:
  /// **'Contract performance (Art. 6(1)(b) GDPR): account management, authentication and essential features. Legitimate interest (Art. 6(1)(f) GDPR): technical security, abuse prevention and service integrity. Consent (Art. 6(1)(a) GDPR): marketing emails and other optional purposes. Legal obligation (Art. 6(1)(c) GDPR): compliance with applicable law where required.'**
  String get legalPrivacySectionLegalBasisBody;

  /// No description provided for @legalPrivacySectionRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Data subject rights'**
  String get legalPrivacySectionRightsTitle;

  /// No description provided for @legalPrivacySectionRightsBody.
  ///
  /// In en, this message translates to:
  /// **'Under Arts. 15-22 GDPR, users have the right to: access their personal data; obtain rectification or erasure; request restriction of processing; object to processing based on legitimate interest; receive data in a structured format (portability); withdraw consent at any time without affecting the lawfulness of prior processing. To exercise these rights: privacy@pitlap.app. Users may also lodge a complaint with the competent supervisory authority.'**
  String get legalPrivacySectionRightsBody;

  /// No description provided for @legalPrivacySectionControllerTitle.
  ///
  /// In en, this message translates to:
  /// **'Data controller'**
  String get legalPrivacySectionControllerTitle;

  /// No description provided for @legalPrivacySectionControllerBody.
  ///
  /// In en, this message translates to:
  /// **'The data controller is PitLap (pre-launch project). Full controller details will be provided before public launch. For any privacy-related enquiry: privacy@pitlap.app.'**
  String get legalPrivacySectionControllerBody;

  /// No description provided for @legalPrivacySectionProcessorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Processors and sub-processors'**
  String get legalPrivacySectionProcessorsTitle;

  /// No description provided for @legalPrivacySectionProcessorsBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap uses Supabase Inc. (USA) as provider for database, authentication and storage services, hosted on AWS infrastructure in the eu-west-2 region (Ireland). Data is physically stored within the European Union. Supabase acts as a data processor under Art. 28 GDPR; the Data Processing Agreement is available at supabase.com/privacy. No other third-party providers with access to users\' personal data are currently in use.'**
  String get legalPrivacySectionProcessorsBody;

  /// No description provided for @legalPrivacySectionTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'International transfers'**
  String get legalPrivacySectionTransfersTitle;

  /// No description provided for @legalPrivacySectionTransfersBody.
  ///
  /// In en, this message translates to:
  /// **'Data is stored on servers located in the EU (AWS eu-west-2, Ireland). Supabase Inc. is a US company: any transfer to the USA takes place under the safeguards required by the GDPR (Standard Contractual Clauses adopted by Supabase). No transfers to countries without an adequate level of data protection take place without the guarantees required by applicable law.'**
  String get legalPrivacySectionTransfersBody;

  /// No description provided for @legalPrivacySectionRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Retention periods'**
  String get legalPrivacySectionRetentionTitle;

  /// No description provided for @legalPrivacySectionRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'Account data is retained for the duration of the service relationship. Upon account deletion, personal data is erased within 30 days, unless retention is required by law. Track attendance records are automatically deleted after 1 day. Technical security logs are retained for a maximum of 90 days.'**
  String get legalPrivacySectionRetentionBody;

  /// No description provided for @legalPrivacySectionSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get legalPrivacySectionSecurityTitle;

  /// No description provided for @legalPrivacySectionSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap implements appropriate technical and organisational measures to protect data against unauthorised access, alteration or disclosure. Authentication relies on magic links (no password to store); data is transmitted over HTTPS; infrastructure services are subject to Supabase\'s security controls. In the event of a personal data breach, notification procedures under Arts. 33-34 GDPR will be applied.'**
  String get legalPrivacySectionSecurityBody;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsTitle;

  /// No description provided for @legalTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'Conditions governing the use of PitLap. By using the service, users accept these terms.'**
  String get legalTermsDescription;

  /// No description provided for @legalTermsSectionServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Service scope'**
  String get legalTermsSectionServiceTitle;

  /// No description provided for @legalTermsSectionServiceBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap is a platform to consult tracks, shops, events, profiles, garages and track attendance, with simplified access by email. Some areas may be made public only at the user\'s explicit choice and, depending on product rules, may be visible only to other authenticated users.'**
  String get legalTermsSectionServiceBody;

  /// No description provided for @legalTermsSectionUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Permitted use'**
  String get legalTermsSectionUseTitle;

  /// No description provided for @legalTermsSectionUseBody.
  ///
  /// In en, this message translates to:
  /// **'Users agree to use the service lawfully and respectfully, providing accurate data and avoiding abuse of community, profile, garage or attendance features. The following are prohibited: using the service for unlawful purposes, harassing other users, spreading false or misleading content, attempting unauthorised access. PitLap reserves the right to suspend or remove accounts that violate these terms.'**
  String get legalTermsSectionUseBody;

  /// No description provided for @legalTermsSectionContentTitle.
  ///
  /// In en, this message translates to:
  /// **'User content'**
  String get legalTermsSectionContentTitle;

  /// No description provided for @legalTermsSectionContentBody.
  ///
  /// In en, this message translates to:
  /// **'Users are responsible for the content they upload (text, images, builds) and for holding the rights required for its publication. By uploading content, users grant PitLap a non-exclusive licence to display it within the service according to the chosen visibility settings. PitLap may restrict or remove unlawful, misleading, harmful or incompatible material without prior notice.'**
  String get legalTermsSectionContentBody;

  /// No description provided for @legalTermsSectionAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability and moderation'**
  String get legalTermsSectionAvailabilityTitle;

  /// No description provided for @legalTermsSectionAvailabilityBody.
  ///
  /// In en, this message translates to:
  /// **'The service is provided \'as is\' and may evolve, change or face temporary interruptions. Information about tracks, events, shops, services or attendance may depend on data entered by users, managers or third parties; PitLap does not guarantee that it is always complete, up to date or error-free.'**
  String get legalTermsSectionAvailabilityBody;

  /// No description provided for @legalTermsSectionIPTitle.
  ///
  /// In en, this message translates to:
  /// **'Intellectual property'**
  String get legalTermsSectionIPTitle;

  /// No description provided for @legalTermsSectionIPBody.
  ///
  /// In en, this message translates to:
  /// **'The PitLap brand, design, code and content produced by the team are the exclusive property of the owner or respective authors. Unauthorised reproduction, distribution or commercial use is prohibited. Content submitted by users remains the property of its respective authors; PitLap holds only the licence strictly necessary for service operation.'**
  String get legalTermsSectionIPBody;

  /// No description provided for @legalTermsSectionLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitation of liability'**
  String get legalTermsSectionLiabilityTitle;

  /// No description provided for @legalTermsSectionLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'To the extent permitted by law, PitLap is not liable for direct or indirect damages arising from use of or inability to use the service, errors in information provided by users or third parties, service interruptions, or unauthorised access due to events beyond PitLap\'s reasonable control. This limitation does not apply in cases of wilful misconduct or gross negligence.'**
  String get legalTermsSectionLiabilityBody;

  /// No description provided for @legalTermsSectionGoverningTitle.
  ///
  /// In en, this message translates to:
  /// **'Governing law and jurisdiction'**
  String get legalTermsSectionGoverningTitle;

  /// No description provided for @legalTermsSectionGoverningBody.
  ///
  /// In en, this message translates to:
  /// **'These terms are governed by Italian law. For any dispute relating to the use of the service, and where permitted by applicable law, the exclusive jurisdiction shall be that of the court of the user-consumer\'s place of residence or domicile. For professional users, the exclusive forum will be specified in dedicated service conditions.'**
  String get legalTermsSectionGoverningBody;

  /// No description provided for @legalCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get legalCookiesTitle;

  /// No description provided for @legalCookiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Information on the use of cookies and equivalent technologies on the PitLap website.'**
  String get legalCookiesDescription;

  /// No description provided for @legalCookiesSectionWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What are cookies'**
  String get legalCookiesSectionWhatTitle;

  /// No description provided for @legalCookiesSectionWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Cookies are small text files that websites save on a user\'s device during browsing. They are used to make pages work correctly, remember preferences and, in some cases, collect statistical or profiling data. In addition to traditional cookies, this policy applies to equivalent technologies such as session tokens, local identifiers and web storage.'**
  String get legalCookiesSectionWhatBody;

  /// No description provided for @legalCookiesSectionTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical and session cookies'**
  String get legalCookiesSectionTechnicalTitle;

  /// No description provided for @legalCookiesSectionTechnicalBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap uses only technical cookies strictly necessary for service operation: authentication tokens (user session after magic link login), language preferences and interface settings. These cookies do not require user consent under applicable EU law.'**
  String get legalCookiesSectionTechnicalBody;

  /// No description provided for @legalCookiesSectionAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics cookies'**
  String get legalCookiesSectionAnalyticsTitle;

  /// No description provided for @legalCookiesSectionAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap does not currently install third-party analytics cookies. Should analytics tools be introduced in the future, this policy will be updated with details of the tools, data collected, purposes and how to give or withdraw consent.'**
  String get legalCookiesSectionAnalyticsBody;

  /// No description provided for @legalCookiesSectionMarketingTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketing and profiling cookies'**
  String get legalCookiesSectionMarketingTitle;

  /// No description provided for @legalCookiesSectionMarketingBody.
  ///
  /// In en, this message translates to:
  /// **'PitLap does not install marketing or profiling cookies. Should they be introduced, they will be preceded by an explicit, specific and freely revocable consent request, in accordance with applicable law.'**
  String get legalCookiesSectionMarketingBody;

  /// No description provided for @legalCookiesSectionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Managing preferences'**
  String get legalCookiesSectionStatusTitle;

  /// No description provided for @legalCookiesSectionStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Since PitLap uses only necessary technical cookies, no mandatory consent banner is required. Users may nevertheless delete stored cookies via their browser or device settings. Removing technical cookies may prevent the service from working correctly (e.g. keeping the login session active).'**
  String get legalCookiesSectionStatusBody;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent. Check your email.'**
  String get magicLinkSent;

  /// No description provided for @nearbyDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover open tracks, useful shops and nearby events with a quick, grounded read of what is happening around you.'**
  String get nearbyDescription;

  /// No description provided for @nearbyPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Mixed discovery'**
  String get nearbyPlaceholderTitle;

  /// No description provided for @nearbyPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This screen will host a distance-sorted list, basic filters and a secondary map view.'**
  String get nearbyPlaceholderBody;

  /// No description provided for @nearbyHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where to go with less friction'**
  String get nearbyHeroTitle;

  /// No description provided for @nearbyHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Geolocation should support the decision, not complicate it: useful list first, map only when it really helps.'**
  String get nearbyHeroBody;

  /// No description provided for @nearbyFlagTracks.
  ///
  /// In en, this message translates to:
  /// **'Nearby tracks'**
  String get nearbyFlagTracks;

  /// No description provided for @nearbyFlagShops.
  ///
  /// In en, this message translates to:
  /// **'Useful shops'**
  String get nearbyFlagShops;

  /// No description provided for @nearbyFlagOutdoorFirst.
  ///
  /// In en, this message translates to:
  /// **'Outdoor and indoor'**
  String get nearbyFlagOutdoorFirst;

  /// No description provided for @nearbyHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How it should work'**
  String get nearbyHowItWorksTitle;

  /// No description provided for @nearbyStepOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Location or city'**
  String get nearbyStepOneTitle;

  /// No description provided for @nearbyStepOneBody.
  ///
  /// In en, this message translates to:
  /// **'Start from current location or a user-selected city, without forcing the map into the main flow.'**
  String get nearbyStepOneBody;

  /// No description provided for @nearbyStepTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'List before map'**
  String get nearbyStepTwoTitle;

  /// No description provided for @nearbyStepTwoBody.
  ///
  /// In en, this message translates to:
  /// **'Users should immediately see useful tracks and shops, sorted by distance and context.'**
  String get nearbyStepTwoBody;

  /// No description provided for @nearbyStepThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast decision'**
  String get nearbyStepThreeTitle;

  /// No description provided for @nearbyStepThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Track status, services and specialization should explain in seconds where it makes sense to go.'**
  String get nearbyStepThreeBody;

  /// No description provided for @nearbyPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Close to you now'**
  String get nearbyPreviewTitle;

  /// No description provided for @nearbyPreviewTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Offroad Parma'**
  String get nearbyPreviewTrackTitle;

  /// No description provided for @nearbyPreviewTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outdoor track · 9 km'**
  String get nearbyPreviewTrackSubtitle;

  /// No description provided for @nearbyPreviewTrackBadge.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get nearbyPreviewTrackBadge;

  /// No description provided for @nearbyPreviewTrackNote.
  ///
  /// In en, this message translates to:
  /// **'Dry surface, key services available, solid choice for today\'s session.'**
  String get nearbyPreviewTrackNote;

  /// No description provided for @nearbyPreviewShopTitle.
  ///
  /// In en, this message translates to:
  /// **'RC Parts Parma'**
  String get nearbyPreviewShopTitle;

  /// No description provided for @nearbyPreviewShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop · 11 km'**
  String get nearbyPreviewShopSubtitle;

  /// No description provided for @nearbyPreviewShopBadge.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get nearbyPreviewShopBadge;

  /// No description provided for @nearbyPreviewShopNote.
  ///
  /// In en, this message translates to:
  /// **'Parts and pit support if you need something before heading to the track.'**
  String get nearbyPreviewShopNote;

  /// No description provided for @eventsDescription.
  ///
  /// In en, this message translates to:
  /// **'All PitLap events'**
  String get eventsDescription;

  /// No description provided for @eventsPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'MVP events'**
  String get eventsPlaceholderTitle;

  /// No description provided for @eventsPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Events will stay lightweight: list, basic detail and simple RSVP where needed.'**
  String get eventsPlaceholderBody;

  /// No description provided for @eventsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'See what is happening at the track'**
  String get eventsHeroTitle;

  /// No description provided for @eventsHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Races, open practice, demos and community meetups collected in a calendar that is easy to browse and ready to share.'**
  String get eventsHeroBody;

  /// No description provided for @eventsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Example event cards'**
  String get eventsPreviewTitle;

  /// No description provided for @eventsDemoOneDate.
  ///
  /// In en, this message translates to:
  /// **'Sat 9 Apr'**
  String get eventsDemoOneDate;

  /// No description provided for @eventsDemoOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening open practice'**
  String get eventsDemoOneTitle;

  /// No description provided for @eventsDemoOneLocation.
  ///
  /// In en, this message translates to:
  /// **'MiniZ Hub Modena'**
  String get eventsDemoOneLocation;

  /// No description provided for @eventsDemoOneNote.
  ///
  /// In en, this message translates to:
  /// **'Informal indoor session focused on tire testing and setup work.'**
  String get eventsDemoOneNote;

  /// No description provided for @eventsDemoTwoDate.
  ///
  /// In en, this message translates to:
  /// **'Sun 17 Apr'**
  String get eventsDemoTwoDate;

  /// No description provided for @eventsDemoTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Offroad club day'**
  String get eventsDemoTwoTitle;

  /// No description provided for @eventsDemoTwoLocation.
  ///
  /// In en, this message translates to:
  /// **'Offroad Parma'**
  String get eventsDemoTwoLocation;

  /// No description provided for @eventsDemoTwoNote.
  ///
  /// In en, this message translates to:
  /// **'Long opening day with expected drivers and active pit area.'**
  String get eventsDemoTwoNote;

  /// No description provided for @eventsBadgePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get eventsBadgePractice;

  /// No description provided for @eventsBadgeRace.
  ///
  /// In en, this message translates to:
  /// **'Club day'**
  String get eventsBadgeRace;

  /// No description provided for @eventsDirectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended direction'**
  String get eventsDirectionTitle;

  /// No description provided for @eventsDirectionBody.
  ///
  /// In en, this message translates to:
  /// **'Start with a clean list showing date, track and context. Richer RSVP and detailed flows should come later, only if truly useful.'**
  String get eventsDirectionBody;

  /// No description provided for @eventsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Event detail'**
  String get eventsDetailTitle;

  /// No description provided for @eventsDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Reference view for reading an event without losing the context of the day.'**
  String get eventsDetailDescription;

  /// No description provided for @eventsDetailOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Event overview'**
  String get eventsDetailOverviewTitle;

  /// No description provided for @eventsDetailTrackContext.
  ///
  /// In en, this message translates to:
  /// **'Track context'**
  String get eventsDetailTrackContext;

  /// No description provided for @eventsDetailCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get eventsDetailCommunity;

  /// No description provided for @eventsDetailLightRsvp.
  ///
  /// In en, this message translates to:
  /// **'Light RSVP'**
  String get eventsDetailLightRsvp;

  /// No description provided for @garageDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal area for models, photos and optional public visibility.'**
  String get garageDescription;

  /// No description provided for @garagePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal garage'**
  String get garagePlaceholderTitle;

  /// No description provided for @garagePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This area will host model lists, images, notes and visibility controls.'**
  String get garagePlaceholderBody;

  /// No description provided for @garageHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your featured builds'**
  String get garageHeroTitle;

  /// No description provided for @garageHeroBody.
  ///
  /// In en, this message translates to:
  /// **'A personal showcase for your models, with photos, light technical details and optional public visibility.'**
  String get garageHeroBody;

  /// No description provided for @garageVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get garageVisibilityPrivate;

  /// No description provided for @garageVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Make it public'**
  String get garageVisibilityPublic;

  /// No description provided for @garageBuildsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent builds'**
  String get garageBuildsTitle;

  /// No description provided for @garageBuildsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} showcase models'**
  String garageBuildsCount(Object count);

  /// No description provided for @garageVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Garage visibility'**
  String get garageVisibilityTitle;

  /// No description provided for @garageVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'The garage starts private, but each build can become public whenever the user wants to show it.'**
  String get garageVisibilityBody;

  /// No description provided for @garageTogglePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get garageTogglePrivate;

  /// No description provided for @garageTogglePublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get garageTogglePublic;

  /// No description provided for @garageBuildVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Build visibility'**
  String get garageBuildVisibilityTitle;

  /// No description provided for @garageBuildVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'Each model can have its own visibility, so the user decides what stays personal and what gets shown to others.'**
  String get garageBuildVisibilityBody;

  /// No description provided for @garageBuildVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private build'**
  String get garageBuildVisibilityPrivate;

  /// No description provided for @garageBuildVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public build'**
  String get garageBuildVisibilityPublic;

  /// No description provided for @garageBuildOneName.
  ///
  /// In en, this message translates to:
  /// **'XB8 nitro'**
  String get garageBuildOneName;

  /// No description provided for @garageBuildOneMeta.
  ///
  /// In en, this message translates to:
  /// **'1/8 buggy · dirt setup'**
  String get garageBuildOneMeta;

  /// No description provided for @garageBuildTwoName.
  ///
  /// In en, this message translates to:
  /// **'Mini-Z MR-03'**
  String get garageBuildTwoName;

  /// No description provided for @garageBuildTwoMeta.
  ///
  /// In en, this message translates to:
  /// **'Mini-Z · indoor setup'**
  String get garageBuildTwoMeta;

  /// No description provided for @garageBuildThreeName.
  ///
  /// In en, this message translates to:
  /// **'Crawler TRX-4'**
  String get garageBuildThreeName;

  /// No description provided for @garageBuildThreeMeta.
  ///
  /// In en, this message translates to:
  /// **'Scaler · weekend trail'**
  String get garageBuildThreeMeta;

  /// No description provided for @garagePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String garagePhotoCount(Object count);

  /// No description provided for @garageSpecMotor.
  ///
  /// In en, this message translates to:
  /// **'Motor'**
  String get garageSpecMotor;

  /// No description provided for @garageSpecBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get garageSpecBattery;

  /// No description provided for @garageSpecSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get garageSpecSurface;

  /// No description provided for @garageNextStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended direction'**
  String get garageNextStepTitle;

  /// No description provided for @garageNextStepBody.
  ///
  /// In en, this message translates to:
  /// **'Start with a private garage holding 3-5 builds, cover photos, quick notes and a public toggle for each build.'**
  String get garageNextStepBody;

  /// No description provided for @managerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Track management'**
  String get managerScreenTitle;

  /// No description provided for @managerDescription.
  ///
  /// In en, this message translates to:
  /// **'Owner/manager area for track status, services and key data.'**
  String get managerDescription;

  /// No description provided for @managerPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager panel'**
  String get managerPlaceholderTitle;

  /// No description provided for @managerPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Status updates, quick messages, services and basic event management will arrive here.'**
  String get managerPlaceholderBody;

  /// No description provided for @managerHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Few tools, very clear'**
  String get managerHeroTitle;

  /// No description provided for @managerHeroBody.
  ///
  /// In en, this message translates to:
  /// **'The manager panel should enable quick and reliable updates, without turning club owners into backoffice operators.'**
  String get managerHeroBody;

  /// No description provided for @managerTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Main operations'**
  String get managerTodayTitle;

  /// No description provided for @managerActionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Update track status'**
  String get managerActionStatusTitle;

  /// No description provided for @managerActionStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Quickly change status, message and visibility of the update.'**
  String get managerActionStatusBody;

  /// No description provided for @managerActionServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services and availability'**
  String get managerActionServicesTitle;

  /// No description provided for @managerActionServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm useful services, pit conditions and small operational details.'**
  String get managerActionServicesBody;

  /// No description provided for @managerActionEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events and special days'**
  String get managerActionEventsTitle;

  /// No description provided for @managerActionEventsBody.
  ///
  /// In en, this message translates to:
  /// **'Publish practice sessions, races or special openings with minimal friction.'**
  String get managerActionEventsBody;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Central control panel for categories, users, tracks, shops and monitoring.'**
  String get adminDescription;

  /// No description provided for @adminHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'PitLap control center'**
  String get adminHeroTitle;

  /// No description provided for @adminHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Administrative area to manage catalog, roles, taxonomies, moderation and operational monitoring without relying on manual SQL queries.'**
  String get adminHeroBody;

  /// No description provided for @adminAccessDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'This area is reserved for administrator accounts. The real role model will be used to enable or block sensitive tools.'**
  String get adminAccessDeniedBody;

  /// No description provided for @adminAccessDeniedCard.
  ///
  /// In en, this message translates to:
  /// **'If you are not an admin you can still see that this area exists, but the real actions stay protected. Once ownership is more mature, access will also be enforced on the backend.'**
  String get adminAccessDeniedCard;

  /// No description provided for @adminUsersChip.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersChip;

  /// No description provided for @adminTracksChip.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get adminTracksChip;

  /// No description provided for @adminShopsChip.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get adminShopsChip;

  /// No description provided for @adminModerationChip.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get adminModerationChip;

  /// No description provided for @adminOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational overview'**
  String get adminOverviewTitle;

  /// No description provided for @adminOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Compact view of the key entities the real admin dashboard will need to monitor.'**
  String get adminOverviewBody;

  /// No description provided for @adminUsersMetric.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersMetric;

  /// No description provided for @adminTracksMetric.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get adminTracksMetric;

  /// No description provided for @adminShopsMetric.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get adminShopsMetric;

  /// No description provided for @adminEventsMetric.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get adminEventsMetric;

  /// No description provided for @adminCategoriesMetric.
  ///
  /// In en, this message translates to:
  /// **'Track categories'**
  String get adminCategoriesMetric;

  /// No description provided for @adminOverviewFallback.
  ///
  /// In en, this message translates to:
  /// **'Real metrics are not available yet in this instance.'**
  String get adminOverviewFallback;

  /// No description provided for @adminCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories and taxonomies'**
  String get adminCategoriesTitle;

  /// No description provided for @adminCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'First draft of the configurator to expand hobbies and track labels without touching SQL by hand.'**
  String get adminCategoriesBody;

  /// No description provided for @adminHobbyCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hobby categories'**
  String get adminHobbyCategoriesTitle;

  /// No description provided for @adminHobbyCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'Local draft used to validate the structure and tone of the hobby configurator before the final database model.'**
  String get adminHobbyCategoriesBody;

  /// No description provided for @adminTrackLabelCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Track label categories'**
  String get adminTrackLabelCategoriesTitle;

  /// No description provided for @adminTrackCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'This section is connected to the real track categories stored in the database when the remote schema is aligned.'**
  String get adminTrackCategoriesBody;

  /// No description provided for @adminAddHobbyCategory.
  ///
  /// In en, this message translates to:
  /// **'New hobby category'**
  String get adminAddHobbyCategory;

  /// No description provided for @adminAddTrackLabelCategory.
  ///
  /// In en, this message translates to:
  /// **'New track label category'**
  String get adminAddTrackLabelCategory;

  /// No description provided for @adminAddGenericAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAddGenericAction;

  /// No description provided for @adminTrackCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No track categories available.'**
  String get adminTrackCategoriesEmpty;

  /// No description provided for @adminTrackCategoriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Track categories are not available from this instance yet.'**
  String get adminTrackCategoriesUnavailable;

  /// No description provided for @adminCategorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved.'**
  String get adminCategorySaved;

  /// No description provided for @adminCategoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category removed.'**
  String get adminCategoryDeleted;

  /// No description provided for @adminCategorySaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save category: {error}'**
  String adminCategorySaveError(Object error);

  /// No description provided for @adminCategoryDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove category: {error}'**
  String adminCategoryDeleteError(Object error);

  /// No description provided for @adminEntitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Managed entities'**
  String get adminEntitiesTitle;

  /// No description provided for @adminEntitiesBody.
  ///
  /// In en, this message translates to:
  /// **'Blocks that will evolve into dedicated panels for users, tracks, shops, media and moderation.'**
  String get adminEntitiesBody;

  /// No description provided for @adminShopsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get adminShopsCardTitle;

  /// No description provided for @adminShopsCardBody.
  ///
  /// In en, this message translates to:
  /// **'Create, edit, deactivate and connect shops to tracks or owners.'**
  String get adminShopsCardBody;

  /// No description provided for @adminTracksCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get adminTracksCardTitle;

  /// No description provided for @adminTracksCardBody.
  ///
  /// In en, this message translates to:
  /// **'Manage track records, ownership, services, labels and media.'**
  String get adminTracksCardBody;

  /// No description provided for @adminUsersCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersCardTitle;

  /// No description provided for @adminUsersCardBody.
  ///
  /// In en, this message translates to:
  /// **'Inspect profiles, roles, garages, events and overall account state.'**
  String get adminUsersCardBody;

  /// No description provided for @adminMonitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard and monitoring'**
  String get adminMonitoringTitle;

  /// No description provided for @adminMonitoringBody.
  ///
  /// In en, this message translates to:
  /// **'Space for the data the admin will actually need: volume, funnel, moderation, media and visited pages.'**
  String get adminMonitoringBody;

  /// No description provided for @adminVisitedPagesMetric.
  ///
  /// In en, this message translates to:
  /// **'Visited pages'**
  String get adminVisitedPagesMetric;

  /// No description provided for @adminVisitedPagesPending.
  ///
  /// In en, this message translates to:
  /// **'To connect'**
  String get adminVisitedPagesPending;

  /// No description provided for @adminCompletedLoginsMetric.
  ///
  /// In en, this message translates to:
  /// **'Completed logins'**
  String get adminCompletedLoginsMetric;

  /// No description provided for @adminModerationQueueMetric.
  ///
  /// In en, this message translates to:
  /// **'Media to moderate'**
  String get adminModerationQueueMetric;

  /// No description provided for @adminOpenReportsMetric.
  ///
  /// In en, this message translates to:
  /// **'Open reports'**
  String get adminOpenReportsMetric;

  /// No description provided for @adminUsersPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent users'**
  String get adminUsersPreviewTitle;

  /// No description provided for @adminUsersPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'First compact look at the active user catalog in this instance.'**
  String get adminUsersPreviewBody;

  /// No description provided for @adminUsersPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users available.'**
  String get adminUsersPreviewEmpty;

  /// No description provided for @adminUsersPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'User preview is not available right now.'**
  String get adminUsersPreviewUnavailable;

  /// No description provided for @adminImpersonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Impersonate role'**
  String get adminImpersonationTitle;

  /// No description provided for @adminImpersonationBody.
  ///
  /// In en, this message translates to:
  /// **'Local testing tool to simulate permissions behavior without actually changing your account in the database.'**
  String get adminImpersonationBody;

  /// No description provided for @adminImpersonationInactive.
  ///
  /// In en, this message translates to:
  /// **'You are using your real role.'**
  String get adminImpersonationInactive;

  /// No description provided for @adminImpersonationActive.
  ///
  /// In en, this message translates to:
  /// **'You are testing the app as {role}.'**
  String adminImpersonationActive(Object role);

  /// No description provided for @adminImpersonationBanner.
  ///
  /// In en, this message translates to:
  /// **'Impersonation active: you are using role {role} for UI testing.'**
  String adminImpersonationBanner(Object role);

  /// No description provided for @adminImpersonationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get adminImpersonationStop;

  /// No description provided for @adminRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminRoleUser;

  /// No description provided for @adminRoleShopOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop owner'**
  String get adminRoleShopOwner;

  /// No description provided for @adminRoleTrackOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Track organizer'**
  String get adminRoleTrackOrganizer;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Real admin'**
  String get adminRoleAdmin;

  /// No description provided for @managerGovernanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Governance principle'**
  String get managerGovernanceTitle;

  /// No description provided for @managerGovernanceBody.
  ///
  /// In en, this message translates to:
  /// **'The manager area should stay sober, fast and traceable. Every update should improve user trust, not add operational overhead for the club.'**
  String get managerGovernanceBody;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'Driver profile with preferences, privacy and garage connection.'**
  String get profileDescription;

  /// No description provided for @profilePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal profile'**
  String get profilePlaceholderTitle;

  /// No description provided for @profilePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll configure language, identity, avatar and public profile visibility here.'**
  String get profilePlaceholderBody;

  /// No description provided for @profileIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile identity'**
  String get profileIdentityTitle;

  /// No description provided for @profileIdentityBody.
  ///
  /// In en, this message translates to:
  /// **'A sober account foundation, useful for discovery, garage and future relationships without forcing invasive social patterns.'**
  String get profileIdentityBody;

  /// No description provided for @profileFieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFieldFirstName;

  /// No description provided for @profileFieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profileFieldLastName;

  /// No description provided for @profileFieldNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileFieldNickname;

  /// No description provided for @profileFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileFieldLocation;

  /// No description provided for @profileFieldYearsInHobby.
  ///
  /// In en, this message translates to:
  /// **'Years in the hobby'**
  String get profileFieldYearsInHobby;

  /// No description provided for @profileVisibleName.
  ///
  /// In en, this message translates to:
  /// **'Visible name'**
  String get profileVisibleName;

  /// No description provided for @profileCurrentEmail.
  ///
  /// In en, this message translates to:
  /// **'Current email'**
  String get profileCurrentEmail;

  /// No description provided for @profilePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get profilePreferredLanguage;

  /// No description provided for @profileAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get profileAccountStatus;

  /// No description provided for @profileAccountStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileAccountStatusActive;

  /// No description provided for @profileAccountStatusGuest.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profileAccountStatusGuest;

  /// No description provided for @profileAccountSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Account snapshot'**
  String get profileAccountSnapshotTitle;

  /// No description provided for @profileAccountSnapshotBody.
  ///
  /// In en, this message translates to:
  /// **'A quick account overview before opening more sensitive actions.'**
  String get profileAccountSnapshotBody;

  /// No description provided for @profileEditBasics.
  ///
  /// In en, this message translates to:
  /// **'Edit basics'**
  String get profileEditBasics;

  /// No description provided for @profileSaveBasics.
  ///
  /// In en, this message translates to:
  /// **'Save basics'**
  String get profileSaveBasics;

  /// No description provided for @profileCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get profileCancelEdit;

  /// No description provided for @profileSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Basic profile details saved.'**
  String get profileSavedMessage;

  /// No description provided for @profileEditHint.
  ///
  /// In en, this message translates to:
  /// **'In this first step you can save visible name and preferred language. The other fields will arrive through onboarding.'**
  String get profileEditHint;

  /// No description provided for @profileEditableFieldsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'First name, last name, nickname, location and years in the hobby will be collected and saved in the next onboarding step.'**
  String get profileEditableFieldsComingSoon;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'No active email'**
  String get profileNotSignedIn;

  /// No description provided for @profileSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get profileSignedIn;

  /// No description provided for @profileSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get profileSignedOut;

  /// No description provided for @profileHobbiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hobbies and interests'**
  String get profileHobbiesTitle;

  /// No description provided for @profileHobbyDrones.
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get profileHobbyDrones;

  /// No description provided for @profileHobbyTrains.
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get profileHobbyTrains;

  /// No description provided for @profilePreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'These preferences will support discovery, shops, suggestions and future badges.'**
  String get profilePreferencesHint;

  /// No description provided for @profilePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and visibility'**
  String get profilePrivacyTitle;

  /// No description provided for @profilePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Private by default, with an optional public profile only if the user wants to show up.'**
  String get profilePrivacyBody;

  /// No description provided for @profileTogglePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get profileTogglePrivate;

  /// No description provided for @profileTogglePublic.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get profileTogglePublic;

  /// No description provided for @profileGarageVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Garage visibility'**
  String get profileGarageVisibilityTitle;

  /// No description provided for @profileGarageVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'The garage can stay fully private or open up selectively, one build at a time.'**
  String get profileGarageVisibilityBody;

  /// No description provided for @profileConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consents and documents'**
  String get profileConsentTitle;

  /// No description provided for @profileConsentTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get profileConsentTerms;

  /// No description provided for @profileConsentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get profileConsentPrivacy;

  /// No description provided for @profileConsentMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing email'**
  String get profileConsentMarketing;

  /// No description provided for @profileConsentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get profileConsentAccepted;

  /// No description provided for @profileConsentNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get profileConsentNotAccepted;

  /// No description provided for @profileConsentLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking consents...'**
  String get profileConsentLoading;

  /// No description provided for @profileConsentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Consent data is not available in this session yet.'**
  String get profileConsentUnavailable;

  /// No description provided for @profileConsentVersion.
  ///
  /// In en, this message translates to:
  /// **'Recorded document version: {version}'**
  String profileConsentVersion(Object version);

  /// No description provided for @profileConsentUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated on {value}'**
  String profileConsentUpdatedAt(Object value);

  /// No description provided for @profileConsentSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String profileConsentSource(Object source);

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Sensitive account operations should live here, separate from the public-facing profile data.'**
  String get profileSettingsBody;

  /// No description provided for @profileChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get profileChangeEmail;

  /// No description provided for @profileChangeEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Guided flow with confirmation on the new email address.'**
  String get profileChangeEmailHint;

  /// No description provided for @profileChangeEmailInfo.
  ///
  /// In en, this message translates to:
  /// **'Email change will be connected to a dedicated verified flow with minimal audit.'**
  String get profileChangeEmailInfo;

  /// No description provided for @profileResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get profileResetPassword;

  /// No description provided for @profileResetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Useful for recovery flows when quick sign-in is not enough.'**
  String get profileResetPasswordHint;

  /// No description provided for @profileResetPasswordInfo.
  ///
  /// In en, this message translates to:
  /// **'We will shape this as a secure standalone flow, separate from quick sign-in.'**
  String get profileResetPasswordInfo;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'Closes the session on this browser without touching profile data.'**
  String get profileSignOutHint;

  /// No description provided for @profileSignedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out successfully.'**
  String get profileSignedOutMessage;

  /// No description provided for @profileCloseAccount.
  ///
  /// In en, this message translates to:
  /// **'Close profile'**
  String get profileCloseAccount;

  /// No description provided for @profileCloseAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Delicate action to protect with explicit confirmation.'**
  String get profileCloseAccountHint;

  /// No description provided for @profileCloseAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account closure will require a dedicated flow with data summary, export and final confirmation.'**
  String get profileCloseAccountInfo;

  /// No description provided for @profileSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Initial proposal'**
  String get profileSummaryTitle;

  /// No description provided for @profileSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Collect first name, last name, nickname, location, years in RC/modeling, main hobbies, preferred language and garage connection.'**
  String get profileSummaryBody;

  /// No description provided for @profileOnboardingAction.
  ///
  /// In en, this message translates to:
  /// **'Open onboarding'**
  String get profileOnboardingAction;

  /// No description provided for @profileOnboardingActionHint.
  ///
  /// In en, this message translates to:
  /// **'Draft of the guided first access flow to decide what should be asked immediately.'**
  String get profileOnboardingActionHint;

  /// No description provided for @profileFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileFavoritesTitle;

  /// No description provided for @profileFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Personal hub for followed tracks, saved builds, useful shops and other relevant content.'**
  String get profileFavoritesBody;

  /// No description provided for @profileFavoriteTracks.
  ///
  /// In en, this message translates to:
  /// **'Saved tracks'**
  String get profileFavoriteTracks;

  /// No description provided for @profileFavoriteBuilds.
  ///
  /// In en, this message translates to:
  /// **'Saved builds'**
  String get profileFavoriteBuilds;

  /// No description provided for @profileFavoriteShops.
  ///
  /// In en, this message translates to:
  /// **'Saved shops'**
  String get profileFavoriteShops;

  /// No description provided for @profileCreatedEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Created events'**
  String get profileCreatedEventsTitle;

  /// No description provided for @profileLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital library'**
  String get profileLibraryTitle;

  /// No description provided for @profileLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'A growing collection of the content that matters to your journey: favorites, events and personal history.'**
  String get profileLibraryBody;

  /// No description provided for @entitySavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String entitySavedCount(Object count);

  /// No description provided for @profileFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'This section will become the cross-product favorites hub, not just a list of tracks.'**
  String get profileFavoritesHint;

  /// No description provided for @profileFavoriteTracksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved tracks yet.'**
  String get profileFavoriteTracksEmpty;

  /// No description provided for @profileFavoriteBuildsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved builds yet.'**
  String get profileFavoriteBuildsEmpty;

  /// No description provided for @profileFavoriteShopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved shops yet.'**
  String get profileFavoriteShopsEmpty;

  /// No description provided for @profileCreatedEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No created events yet.'**
  String get profileCreatedEventsEmpty;

  /// No description provided for @profileArchivedEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No past events available.'**
  String get profileArchivedEventsEmpty;

  /// No description provided for @publicProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfileTitle;

  /// No description provided for @publicProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Public driver profile for {slug}'**
  String publicProfileDescription(Object slug);

  /// No description provided for @publicProfilePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Opt-in profile'**
  String get publicProfilePlaceholderTitle;

  /// No description provided for @publicProfilePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'The public profile will always stay optional and separate from private account data.'**
  String get publicProfilePlaceholderBody;

  /// No description provided for @shopDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop detail'**
  String get shopDetailTitle;

  /// No description provided for @shopDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'{shopName}'**
  String shopDetailDescription(Object shopName);

  /// No description provided for @shopPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopPlaceholderTitle;

  /// No description provided for @shopPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Identity, distance, main categories and essential contacts will live here.'**
  String get shopPlaceholderBody;

  /// No description provided for @shopsDescription.
  ///
  /// In en, this message translates to:
  /// **'Find the nearest shop and discover useful specializations.'**
  String get shopsDescription;

  /// No description provided for @shopDemoName.
  ///
  /// In en, this message translates to:
  /// **'RC Parts Parma'**
  String get shopDemoName;

  /// No description provided for @shopDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spare parts, electronics, pit support'**
  String get shopDemoSubtitle;

  /// No description provided for @shopSecondaryName.
  ///
  /// In en, this message translates to:
  /// **'Mini Garage Modena'**
  String get shopSecondaryName;

  /// No description provided for @shopSecondarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mini-Z, tires, indoor setup'**
  String get shopSecondarySubtitle;

  /// No description provided for @shopDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String shopDistance(Object distance);

  /// No description provided for @shopOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get shopOpenNow;

  /// No description provided for @shopCallButton.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get shopCallButton;

  /// No description provided for @shopDirectionsButton.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get shopDirectionsButton;

  /// No description provided for @shopDetailHeroBody.
  ///
  /// In en, this message translates to:
  /// **'A practical sheet to quickly find specialties, useful services, contacts and everything you need before stopping by the shop.'**
  String get shopDetailHeroBody;

  /// No description provided for @shopSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get shopSpecialtiesTitle;

  /// No description provided for @shopServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'In-store services'**
  String get shopServicesTitle;

  /// No description provided for @shopHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get shopHoursTitle;

  /// No description provided for @shopContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get shopContactsTitle;

  /// No description provided for @shopNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get shopNotesTitle;

  /// No description provided for @shopNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the context clean and professional: no promo noise, only clear and reliable information for hobby users.'**
  String get shopNotesBody;

  /// No description provided for @shopEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get shopEditAction;

  /// No description provided for @shopEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Close edit'**
  String get shopEditCancel;

  /// No description provided for @shopEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get shopEditSave;

  /// No description provided for @shopEditSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Shop changes saved to the database.'**
  String get shopEditSavedMessage;

  /// No description provided for @shopEditNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopEditNameLabel;

  /// No description provided for @shopEditSubtitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get shopEditSubtitleLabel;

  /// No description provided for @shopEditImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image (URL)'**
  String get shopEditImageUrlLabel;

  /// No description provided for @shopImageUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get shopImageUploadAction;

  /// No description provided for @shopGalleryUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Add gallery images'**
  String get shopGalleryUploadAction;

  /// No description provided for @shopGalleryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery images (one per line)'**
  String get shopGalleryFieldLabel;

  /// No description provided for @shopGalleryLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Gallery: {count}/{max} images'**
  String shopGalleryLimitHint(Object count, Object max);

  /// No description provided for @shopEditHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get shopEditHoursLabel;

  /// No description provided for @shopEditContactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get shopEditContactsLabel;

  /// No description provided for @shopEditNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Operational notes'**
  String get shopEditNotesLabel;

  /// No description provided for @shopImagePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image preview unavailable'**
  String get shopImagePreviewUnavailable;

  /// No description provided for @shopProfileModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop data'**
  String get shopProfileModeTitle;

  /// No description provided for @shopProfileModeBody.
  ///
  /// In en, this message translates to:
  /// **'Fill in the data that will appear on your shop\'s public card.'**
  String get shopProfileModeBody;

  /// No description provided for @shopServicePickup.
  ///
  /// In en, this message translates to:
  /// **'Quick pickup'**
  String get shopServicePickup;

  /// No description provided for @shopServiceBench.
  ///
  /// In en, this message translates to:
  /// **'Pit support'**
  String get shopServiceBench;

  /// No description provided for @shopServiceElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get shopServiceElectronics;

  /// No description provided for @shopSpecialtyBuggy.
  ///
  /// In en, this message translates to:
  /// **'1/8 buggy'**
  String get shopSpecialtyBuggy;

  /// No description provided for @shopSpecialtyMiniZ.
  ///
  /// In en, this message translates to:
  /// **'Mini-Z'**
  String get shopSpecialtyMiniZ;

  /// No description provided for @shopSpecialtyBatteries.
  ///
  /// In en, this message translates to:
  /// **'Batteries and charging'**
  String get shopSpecialtyBatteries;

  /// No description provided for @externalLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Links and channels'**
  String get externalLinksTitle;

  /// No description provided for @externalLinksProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Add only channels you want to make public on your profile.'**
  String get externalLinksProfileBody;

  /// No description provided for @externalLinksShopBody.
  ///
  /// In en, this message translates to:
  /// **'Official shop channels: website, social, videos or operational chats.'**
  String get externalLinksShopBody;

  /// No description provided for @externalLinksTrackBody.
  ///
  /// In en, this message translates to:
  /// **'Official track channels: website, social, race streams or community groups.'**
  String get externalLinksTrackBody;

  /// No description provided for @externalLinksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No public links added yet.'**
  String get externalLinksEmpty;

  /// No description provided for @externalLinksAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get externalLinksAddAction;

  /// No description provided for @externalLinksAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add an external link'**
  String get externalLinksAddTitle;

  /// No description provided for @externalLinksProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get externalLinksProviderLabel;

  /// No description provided for @externalLinksLabelField.
  ///
  /// In en, this message translates to:
  /// **'Alias / visible label'**
  String get externalLinksLabelField;

  /// No description provided for @externalLinksUrlField.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get externalLinksUrlField;

  /// No description provided for @externalLinksUrlHint.
  ///
  /// In en, this message translates to:
  /// **'You can paste the link without https://, we will add it for you.'**
  String get externalLinksUrlHint;

  /// No description provided for @externalLinksInvalidUrlError.
  ///
  /// In en, this message translates to:
  /// **'This link does not look valid. Try an address like instagram.com/name or https://yoursite.com.'**
  String get externalLinksInvalidUrlError;

  /// No description provided for @externalLinksPublicToggle.
  ///
  /// In en, this message translates to:
  /// **'Make public'**
  String get externalLinksPublicToggle;

  /// No description provided for @externalLinksSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save link'**
  String get externalLinksSaveAction;

  /// No description provided for @externalLinkProviderWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get externalLinkProviderWebsite;

  /// No description provided for @externalLinkProviderInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get externalLinkProviderInstagram;

  /// No description provided for @externalLinkProviderFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get externalLinkProviderFacebook;

  /// No description provided for @externalLinkProviderYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get externalLinkProviderYoutube;

  /// No description provided for @externalLinkProviderTiktok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get externalLinkProviderTiktok;

  /// No description provided for @externalLinkProviderWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get externalLinkProviderWhatsapp;

  /// No description provided for @externalLinkProviderTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get externalLinkProviderTelegram;

  /// No description provided for @submitPlaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Moderated user contribution for tracks, spots, bashing areas or shops.'**
  String get submitPlaceDescription;

  /// No description provided for @submissionHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Help expand the real map'**
  String get submissionHeroTitle;

  /// No description provided for @submissionHeroBody.
  ///
  /// In en, this message translates to:
  /// **'User submissions should help surface useful tracks, spots and shops without degrading the public catalog.'**
  String get submissionHeroBody;

  /// No description provided for @submissionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get submissionTypeLabel;

  /// No description provided for @submissionTypeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get submissionTypeTrack;

  /// No description provided for @submissionTypeSpot.
  ///
  /// In en, this message translates to:
  /// **'Spot / Bashing'**
  String get submissionTypeSpot;

  /// No description provided for @submissionTypeShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get submissionTypeShop;

  /// No description provided for @submissionPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get submissionPlaceName;

  /// No description provided for @submissionCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get submissionCity;

  /// No description provided for @submissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get submissionDescription;

  /// No description provided for @submissionWhatHelpsTitle.
  ///
  /// In en, this message translates to:
  /// **'What really helps review'**
  String get submissionWhatHelpsTitle;

  /// No description provided for @submissionWhatHelpsBody.
  ///
  /// In en, this message translates to:
  /// **'A recognizable name, correct city, concise description and a few practical details greatly improve the quality of the submission.'**
  String get submissionWhatHelpsBody;

  /// No description provided for @submissionReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Submissions do not enter the public catalog automatically: they always go through review.'**
  String get submissionReviewHint;

  /// No description provided for @submissionSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send submission'**
  String get submissionSendButton;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingTitle;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Guided first access to decide what to ask immediately and what to keep optional.'**
  String get onboardingDescription;

  /// No description provided for @onboardingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'A light, but useful first access'**
  String get onboardingHeroTitle;

  /// No description provided for @onboardingHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Onboarding should help PitLap understand hobbies, context and preferences without turning registration into a heavy questionnaire.'**
  String get onboardingHeroBody;

  /// No description provided for @onboardingStepOneTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Essential data'**
  String get onboardingStepOneTitle;

  /// No description provided for @onboardingStepOneBody.
  ///
  /// In en, this message translates to:
  /// **'Email, language, document acceptance and very little else. The first entry should stay frictionless.'**
  String get onboardingStepOneBody;

  /// No description provided for @onboardingStepTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Hobby identity'**
  String get onboardingStepTwoTitle;

  /// No description provided for @onboardingStepTwoBody.
  ///
  /// In en, this message translates to:
  /// **'Nickname, location, years in the hobby and an optional short bio.'**
  String get onboardingStepTwoBody;

  /// No description provided for @onboardingStepThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Hobbies and interests'**
  String get onboardingStepThreeTitle;

  /// No description provided for @onboardingStepThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Preferences such as buggy, Mini-Z, drones or trains help discovery, shops and suggestions.'**
  String get onboardingStepThreeBody;

  /// No description provided for @onboardingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Data to collect'**
  String get onboardingChecklistTitle;

  /// No description provided for @onboardingChecklistBody.
  ///
  /// In en, this message translates to:
  /// **'Initial checklist to decide what to ask immediately, what to make optional and what to postpone.'**
  String get onboardingChecklistBody;

  /// No description provided for @onboardingFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Account email'**
  String get onboardingFieldEmail;

  /// No description provided for @onboardingFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get onboardingFieldLanguage;

  /// No description provided for @onboardingFieldNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get onboardingFieldNickname;

  /// No description provided for @onboardingFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location / city'**
  String get onboardingFieldLocation;

  /// No description provided for @onboardingFieldYears.
  ///
  /// In en, this message translates to:
  /// **'Years in the hobby'**
  String get onboardingFieldYears;

  /// No description provided for @onboardingFieldHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies and interests'**
  String get onboardingFieldHobbies;

  /// No description provided for @onboardingFieldMarketing.
  ///
  /// In en, this message translates to:
  /// **'Optional marketing'**
  String get onboardingFieldMarketing;

  /// No description provided for @onboardingFieldAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get onboardingFieldAccountType;

  /// No description provided for @onboardingAccountTypeActive.
  ///
  /// In en, this message translates to:
  /// **'Active account type: {role}'**
  String onboardingAccountTypeActive(Object role);

  /// No description provided for @onboardingPrinciplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Design principles'**
  String get onboardingPrinciplesTitle;

  /// No description provided for @onboardingPrincipleOne.
  ///
  /// In en, this message translates to:
  /// **'Do not ask for everything upfront: start with the minimum that matters.'**
  String get onboardingPrincipleOne;

  /// No description provided for @onboardingPrincipleTwo.
  ///
  /// In en, this message translates to:
  /// **'Keep optional any data that is not required for the first useful session.'**
  String get onboardingPrincipleTwo;

  /// No description provided for @onboardingPrincipleThree.
  ///
  /// In en, this message translates to:
  /// **'Allow users to complete the profile later without penalizing access.'**
  String get onboardingPrincipleThree;

  /// No description provided for @onboardingNextStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended direction'**
  String get onboardingNextStepTitle;

  /// No description provided for @onboardingNextStepBody.
  ///
  /// In en, this message translates to:
  /// **'Suggested first implementation: login, consent, language, nickname and hobby choice in a maximum 2-step flow.'**
  String get onboardingNextStepBody;

  /// No description provided for @noTracksMatchingFilters.
  ///
  /// In en, this message translates to:
  /// **'No tracks match the active filters.'**
  String get noTracksMatchingFilters;

  /// No description provided for @profileBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get profileBasicsTitle;

  /// No description provided for @profileBasicsBody.
  ///
  /// In en, this message translates to:
  /// **'Here you can already update visible name, language and profile photo. The rest of the profile will land in onboarding.'**
  String get profileBasicsBody;

  /// No description provided for @profilePhotoUrl.
  ///
  /// In en, this message translates to:
  /// **'Profile photo (URL)'**
  String get profilePhotoUrl;

  /// No description provided for @profilePhotoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste an image URL to test avatar and preview.'**
  String get profilePhotoUrlHint;

  /// No description provided for @profilePhotoUrlSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Some sites block direct loading in the browser. In that case PitLap will automatically show the initials fallback.'**
  String get profilePhotoUrlSupportHint;

  /// No description provided for @eventsCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventsCreateAction;

  /// No description provided for @eventsCreatedByYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming public events'**
  String get eventsCreatedByYouTitle;

  /// No description provided for @eventsPublicBadge.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get eventsPublicBadge;

  /// No description provided for @eventsShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get eventsShareAction;

  /// No description provided for @eventsShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Event link copied. We can connect it to the full Share panel later.'**
  String get eventsShareCopied;

  /// No description provided for @eventsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Event history'**
  String get eventsArchiveTitle;

  /// No description provided for @eventsBadgeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get eventsBadgeCommunity;

  /// No description provided for @eventsBadgeArchived.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get eventsBadgeArchived;

  /// No description provided for @eventsCreateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new event'**
  String get eventsCreateDialogTitle;

  /// No description provided for @eventsCreateTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventsCreateTitleLabel;

  /// No description provided for @eventsCreateLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventsCreateLocationLabel;

  /// No description provided for @eventsCreateVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue / track / shop'**
  String get eventsCreateVenueLabel;

  /// No description provided for @eventsCreateNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Short note'**
  String get eventsCreateNoteLabel;

  /// No description provided for @eventsCreateImageAction.
  ///
  /// In en, this message translates to:
  /// **'Upload event photo'**
  String get eventsCreateImageAction;

  /// No description provided for @eventsCreateImageLoaded.
  ///
  /// In en, this message translates to:
  /// **'Event photo ready'**
  String get eventsCreateImageLoaded;

  /// No description provided for @imageUploadTooLargeMessage.
  ///
  /// In en, this message translates to:
  /// **'This image is too heavy for the preview. Try a photo under 5 MB or compress it before uploading.'**
  String get imageUploadTooLargeMessage;

  /// No description provided for @imageUploadUnreadableMessage.
  ///
  /// In en, this message translates to:
  /// **'I cannot read this image. Try JPG, PNG, or WebP.'**
  String get imageUploadUnreadableMessage;

  /// No description provided for @mediaUploadNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Sign in to upload images.'**
  String get mediaUploadNotAuthenticated;

  /// No description provided for @mediaUploadGenericError.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed. Please try again.'**
  String get mediaUploadGenericError;

  /// No description provided for @eventsCreateDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventsCreateDateLabel;

  /// No description provided for @eventsCreateSave.
  ///
  /// In en, this message translates to:
  /// **'Save event'**
  String get eventsCreateSave;

  /// No description provided for @eventsCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Public event created. It now appears in the community event list.'**
  String get eventsCreateSuccess;

  /// No description provided for @eventsCreateDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'Event created by the PitLap community.'**
  String get eventsCreateDefaultNote;

  /// No description provided for @eventsEmptyCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'No created events yet'**
  String get eventsEmptyCreatedTitle;

  /// No description provided for @eventsEmptyCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first event to test the community flow and preview how it could appear to other users.'**
  String get eventsEmptyCreatedBody;

  /// No description provided for @clearSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchAction;

  /// No description provided for @profileQuickLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get profileQuickLinksTitle;

  /// No description provided for @profileQuickLinksBody.
  ///
  /// In en, this message translates to:
  /// **'Fast access to the areas you are already using in the current tests.'**
  String get profileQuickLinksBody;

  /// No description provided for @garagePublicBuildsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} public builds'**
  String garagePublicBuildsCount(int count);

  /// No description provided for @garageAddBuildAction.
  ///
  /// In en, this message translates to:
  /// **'Add build'**
  String get garageAddBuildAction;

  /// No description provided for @garageSetPrivateAction.
  ///
  /// In en, this message translates to:
  /// **'Make garage private'**
  String get garageSetPrivateAction;

  /// No description provided for @garageSetPublicAction.
  ///
  /// In en, this message translates to:
  /// **'Make garage public'**
  String get garageSetPublicAction;

  /// No description provided for @garageBuildsTestingHint.
  ///
  /// In en, this message translates to:
  /// **'You can already test build creation, image URL and public/private visibility here.'**
  String get garageBuildsTestingHint;

  /// No description provided for @garageBuildTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Build name'**
  String get garageBuildTitleLabel;

  /// No description provided for @garageBuildMetaLabel.
  ///
  /// In en, this message translates to:
  /// **'Category / platform'**
  String get garageBuildMetaLabel;

  /// No description provided for @garageBuildImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Build photo (URL)'**
  String get garageBuildImageUrlLabel;

  /// No description provided for @garageImageUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get garageImageUploadAction;

  /// No description provided for @garageImageLoaded.
  ///
  /// In en, this message translates to:
  /// **'Image ready'**
  String get garageImageLoaded;

  /// No description provided for @garageBuildSpecsHint.
  ///
  /// In en, this message translates to:
  /// **'Quick specs separated by commas'**
  String get garageBuildSpecsHint;

  /// No description provided for @garageBuildPublicToggle.
  ///
  /// In en, this message translates to:
  /// **'Make this build public'**
  String get garageBuildPublicToggle;

  /// No description provided for @garageBuildSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save build'**
  String get garageBuildSaveAction;

  /// No description provided for @garageBuildCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Build added to the garage.'**
  String get garageBuildCreatedMessage;

  /// No description provided for @garageBuildUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Build updated.'**
  String get garageBuildUpdatedMessage;

  /// No description provided for @garageEditBuildAction.
  ///
  /// In en, this message translates to:
  /// **'Edit build'**
  String get garageEditBuildAction;

  /// No description provided for @garageBuildMaxImagesReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} images per build.'**
  String garageBuildMaxImagesReached(int max);

  /// No description provided for @garageBuildImagesHelper.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} images. The first image is used as the build preview.'**
  String garageBuildImagesHelper(int max);

  /// No description provided for @garageBuildImagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} images'**
  String garageBuildImagesCount(int count, int max);

  /// No description provided for @garageUploadPhotosAction.
  ///
  /// In en, this message translates to:
  /// **'Upload photos'**
  String get garageUploadPhotosAction;

  /// No description provided for @processingUploadImages.
  ///
  /// In en, this message translates to:
  /// **'Preparing images'**
  String get processingUploadImages;

  /// No description provided for @processingUploadCover.
  ///
  /// In en, this message translates to:
  /// **'Preparing cover'**
  String get processingUploadCover;

  /// No description provided for @processingUploadGallery.
  ///
  /// In en, this message translates to:
  /// **'Preparing gallery'**
  String get processingUploadGallery;

  /// No description provided for @processingUploadEventImage.
  ///
  /// In en, this message translates to:
  /// **'Preparing event photo'**
  String get processingUploadEventImage;

  /// No description provided for @eventsOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open event'**
  String get eventsOpenAction;

  /// No description provided for @nearbySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a nearby track or shop...'**
  String get nearbySearchHint;

  /// No description provided for @nearbyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get nearbyFilterAll;

  /// No description provided for @nearbyFilterTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get nearbyFilterTracks;

  /// No description provided for @nearbyFilterShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get nearbyFilterShops;

  /// No description provided for @nearbyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for the active filters.'**
  String get nearbyNoResults;

  /// No description provided for @nearbyNearMeButton.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearbyNearMeButton;

  /// No description provided for @nearbyOpenInMap.
  ///
  /// In en, this message translates to:
  /// **'Open in map'**
  String get nearbyOpenInMap;

  /// No description provided for @nearbyOpenTrack.
  ///
  /// In en, this message translates to:
  /// **'Open track'**
  String get nearbyOpenTrack;

  /// No description provided for @nearbyOpenShop.
  ///
  /// In en, this message translates to:
  /// **'Open shop'**
  String get nearbyOpenShop;

  /// No description provided for @nearbyNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services'**
  String get nearbyNoServices;

  /// No description provided for @nearbyServicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} services'**
  String nearbyServicesCount(int count);

  /// No description provided for @nearbyShopGeneric.
  ///
  /// In en, this message translates to:
  /// **'RC shop'**
  String get nearbyShopGeneric;

  /// No description provided for @nearbyStatusUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get nearbyStatusUpdating;

  /// No description provided for @shopSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a shop or specialty...'**
  String get shopSearchHint;

  /// No description provided for @shopSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save shop'**
  String get shopSaveAction;

  /// No description provided for @shopSavedAction.
  ///
  /// In en, this message translates to:
  /// **'Shop saved'**
  String get shopSavedAction;

  /// No description provided for @shopOpenDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get shopOpenDetailsAction;

  /// No description provided for @shopNoResults.
  ///
  /// In en, this message translates to:
  /// **'No shop matches the current search.'**
  String get shopNoResults;

  /// No description provided for @managerStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s track status'**
  String get managerStatusLabel;

  /// No description provided for @managerToggleCompressor.
  ///
  /// In en, this message translates to:
  /// **'Compressed air available'**
  String get managerToggleCompressor;

  /// No description provided for @managerToggleBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms available'**
  String get managerToggleBathrooms;

  /// No description provided for @managerToggleEventReady.
  ///
  /// In en, this message translates to:
  /// **'Evening event confirmed'**
  String get managerToggleEventReady;

  /// No description provided for @managerStatusMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick message'**
  String get managerStatusMessageLabel;

  /// No description provided for @managerSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save update'**
  String get managerSaveAction;

  /// No description provided for @managerSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local update saved. We can use this flow to shape the manager panel.'**
  String get managerSaveSuccess;

  /// No description provided for @managerSaveSuccessTrack.
  ///
  /// In en, this message translates to:
  /// **'Track update saved for {trackName}.'**
  String managerSaveSuccessTrack(Object trackName);

  /// No description provided for @managerNoTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'No assigned tracks'**
  String get managerNoTracksTitle;

  /// No description provided for @managerNoTracksBody.
  ///
  /// In en, this message translates to:
  /// **'This account can enter the manager area, but it is not currently assigned to any track. The next step is to connect ownership and the real operational panel.'**
  String get managerNoTracksBody;

  /// No description provided for @managerAssignedTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned tracks'**
  String get managerAssignedTracksTitle;

  /// No description provided for @managerAssignedTracksBody.
  ///
  /// In en, this message translates to:
  /// **'This list comes from the real `track_managers` relationship, not only from the account global role.'**
  String get managerAssignedTracksBody;

  /// No description provided for @managerEditingTrack.
  ///
  /// In en, this message translates to:
  /// **'You are preparing an update for {trackName}.'**
  String managerEditingTrack(Object trackName);

  /// No description provided for @submissionImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo or cover (URL)'**
  String get submissionImageUrlLabel;

  /// No description provided for @submissionMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least place name and city.'**
  String get submissionMissingFields;

  /// No description provided for @submissionSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Submission ready: {name} in {city}.'**
  String submissionSendSuccess(String name, String city);

  /// No description provided for @pitcoinBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'PitCoin'**
  String get pitcoinBalanceTitle;

  /// No description provided for @pitcoinBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How active and useful you are to the PitLap community.'**
  String get pitcoinBalanceSubtitle;

  /// No description provided for @pitcoinBalanceDeltaWeek.
  ///
  /// In en, this message translates to:
  /// **'+{count} this week'**
  String pitcoinBalanceDeltaWeek(int count);

  /// No description provided for @pitcoinHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'View activity'**
  String get pitcoinHistoryAction;

  /// No description provided for @pitcoinHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get pitcoinHistoryTitle;

  /// No description provided for @pitcoinHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All the actions that earned you PitCoin.'**
  String get pitcoinHistorySubtitle;

  /// No description provided for @pitcoinHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet. Start contributing to the community and your PitCoin will appear here.'**
  String get pitcoinHistoryEmpty;

  /// No description provided for @pitcoinHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get pitcoinHistoryLoadMore;

  /// No description provided for @pitcoinBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get pitcoinBadgesTitle;

  /// No description provided for @pitcoinBadgesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones along your PitLap journey.'**
  String get pitcoinBadgesSubtitle;

  /// No description provided for @pitcoinBadgesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trophies unlocked yet.'**
  String get pitcoinBadgesEmpty;

  /// No description provided for @pitcoinBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get pitcoinBadgeLocked;

  /// No description provided for @pitcoinBadgeUnlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String pitcoinBadgeUnlockedOn(String date);

  /// No description provided for @pitcoinTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get pitcoinTierBronze;

  /// No description provided for @pitcoinTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get pitcoinTierSilver;

  /// No description provided for @pitcoinTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get pitcoinTierGold;

  /// No description provided for @pitcoinTierSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get pitcoinTierSpecial;

  /// No description provided for @pitcoinPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} PitCoin'**
  String pitcoinPointsLabel(int count);

  /// No description provided for @pitcoinPointsShort.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String pitcoinPointsShort(int count);

  /// No description provided for @pitcoinPointsZero.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get pitcoinPointsZero;

  /// No description provided for @trackEditorCategorySection.
  ///
  /// In en, this message translates to:
  /// **'Track category'**
  String get trackEditorCategorySection;

  /// No description provided for @trackEditorCategorySectionBody.
  ///
  /// In en, this message translates to:
  /// **'Select the track type — used in search filters.'**
  String get trackEditorCategorySectionBody;

  /// No description provided for @trackEditorServicesSection.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get trackEditorServicesSection;

  /// No description provided for @trackEditorServicesSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Select the services confirmed at this track.'**
  String get trackEditorServicesSectionBody;

  /// No description provided for @trackEditorDraftsSection.
  ///
  /// In en, this message translates to:
  /// **'Drafts and pending approval'**
  String get trackEditorDraftsSection;

  /// No description provided for @trackEditorDraftsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Tracks you have submitted that are awaiting review or are still in draft.'**
  String get trackEditorDraftsSectionBody;

  /// No description provided for @trackEditorDraftEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit track'**
  String get trackEditorDraftEditButton;

  /// No description provided for @trackEditorDraftPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting admin review'**
  String get trackEditorDraftPendingLabel;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get shareLinkCopied;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @commentsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsSectionTitle;

  /// No description provided for @commentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get commentsEmptyTitle;

  /// No description provided for @commentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a comment on this content.'**
  String get commentsEmptyBody;

  /// No description provided for @commentsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more comments'**
  String get commentsLoadMore;

  /// No description provided for @commentsInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentsInputHint;

  /// No description provided for @commentsSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commentsSubmitAction;

  /// No description provided for @commentsPostError.
  ///
  /// In en, this message translates to:
  /// **'Could not post the comment. Please try again.'**
  String get commentsPostError;

  /// No description provided for @commentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading comments.'**
  String get commentsLoadError;

  /// No description provided for @commentsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commentsDeleteAction;

  /// No description provided for @commentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get commentsDeleteTitle;

  /// No description provided for @commentsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment? This action cannot be undone.'**
  String get commentsDeleteBody;

  /// No description provided for @commentsDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commentsDeleteCancel;

  /// No description provided for @commentsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commentsDeleteConfirm;

  /// No description provided for @commentsReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commentsReportAction;

  /// No description provided for @commentsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get commentsReportTitle;

  /// No description provided for @commentsReportBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to report this comment to the moderation team?'**
  String get commentsReportBody;

  /// No description provided for @commentsReportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commentsReportCancel;

  /// No description provided for @commentsReportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commentsReportConfirm;

  /// No description provided for @commentsReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment reported. Thank you.'**
  String get commentsReportSuccess;

  /// No description provided for @commentsReportError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the report. Please try again.'**
  String get commentsReportError;

  /// No description provided for @commentsGuestCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in to leave a comment.'**
  String get commentsGuestCta;

  /// No description provided for @commentsGuestLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get commentsGuestLogin;

  /// No description provided for @commentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comment} =1{1 comment} other{{count} comments}}'**
  String commentsCountLabel(int count);

  /// No description provided for @profileFollowAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get profileFollowAction;

  /// No description provided for @profileFollowingAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowingAction;

  /// No description provided for @profileUnfollowAction.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get profileUnfollowAction;

  /// No description provided for @profileFollowerSingular.
  ///
  /// In en, this message translates to:
  /// **'follower'**
  String get profileFollowerSingular;

  /// No description provided for @profileFollowerPlural.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get profileFollowerPlural;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your recent notifications'**
  String get notificationsDescription;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get notificationsLoadMore;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When someone follows you or posts something new, you\'ll see it here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications.'**
  String get notificationsErrorTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
