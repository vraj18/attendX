// =============================================================
// auth.js — Global Authentication & Role Management
// =============================================================

function checkAuth() {
  const userJson = localStorage.getItem('currentUser');
  if (!userJson) {
    window.location.href = 'login.html';
    return null;
  }
  try {
    return JSON.parse(userJson);
  } catch(e) {
    window.location.href = 'login.html';
    return null;
  }
}

const currentUser = checkAuth();

function logout() {
  localStorage.removeItem('currentUser');
  window.location.href = 'login.html';
}

function renderUserBadge() {
  if (!currentUser) return;
  const sidebar = document.querySelector('.sidebar-nav');
  if (sidebar) {
    const badge = document.createElement('div');
    badge.style.marginTop = 'auto';
    badge.style.padding = '1rem 0.875rem';
    badge.style.borderTop = '1px solid var(--border)';
    badge.style.display = 'flex';
    badge.style.justifyContent = 'space-between';
    badge.style.alignItems = 'center';
    
    badge.innerHTML = `
      <div style="font-size:0.8rem;color:var(--text-secondary);overflow:hidden;">
        <div style="font-weight:600;white-space:nowrap;text-overflow:ellipsis" title="${currentUser.NAME}">${currentUser.NAME}</div>
        <div style="font-size:0.7rem;text-transform:capitalize">${currentUser.Role}</div>
      </div>
      <button class="btn btn-ghost" style="padding:0.4rem;font-size:0.8rem" onclick="logout()" title="Log out">🚪</button>
    `;
    sidebar.appendChild(badge);
  }
}

// Automatically render badge when DOM is ready
document.addEventListener('DOMContentLoaded', renderUserBadge);
