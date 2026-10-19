"""The FastAPI reference, as its tutorial shows, served by uvicorn with uvloop and httptools."""

from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()


@app.get("/plaintext", response_class=PlainTextResponse)
async def plaintext():
    return "Hello, World!"


@app.get("/json")
async def json():
    return {"message": "Hello, World!"}
