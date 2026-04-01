-- ============================================================
-- Personal EHR: Database Schema + Row Level Security
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- ENUMS
-- ============================================================

create type document_category as enum (
    'lab_result',
    'prescription',
    'imaging',
    'insurance',
    'visit_summary',
    'immunization',
    'other'
);

create type document_status as enum (
    'processing',
    'ready',
    'error'
);

create type message_role as enum (
    'user',
    'assistant'
);

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles (auto-created on auth signup)
create table profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    full_name text not null default '',
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Documents (health records)
create table documents (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references profiles(id) on delete cascade,
    title text not null,
    description text,
    category document_category not null default 'other',
    file_path text not null,
    file_type text not null,
    file_size bigint not null default 0,
    document_date date,
    provider_name text,
    tags text[] not null default '{}',
    ai_summary text,
    ai_extracted jsonb,
    status document_status not null default 'processing',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- AI Conversations
create table ai_conversations (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references profiles(id) on delete cascade,
    title text not null default 'New Conversation',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- AI Messages
create table ai_messages (
    id uuid primary key default uuid_generate_v4(),
    conversation_id uuid not null references ai_conversations(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    role message_role not null,
    content text not null,
    referenced_docs uuid[] not null default '{}',
    created_at timestamptz not null default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_documents_user_id on documents(user_id);
create index idx_documents_category on documents(user_id, category);
create index idx_documents_status on documents(user_id, status);
create index idx_documents_created_at on documents(user_id, created_at desc);
create index idx_ai_conversations_user_id on ai_conversations(user_id);
create index idx_ai_messages_conversation_id on ai_messages(conversation_id);
create index idx_ai_messages_user_id on ai_messages(user_id);

-- GIN index for tag searching
create index idx_documents_tags on documents using gin(tags);

-- GIN index for AI extracted JSONB searching
create index idx_documents_ai_extracted on documents using gin(ai_extracted);

-- ============================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================

create or replace function update_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger tr_profiles_updated_at
    before update on profiles
    for each row execute function update_updated_at();

create trigger tr_documents_updated_at
    before update on documents
    for each row execute function update_updated_at();

create trigger tr_ai_conversations_updated_at
    before update on ai_conversations
    for each row execute function update_updated_at();

-- ============================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================

create or replace function handle_new_user()
returns trigger as $$
begin
    insert into profiles (id, email, full_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', '')
    );
    return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
alter table profiles enable row level security;
alter table documents enable row level security;
alter table ai_conversations enable row level security;
alter table ai_messages enable row level security;

-- Profiles: users can only access their own profile
create policy "Users can view own profile"
    on profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on profiles for update
    using (auth.uid() = id);

-- Documents: users can only access their own documents
create policy "Users can view own documents"
    on documents for select
    using (auth.uid() = user_id);

create policy "Users can insert own documents"
    on documents for insert
    with check (auth.uid() = user_id);

create policy "Users can update own documents"
    on documents for update
    using (auth.uid() = user_id);

create policy "Users can delete own documents"
    on documents for delete
    using (auth.uid() = user_id);

-- AI Conversations: users can only access their own
create policy "Users can view own conversations"
    on ai_conversations for select
    using (auth.uid() = user_id);

create policy "Users can insert own conversations"
    on ai_conversations for insert
    with check (auth.uid() = user_id);

create policy "Users can update own conversations"
    on ai_conversations for update
    using (auth.uid() = user_id);

create policy "Users can delete own conversations"
    on ai_conversations for delete
    using (auth.uid() = user_id);

-- AI Messages: users can only access their own
create policy "Users can view own messages"
    on ai_messages for select
    using (auth.uid() = user_id);

create policy "Users can insert own messages"
    on ai_messages for insert
    with check (auth.uid() = user_id);

-- ============================================================
-- STORAGE BUCKET + POLICIES
-- ============================================================

-- Create documents storage bucket
insert into storage.buckets (id, name, public, file_size_limit)
values ('documents', 'documents', false, 52428800); -- 50MB limit

-- Storage: users can only access their own folder
create policy "Users can upload to own folder"
    on storage.objects for insert
    with check (
        bucket_id = 'documents'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can view own files"
    on storage.objects for select
    using (
        bucket_id = 'documents'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can delete own files"
    on storage.objects for delete
    using (
        bucket_id = 'documents'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
