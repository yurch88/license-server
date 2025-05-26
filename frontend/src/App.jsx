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
