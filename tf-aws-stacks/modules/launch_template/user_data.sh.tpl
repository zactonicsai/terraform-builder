#!/bin/bash
# First-boot script. Runs once. Installs a tiny "Notes" CRUD website that
# stores rows in the RDS PostgreSQL database.
#
# There is NO internet in this VPC, so we only use:
#   - dnf packages (reach Amazon's repo through the S3 gateway endpoint)
#   - the AWS CLI that ships with Amazon Linux (reaches Secrets Manager
#     through the Secrets Manager interface endpoint)
#   - Python's standard library web server (no pip needed)
set -e

dnf install -y python3 python3-psycopg2

mkdir -p /opt/app

cat > /opt/app/app.env <<'ENV'
SECRET_ARN=${secret_arn}
DB_HOST=${db_endpoint}
DB_PORT=${db_port}
DB_NAME=${db_name}
AWS_REGION=${region}
APP_PORT=${app_port}
ENV

cat > /opt/app/app.py <<'PY'
import os, json, subprocess, html
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
import psycopg2

# --- 1. Get the password from Secrets Manager using the instance's IAM role ---
raw = subprocess.check_output([
    "aws", "secretsmanager", "get-secret-value",
    "--secret-id", os.environ["SECRET_ARN"],
    "--region", os.environ["AWS_REGION"],
    "--query", "SecretString", "--output", "text",
])
secret = json.loads(raw)

def db():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        dbname=os.environ["DB_NAME"],
        user=secret["username"],
        password=secret["password"],
    )

# --- 2. Create the table once ---
with db() as c, c.cursor() as cur:
    cur.execute("CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, text TEXT NOT NULL)")

# --- 3. The four CRUD operations ---
def list_notes():                       # READ
    with db() as c, c.cursor() as cur:
        cur.execute("SELECT id, text FROM notes ORDER BY id")
        return cur.fetchall()

def add_note(text):                     # CREATE
    with db() as c, c.cursor() as cur:
        cur.execute("INSERT INTO notes (text) VALUES (%s)", (text,))

def update_note(nid, text):             # UPDATE
    with db() as c, c.cursor() as cur:
        cur.execute("UPDATE notes SET text=%s WHERE id=%s", (text, nid))

def delete_note(nid):                   # DELETE
    with db() as c, c.cursor() as cur:
        cur.execute("DELETE FROM notes WHERE id=%s", (nid,))

# --- 4. Turn the notes into an HTML page ---
def page():
    rows = ""
    for nid, text in list_notes():
        t = html.escape(text)
        rows += (
            "<li>"
            "<form method='post' action='/update/" + str(nid) + "' style='display:inline'>"
            "<input name='text' value='" + t + "'> <button>Save</button></form> "
            "<form method='post' action='/delete/" + str(nid) + "' style='display:inline'>"
            "<button>Delete</button></form>"
            "</li>"
        )
    return (
        "<!doctype html><title>Notes CRUD</title>"
        "<h1>Notes (stored in RDS PostgreSQL)</h1>"
        "<form method='post' action='/add'>"
        "<input name='text' placeholder='New note' required> <button>Add</button></form>"
        "<ul>" + rows + "</ul>"
    )

# --- 5. A tiny web server from Python's standard library ---
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = page().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        form = parse_qs(self.rfile.read(length).decode())
        text = form.get("text", [""])[0]
        parts = self.path.strip("/").split("/")
        if parts[0] == "add":
            add_note(text)
        elif parts[0] == "update" and len(parts) == 2:
            update_note(int(parts[1]), text)
        elif parts[0] == "delete" and len(parts) == 2:
            delete_note(int(parts[1]))
        self.send_response(303)          # "see other" = redirect back to /
        self.send_header("Location", "/")
        self.end_headers()

HTTPServer(("0.0.0.0", int(os.environ["APP_PORT"])), Handler).serve_forever()
PY

cat > /etc/systemd/system/app.service <<'UNIT'
[Unit]
Description=Notes CRUD app
After=network-online.target

[Service]
EnvironmentFile=/opt/app/app.env
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now app
