# BlueBug 🐛💙 — Housing Community App

A Flutter mobile app for housing community management with role-based dashboards.

---

## Project Structure

```
lib/
├── main.dart                     # App entry point & routing
├── screens/
│   ├── login_screen.dart         # Login with bounce animation
│   ├── admin_dashboard.dart      # Admin: post/delete events, view complaints
│   └── community_dashboard.dart  # Security/Owner/Visitor: 3-tab dashboard
├── services/
│   └── api_service.dart          # All HTTP API calls
├── models/
│   ├── event.dart                # Event data model
│   └── complaint.dart            # Complaint data model
└── widgets/
    ├── event_card.dart           # Animated event card with delete button
    ├── complaint_card.dart       # Animated complaint card with role badge
    └── loading_shimmer.dart      # Shimmer loading placeholder
```

---

## Setup Instructions

### 1. Prerequisites

- Flutter SDK 3.x installed
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Server URL

Open `lib/services/api_service.dart` and update the base URL:

```dart
static const String baseUrl = 'https://yourwebsite.com';
```

Replace `https://yourwebsite.com` with your actual server URL.

### 4. Run the App

```bash
flutter run
```

Or build an APK:

```bash
flutter build apk --release
```

---

## API Endpoints (Backend Must Implement)

| Endpoint             | Method | Body / Notes                                   |
|----------------------|--------|------------------------------------------------|
| `/api/login`         | POST   | `{ "id": "...", "password": "..." }`           |
| `/api/events`        | GET    | Returns array of event objects                 |
| `/api/events`        | POST   | `{ "title": "...", "description": "..." }`     |
| `/api/events/{id}`   | DELETE | Deletes event by ID                            |
| `/api/complaints`    | GET    | Returns array of complaint objects             |
| `/api/complaints`    | POST   | `{ "complaintText": "..." }`                   |

### Login Response Format

```json
{
  "success": true,
  "role": "admin",
  "name": "Admin"
}
```

Role values: `"admin"` | `"security"` | `"owner"` | `"visitor"`

### Events Response Format

```json
[
  {
    "id": 1,
    "title": "Community Meeting",
    "description": "Tomorrow 7pm in clubhouse",
    "dateTime": "2024-01-15 10:30:00",
    "postedBy": "Admin"
  }
]
```

### Complaints Response Format

```json
[
  {
    "id": 1,
    "userName": "Rajesh",
    "userRole": "owner",
    "complaintText": "Water leakage in parking",
    "dateTime": "2024-01-15 11:45:00"
  }
]
```

---

## Pre-Set Credentials (Configure in PostgreSQL)

| Role         | ID         | Password    |
|--------------|------------|-------------|
| Admin        | `admin`    | `admin123`  |
| Security     | `security` | `sec123`    |
| House Owner  | `owner`    | `owner123`  |
| Visitor      | `visitor`  | `visit123`  |

---

## Features

### Admin Dashboard
- Post new events (title + description)
- Delete any event with confirmation dialog
- View all complaints from all users
- Pull-to-refresh

### Community Dashboard (Security / Owner / Visitor)
- **Tab 1 – Events**: View all events (read-only)
- **Tab 2 – Raise Complaint**: Submit a complaint with character counter
- **Tab 3 – All Complaints**: View complaints from everyone (newest first, green dot on latest 3)

---

## Animations

| Element              | Animation                              |
|----------------------|----------------------------------------|
| App logo             | Bounce on load (900ms)                 |
| Login button tap     | Scale to 0.95 → back (100ms)           |
| Page transitions     | Slide from right (300ms)               |
| Cards                | Fade-in + slide-up with stagger delay  |
| Delete button        | Scale to 0.88 → back (100ms)          |
| Submit button        | Scale to 0.95 → back (100ms)          |
| Delete dialog        | Scale from 0.8 → 1.0 (200ms)          |
| Loading state        | Shimmer effect on placeholder cards   |

---

## Notes

- **Frontend only** — no local database, no offline support
- Session persisted via `shared_preferences` (stores role and name)
- Pull-to-refresh available on all list views
- Server returns complaints/events sorted by ID; app reverses list (newest first)
- Food delivery personnel have no app access (show JSON order physically to security)
