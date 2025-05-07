# database_week8

# Advanced Library Management System

## 📚 Project Overview

The **Advanced Library Management System** is a robust and scalable application designed to manage library operations efficiently. It includes features such as user management, book tracking, loan management, and fines calculation. The system is built with a South African context in mind, ensuring cultural relevance and compliance with local standards.

---

## 🚀 Features

- **Database Management**:
  - Well-structured relational database with advanced constraints.
  - Support for JSON fields for flexible data storage.
  - Full-text search and optimized indexes for performance.
  - Triggers, stored procedures, and events for business logic.

- **API**:
  - Built with **FastAPI** for high performance and scalability.
  - JWT authentication for secure access.
  - CRUD operations for users, tasks, categories, books, loans, and fines.
  - Rate limiting and CORS middleware for enhanced security.

- **South African Context**:
  - Sample data includes South African names and addresses.
  - Designed to handle local use cases and standards.

---

## 🛠️ Technologies Used

- **Backend**: FastAPI (Python)
- **Database**: MySQL (Library Management) and PostgreSQL (Task Manager)
- **ORM**: SQLAlchemy with async support
- **Authentication**: JWT
- **Other Tools**: Redis (Rate Limiting), dbdiagram.io (ERD)

---

## 📂 Project Structure

```
Library API/
├── app/
│   ├── api/
│   │   └── v1/
│   │       └── endpoints/
│   │           └── users.py
│   ├── models/
│   │   └── user.py
│   ├── schemas/
│   │   └── user.py
│   ├── main.py
│   ├── database.sql
│   └── config.py
├── docs/
│   └── erd.svg
├── task_manager.sql
└── README.md
```

---

## 🖼️ Entity Relationship Diagram (ERD)

Below is the ERD for the **Library Management System**. It illustrates the relationships between the tables in the database.

![ERD](docs/erd.svg)

---

## ⚙️ How to Run the Project

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/library-management-system.git
cd library-management-system
```

### 2. Set Up the Database
- Import the SQL files into your database:
  - For **Library Management**:
    ```bash
    mysql -u your_username -p library_management < library_management.sql
    ```
  - For **Task Manager**:
    ```bash
    psql -U your_username -d task_manager -f task_manager.sql
    ```

### 3. Configure Environment Variables
Create a `.env` file in the `app/` directory with the following content:
```
DATABASE_URL=mysql+asyncmy://username:password@localhost/library_management
REDIS_HOST=localhost
REDIS_PORT=6379
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### 4. Install Dependencies
```bash
pip install -r requirements.txt
```

### 5. Run the Application
```bash
uvicorn app.main:app --reload
```

### 6. Access the API
- API Documentation: [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs)
- Redoc Documentation: [http://127.0.0.1:8000/api/redoc](http://127.0.0.1:8000/api/redoc)

---

## 🧪 Testing

To run unit tests:
```bash
pytest
```

---

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## 👤 Author

Thembelani Bukali

---

## 🌟 Acknowledgments

- Special thanks to the South African developer community for inspiration and support.
