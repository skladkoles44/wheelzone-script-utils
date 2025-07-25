-- WheelZone Core DB Schema
-- Autogen v1.0 — Tables in schema wz

CREATE SCHEMA IF NOT EXISTS wz;

CREATE TABLE IF NOT EXISTS wz.rules (
    id UUID PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.chatends (
    id UUID PRIMARY KEY,
    file_name TEXT UNIQUE NOT NULL,
    summary TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.tasks (
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.insights (
    id UUID PRIMARY KEY,
    content TEXT NOT NULL,
    source TEXT,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.log_events (
    id UUID PRIMARY KEY,
    event_type TEXT NOT NULL,
    message TEXT,
    severity TEXT,
    source TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.agents (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT,
    status TEXT,
    meta JSONB,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.registry (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    path TEXT NOT NULL,
    version TEXT,
    tags TEXT[],
    status TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.chat_links (
    id UUID PRIMARY KEY,
    from_chat UUID NOT NULL,
    to_chat UUID NOT NULL,
    relation TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.script_events (
    id UUID PRIMARY KEY,
    script TEXT NOT NULL,
    status TEXT,
    message TEXT,
    context JSONB,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wz.core_meta (
    id UUID PRIMARY KEY,
    key TEXT NOT NULL,
    value TEXT,
    updated_at TIMESTAMP DEFAULT now()
);
