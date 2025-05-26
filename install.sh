#!/bin/bash
set -e

echo -e "\033[1;33m[INSTALL] Удаляю старое...\033[0m"
rm -rf backend frontend migrations .env docker-compose.yml cat-all.sh delete.sh

echo -e "\033[1;32m[INSTALL] Создаю backend...\033[0m"
mkdir -p backend/app

cat > backend/requirements.txt <<'EOF'
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy==2.0.30
alembic==1.13.1
asyncpg==0.29.0
pydantic==2.7.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
EOF

cat > backend/Dockerfile <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

cat > backend/app/main.py <<'EOF'
from fastapi import FastAPI
from . import api
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.include_router(api.router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)
EOF

cat > backend/app/api.py <<'EOF'
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from datetime import datetime, timedelta
from jose import jwt

router = APIRouter()

SECRET = "supersecret"
ADMIN_LOGIN = "admin"
ADMIN_PASSWORD = "CFT^7ygvCFT^7ygv"

class License(BaseModel):
    id: int
    organization: str
    phone: str
    telegram: str
    key: str
    created_at: datetime
    expires_at: datetime
    status: str

db = {
    "users": [{"login": ADMIN_LOGIN, "password": ADMIN_PASSWORD}],
    "licenses": []
}

def create_license(org, phone, telegram, period_days):
    created = datetime.utcnow()
    expires = created + timedelta(days=period_days)
    payload = {"org": org, "phone": phone, "telegram": telegram, "exp": expires.timestamp()}
    key = jwt.encode(payload, SECRET, algorithm="HS256")
    lic = {
        "id": len(db["licenses"])+1,
        "organization": org,
        "phone": phone,
        "telegram": telegram,
        "key": key,
        "created_at": created,
        "expires_at": expires,
        "status": "active"
    }
    db["licenses"].append(lic)
    return lic

class LoginForm(BaseModel):
    login: str
    password: str

@router.post("/login")
def login(form: LoginForm):
    if form.login == ADMIN_LOGIN and form.password == ADMIN_PASSWORD:
        return {"token": jwt.encode({"login": ADMIN_LOGIN}, SECRET, algorithm="HS256")}
    raise HTTPException(status_code=401, detail="Invalid credentials")

def check_token(token: str):
    try:
        payload = jwt.decode(token, SECRET, algorithms=["HS256"])
        return payload
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

class LicenseForm(BaseModel):
    organization: str
    phone: str
    telegram: str
    period: int

@router.get("/licenses")
def get_licenses(token: str):
    check_token(token)
    return db["licenses"]

@router.post("/licenses")
def add_license(form: LicenseForm, token: str = ""):
    check_token(token)
    lic = create_license(form.organization, form.phone, form.telegram, form.period)
    return lic
EOF

echo -e "\033[1;32m[INSTALL] Создаю frontend...\033[0m"
mkdir -p frontend/src

cat > frontend/package.json <<'EOF'
{
  "name": "frontend",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "jspdf": "^2.5.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.0.0"
  }
}
EOF

cat > frontend/vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
EOF

cat > frontend/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>License Server</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > frontend/Dockerfile <<'EOF'
FROM node:20-alpine as build
WORKDIR /app
COPY . .
RUN npm install && npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/nginx.conf <<'EOF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;
  location /api/ {
    proxy_pass http://backend:8000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
  location / {
    try_files $uri /index.html;
  }
}
EOF

cat > frontend/src/App.jsx <<'EOF'
import React, { useState } from "react";
import Dashboard from "./Dashboard";
import Login from "./Login";

function App() {
  const [token, setToken] = useState(localStorage.getItem("token"));

  if (!token) {
    return <Login onLogin={() => window.location.reload()} />;
  }

  return <Dashboard />;
}

export default App;
EOF

cat > frontend/src/Dashboard.jsx <<'EOF'
import React, { useState, useEffect } from "react";
import axios from "axios";
import jsPDF from "jspdf";

