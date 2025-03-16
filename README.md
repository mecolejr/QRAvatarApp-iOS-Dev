# QR Avatar App

A SwiftUI application for creating, customizing, and sharing 3D avatars via QR codes.

## Features

- Browse and select from a collection of 3D avatar models
- Preview avatars in 3D with ARKit integration
- Customize avatar appearance with color options
- Generate QR codes to share your avatars with others
- Scan QR codes to view other users' avatars in AR
- Simulator-friendly preview mode for development

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.0+
- Device with camera for QR scanning and AR features

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/QRAvatarApp.git
```

2. Open the project in Xcode
```bash
cd QRAvatarApp
open QRAvatarApp.xcodeproj
```

3. Build and run the application on your device (AR features require a physical device)

## Project Structure

- **QRAvatarApp.swift**: Main application entry point
- **ContentView.swift**: Main view controller for the app
- **Model.swift**: Data model for avatar models
- **ModelPicker.swift**: UI component for browsing and selecting models
- **ModelPickerViewModel.swift**: View model for the model picker
- **ModelPreview.swift**: 3D preview component for models
- **AvatarPreviewView.swift**: View for customizing and previewing avatars
- **QRScannerView.swift**: Camera view for scanning QR codes
- **QRCodeGenerator.swift**: Utilities for generating QR codes
- **SimulatorPreviewHelper.swift**: Helper utilities for simulator previews

## How It Works

1. **Select an Avatar**: Browse the available 3D models and select one
2. **Customize**: Change the color of your avatar
3. **Share**: Generate a QR code that represents your avatar
4. **Scan**: Use the QR scanner to view other users' avatars in AR

## Simulator Support

The app includes special handling for simulator environments, allowing development and testing without ARKit capabilities. When running in the simulator:

- Sample 3D models are automatically loaded
- Basic 3D shapes are used as placeholders
- UI adapts to show appropriate controls

## License

This project is provided for educational purposes.