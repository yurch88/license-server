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
    <div style={{
      minHeight: "100vh",
      display: "flex",
      alignItems: "center",
      justifyContent: "center"
    }}>
      <div style={{
        background: "#fff",
        borderRadius: 8,
        boxShadow: "0 2px 8px #0002",
        padding: 32,
        minWidth: 320
      }}>
        <h2 style={{ textAlign: "center" }}>Login</h2>
        <form onSubmit={handleSubmit}>
          <input
            name="login"
            placeholder="Login"
            value={form.login}
            onChange={handleChange}
            required
            style={{ width: "100%", marginBottom: 10, fontSize: 15 }}
          />
          <input
            name="password"
            type="password"
            placeholder="Password"
            value={form.password}
            onChange={handleChange}
            required
            style={{ width: "100%", marginBottom: 10, fontSize: 15 }}
          />
          <button type="submit" style={{ width: "100%", fontSize: 16, padding: 8 }}>Login</button>
        </form>
        {err && <div style={{ color: "red", marginTop: 10, textAlign: "center" }}>{err}</div>}
      </div>
    </div>
  );
}

export default Login;
