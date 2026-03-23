from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import create_engine, and_, or_
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timedelta
from typing import List, Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_Distance
from geoalchemy2.shape import to_shape
import json
import os

from models import Base, User, LocationLog, Connection, Event, EventRegistration, Badge, UserBadge, Admin
from models import UserStatus, ConnectionStatus, EventStatus

# ─── Configuration ───────────────────────────────────────────────────────────
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/ppn_db")
# Fix Render's postgres:// prefix
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
SECRET_KEY   = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM    = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours for convenience

# ─── Database ─────────────────────────────────────────────────────────────────
engine       = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# Auto-enable PostGIS extension
from sqlalchemy import text
with engine.connect() as conn:
    conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
    conn.commit()

Base.metadata.create_all(bind=engine)

# ─── Security ─────────────────────────────────────────────────────────────────
pwd_context    = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme  = OAuth2PasswordBearer(tokenUrl="token")
admin_scheme   = OAuth2PasswordBearer(tokenUrl="admin/token")

# ─── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(title="Proximity Professional Network API", version="1.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── DB Dependency ────────────────────────────────────────────────────────────
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ─── Pydantic Schemas ─────────────────────────────────────────────────────────
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    name: str
    profession: Optional[str] = None
    course: Optional[str] = None
    department: Optional[str] = None
    graduation_year: Optional[int] = None
    bio: Optional[str] = None

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    profession: Optional[str] = None
    course: Optional[str] = None
    department: Optional[str] = None
    graduation_year: Optional[int] = None
    skills: Optional[str] = None
    bio: Optional[str] = None

class UserProfile(BaseModel):
    id: int
    email: str
    name: str
    profession: Optional[str]
    course: Optional[str]
    department: Optional[str]
    graduation_year: Optional[int]
    skills: Optional[str]
    credentials: Optional[str]
    bio: Optional[str]
    profile_image_url: Optional[str]
    is_open_to_connect: bool
    status: str

    class Config:
        from_attributes = True

class LocationUpdate(BaseModel):
    latitude: float
    longitude: float

class ConnectionRequest(BaseModel):
    receiver_id: int
    message: Optional[str] = None

class EventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    location_name: str
    latitude: float
    longitude: float
    start_time: datetime
    end_time: datetime
    organizer: Optional[str] = None
    capacity: Optional[int] = None

class EventResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    location_name: str
    start_time: datetime
    end_time: datetime
    organizer: Optional[str]
    capacity: Optional[int]
    status: str

    class Config:
        from_attributes = True

class AdminRegister(BaseModel):
    email: EmailStr
    password: str
    name: str

# ─── Helpers ──────────────────────────────────────────────────────────────────
def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire    = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise exc
    except JWTError:
        raise exc
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise exc
    if user.status != UserStatus.ACTIVE:
        raise HTTPException(status_code=403, detail="Account suspended or banned")
    return user

async def get_current_admin(token: str = Depends(admin_scheme), db: Session = Depends(get_db)) -> Admin:
    exc = HTTPException(status_code=401, detail="Invalid admin credentials")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        role: str  = payload.get("role")
        if email is None or role != "admin":
            raise exc
    except JWTError:
        raise exc
    admin = db.query(Admin).filter(Admin.email == email).first()
    if admin is None:
        raise exc
    return admin

# ─────────────────────────────────────────────────────────────────────────────
# AUTH ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/register", status_code=201)
def register_user(user_data: UserRegister, db: Session = Depends(get_db)):
    """FR-U-01: Register a new user."""
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        name=user_data.name,
        profession=user_data.profession,
        course=user_data.course,
        department=user_data.department,
        graduation_year=user_data.graduation_year,
        bio=user_data.bio,
        is_open_to_connect=False,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "User registered successfully", "user_id": new_user.id}


@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """FR-U-01: User login → JWT."""
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password",
                            headers={"WWW-Authenticate": "Bearer"})
    if user.status != UserStatus.ACTIVE:
        raise HTTPException(status_code=403, detail="Account suspended or banned")

    token = create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": token, "token_type": "bearer"}


