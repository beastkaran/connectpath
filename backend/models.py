from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Float, Text, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
from geoalchemy2 import Geography
import enum

Base = declarative_base()

class UserStatus(str, enum.Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    BANNED = "banned"

class ConnectionStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"

class EventStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    name = Column(String, nullable=False)
    profession = Column(String)
    course = Column(String)
    department = Column(String)
    graduation_year = Column(Integer)
    skills = Column(Text)  # JSON string
    credentials = Column(Text)  # JSON string
    bio = Column(Text)
    profile_image_url = Column(String)
    
    # Privacy settings
    is_open_to_connect = Column(Boolean, default=False)
    status = Column(Enum(UserStatus), default=UserStatus.ACTIVE)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    location_logs = relationship("LocationLog", back_populates="user", cascade="all, delete-orphan")
    sent_connections = relationship("Connection", foreign_keys="Connection.sender_id", back_populates="sender")
    received_connections = relationship("Connection", foreign_keys="Connection.receiver_id", back_populates="receiver")
    event_registrations = relationship("EventRegistration", back_populates="user")
    badges = relationship("UserBadge", back_populates="user")

class LocationLog(Base):
    __tablename__ = "location_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # PostGIS geography type for efficient spatial queries
    location = Column(Geography(geometry_type='POINT', srid=4326), nullable=False)
    
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Relationship
    user = relationship("User", back_populates="location_logs")
    
    __table_args__ = (
        # Index for spatial queries
        {'schema': 'public'}
    )

class Connection(Base):
    __tablename__ = "connections"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(ConnectionStatus), default=ConnectionStatus.PENDING)
    message = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_connections")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_connections")

class Event(Base):
    __tablename__ = "events"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    location_name = Column(String, nullable=False)
    location = Column(Geography(geometry_type='POINT', srid=4326))
    
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    
    organizer = Column(String)
    capacity = Column(Integer)
    status = Column(Enum(EventStatus), default=EventStatus.PENDING)
    
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    registrations = relationship("EventRegistration", back_populates="event")

class EventRegistration(Base):
    __tablename__ = "event_registrations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    
    registered_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="event_registrations")
    event = relationship("Event", back_populates="registrations")

class Badge(Base):
    __tablename__ = "badges"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(Text)
    icon_url = Column(String)
    criteria = Column(Text)  # JSON string describing criteria
    
    # Relationships
    user_badges = relationship("UserBadge", back_populates="badge")

class UserBadge(Base):
    __tablename__ = "user_badges"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    badge_id = Column(Integer, ForeignKey("badges.id"), nullable=False)
    
    earned_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="badges")
    badge = relationship("Badge", back_populates="user_badges")

class Admin(Base):
    __tablename__ = "admins"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    name = Column(String, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)