/*
Advanced Task Manager Database
Author: Thembelani Bukali
Date: 2025 May 05
Features:
- Schema separation
- Advanced constraints
- Full-text search
- JSON support
- Optimized indexes
- Partitioning for large datasets
*/

CREATE SCHEMA IF NOT EXISTS task_manager;

-- Users table with advanced security features
CREATE TABLE task_manager.users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    metadata JSONB,
    CONSTRAINT email_unique UNIQUE (email),
    CONSTRAINT username_unique UNIQUE (username),
    CONSTRAINT email_check CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$'),
    CONSTRAINT username_check CHECK (username ~* '^[a-zA-Z0-9_-]+$')
);

-- Create index for faster lookups
CREATE INDEX idx_users_email ON task_manager.users (email);
CREATE INDEX idx_users_username ON task_manager.users (username);
CREATE INDEX idx_users_active ON task_manager.users (is_active) WHERE is_active = TRUE;

-- Tasks table with full-text search
CREATE TABLE task_manager.tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'archived')),
    priority VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    due_date DATE,
    owner_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tags VARCHAR(50)[] DEFAULT '{}',
    metadata JSONB,
    CONSTRAINT fk_owner FOREIGN KEY (owner_id) REFERENCES task_manager.users(id) ON DELETE CASCADE
);

-- Add default value for tags column
ALTER TABLE task_manager.tasks ALTER COLUMN tags SET DEFAULT '{}';

-- Add full-text search index
CREATE INDEX idx_tasks_title_description ON task_manager.tasks USING gin(to_tsvector('english', title || ' ' || description));
CREATE INDEX idx_tasks_status ON task_manager.tasks (status);
CREATE INDEX idx_tasks_priority ON task_manager.tasks (priority);
CREATE INDEX idx_tasks_due_date ON task_manager.tasks (due_date);
CREATE INDEX idx_tasks_owner ON task_manager.tasks (owner_id);

-- Categories table
CREATE TABLE task_manager.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_by INTEGER REFERENCES task_manager.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT category_name_unique UNIQUE (name)
);

-- Task-Category many-to-many relationship
CREATE TABLE task_manager.task_categories (
    task_id INTEGER NOT NULL REFERENCES task_manager.tasks(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES task_manager.categories(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    assigned_by INTEGER REFERENCES task_manager.users(id) ON DELETE SET NULL,
    PRIMARY KEY (task_id, category_id)
);

-- Audit log table
CREATE TABLE task_manager.audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER REFERENCES task_manager.users(id) ON DELETE SET NULL,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (changed_at);

-- Create monthly partitions for audit log
CREATE TABLE task_manager.audit_log_2023_01 PARTITION OF task_manager.audit_log
    FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');
CREATE TABLE task_manager.audit_log_2023_02 PARTITION OF task_manager.audit_log
    FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');
CREATE TABLE task_manager.audit_log_2023_03 PARTITION OF task_manager.audit_log
    FOR VALUES FROM ('2023-03-01') TO ('2023-04-01');

-- Create indexes on audit log
CREATE INDEX idx_audit_log_table_record ON task_manager.audit_log (table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON task_manager.audit_log (changed_at);
CREATE INDEX idx_audit_log_changed_by ON task_manager.audit_log (changed_by);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON task_manager.users
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_tasks_modtime
BEFORE UPDATE ON task_manager.tasks
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Insert sample data
INSERT INTO task_manager.users (email, username, hashed_password, full_name, is_superuser)
VALUES 
('admin@taskmanager.co.za', 'admin', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Admin User', TRUE),
('user@taskmanager.co.za', 'user1', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Sipho Nkosi', FALSE);

INSERT INTO task_manager.tasks (title, description, status, priority, owner_id, due_date)
VALUES
('Complete project', 'Finish the API implementation for the Task Manager', 'pending', 'high', 1, '2023-06-15'),
('Write documentation', 'Document all endpoints for the Task Manager API', 'in_progress', 'medium', 1, '2023-06-10'),
('Review code', 'Peer review of new features added to the API', 'pending', 'medium', 2, '2023-06-12');

INSERT INTO task_manager.categories (name, description, created_by)
VALUES
('work', 'Tasks related to professional work or projects', 1),
('personal', 'Personal tasks and errands', 1),
('health', 'Health and fitness-related tasks', 2);

INSERT INTO task_manager.task_categories (task_id, category_id, assigned_by)
VALUES
(1, 1, 1),
(2, 1, 1),
(3, 2, 2);