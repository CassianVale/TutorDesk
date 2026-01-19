# TutorDesk

TutorDesk is a lightweight macOS app for tutoring workflow and schedule planning. It helps you organize students, manage enrollment “terms” (e.g., Spring/Winter), and reduce time conflicts in course scheduling.

> **Platform**: macOS only (built with Xcode / SwiftUI).  
> **Windows/Linux**: not supported.

---

## Features

- Student management (create, edit, delete)
- Enrollment / term templates (e.g., Spring 2026, Winter break)
- Course scheduling helpers to reduce time conflicts
- Local-first data (no server required)

---

## Requirements

- macOS 13.0 or later (recommended)
- Apple Silicon or Intel Mac

---

## Download & Install (macOS)

1. Go to **Releases** and download the latest `TutorDesk.zip`.
2. Unzip it to get `TutorDesk.app`.
3. Move `TutorDesk.app` to `/Applications` (recommended).
4. Open the app.

### If macOS blocks the app (“can’t be opened”)

Because the app may be **unsigned / not notarized**, macOS Gatekeeper may block it.

- **Option A (recommended for users):**
  1. Right-click `TutorDesk.app`
  2. Choose **Open**
  3. Confirm **Open** again

- **Option B: System Settings**
  1. Open **System Settings → Privacy & Security**
  2. Find the warning about TutorDesk
  3. Click **Open Anyway**

---

## Build from Source (Developers)

1. Clone the repository:
   ```bash
   git clone https://github.com/CassianVale/TutorDesk.git
   cd TutorDesk
