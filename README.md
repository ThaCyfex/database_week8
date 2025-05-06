# database_week8
# Advanced Task Manager API

## Description
The Advanced Task Manager API is a backend service designed to manage tasks and users with advanced features such as JWT authentication, role-based access control, and full-text search. It is built using FastAPI and PostgreSQL, providing a robust and scalable solution for task management.

The project includes:
- A well-structured relational database with advanced constraints and relationships.
- A fully functional CRUD API for managing tasks and users.
- Secure authentication and authorization using JWT.
- Modular and scalable codebase following best practices.

---

## How to Run/Setup the Project

### Prerequisites
1. **Python**: Version 3.9 or higher.
2. **PostgreSQL**: Version 12 or higher.
3. **Redis**: For rate limiting.
4. **Pip**: Python package manager.

### Steps to Run
1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd Library-API
   ```

2. **Set Up the Database**:
   - Create a PostgreSQL database.
   - Import the SQL schema:
     ```bash
     psql -U <username> -d <database_name> -f task_manager.sql
     ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables**:
   - Create a `.env` file in the `app/` directory with the following:
     ```
     DATABASE_URL=postgresql+asyncpg://<username>:<password>@<host>:<port>/<database_name>
     REDIS_HOST=<redis_host>
     REDIS_PORT=<redis_port>
     ```

5. **Run the Application**:
   ```bash
   uvicorn app.main:app --reload
   ```

6. **Access the API**:
   - Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
   - ReDoc: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## Entity-Relationship Diagram (ERD)
Below is the ERD for the Task Manager database:

![ERD](docs/erd.png)

---

## Project Structure
```
Library-API/
│
├── README.md                # Project documentation
├── task_manager.sql         # SQL file for creating the database
│
├── app/                     # Source code for the FastAPI application
│   ├── main.py              # Entry point for the FastAPI application
│   ├── database.sql         # Database connection and session management
│   ├── models/              # Database models
│   │   ├── user.py          # User model
│   │   └── ...              # Other models (if any)
│   ├── schemas/             # Pydantic schemas for data validation
│   │   ├── user.py          # User schemas
│   │   └── ...              # Other schemas (if any)
│   ├── api/                 # API endpoints
│   │   ├── v1/              # Versioned API
│   │   │   ├── endpoints/   # Endpoint files
│   │   │   │   ├── users.py # User-related endpoints
│   │   │   │   └── ...      # Other endpoint files (if any)
│   │   │   └── routers.py   # Router definitions (if applicable)
│   └── config/              # Configuration files (e.g., settings.py)
│
└── docs/                    # Documentation
    ├── erd.png              # Screenshot of the ERD
    └── ...                  # Other documentation files (if any)
```

---

## Code and Logic Explanation

### **1. Database Schema (`task_manager.sql`)**
- **Purpose**: Defines the database structure for the Task Manager.
- **Key Features**:
  - **Users Table**: Stores user information with constraints like unique email and username.
  - **Tasks Table**: Stores task details with relationships to users.
  - **Categories Table**: Allows categorization of tasks.
  - **Task-Categories Table**: Implements a many-to-many relationship between tasks and categories.
  - **Audit Log Table**: Tracks changes to records for auditing purposes.
  - **Indexes**: Optimized for faster lookups.
  - **Triggers**: Automatically updates timestamps on record changes.

### **2. FastAPI Application**
- **`main.py`**:
  - Entry point for the application.
  - Configures middleware (e.g., CORS, rate limiting).
  - Includes application lifecycle management (startup and shutdown events).
  - Serves API documentation via Swagger and ReDoc.

- **`models/user.py`**:
  - Defines the `User` model using SQLAlchemy.
  - Includes methods for password hashing and verification using `passlib`.
  - Implements relationships to link users to their tasks.

- **`schemas/user.py`**:
  - Defines Pydantic schemas for user-related data validation.
  - Includes schemas for user creation, updates, and reading.
  - Implements validation rules (e.g., email format, username regex).

- **`api/v1/endpoints/users.py`**:
  - Implements user-related CRUD endpoints.
  - Includes JWT authentication and role-based access control.
  - Provides endpoints for login, user creation, reading, updating, and deleting.

- **`database.sql`**:
  - Configures the database connection using SQLAlchemy's async engine.
  - Manages database sessions with proper error handling and cleanup.

---

## Features
- **JWT Authentication**: Secure login and token-based authentication.
- **Role-Based Access Control**: Permissions based on user roles (e.g., admin, regular user).
- **CRUD Operations**: Create, Read, Update, and Delete tasks and users.
- **Full-Text Search**: Search tasks by title and description.
- **Rate Limiting**: Prevent abuse with Redis-based rate limiting.
- **Scalable Architecture**: Modular and organized codebase for easy maintenance and scalability.

---

## Sample Data
The database includes the following sample data:
- **Users**:
  - `admin@taskmanager.co.za` (Admin User)
  - `user@taskmanager.co.za` (Regular User)
- **Tasks**:
  - "Complete project"
  - "Write documentation"
  - "Review code"
- **Categories**:
  - "Work"
  - "Personal"
  - "Health"

---

## Contact
For any questions or issues, please contact **Thembelani Bukali**.
