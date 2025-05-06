-- Advanced Library Management System
-- Author: [Your Name]
-- Date: [Current Date]
-- Features: 
-- - Schema versioning with migrations
-- - Advanced constraints and indexes
-- - Optimized for performance
-- - Full ACID compliance
-- - Data validation at DB level

-- Database setup with strict mode for data integrity
SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- Main database creation
DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE library_management;

-- ======================
-- TABLES WITH ADVANCED FEATURES
-- ======================

-- Members with advanced constraints
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address JSON, -- Using JSON for flexible address structure
    membership_date DATE NOT NULL,
    membership_expiry DATE GENERATED ALWAYS AS (DATE_ADD(membership_date, INTERVAL 1 YEAR)) STORED,
    membership_status ENUM('active', 'expired', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_email CHECK (email REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$'),
    CONSTRAINT chk_phone CHECK (phone REGEXP '^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\\s\\./0-9]*$'),
    INDEX idx_member_name (last_name, first_name),
    UNIQUE INDEX idx_member_email (email)
) ENGINE=InnoDB;

-- Authors with full-text search support
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth_date DATE,
    death_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT chk_dates CHECK (death_date IS NULL OR birth_date < death_date),
    FULLTEXT INDEX ft_author_name (name)
) ENGINE=InnoDB;

-- Publishers with soft delete
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address JSON,
    contact_info JSON,
    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_publisher_name (name)
) ENGINE=InnoDB;

-- Books with advanced features
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    publisher_id INT,
    publication_year SMALLINT,
    edition SMALLINT UNSIGNED,
    category ENUM('Fiction', 'Non-Fiction', 'Reference', 'Periodical'),
    language CHAR(2) DEFAULT 'en',
    metadata JSON, -- For flexible additional data
    total_copies SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    available_copies SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (publisher_id) 
        REFERENCES publishers(publisher_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    CONSTRAINT chk_isbn CHECK (isbn REGEXP '^(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]$'),
    CONSTRAINT chk_publication_year CHECK (publication_year BETWEEN 1500 AND YEAR(CURRENT_DATE)),
    CONSTRAINT chk_copies CHECK (available_copies <= total_copies),
    FULLTEXT INDEX ft_book_title (title),
    UNIQUE INDEX idx_book_isbn (isbn)
) ENGINE=InnoDB;

