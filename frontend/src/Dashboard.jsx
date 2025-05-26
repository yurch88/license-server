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
