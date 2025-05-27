import React, { useState, useEffect } from "react";
import axios from "axios";
import jsPDF from "jspdf";

const statusColors = {
  active: "#4CAF50",
  freeze: "#2196F3",
  inactive: "#F44336"
};

function formatDate(dt) {
  if (!dt) return "";
  return new Date(dt).toLocaleDateString();
}

function StatusCircle({ status }) {
  return (
    <span style={{
      display: "inline-block",
      width: 12, height: 12,
      borderRadius: "50%",
      background: statusColors[status] || "#888",
      marginRight: 6,
      verticalAlign: "middle"
    }}/>
  );
}

function KeyWithEye({ value }) {
  const [show, setShow] = useState(false);
  return (
    <span style={{ fontFamily: "monospace" }}>
      {show ? value : "••••••••••••••"}
      <span
        style={{
          marginLeft: 8,
          cursor: "pointer",
          fontSize: 18,
          verticalAlign: "middle"
        }}
        onClick={() => setShow(s => !s)}
        title={show ? "Hide" : "Show"}
      >
        {show ? "👁️" : "🙈"}
      </span>
    </span>
  );
}

function Dashboard() {
  const [licenses, setLicenses] = useState([]);
  const [form, setForm] = useState({
    organization: "",
    phone: "",
    telegram: "",
    period: 7,
  });
  const [err, setErr] = useState("");
  const token = localStorage.getItem("token");

  const fetchLicenses = async () => {
    try {
      const res = await axios.get("/api/licenses", { params: { token } });
      setLicenses(res.data);
    } catch (e) {
      setErr("Failed to load licenses");
    }
  };

  useEffect(() => { fetchLicenses(); }, []);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    setErr("");
    try {
      await axios.post("/api/licenses", { ...form }, { params: { token } });
      setForm({
        organization: "",
        phone: "",
        telegram: "",
        period: 7,
      });
      fetchLicenses();
    } catch (e) {
      setErr("Failed to create license");
    }
  };

  const licenseAction = async (key, type) => {
    try {
      await axios.post(`/api/licenses/${type}`, { key }, { params: { token } });
      fetchLicenses();
    } catch (e) {
      setErr("Action failed");
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    window.location.reload();
  };

  function downloadPdf(lic) {
    const doc = new jsPDF();
    doc.setFontSize(18);
    doc.text("License Certificate", 20, 20);
    doc.setFontSize(12);
    doc.text(`Organization: ${lic.organization}`, 20, 40);
    doc.text(`Phone: ${lic.phone}`, 20, 50);
    doc.text(`Telegram: ${lic.telegram}`, 20, 60);
    doc.text(`Key: ${lic.key}`, 20, 70);
    doc.text(`Created: ${formatDate(lic.created_at)}`, 20, 80);
    doc.text(`Expires: ${formatDate(lic.expires_at)}`, 20, 90);
    doc.text(`Status: ${lic.status}`, 20, 100);
    doc.save(`${lic.organization}.pdf`);
  }

  return (
    <div style={{
      minHeight: "100vh",
      display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center",
      background: "#fafbfc"
    }}>
      <div style={{ width: "100%", maxWidth: 700, marginTop: 36 }}>
        <div style={{
          display: "flex", justifyContent: "space-between", alignItems: "center",
          marginBottom: 10
        }}>
          <h2 style={{
            fontFamily: "sans-serif",
            letterSpacing: 1,
            fontWeight: 700,
            fontSize: 22,
            margin: 0
          }}>
            License Point
          </h2>
          <button
            onClick={logout}
            style={{
              minWidth: 115, padding: "10px 0", fontWeight: 500,
              fontSize: 16, background: "#f9f9f9"
            }}>Logout</button>
        </div>

        <form onSubmit={handleCreate} style={{
          display: "flex", gap: 8, alignItems: "flex-end",
          marginBottom: 28
        }}>
          <input name="organization" placeholder="Organization"
            value={form.organization} onChange={handleChange} required
            style={{ width: 140, fontSize: 15 }} />
          <input name="phone" placeholder="Phone"
            value={form.phone} onChange={handleChange} required
            style={{ width: 120, fontSize: 15 }} />
          <input name="telegram" placeholder="Telegram"
            value={form.telegram} onChange={handleChange} required
            style={{ width: 110, fontSize: 15 }} />
          <select name="period" value={form.period} onChange={handleChange} style={{ width: 95 }}>
            <option value={7}>7 days</option>
            <option value={365}>1 year</option>
            <option value={730}>2 years</option>
            <option value={1095}>3 years</option>
          </select>
          <button
            type="submit"
            style={{
              minWidth: 115, fontWeight: 500, fontSize: 16, background: "#f9f9f9"
            }}
          >Create license</button>
        </form>

        {/* Карточки лицензий */}
        <div style={{
          marginTop: 10, display: "flex", flexDirection: "column",
          alignItems: "center", width: "100%"
        }}>
          {licenses.map((lic, i) => (
            <div key={i} style={{
              background: "#fff",
              boxShadow: "0 2px 8px #0001",
              borderRadius: 8,
              padding: 16,
              marginBottom: 18,
              width: "100%",
              maxWidth: 420,
              minWidth: 320,
              fontSize: 15,
              display: "flex",
              flexDirection: "column"
            }}>
              <div style={{ display: "flex", alignItems: "center", marginBottom: 5 }}>
                <StatusCircle status={lic.status} />
                <b style={{ textTransform: "uppercase", marginRight: 12 }}>{lic.organization}</b>
                <span style={{ fontSize: 12, color: "#888" }}>{lic.status}</span>
                <span style={{ marginLeft: "auto" }}>
                  <button
                    style={{ marginLeft: 10, minWidth: 60 }}
                    onClick={() => downloadPdf(lic)}
                  >PDF</button>
                </span>
              </div>
              <div style={{ margin: "2px 0" }}><b>Key:</b> <KeyWithEye value={lic.key} /></div>
              <div style={{ margin: "2px 0" }}><b>Phone:</b> {lic.phone}</div>
              <div style={{ margin: "2px 0" }}><b>Telegram:</b> {lic.telegram}</div>
              <div style={{ margin: "2px 0" }}><b>Created:</b> {formatDate(lic.created_at)}</div>
              <div style={{ margin: "2px 0" }}><b>Expires:</b> {formatDate(lic.expires_at)}</div>
              <div style={{ margin: "2px 0" }}>
                {lic.status === "active" && (
                  <>
                    <button
                      onClick={() => licenseAction(lic.key, "freeze")}
                      style={{ marginRight: 8, minWidth: 90 }}
                    >Freeze</button>
                    <button
                      onClick={() => licenseAction(lic.key, "revoke")}
                      style={{
                        color: "#F44336", border: "1px solid #F44336",
                        background: "#fff", minWidth: 90
                      }}
                    >Revoke</button>
                  </>
                )}
                {lic.status === "freeze" && (
                  <button
                    onClick={() => licenseAction(lic.key, "unfreeze")}
                    style={{ minWidth: 90 }}
                  >Unfreeze</button>
                )}
              </div>
            </div>
          ))}
        </div>
        {err && <div style={{ color: "red", marginTop: 20 }}>{err}</div>}
      </div>
    </div>
  );
}

export default Dashboard;
