import os
from flask import Flask, jsonify

app = Flask(__name__)
VERSION = os.getenv("APP_VERSION", "1.0")


@app.route("/")
def home():
    return f"Welcome to the DevOps Week 09 project! Version {VERSION}\n"


@app.route("/health")
def health():
    return jsonify(status="ok", version=VERSION), 200
