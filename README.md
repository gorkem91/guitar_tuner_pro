# 🎸 Pro Guitar Tuner

A high-performance, real-time Guitar Tuner application built with **Flutter**. 
Unlike standard tuner apps that rely on heavy external libraries, this project implements a **custom Native Pitch Detection Algorithm** (Autocorrelation) based on raw audio data processing.

<div align="center">
  <img src="https://github.com/user-attachments/assets/7e324f24-a20d-4354-bed7-59b2b32ae1e4" width="250" />
  <img src="https://github.com/user-attachments/assets/8cb63002-d641-41c5-8e62-07d01cb3ceaa" width="250" />
  <img src="https://github.com/user-attachments/assets/2d5c90ba-e2d9-4d88-9fb7-d278a731b336" width="250" />
</div>

<br>

## 🔥 Key Features

- **🚀 No Heavy Dependencies:** Uses a custom-written mathematical engine for frequency analysis.
- **🎛️ Native Pitch Detection:** Implements **Autocorrelation** algorithm specifically optimized for guitar frequencies (60Hz - 700Hz).
- **🎨 Custom UI Painting:** The gauge needle and arc are drawn using `CustomPainter` for smooth 60fps animations.
- **🎤 Raw Audio Capture:** Processes raw PCM audio stream directly from the microphone.
- **📱 iOS Optimized:** Handles iOS permission flows and sample rate conversions seamlessly.

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Audio Engine:** `flutter_audio_capture` + Custom Math Logic
- **State Management:** Native `setState` & `WidgetsBindingObserver`
- **Permissions:** `permission_handler`

## 🧠 How It Works (The Math Behind It)

Instead of using a generic FFT (Fast Fourier Transform), this app uses **Autocorrelation**, which is more accurate for string instruments.

1.  **Capture:** The app captures raw audio buffer (Float64List).
2.  **Noise Gate:** Silence and background noise are filtered out using RMS (Root Mean Square) calculation.
3.  **Analysis:** The algorithm compares the audio signal with a time-lagged version of itself to find the fundamental frequency (Pitch).
4.  **Smoothing:** The UI updates only when a stable pitch is detected to prevent needle jitter.

## 📸 Installation & Run

```bash
# Clone the repository
git clone [https://github.com/gorkem91/guitar_tuner_pro.git](https://github.com/gorkem91/guitar_tuner_pro.git)

# Install dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Run on device
flutter run