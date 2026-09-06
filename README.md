# Productivity Agent

AI Productivity Agent for RUET EEE students preparing for the BCS exam.

## Live Web App

The web version is deployed via GitHub Pages (served from the `docs/` folder).

## Structure

- `mobile_app/` — Flutter app (Android, Windows, Web)
- `backend/` — FastAPI backend (Gemini AI agent)
- `docs/` — Prebuilt web version (GitHub Pages)

## Features

- Task management with priorities, categories, and due dates
- Pomodoro focus timer with XP rewards
- BCS exam preparation tracker (subjects, topics, mock tests)
- Daily habits with streaks
- AI chat agent (Gemini-powered)
- Study analytics with activity heatmap
- Focus Lock (Android app blocker)

## Development

```bash
# Run the app locally
cd mobile_app
flutter run

# Build web version (output: mobile_app/build/web)
flutter build web --release
# Copy to docs/ for GitHub Pages deployment
```

```bash
# Run the backend
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```
