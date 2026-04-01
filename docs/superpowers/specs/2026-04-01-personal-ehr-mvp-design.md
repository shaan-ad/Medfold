# Personal EHR - MVP Design Spec

## Context

Users have health records scattered across patient portals, paper files, and email attachments. There is no single place to store, organize, and make sense of all personal health data. Personal EHR solves this by providing a secure document vault with an AI intelligence layer that extracts insights, summarizes records, and answers questions about a user's health history.

This spec covers the MVP: secure document storage + basic AI analysis. Phase 2 (wearable integration, structured data entry) is out of scope but the architecture accommodates it.

## Product Overview

- **Platform:** iOS only (native Swift/SwiftUI)
- **Target users:** General consumers managing their own health records
- **Backend:** Supabase (Postgres, Auth, Storage, Edge Functions)
- **AI layer:** Provider-agnostic abstraction (swap Claude, GPT, or others via config)
- **Auth:** Sign in with Apple + email/password + biometric unlock (Face ID/Touch ID)
- **Compliance:** Standard security best practices (no HIPAA required)

## Architecture

### System Layers

1. **iOS App (SwiftUI + MVVM):** Three main flows (auth, document vault, AI chat) with a service layer abstracting all backend communication.
2. **Service Layer (Swift protocols):** AuthService, StorageService, DocumentService, AIService. Enables testing and future provider swaps.
3. **Supabase Backend:** Auth, Storage (encrypted files), Edge Functions (AI processing), Postgres (metadata + structured data).
4. **Postgres Database:** Row Level Security on every table. Users can only access their own data.

### Data Flow

```
iOS App <-> Supabase Auth (JWT)
iOS App <-> Supabase Storage (file upload/download)
iOS App <-> Supabase Edge Functions (AI requests)
Edge Functions <-> AI Provider (document analysis, chat)
Edge Functions <-> Postgres (read/write document metadata)
Supabase Realtime -> iOS App (live updates after AI processing)
```

## Data Model

### profiles
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | = auth.uid() |
| email | text | |
| full_name | text | |
| avatar_url | text? | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### documents
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | auto-generated |
| user_id | uuid (FK) | -> profiles.id |
| title | text | user-provided or AI-extracted |
| description | text? | optional notes |
| category | enum | lab_result, prescription, imaging, insurance, visit_summary, immunization, other |
| file_path | text | path in Supabase Storage |
| file_type | text | pdf, png, jpg, heic |
| file_size | bigint | bytes |
| document_date | date? | date of the document itself |
| provider_name | text? | doctor/facility name |
| tags | text[] | user-defined tags |
| ai_summary | text? | AI-generated summary |
| ai_extracted | jsonb? | structured data from AI (key values, metrics, dates) |
| status | enum | processing, ready, error |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### ai_conversations
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | |
| user_id | uuid (FK) | -> profiles.id |
| title | text | auto-generated from first message |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### ai_messages
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | |
| conversation_id | uuid (FK) | -> ai_conversations.id |
| user_id | uuid (FK) | -> profiles.id (for direct RLS) |
| role | enum | user, assistant |
| content | text | message text |
| referenced_docs | uuid[] | document IDs used as context |
| created_at | timestamptz | |

### RLS Policy
Every table has RLS enabled. All SELECT, INSERT, UPDATE, DELETE policies filter by `user_id = auth.uid()`. Storage policies restrict access to `/{user_id}/*` paths.

## App Screens

### Tab 1: Documents (DocumentListView)
- Search bar with text search across titles, tags, AI summaries
- Category filter pills (All, Labs, Rx, Imaging, Insurance, Visits, Other)
- Document cards showing: file type icon, title, provider, date, tags, AI summary snippet
- Pull to refresh
- "+" button to upload new document

### Document Upload (DocumentUploadView)
- Source picker: Camera, Photos, Files
- Form fields: Title (auto-filled by AI), Category (AI-suggested), Date, Provider, Tags
- Progress indicator during AI analysis
- Save button

### Document Detail (DocumentDetailView)
- Header: title, provider, date, tags
- AI Summary section
- Key Values section (extracted lab metrics, dosages, etc. from ai_extracted JSONB)
- "View Original Document" button (PDF viewer / image viewer)
- "Ask AI About This" button (opens AI chat with document pre-loaded as context)

### Tab 2: AI Chat (AIChatView)
- New chat / conversation list
- Suggested prompts for new conversations
- Chat bubbles with markdown rendering
- Streaming responses
- Referenced documents shown as tappable chips in assistant messages

