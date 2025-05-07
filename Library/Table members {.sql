Table members {
    member_id INT [pk, increment]
    first_name VARCHAR(50) [not null]
    last_name VARCHAR(50) [not null]
    email VARCHAR(100) [not null, unique]
    phone VARCHAR(20)
    address JSON
    membership_date DATE [not null]
    membership_expiry DATE
    membership_status ENUM('active', 'expired', 'suspended') [default: 'active']
    created_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
    updated_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
}

Table authors {
    author_id INT [pk, increment]
    name VARCHAR(100) [not null]
    birth_date DATE
    death_date DATE
    nationality VARCHAR(50)
    biography TEXT
}

Table publishers {
    publisher_id INT [pk, increment]
    name VARCHAR(100) [not null, unique]
    address JSON
    contact_info JSON
    is_active BOOLEAN [default: true]
    deleted_at TIMESTAMP
    created_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
    updated_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
}

Table books {
    book_id INT [pk, increment]
    title VARCHAR(255) [not null]
    isbn VARCHAR(20) [not null, unique]
    publisher_id INT [ref: > publishers.publisher_id]
    publication_year SMALLINT
    edition SMALLINT
    category ENUM('Fiction', 'Non-Fiction', 'Reference', 'Periodical')
    language CHAR(2) [default: 'en']
    metadata JSON
    total_copies SMALLINT [not null, default: 1]
    available_copies SMALLINT [not null, default: 1]
    created_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
    updated_at TIMESTAMP [default: 'CURRENT_TIMESTAMP']
}

Table book_authors {
    book_id INT [ref: > books.book_id]
    author_id INT [ref: > authors.author_id]
    contribution_type ENUM('Primary', 'Secondary', 'Editor', 'Translator') [default: 'Primary']
    royalty_percentage DECIMAL(5,2)
    indexes {
        (book_id, author_id) [unique]
    }
}

Table loans {
    loan_id INT [pk, increment]
    book_id INT [ref: > books.book_id]
    member_id INT [ref: > members.member_id]
    loan_date DATETIME [default: 'CURRENT_TIMESTAMP']
    due_date DATETIME [not null]
    return_date DATETIME
    status ENUM('active', 'returned', 'overdue', 'lost') [default: 'active']
    renewed_count TINYINT [default: 0]
    last_renewal_date DATETIME
    notes TEXT
}

Table fines {
    fine_id INT [pk, increment]
    loan_id INT [ref: > loans.loan_id]
    amount DECIMAL(10,2) [not null]
    reason ENUM('late', 'damage', 'lost') [not null]
    issue_date DATETIME [default: 'CURRENT_TIMESTAMP']
    payment_date DATETIME
    status ENUM('pending', 'paid', 'waived', 'cancelled') [default: 'pending']
    created_by INT [ref: > members.member_id]
    updated_at DATETIME [default: 'CURRENT_TIMESTAMP']
}

Table audit_log {
    audit_id INT [pk, increment]
    table_name VARCHAR(50) [not null]
    record_id INT [not null]
    action ENUM('INSERT', 'UPDATE', 'DELETE') [not null]
    old_values JSON
    new_values JSON
    changed_by INT [ref: > members.member_id]
    changed_at DATETIME [default: 'CURRENT_TIMESTAMP']
}

Ref: books.publisher_id > publishers.publisher_id
Ref: book_authors.book_id > books.book_id
Ref: book_authors.author_id > authors.author_id
Ref: loans.book_id > books.book_id
Ref: loans.member_id > members.member_id
Ref: fines.loan_id > loans.loan_id
Ref: fines.created_by > members.member_id [name: "fk_fines_created_by"]
Ref: audit_log.changed_by > members.member_id [name: "fk_audit_log_changed_by"]
