"""The Flask reference, as its quickstart shows, served by gunicorn's threaded worker."""

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/plaintext")
def plaintext():
    return "Hello, World!", 200, {"Content-Type": "text/plain"}


@app.get("/json")
def json():
    return jsonify(message="Hello, World!")