-- Book-Author relationship with additional metadata
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type ENUM('Primary', 'Secondary', 'Editor', 'Translator') DEFAULT 'Primary',
    royalty_percentage DECIMAL(5,2),
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) 
        REFERENCES books(book_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (author_id) 
        REFERENCES authors(author_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT chk_royalty CHECK (royalty_percentage BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- Loans with advanced tracking
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATETIME NOT NULL,
    return_date DATETIME NULL,
    status ENUM('active', 'returned', 'overdue', 'lost') DEFAULT 'active',
    renewed_count TINYINT UNSIGNED DEFAULT 0,
    last_renewal_date DATETIME NULL,
    notes TEXT,
    FOREIGN KEY (book_id) 
        REFERENCES books(book_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    FOREIGN KEY (member_id) 
        REFERENCES members(member_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_due_date CHECK (due_date > loan_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= loan_date),
    INDEX idx_loan_status (status),
    INDEX idx_loan_dates (due_date, return_date)
) ENGINE=InnoDB;

-- Fines with audit trail
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount DECIMAL(10, 2) UNSIGNED NOT NULL,
    reason ENUM('late', 'damage', 'lost') NOT NULL,
    issue_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_date DATETIME NULL,
    status ENUM('pending', 'paid', 'waived', 'cancelled') DEFAULT 'pending',
    created_by INT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) 
        REFERENCES loans(loan_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    FOREIGN KEY (created_by) 
        REFERENCES members(member_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    CONSTRAINT chk_amount CHECK (amount > 0),
    INDEX idx_fine_status (status),
    INDEX idx_fine_dates (issue_date, payment_date)
) ENGINE=InnoDB;

-- Audit table for tracking changes
CREATE TABLE audit_log (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by INT,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (changed_by) 
        REFERENCES members(member_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_record (table_name, record_id),
    INDEX idx_audit_date (changed_at)
) ENGINE=InnoDB;

-- ======================
-- TRIGGERS FOR BUSINESS LOGIC
-- ======================

DELIMITER //

-- Update available copies when a loan is created
CREATE TRIGGER after_loan_insert
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    UPDATE books 
    SET available_copies = available_copies - 1 
    WHERE book_id = NEW.book_id;
    
    INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
    VALUES ('loans', NEW.loan_id, 'INSERT', 
            JSON_OBJECT('book_id', NEW.book_id, 'member_id', NEW.member_id), 
            NEW.member_id);
END//

-- Update available copies when a loan is returned
CREATE TRIGGER after_loan_update
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE books 
        SET available_copies = available_copies + 1 
        WHERE book_id = NEW.book_id;
        
        -- Check for overdue and create fine if needed
        IF NEW.return_date > NEW.due_date THEN
            INSERT INTO fines (loan_id, amount, reason, created_by)
            VALUES (NEW.loan_id, 
                    DATEDIFF(NEW.return_date, NEW.due_date) * 0.50, -- $0.50 per day
                    'late',
                    NEW.member_id);
        END IF;
    END IF;
    
    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
    VALUES ('loans', NEW.loan_id, 'UPDATE', 
            JSON_OBJECT('status', OLD.status, 'return_date', OLD.return_date),
            JSON_OBJECT('status', NEW.status, 'return_date', NEW.return_date),
            NEW.member_id);
END//

-- Update loan status when due date passes
CREATE EVENT check_overdue_loans
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE loans
    SET status = 'overdue'
    WHERE status = 'active' 
    AND due_date < CURRENT_DATE 
    AND return_date IS NULL;
    
    -- Create audit entries for changed loans
    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
    SELECT 'loans', loan_id, 'UPDATE', 
           JSON_OBJECT('status', 'active'),
           JSON_OBJECT('status', 'overdue')
    FROM loans
    WHERE status = 'overdue' 
    AND due_date < CURRENT_DATE 
    AND return_date IS NULL;
END//

DELIMITER ;

-- ======================
-- STORED PROCEDURES
-- ======================

DELIMITER //

-- Procedure for checking out a book
CREATE PROCEDURE checkout_book(
    IN p_member_id INT,
    IN p_book_id INT,
    IN p_due_days INT,
    OUT p_loan_id INT
)
BEGIN
    DECLARE v_available INT;
    DECLARE v_member_status VARCHAR(20);
    
    -- Check member status
    SELECT membership_status INTO v_member_status
    FROM members
    WHERE member_id = p_member_id;
    
    IF v_member_status != 'active' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Member is not active';
    END IF;
    
    -- Check book availability
    SELECT available_copies INTO v_available
    FROM books
    WHERE book_id = p_book_id;
    
    IF v_available < 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Book is not available';
    END IF;
    
    -- Create the loan
    INSERT INTO loans (book_id, member_id, due_date)
    VALUES (p_book_id, p_member_id, DATE_ADD(CURRENT_DATE, INTERVAL p_due_days DAY));
    
    SET p_loan_id = LAST_INSERT_ID();
END//

-- Procedure for renewing a loan
CREATE PROCEDURE renew_loan(
    IN p_loan_id INT,
    IN p_extension_days INT,
    OUT p_new_due_date DATETIME
)
BEGIN
    DECLARE v_current_due_date DATETIME;
    DECLARE v_renewed_count TINYINT;
    DECLARE v_max_renewals TINYINT DEFAULT 3;
    
    -- Get current loan info
    SELECT due_date, renewed_count INTO v_current_due_date, v_renewed_count
    FROM loans
    WHERE loan_id = p_loan_id
    AND return_date IS NULL;
    
    IF v_current_due_date IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Loan not found or already returned';
    END IF;
    
    IF v_renewed_count >= v_max_renewals THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Maximum renewals reached';
    END IF;
    
    -- Update the loan
    SET p_new_due_date = DATE_ADD(v_current_due_date, INTERVAL p_extension_days DAY);
    
    UPDATE loans
    SET due_date = p_new_due_date,
        renewed_count = renewed_count + 1,
        last_renewal_date = CURRENT_TIMESTAMP
    WHERE loan_id = p_loan_id;
END//

DELIMITER ;

-- ======================
-- SAMPLE DATA
-- ======================

-- Insert sample publishers
INSERT INTO publishers (name, address, contact_info) VALUES
('Penguin Random House', 
 '{"street": "1745 Broadway", "city": "New York", "state": "NY", "zip": "10019", "country": "USA"}', 
 '{"email": "contact@penguinrandomhouse.com", "phone": "+1-212-782-9000"}'),
('HarperCollins', 
 '{"street": "195 Broadway", "city": "New York", "state": "NY", "zip": "10007", "country": "USA"}', 
 '{"email": "customer.service@harpercollins.com", "phone": "+1-212-207-7000"}'),
('Simon & Schuster', 
 '{"street": "1230 Avenue of the Americas", "city": "New York", "state": "NY", "zip": "10020", "country": "USA"}', 
 '{"email": "consumer@simonandschuster.com", "phone": "+1-800-223-2336"}');

-- Insert sample authors
INSERT INTO authors (name, birth_date, death_date, nationality, biography) VALUES
('George Orwell', '1903-06-25', '1950-01-21', 'British', 'Eric Arthur Blair, known by his pen name George Orwell, was an English novelist, essayist, journalist, and critic.'),
('J.K. Rowling', '1965-07-31', NULL, 'British', 'Joanne Rowling, better known by her pen name J.K. Rowling, is a British author and philanthropist.'),
('Stephen King', '1947-09-21', NULL, 'American', 'Stephen Edwin King is an American author of horror, supernatural fiction, suspense, crime, science-fiction, and fantasy novels.');

-- Insert sample books
INSERT INTO books (title, isbn, publisher_id, publication_year, edition, category, language, total_copies, available_copies) VALUES
('1984', '978-0451524935', 1, 1949, 1, 'Fiction', 'en', 5, 5),
('Animal Farm', '978-0451526342', 1, 1945, 1, 'Fiction', 'en', 3, 3),
('Harry Potter and the Philosopher''s Stone', '978-0747532743', 2, 1997, 1, 'Fiction', 'en', 7, 7),
('The Shining', '978-0307743657', 3, 1977, 1, 'Fiction', 'en', 4, 4);

-- Insert book-author relationships
INSERT INTO book_authors (book_id, author_id, contribution_type, royalty_percentage) VALUES
(1, 1, 'Primary', 15.00),
(2, 1, 'Primary', 15.00),
(3, 2, 'Primary', 20.00),
(4, 3, 'Primary', 18.50);

-- Insert sample members
INSERT INTO members (first_name, last_name, email, phone, address, membership_date) VALUES
('John', 'Doe', 'john.doe@example.com', '+1-555-0101', 
 '{"street": "123 Main St", "city": "Anytown", "state": "CA", "zip": "90210", "country": "USA"}', 
 '2023-01-15'),
('Jane', 'Smith', 'jane.smith@example.com', '+1-555-0102', 
 '{"street": "456 Oak Ave", "city": "Somewhere", "state": "NY", "zip": "10001", "country": "USA"}', 
 '2023-03-22'),
('Robert', 'Johnson', 'robert.j@example.com', '+1-555-0103', 
 '{"street": "789 Pine Rd", "city": "Nowhere", "state": "TX", "zip": "73301", "country": "USA"}', 
 '2022-11-05');