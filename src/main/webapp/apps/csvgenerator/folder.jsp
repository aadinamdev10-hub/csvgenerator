<%@ page import="java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String currentFolder = (String) request.getAttribute("folder");
    if (currentFolder == null) currentFolder = "";

    @SuppressWarnings("unchecked")
    List<String> allFiles = (List<String>) request.getAttribute("allFiles");
    if (allFiles == null) allFiles = new ArrayList<>();

    @SuppressWarnings("unchecked")
    List<String> pendingFiles = (List<String>) request.getAttribute("pendingFiles");
    if (pendingFiles == null) pendingFiles = new ArrayList<>();

    @SuppressWarnings("unchecked")
    Map<String,String> descriptions = (Map<String,String>) request.getAttribute("descriptions");
    if (descriptions == null) descriptions = new HashMap<>();

    @SuppressWarnings("unchecked")
    Map<String,Map<String,String>> statusMap =
        (Map<String,Map<String,String>>) request.getAttribute("statusMap");
    if (statusMap == null) statusMap = new HashMap<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CSV Files – <%= currentFolder %></title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
    :root {
        --primary: #1e90ff;
        --primary-hover: #0077e6;
        --primary-light: #e6f2ff;
        --secondary: #2c3e50;
        --background: #f4f7fa;
        --surface: #ffffff;
        --text-main: #333333;
        --text-muted: #666666;
        --success: #2ec4b6;
        --warning: #ff9f1c;
        --danger: #e71d36;
        --border: #e2e8f0;
        --shadow: 0 10px 30px rgba(30, 144, 255, 0.05);
        --radius: 12px;
    }

    * { margin:0; padding:0; box-sizing:border-box; }
    body {
        font-family: 'Inter', sans-serif;
        background: var(--background);
        color: var(--text-main);
        line-height: 1.5;
        padding-bottom: 40px;
    }

    .header {
        background: var(--surface);
        text-align: center;
        padding: 8px 0;
        border-bottom: 1px solid var(--border);
        box-shadow: 0 2px 10px rgba(0,0,0,0.02);
    }
    .header img { width: auto; max-width: 220px; height: auto; display: block; margin: 0 auto; object-fit: contain; }

    .container {
        width: 96%;
        max-width: 1400px;
        margin: 24px auto;
        background: var(--surface);
        padding: 24px;
        border-radius: var(--radius);
        box-shadow: var(--shadow);
        border: 1px solid rgba(30, 144, 255, 0.1);
    }

    /* ── Top bar ── */
    .top-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 14px;
        margin-bottom: 24px;
    }
    .section-title {
        font-size: 22px;
        font-weight: 700;
        color: var(--secondary);
        display: flex;
        align-items: center;
        gap: 10px;
    }
    .section-title i { color: var(--primary); }

    .btn {
        padding: 10px 18px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 13.5px;
        cursor: pointer;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        border: none;
        transition: all 0.2s ease;
        white-space: nowrap;
    }
    .btn-primary {
        background: linear-gradient(135deg, var(--primary), #0073e6);
        color: white;
        box-shadow: 0 4px 14px rgba(30, 144, 255, 0.2);
    }
    .btn-primary:hover {
        background: linear-gradient(135deg, #0073e6, #0059b3);
        transform: translateY(-1px);
    }
    .btn-outline {
        background: var(--surface);
        color: var(--text-muted);
        border: 1px solid var(--border);
    }
    .btn-outline:hover {
        background: var(--background);
        color: var(--text-main);
    }

    /* ── Toolbar ── */
    .toolbar {
        background: #fafcff;
        border: 1.5px solid var(--border);
        padding: 16px 20px;
        border-radius: var(--radius);
        margin-bottom: 24px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 14px;
    }
    .toolbar-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }

    .file-select {
        padding: 10px 14px;
        border: 1.5px solid var(--border);
        border-radius: 8px;
        font-size: 14px;
        background: white;
        color: var(--text-main);
        font-weight: 500;
        min-width: 280px;
        outline: none;
        font-family: inherit;
    }
    .file-select:focus { border-color: var(--primary); }
    .file-select:disabled { opacity: 0.6; cursor: not-allowed; }

    /* ── Message banner ── */
    #msgBanner {
        display: none;
        margin-top: 10px;
        padding: 10px 16px;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 600;
        align-items: center;
        gap: 10px;
    }
    #msgBanner.error {
        background: #fff5f5;
        border: 1px solid rgba(231, 29, 54, 0.2);
        color: var(--danger);
        display: flex;
    }
    #msgBanner.success {
        background: #f0fdfa;
        border: 1px solid rgba(46, 196, 182, 0.2);
        color: var(--success);
        display: flex;
    }

    .search-input {
        padding: 10px 16px;
        border: 1.5px solid var(--border);
        border-radius: 8px;
        font-size: 14px;
        width: 260px;
        outline: none;
        font-family: inherit;
    }
    .search-input:focus {
        border-color: var(--primary);
        box-shadow: 0 0 0 3px rgba(30, 144, 255, 0.15);
    }

    /* ── Table ── */
    .table-wrap { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border); }
    table { width: 100%; border-collapse: collapse; min-width: 900px; text-align: left; }
    th {
        background: #1e90ff;
        color: white;
        padding: 14px 16px;
        font-weight: 600;
        font-size: 13px;
    }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border); font-size: 13.5px; vertical-align: middle; }
    tr:nth-child(even) td { background: #fbfdff; }
    tr:hover td { background: var(--primary-light); }

    /* ── Status badges ── */
    .badge {
        padding: 6px 14px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 700;
        white-space: nowrap;
        display: inline-flex;
        align-items: center;
        gap: 6px;
    }
    .b-generating { background: #fffbf0; color: var(--warning); border: 1px solid rgba(255,159,28,0.2); }
    .b-generated { background: #f0fdfa; color: var(--success); border: 1px solid rgba(46,196,182,0.2); }
    .b-error { background: #fff5f5; color: var(--danger); border: 1px solid rgba(231,29,54,0.2); }
    .b-pending { background: var(--background); color: var(--text-muted); }

    /* ── Progress bar ── */
    .progress-wrap {
        display: flex;
        flex-direction: column;
        gap: 6px;
        min-width: 180px;
    }
    .progress-bar-bg {
        background: #edf2f7;
        border-radius: 4px;
        height: 6px;
        width: 100%;
        overflow: hidden;
    }
    .progress-bar-fg {
        background: var(--warning);
        height: 100%;
        border-radius: 4px;
        transition: width 0.3s ease;
        width: 0%;
    }
    .progress-label {
        font-size: 11px;
        color: var(--text-muted);
        font-weight: 600;
    }

    .no-files {
        padding: 60px; text-align: center; color: var(--text-muted); font-size: 15px;
    }

    .footer {
        background: linear-gradient(135deg, #1e90ff, #1565c0);
        color: white;
        text-align: center;
        padding: 20px;
        margin-top: 40px;
        font-size: 14px;
        font-weight: 500;
        border-radius: 8px;
        border: none;
        box-shadow: 0 4px 12px rgba(30, 144, 255, 0.15);
    }

    .date-main { font-size: 13px; color: var(--text-main); font-weight: 500; }
    .date-time { font-size: 11px; color: var(--text-muted); }

    .desc-text { font-size: 13px; color: var(--text-muted); font-style: italic; }
    .desc-empty { font-size: 12px; color: #cbd5e1; font-style: italic; }
</style>
</head>
<body>

<div class="header">
    <img src="/apps/apps/csvgenerator/logo.png" alt="App Logo">
</div>

<div class="container">

    <!-- Top bar -->
    <div class="top-bar">
        <div class="section-title">
            <i class="fa-solid fa-folder-open"></i>&nbsp; <%= currentFolder %>
        </div>
        <a href="/apps/apps/csvgenerator/fileListServlet" class="btn btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Back to Folders
        </a>
    </div>

    <!-- Toolbar: dropdown + generate button + search -->
    <div class="toolbar">
        <div style="display:flex;flex-direction:column;gap:8px;flex:1;">
            <div class="toolbar-left">
                <select class="file-select" id="fileSelect" onchange="onFileChange()">
                    <% if (pendingFiles.isEmpty()) { %>
                        <option value="">No files available to generate</option>
                    <% } else { %>
                        <option value="">-- Select a CSV file --</option>
                        <% for (String pf : pendingFiles) { %>
                            <option value="<%= pf %>"><%= pf %></option>
                        <% } %>
                    <% } %>
                </select>

                <button id="btnGenerate" class="btn btn-primary" onclick="startGenerate()" disabled>
                    <i class="fa-solid fa-bolt"></i>
                    <span>Generate</span>
                </button>
            </div>
            <div id="msgBanner"></div>
        </div>

        <input type="text" class="search-input" id="searchInput"
               placeholder="Search files..." onkeyup="searchFile()">
    </div>

    <!-- Files Table -->
    <div class="table-wrap">
        <table id="fileTable">
            <thead>
                <tr>
                    <th style="width:75px;text-align:center;">Sr No</th>
                    <th style="min-width:220px;">File Name</th>
                    <th style="min-width:180px;">Description</th>
                    <th style="width:150px;">Created At</th>
                    <th style="width:150px;">Last Modified</th>
                    <th style="width:200px;text-align:center;">Status</th>
                    <th style="width:160px;text-align:center;">Action</th>
                </tr>
            </thead>
            <tbody id="fileTableBody">
            <%
                boolean hasRows = false;
                int sr = 1;
                for (String file : allFiles) {
                    Map<String,String> info = statusMap.get(file);
                    if (info == null) continue;

                    String dbStatus = info.getOrDefault("status", "pending");
                    if ("pending".equals(dbStatus)) continue;

                    String dbCreated  = info.getOrDefault("createdAt",  null);
                    String dbModified = info.getOrDefault("modifiedAt", null);
                    String desc       = descriptions.getOrDefault(file, "");
                    boolean isGenerated  = "generated".equals(dbStatus);
                    boolean isGenerating = "generating".equals(dbStatus);

                    hasRows = true;

                    String viewUrl = request.getContextPath()
                        + "/apps/csvgenerator/viewCsvServlet?folder=" + currentFolder
                        + "&file=" + file;
            %>
                <tr id="row-<%= file %>" data-filename="<%= file %>" data-status="<%= dbStatus %>">
                    <td style="text-align:center;"><%= sr++ %></td>
                    <td>
                        <i class="fa-solid fa-file-csv"
                           style="color:<%= isGenerated ? "var(--success)" : (isGenerating ? "var(--warning)" : "var(--danger)") %>;margin-right:6px;font-size:16px;"></i>
                        <span class="file-label"><%= file %></span>
                    </td>
                    <td>
                        <% if (desc != null && !desc.trim().isEmpty()) { %>
                            <span class="desc-text"><%= desc %></span>
                        <% } else { %>
                            <span class="desc-empty">No description</span>
                        <% } %>
                    </td>
                    <td id="created-<%= file %>">
                        <% if (dbCreated != null) {
                               String[] cp = dbCreated.split("\\|");
                        %>
                            <div class="date-main"><%= cp[0] %></div>
                            <% if (cp.length > 1) { %><div class="date-time"><%= cp[1] %></div><% } %>
                        <% } else { %>—<% } %>
                    </td>
                    <td id="modified-<%= file %>">
                        <% if (dbModified != null) {
                               String[] mp = dbModified.split("\\|");
                        %>
                            <div class="date-main"><%= mp[0] %></div>
                            <% if (mp.length > 1) { %><div class="date-time"><%= mp[1] %></div><% } %>
                        <% } else { %>—<% } %>
                    </td>
                    <td style="text-align:center;" id="status-<%= file %>">
                        <% if (isGenerated) { %>
                            <span class="badge b-generated">
                                <i class="fa-solid fa-circle-check"></i> Generated
                            </span>
                        <% } else if (isGenerating) { %>
                            <div class="progress-wrap">
                                <span class="badge b-generating">Generating...</span>
                                <div class="progress-bar-bg">
                                    <div class="progress-bar-fg" id="bar-<%= file %>"
                                         style="width:0%"></div>
                                </div>
                                <div class="progress-label" id="pct-<%= file %>">0%</div>
                            </div>
                        <% } else { %>
                            <span class="badge b-error"><i class="fa-solid fa-circle-xmark"></i> Error</span>
                        <% } %>
                    </td>
                    <td style="text-align:center;" id="action-<%= file %>">
                        <% if (isGenerated) { %>
                            <a class="btn btn-primary" href="<%= viewUrl %>">
                                <i class="fa-solid fa-eye"></i> View Report
                            </a>
                        <% } else { %>
                            <button class="btn btn-outline"
                                    onclick="refreshRow('<%= file.replace("'", "\\'") %>')">
                                <i class="fa-solid fa-rotate-right"></i> <%= isGenerating ? "Refresh" : "Retry" %>
                            </button>
                        <% } %>
                    </td>
                </tr>
            <% } %>

            <% if (!hasRows) { %>
                <tr id="emptyRow">
                    <td colspan="7" class="no-files">
                        <i class="fa-solid fa-file-csv"
                           style="font-size:36px;display:block;margin-bottom:12px;color:#cbd5e1;"></i>
                        No reports generated yet. Select a file above and click Generate.
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>

<div class="footer">
    © 2026 Application Portal (App), Main Campus
</div>

<script>
const FOLDER = '<%= currentFolder.replace("'", "\\'") %>';
const CTX    = '/apps';

let activePolls = new Set();

// Enable/disable generate button based on dropdown
function onFileChange() {
    const val = document.getElementById('fileSelect').value;
    document.getElementById('btnGenerate').disabled = !val;
    hideMsg();
}

// ── Start Generate ────────────────────────────────────────────────────────────
function startGenerate() {
    const fileName = document.getElementById('fileSelect').value;
    if (!fileName) return;

    const btn = document.getElementById('btnGenerate');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Starting...';

    hideMsg();

    fetch(CTX + '/apps/csvgenerator/generateServlet'
        + '?folder=' + encodeURIComponent(FOLDER)
        + '&file='   + encodeURIComponent(fileName))
    .then(r => r.json())
    .then(data => {
        if (data.status === 'started' || data.status === 'ok') {
            removeFromDropdown(fileName);
            addGeneratingRow(fileName, data.totalRows || 0, data.description || '');
            
            // Re-enable generate button
            btn.innerHTML = '<i class="fa-solid fa-bolt"></i> Generate';
            btn.disabled = !document.getElementById('fileSelect').value;

            // Start auto poll immediately
            startAutoPolling(fileName);
        } else {
            showMsg('error', '<i class="fa-solid fa-circle-xmark"></i> ' +
                    (data.message || 'Failed to start generation.'));
            btn.innerHTML = '<i class="fa-solid fa-bolt"></i> Generate';
            btn.disabled = false;
        }
    })
    .catch(err => {
        console.error(err);
        showMsg('error', '<i class="fa-solid fa-circle-xmark"></i> Request failed. Please try again.');
        btn.innerHTML = '<i class="fa-solid fa-bolt"></i> Generate';
        btn.disabled = false;
    });
}

// ── Add a new Generating row to the table ────────────────────────────────────
function addGeneratingRow(fileName, totalRows, description) {
    const tbody = document.getElementById('fileTableBody');

    const emptyRow = document.getElementById('emptyRow');
    if (emptyRow) emptyRow.remove();

    const srNo = tbody.querySelectorAll('tr').length + 1;
    const safeFile = escJs(fileName);

    let descHtml = '<span class="desc-empty">No description</span>';
    if (description && description.trim() !== '') {
        descHtml = '<span class="desc-text">' + escHtml(description) + '</span>';
    }

    const tr = document.createElement('tr');
    tr.id = 'row-' + fileName;
    tr.setAttribute('data-filename', fileName);
    tr.setAttribute('data-status', 'generating');
    tr.innerHTML =
        '<td style="text-align:center;">' + srNo + '</td>' +
        '<td><i class="fa-solid fa-file-csv" style="color:var(--warning);margin-right:6px;font-size:16px;"></i>' + fileName + '</td>' +
        '<td>' + descHtml + '</td>' +
        '<td id="created-'  + fileName + '">—</td>' +
        '<td id="modified-' + fileName + '">—</td>' +
        '<td style="text-align:center;" id="status-' + fileName + '">' +
            '<div class="progress-wrap">' +
                '<span class="badge b-generating">Generating...</span>' +
                '<div class="progress-bar-bg">' +
                    '<div class="progress-bar-fg" id="bar-' + fileName + '" style="width:0%"></div>' +
                '</div>' +
                '<div class="progress-label" id="pct-' + fileName + '">0%</div>' +
            '</div>' +
        '</td>' +
        '<td style="text-align:center;" id="action-' + fileName + '">' +
            '<button class="btn btn-outline" onclick="refreshRow(\'' + safeFile + '\')">' +
                '<i class="fa-solid fa-rotate-right"></i> Refresh' +
            '</button>' +
        '</td>';

    tbody.appendChild(tr);
}

// ── Refresh/Poll row status ──
function refreshRow(fileName) {
    return fetch(CTX + '/apps/csvgenerator/progressServlet'
        + '?folder=' + encodeURIComponent(FOLDER)
        + '&file='   + encodeURIComponent(fileName))
    .then(r => r.json())
    .then(data => {
        const row = document.getElementById('row-' + fileName);
        const statusCell = document.getElementById('status-' + fileName);
        const actionCell = document.getElementById('action-' + fileName);

        if (!statusCell || !actionCell) return data;

        const safeFile = escJs(fileName);

        if (data.status === 'generated') {
            activePolls.delete(fileName);

            if (row) {
                row.setAttribute('data-status', 'generated');
                const icon = row.querySelector('.fa-file-csv');
                if (icon) icon.style.color = 'var(--success)';
            }

            statusCell.innerHTML =
                '<span class="badge b-generated">' +
                '<i class="fa-solid fa-circle-check"></i> Generated</span>';

            const createdCell  = document.getElementById('created-'  + fileName);
            const modifiedCell = document.getElementById('modified-' + fileName);
            if (createdCell  && data.createdAt)  createdCell.innerHTML  = formatDate(data.createdAt);
            if (modifiedCell && data.modifiedAt) modifiedCell.innerHTML = formatDate(data.modifiedAt);

            const viewUrl = CTX + '/apps/csvgenerator/viewCsvServlet'
                          + '?folder=' + encodeURIComponent(FOLDER)
                          + '&file='   + encodeURIComponent(fileName);
            actionCell.innerHTML =
                '<a class="btn btn-primary" href="' + viewUrl + '">' +
                '<i class="fa-solid fa-eye"></i> View Report</a>';

        } else if (data.status === 'generating') {
            const pct = data.percent || 0;
            const bar = document.getElementById('bar-' + fileName);
            const label = document.getElementById('pct-' + fileName);

            if (bar && label) {
                bar.style.width = pct + '%';
                label.textContent = pct + '% (' + data.processedRows + ' / ' + data.totalRows + ' rows)';
            } else {
                statusCell.innerHTML =
                    '<div class="progress-wrap">' +
                        '<span class="badge b-generating">Generating...</span>' +
                        '<div class="progress-bar-bg">' +
                            '<div class="progress-bar-fg" id="bar-' + fileName + '" style="width:' + pct + '%"></div>' +
                        '</div>' +
                        '<div class="progress-label" id="pct-' + fileName + '">' +
                            pct + '% (' + data.processedRows + ' / ' + data.totalRows + ' rows)' +
                        '</div>' +
                    '</div>';
            }

        } else if (data.status === 'error') {
            activePolls.delete(fileName);
            if (row) row.setAttribute('data-status', 'error');

            statusCell.innerHTML =
                '<span class="badge b-error"><i class="fa-solid fa-circle-xmark"></i> Error</span>';
            actionCell.innerHTML =
                '<button class="btn btn-outline" onclick="refreshRow(\'' + safeFile + '\')">' +
                '<i class="fa-solid fa-rotate-right"></i> Retry</button>';
        }

        return data;
    });
}

// ── Auto Polling Engine ──
function startAutoPolling(fileName) {
    if (activePolls.has(fileName)) return;
    activePolls.add(fileName);

    const intervalId = setInterval(() => {
        if (!activePolls.has(fileName)) {
            clearInterval(intervalId);
            return;
        }

        refreshRow(fileName).then(data => {
            if (data.status === 'generated' || data.status === 'error') {
                clearInterval(intervalId);
            }
        }).catch(() => {
            // Keep polling on brief network disconnect
        });
    }, 1500);
}

// Start auto polling for all rendering files on initial page load
window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('#fileTableBody tr').forEach(row => {
        const fn = row.getAttribute('data-filename');
        const st = row.getAttribute('data-status');
        if (fn && st === 'generating') {
            startAutoPolling(fn);
        }
    });
});

// ── Remove file from dropdown ──
function removeFromDropdown(fileName) {
    const sel = document.getElementById('fileSelect');
    for (let i = 0; i < sel.options.length; i++) {
        if (sel.options[i].value === fileName) {
            sel.remove(i);
            break;
        }
    }
    if (sel.options.length === 0 ||
        (sel.options.length === 1 && sel.options[0].value === '')) {
        sel.innerHTML = '<option value="">No files available to generate</option>';
        document.getElementById('btnGenerate').disabled = true;
    } else {
        sel.value = '';
        document.getElementById('btnGenerate').disabled = true;
    }
}

// ── Search ──
function searchFile() {
    const q = document.getElementById('searchInput').value.toLowerCase();
    document.querySelectorAll('#fileTableBody tr').forEach(row => {
        row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
}

// ── Helpers ──
function showMsg(type, html) {
    const el = document.getElementById('msgBanner');
    el.className = type;
    el.innerHTML = html;
}
function hideMsg() {
    const el = document.getElementById('msgBanner');
    el.className = '';
    el.innerHTML = '';
}
function formatDate(raw) {
    if (!raw) return '—';
    const parts = raw.split('|');
    let html = '<div class="date-main">' + parts[0] + '</div>';
    if (parts[1]) html += '<div class="date-time">' + parts[1] + '</div>';
    return html;
}
function escJs(s) {
    return s.replace(/\\/g,'\\\\').replace(/'/g,"\\'");
}
</script>

</body>
</html>
