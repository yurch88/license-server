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
