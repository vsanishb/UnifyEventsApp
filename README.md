# UnifyEvents

A full-stack campus event management platform built for colleges and universities to streamline event discovery, registrations, bookings, QR-based attendance, organiser management, and real-time event operations across web and mobile.

---

# Overview

UnifyEvents is designed as a modern event ecosystem where:

* Students can discover and register for events
* Organisers can manage events, slots, and participants
* Admins can oversee the complete platform
* QR-based attendance enables secure check-ins
* Mobile-first workflows improve event-day operations
* Offline caching and sync support improve reliability

The platform consists of:

* Django REST Framework backend
* Flutter mobile application
* React web dashboard
* JWT + Google OAuth authentication
* QR-based attendance system
* Role-based access control system

---

# Features

## Authentication

* JWT Authentication
* Google OAuth Login
* Parallel OAuth + Email login support
* Role-based access control
* Persistent sessions
* Automatic logout on expired credentials

---

# User Roles

## Participant

* Browse events
* Filter and search events
* Add events to cart
* Register/book tickets
* View digital passes
* Access QR tickets
* Offline ticket access

## Organiser

* Manage assigned events
* Scan participant QR codes
* Confirm participant check-ins
* View participant details
* Manage slots and constraints

## Admin

* Full platform control
* Manage all events
* Manage organisers
* Access all attendance flows
* Platform-wide visibility

---

# Event Management

* Event creation/editing
* Parent event hierarchy
* Category-based organization
* Slot management
* Team constraints
* Pricing support
* Exclusive events
* Event image support
* Organiser assignment system

---

# QR Attendance System

## Features

* Individual QR per participant
* Secure token-based QR validation
* One-time QR usage
* Real-time attendance tracking
* Invalid QR handling
* Already checked-in detection
* Organiser permission validation
* QR invalidation after check-in

## Attendance Flow

1. Participant opens digital ticket
2. Organiser scans QR
3. App fetches preview details
4. Organiser confirms check-in
5. Backend validates permissions
6. Attendance is marked
7. QR becomes invalid

---

# Offline Support

## Participant Side

* Ticket caching
* Offline ticket viewing
* Cached event details
* Persistent bookings

## Organiser Side

* Cached participant data
* Offline scan queue
* Deferred sync engine
* Retry mechanism for failed scans

---

# Tech Stack

## Backend

* Django
* Django REST Framework
* JWT Authentication
* Google OAuth
* SQLite/PostgreSQL
* QR Token System

## Mobile App

* Flutter
* Riverpod
* Dio
* GoRouter
* Mobile Scanner
* Secure Storage
* Offline Cache Layer

## Web App

* React
* Modern responsive dashboard UI
* Role-aware navigation
* Event management tools

---

# UI/UX Design System

## Theme

* Premium dark theme
* Fully black backgrounds
* Cyan accent system (#26CCC2)
* Strong bordered card system
* Glassmorphism-inspired UI
* Mobile-first layouts

## Typography

* Mona Sans
* Brier Serif

---

# Core Modules

## Events

* Event browsing
* Search
* Filtering
* Categories
* Parent events
* Event details
* Slot management

## Cart & Checkout

* Cart management
* Quantity handling
* Order summary
* Booking confirmation
* Secure checkout flow

## Tickets

* Digital event passes
* Individual participant tickets
* Swipeable ticket UI
* QR code generation
* Checked-in states

## Scanner

* QR scanning
* Participant preview
* Check-in confirmation
* Error handling
* Role validation

---

# Security Features

* JWT-based authorization
* Role-based route protection
* Organiser event access restrictions
* QR invalidation after usage
* Secure offline sync handling
* Protected attendance APIs
* Token validation checks

---

# Project Structure

## Backend

```bash
backend/
├── app/
├── authentication/
├── events/
├── bookings/
├── qr/
└── manage.py
```

## Flutter App

```bash
lib/
├── core/
├── features/
│   ├── auth/
│   ├── events/
│   ├── bookings/
│   ├── cart/
│   ├── scan/
│   ├── profile/
│   └── home/
├── shared/
└── main.dart
```

---

# Installation

## Backend Setup

```bash
git clone <repository-url>
cd backend

python -m venv venv
venv\Scripts\activate

pip install -r requirements.txt

python manage.py makemigrations
python manage.py migrate

python manage.py runserver
```

---

## Flutter App Setup

```bash
cd frontend

flutter pub get

flutter run
```

---

# Environment Variables

Create a `.env` file:

```env
SECRET_KEY=
DEBUG=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
JWT_SECRET=
DATABASE_URL=
```

---

# API Highlights

## Authentication

```http
POST /auth/login/
POST /auth/register/
POST /auth/google/
```

## Events

```http
GET /events/
GET /categories/
GET /parent-events/
```

## Cart

```http
GET /cart/
POST /cart/add/
```

## Bookings

```http
POST /bookings/create/
GET /bookings/
```

## QR Attendance

```http
POST /qr/preview/
POST /qr/checkin/
```

---

# Performance Optimizations

* Offline caching
* Optimized event fetching
* Debounced searching
* Lazy loading
* Efficient image handling
* Sync retry engine
* Scan locking system
* Reduced rebuilds

---

# Future Improvements

* Push notifications
* Live announcements
* Event analytics dashboard
* Wallet integration
* AI recommendations
* NFC attendance
* Multi-college support
* Real-time event chat

---

# Development Goals

UnifyEvents aims to provide:

* A production-ready campus event ecosystem
* Fast event-day operations
* Smooth participant experience
* Reliable organiser tooling
* Modern UI/UX standards
* Scalable architecture

---

# License

MIT Licence
