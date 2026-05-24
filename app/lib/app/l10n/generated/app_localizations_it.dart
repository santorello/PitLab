// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'PitLap';

  @override
  String get appTagline => 'Dove il modellismo si incontra';

  @override
  String get tracksTitle => 'Piste';

  @override
  String get menuOpen => 'Apri menu';

  @override
  String get menuClose => 'Chiudi menu';

  @override
  String get homeHeadline => 'Dove il modellismo si incontra';

  @override
  String get homeSubheadline =>
      'Scopri piste, eventi, negozi e persone che tengono viva la parte più reale del modellismo.';

  @override
  String get homeExploreTitle => 'Ingressi rapidi';

  @override
  String get homeExploreBody =>
      'Tre aree chiave per orientarti subito tra piste, eventi e negozi utili.';

  @override
  String get loginCtaButton => 'Accedi';

  @override
  String get loginCtaHint =>
      'Accedi per salvare preferiti, segnalare la tua presenza in pista e completare il profilo in seguito.';

  @override
  String get accountActiveNow => 'Accesso attivo';

  @override
  String get guestModeLabel => 'Modalità ospite';

  @override
  String get searchTracksHint => 'Cerca pista o luogo...';

  @override
  String get filterNearby => 'Vicino a te';

  @override
  String get filterBuggy => 'Buggy';

  @override
  String get filterMiniZ => 'Mini-Z';

  @override
  String get filterIndoor => 'Indoor';

  @override
  String get filterOutdoor => 'Outdoor';

  @override
  String get nearbyTitle => 'Vicino a te';

  @override
  String get spotsTitle => 'Spot';

  @override
  String get eventsTitle => 'Eventi';

  @override
  String get shopsTitle => 'Negozi';

  @override
  String get garageTitle => 'Garage';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get managerTitle => 'Gestione';

  @override
  String get submitPlaceTitle => 'Segnala luogo';

  @override
  String get spotsDescription =>
      'Mappa sociale dei posti informali dove girare in compagnia con buggy, scaler, droni e altri mezzi fuori dai circuiti convenzionali.';

  @override
  String get spotsHeroTitle => 'Trova e condividi spot non convenzionali';

  @override
  String get spotsHeroBody =>
      'Argini, cave, trail, piazzali, campi volo e altri luoghi utili da vivere con rispetto, foto, punto mappa e note pratiche per la community.';

  @override
  String get spotsHeroChipMap => 'Punto mappa';

  @override
  String get spotsHeroChipPhotos => 'Foto del posto';

  @override
  String get spotsHeroChipCommunity => 'Uso condiviso';

  @override
  String get spotsSubmitAction => 'Segnala spot';

  @override
  String get spotsWhyTitle => 'Perché serve';

  @override
  String get spotsWhyBody =>
      'Non tutto passa da piste ufficiali o negozi: questa sezione raccoglie luoghi reali, informali e utili per organizzare uscite leggere con la community.';

  @override
  String get spotsBestForLabel => 'Ideale per';

  @override
  String get spotsSurfaceLabel => 'Terreno';

  @override
  String spotsPhotosCount(int count) {
    return '$count foto';
  }

  @override
  String get spotsSuggestEditAction => 'Segnala aggiornamento';

  @override
  String get signupButton => 'Iscrivimi';

  @override
  String get comingButton => 'Sto arrivando';

  @override
  String get favoriteTrackButton => 'Preferiti';

  @override
  String get favoritedTrackButton => 'Salvata';

  @override
  String get followTrackButton => 'Segui pista';

  @override
  String get followingTrackButton => 'Nei preferiti';

  @override
  String get viewTrackButton => 'Vedi pista';

  @override
  String get galleryButton => 'Galleria';

  @override
  String get openMapButton => 'Apri mappa';

  @override
  String get statusOpen => 'APERTA';

  @override
  String get statusWet => 'BAGNATA';

  @override
  String get statusClosed => 'CHIUSA';

  @override
  String get statusUnknown => 'DA VERIFICARE';

  @override
  String get arrivalsSoonAvailable => 'Presenze presto disponibili';

  @override
  String get servicesComingSoon => 'Servizi in arrivo';

  @override
  String get noTracksAvailable => 'Nessuna pista disponibile al momento.';

  @override
  String tracksLoadError(Object error) {
    return 'Errore nel caricamento piste: $error';
  }

  @override
  String get trackDetailTitle => 'Dettaglio pista e condizioni attuali';

  @override
  String get trackNotFound => 'Pista non trovata o non pubblica.';

  @override
  String trackLoadError(Object error) {
    return 'Errore nel caricamento pista: $error';
  }

  @override
  String trackBreadcrumb(Object name) {
    return 'Piste / $name';
  }

  @override
  String get trackStatusUpdated => 'Stato pista aggiornato';

  @override
  String get weatherLabel => 'Meteo';

  @override
  String get servicesLabel => 'Servizi';

  @override
  String servicesConfirmedCount(Object count) {
    return '$count confermati';
  }

  @override
  String get todayLabel => 'Oggi';

  @override
  String get weatherOk => 'OK';

  @override
  String get weatherWarning => 'Attenzione';

  @override
  String get weatherNo => 'No';

  @override
  String get weatherTrackTitle => 'Meteo pista';

  @override
  String get weatherQuickVerdict => 'Verdetto rapido';

  @override
  String weatherTodayVerdict(Object verdict) {
    return '$verdict oggi';
  }

  @override
  String get weatherDataSourceAttribution =>
      'Dati meteo forniti da Open-Meteo.';

  @override
  String get weatherDaySun => 'Dom';

  @override
  String get weatherDayMon => 'Lun';

  @override
  String get weatherOutdoorOkNote => 'Asciutto e stabile';

  @override
  String get weatherOutdoorWarningNote => 'Nuvoloso, rischio pioggia';

  @override
  String get weatherOutdoorNoNote => 'Pioggia prevista';

  @override
  String get weatherIndoorOkNote => 'Indoor, meteo poco critico';

  @override
  String get weatherIndoorRegularNote => 'Sessione regolare';

  @override
  String get weatherIndoorWarningNote => 'Traffico e umidita\'';

  @override
  String get weatherLiveBadge => 'Meteo live';

  @override
  String get weatherMockBadge => 'Fallback locale';

  @override
  String weatherApiStableDay(Object temp) {
    return 'Stabile, max $temp°C';
  }

  @override
  String weatherApiMixedConditions(Object chance) {
    return 'Variabile, pioggia fino al $chance%';
  }

  @override
  String weatherApiRainExpected(Object chance) {
    return 'Pioggia probabile, fino al $chance%';
  }

  @override
  String get galleryTitle => 'Galleria';

  @override
  String get galleryPreviewBody =>
      'Anteprima visuale della pista e del contesto.';

  @override
  String get galleryCoverTrack => 'Cover pista';

  @override
  String get galleryBox => 'Box';

  @override
  String get galleryTypicalDay => 'Giornata tipo';

  @override
  String get todayAtTrackTitle => 'Oggi in pista';

  @override
  String get todayAtTrackStateLabel => 'Stato di oggi';

  @override
  String get todayAtTrackUpdatedLabel => 'Ultimo aggiornamento';

  @override
  String get signInForArrivalStatus =>
      'Accedi per segnalare la tua presenza e vedere il tuo stato di oggi.';

  @override
  String get noArrivalForToday =>
      'Non hai ancora segnalato la tua presenza per oggi.';

  @override
  String get arrivalConfirmed => 'Confermato: stai arrivando';

  @override
  String get arrivalMaybe => 'Segnalato come: forse';

  @override
  String get arrivalCancelled => 'Segnalazione annullata';

  @override
  String get arrivalStatusUpdated => 'Stato presenza aggiornato';

  @override
  String arrivalRegisteredAt(Object time) {
    return 'Registrato alle $time';
  }

  @override
  String get arrivalValidForToday =>
      'Questa presenza vale solo per oggi e si azzera nel giorno successivo.';

  @override
  String get loadingTodayArrival => 'Verifica presenza odierna in corso...';

  @override
  String arrivalReadError(Object error) {
    return 'Impossibile leggere la tua presenza di oggi: $error';
  }

  @override
  String get arrivalSheetTitle => 'Sto arrivando';

  @override
  String arrivalSheetBody(Object trackName) {
    return 'Primo flusso UI per confermare la presenza su $trackName.';
  }

  @override
  String get arrivalConfirmTitle => 'Confermo';

  @override
  String get arrivalConfirmSubtitle => 'Mi sto organizzando per venire.';

  @override
  String get arrivalMaybeTitle => 'Forse';

  @override
  String get arrivalMaybeSubtitle => 'Potrei passare, ma non è sicuro.';

  @override
  String get arrivalCancelTitle => 'Annulla';

  @override
  String get arrivalCancelSubtitle => 'Segno che oggi non verrai in pista.';

  @override
  String arrivalSavedMessage(Object selection, Object trackName) {
    return '$selection registrato per oggi su $trackName.';
  }

  @override
  String followTrackSaved(Object trackName) {
    return '$trackName aggiunta ai preferiti.';
  }

  @override
  String followTrackRemoved(Object trackName) {
    return '$trackName rimossa dai preferiti.';
  }

  @override
  String get loginTitle => 'Accedi a PitLap';

  @override
  String get loginBody =>
      'Inserisci la tua email e ti inviamo un link di accesso rapido per entrare in PitLap.';

  @override
  String get loginExistingAccountHint =>
      'Se hai già un account, userai lo stesso accesso. Se è il primo ingresso, PitLap preparerà il tuo profilo di base.';

  @override
  String get loginAccountTypeTitle => 'Tipo di account iniziale';

  @override
  String get loginAccountTypeBody =>
      'Scegli come vuoi entrare in PitLap. Potrai completare e affinare il profilo in seguito.';

  @override
  String get loginAccountTypeUser => 'Modellista';

  @override
  String get loginAccountTypeShopOwner => 'Negozio';

  @override
  String get loginAccountTypeTrackOrganizer => 'Organizzatore pista';

  @override
  String get emailLabel => 'Email';

  @override
  String get loginSendLink => 'Ricevi link di accesso';

  @override
  String get loginSending => 'Invio in corso...';

  @override
  String get loginTermsConsentLabel => 'Accetto i Termini di Servizio';

  @override
  String get loginTermsConsentHint =>
      'Richiesto per creare o usare l\'account PitLap.';

  @override
  String get loginPrivacyNoticeLabel =>
      'Ho preso visione dell\'Informativa Privacy';

  @override
  String get loginPrivacyNoticeHint =>
      'Richiesto per proseguire con l\'accesso e capire come trattiamo i dati personali.';

  @override
  String get loginMarketingConsentLabel =>
      'Acconsento a ricevere comunicazioni marketing via email';

  @override
  String get loginMarketingConsentHint =>
      'Facoltativo. Non è necessario per usare PitLap e potrà essere revocato in futuro.';

  @override
  String get loginLegalDocsHint =>
      'Documenti base disponibili nel progetto: Privacy Policy, Terms of Service, Cookie Policy e registro consensi.';

  @override
  String get loginRequiredConsentsError =>
      'Per continuare devi accettare i Termini di Servizio e confermare la presa visione dell\'Informativa Privacy.';

  @override
  String get loginExpiredLinkError =>
      'Il link di accesso non è più valido o è già scaduto. Richiedine uno nuovo.';

  @override
  String get loginGenericAuthError =>
      'Non siamo riusciti a completare l\'accesso. Riprova con un nuovo link.';

  @override
  String loginRedirectHint(Object path) {
    return 'Dopo il login tornerai su $path.';
  }

  @override
  String get legalPrivacyTitle => 'Informativa Privacy';

  @override
  String get legalPrivacyDescription =>
      'Informativa sul trattamento dei dati personali ai sensi degli artt. 13-14 del Regolamento UE 2016/679 (GDPR).';

  @override
  String get legalPrivacySectionCollectedTitle => 'Dati raccolti';

  @override
  String get legalPrivacySectionCollectedBody =>
      'PitLap tratta dati account (email e identificativo utente), dati profilo (nome visibile, lingua), preferenze, piste salvate, presenze giornaliere in pista, contenuti di garage o profilo pubblico resi visibili su scelta dell\'utente, e dati tecnici minimi necessari per sicurezza, autenticazione e corretto funzionamento del servizio.';

  @override
  String get legalPrivacySectionPurposeTitle => 'Finalita\' del trattamento';

  @override
  String get legalPrivacySectionPurposeBody =>
      'I dati sono trattati per: creare e gestire l\'account; fornire accesso sicuro tramite magic link; salvare preferenze (lingua, piste seguite); abilitare funzionalità richieste come la presenza in pista; garantire la sicurezza tecnica e prevenire abusi; inviare comunicazioni di servizio. Solo previo consenso separato e specifico: inviare comunicazioni marketing via email.';

  @override
  String get legalPrivacySectionLegalBasisTitle => 'Basi giuridiche';

  @override
  String get legalPrivacySectionLegalBasisBody =>
      'Esecuzione del contratto (art. 6 par. 1 lett. b GDPR): account, autenticazione e funzioni essenziali. Legittimo interesse (art. 6 par. 1 lett. f GDPR): sicurezza tecnica, prevenzione abusi, integrità del servizio. Consenso (art. 6 par. 1 lett. a GDPR): marketing via email e altre finalità facoltative. Obbligo legale (art. 6 par. 1 lett. c GDPR): adempimenti normativi ove applicabili.';

  @override
  String get legalPrivacySectionRightsTitle => 'Diritti dell\'interessato';

  @override
  String get legalPrivacySectionRightsBody =>
      'Ai sensi degli artt. 15-22 GDPR, l\'utente ha diritto di: accedere ai propri dati; ottenerne la rettifica o la cancellazione; richiedere la limitazione del trattamento; opporsi al trattamento basato su legittimo interesse; ricevere i dati in formato strutturato (portabilita\'); revocare il consenso in qualsiasi momento senza pregiudizio per la liceità del trattamento anteriore. Per esercitare questi diritti: privacy@pitlap.app. In caso di violazione, è possibile proporre reclamo all\'autorita\' di controllo competente (Garante per la protezione dei dati personali, www.garanteprivacy.it).';

  @override
  String get legalPrivacySectionControllerTitle => 'Titolare del trattamento';

  @override
  String get legalPrivacySectionControllerBody =>
      'Titolare del trattamento è PitLap (progetto in fase pre-lancio). I dati di contatto definitivi saranno indicati prima dell\'apertura al pubblico. Per qualsiasi richiesta relativa alla privacy scrivere a: privacy@pitlap.app.';

  @override
  String get legalPrivacySectionProcessorsTitle => 'Responsabili e fornitori';

  @override
  String get legalPrivacySectionProcessorsBody =>
      'PitLap si avvale di Supabase Inc. (USA) come fornitore di database, autenticazione e storage, su infrastruttura AWS nella regione eu-west-2 (Irlanda). I dati restano fisicamente all\'interno dell\'Unione Europea. Supabase opera come responsabile del trattamento ai sensi dell\'art. 28 GDPR; il Data Processing Agreement è disponibile su supabase.com/privacy. Non sono utilizzati altri fornitori terzi con accesso ai dati personali degli utenti.';

  @override
  String get legalPrivacySectionTransfersTitle => 'Trasferimento dati extra-UE';

  @override
  String get legalPrivacySectionTransfersBody =>
      'I dati sono conservati in server localizzati nell\'UE (AWS eu-west-2, Irlanda). Supabase Inc. è una società statunitense: il trasferimento verso gli USA avviene nel rispetto delle garanzie previste dal GDPR (Standard Contractual Clauses adottate da Supabase). Non vengono effettuati trasferimenti verso Paesi privi di adeguato livello di protezione senza le garanzie richieste dalla normativa.';

  @override
  String get legalPrivacySectionRetentionTitle => 'Conservazione dei dati';

  @override
  String get legalPrivacySectionRetentionBody =>
      'I dati dell\'account sono conservati per tutta la durata del rapporto con il servizio. In caso di cancellazione account, i dati personali vengono eliminati entro 30 giorni, salvo obblighi di conservazione previsti dalla legge. Le presenze in pista vengono rimosse automaticamente dopo 1 giorno dall\'inserimento. I log tecnici di sicurezza sono conservati per un massimo di 90 giorni.';

  @override
  String get legalPrivacySectionSecurityTitle => 'Sicurezza';

  @override
  String get legalPrivacySectionSecurityBody =>
      'PitLap adotta misure tecniche e organizzative adeguate per proteggere i dati da accessi non autorizzati, alterazioni o divulgazioni indebite. L\'autenticazione avviene tramite magic link (senza password da memorizzare); i dati sono trasmessi via HTTPS; i servizi infrastrutturali sono soggetti ai controlli di sicurezza di Supabase. In caso di violazione dei dati personali, saranno applicate le procedure di notifica previste dagli artt. 33-34 GDPR.';

  @override
  String get legalTermsTitle => 'Termini di Servizio';

  @override
  String get legalTermsDescription =>
      'Condizioni che regolano l\'uso di PitLap. Utilizzando il servizio l\'utente ne accetta i termini.';

  @override
  String get legalTermsSectionServiceTitle => 'Oggetto del servizio';

  @override
  String get legalTermsSectionServiceBody =>
      'PitLap è una piattaforma per consultare piste, negozi, eventi, profili, garage e presenze in pista, con accesso semplificato via email. Alcune aree possono essere rese pubbliche solo su scelta esplicita dell\'utente e, in base alle regole di prodotto, visibili soltanto ad altri utenti autenticati.';

  @override
  String get legalTermsSectionUseTitle => 'Uso consentito';

  @override
  String get legalTermsSectionUseBody =>
      'L\'utente si impegna a usare il servizio in modo lecito e rispettoso, fornendo dati accurati e senza abusare delle funzioni community, profilo, garage o presenza in pista. È vietato: usare il servizio per scopi illeciti, molestare altri utenti, diffondere contenuti falsi o ingannevoli, tentare accessi non autorizzati. PitLap si riserva il diritto di sospendere o rimuovere account che violino queste condizioni.';

  @override
  String get legalTermsSectionContentTitle => 'Contenuti utente';

  @override
  String get legalTermsSectionContentBody =>
      'L\'utente è responsabile dei contenuti che carica (testi, immagini, build) e dei diritti necessari alla loro pubblicazione. Caricando contenuti, l\'utente concede a PitLap una licenza non esclusiva per visualizzarli all\'interno del servizio secondo le impostazioni di visibilità scelte. PitLap potrà limitare o rimuovere materiali illeciti, ingannevoli, lesivi o incompatibili con il progetto, senza obbligo di preavviso.';

  @override
  String get legalTermsSectionAvailabilityTitle =>
      'Disponibilità e moderazione';

  @override
  String get legalTermsSectionAvailabilityBody =>
      'Il servizio è fornito \'così com\'è\' e può evolvere, cambiare o subire interruzioni temporanee. Le informazioni su piste, eventi, negozi, servizi o presenze possono dipendere da dati inseriti da utenti, gestori o terze parti; PitLap non garantisce che siano sempre complete, aggiornate o prive di errori.';

  @override
  String get legalTermsSectionIPTitle => 'Proprietà intellettuale';

  @override
  String get legalTermsSectionIPBody =>
      'Il marchio, il design, il codice e i contenuti prodotti da PitLap sono di proprietà esclusiva del titolare o dei rispettivi autori. È vietata la riproduzione, distribuzione o utilizzo commerciale non autorizzato. I contenuti inseriti dagli utenti restano di proprietà dei rispettivi autori; PitLap ne detiene solo la licenza d\'uso strettamente necessaria al funzionamento del servizio.';

  @override
  String get legalTermsSectionLiabilityTitle => 'Limitazione di responsabilità';

  @override
  String get legalTermsSectionLiabilityBody =>
      'Nella misura consentita dalla legge, PitLap non è responsabile per danni diretti o indiretti derivanti dall\'uso o dall\'impossibilita\' di uso del servizio, da errori nelle informazioni fornite da utenti o terzi, da interruzioni del servizio o da accessi non autorizzati a causa di eventi fuori dal controllo ragionevole di PitLap. Questa limitazione non si applica in caso di dolo o colpa grave.';

  @override
  String get legalTermsSectionGoverningTitle =>
      'Legge applicabile e foro competente';

  @override
  String get legalTermsSectionGoverningBody =>
      'I presenti termini sono regolati dalla legge italiana. Per qualsiasi controversia relativa all\'uso del servizio, ove consentito dalla normativa applicabile, sarà competente in via esclusiva il foro del luogo di residenza o domicilio dell\'utente consumatore. Per gli utenti professionali il foro esclusivo sarà indicato nelle condizioni specifiche di utilizzo.';

  @override
  String get legalCookiesTitle => 'Cookie Policy';

  @override
  String get legalCookiesDescription =>
      'Informativa sull\'uso di cookie e tecnologie equivalenti sul sito web di PitLap.';

  @override
  String get legalCookiesSectionWhatTitle => 'Cosa sono i cookie';

  @override
  String get legalCookiesSectionWhatBody =>
      'I cookie sono piccoli file di testo che i siti web salvano sul dispositivo dell\'utente durante la navigazione. Vengono usati per far funzionare le pagine correttamente, ricordare le preferenze e, in alcuni casi, raccogliere dati statistici o di profilazione. Oltre ai cookie tradizionali, questa policy si applica a tecnologie equivalenti come token di sessione, identificatori locali e storage web.';

  @override
  String get legalCookiesSectionTechnicalTitle =>
      'Cookie tecnici e di sessione';

  @override
  String get legalCookiesSectionTechnicalBody =>
      'PitLap utilizza esclusivamente cookie tecnici strettamente necessari al funzionamento del servizio: token di autenticazione (sessione utente dopo il login via magic link), preferenze di lingua e impostazioni dell\'interfaccia. Questi cookie non richiedono il consenso dell\'utente ai sensi dell\'art. 122 D.Lgs. 196/2003 (Codice Privacy) e della normativa europea.';

  @override
  String get legalCookiesSectionAnalyticsTitle => 'Cookie analitici';

  @override
  String get legalCookiesSectionAnalyticsBody =>
      'Allo stato attuale PitLap non installa cookie analitici di terze parti. Qualora in futuro venissero introdotti strumenti di analisi dell\'utilizzo, questa policy verrà aggiornata con indicazione degli strumenti, dei dati raccolti, delle finalità e delle modalità per esprimere o revocare il consenso.';

  @override
  String get legalCookiesSectionMarketingTitle =>
      'Cookie di marketing e profilazione';

  @override
  String get legalCookiesSectionMarketingBody =>
      'PitLap non installa cookie di marketing o profilazione. Qualora venissero introdotti, saranno preceduti da una richiesta di consenso esplicita, specifica e revocabile in qualsiasi momento, in conformita\' con la normativa vigente.';

  @override
  String get legalCookiesSectionStatusTitle => 'Gestione delle preferenze';

  @override
  String get legalCookiesSectionStatusBody =>
      'Poiché PitLap utilizza solo cookie tecnici necessari, non è richiesto un banner di consenso obbligatorio. L\'utente può comunque eliminare i cookie salvati tramite le impostazioni del proprio browser o dispositivo. La rimozione dei cookie tecnici potrebbe impedire il corretto funzionamento del servizio (ad es. mantenimento della sessione di login).';

  @override
  String get magicLinkSent => 'Magic link inviato. Controlla la tua email.';

  @override
  String get nearbyDescription =>
      'Scopri piste aperte, negozi utili ed eventi vicini a te con una lettura rapida e concreta del territorio.';

  @override
  String get nearbyPlaceholderTitle => 'Discovery mista';

  @override
  String get nearbyPlaceholderBody =>
      'Questa schermata ospiterà lista ordinabile per distanza, filtri base e una vista mappa secondaria.';

  @override
  String get nearbyHeroTitle => 'Scegli dove muoverti con meno attrito';

  @override
  String get nearbyHeroBody =>
      'Qui la geolocalizzazione serve a supportare la decisione, non a complicarla: prima lista utile, poi mappa se davvero serve.';

  @override
  String get nearbyFlagTracks => 'Piste vicine';

  @override
  String get nearbyFlagShops => 'Negozi utili';

  @override
  String get nearbyFlagOutdoorFirst => 'Outdoor e indoor';

  @override
  String get nearbyHowItWorksTitle => 'Come dovrebbe funzionare';

  @override
  String get nearbyStepOneTitle => 'Posizione o città';

  @override
  String get nearbyStepOneBody =>
      'Partiamo da posizione attuale o città scelta dall\'utente, senza rendere la mappa obbligatoria.';

  @override
  String get nearbyStepTwoTitle => 'Lista prima della mappa';

  @override
  String get nearbyStepTwoBody =>
      'L\'utente vede subito piste e negozi utili, ordinati per distanza e contesto.';

  @override
  String get nearbyStepThreeTitle => 'Decisione rapida';

  @override
  String get nearbyStepThreeBody =>
      'Stato pista, servizi e specializzazione devono chiarire in pochi secondi dove conviene andare.';

  @override
  String get nearbyPreviewTitle => 'Subito vicino';

  @override
  String get nearbyPreviewTrackTitle => 'Offroad Parma';

  @override
  String get nearbyPreviewTrackSubtitle => 'Pista outdoor · 9 km';

  @override
  String get nearbyPreviewTrackBadge => 'Pista';

  @override
  String get nearbyPreviewTrackNote =>
      'Fondo asciutto, servizi chiave presenti, buona scelta per la giornata.';

  @override
  String get nearbyPreviewShopTitle => 'RC Parts Parma';

  @override
  String get nearbyPreviewShopSubtitle => 'Negozio · 11 km';

  @override
  String get nearbyPreviewShopBadge => 'Negozio';

  @override
  String get nearbyPreviewShopNote =>
      'Ricambi e supporto box se prima della pista ti manca qualcosa.';

  @override
  String get eventsDescription => 'Tutti gli eventi di PitLap';

  @override
  String get eventsPlaceholderTitle => 'Eventi MVP';

  @override
  String get eventsPlaceholderBody =>
      'Gli eventi resteranno leggeri: lista, dettaglio base e RSVP semplice dove serve.';

  @override
  String get eventsHeroTitle => 'Scopri cosa succede in pista';

  @override
  String get eventsHeroBody =>
      'Gare, prove libere, demo e ritrovi della community raccolti in un calendario semplice da consultare e pronto da condividere.';

  @override
  String get eventsPreviewTitle => 'Esempi di card evento';

  @override
  String get eventsDemoOneDate => 'Sab 9 Apr';

  @override
  String get eventsDemoOneTitle => 'Prove libere serali';

  @override
  String get eventsDemoOneLocation => 'MiniZ Hub Modena';

  @override
  String get eventsDemoOneNote =>
      'Sessione informale indoor con focus test gomme e setup.';

  @override
  String get eventsDemoTwoDate => 'Dom 17 Apr';

  @override
  String get eventsDemoTwoTitle => 'Giornata club offroad';

  @override
  String get eventsDemoTwoLocation => 'Offroad Parma';

  @override
  String get eventsDemoTwoNote =>
      'Apertura lunga con presenza prevista di piloti e area box attiva.';

  @override
  String get eventsBadgePractice => 'Prove';

  @override
  String get eventsBadgeRace => 'Club day';

  @override
  String get eventsDirectionTitle => 'Direzione consigliata';

  @override
  String get eventsDirectionBody =>
      'Prima elenco pulito con data, pista e contesto. RSVP e dettagli più ricchi arrivano dopo, solo se davvero utili.';

  @override
  String get eventsDetailTitle => 'Dettaglio evento';

  @override
  String get eventsDetailDescription =>
      'Scheda di riferimento per leggere un evento senza perdere il contesto della giornata.';

  @override
  String get eventsDetailOverviewTitle => 'Panoramica evento';

  @override
  String get eventsDetailTrackContext => 'Contesto pista';

  @override
  String get eventsDetailCommunity => 'Community';

  @override
  String get eventsDetailLightRsvp => 'RSVP leggero';

  @override
  String get garageDescription =>
      'Area personale per modelli, foto e visibilità pubblica opzionale.';

  @override
  String get garagePlaceholderTitle => 'Garage personale';

  @override
  String get garagePlaceholderBody =>
      'Questa area ospiterà elenco modelli, immagini, note e controlli di visibilità.';

  @override
  String get garageHeroTitle => 'Le tue build in evidenza';

  @override
  String get garageHeroBody =>
      'Vetrina personale per raccontare i tuoi modelli, con foto, dettagli tecnici leggeri e pubblicazione opzionale.';

  @override
  String get garageVisibilityPrivate => 'Privato di default';

  @override
  String get garageVisibilityPublic => 'Rendilo pubblico';

  @override
  String get garageBuildsTitle => 'Build recenti';

  @override
  String garageBuildsCount(Object count) {
    return '$count modelli in vetrina';
  }

  @override
  String get garageVisibilityTitle => 'Visibilita\' garage';

  @override
  String get garageVisibilityBody =>
      'Il garage nasce privato, ma ogni build può diventare pubblica quando l\'utente vuole mostrarla.';

  @override
  String get garageTogglePrivate => 'Privato';

  @override
  String get garageTogglePublic => 'Pubblico';

  @override
  String get garageBuildVisibilityTitle => 'Visibilita\' delle build';

  @override
  String get garageBuildVisibilityBody =>
      'Ogni modello può avere una visibilità diversa, così l\'utente decide cosa tenere personale e cosa mostrare agli altri.';

  @override
  String get garageBuildVisibilityPrivate => 'Build privata';

  @override
  String get garageBuildVisibilityPublic => 'Build pubblica';

  @override
  String get garageBuildOneName => 'XB8 nitro';

  @override
  String get garageBuildOneMeta => 'Buggy 1/8 · assetto terra';

  @override
  String get garageBuildTwoName => 'Mini-Z MR-03';

  @override
  String get garageBuildTwoMeta => 'Mini-Z · setup indoor';

  @override
  String get garageBuildThreeName => 'Crawler TRX-4';

  @override
  String get garageBuildThreeMeta => 'Scaler · trail weekend';

  @override
  String garagePhotoCount(Object count) {
    return '$count foto';
  }

  @override
  String get garageSpecMotor => 'Motore';

  @override
  String get garageSpecBattery => 'Batteria';

  @override
  String get garageSpecSurface => 'Superficie';

  @override
  String get garageNextStepTitle => 'Direzione consigliata';

  @override
  String get garageNextStepBody =>
      'Partire da garage privato con 3-5 build, foto cover, note rapide e toggle pubblico per singola build.';

  @override
  String get managerScreenTitle => 'Gestione pista';

  @override
  String get managerDescription =>
      'Area owner/manager per stato pista, servizi e dati essenziali.';

  @override
  String get managerPlaceholderTitle => 'Pannello gestore';

  @override
  String get managerPlaceholderBody =>
      'Qui arriveranno update stato, messaggi rapidi, servizi e gestione base eventi.';

  @override
  String get managerHeroTitle => 'Pochi strumenti, molto chiari';

  @override
  String get managerHeroBody =>
      'Il pannello gestore deve permettere aggiornamenti rapidi e affidabili, senza trasformare il gestore in un operatore di backoffice.';

  @override
  String get managerTodayTitle => 'Operazioni principali';

  @override
  String get managerActionStatusTitle => 'Aggiorna stato pista';

  @override
  String get managerActionStatusBody =>
      'Cambia rapidamente stato, messaggio e visibilità dell\'update.';

  @override
  String get managerActionServicesTitle => 'Servizi e disponibilità';

  @override
  String get managerActionServicesBody =>
      'Conferma servizi utili, condizioni box e piccoli dettagli operativi.';

  @override
  String get managerActionEventsTitle => 'Eventi e giornate speciali';

  @override
  String get managerActionEventsBody =>
      'Pubblica sessioni prova, gare o aperture straordinarie con poco attrito.';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminDescription =>
      'Pannello centrale per categorie, utenti, piste, negozi e monitoraggio.';

  @override
  String get adminHeroTitle => 'Centro di controllo PitLap';

  @override
  String get adminHeroBody =>
      'Area amministrativa per governare catalogo, ruoli, tassonomie, moderazione e monitoraggio operativo senza passare da query SQL.';

  @override
  String get adminAccessDeniedBody =>
      'Questa area è riservata agli account amministratori. Il ruolo reale verrà usato per abilitare o bloccare strumenti sensibili.';

  @override
  String get adminAccessDeniedCard =>
      'Se non sei admin puoi comunque vedere che questa area esiste, ma le azioni reali restano protette. Appena le ownership saranno più mature, l\'accesso verrà verificato anche lato backend.';

  @override
  String get adminUsersChip => 'Utenti';

  @override
  String get adminTracksChip => 'Piste';

  @override
  String get adminShopsChip => 'Negozi';

  @override
  String get adminModerationChip => 'Moderazione';

  @override
  String get adminOverviewTitle => 'Overview operativa';

  @override
  String get adminOverviewBody =>
      'Quadro sintetico delle entità chiave che l\'admin dovra\' controllare nella dashboard reale.';

  @override
  String get adminUsersMetric => 'Utenti';

  @override
  String get adminTracksMetric => 'Piste';

  @override
  String get adminShopsMetric => 'Negozi';

  @override
  String get adminEventsMetric => 'Eventi';

  @override
  String get adminCategoriesMetric => 'Categorie pista';

  @override
  String get adminOverviewFallback =>
      'Le metriche reali non sono ancora disponibili in questa istanza.';

  @override
  String get adminCategoriesTitle => 'Categorie e tassonomie';

  @override
  String get adminCategoriesBody =>
      'Prima bozza del configuratore per ampliare hobby e label pista senza toccare SQL a mano.';

  @override
  String get adminHobbyCategoriesTitle => 'Categorie hobby';

  @override
  String get adminHobbyCategoriesBody =>
      'Bozza locale utile a validare struttura e tono del configuratore hobby prima del database definitivo.';

  @override
  String get adminTrackLabelCategoriesTitle => 'Categorie label pista';

  @override
  String get adminTrackCategoriesBody =>
      'Questa sezione è collegata alle categorie pista reali presenti a database quando lo schema remoto è allineato.';

  @override
  String get adminAddHobbyCategory => 'Nuova categoria hobby';

  @override
  String get adminAddTrackLabelCategory => 'Nuova categoria label pista';

  @override
  String get adminAddGenericAction => 'Aggiungi';

  @override
  String get adminTrackCategoriesEmpty =>
      'Nessuna categoria pista disponibile.';

  @override
  String get adminTrackCategoriesUnavailable =>
      'Le categorie pista non sono ancora leggibili da questa istanza.';

  @override
  String get adminCategorySaved => 'Categoria salvata.';

  @override
  String get adminCategoryDeleted => 'Categoria rimossa.';

  @override
  String adminCategorySaveError(Object error) {
    return 'Impossibile salvare la categoria: $error';
  }

  @override
  String adminCategoryDeleteError(Object error) {
    return 'Impossibile rimuovere la categoria: $error';
  }

  @override
  String get adminEntitiesTitle => 'Entita\' gestite';

  @override
  String get adminEntitiesBody =>
      'Blocchi che evolveranno in pannelli dedicati per utenti, piste, negozi, media e moderazione.';

  @override
  String get adminShopsCardTitle => 'Negozi';

  @override
  String get adminShopsCardBody =>
      'Crea, modifica, disattiva e collega negozi a piste o proprietari.';

  @override
  String get adminTracksCardTitle => 'Piste';

  @override
  String get adminTracksCardBody =>
      'Gestisci anagrafiche pista, ownership, servizi, label e media.';

  @override
  String get adminUsersCardTitle => 'Utenti';

  @override
  String get adminUsersCardBody =>
      'Consulta profili, ruoli, garage, eventi e stato generale dell\'account.';

  @override
  String get adminMonitoringTitle => 'Dashboard e monitoraggio';

  @override
  String get adminMonitoringBody =>
      'Spazio per i dati che serviranno davvero all\'admin: volumi, funnel, moderazione, media e pagine visitate.';

  @override
  String get adminVisitedPagesMetric => 'Pagine visitate';

  @override
  String get adminVisitedPagesPending => 'Da collegare';

  @override
  String get adminCompletedLoginsMetric => 'Login completati';

  @override
  String get adminModerationQueueMetric => 'Media da moderare';

  @override
  String get adminOpenReportsMetric => 'Segnalazioni aperte';

  @override
  String get adminUsersPreviewTitle => 'Utenti recenti';

  @override
  String get adminUsersPreviewBody =>
      'Prima lettura sintetica del catalogo utenti attivo in questa istanza.';

  @override
  String get adminUsersPreviewEmpty => 'Nessun utente disponibile.';

  @override
  String get adminUsersPreviewUnavailable =>
      'L\'anteprima utenti non è disponibile in questo momento.';

  @override
  String get adminImpersonationTitle => 'Impersonifica ruolo';

  @override
  String get adminImpersonationBody =>
      'Strumento di test locale per simulare il comportamento dei permessi senza cambiare davvero il tuo account su database.';

  @override
  String get adminImpersonationInactive => 'Stai usando il tuo ruolo reale.';

  @override
  String adminImpersonationActive(Object role) {
    return 'Stai testando l\'app come $role.';
  }

  @override
  String adminImpersonationBanner(Object role) {
    return 'Impersonificazione attiva: stai usando il ruolo $role per i test UI.';
  }

  @override
  String get adminImpersonationStop => 'Esci';

  @override
  String get adminRoleUser => 'Utente';

  @override
  String get adminRoleShopOwner => 'Negozio';

  @override
  String get adminRoleTrackOrganizer => 'Organizzatore pista';

  @override
  String get adminRoleAdmin => 'Admin reale';

  @override
  String get managerGovernanceTitle => 'Principio di governance';

  @override
  String get managerGovernanceBody =>
      'La parte gestore deve restare sobria, veloce e tracciabile. Ogni aggiornamento deve migliorare la fiducia dell\'utente finale, non complicare il lavoro del club.';

  @override
  String get profileDescription =>
      'Profilo pilota con preferenze, privacy e collegamento al garage.';

  @override
  String get profilePlaceholderTitle => 'Profilo personale';

  @override
  String get profilePlaceholderBody =>
      'Qui imposteremo lingua, identità, avatar e visibilità del profilo pubblico.';

  @override
  String get profileIdentityTitle => 'Identità profilo';

  @override
  String get profileIdentityBody =>
      'Base account sobria, utile a discovery, garage e relazioni future senza forzare dinamiche social invasive.';

  @override
  String get profileFieldFirstName => 'Nome';

  @override
  String get profileFieldLastName => 'Cognome';

  @override
  String get profileFieldNickname => 'Soprannome';

  @override
  String get profileFieldLocation => 'Luogo';

  @override
  String get profileFieldYearsInHobby => 'Anni di modellismo';

  @override
  String get profileVisibleName => 'Nome visibile';

  @override
  String get profileCurrentEmail => 'Email attuale';

  @override
  String get profilePreferredLanguage => 'Lingua preferita';

  @override
  String get profileAccountStatus => 'Stato account';

  @override
  String get profileAccountStatusActive => 'Attivo';

  @override
  String get profileAccountStatusGuest => 'Non autenticato';

  @override
  String get profileAccountSnapshotTitle => 'Snapshot account';

  @override
  String get profileAccountSnapshotBody =>
      'Una lettura rapida delle impostazioni account, utile prima di aprire le azioni sensibili.';

  @override
  String get profileEditBasics => 'Modifica dati base';

  @override
  String get profileSaveBasics => 'Salva dati base';

  @override
  String get profileCancelEdit => 'Annulla modifica';

  @override
  String get profileSavedMessage => 'Dati base del profilo salvati.';

  @override
  String get profileEditHint =>
      'In questa prima fase puoi salvare nome visibile e lingua preferita. Gli altri dati arriveranno nel flusso onboarding.';

  @override
  String get profileEditableFieldsComingSoon =>
      'Nome, cognome, soprannome, luogo e anni di modellismo saranno raccolti e salvati nel prossimo step onboarding.';

  @override
  String get profileNotSignedIn => 'Nessuna email attiva';

  @override
  String get profileSignedIn => 'Sessione attiva';

  @override
  String get profileSignedOut => 'Sessione assente';

  @override
  String get profileHobbiesTitle => 'Hobby e interessi';

  @override
  String get profileHobbyDrones => 'Droni';

  @override
  String get profileHobbyTrains => 'Treni';

  @override
  String get profilePreferencesHint =>
      'Queste preferenze serviranno per discovery, negozi, suggerimenti e futuri badge.';

  @override
  String get profilePrivacyTitle => 'Privacy e visibilità';

  @override
  String get profilePrivacyBody =>
      'Profilo privato di default, con parte pubblica attivabile solo se l\'utente vuole mostrarsi.';

  @override
  String get profileTogglePrivate => 'Profilo privato';

  @override
  String get profileTogglePublic => 'Profilo pubblico';

  @override
  String get profileGarageVisibilityTitle => 'Visibilita\' garage';

  @override
  String get profileGarageVisibilityBody =>
      'Il garage può restare privato nel suo insieme oppure aprirsi in modo selettivo, build per build.';

  @override
  String get profileConsentTitle => 'Consensi e documenti';

  @override
  String get profileConsentTerms => 'Termini di Servizio';

  @override
  String get profileConsentPrivacy => 'Informativa Privacy';

  @override
  String get profileConsentMarketing => 'Marketing email';

  @override
  String get profileConsentAccepted => 'Accettato';

  @override
  String get profileConsentNotAccepted => 'Non attivo';

  @override
  String get profileConsentLoading => 'Verifica consensi in corso...';

  @override
  String get profileConsentUnavailable =>
      'Consensi non ancora disponibili in questa sessione.';

  @override
  String profileConsentVersion(Object version) {
    return 'Versione documenti registrata: $version';
  }

  @override
  String profileConsentUpdatedAt(Object value) {
    return 'Aggiornato il $value';
  }

  @override
  String profileConsentSource(Object source) {
    return 'Origine: $source';
  }

  @override
  String get profileSettingsTitle => 'Impostazioni account';

  @override
  String get profileSettingsBody =>
      'Qui vivranno le operazioni sensibili dell\'account, separate dai dati pubblici del profilo.';

  @override
  String get profileChangeEmail => 'Cambio email';

  @override
  String get profileChangeEmailHint =>
      'Passaggio guidato con conferma sulla nuova email.';

  @override
  String get profileChangeEmailInfo =>
      'Il cambio email verrà collegato a un flusso dedicato con verifica e audit minimo.';

  @override
  String get profileResetPassword => 'Reset password';

  @override
  String get profileResetPasswordHint =>
      'Per magic link e recupero accesso quando il login rapido non basta.';

  @override
  String get profileResetPasswordInfo =>
      'Prepariamo questo flusso come azione sicura e separata dal login rapido.';

  @override
  String get profileSignOut => 'Esci';

  @override
  String get profileSignOutHint =>
      'Chiude la sessione su questo browser senza toccare i dati profilo.';

  @override
  String get profileSignedOutMessage => 'Sessione chiusa correttamente.';

  @override
  String get profileCloseAccount => 'Chiudi profilo';

  @override
  String get profileCloseAccountHint =>
      'Azione delicata da proteggere con conferma esplicita.';

  @override
  String get profileCloseAccountInfo =>
      'La chiusura account richiedera\' un passaggio dedicato con riepilogo dati, export e conferma finale.';

  @override
  String get profileSummaryTitle => 'Proposta iniziale';

  @override
  String get profileSummaryBody =>
      'Raccogliere nome, cognome, soprannome, luogo, anzianità nel modellismo, hobby principali, lingua preferita e collegamento al garage.';

  @override
  String get profileOnboardingAction => 'Apri onboarding';

  @override
  String get profileOnboardingActionHint =>
      'Bozza del primo accesso guidato per capire cosa chiedere subito.';

  @override
  String get profileFavoritesTitle => 'Preferiti';

  @override
  String get profileFavoritesBody =>
      'Hub personale per raccogliere piste seguite, build salvate, negozi utili e altri contenuti rilevanti.';

  @override
  String get profileFavoriteTracks => 'Piste salvate';

  @override
  String get profileFavoriteBuilds => 'Build salvate';

  @override
  String get profileFavoriteShops => 'Negozi salvati';

  @override
  String get profileCreatedEventsTitle => 'Eventi creati';

  @override
  String get profileLibraryTitle => 'Biblioteca digitale';

  @override
  String get profileLibraryBody =>
      'Raccolta progressiva dei contenuti che contano per il tuo percorso: preferiti, eventi e storico personale.';

  @override
  String entitySavedCount(Object count) {
    return '$count nei preferiti';
  }

  @override
  String get profileFavoritesHint =>
      'Questa sezione diventerà il punto di raccolta dei preferiti cross-prodotto, non solo delle piste.';

  @override
  String get profileFavoriteTracksEmpty => 'Nessuna pista salvata.';

  @override
  String get profileFavoriteBuildsEmpty => 'Nessuna build salvata.';

  @override
  String get profileFavoriteShopsEmpty => 'Nessun negozio salvato.';

  @override
  String get profileCreatedEventsEmpty => 'Nessun evento creato.';

  @override
  String get profileArchivedEventsEmpty => 'Nessun evento passato disponibile.';

  @override
  String get publicProfileTitle => 'Profilo pubblico';

  @override
  String publicProfileDescription(Object slug) {
    return 'Profilo pilota pubblico per $slug';
  }

  @override
  String get publicProfilePlaceholderTitle => 'Profilo opt-in';

  @override
  String get publicProfilePlaceholderBody =>
      'Il profilo pubblico restera\' sempre opzionale e separato dai dati account privati.';

  @override
  String get shopDetailTitle => 'Dettaglio negozio';

  @override
  String shopDetailDescription(Object shopName) {
    return '$shopName';
  }

  @override
  String get shopPlaceholderTitle => 'Negozio';

  @override
  String get shopPlaceholderBody =>
      'Qui troveremo identità, distanza, categorie principali e contatti essenziali.';

  @override
  String get shopsDescription =>
      'Trova il negozio più vicino a te e scopri specializzazioni utili.';

  @override
  String get shopDemoName => 'RC Parts Parma';

  @override
  String get shopDemoSubtitle => 'Ricambi, elettronica, supporto box';

  @override
  String get shopSecondaryName => 'Mini Garage Modena';

  @override
  String get shopSecondarySubtitle => 'Mini-Z, gomme, setup indoor';

  @override
  String shopDistance(Object distance) {
    return '$distance km';
  }

  @override
  String get shopOpenNow => 'Aperto ora';

  @override
  String get shopCallButton => 'Chiama';

  @override
  String get shopDirectionsButton => 'Indicazioni';

  @override
  String get shopDetailHeroBody =>
      'Scheda pratica per trovare subito specializzazione, servizi utili, contatti e tutto quello che serve prima di passare in negozio.';

  @override
  String get shopSpecialtiesTitle => 'Specialità';

  @override
  String get shopServicesTitle => 'Servizi in negozio';

  @override
  String get shopHoursTitle => 'Orari';

  @override
  String get shopContactsTitle => 'Contatti';

  @override
  String get shopNotesTitle => 'Perché è utile';

  @override
  String get shopNotesBody =>
      'Contesto semplice e professionale: niente rumore promozionale, solo informazioni chiare e affidabili per il modellista.';

  @override
  String get shopEditAction => 'Modifica negozio';

  @override
  String get shopEditCancel => 'Chiudi modifica';

  @override
  String get shopEditSave => 'Salva modifiche';

  @override
  String get shopEditSavedMessage => 'Modifiche negozio salvate su database.';

  @override
  String get shopEditNameLabel => 'Nome negozio';

  @override
  String get shopEditSubtitleLabel => 'Sottotitolo';

  @override
  String get shopEditImageUrlLabel => 'Immagine copertina (URL)';

  @override
  String get shopImageUploadAction => 'Carica cover';

  @override
  String get shopGalleryUploadAction => 'Aggiungi immagini galleria';

  @override
  String get shopGalleryFieldLabel => 'Galleria immagini (una per riga)';

  @override
  String shopGalleryLimitHint(Object count, Object max) {
    return 'Galleria: $count/$max immagini';
  }

  @override
  String get shopEditHoursLabel => 'Orari';

  @override
  String get shopEditContactsLabel => 'Contatti';

  @override
  String get shopEditNotesLabel => 'Note operative';

  @override
  String get shopImagePreviewUnavailable =>
      'Anteprima immagine non disponibile';

  @override
  String get shopProfileModeTitle => 'Dati negozio';

  @override
  String get shopProfileModeBody =>
      'Compila i dati che appariranno sulla scheda pubblica del tuo negozio.';

  @override
  String get shopServicePickup => 'Ritiro rapido';

  @override
  String get shopServiceBench => 'Supporto box';

  @override
  String get shopServiceElectronics => 'Elettronica';

  @override
  String get shopSpecialtyBuggy => 'Buggy 1/8';

  @override
  String get shopSpecialtyMiniZ => 'Mini-Z';

  @override
  String get shopSpecialtyBatteries => 'Batterie e carica';

  @override
  String get externalLinksTitle => 'Link e canali';

  @override
  String get externalLinksProfileBody =>
      'Aggiungi solo canali che vuoi rendere pubblici sul tuo profilo.';

  @override
  String get externalLinksShopBody =>
      'Canali ufficiali del negozio: sito, social, video o chat operative.';

  @override
  String get externalLinksTrackBody =>
      'Canali ufficiali della pista: sito, social, streaming gare o gruppi community.';

  @override
  String get externalLinksEmpty => 'Nessun link pubblico aggiunto.';

  @override
  String get externalLinksAddAction => 'Aggiungi link';

  @override
  String get externalLinksAddTitle => 'Aggiungi un link esterno';

  @override
  String get externalLinksProviderLabel => 'Canale';

  @override
  String get externalLinksLabelField => 'Alias / etichetta visibile';

  @override
  String get externalLinksUrlField => 'URL';

  @override
  String get externalLinksUrlHint =>
      'Puoi incollare anche il link senza https://, ci pensiamo noi.';

  @override
  String get externalLinksInvalidUrlError =>
      'Questo link non sembra valido. Prova con un indirizzo tipo instagram.com/nome o https://tuosito.it.';

  @override
  String get externalLinksPublicToggle => 'Rendi pubblico';

  @override
  String get externalLinksSaveAction => 'Salva link';

  @override
  String get externalLinkProviderWebsite => 'Sito web';

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
      'Contributo utente moderato per piste, spot, bashing o negozi.';

  @override
  String get submissionHeroTitle => 'Aiutaci ad allargare la mappa reale';

  @override
  String get submissionHeroBody =>
      'Le segnalazioni utente servono a far emergere piste, spot e negozi utili senza degradare il catalogo pubblico.';

  @override
  String get submissionTypeLabel => 'Tipologia';

  @override
  String get submissionTypeTrack => 'Circuito';

  @override
  String get submissionTypeSpot => 'Spot / Bashing';

  @override
  String get submissionTypeShop => 'Negozio';

  @override
  String get submissionPlaceName => 'Nome luogo';

  @override
  String get submissionCity => 'Città';

  @override
  String get submissionDescription => 'Descrizione';

  @override
  String get submissionWhatHelpsTitle => 'Cosa aiuta davvero la revisione';

  @override
  String get submissionWhatHelpsBody =>
      'Nome riconoscibile, città corretta, descrizione sintetica e qualche dettaglio pratico aumentano molto la qualità della segnalazione.';

  @override
  String get submissionReviewHint =>
      'Le segnalazioni non entrano automaticamente nel catalogo pubblico: passano sempre da revisione.';

  @override
  String get submissionSendButton => 'Invia segnalazione';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get onboardingDescription =>
      'Primo accesso guidato per capire cosa chiedere subito e cosa lasciare facoltativo.';

  @override
  String get onboardingHeroTitle => 'Primo accesso leggero, ma utile';

  @override
  String get onboardingHeroBody =>
      'L\'onboarding deve aiutare PitLap a capire hobby, contesto e preferenze senza trasformare la registrazione in un questionario pesante.';

  @override
  String get onboardingStepOneTitle => '1. Dati essenziali';

  @override
  String get onboardingStepOneBody =>
      'Email, lingua, accettazione documenti e poco altro. Serve iniziare senza attrito.';

  @override
  String get onboardingStepTwoTitle => '2. Identità modellista';

  @override
  String get onboardingStepTwoBody =>
      'Soprannome, luogo, anni di modellismo e una bio breve opzionale.';

  @override
  String get onboardingStepThreeTitle => '3. Hobby e interessi';

  @override
  String get onboardingStepThreeBody =>
      'Preferenze come buggy, Mini-Z, droni o treni aiutano discovery, negozi e suggerimenti.';

  @override
  String get onboardingChecklistTitle => 'Dati da raccogliere';

  @override
  String get onboardingChecklistBody =>
      'Checklist iniziale per decidere cosa chiedere subito, cosa rendere opzionale e cosa spostare più avanti.';

  @override
  String get onboardingFieldEmail => 'Email account';

  @override
  String get onboardingFieldLanguage => 'Lingua preferita';

  @override
  String get onboardingFieldNickname => 'Soprannome';

  @override
  String get onboardingFieldLocation => 'Luogo / città';

  @override
  String get onboardingFieldYears => 'Anni di modellismo';

  @override
  String get onboardingFieldHobbies => 'Hobby e interessi';

  @override
  String get onboardingFieldMarketing => 'Marketing opzionale';

  @override
  String get onboardingFieldAccountType => 'Tipo account';

  @override
  String onboardingAccountTypeActive(Object role) {
    return 'Tipo account attivo: $role';
  }

  @override
  String get onboardingPrinciplesTitle => 'Principi di design';

  @override
  String get onboardingPrincipleOne =>
      'Non chiedere tutto subito: partire con il minimo indispensabile.';

  @override
  String get onboardingPrincipleTwo =>
      'Rendere opzionali i dati che non servono al primo utilizzo.';

  @override
  String get onboardingPrincipleThree =>
      'Permettere di completare il profilo più tardi senza penalizzare l\'accesso.';

  @override
  String get onboardingNextStepTitle => 'Direzione consigliata';

  @override
  String get onboardingNextStepBody =>
      'Prima implementazione suggerita: login, consenso, lingua, soprannome e scelta hobby in un flusso di 2 step massimo.';

  @override
  String get noTracksMatchingFilters =>
      'Nessuna pista corrisponde ai filtri attivi.';

  @override
  String get profileBasicsTitle => 'Dati base';

  @override
  String get profileBasicsBody =>
      'Qui puoi aggiornare subito nome visibile, lingua e foto profilo. Il resto dei dati arrivera\' nel flusso onboarding.';

  @override
  String get profilePhotoUrl => 'Foto profilo (URL)';

  @override
  String get profilePhotoUrlHint =>
      'Incolla un link immagine per provare avatar e anteprima.';

  @override
  String get profilePhotoUrlSupportHint =>
      'Alcuni siti bloccano il caricamento diretto nel browser. In quel caso PitLap mostra automaticamente il fallback con iniziale.';

  @override
  String get eventsCreateAction => 'Crea evento';

  @override
  String get eventsCreatedByYouTitle => 'Prossimi eventi pubblici';

  @override
  String get eventsPublicBadge => 'Pubblico';

  @override
  String get eventsShareAction => 'Condividi';

  @override
  String get eventsShareCopied =>
      'Link evento copiato. Potremo collegarlo al pannello Condividi completo.';

  @override
  String get eventsArchiveTitle => 'Storico eventi';

  @override
  String get eventsBadgeCommunity => 'Community';

  @override
  String get eventsBadgeArchived => 'Archivio';

  @override
  String get eventsCreateDialogTitle => 'Crea un nuovo evento';

  @override
  String get eventsCreateTitleLabel => 'Titolo evento';

  @override
  String get eventsCreateLocationLabel => 'Luogo';

  @override
  String get eventsCreateVenueLabel => 'Luogo / pista / negozio';

  @override
  String get eventsCreateNoteLabel => 'Nota rapida';

  @override
  String get eventsCreateImageAction => 'Carica foto evento';

  @override
  String get eventsCreateImageLoaded => 'Foto evento pronta';

  @override
  String get imageUploadTooLargeMessage =>
      'Questa immagine è troppo pesante per l\'anteprima. Prova con una foto sotto i 5 MB o comprimila prima di caricarla.';

  @override
  String get imageUploadUnreadableMessage =>
      'Non riesco a leggere questa immagine. Prova con JPG, PNG o WebP.';

  @override
  String get eventsCreateDateLabel => 'Data';

  @override
  String get eventsCreateSave => 'Salva evento';

  @override
  String get eventsCreateSuccess =>
      'Evento pubblico creato. Ora compare nella lista eventi della community.';

  @override
  String get eventsCreateDefaultNote => 'Evento creato dalla community PitLap.';

  @override
  String get eventsEmptyCreatedTitle => 'Nessun evento creato ancora';

  @override
  String get eventsEmptyCreatedBody =>
      'Crea il primo evento per provare il flusso community e vedere come potrebbe apparire agli altri utenti.';

  @override
  String get clearSearchAction => 'Pulisci ricerca';

  @override
  String get profileQuickLinksTitle => 'Accessi rapidi';

  @override
  String get profileQuickLinksBody =>
      'Collegamenti veloci alle aree che stai già usando nei test.';

  @override
  String garagePublicBuildsCount(int count) {
    return '$count build pubbliche';
  }

  @override
  String get garageAddBuildAction => 'Aggiungi build';

  @override
  String get garageSetPrivateAction => 'Rendi garage privato';

  @override
  String get garageSetPublicAction => 'Rendi garage pubblico';

  @override
  String get garageBuildsTestingHint =>
      'Qui puoi già testare creazione build, immagine via URL e visibilità pubblica o privata.';

  @override
  String get garageBuildTitleLabel => 'Nome build';

  @override
  String get garageBuildMetaLabel => 'Categoria / piattaforma';

  @override
  String get garageBuildImageUrlLabel => 'Foto build (URL)';

  @override
  String get garageImageUploadAction => 'Carica immagine';

  @override
  String get garageImageLoaded => 'Immagine pronta';

  @override
  String get garageBuildSpecsHint => 'Specifiche rapide separate da virgola';

  @override
  String get garageBuildPublicToggle => 'Rendi pubblica questa build';

  @override
  String get garageBuildSaveAction => 'Salva build';

  @override
  String get garageBuildCreatedMessage =>
      'Build aggiunta localmente al garage.';

  @override
  String get garageBuildUpdatedMessage => 'Build aggiornata.';

  @override
  String get garageEditBuildAction => 'Modifica build';

  @override
  String garageBuildMaxImagesReached(int max) {
    return 'Puoi aggiungere fino a $max immagini per build.';
  }

  @override
  String garageBuildImagesHelper(int max) {
    return 'Puoi aggiungere fino a $max immagini. La prima immagine viene usata come anteprima della build.';
  }

  @override
  String garageBuildImagesCount(int count, int max) {
    return '$count/$max immagini';
  }

  @override
  String get processingUploadImages => 'Sto preparando le immagini';

  @override
  String get processingUploadCover => 'Sto preparando la cover';

  @override
  String get processingUploadGallery => 'Sto preparando la galleria';

  @override
  String get processingUploadEventImage => 'Sto preparando la foto evento';

  @override
  String get eventsOpenAction => 'Apri evento';

  @override
  String get nearbySearchHint => 'Cerca una pista o un negozio vicino...';

  @override
  String get nearbyFilterAll => 'Tutto';

  @override
  String get nearbyFilterTracks => 'Piste';

  @override
  String get nearbyFilterShops => 'Negozi';

  @override
  String get nearbyNoResults => 'Nessun risultato per i filtri attivi.';

  @override
  String get nearbyNearMeButton => 'Vicino a me';

  @override
  String get nearbyOpenInMap => 'Apri in mappa';

  @override
  String get nearbyOpenTrack => 'Apri pista';

  @override
  String get nearbyOpenShop => 'Apri negozio';

  @override
  String get nearbyNoServices => 'Nessun servizio';

  @override
  String nearbyServicesCount(int count) {
    return '$count servizi';
  }

  @override
  String get nearbyShopGeneric => 'Negozio RC';

  @override
  String get nearbyStatusUpdating => 'Aggiornamento in corso';

  @override
  String get shopSearchHint => 'Cerca negozio o specializzazione...';

  @override
  String get shopSaveAction => 'Salva negozio';

  @override
  String get shopSavedAction => 'Negozio salvato';

  @override
  String get shopOpenDetailsAction => 'Apri scheda';

  @override
  String get shopNoResults => 'Nessun negozio corrisponde alla ricerca.';

  @override
  String get managerStatusLabel => 'Stato pista di oggi';

  @override
  String get managerToggleCompressor => 'Aria compressa disponibile';

  @override
  String get managerToggleBathrooms => 'Bagni disponibili';

  @override
  String get managerToggleEventReady => 'Evento serale confermato';

  @override
  String get managerStatusMessageLabel => 'Messaggio rapido';

  @override
  String get managerSaveAction => 'Salva aggiornamento';

  @override
  String get managerSaveSuccess =>
      'Aggiornamento locale salvato. Possiamo usare questo flusso per definire il pannello gestore.';

  @override
  String managerSaveSuccessTrack(Object trackName) {
    return 'Aggiornamento pista salvato per $trackName.';
  }

  @override
  String get managerNoTracksTitle => 'Nessuna pista assegnata';

  @override
  String get managerNoTracksBody =>
      'Questo account può entrare nell\'area gestione, ma al momento non risulta assegnato a nessuna pista. Il prossimo passo è collegare ownership e pannello operativo.';

  @override
  String get managerAssignedTracksTitle => 'Piste assegnate';

  @override
  String get managerAssignedTracksBody =>
      'Questa lista arriva dalla relazione reale `track_managers`, non solo dal ruolo globale dell\'account.';

  @override
  String managerEditingTrack(Object trackName) {
    return 'Stai preparando un aggiornamento per $trackName.';
  }

  @override
  String get submissionImageUrlLabel => 'Foto o copertina (URL)';

  @override
  String get submissionMissingFields => 'Compila almeno nome luogo e città.';

  @override
  String submissionSendSuccess(String name, String city) {
    return 'Segnalazione pronta: $name a $city.';
  }

  @override
  String get pitcoinBalanceTitle => 'PitCoin';

  @override
  String get pitcoinBalanceSubtitle =>
      'Quanto sei attivo e utile alla community PitLap.';

  @override
  String pitcoinBalanceDeltaWeek(int count) {
    return '+$count questa settimana';
  }

  @override
  String get pitcoinHistoryAction => 'Vedi storico';

  @override
  String get pitcoinHistoryTitle => 'Storico attività';

  @override
  String get pitcoinHistorySubtitle =>
      'Tutte le tue azioni che hanno generato PitCoin.';

  @override
  String get pitcoinHistoryEmpty =>
      'Nessuna attività registrata ancora. Inizia a contribuire alla community e i tuoi PitCoin appariranno qui.';

  @override
  String get pitcoinHistoryLoadMore => 'Carica altre';

  @override
  String get pitcoinBadgesTitle => 'Trofei';

  @override
  String get pitcoinBadgesSubtitle => 'Le tappe del tuo cammino su PitLap.';

  @override
  String get pitcoinBadgesEmpty => 'Nessun trofeo sbloccato ancora.';

  @override
  String get pitcoinBadgeLocked => 'Da sbloccare';

  @override
  String pitcoinBadgeUnlockedOn(String date) {
    return 'Ottenuto il $date';
  }

  @override
  String get pitcoinTierBronze => 'Bronzo';

  @override
  String get pitcoinTierSilver => 'Argento';

  @override
  String get pitcoinTierGold => 'Oro';

  @override
  String get pitcoinTierSpecial => 'Speciale';

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
}
