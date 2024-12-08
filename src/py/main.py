from fastapi import FastAPI
from src.py.controlers import project_controller, task_controller

app = FastAPI()

app.include_router(project_controller.router)
app.include_router(task_controller.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the API!"}