### Tab 3: Profile (ProfileView)
- Account info (name, email)
- App settings
- Sign out
- Delete account (removes all data)

## AI Processing Pipeline

### Document Analysis (on upload)
1. File uploaded to Supabase Storage at `/{user_id}/{doc_id}/{filename}`
2. Document row created in Postgres with `status = "processing"`
3. Database webhook triggers `analyze-doc` Edge Function
4. Edge Function retrieves file, sends to AI provider with extraction prompt
5. AI returns: summary (2-3 sentences), category suggestion, key values (lab metrics, dates, dosages), provider name, document date
6. Document row updated with AI results, `status = "ready"`
7. App receives update via Supabase Realtime subscription

### AI Chat
1. User sends message to `ai-chat` Edge Function
2. Edge Function fetches relevant documents for context:
   - Keyword match on ai_extracted JSONB fields
   - Category filtering based on query intent
   - Recency weighting (newer documents ranked higher)
   - Max ~10 documents included as context
3. Builds prompt: system prompt (health assistant role) + document context + conversation history + user question
4. Streams response back to app
5. Saves message and referenced_docs to database

### AI Provider Abstraction
Edge Functions use an internal `AIProvider` interface:
- `analyzeDocument(fileContent, fileType)` returns `{ summary, category, extracted_data }`
- `chat(messages, documentContext)` returns `AsyncStream<String>`

Swap providers by changing an environment variable. No app update required.

## Security

### Authentication
- Sign in with Apple (OAuth via Supabase)
- Email + password with email confirmation
- JWT tokens managed by Supabase Auth SDK
- Biometric unlock (Face ID / Touch ID) for returning users via Keychain

### Data Isolation
- Row Level Security on every Postgres table
- Storage policies: users access only their own `/{user_id}/` folder
- Edge Functions verify JWT before processing any request

### Encryption
- TLS for all data in transit
- Supabase Storage: AES-256 encryption at rest
- Postgres: encrypted at rest by default
- AI API calls over HTTPS only

### Privacy
- AI providers process document content for analysis only (not used for training)
- Full account deletion removes all data (profile, documents, files, AI history)
- No analytics on document content
- Minimal PII in application logs

## Project Structure

```
Personal-EHR/
  PersonalEHR/                    # iOS App (Xcode project)
    App/
      PersonalEHRApp.swift        # App entry point
      ContentView.swift           # Root view with tab navigation
    Models/
      Document.swift
      AIConversation.swift
      Profile.swift
    Views/
      Auth/
        LoginView.swift
        RegisterView.swift
      Documents/
        DocumentListView.swift
        DocumentDetailView.swift
        DocumentUploadView.swift
      AI/
        AIChatView.swift
        AIMessageView.swift
      Profile/
        ProfileView.swift
    ViewModels/
      AuthViewModel.swift
      DocumentViewModel.swift
      AIChatViewModel.swift
    Services/
      AuthService.swift           # Supabase Auth wrapper
      StorageService.swift        # File upload/download
      DocumentService.swift       # CRUD for documents table
      AIService.swift             # Chat + analysis API calls
    Utilities/
      SupabaseClient.swift        # Singleton Supabase client
      Constants.swift             # API URLs, config

  supabase/                       # Supabase project config
    migrations/
      001_create_tables.sql       # Schema + RLS policies
    functions/
      analyze-doc/
        index.ts                  # Document analysis Edge Function
      ai-chat/
        index.ts                  # Chat Edge Function
    config.toml                   # Supabase local dev config
```

## Phase 2 (Future Scope)

Not part of this spec, but the architecture supports:

- **Wearable Integration:** Apple HealthKit for Apple Watch, Whoop and Oura via their REST APIs (OAuth). New HealthDataService, sync infrastructure, and health_data table.
- **Structured Data Entry:** Manual entry forms for medications, allergies, conditions, vitals. New tables and views. AI cross-references with wearable data for trend analysis and alerts.

## Verification

To verify the MVP works end-to-end:

1. **Auth flow:** Register with email, sign in with Apple, sign out, biometric re-auth
2. **Document upload:** Upload a PDF lab result, verify AI extracts summary and key values within ~10 seconds
3. **Document browsing:** Filter by category, search by text, view document detail with AI summary
4. **AI chat:** Ask "summarize my recent lab results", verify response references the uploaded document
5. **Data isolation:** Create two test accounts, verify neither can see the other's documents
6. **File viewing:** Open original PDF/image from document detail view
7. **Account deletion:** Delete account, verify all data (DB rows + storage files) is removed
