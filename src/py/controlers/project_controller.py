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