# ─────────────────────────────────────────────────────────────────────────────
# PROFILE ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/profile/me", response_model=UserProfile)
def get_my_profile(current_user: User = Depends(get_current_user)):
    """Get own profile."""
    return current_user


@app.put("/profile/me")
def update_profile(
    update: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update editable profile fields."""
    for field, value in update.dict(exclude_none=True).items():
        setattr(current_user, field, value)
    current_user.updated_at = datetime.utcnow()
    db.commit()
    award_badge_if_eligible(current_user, db)
    return {"message": "Profile updated successfully"}


@app.put("/profile/toggle-visibility")
def toggle_visibility(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """FR-U-05: Toggle Open-to-Connect / Private mode."""
    current_user.is_open_to_connect = not current_user.is_open_to_connect
    db.commit()
    return {"message": "Visibility updated", "is_open_to_connect": current_user.is_open_to_connect}


@app.get("/profile/{user_id}", response_model=UserProfile)
def get_user_profile(user_id: int, db: Session = Depends(get_db)):
    """View another user's profile (public endpoint)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# ─────────────────────────────────────────────────────────────────────────────
# LOCATION ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/location/update")
def update_location(
    location: LocationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """FR-U-02: Log a location point (only when Open to Connect)."""
    if not current_user.is_open_to_connect:
        raise HTTPException(status_code=400, detail="Enable 'Open to Connect' first.")

    point = f'SRID=4326;POINT({location.longitude} {location.latitude})'
    log = LocationLog(user_id=current_user.id, location=point)
    db.add(log)

    # NFR-S-01: Purge location logs older than 48 hours for this user
    cutoff = datetime.utcnow() - timedelta(hours=48)
    db.query(LocationLog).filter(
        LocationLog.user_id == current_user.id,
        LocationLog.timestamp < cutoff
    ).delete()

    db.commit()
    return {"message": "Location updated"}


@app.get("/location/crossed-paths")
def get_crossed_paths(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """FR-U-03: Return profiles that crossed within 50m in last 24 hours."""
    since = datetime.utcnow() - timedelta(hours=24)

    # Get current user's recent locations
    my_logs = db.query(LocationLog).filter(
        LocationLog.user_id == current_user.id,
        LocationLog.timestamp >= since
    ).all()

    if not my_logs:
        return {"crossed_paths": []}

    matched_user_ids = set()

    for my_log in my_logs:
        nearby = db.query(LocationLog).filter(
            LocationLog.user_id != current_user.id,
            LocationLog.timestamp >= since,
            ST_DWithin(
                LocationLog.location,
                my_log.location,
                50  # metres
            )
        ).all()
        for log in nearby:
            matched_user_ids.add(log.user_id)

    users = db.query(User).filter(
        User.id.in_(matched_user_ids),
        User.is_open_to_connect == True,
        User.status == UserStatus.ACTIVE
    ).all()

    return {
        "crossed_paths": [
            {
                "id": u.id,
                "name": u.name,
                "profession": u.profession,
                "course": u.course,
                "department": u.department,
                "bio": u.bio,
                "skills": u.skills,
                "profile_image_url": u.profile_image_url,
            }
            for u in users
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# CONNECTION ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/connections/request")
def send_connection_request(
    req: ConnectionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """FR-U-04: Send a connection request."""
    if req.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot connect with yourself")

    if not db.query(User).filter(User.id == req.receiver_id).first():
        raise HTTPException(status_code=404, detail="User not found")

    existing = db.query(Connection).filter(
        or_(
            and_(Connection.sender_id == current_user.id, Connection.receiver_id == req.receiver_id),
            and_(Connection.sender_id == req.receiver_id, Connection.receiver_id == current_user.id)
        )
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Connection already exists or was requested")

    conn = Connection(
        sender_id=current_user.id,
        receiver_id=req.receiver_id,
        message=req.message,
        status=ConnectionStatus.PENDING
    )
    db.add(conn)
    db.commit()
    return {"message": "Connection request sent"}


@app.get("/connections/pending")
def get_pending_connections(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """List incoming pending connection requests."""
    connections = db.query(Connection).filter(
        Connection.receiver_id == current_user.id,
        Connection.status == ConnectionStatus.PENDING
    ).all()

    return {
        "requests": [
            {
                "id": c.id,
                "sender": {"id": c.sender.id, "name": c.sender.name, "profession": c.sender.profession},
                "message": c.message,
                "created_at": c.created_at,
            }
            for c in connections
        ]
    }


@app.get("/connections/accepted")
def get_accepted_connections(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """List accepted connections (network)."""
    connections = db.query(Connection).filter(
        or_(
            Connection.sender_id == current_user.id,
            Connection.receiver_id == current_user.id
        ),
        Connection.status == ConnectionStatus.ACCEPTED
    ).all()

    result = []
    for c in connections:
        other = c.receiver if c.sender_id == current_user.id else c.sender
        result.append({"id": other.id, "name": other.name, "profession": other.profession,
                       "course": other.course, "profile_image_url": other.profile_image_url})
    return {"connections": result}


@app.put("/connections/{connection_id}/respond")
def respond_to_connection(
    connection_id: int,
    accept: bool,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Accept or reject a connection request."""
    conn = db.query(Connection).filter(
        Connection.id == connection_id,
        Connection.receiver_id == current_user.id,
        Connection.status == ConnectionStatus.PENDING
    ).first()
    if not conn:
        raise HTTPException(status_code=404, detail="Connection request not found")

    conn.status = ConnectionStatus.ACCEPTED if accept else ConnectionStatus.REJECTED
    db.commit()
    if accept:
        award_badge_if_eligible(current_user, db)
    return {"message": f"Connection {'accepted' if accept else 'rejected'}"}


# ─────────────────────────────────────────────────────────────────────────────
# EVENT ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/events", response_model=List[EventResponse])
def get_events(db: Session = Depends(get_db)):
    """FR-U-07: List all approved upcoming events."""
    return db.query(Event).filter(
        Event.status == EventStatus.APPROVED,
        Event.start_time >= datetime.utcnow()
    ).order_by(Event.start_time).all()


@app.post("/events", status_code=201)
def create_event(
    event_data: EventCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit an event for admin approval."""
    event = Event(
        title=event_data.title,
        description=event_data.description,
        location_name=event_data.location_name,
        location=f'SRID=4326;POINT({event_data.longitude} {event_data.latitude})',
        start_time=event_data.start_time,
        end_time=event_data.end_time,
        organizer=event_data.organizer or current_user.name,
        capacity=event_data.capacity,
        created_by=current_user.id,
        status=EventStatus.PENDING,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return {"message": "Event submitted for approval", "event_id": event.id}


@app.post("/events/{event_id}/register")
def register_for_event(
    event_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """FR-U-07: RSVP to an event."""
    event = db.query(Event).filter(Event.id == event_id, Event.status == EventStatus.APPROVED).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found or not approved")

    if event.capacity:
        registered_count = db.query(EventRegistration).filter(EventRegistration.event_id == event_id).count()
        if registered_count >= event.capacity:
            raise HTTPException(status_code=400, detail="Event is full")

    if db.query(EventRegistration).filter(
        EventRegistration.user_id == current_user.id,
        EventRegistration.event_id == event_id
    ).first():
        raise HTTPException(status_code=400, detail="Already registered")

    db.add(EventRegistration(user_id=current_user.id, event_id=event_id))
    db.commit()
    award_badge_if_eligible(current_user, db)
    return {"message": "Registered successfully"}


@app.delete("/events/{event_id}/register")
def unregister_from_event(
    event_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel RSVP."""
    reg = db.query(EventRegistration).filter(
        EventRegistration.user_id == current_user.id,
        EventRegistration.event_id == event_id
    ).first()
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")
    db.delete(reg)
    db.commit()
    return {"message": "Registration cancelled"}


@app.get("/events/{event_id}/attendees")
def get_event_attendees(
    event_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """FR-U-08: View attendees of a registered event."""
    if not db.query(EventRegistration).filter(
        EventRegistration.user_id == current_user.id,
        EventRegistration.event_id == event_id
    ).first():
        raise HTTPException(status_code=403, detail="Must be registered to view attendees")

    regs = db.query(EventRegistration).filter(EventRegistration.event_id == event_id).all()
    attendees = [
        {"id": r.user.id, "name": r.user.name, "profession": r.user.profession,
         "course": r.user.course, "profile_image_url": r.user.profile_image_url}
        for r in regs if r.user.is_open_to_connect
    ]
    return {"attendees": attendees, "total": len(regs)}


# ─────────────────────────────────────────────────────────────────────────────
# ALUMNI SEARCH
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/alumni/search")
def search_alumni(
    department: Optional[str] = None,
    graduation_year: Optional[int] = None,
    skill: Optional[str] = None,
    name: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """FR-U-06: Search the university alumni network."""
    q = db.query(User).filter(User.is_open_to_connect == True, User.status == UserStatus.ACTIVE)

    if department:
        q = q.filter(User.department.ilike(f"%{department}%"))
    if graduation_year:
        q = q.filter(User.graduation_year == graduation_year)
    if skill:
        q = q.filter(User.skills.ilike(f"%{skill}%"))
    if name:
        q = q.filter(User.name.ilike(f"%{name}%"))

    users = q.limit(50).all()
    return {
        "results": [
            {
                "id": u.id, "name": u.name, "profession": u.profession,
                "department": u.department, "graduation_year": u.graduation_year,
                "skills": u.skills, "bio": u.bio,
                "profile_image_url": u.profile_image_url,
            }
            for u in users
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# MATCHMAKING  (FR-U-09)
# ─────────────────────────────────────────────────────────────────────────────

COMPLEMENTARY_SKILLS = {
    "developer": ["designer", "ux", "product manager", "business analyst"],
    "designer":  ["developer", "frontend", "marketing"],
    "machine learning": ["data engineer", "backend", "product manager"],
    "data":      ["ml", "backend", "visualisation"],
    "marketing": ["designer", "content", "seo"],
    "finance":   ["accounting", "data analyst", "strategy"],
}

@app.get("/matchmaking/suggestions")
def get_suggestions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """FR-U-09: Complementary skills matchmaking."""
    my_skills = (current_user.skills or "").lower()
    my_profession = (current_user.profession or "").lower()

    target_keywords = []
    for keyword, complements in COMPLEMENTARY_SKILLS.items():
        if keyword in my_skills or keyword in my_profession:
            target_keywords.extend(complements)

    if not target_keywords:
        # Fallback: return random active open users
        users = db.query(User).filter(
            User.id != current_user.id,
            User.is_open_to_connect == True,
            User.status == UserStatus.ACTIVE
        ).limit(10).all()
    else:
        from sqlalchemy import func
        users = []
        seen = set()
        for kw in target_keywords:
            matches = db.query(User).filter(
                User.id != current_user.id,
                User.is_open_to_connect == True,
                User.status == UserStatus.ACTIVE,
                or_(User.skills.ilike(f"%{kw}%"), User.profession.ilike(f"%{kw}%"))
            ).limit(5).all()
            for u in matches:
                if u.id not in seen:
                    users.append(u)
                    seen.add(u.id)

    return {
        "suggestions": [
            {
                "id": u.id, "name": u.name, "profession": u.profession,
                "skills": u.skills, "department": u.department,
                "profile_image_url": u.profile_image_url,
            }
            for u in users[:15]
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# BADGES  (FR-U-10)
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/badges/my")
def get_my_badges(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get all badges earned by the current user."""
    user_badges = db.query(UserBadge).filter(UserBadge.user_id == current_user.id).all()
    return {
        "badges": [
            {
                "name": ub.badge.name,
                "description": ub.badge.description,
                "icon_url": ub.badge.icon_url,
                "earned_at": ub.earned_at,
            }
            for ub in user_badges
        ]
    }


def award_badge_if_eligible(user: User, db: Session):
    """Internal helper: check and award badges after relevant actions."""
    existing_badge_ids = {ub.badge_id for ub in user.badges}

    all_badges = db.query(Badge).all()
    for badge in all_badges:
        if badge.id in existing_badge_ids:
            continue

        criteria = json.loads(badge.criteria or "{}")
        awarded = False

        if criteria.get("type") == "event_attendee":
            count = db.query(EventRegistration).filter(EventRegistration.user_id == user.id).count()
            if count >= criteria.get("min_events", 1):
                awarded = True

        elif criteria.get("type") == "connections":
            count = db.query(Connection).filter(
                or_(Connection.sender_id == user.id, Connection.receiver_id == user.id),
                Connection.status == ConnectionStatus.ACCEPTED
            ).count()
            if count >= criteria.get("min_connections", 5):
                awarded = True

        elif criteria.get("type") == "profile_complete":
            fields = ["bio", "skills", "profession", "course", "department"]
            if all(getattr(user, f) for f in fields):
                awarded = True

        if awarded:
            db.add(UserBadge(user_id=user.id, badge_id=badge.id))
    db.commit()


# ─────────────────────────────────────────────────────────────────────────────
# ADMIN AUTH
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/admin/register", status_code=201)
def register_admin(data: AdminRegister, db: Session = Depends(get_db)):
    """One-time admin registration (protect this endpoint in production)."""
    if db.query(Admin).filter(Admin.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    admin = Admin(email=data.email, hashed_password=hash_password(data.password), name=data.name)
    db.add(admin)
    db.commit()
    return {"message": "Admin registered"}


@app.post("/admin/token")
def admin_login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """FR-A-01: Admin login."""
    admin = db.query(Admin).filter(Admin.email == form_data.username).first()
    if not admin or not verify_password(form_data.password, admin.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid admin credentials")
    token = create_access_token(
        data={"sub": admin.email, "role": "admin"},
        expires_delta=timedelta(hours=8)
    )
    return {"access_token": token, "token_type": "bearer"}


# ─────────────────────────────────────────────────────────────────────────────
# ADMIN ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/admin/events/pending")
def get_pending_events(admin: Admin = Depends(get_current_admin), db: Session = Depends(get_db)):
    """FR-A-02: List events awaiting approval."""
    events = db.query(Event).filter(Event.status == EventStatus.PENDING).all()
    return {"events": [{"id": e.id, "title": e.title, "organizer": e.organizer,
                         "start_time": e.start_time, "location_name": e.location_name} for e in events]}


@app.post("/admin/events/{event_id}/review")
def review_event(
    event_id: int,
    approve: bool,
    admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """FR-A-02: Approve or reject an event."""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    event.status = EventStatus.APPROVED if approve else EventStatus.REJECTED
    db.commit()
    return {"message": f"Event {'approved' if approve else 'rejected'}"}


@app.get("/admin/users")
def list_users(
    skip: int = 0,
    limit: int = 50,
    admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """FR-A-03: List all users."""
    users = db.query(User).offset(skip).limit(limit).all()
    return {
        "users": [
            {"id": u.id, "name": u.name, "email": u.email,
             "status": u.status, "is_open_to_connect": u.is_open_to_connect,
             "created_at": u.created_at}
            for u in users
        ]
    }


@app.put("/admin/users/{user_id}/status")
def update_user_status(
    user_id: int,
    new_status: str,
    admin: Admin = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """FR-A-03: Suspend or ban a user."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        user.status = UserStatus(new_status)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid status: {new_status}")
    db.commit()
    return {"message": f"User status updated to {new_status}"}

# ─────────────────────────────────────────────────────────────────────────────
# PROFILE IMAGE  
# ─────────────────────────────────────────────────────────────────────────────

class ProfileImageUpdate(BaseModel):
    profile_image_url: str

@app.put("/profile/image")
def update_profile_image(
    data: ProfileImageUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update profile image URL."""
    current_user.profile_image_url = data.profile_image_url
    db.commit()
    db.refresh(current_user)
    return {"message": "Profile image updated", "profile_image_url": current_user.profile_image_url}

@app.get("/")
def root():
    return {"message": "Proximity Professional Network API v1.1", "docs": "/docs"}
