# Реалізація інформаційного та програмного забезпечення


## SQL-скрипт для створення початкового наповнення бази даних

```sql
CREATE SCHEMA IF NOT EXISTS ProjectManagement;
USE ProjectManagement;

CREATE TABLE IF NOT EXISTS Project (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Board (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    project_id BIGINT,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Task (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    deadline DATETIME,
    status VARCHAR(50),
    board_id BIGINT,
    FOREIGN KEY (board_id) REFERENCES Board(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS Attachment (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    format VARCHAR(50),
    content BLOB,
    task_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Label (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Tag (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT,
    label_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (label_id) REFERENCES Label(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS User (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50),
    isBanned TINYINT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Member (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    project_id BIGINT,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Assignee (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT,
    member_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Member(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Permission (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS AccessGrant (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id BIGINT,
    permission_id BIGINT,
    FOREIGN KEY (member_id) REFERENCES Member(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permission(id) ON DELETE CASCADE
);


INSERT INTO Project (title, description) VALUES
('Project Alpha', 'Опис проекту Alpha'),
('Project Beta', 'Опис проекту Beta');

INSERT INTO Board (title, project_id) VALUES
('Board 1', 1),
('Board 2', 1),
('Board 3', 2);

INSERT INTO Task (title, description, deadline, status, board_id) VALUES
('Task 1', 'Опис Task 1', '2024-12-31 23:59:59', 'open', 1),
('Task 2', 'Опис Task 2', '2024-11-30 23:59:59', 'in progress', 1),
('Task 3', 'Опис Task 3', '2024-10-15 23:59:59', 'completed', 2);

INSERT INTO Attachment (format, content, task_id) VALUES
('pdf', 0x1234567890ABCDEF, 1),
('jpg', 0xABCDEF1234567890, 2),
('docx', 0x7890ABCDEF123456, 3);

INSERT INTO Label (name, color) VALUES
('Urgent', 'red'),
('Review', 'blue'),
('Low Priority', 'green');

INSERT INTO Tag (task_id, label_id) VALUES
(1, 1),
(2, 2),
(3, 3);

INSERT INTO User (username, password, email, role, isBanned) VALUES
('john_doe', 'password123', 'john@example.com', 'admin', 0),
('jane_smith', 'password456', 'jane@example.com', 'member', 0),
('alice_jones', 'password789', 'alice@example.com', 'member', 0);

INSERT INTO Member (user_id, project_id) VALUES
(1, 1),
(2, 1),
(3, 2);

INSERT INTO Assignee (task_id, member_id) VALUES
(1, 1),
(2, 2),
(3, 3);

INSERT INTO Permission (action) VALUES
('view'),
('edit'),
('delete');

INSERT INTO AccessGrant (member_id, permission_id) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3),
(3, 1);
```


## RESTfull сервіс для управління даними

### Підключення до бази даних

````python
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy import create_engine
from src.py.models import Base

DATABASE_URL = "mysql+pymysql://root:admin@localhost:3306/rest_api"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
````
### Визначення моделей "Project" і "Task" у SQLAlchemy
````python
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Project(Base):
    __tablename__ = "projects"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True)
    description = Column(String(500))

    tasks = relationship("Task", back_populates="project")


class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True)
    status = Column(String(50), default="pending")
    project_id = Column(Integer, ForeignKey("projects.id"))

    project = relationship("Project", back_populates="tasks")
````

### Моделі валідації запитів і відповідей для Project та Task (Pydantic)
```python
from pydantic import BaseModel
from typing import Optional

class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None

class ProjectCreate(ProjectBase):
    pass

class ProjectResponse(ProjectBase):
    id: int

    class Config:
        orm_mode = True

class TaskBase(BaseModel):
    name: str
    status: Optional[str] = "pending"
    project_id: int

class TaskCreate(TaskBase):
    pass

class TaskResponse(TaskBase):
    id: int

    class Config:
        orm_mode = True

```
### Project Контролер
```python
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from src.py.database import get_db
from src.py.models import Project
from typing import List, Optional

router = APIRouter()

@router.post("/projects/")
async def create_project(project: dict, db: Session = Depends(get_db)):
    try:
        db_project = Project(name=project.get("name"), description=project.get("description"))
        db.add(db_project)
        db.commit()
        db.refresh(db_project)
        return db_project
    except Exception as e:
        print(f"Error creating project: {e}")
        raise HTTPException(status_code=500, detail="Error creating project")

@router.get("/projects/")
async def get_projects(
    local_kw: Optional[str] = Query(default=None, description="Keyword to filter projects by name"),
    db: Session = Depends(get_db),
):
    try:
        if local_kw:
            projects = db.query(Project).filter(Project.name.contains(local_kw)).all()
        else:
            projects = db.query(Project).all()
        return projects
    except Exception as e:
        print(f"Error fetching projects: {e}")
        raise HTTPException(status_code=500, detail="Error fetching projects")

@router.get("/projects/{project_id}")
async def get_project(project_id: int, db: Session = Depends(get_db)):
    db_project = db.query(Project).filter(Project.id == project_id).first()
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project

@router.put("/projects/{project_id}")
async def update_project(project_id: int, project: dict, db: Session = Depends(get_db)):
    db_project = db.query(Project).filter(Project.id == project_id).first()
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")

    db_project.name = project.get("name")
    db_project.description = project.get("description")
    db.commit()
    db.refresh(db_project)
    return db_project

@router.delete("/projects/{project_id}")
async def delete_project(project_id: int, db: Session = Depends(get_db)):
    db_project = db.query(Project).filter(Project.id == project_id).first()
    if not db_project:
        raise HTTPException(status_code=404, detail="Project not found")

    db.delete(db_project)
    db.commit()
    return {"message": "Project deleted successfully"}


```
### Task Контролер
```python
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from src.py.database import get_db
from src.py.models import Task
from src.py.schemas import TaskCreate, TaskResponse
from typing import List
router = APIRouter()

@router.post("/tasks/", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    db_task = Task(name=task.name, status=task.status, project_id=task.project_id)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@router.get("/tasks/", response_model=List[TaskResponse])
async def get_tasks(db: Session = Depends(get_db)):
    return db.query(Task).all()

@router.get("/projects/{project_id}/tasks", response_model=List[TaskResponse])
async def get_tasks_for_project(project_id: int, db: Session = Depends(get_db)):
    return db.query(Task).filter(Task.project_id == project_id).all()

@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: int, db: Session = Depends(get_db)):
    db_task = db.query(Task).filter(Task.id == task_id).first()
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(task_id: int, task: TaskCreate, db: Session = Depends(get_db)):
    db_task = db.query(Task).filter(Task.id == task_id).first()
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")

    db_task.name = task.name
    db_task.status = task.status
    db_task.project_id = task.project_id
    db.commit()
    db.refresh(db_task)
    return db_task

@router.delete("/tasks/{task_id}")
async def delete_task(task_id: int, db: Session = Depends(get_db)):
    db_task = db.query(Task).filter(Task.id == task_id).first()
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")

    db.delete(db_task)
    db.commit()
    return {"message": "Task deleted successfully"}


```
### FastAPI додаток з маршрутизацією для "Project" та "Task'
```python
from fastapi import FastAPI
from src.py.controlers import project_controller, task_controller

app = FastAPI()

app.include_router(project_controller.router)
app.include_router(task_controller.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the API!"}

```