class AppConstants {
  static const String appName = 'PAUSE';

  static const List<String> weekDays = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  static const List<String> weekDaysFull = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  static const List<String> failReasons = [
    'Stress',
    'Fatigue',
    'Ennui',
    'Émotions',
    'Frustration',
    'Environnement',
    'Autre',
  ];

  static const List<String> failReasonsEmoji = [
    '😤',
    '😴',
    '😑',
    '😢',
    '😡',
    '🌍',
    '💬',
  ];

  // Rayon de détection géolocalisation (mètres)
  static const double locationRadius = 150;
}