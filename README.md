# Medfold

**Your health records, intelligently folded.**

Medfold is a native iOS app that gives you a single, secure place to store all your health documents. Upload a lab result, prescription, or imaging report and AI automatically summarizes it, extracts key values, and makes it searchable. Then ask questions about your records in a conversational chat.

## Features

**Document Vault** - Upload health records via camera, photo library, or file picker. Organize across 7 categories (Labs, Rx, Imaging, Insurance, Visits, Immunization, Other). Search across titles, tags, AI summaries, and provider names.

**AI Analysis** - Every uploaded document is automatically processed: a 2-3 sentence summary, category suggestion, extracted key values (lab metrics, dosages, dates, reference ranges), and provider identification.

**AI Chat** - Ask questions about your health records in natural language. The assistant loads your recent documents as context and can reference specific records in its answers. Includes suggested prompts like "Summarize my recent lab results" and "Are there any concerning patterns?"

**Security First** - Row Level Security on every database table, per-user storage folder isolation, AES-256 encryption at rest, Sign in with Apple, email/password, and Face ID/Touch ID biometric unlock.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift, SwiftUI, MVVM (iOS 17+) |
| Backend | Supabase (Postgres 15, Auth, Storage, Edge Functions) |
| AI | Provider-agnostic: Anthropic Claude or OpenAI GPT, switchable via env var |
| Auth | Sign in with Apple, email/password, Face ID/Touch ID |
| Edge Functions | Deno/TypeScript with SSE streaming |

## Architecture Highlights

- **Protocol-oriented services**: Every service (Auth, Documents, Storage, AI) is defined as a Swift protocol with a concrete implementation, making it easy to swap backends or mock for testing.
- **Provider-agnostic AI**: A shared TypeScript `AIProvider` interface with Anthropic and OpenAI implementations. Switch providers by changing one environment variable.
- **Streaming chat**: The `ai-chat` Edge Function returns Server-Sent Events, normalizing both Anthropic and OpenAI streaming formats into a unified event shape.
- **JSONB for extracted data**: AI-extracted values are stored in a PostgreSQL JSONB column with a GIN index, allowing flexible schema-free storage of lab metrics, dosages, and reference ranges.
- **Strict Swift concurrency**: `SWIFT_STRICT_CONCURRENCY: complete` enabled, all ViewModels are `@MainActor`, async/await throughout.

## Project Structure

```
Medfold/                  # iOS app source
  App/                    # Entry point, tab navigation
  Models/                 # Document, Profile, AIConversation
  Views/                  # SwiftUI views (Auth, Documents, AI Chat, Profile)
  ViewModels/             # MVVM view models
  Services/               # Protocol-based service layer + Supabase implementations
  Utilities/              # Supabase client singleton, constants

supabase/                 # Backend
  migrations/             # Postgres schema, enums, RLS policies, triggers
  functions/
    _shared/              # AI provider abstraction (Anthropic + OpenAI)
    analyze-doc/          # Document analysis Edge Function
    ai-chat/              # Streaming chat Edge Function
```

## Getting Started

### Prerequisites

- Xcode 16+
- A [Supabase](https://supabase.com) project (free tier works)
- An AI provider API key ([Anthropic](https://console.anthropic.com) or [OpenAI](https://platform.openai.com))

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/shaan-ad/Medfold.git
   cd Medfold
   ```

2. **Configure Supabase credentials** in `Medfold/Utilities/Constants.swift`:
   ```swift
   static let supabaseURL = "https://your-project.supabase.co"
   static let supabaseAnonKey = "your-anon-key"
   ```

3. **Run the database migration**: Copy `supabase/migrations/001_create_tables.sql` into your Supabase SQL Editor and execute it. This creates all tables, enums, RLS policies, triggers, and the storage bucket.

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

> **Note:** The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen). To regenerate the Xcode project from `project.yml`, run `xcodegen generate`.

## Roadmap

- [x] Secure document vault with upload, search, and category filtering
- [x] AI document analysis with summary and key value extraction
- [x] AI chat with health record context and streaming responses
- [x] Multi-method auth (Apple, email, biometric)
- [ ] Apple HealthKit integration (Apple Watch data)
- [ ] Whoop and Oura wearable sync
- [ ] Structured data entry (medications, allergies, vitals)
- [ ] Trend charts and health dashboards

## License

MIT
