🏡 Little House Clothing Catalog
A smarter way to browse and organize your clothing collection.
💡 About the Project
This is a mobile application built with Flutter that serves as a digital clothing catalog. What makes it unique is its integration with a FastAPI backend running a lightweight TFLite image classification model. This powerful system automatically categorizes clothes by their material type, providing a more efficient and precise browsing experience.

✨ Features
🤖 AI-Powered Material Classification: The app automatically identifies the material of a garment using a lightweight TFLite image classification model on a FastAPI backend.

👕 Elegant Product Catalog: Browse a beautifully designed collection of clothing items with a smooth and responsive interface.

🔍 Advanced Filtering: Easily filter and sort items by their material type, category, or other properties.

💖 Personalized Wishlist: Save your favorite items to a personalized wishlist for easy access and organization.

📱 Cross-Platform: Built with Flutter for a native-like experience on both Android and iOS devices.

📸 Screenshots
Here's a quick look at the app in action.
(Note: These are placeholder images. Replace them with actual screenshots of your application.)

<div align="center">
<img src="https://placehold.co/400x800/E8E8E8/4F4F4F?text=Main+Catalog" alt="Main Catalog Screen" width="200" style="margin-right: 10px;">
<img src="https://placehold.co/400x800/E8E8E8/4F4F4F?text=Product+Details" alt="Product Details Screen" width="200" style="margin-right: 10px;">
<img src="https://placehold.co/400x800/E8E8E8/4F4F4F?text=Wishlist" alt="Wishlist Screen" width="200">
</div>

🚀 Getting Started
Follow these steps to get the project up and running on your local machine for development.

Prerequisites
Flutter SDK: Install Flutter

A running FastAPI backend with the TFLite model, accessible from the app.

Installation
Clone the repository:

git clone https://github.com/your-username/little_house_clothing_catalog.git
cd little_house_clothing_catalog

Install dependencies:

flutter pub get

Run the app:

flutter run

This will launch the app on your connected device or emulator.

📂 Project Structure
A brief overview of the main folders and files:

.
├── android/            # Android-specific files and settings
├── ios/                # iOS-specific files and settings
├── lib/                # All the Dart code for the application
│   ├── main.dart       # The app's entry point
│   ├── screens/        # UI for major pages (e.g., Catalog, Details)
│   ├── widgets/        # Reusable UI components
│   └── services/       # Code for API calls to the FastAPI backend
└── pubspec.yaml        # Project dependencies and asset declarations

👋 Contributing
We welcome contributions! If you have ideas for new features, bug fixes, or improvements, feel free to open an issue or submit a pull request.

📝 License
This project is licensed under the MIT License. See the LICENSE file for details.