function Dashboard() {
  const [licenses, setLicenses] = useState([]);
  const [form, setForm] = useState({
    organization: "",
    phone: "",
    telegram: "",
    period: 7,
  });
  const [err, setErr] = useState("");
  const [ok, setOk] = useState("");

  const token = localStorage.getItem("token");

  const fetchLicenses = async () => {
    try {
      const res = await axios.get("/api/licenses", {
        params: { token },
      });
      setLicenses(res.data);
    } catch (e) {
      setErr("Ошибка загрузки списка");
    }
  };

  useEffect(() => {
    fetchLicenses();
  }, []);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    setErr("");
    setOk("");
    try {
      await axios.post(
        "/api/licenses",
        { ...form },
        { params: { token } }
      );
      setOk("Лицензия создана");
      setForm({
        organization: "",
        phone: "",
        telegram: "",
        period: 7,
      });
      fetchLicenses();
    } catch (e) {
      setErr("Ошибка создания лицензии");
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    window.location.reload();
  };

  function downloadPdf(lic) {
    const doc = new jsPDF();
    doc.setFontSize(22);
    doc.text("License Certificate", 20, 20);
    doc.setFontSize(14);
    doc.text(\`Organization: \${lic.organization}\`, 20, 40);
    doc.text(\`Phone: \${lic.phone}\`, 20, 50);
    doc.text(\`Telegram: \${lic.telegram}\`, 20, 60);
    doc.text(\`Key: \${lic.key}\`, 20, 70);
    doc.text(\`Valid from: \${new Date(lic.created_at).toLocaleString()}\`, 20, 80);
    doc.text(\`Expires at: \${new Date(lic.expires_at).toLocaleString()}\`, 20, 90);
    doc.text(\`Status: \${lic.status}\`, 20, 100);
    doc.save(\`\${lic.organization}.pdf\`);
  }

  return (
    <div style={{ margin: "30px" }}>
      <h1>Dashboard</h1>
      <button onClick={logout}>Logout</button>
      <h2>Licenses</h2>
      <button onClick={fetchLicenses}>Обновить список</button>
      <table border="1" style={{ marginTop: 15 }}>
        <thead>
          <tr>
            <th>ID</th>
            <th>Organization</th>
            <th>Phone</th>
            <th>Telegram</th>
            <th>Key</th>
            <th>Created</th>
            <th>Expires</th>
            <th>Status</th>
            <th>PDF</th>
          </tr>
        </thead>
        <tbody>
          {licenses.map((lic) => (
            <tr key={lic.id}>
              <td>{lic.id}</td>
              <td>{lic.organization}</td>
              <td>{lic.phone}</td>
              <td>{lic.telegram}</td>
              <td style={{ maxWidth: 110, wordBreak: "break-all" }}>
                {lic.key}
              </td>
              <td>{new Date(lic.created_at).toLocaleString()}</td>
              <td>{new Date(lic.expires_at).toLocaleString()}</td>
              <td>{lic.status}</td>
              <td>
                <button onClick={() => downloadPdf(lic)}>PDF</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <h3 style={{ marginTop: 35 }}>Create License</h3>
      <form onSubmit={handleCreate} style={{ marginBottom: 30 }}>
        <input
          name="organization"
          placeholder="Organization"
          value={form.organization}
          onChange={handleChange}
          required
        />
        <input
          name="phone"
          placeholder="Phone"
          value={form.phone}
          onChange={handleChange}
          required
        />
        <input
          name="telegram"
          placeholder="Telegram"
          value={form.telegram}
          onChange={handleChange}
          required
        />
        <select name="period" value={form.period} onChange={handleChange}>
          <option value={7}>7 дней</option>
          <option value={365}>1 год</option>
          <option value={730}>2 года</option>
          <option value={1095}>3 года</option>
        </select>
        <button type="submit">Создать лицензию</button>
      </form>
      {err && <div style={{ color: "red" }}>{err}</div>}
      {ok && <div style={{ color: "green" }}>{ok}</div>}
    </div>
  );
}

export default Dashboard;
EOF

cat > frontend/src/Login.jsx <<'EOF'
import React, { useState } from "react";
import axios from "axios";

function Login({ onLogin }) {
  const [form, setForm] = useState({ login: "", password: "" });
  const [err, setErr] = useState("");

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErr("");
    try {
      const res = await axios.post("/api/login", form);
      localStorage.setItem("token", res.data.token);
      onLogin();
    } catch (e) {
      setErr("Invalid credentials");
    }
  };

  return (
    <div style={{ margin: "50px auto", width: 320 }}>
      <h2>Login</h2>
      <form onSubmit={handleSubmit}>
        <input
          name="login"
          placeholder="Login"
          value={form.login}
          onChange={handleChange}
          required
        />
        <br />
        <input
          name="password"
          type="password"
          placeholder="Password"
          value={form.password}
          onChange={handleChange}
          required
        />
        <br />
        <button type="submit">Login</button>
      </form>
      {err && <div style={{ color: "red" }}>{err}</div>}
    </div>
  );
}

export default Login;
EOF

cat > frontend/src/main.jsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > frontend/src/App.css <<'EOF'
#root {
  max-width: 1280px;
  margin: 0 auto;
  padding: 2rem;
  text-align: center;
}
.logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
}
.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}
.logo.react:hover {
  filter: drop-shadow(0 0 2em #61dafbaa);
}
@keyframes logo-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
@media (prefers-reduced-motion: no-preference) {
  a:nth-of-type(2) .logo {
    animation: logo-spin infinite 20s linear;
  }
}
.card {
  padding: 2em;
}
.read-the-docs {
  color: #888;
}
EOF

cat > frontend/src/index.css <<'EOF'
:root {
  font-family: system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
  color-scheme: light dark;
  color: rgba(255, 255, 255, 0.87);
  background-color: #242424;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
a {
  font-weight: 500;
  color: #646cff;
  text-decoration: inherit;
}
a:hover {
  color: #535bf2;
}
body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}
h1 {
  font-size: 3.2em;
  line-height: 1.1;
}
button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  background-color: #1a1a1a;
  cursor: pointer;
  transition: border-color 0.25s;
}
button:hover {
  border-color: #646cff;
}
button:focus,
button:focus-visible {
  outline: 4px auto -webkit-focus-ring-color;
}
@media (prefers-color-scheme: light) {
  :root {
    color: #213547;
    background-color: #ffffff;
  }
  a:hover {
    color: #747bff;
  }
  button {
    background-color: #f9f9f9;
  }
}
EOF

echo -e "\033[1;32m[INSTALL] Создаю migrations, .env, docker-compose.yml, cat-all.sh, delete.sh...\033[0m"
mkdir -p migrations

cat > .env <<'EOF'
# Для секретов, если понадобятся
EOF

cat > docker-compose.yml <<'EOF'
version: "3.3"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: license_server
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/license_server
    depends_on:
      - db
    ports:
      - "8000:8000"

  frontend:
    build: ./frontend
    depends_on:
      - backend
    ports:
      - "3000:80"
volumes:
  db_data:
EOF

cat > cat-all.sh <<'EOF'
#!/bin/bash
set -e

echo -e '
========== .env =========='
cat ".env" 2>/dev/null || echo '(нет файла)'

echo -e '
========== docker-compose.yml =========='
cat "docker-compose.yml" 2>/dev/null || echo '(нет файла)'

echo -e '
========== cat-all.sh =========='
cat "cat-all.sh" 2>/dev/null || echo '(нет файла)'

echo -e '
========== delete.sh =========='
cat "delete.sh" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/requirements.txt =========='
cat "backend/requirements.txt" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/Dockerfile =========='
cat "backend/Dockerfile" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/app/api.py =========='
cat "backend/app/api.py" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/app/main.py =========='
cat "backend/app/main.py" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/Dockerfile =========='
cat "frontend/Dockerfile" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/nginx.conf =========='
cat "frontend/nginx.conf" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/package.json =========='
cat "frontend/package.json" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/vite.config.js =========='
cat "frontend/vite.config.js" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/index.html =========='
cat "frontend/index.html" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/App.jsx =========='
cat "frontend/src/App.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/Dashboard.jsx =========='
cat "frontend/src/Dashboard.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/Login.jsx =========='
cat "frontend/src/Login.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/main.jsx =========='
cat "frontend/src/main.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/App.css =========='
cat "frontend/src/App.css" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/index.css =========='
cat "frontend/src/index.css" 2>/dev/null || echo '(нет файла)'
EOF

cat > delete.sh <<'EOF'
#!/bin/bash
set -e

echo -e "\033[1;31m[DELETE] ОСТОРОЖНО! Полная очистка всего Docker — все контейнеры, образы, volume, сети!\033[0m"

docker ps -aq | xargs -r docker stop || true
docker ps -aq | xargs -r docker rm -f || true

docker images -aq | xargs -r docker rmi -f || true

docker volume ls -q | xargs -r docker volume rm -f || true

docker network ls | grep -v 'bridge\|host\|none' | awk '{print $1}' | xargs -r docker network rm || true

docker builder prune -af || true

docker compose down -v --remove-orphans || true

echo -e "\033[1;33m[DELETE] Очищаю папки и файлы проекта...\033[0m"
rm -rf backend frontend migrations docker-compose.yml .env

echo -e "\033[1;32m[DELETE] Полная очистка завершена. Docker как с нуля!\033[0m"
EOF

# Делаем install.sh и delete.sh исполняемыми
chmod +x install.sh delete.sh

echo -e "\033[1;32m[INSTALL] Готово! Проект создан в $(pwd)\033[0m"
echo -e "1. cd frontend && npm install"
echo -e "2. cd .. && docker-compose build"
echo -e "3. docker-compose up -d"
echo -e "\033[1;36mFastAPI:  http://localhost:8000\033[0m"
echo -e "\033[1;36mFrontend: http://localhost:3000\033[0m"
