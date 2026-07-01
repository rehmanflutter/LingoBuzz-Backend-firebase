



# Lingo Buzz - Language Learning App

Lingo Buzz is a Flutter-based language learning application designed to help users expand their vocabulary through daily practice, quizzes, speech playback, and home screen widgets. Learn new words from multiple languages and improve your language skills with a simple and engaging experience.

## Supported Languages

* Chinese
* French
* German
* Italian
* Japanese
* Korean
* Portuguese
* Spanish

## Features

### 📚 Vocabulary Learning

* Learn new words daily from multiple languages.
* Save favorite words for later review.
* Track your learning progress.

### 🔊 Text-to-Speech

* Listen to word pronunciations.
* Improve speaking and listening skills.
* Native-like pronunciation support.

### 🏠 Home Screen Widget

* Displays 3 daily vocabulary words directly on the device home screen.
* Learn without opening the application.
* Quick access to pronunciation and word review.

### 🧠 Interactive Quizzes

* Test vocabulary knowledge with quizzes.
* Improve retention through practice.
* Track quiz performance.

### 👤 User Profiles

* Manage personal learning progress.
* Save preferences and learning history.

### 🌍 Multi-Language Support

* User interface localization support.
* Easy language switching.

### ⭐ Premium Membership

Premium users can:

* Learn up to 10 new words daily.
* Access advanced learning features.
* Enjoy an enhanced learning experience.

### 💳 Stripe Integration

* Secure subscription payments.
* Premium membership management.
* Easy upgrade and renewal process.

## Project Structure

```text
lib/
│
├── Routes/
│
├── controller/
│   ├── AuthController/
│   ├── HomeController/
│   ├── SettingController/
│   ├── UpgradeProController/
│   ├── languages_controller/
│   ├── quizController/
│   ├── words_controller/
│   └── app_info_controller.dart
│
├── core/
│
├── model/
│
├── view/
│   ├── Home/
│   ├── MyWords/
│   ├── Onboarding/
│   ├── Quiz/
│   ├── Settings/
│   ├── SplashScreen/
│   ├── UpgradePro/
│   └── Profile/
│
└── main.dart

android/
ios/
assets/
functions/
```

## Technology Stack

* Flutter 3.33
* Dart
* Firebase
* Stripe Payment Gateway
* Home Screen Widgets
* Text-to-Speech (TTS)
* Local Notifications

## Installation


### Install Dependencies

```bash
flutter pub get
```

### Verify Flutter Version

```bash
flutter --version
```

Required Version:
Flutter 3.32.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 8defaa71a7 (5 months ago) • 2025-06-04 11:02:51 -0700
Engine • revision 1091508939 (5 months ago) • 2025-05-30 12:17:36 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1
```

### Run Application

```bash
flutter run
```

## Premium Plan

| Feature             | Free | Premium |
| ------------------- | ---- | ------- |
| Daily Words         | 3    | 10      |
| Home Widget         | ✓    | ✓       |
| Pronunciation       | ✓    | ✓       |
| Vocabulary Tracking | ✓    | ✓       |
| Advanced Learning   | ✗    | ✓       |

## How It Works

1. Select the language you want to learn.
2. Receive daily vocabulary words.
3. Listen to word pronunciations.
4. Practice through quizzes.
5. Review saved words.
6. Learn directly from the home screen widget.
7. Upgrade to Premium for additional daily vocabulary and advanced features.

## Developer

Lingo Buzz is a language-learning platform built with Flutter, designed to make vocabulary learning simple, engaging, and accessible directly from your mobile device and home screen widgets.

## License

This project is available for educational and personal use.

<h2 align="center">Screenshots</h2>

<p align="center">
  <img src="images/screenshot_1.png" width="30%" />
  <img src="images/screenshot_2.png" width="30%" />
  <img src="images/screenshot_3.png" width="30%" />
</p>

<p align="center">
  <img src="images/screenshot_4.png" width="30%" />
  <img src="images/screenshot_5.png" width="30%" />
  <img src="images/screenshot_6.png" width="30%" />
</p>

<p align="center">
  <img src="images/screenshot_7.png" width="30%" />
  <img src="images/screenshot_8.png" width="30%" />
  <img src="images/screenshot_9.png" width="30%" />
</p>

<p align="center">
  <img src="images/screenshot_10.png" width="30%" />
</p>
