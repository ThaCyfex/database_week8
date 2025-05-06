# Advanced Library and Task Management System

**Author**: Thembelani Bukali  
**Date**: 2025 May 05  

## Overview

This project consists of two main components:
1. **Library Management System**: A comprehensive database system for managing library operations, including members, books, authors, publishers, loans, and fines.
2. **Task Manager API**: A FastAPI-based application for managing tasks, users, and categories with advanced features like rate limiting, JWT authentication, and async database support.

The project is designed with South Africa in mind, using local names, locations, and context to make it relevant to the region.

---

## Library Management System

### Features
- **Advanced Constraints**: Ensures data integrity with primary keys, foreign keys, and validation checks.
- **Triggers and Events**: Automates business logic, such as updating book availability and marking overdue loans.
- **Stored Procedures**: Simplifies complex operations like book checkout and loan renewal.
- **Audit Logging**: Tracks changes to records for accountability.
- **Sample Data**: Includes realistic South African names and addresses.

### Sample Data
- **Members**: Names like "Sipho Dlamini" and "Thandiwe Mokoena" with addresses in Johannesburg and Cape Town.
- **Publishers**: Local publishers like "NB Publishers" and "Jonathan Ball Publishers."
- **Books**: Titles like "Long Walk to Freedom" and "Born a Crime" by South African authors.

---

## Task Manager API

### Features
- **CRUD Operations**: Create, Read, Update, and Delete tasks, users, and categories.
- **Async Database Support**: Uses SQLAlchemy with PostgreSQL for efficient database operations.
- **JWT Authentication**: Secures the API with token-based authentication.
- **Rate Limiting**: Prevents abuse with request limits.
- **Health Check**: Provides a `/health` endpoint to monitor the API's status.

### Sample Data
- **Users**: Names like "Lerato Nkosi" and "Mandla Khumalo."
- **Tasks**: Tasks like "Prepare presentation for SONA" and "Submit tax returns."
- **Categories**: Categories like "Work," "Personal," and "Community."

---

## Installation and Setup

### Prerequisites
- Python 3.10+
- PostgreSQL 13+
- Redis (for rate limiting)

### Steps
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Library-API
   ```

2. Set up the database:
   - Run the SQL scripts in the `sql/` folder to create the databases and tables.

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables:
   - Create a `.env` file in the `app/` folder with the following:
     ```
     DATABASE_URL=postgresql+asyncpg://<username>:<password>@localhost/task_manager
     REDIS_HOST=localhost
     REDIS_PORT=6379
     ```

5. Start the API:
   ```bash
   uvicorn app.main:app --reload
   ```

6. Access the API:
   - Open [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs) for the interactive API documentation.

---

## Folder Structure

```
Library-API/
│
├── sql/
│   ├── library_management.sql
│   ├── task_manager.sql
│
├── app/
│   ├── models/
│   │   ├── user.py
│   │   ├── base.py
│   │   ├── task.py
│   │
│   ├── main.py
│   ├── database.py
│
├── static/
│   ├── ...
│
├── config/
│   ├── settings.py
│
├── README.md
```

---

## Future Enhancements
- Add support for multilingual interfaces.
- Implement advanced analytics for library and task management.
- Integrate with mobile applications for better accessibility.

---

## Acknowledgments
This project was created by **Thembelani Bukali** on **2025 May 05** as part of a database and API development assignment. It is tailored for South African use cases and demonstrates advanced database and API design principles.

