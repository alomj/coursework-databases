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
