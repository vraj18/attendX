// =============================================================
// js/app.js — Shared utilities across all pages
// =============================================================

// ── Toast notifications ────────────────────────────────────
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const icons = { success: '✅', error: '❌', info: 'ℹ️' };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${icons[type]||'ℹ️'}</span><span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'fadeOut 0.35s ease forwards';
    setTimeout(() => toast.remove(), 350);
  }, 3500);
}

// ── Format dates ───────────────────────────────────────────
function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-IN', {
    day: '2-digit', month: 'short', year: 'numeric'
  });
}

// ── Today's date YYYY-MM-DD ───────────────────────────────
function todayStr() {
  return new Date().toISOString().slice(0, 10);
}
