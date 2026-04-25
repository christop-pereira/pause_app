## Prérequis
Avant de lancer le projet :

### 1. Installer Flutter
https://flutter.dev/docs/get-started/install

Vérifier l’installation :
```bash
flutter doctor
```

### 2. Installer Android Studio
https://developer.android.com/studio

### 3. Installer Visual Studio Community
https://visualstudio.microsoft.com/fr/vs/features/cplusplus/

## Installation

### 1. Cloner le projet
```bash
git clone https://github.com/christop-pereira/pause_app.git
cd pause_app
```

### 2. Installer les dépendances
```bash
flutter pub get
```

## Lancer l'application

### Android
```bash
flutter run -d android
```

### iOS (Mac uniquement)
```bash
flutter run -d ios
```

### Desktop (Windows / Mac / Linux)
```bash
flutter run
```

## 🧹 Nettoyer le cache de build

En cas d’erreur après déplacement du projet, renommage du dossier ou problème de compilation :

```bash
flutter clean  
flutter pub get  
flutter run
```
