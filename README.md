# 🏡 Little House Clothing Catalog

A smarter, AI-powered way to browse and organize clothing.

---

## 💡 About the Project

This project is a cross-platform mobile app built with Flutter that re-imagines the traditional clothing catalog. Instead of simple browsing, it integrates with a FastAPI backend running a lightweight TFLite image classification model. This powerful combination automatically analyzes and categorizes clothes by their material type, providing a more precise and efficient shopping experience.

---

## ✨ Key Features

- 🤖 **AI-Powered Material Classification:** Uses a TFLite model on a backend to automatically identify a garment's material.

- 👕 **Elegant Product Catalog:** A clean, responsive UI for browsing a curated collection of clothing items.

- 🔍 **Advanced Filtering:** Easily filter and sort items based on their automatically detected material, category, and more.

- 💖 **Personalized Wishlist:** Users can save their favorite items to a personal wishlist for quick access.

- 📱 **Built for Mobile:** A smooth, native-like experience on both Android and iOS devices.

---

## 🌐 Live Demo

Experience the app and its features directly on the web:

[https://little-house-clothing-catalog.web.app/](https://little-house-clothing-catalog.web.app/)

---

## 🚀 Getting Started

To get a local copy of this project up and running, follow these steps.

### Prerequisites

- Flutter SDK: Install Flutter

- A running FastAPI backend with the TFLite model, configured and accessible from your Flutter app.

### Installation

Clone the repository:

```bash
git clone https://github.com/your-username/little_house_clothing_catalog.git
cd little_house_clothing_catalog
````

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

This command will launch the app on your connected device or emulator.

---

## 📂 Project Structure

A clean overview of the project's folder hierarchy:

```
little_house_clothing_catalog/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── screens/          # Major UI views (e.g., Catalog, ProductDetail)
│   ├── widgets/          # Reusable UI components
│   └── services/         # API clients and data fetching logic
└── pubspec.yaml          # Project dependencies
```

---

## 👋 Contributing

We welcome contributions! If you have suggestions for improvements or find a bug, please feel free to open an issue or submit a pull request.

---

## 📝 License

This project is licensed under the MIT License. See the LICENSE file for more details.
