# Medfold

A secure iOS app for storing, organizing, and analyzing personal health records with AI.

## What it does

- **Document Vault**: Upload and organize health records (lab results, prescriptions, imaging, insurance cards, visit summaries)
- **AI Analysis**: Documents are automatically summarized and key values extracted (lab metrics, medications, dates)
- **AI Chat**: Ask questions about your health records, spot trends, and get insights
- **Secure by default**: Row Level Security, encrypted storage, per-user data isolation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift, SwiftUI, MVVM |
| Backend | Supabase (Postgres, Auth, Storage, Edge Functions) |
| AI | Provider-agnostic (Claude, GPT, or others via config) |
| Auth | Sign in with Apple + email/password + Face ID |

## Project Structure

```
Medfold/              # iOS app
  App/                # Entry point, tab navigation
  Models/             # Data models (Document, Profile, AIConversation)
  Views/              # SwiftUI views (Auth, Documents, AI, Profile)
  ViewModels/         # MVVM view models
  Services/           # Backend service protocols + Supabase implementations
  Utilities/          # Supabase client, constants

supabase/             # Backend
  migrations/         # Postgres schema + RLS policies
  functions/          # Edge Functions (document analysis, AI chat)
```

## Getting Started

### Prerequisites

- Xcode 16+
- A [Supabase](https://supabase.com) project
- An AI provider API key (Anthropic or OpenAI)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/shaan-ad/Medfold.git
   cd Medfold
   ```

2. **Configure Supabase**: Update `Medfold/Utilities/Constants.swift` with your Supabase project URL and anon key.

3. **Run the database migration**: Copy `supabase/migrations/001_create_tables.sql` into your Supabase SQL Editor and run it.

4. **Set Edge Function secrets** in your Supabase dashboard:
   ```
   AI_PROVIDER=anthropic
   ANTHROPIC_API_KEY=your_key_here
   ```

5. **Deploy Edge Functions**:
   ```bash
   supabase functions deploy analyze-doc
   supabase functions deploy ai-chat
   ```

6. **Open in Xcode**: Open `Medfold.xcodeproj`, select a simulator or device, and run.

## Roadmap

- [x] Secure document vault with upload, search, and filtering
- [x] AI document analysis (summary + key value extraction)
- [x] AI chat with health record context
- [ ] Apple HealthKit integration (Apple Watch data)
- [ ] Whoop and Oura wearable sync
- [ ] Structured data entry (medications, allergies, vitals)
- [ ] Trend charts and health dashboards

## License

MIT
