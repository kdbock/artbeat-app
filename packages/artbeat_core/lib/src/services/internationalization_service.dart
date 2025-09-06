import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive internationalization service for ARTbeat platform
/// Supports multiple languages, localization, and cultural adaptations
class InternationalizationService {
  static final InternationalizationService _instance =
      InternationalizationService._internal();
  factory InternationalizationService() => _instance;
  InternationalizationService._internal();

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (US)
    Locale('es', 'ES'), // Spanish (Spain)
    Locale('fr', 'FR'), // French (France)
    Locale('de', 'DE'), // German (Germany)
    Locale('it', 'IT'), // Italian (Italy)
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('ja', 'JP'), // Japanese (Japan)
    Locale('ko', 'KR'), // Korean (South Korea)
    Locale('zh', 'CN'), // Chinese (Simplified)
    Locale('ar', 'SA'), // Arabic (Saudi Arabia)
  ];

  // Current locale and translations
  Locale _currentLocale = const Locale('en', 'US');
  Map<String, String> _translations = {};
  Map<String, Map<String, String>> _allTranslations = {};

  // Locale change notifier
  final StreamController<Locale> _localeController =
      StreamController<Locale>.broadcast();
  Stream<Locale> get localeStream => _localeController.stream;

  /// Initialize internationalization service
  Future<void> initialize([Locale? locale]) async {
    await _loadAllTranslations();
    await setLocale(locale ?? _currentLocale);
  }

  /// Load all translations
  Future<void> _loadAllTranslations() async {
    for (final locale in supportedLocales) {
      final localeKey = '${locale.languageCode}_${locale.countryCode}';
      try {
        final jsonString = await rootBundle.loadString(
          'assets/i18n/$localeKey.json',
        );
        final Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;
        _allTranslations[localeKey] = jsonMap.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      } catch (e) {
        // If translation file doesn't exist, use default English translations
        debugPrint('Translation file not found for $localeKey, using defaults');
        _allTranslations[localeKey] = _getDefaultTranslations(locale);
      }
    }
  }

  /// Get default translations for a locale
  Map<String, String> _getDefaultTranslations(Locale locale) {
    // This would typically be loaded from a comprehensive translation database
    // For now, providing basic translations for key languages
    switch (locale.languageCode) {
      case 'es':
        return _getSpanishTranslations();
      case 'fr':
        return _getFrenchTranslations();
      case 'de':
        return _getGermanTranslations();
      case 'it':
        return _getItalianTranslations();
      case 'pt':
        return _getPortugueseTranslations();
      case 'ja':
        return _getJapaneseTranslations();
      case 'ko':
        return _getKoreanTranslations();
      case 'zh':
        return _getChineseTranslations();
      case 'ar':
        return _getArabicTranslations();
      default:
        return _getEnglishTranslations();
    }
  }

  /// Set current locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      locale = const Locale('en', 'US');
    }

    _currentLocale = locale;
    final localeKey = '${locale.languageCode}_${locale.countryCode}';
    _translations = _allTranslations[localeKey] ?? _getEnglishTranslations();

    _localeController.add(locale);
  }

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get translation for key
  String translate(String key, {Map<String, String>? params}) {
    String translation = _translations[key] ?? key;

    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  /// Get translation with plural support
  String translatePlural(String key, int count, {Map<String, String>? params}) {
    final pluralKey = count == 1 ? '${key}_singular' : '${key}_plural';
    String translation = _translations[pluralKey] ?? _translations[key] ?? key;

    // Replace count parameter
    translation = translation.replaceAll('{count}', count.toString());

    // Replace other parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  /// Get localized date format
  String formatDate(DateTime date, {DateFormat format = DateFormat.medium}) {
    switch (_currentLocale.languageCode) {
      case 'es':
        return _formatSpanishDate(date, format);
      case 'fr':
        return _formatFrenchDate(date, format);
      case 'de':
        return _formatGermanDate(date, format);
      case 'ja':
        return _formatJapaneseDate(date, format);
      case 'ar':
        return _formatArabicDate(date, format);
      default:
        return _formatEnglishDate(date, format);
    }
  }

  /// Get localized number format
  String formatNumber(
    num number, {
    NumberFormat format = NumberFormat.decimal,
  }) {
    switch (_currentLocale.languageCode) {
      case 'es':
      case 'fr':
      case 'de':
      case 'it':
        return number.toString().replaceAll('.', ',');
      case 'ja':
      case 'ko':
      case 'zh':
        return _formatAsianNumber(number, format);
      case 'ar':
        return _formatArabicNumber(number, format);
      default:
        return number.toString();
    }
  }

  /// Get localized currency format
  String formatCurrency(double amount, {String? currencyCode}) {
    currencyCode ??= _getDefaultCurrency();

    switch (_currentLocale.languageCode) {
      case 'es':
        return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
      case 'fr':
        return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
      case 'de':
        return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
      case 'ja':
        return '¥${amount.toStringAsFixed(0)}';
      case 'ko':
        return '₩${amount.toStringAsFixed(0)}';
      case 'zh':
        return '¥${amount.toStringAsFixed(2)}';
      case 'ar':
        return '${amount.toStringAsFixed(2)} ر.س';
      default:
        return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Get text direction for current locale
  TextDirection get textDirection {
    return _currentLocale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Check if current locale is RTL
  bool get isRTL => textDirection == TextDirection.rtl;

  /// Get locale-specific font family
  String? get fontFamily {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'NotoSansArabic';
      case 'ja':
        return 'NotoSansJP';
      case 'ko':
        return 'NotoSansKR';
      case 'zh':
        return 'NotoSansSC';
      default:
        return null;
    }
  }

  /// Get default currency for locale
  String _getDefaultCurrency() {
    switch (_currentLocale.countryCode) {
      case 'US':
        return 'USD';
      case 'ES':
      case 'FR':
      case 'DE':
      case 'IT':
        return 'EUR';
      case 'BR':
        return 'BRL';
      case 'JP':
        return 'JPY';
      case 'KR':
        return 'KRW';
      case 'CN':
        return 'CNY';
      case 'SA':
        return 'SAR';
      default:
        return 'USD';
    }
  }

  // Date formatting methods
  String _formatEnglishDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.month}/${date.day}/${date.year}';
      case DateFormat.medium:
        return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      case DateFormat.long:
        return '${_getDayName(date.weekday)}, ${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _formatSpanishDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.day}/${date.month}/${date.year}';
      case DateFormat.medium:
        return '${date.day} de ${_getSpanishMonthName(date.month)} de ${date.year}';
      case DateFormat.long:
        return '${_getSpanishDayName(date.weekday)}, ${date.day} de ${_getSpanishMonthName(date.month)} de ${date.year}';
    }
  }

  String _formatFrenchDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.day}/${date.month}/${date.year}';
      case DateFormat.medium:
        return '${date.day} ${_getFrenchMonthName(date.month)} ${date.year}';
      case DateFormat.long:
        return '${_getFrenchDayName(date.weekday)} ${date.day} ${_getFrenchMonthName(date.month)} ${date.year}';
    }
  }

  String _formatGermanDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.day}.${date.month}.${date.year}';
      case DateFormat.medium:
        return '${date.day}. ${_getGermanMonthName(date.month)} ${date.year}';
      case DateFormat.long:
        return '${_getGermanDayName(date.weekday)}, ${date.day}. ${_getGermanMonthName(date.month)} ${date.year}';
    }
  }

  String _formatJapaneseDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.year}/${date.month}/${date.day}';
      case DateFormat.medium:
        return '${date.year}年${date.month}月${date.day}日';
      case DateFormat.long:
        return '${date.year}年${date.month}月${date.day}日 (${_getJapaneseDayName(date.weekday)})';
    }
  }

  String _formatArabicDate(DateTime date, DateFormat format) {
    switch (format) {
      case DateFormat.short:
        return '${date.day}/${date.month}/${date.year}';
      case DateFormat.medium:
        return '${date.day} ${_getArabicMonthName(date.month)} ${date.year}';
      case DateFormat.long:
        return '${_getArabicDayName(date.weekday)}، ${date.day} ${_getArabicMonthName(date.month)} ${date.year}';
    }
  }

  // Number formatting methods
  String _formatAsianNumber(num number, NumberFormat format) {
    // Asian number formatting (e.g., 10,000 = 1万 in Japanese/Chinese)
    if (number >= 10000) {
      final wan = number / 10000;
      return '${wan.toStringAsFixed(1)}万';
    }
    return number.toString();
  }

  String _formatArabicNumber(num number, NumberFormat format) {
    // Arabic numerals (٠١٢٣٤٥٦٧٨٩)
    final arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(i.toString(), arabicDigits[i]);
    }
    return result;
  }

  // Helper methods for month and day names
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getSpanishMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month - 1];
  }

  String _getSpanishDayName(int weekday) {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return days[weekday - 1];
  }

  String _getFrenchMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
  }

  String _getFrenchDayName(int weekday) {
    const days = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    return days[weekday - 1];
  }

  String _getGermanMonthName(int month) {
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return months[month - 1];
  }

  String _getGermanDayName(int weekday) {
    const days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return days[weekday - 1];
  }

  String _getJapaneseDayName(int weekday) {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return '${days[weekday - 1]}曜日';
  }

  String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  String _getArabicDayName(int weekday) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday - 1];
  }

  // Default translation maps
  Map<String, String> _getEnglishTranslations() {
    return {
      // Common UI elements
      'app_name': 'ARTbeat',
      'welcome': 'Welcome',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',

      // Navigation
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'help': 'Help',
      'about': 'About',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',

      // Art Walk
      'art_walk': 'Art Walk',
      'start_walk': 'Start Walk',
      'end_walk': 'End Walk',
      'distance': 'Distance',
      'duration': 'Duration',
      'artworks_viewed': 'Artworks Viewed',

      // Artwork
      'artwork': 'Artwork',
      'artworks': 'Artworks',
      'artist': 'Artist',
      'title': 'Title',
      'description': 'Description',
      'like': 'Like',
      'share': 'Share',
      'comment': 'Comment',
      'view_count': 'Views',

      // Community
      'community': 'Community',
      'post': 'Post',
      'posts': 'Posts',
      'follow': 'Follow',
      'unfollow': 'Unfollow',
      'followers': 'Followers',
      'following': 'Following',

      // Capture
      'capture': 'Capture',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'photo': 'Photo',
      'video': 'Video',
      'take_photo': 'Take Photo',
      'record_video': 'Record Video',

      // Plurals
      'artwork_singular': '{count} artwork',
      'artwork_plural': '{count} artworks',
      'follower_singular': '{count} follower',
      'follower_plural': '{count} followers',
    };
  }

  Map<String, String> _getSpanishTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'Bienvenido',
      'login': 'Iniciar Sesión',
      'logout': 'Cerrar Sesión',
      'register': 'Registrarse',
      'email': 'Correo Electrónico',
      'password': 'Contraseña',
      'confirm_password': 'Confirmar Contraseña',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'search': 'Buscar',
      'filter': 'Filtrar',
      'sort': 'Ordenar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'warning': 'Advertencia',
      'info': 'Información',
      'home': 'Inicio',
      'profile': 'Perfil',
      'settings': 'Configuración',
      'help': 'Ayuda',
      'about': 'Acerca de',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'art_walk': 'Paseo Artístico',
      'start_walk': 'Comenzar Paseo',
      'end_walk': 'Terminar Paseo',
      'distance': 'Distancia',
      'duration': 'Duración',
      'artworks_viewed': 'Obras Vistas',
      'artwork': 'Obra de Arte',
      'artworks': 'Obras de Arte',
      'artist': 'Artista',
      'title': 'Título',
      'description': 'Descripción',
      'like': 'Me Gusta',
      'share': 'Compartir',
      'comment': 'Comentar',
      'view_count': 'Visualizaciones',
      'community': 'Comunidad',
      'post': 'Publicación',
      'posts': 'Publicaciones',
      'follow': 'Seguir',
      'unfollow': 'Dejar de Seguir',
      'followers': 'Seguidores',
      'following': 'Siguiendo',
      'capture': 'Capturar',
      'camera': 'Cámara',
      'gallery': 'Galería',
      'photo': 'Foto',
      'video': 'Video',
      'take_photo': 'Tomar Foto',
      'record_video': 'Grabar Video',
      'artwork_singular': '{count} obra de arte',
      'artwork_plural': '{count} obras de arte',
      'follower_singular': '{count} seguidor',
      'follower_plural': '{count} seguidores',
    };
  }

  Map<String, String> _getFrenchTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'Bienvenue',
      'login': 'Se Connecter',
      'logout': 'Se Déconnecter',
      'register': 'S\'inscrire',
      'email': 'E-mail',
      'password': 'Mot de Passe',
      'confirm_password': 'Confirmer le Mot de Passe',
      'forgot_password': 'Mot de passe oublié?',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'sort': 'Trier',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'warning': 'Avertissement',
      'info': 'Information',
      'home': 'Accueil',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'help': 'Aide',
      'about': 'À Propos',
      'back': 'Retour',
      'next': 'Suivant',
      'previous': 'Précédent',
      'art_walk': 'Promenade Artistique',
      'start_walk': 'Commencer la Promenade',
      'end_walk': 'Terminer la Promenade',
      'distance': 'Distance',
      'duration': 'Durée',
      'artworks_viewed': 'Œuvres Vues',
      'artwork': 'Œuvre d\'Art',
      'artworks': 'Œuvres d\'Art',
      'artist': 'Artiste',
      'title': 'Titre',
      'description': 'Description',
      'like': 'J\'aime',
      'share': 'Partager',
      'comment': 'Commenter',
      'view_count': 'Vues',
      'community': 'Communauté',
      'post': 'Publication',
      'posts': 'Publications',
      'follow': 'Suivre',
      'unfollow': 'Ne Plus Suivre',
      'followers': 'Abonnés',
      'following': 'Abonnements',
      'capture': 'Capturer',
      'camera': 'Caméra',
      'gallery': 'Galerie',
      'photo': 'Photo',
      'video': 'Vidéo',
      'take_photo': 'Prendre une Photo',
      'record_video': 'Enregistrer une Vidéo',
      'artwork_singular': '{count} œuvre d\'art',
      'artwork_plural': '{count} œuvres d\'art',
      'follower_singular': '{count} abonné',
      'follower_plural': '{count} abonnés',
    };
  }

  Map<String, String> _getGermanTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'Willkommen',
      'login': 'Anmelden',
      'logout': 'Abmelden',
      'register': 'Registrieren',
      'email': 'E-Mail',
      'password': 'Passwort',
      'confirm_password': 'Passwort Bestätigen',
      'forgot_password': 'Passwort vergessen?',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'search': 'Suchen',
      'filter': 'Filtern',
      'sort': 'Sortieren',
      'loading': 'Laden...',
      'error': 'Fehler',
      'success': 'Erfolg',
      'warning': 'Warnung',
      'info': 'Information',
      'home': 'Startseite',
      'profile': 'Profil',
      'settings': 'Einstellungen',
      'help': 'Hilfe',
      'about': 'Über',
      'back': 'Zurück',
      'next': 'Weiter',
      'previous': 'Vorherige',
      'art_walk': 'Kunstspaziergang',
      'start_walk': 'Spaziergang Beginnen',
      'end_walk': 'Spaziergang Beenden',
      'distance': 'Entfernung',
      'duration': 'Dauer',
      'artworks_viewed': 'Kunstwerke Angesehen',
      'artwork': 'Kunstwerk',
      'artworks': 'Kunstwerke',
      'artist': 'Künstler',
      'title': 'Titel',
      'description': 'Beschreibung',
      'like': 'Gefällt mir',
      'share': 'Teilen',
      'comment': 'Kommentieren',
      'view_count': 'Aufrufe',
      'community': 'Gemeinschaft',
      'post': 'Beitrag',
      'posts': 'Beiträge',
      'follow': 'Folgen',
      'unfollow': 'Entfolgen',
      'followers': 'Follower',
      'following': 'Folge ich',
      'capture': 'Aufnehmen',
      'camera': 'Kamera',
      'gallery': 'Galerie',
      'photo': 'Foto',
      'video': 'Video',
      'take_photo': 'Foto Aufnehmen',
      'record_video': 'Video Aufnehmen',
      'artwork_singular': '{count} Kunstwerk',
      'artwork_plural': '{count} Kunstwerke',
      'follower_singular': '{count} Follower',
      'follower_plural': '{count} Follower',
    };
  }

  Map<String, String> _getItalianTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'Benvenuto',
      'login': 'Accedi',
      'logout': 'Esci',
      'register': 'Registrati',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Conferma Password',
      'forgot_password': 'Password dimenticata?',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'edit': 'Modifica',
      'search': 'Cerca',
      'filter': 'Filtra',
      'sort': 'Ordina',
      'loading': 'Caricamento...',
      'error': 'Errore',
      'success': 'Successo',
      'warning': 'Avviso',
      'info': 'Informazione',
      'home': 'Home',
      'profile': 'Profilo',
      'settings': 'Impostazioni',
      'help': 'Aiuto',
      'about': 'Informazioni',
      'back': 'Indietro',
      'next': 'Avanti',
      'previous': 'Precedente',
      'art_walk': 'Passeggiata Artistica',
      'start_walk': 'Inizia Passeggiata',
      'end_walk': 'Termina Passeggiata',
      'distance': 'Distanza',
      'duration': 'Durata',
      'artworks_viewed': 'Opere Viste',
      'artwork': 'Opera d\'Arte',
      'artworks': 'Opere d\'Arte',
      'artist': 'Artista',
      'title': 'Titolo',
      'description': 'Descrizione',
      'like': 'Mi Piace',
      'share': 'Condividi',
      'comment': 'Commenta',
      'view_count': 'Visualizzazioni',
      'community': 'Comunità',
      'post': 'Post',
      'posts': 'Post',
      'follow': 'Segui',
      'unfollow': 'Non Seguire',
      'followers': 'Follower',
      'following': 'Seguiti',
      'capture': 'Cattura',
      'camera': 'Fotocamera',
      'gallery': 'Galleria',
      'photo': 'Foto',
      'video': 'Video',
      'take_photo': 'Scatta Foto',
      'record_video': 'Registra Video',
      'artwork_singular': '{count} opera d\'arte',
      'artwork_plural': '{count} opere d\'arte',
      'follower_singular': '{count} follower',
      'follower_plural': '{count} follower',
    };
  }

  Map<String, String> _getPortugueseTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'Bem-vindo',
      'login': 'Entrar',
      'logout': 'Sair',
      'register': 'Registrar',
      'email': 'E-mail',
      'password': 'Senha',
      'confirm_password': 'Confirmar Senha',
      'forgot_password': 'Esqueceu a senha?',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'delete': 'Excluir',
      'edit': 'Editar',
      'search': 'Pesquisar',
      'filter': 'Filtrar',
      'sort': 'Ordenar',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',
      'warning': 'Aviso',
      'info': 'Informação',
      'home': 'Início',
      'profile': 'Perfil',
      'settings': 'Configurações',
      'help': 'Ajuda',
      'about': 'Sobre',
      'back': 'Voltar',
      'next': 'Próximo',
      'previous': 'Anterior',
      'art_walk': 'Caminhada Artística',
      'start_walk': 'Iniciar Caminhada',
      'end_walk': 'Terminar Caminhada',
      'distance': 'Distância',
      'duration': 'Duração',
      'artworks_viewed': 'Obras Visualizadas',
      'artwork': 'Obra de Arte',
      'artworks': 'Obras de Arte',
      'artist': 'Artista',
      'title': 'Título',
      'description': 'Descrição',
      'like': 'Curtir',
      'share': 'Compartilhar',
      'comment': 'Comentar',
      'view_count': 'Visualizações',
      'community': 'Comunidade',
      'post': 'Publicação',
      'posts': 'Publicações',
      'follow': 'Seguir',
      'unfollow': 'Deixar de Seguir',
      'followers': 'Seguidores',
      'following': 'Seguindo',
      'capture': 'Capturar',
      'camera': 'Câmera',
      'gallery': 'Galeria',
      'photo': 'Foto',
      'video': 'Vídeo',
      'take_photo': 'Tirar Foto',
      'record_video': 'Gravar Vídeo',
      'artwork_singular': '{count} obra de arte',
      'artwork_plural': '{count} obras de arte',
      'follower_singular': '{count} seguidor',
      'follower_plural': '{count} seguidores',
    };
  }

  Map<String, String> _getJapaneseTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'ようこそ',
      'login': 'ログイン',
      'logout': 'ログアウト',
      'register': '登録',
      'email': 'メール',
      'password': 'パスワード',
      'confirm_password': 'パスワード確認',
      'forgot_password': 'パスワードを忘れましたか？',
      'save': '保存',
      'cancel': 'キャンセル',
      'delete': '削除',
      'edit': '編集',
      'search': '検索',
      'filter': 'フィルター',
      'sort': '並び替え',
      'loading': '読み込み中...',
      'error': 'エラー',
      'success': '成功',
      'warning': '警告',
      'info': '情報',
      'home': 'ホーム',
      'profile': 'プロフィール',
      'settings': '設定',
      'help': 'ヘルプ',
      'about': 'について',
      'back': '戻る',
      'next': '次へ',
      'previous': '前へ',
      'art_walk': 'アートウォーク',
      'start_walk': 'ウォーク開始',
      'end_walk': 'ウォーク終了',
      'distance': '距離',
      'duration': '時間',
      'artworks_viewed': '閲覧した作品',
      'artwork': 'アート作品',
      'artworks': 'アート作品',
      'artist': 'アーティスト',
      'title': 'タイトル',
      'description': '説明',
      'like': 'いいね',
      'share': 'シェア',
      'comment': 'コメント',
      'view_count': '閲覧数',
      'community': 'コミュニティ',
      'post': '投稿',
      'posts': '投稿',
      'follow': 'フォロー',
      'unfollow': 'フォロー解除',
      'followers': 'フォロワー',
      'following': 'フォロー中',
      'capture': 'キャプチャ',
      'camera': 'カメラ',
      'gallery': 'ギャラリー',
      'photo': '写真',
      'video': 'ビデオ',
      'take_photo': '写真を撮る',
      'record_video': 'ビデオを録画',
      'artwork_singular': '{count}つの作品',
      'artwork_plural': '{count}つの作品',
      'follower_singular': '{count}人のフォロワー',
      'follower_plural': '{count}人のフォロワー',
    };
  }

  Map<String, String> _getKoreanTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': '환영합니다',
      'login': '로그인',
      'logout': '로그아웃',
      'register': '회원가입',
      'email': '이메일',
      'password': '비밀번호',
      'confirm_password': '비밀번호 확인',
      'forgot_password': '비밀번호를 잊으셨나요?',
      'save': '저장',
      'cancel': '취소',
      'delete': '삭제',
      'edit': '편집',
      'search': '검색',
      'filter': '필터',
      'sort': '정렬',
      'loading': '로딩 중...',
      'error': '오류',
      'success': '성공',
      'warning': '경고',
      'info': '정보',
      'home': '홈',
      'profile': '프로필',
      'settings': '설정',
      'help': '도움말',
      'about': '정보',
      'back': '뒤로',
      'next': '다음',
      'previous': '이전',
      'art_walk': '아트 워크',
      'start_walk': '워크 시작',
      'end_walk': '워크 종료',
      'distance': '거리',
      'duration': '시간',
      'artworks_viewed': '본 작품',
      'artwork': '예술 작품',
      'artworks': '예술 작품들',
      'artist': '아티스트',
      'title': '제목',
      'description': '설명',
      'like': '좋아요',
      'share': '공유',
      'comment': '댓글',
      'view_count': '조회수',
      'community': '커뮤니티',
      'post': '게시물',
      'posts': '게시물들',
      'follow': '팔로우',
      'unfollow': '언팔로우',
      'followers': '팔로워',
      'following': '팔로잉',
      'capture': '캡처',
      'camera': '카메라',
      'gallery': '갤러리',
      'photo': '사진',
      'video': '비디오',
      'take_photo': '사진 찍기',
      'record_video': '비디오 녹화',
      'artwork_singular': '{count}개의 작품',
      'artwork_plural': '{count}개의 작품',
      'follower_singular': '{count}명의 팔로워',
      'follower_plural': '{count}명의 팔로워',
    };
  }

  Map<String, String> _getChineseTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': '欢迎',
      'login': '登录',
      'logout': '登出',
      'register': '注册',
      'email': '邮箱',
      'password': '密码',
      'confirm_password': '确认密码',
      'forgot_password': '忘记密码？',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'search': '搜索',
      'filter': '筛选',
      'sort': '排序',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'info': '信息',
      'home': '首页',
      'profile': '个人资料',
      'settings': '设置',
      'help': '帮助',
      'about': '关于',
      'back': '返回',
      'next': '下一步',
      'previous': '上一步',
      'art_walk': '艺术漫步',
      'start_walk': '开始漫步',
      'end_walk': '结束漫步',
      'distance': '距离',
      'duration': '时长',
      'artworks_viewed': '已浏览作品',
      'artwork': '艺术作品',
      'artworks': '艺术作品',
      'artist': '艺术家',
      'title': '标题',
      'description': '描述',
      'like': '点赞',
      'share': '分享',
      'comment': '评论',
      'view_count': '浏览量',
      'community': '社区',
      'post': '帖子',
      'posts': '帖子',
      'follow': '关注',
      'unfollow': '取消关注',
      'followers': '粉丝',
      'following': '关注中',
      'capture': '拍摄',
      'camera': '相机',
      'gallery': '图库',
      'photo': '照片',
      'video': '视频',
      'take_photo': '拍照',
      'record_video': '录制视频',
      'artwork_singular': '{count}件作品',
      'artwork_plural': '{count}件作品',
      'follower_singular': '{count}个粉丝',
      'follower_plural': '{count}个粉丝',
    };
  }

  Map<String, String> _getArabicTranslations() {
    return {
      'app_name': 'ARTbeat',
      'welcome': 'مرحباً',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'register': 'التسجيل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'search': 'بحث',
      'filter': 'تصفية',
      'sort': 'ترتيب',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'warning': 'تحذير',
      'info': 'معلومات',
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'help': 'المساعدة',
      'about': 'حول',
      'back': 'رجوع',
      'next': 'التالي',
      'previous': 'السابق',
      'art_walk': 'جولة فنية',
      'start_walk': 'بدء الجولة',
      'end_walk': 'إنهاء الجولة',
      'distance': 'المسافة',
      'duration': 'المدة',
      'artworks_viewed': 'الأعمال المشاهدة',
      'artwork': 'عمل فني',
      'artworks': 'أعمال فنية',
      'artist': 'فنان',
      'title': 'العنوان',
      'description': 'الوصف',
      'like': 'إعجاب',
      'share': 'مشاركة',
      'comment': 'تعليق',
      'view_count': 'المشاهدات',
      'community': 'المجتمع',
      'post': 'منشور',
      'posts': 'منشورات',
      'follow': 'متابعة',
      'unfollow': 'إلغاء المتابعة',
      'followers': 'المتابعون',
      'following': 'يتابع',
      'capture': 'التقاط',
      'camera': 'الكاميرا',
      'gallery': 'المعرض',
      'photo': 'صورة',
      'video': 'فيديو',
      'take_photo': 'التقاط صورة',
      'record_video': 'تسجيل فيديو',
      'artwork_singular': '{count} عمل فني',
      'artwork_plural': '{count} أعمال فنية',
      'follower_singular': '{count} متابع',
      'follower_plural': '{count} متابعين',
    };
  }

  /// Dispose service
  void dispose() {
    _localeController.close();
  }
}

/// Date format options
enum DateFormat { short, medium, long }

/// Number format options
enum NumberFormat { decimal, currency, percentage }

/// Internationalization widget helper
class I18nText extends StatelessWidget {
  final String translationKey;
  final Map<String, String>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const I18nText(
    this.translationKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = InternationalizationService();
    return Text(
      i18n.translate(translationKey, params: params),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: i18n.textDirection,
    );
  }
}

/// Internationalization mixin for widgets
mixin InternationalizationMixin {
  InternationalizationService get i18n => InternationalizationService();

  String t(String key, {Map<String, String>? params}) {
    return i18n.translate(key, params: params);
  }

  String tp(String key, int count, {Map<String, String>? params}) {
    return i18n.translatePlural(key, count, params: params);
  }
}
