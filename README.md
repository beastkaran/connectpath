# ConnectPath — Proximity Professional Network (PPN)

> B.Tech Final Year Project · Flutter + FastAPI + PostgreSQL/PostGIS

---

## Project Structure

```
ppn_project/
├── backend/
│   ├── main.py              ← FastAPI app (all endpoints)
│   ├── models.py            ← SQLAlchemy ORM models
│   ├── requirements.txt
│   └── Dockerfile
├── flutter/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                        ← App entry point
│       ├── theme.dart                       ← Design system / colours
│       ├── services/
│       │   ├── api_service.dart             ← HTTP client (all API calls)
│       │   ├── location_service.dart        ← Background GPS tracking
│       │   └── app_state.dart               ← Global state (Provider)
│       ├── widgets/
│       │   └── common_widgets.dart          ← ProfileCard, Avatar, EmptyState…
│       └── screens/
│           ├── auth_screens.dart            ← Splash, Login, Register
│           ├── home_screen.dart             ← Dashboard + bottom nav
│           ├── crossed_paths_screen.dart    ← Radar / proximity matches
│           ├── events_screen.dart           ← Event listing + RSVP
│           ├── alumni_screen.dart           ← Alumni search
│           ├── connections_screen.dart      ← Pending + accepted network
│           ├── profile_screen.dart          ← Own profile + edit + badges
│           └── matchmaking_screen.dart      ← Smart skill matching
└── docker-compose.yml
```

---

## Quick Start

### 1. Run the backend (Docker)

```bash
docker-compose up --build
```

The API will be live at **http://localhost:8000**  
Interactive docs: **http://localhost:8000/docs**

### 2. Create an admin account

```bash
curl -X POST http://localhost:8000/admin/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ppn.com","password":"admin123","name":"Admin"}'
```

### 3. Run the Flutter app

```bash
cd flutter
flutter pub get
flutter run
```

> **Important:** Update `baseUrl` in `lib/services/api_service.dart` to match your backend.
> - Android emulator → `http://127.0.0.1:8000`
> - iOS simulator   → `http://localhost:8000`
> - Physical device → `http://<your-machine-ip>:8000`

---

## API Reference

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | Register user |
| POST | `/token` | Login → JWT |

### Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile/me` | Get own profile |
| PUT | `/profile/me` | Update profile |
| PUT | `/profile/toggle-visibility` | Toggle Open/Private |
| GET | `/profile/{user_id}` | View another user |

### Location (FR-U-02, FR-U-03)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/location/update` | Log GPS point (requires Open to Connect) |
| GET | `/location/crossed-paths` | Users within 50m in last 24h |

### Connections (FR-U-04)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/connections/request` | Send request |
| GET | `/connections/pending` | Incoming requests |
| GET | `/connections/accepted` | Your network |
| PUT | `/connections/{id}/respond?accept=true` | Accept/reject |

### Events (FR-U-07, FR-U-08)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/events` | All approved events |
| POST | `/events` | Submit event (pending review) |
| POST | `/events/{id}/register` | RSVP |
| DELETE | `/events/{id}/register` | Cancel RSVP |
| GET | `/events/{id}/attendees` | View attendees (registered users only) |

### Alumni Search (FR-U-06)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/alumni/search?name=&department=&skill=&graduation_year=` | Search network |

### Matchmaking (FR-U-09)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/matchmaking/suggestions` | Complementary skill matches |

### Badges (FR-U-10)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/badges/my` | My earned badges |

### Admin (FR-A-01, FR-A-02, FR-A-03)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/admin/register` | Register admin |
| POST | `/admin/token` | Admin login |
| GET | `/admin/events/pending` | Events awaiting approval |
| POST | `/admin/events/{id}/review?approve=true` | Approve/reject event |
| GET | `/admin/users` | List all users |
| PUT | `/admin/users/{id}/status?new_status=suspended` | Suspend/ban user |

---

## SRS Feature Coverage

| FR ID | Feature | Status |
|-------|---------|--------|
| FR-U-01 | User Authentication | ✅ |
| FR-U-02 | Location Tracking & Storage | ✅ |
| FR-U-03 | Crossed Paths (50m / 24h) | ✅ |
| FR-U-04 | Connection Action | ✅ |
| FR-U-05 | Profile Visibility Toggle | ✅ |
| FR-U-06 | Alumni Search | ✅ |
| FR-U-07 | Event Listing & RSVP | ✅ |
| FR-U-08 | Event Attendee List | ✅ |
| FR-U-09 | Smart Matchmaking | ✅ |
| FR-U-10 | Gamification / Badges | ✅ |
| FR-A-01 | Admin Authentication | ✅ |
| FR-A-02 | Event Verification | ✅ |
| FR-A-03 | User Moderation | ✅ |

### NFR Compliance
| NFR | Description | Implementation |
|-----|-------------|----------------|
| NFR-S-01 | Location data auto-purge | 48h purge on every `/location/update` call |
| NFR-S-02 | HTTPS/SSL | Enforced via reverse proxy (Nginx in production) |
| NFR-S-03 | Explicit consent | Location only logged if `is_open_to_connect = True` |
| NFR-P-01 | <3s match speed | PostGIS `ST_DWithin` spatial index |
| NFR-U-03 | Location feedback | ConnectToggleCard visible on home screen |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://user:password@localhost/ppn_db` | PostgreSQL connection string |
| `SECRET_KEY` | `your-secret-key` | JWT signing key — **change in production** |

---

## Production Checklist

- [ ] Change `SECRET_KEY` to a strong random string
- [ ] Configure HTTPS (Nginx + Let's Encrypt)
- [ ] Restrict `/admin/register` endpoint (remove or add IP allowlist)
- [ ] Set `allow_origins` in CORS to your actual domain(s)
- [ ] Enable PostGIS spatial index: `CREATE INDEX ON location_logs USING GIST (location);`
- [ ] Set up cron job or pg_cron for periodic location cleanup
- [ ] Update `baseUrl` in Flutter `api_service.dart` to production URL
