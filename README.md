# 🐺 Loup Garou Party Game (Flutter + React)

A modern, digital adaptation of the classic party game **"Werewolf"** (Loup-Garou). This project allows a host to run the game from a Flutter application, while players participate using their own smartphones via a web interface—no app installation required for players!

## 🚀 How it Works

1.  **Host**: Runs the Flutter application on a laptop or tablet connected to Wi-Fi.
2.  **Players**: Scan a QR code displayed by the host to join the game through their mobile browser.
3.  **Real-time Play**: The Flutter host acts as the game server, handling logic and state, while the web clients provide a private interface for each player (to see their role, vote, etc.).

## ✨ Features

-   **Seamless Joining**: QR code based entry—just scan and play.
-   **Automated Game Logic**: The server handles role distribution, night/day cycles, and vote counting.
-   **Dynamic Roles**: Support for classic roles:
    -   🐺 **Werewolf**: Hunt villagers at night.
    -   👁️ **Seer**: Discover the true identity of other players.
    -   🧪 **Witch**: Use potions to save or kill.
    -   🏹 **Hunter**: Take someone down with you if you die.
    -   🧑‍🌾 **Villager**: Survive and find the wolves.
-   **Host Dashboard**: Full control over the game (kill players, force phases, reset).
-   **Responsive Design**: A sleek, mobile-first web interface for players using Tailwind CSS.

## 🛠️ Tech Stack

### Host (Server & Admin UI)
-   **Framework**: [Flutter](https://flutter.dev)
-   **Backend**: `shelf` (Dart Web Server), `shelf_router`, `shelf_web_socket`
-   **State Management**: Stream-based with JSON serialization.

### Client (Player Web App)
-   **Framework**: [React](https://reactjs.org/) + [Vite](https://vitejs.dev/)
-   **Styling**: [Tailwind CSS](https://tailwindcss.com/)
-   **Communication**: WebSockets (via `react-use-websocket`)

---

## 🏁 Getting Started

### Prerequisites
-   [Flutter SDK](https://docs.flutter.dev/get-started/install)
-   [Node.js & npm](https://nodejs.org/) (for building the web client)

### 1. Build the Web Client
Before running the Flutter app, you need to compile the React frontend:

```bash
cd client_web
npm install
npm run build
```
*Note: The build script automatically copies the production files into the Flutter `assets/web` directory.*

### 2. Run the Flutter Host
Once the web assets are built, you can launch the Flutter application:

```bash
# From the root directory
flutter pub get
flutter run
```

> **Important**: Ensure your host device and player devices are on the same Wi-Fi network.

---

## 📂 Project Structure

-   `lib/`: Flutter host application source code.
    -   `server/`: Game server logic and WebSocket management.
    -   `game/`: Core game state and controller.
    -   `screens/`: UI for the host dashboard.
-   `client_web/`: Source code for the React player interface.
-   `assets/web/`: Compiled web assets (used by the Flutter app).

---

Made with ❤️ for great party nights!

