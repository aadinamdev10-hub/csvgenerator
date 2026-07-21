<%@ page import="java.io.*, java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String path = application.getRealPath("/apps/csvgenerator/csvfiles");
    File mainFolder = new File(path);
    File[] folders = mainFolder.listFiles();
    if (folders == null) folders = new File[0];
    Arrays.sort(folders);
    String ctx = request.getContextPath();

    String success = request.getParameter("success");
    String error   = request.getParameter("error");

    StringBuilder folderJsonArr = new StringBuilder("[");
    boolean first = true;
    for (File f : folders) {
        if (f.isDirectory()) {
            if (!first) folderJsonArr.append(",");
            String safeName = f.getName().replace("\\", "\\\\").replace("\"", "\\\"");
            folderJsonArr.append("\"").append(safeName).append("\"");
            first = false;
        }
    }
    folderJsonArr.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin — CSV Folder Explorer</title>
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

    * { box-sizing: border-box; margin: 0; padding: 0; }
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

    .admin-bar {
        text-align: right;
        padding: 10px 4%;
        font-size: 13px;
        color: var(--text-muted);
        font-weight: 600;
    }
    .admin-bar span {
        background: linear-gradient(135deg, #ff4d4d, #d32f2f);
        color: white;
        padding: 4px 14px;
        border-radius: 20px;
        font-weight: 700;
        box-shadow: 0 4px 10px rgba(211, 47, 47, 0.25);
        font-size: 11px;
        letter-spacing: 0.5px;
    }

    .container {
        width: 96%;
        max-width: 1400px;
        margin: 16px auto 24px auto;
        background: var(--surface);
        padding: 24px;
        border-radius: var(--radius);
        box-shadow: var(--shadow);
        border: 1px solid rgba(30, 144, 255, 0.1);
    }

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
    .top-actions { display: flex; gap: 10px; flex-wrap: wrap; }

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
    .btn-create {
        background: linear-gradient(135deg, var(--success), #259e93);
        color: white;
        box-shadow: 0 4px 14px rgba(46, 196, 182, 0.2);
    }
    .btn-create:hover {
        background: linear-gradient(135deg, #259e93, #1c7a71);
        transform: translateY(-1px);
    }
    .btn-upload-top {
        background: linear-gradient(135deg, #8a2be2, #4b0082);
        color: white;
        box-shadow: 0 4px 14px rgba(138, 43, 226, 0.2);
    }
    .btn-upload-top:hover {
        background: linear-gradient(135deg, #7b2cbf, #3c096c);
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

    .search-box {
        position: relative;
        width: 320px;
        margin-bottom: 20px;
    }
    .search-box input {
        width: 100%;
        padding: 10px 16px 10px 40px;
        border: 1.5px solid var(--border);
        border-radius: 8px;
        font-size: 14px;
        outline: none;
        transition: all 0.2s;
        font-family: inherit;
    }
    .search-box input:focus {
        border-color: var(--primary);
        box-shadow: 0 0 0 3px rgba(30, 144, 255, 0.15);
    }
    .search-box i {
        position: absolute;
        left: 14px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-muted);
    }

    /* Table */
    .table-wrap { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border); }
    table { width: 100%; border-collapse: collapse; min-width: 700px; text-align: left; }
    th {
        background: #1e90ff;
        color: white;
        padding: 14px 16px;
        font-weight: 600;
        font-size: 13px;
    }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border); font-size: 13.5px; vertical-align: middle; }
    
    th:nth-child(1), td:nth-child(1) { width: 90px; text-align: center; }
    th:nth-child(3), td:nth-child(3) { width: 180px; text-align: center; }
    th:nth-child(4), td:nth-child(4) { width: 220px; text-align: center; }

    tr:nth-child(even) td { background: #fbfdff; }
    tr:hover td { background: var(--primary-light); }

    .action-group { display: flex; align-items: center; justify-content: center; gap: 8px; }

    .btn-icon {
        width: 38px;
        height: 38px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 15px;
        text-decoration: none;
        transition: all 0.2s;
        border: none;
        cursor: pointer;
        box-shadow: 0 2px 6px rgba(0,0,0,0.05);
    }
    .btn-open { background: var(--primary-light); color: var(--primary); }
    .btn-open:hover { background: var(--primary); color: white; transform: translateY(-1px); }
    
    .btn-upload-row { background: #f5eefb; color: #8e44ad; }
    .btn-upload-row:hover { background: #8e44ad; color: white; transform: translateY(-1px); }
    
    .btn-delete { background: #fff5f5; color: var(--danger); }
    .btn-delete:hover { background: var(--danger); color: white; transform: translateY(-1px); }

    .alert {
        padding: 12px 16px;
        border-radius: 8px;
        margin-bottom: 20px;
        font-weight: 600;
        font-size: 13.5px;
        display: flex;
        align-items: center;
        gap: 10px;
    }
    .alert-success { background: #f0fdfa; color: var(--success); border: 1px solid rgba(46,196,182,0.2); }
    .alert-error { background: #fff5f5; color: var(--danger); border: 1px solid rgba(231,29,54,0.2); }

    /* Glassmorphic Modals with Backdrop Blur */
    .modal-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0,0,0,0.3);
        backdrop-filter: blur(4px);
        z-index: 1000;
        align-items: center;
        justify-content: center;
    }
    .modal-overlay.open { display: flex; }
    .modal {
        background: var(--surface);
        border-radius: var(--radius);
        padding: 28px;
        width: 480px;
        max-width: 95vw;
        box-shadow: 0 20px 50px rgba(0,0,0,0.15);
        border: 1px solid var(--border);
        animation: popIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    @keyframes popIn { from { transform: scale(0.92); opacity: 0; } to { transform: scale(1); opacity: 1; } }
    .modal-title { font-size: 18px; font-weight: 700; color: var(--secondary); margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
    .modal-label { font-size: 12px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px; display: block; }
    .modal-input { width: 100%; padding: 10px 14px; border: 1.5px solid var(--border); border-radius: 8px; font-size: 14.5px; outline: none; margin-bottom: 14px; color: var(--text-main); font-family: inherit; }
    .modal-input:focus { border-color: var(--primary); }
    .modal-hint { font-size: 11px; color: var(--text-muted); margin-bottom: 16px; margin-top: -10px; }
    .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 6px; }

    /* Drop zone */
    .drop-zone {
        border: 2px dashed rgba(138, 43, 226, 0.3);
        border-radius: 8px;
        padding: 24px;
        text-align: center;
        cursor: pointer;
        transition: all 0.2s;
        background: #fafbff;
        margin-bottom: 14px;
        position: relative;
    }
    .drop-zone:hover, .drop-zone.dragover { border-color: #8e44ad; background: #faf5ff; }
    .drop-zone input[type=file] { position: absolute; inset: 0; opacity: 0; cursor: pointer; width: 100%; }
    .drop-zone .dz-icon { font-size: 32px; color: #b08fd4; margin-bottom: 8px; }
    .drop-zone .dz-text { font-size: 13.5px; color: #7d5a9e; font-weight: 600; }
    .drop-zone .dz-hint { font-size: 11px; color: var(--text-muted); margin-top: 4px; }
    .drop-zone .dz-chosen { font-size: 12.5px; color: #6c3483; font-weight: 700; margin-top: 8px; }

    #uploadProgressWrap { display: none; margin-bottom: 14px; }
    .upload-bar-bg { background: #edf2f7; border-radius: 6px; height: 8px; width: 100%; overflow: hidden; margin-bottom: 4px; }
    .upload-bar-fg { background: linear-gradient(90deg, #8e44ad, #6c3483); height: 100%; border-radius: 6px; transition: width 0.3s ease; width: 0%; }
    .upload-bar-label { font-size: 11px; color: var(--text-muted); font-weight: 600; }

    /* Warning box */
    .warning-box { background: #fff5f5; border: 1px solid rgba(231,29,54,0.15); border-radius: 8px; padding: 14px; font-size: 13px; color: var(--danger); margin-bottom: 18px; display: flex; gap: 10px; align-items: flex-start; }
    .warning-box i { font-size: 16px; flex-shrink: 0; margin-top: 2px; }

    /* Toast */
    #toast { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%) translateY(80px); padding: 12px 24px; border-radius: 8px; font-size: 13.5px; font-weight: 600; box-shadow: 0 10px 30px rgba(0,0,0,0.12); transition: all 0.3s ease; opacity: 0; z-index: 2000; display: flex; align-items: center; gap: 8px; }
    #toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }
    #toast.success { background: var(--success); color: white; }
    #toast.error { background: var(--danger); color: white; }

    @keyframes spin { to { transform: rotate(360deg); } }
    .mini-spin { display: inline-block; width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.4); border-top-color: white; border-radius: 50%; animation: spin 0.7s linear infinite; }

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

    .empty-state { text-align: center; padding: 60px 20px; color: var(--text-muted); }
    .empty-state i { font-size: 40px; color: #cbd5e1; display: block; margin-bottom: 12px; }
</style>
</head>
<body>

<div class="header">
    <img src="<%= ctx %>/apps/csvgenerator/logo.png" alt="App Logo">
</div>
<div class="admin-bar">Logged in as <span>ADMIN</span></div>

<div class="container">
    <div class="top-bar">
        <div class="section-title">
            <i class="fa-solid fa-lock"></i> CSV Folder Explorer
        </div>
        <div class="top-actions">
            <button class="btn btn-upload-top" onclick="openUploadModal(null)">
                <i class="fa-solid fa-upload"></i> Upload CSV
            </button>
            <button class="btn btn-create" onclick="openCreateModal()">
                <i class="fa-solid fa-folder-plus"></i> New Folder
            </button>
        </div>
    </div>

    <% if ("1".equals(success)) { %>
        <div class="alert alert-success"><i class="fa-solid fa-circle-check"></i> File uploaded successfully.</div>
    <% } else if ("1".equals(error)) { %>
        <div class="alert alert-error"><i class="fa-solid fa-circle-xmark"></i> Upload failed. Please try again.</div>
    <% } else if ("2".equals(error)) { %>
        <div class="alert alert-error"><i class="fa-solid fa-circle-xmark"></i> Missing folder or file parameter.</div>
    <% } %>

    <div class="search-box">
        <i class="fa-solid fa-magnifying-glass"></i>
        <input type="text" id="searchInput" placeholder="Search folders..." onkeyup="searchFolder()">
    </div>

    <%
        int totalFolders = 0;
        for (File f : folders) { if (f.isDirectory()) totalFolders++; }
    %>

    <% if (totalFolders == 0) { %>
        <div class="empty-state">
            <i class="fa-solid fa-folder-open"></i>
            No folders found. Create one using the <strong>New Folder</strong> button above.
        </div>
    <% } else { %>
    <div class="table-wrap">
        <table id="folderTable">
            <thead>
                <tr>
                    <th>Sr No</th>
                    <th>Folder Name</th>
                    <th>No. of Files</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="folderTableBody">
            <%
                int sr = 1;
                for (File folder : folders) {
                    if (folder.isDirectory()) {
                        File[] csvFiles = folder.listFiles((dir, name) -> name.toLowerCase().endsWith(".csv"));
                        int count = (csvFiles != null) ? csvFiles.length : 0;
                        String folderNameEscHtml = folder.getName()
                            .replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
                        String folderNameEscJs = folder.getName()
                            .replace("\\","\\\\").replace("'","\\'");
            %>
                <tr>
                    <td style="text-align:center;"><%= sr++ %></td>
                    <td style="font-weight:600; color: var(--secondary);" data-folder="<%= folderNameEscHtml %>">
                        <i class="fa-solid fa-folder" style="color:#f59e0b;margin-right:10px;font-size:16px;"></i>
                        <%= folderNameEscHtml %>
                    </td>
                    <td style="text-align:center;">
                        <span style="background:var(--primary-light);padding:6px 14px;border-radius:20px;color:var(--primary);font-weight:600;font-size:12px;">
                            <%= count %> file<%= count != 1 ? "s" : "" %>
                        </span>
                    </td>
                    <td>
                        <div class="action-group">
                            <a href="<%= ctx %>/apps/csvgenerator/AdminFolderServlet?folder=<%= folderNameEscHtml %>"
                               class="btn-icon btn-open" title="Open Folder">
                                <i class="fa-solid fa-folder-open"></i>
                            </a>
                            <button class="btn-icon btn-upload-row"
                                    onclick="openUploadModal('<%= folderNameEscJs %>')"
                                    title="Upload CSV to this folder">
                                <i class="fa-solid fa-upload"></i>
                            </button>
                            <button class="btn-icon btn-delete"
                                    onclick="openDeleteModal('<%= folderNameEscJs %>', <%= count %>)"
                                    title="Delete Folder">
                                <i class="fa-solid fa-trash"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            <% } } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<!-- ── CREATE FOLDER MODAL ── -->
<div class="modal-overlay" id="createModal" onclick="closeIfOverlay(event,'createModal')">
    <div class="modal">
        <div class="modal-title"><i class="fa-solid fa-folder-plus" style="color:var(--success);"></i> Create New Folder</div>
        <label class="modal-label">Folder Name</label>
        <input type="text" class="modal-input" id="newFolderName"
               placeholder="e.g. Sales2027"
               oninput="validateFolderName()"
               onkeydown="if(event.key==='Enter') confirmCreate()">
        <div class="modal-hint" id="folderNameHint">Letters, numbers, underscores and hyphens only. No spaces.</div>
        <div class="modal-actions">
            <button class="btn btn-outline" onclick="closeModal('createModal')">Cancel</button>
            <button class="btn btn-create" id="btnConfirmCreate" onclick="confirmCreate()" disabled>
                <i class="fa-solid fa-folder-plus"></i> Create
            </button>
        </div>
    </div>
</div>

<!-- ── UPLOAD CSV MODAL ── -->
<div class="modal-overlay" id="uploadModal" onclick="closeIfOverlay(event,'uploadModal')">
    <div class="modal">
        <div class="modal-title"><i class="fa-solid fa-upload" style="color:#8e44ad;"></i> Upload CSV File</div>

        <div id="uploadFolderRow" style="margin-bottom:14px;"></div>

        <label class="modal-label">Description</label>
        <input type="text" class="modal-input" id="uploadDescription" placeholder="Brief description of this file (optional)">

        <label class="modal-label">CSV File</label>
        <div class="drop-zone" id="dropZone">
            <input type="file" id="csvFileInput" accept=".csv" onchange="onFileChosen(this)">
            <div class="dz-icon"><i class="fa-solid fa-file-csv"></i></div>
            <div class="dz-text">Click to choose or drag &amp; drop a CSV file</div>
            <div class="dz-hint">Maximum file size: 50 MB</div>
            <div class="dz-chosen" id="chosenFileName"></div>
        </div>

        <div id="uploadProgressWrap">
            <div class="upload-bar-bg"><div class="upload-bar-fg" id="uploadBarFg"></div></div>
            <div class="upload-bar-label" id="uploadBarLabel">Uploading...</div>
        </div>

        <div class="modal-actions">
            <button class="btn btn-outline" id="btnUploadCancel" onclick="closeModal('uploadModal')">Cancel</button>
            <button class="btn btn-upload-top" id="btnConfirmUpload" onclick="confirmUpload()" disabled>
                <i class="fa-solid fa-upload"></i> Upload
            </button>
        </div>
    </div>
</div>

<!-- ── DELETE FOLDER MODAL ── -->
<div class="modal-overlay" id="deleteModal" onclick="closeIfOverlay(event,'deleteModal')">
    <div class="modal">
        <div class="modal-title"><i class="fa-solid fa-triangle-exclamation" style="color:var(--danger);"></i> Delete Folder</div>
        <div class="warning-box">
            <i class="fa-solid fa-circle-exclamation"></i>
            <div>
                You are about to permanently delete folder <strong id="deleteFolderName"></strong>
                containing <strong id="deleteFileCount"></strong> CSV file(s).<br><br>
                All database records for this folder will also be removed.
                <strong>This cannot be undone.</strong>
            </div>
        </div>
        <div class="modal-actions">
            <button class="btn btn-outline" onclick="closeModal('deleteModal')">Cancel</button>
            <button class="btn btn-primary" style="background:var(--danger);" id="btnConfirmDelete" onclick="confirmFolderDelete()">
                <i class="fa-solid fa-trash"></i> Yes, Delete
            </button>
        </div>
    </div>
</div>

<div id="toast"></div>

<div class="footer">
    © 2026 Application Portal (App), Main Campus
</div>

<script>
const CTX = '<%= ctx %>';
const ALL_FOLDERS = <%= folderJsonArr.toString() %>;

let pendingDeleteFolder = '';
let uploadTargetFolder  = null;

function searchFolder() {
    const q = document.getElementById('searchInput').value.toLowerCase();
    document.querySelectorAll('#folderTableBody tr').forEach(row => {
        row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
}

function openCreateModal() {
    document.getElementById('newFolderName').value = '';
    document.getElementById('folderNameHint').style.color = '#888';
    document.getElementById('folderNameHint').textContent = 'Letters, numbers, underscores and hyphens only. No spaces.';
    document.getElementById('btnConfirmCreate').disabled = true;
    openModal('createModal');
    setTimeout(() => document.getElementById('newFolderName').focus(), 120);
}

function validateFolderName() {
    const val  = document.getElementById('newFolderName').value.trim();
    const hint = document.getElementById('folderNameHint');
    const btn  = document.getElementById('btnConfirmCreate');
    if (!val) {
        hint.style.color = '#888';
        hint.textContent = 'Letters, numbers, underscores and hyphens only. No spaces.';
        btn.disabled = true;
    } else if (!/^[\w\-]+$/.test(val)) {
        hint.style.color = 'var(--danger)';
        hint.textContent = '✗ Invalid. Use only letters, numbers, _ or -.';
        btn.disabled = true;
    } else {
        hint.style.color = 'var(--success)';
        hint.textContent = '✓ Valid folder name.';
        btn.disabled = false;
    }
}

function confirmCreate() {
    const folderName = document.getElementById('newFolderName').value.trim();
    if (!folderName || !/^[\w\-]+$/.test(folderName)) return;
    const btn = document.getElementById('btnConfirmCreate');
    btn.disabled = true;
    btn.innerHTML = '<span class="mini-spin"></span> Creating...';

    fetch(CTX + '/apps/csvgenerator/folderManageServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=create&folderName=' + encodeURIComponent(folderName)
    })
    .then(r => r.json())
    .then(data => {
        closeModal('createModal');
        if (data.status === 'ok') {
            showToast('success', '✓ ' + data.message);
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast('error', '✗ ' + data.message);
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-folder-plus"></i> Create';
        }
    })
    .catch(() => { closeModal('createModal'); showToast('error', '✗ Request failed.'); });
}

function openUploadModal(folderName) {
    uploadTargetFolder = folderName;
    document.getElementById('csvFileInput').value = '';
    document.getElementById('chosenFileName').textContent = '';
    document.getElementById('uploadDescription').value = '';
    document.getElementById('btnConfirmUpload').disabled = true;
    document.getElementById('btnConfirmUpload').innerHTML = '<i class="fa-solid fa-upload"></i> Upload';
    document.getElementById('uploadProgressWrap').style.display = 'none';
    document.getElementById('uploadBarFg').style.width = '0%';
    document.getElementById('btnUploadCancel').disabled = false;

    const folderRow = document.getElementById('uploadFolderRow');
    if (folderName) {
        folderRow.innerHTML =
            '<label class="modal-label">Target Folder</label>' +
            '<div style="padding:10px 14px;background:var(--primary-light);border:1.5px solid rgba(30,144,255,0.15);border-radius:8px;font-weight:700;color:var(--primary);margin-bottom:14px;">' +
            '<i class="fa-solid fa-folder" style="color:#f59e0b;margin-right:8px;"></i>' +
            escHtml(folderName) + '</div>';
    } else {
        let opts = '<option value="">-- Select a folder --</option>';
        ALL_FOLDERS.forEach(name => {
            opts += '<option value="' + escHtml(name) + '">' + escHtml(name) + '</option>';
        });
        folderRow.innerHTML =
            '<label class="modal-label">Target Folder</label>' +
            '<select class="modal-input" id="uploadFolderSelect" onchange="checkUploadReady()" style="margin-bottom:0;">' +
            opts + '</select>';
    }
    openModal('uploadModal');
}

function onFileChosen(input) {
    const file = input.files[0];
    if (file) {
        document.getElementById('chosenFileName').textContent =
            '📄 ' + file.name + ' (' + (file.size / 1024).toFixed(1) + ' KB)';
        checkUploadReady();
    }
}

function checkUploadReady() {
    const fileInput = document.getElementById('csvFileInput');
    const hasFile   = fileInput.files && fileInput.files.length > 0;
    let folderOk;
    if (uploadTargetFolder) {
        folderOk = true;
    } else {
        const sel = document.getElementById('uploadFolderSelect');
        folderOk  = sel && sel.value !== '';
    }
    document.getElementById('btnConfirmUpload').disabled = !(hasFile && folderOk);
}

function confirmUpload() {
    const fileInput = document.getElementById('csvFileInput');
    if (!fileInput.files || fileInput.files.length === 0) return;

    const folder = uploadTargetFolder ||
        (document.getElementById('uploadFolderSelect') &&
         document.getElementById('uploadFolderSelect').value) || '';
    if (!folder) { showToast('error', '✗ Please select a target folder.'); return; }

    const file        = fileInput.files[0];
    const description = document.getElementById('uploadDescription').value.trim();

    const formData = new FormData();
    formData.append('folderName',  folder);
    formData.append('csvFile',     file);
    formData.append('description', description);

    document.getElementById('uploadProgressWrap').style.display = 'block';
    document.getElementById('btnConfirmUpload').disabled = true;
    document.getElementById('btnConfirmUpload').innerHTML = '<span class="mini-spin"></span> Uploading...';
    document.getElementById('btnUploadCancel').disabled = true;

    const xhr = new XMLHttpRequest();
    xhr.open('POST', CTX + '/apps/csvgenerator/AdminUploadServlet', true);

    xhr.upload.onprogress = function(e) {
        if (e.lengthComputable) {
            const pct = Math.round((e.loaded / e.total) * 100);
            document.getElementById('uploadBarFg').style.width = pct + '%';
            document.getElementById('uploadBarLabel').textContent =
                'Uploading... ' + pct + '% (' +
                (e.loaded / 1024).toFixed(0) + ' KB / ' +
                (e.total  / 1024).toFixed(0) + ' KB)';
        }
    };

    xhr.onload = function() {
        document.getElementById('btnUploadCancel').disabled = false;
        closeModal('uploadModal');
        if (xhr.status >= 200 && xhr.status < 400) {
            showToast('success', '✓ File uploaded successfully.');
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast('error', '✗ Upload failed. Please try again.');
            document.getElementById('btnConfirmUpload').disabled = false;
            document.getElementById('btnConfirmUpload').innerHTML = '<i class="fa-solid fa-upload"></i> Upload';
            document.getElementById('uploadProgressWrap').style.display = 'none';
        }
    };

    xhr.onerror = function() {
        closeModal('uploadModal');
        showToast('error', '✗ Upload failed. Check your connection.');
    };

    xhr.send(formData);
}

const dropZone = document.getElementById('dropZone');
dropZone.addEventListener('dragover',  e => { e.preventDefault(); dropZone.classList.add('dragover'); });
dropZone.addEventListener('dragleave', ()  => dropZone.classList.remove('dragover'));
dropZone.addEventListener('drop', e => {
    e.preventDefault();
    dropZone.classList.remove('dragover');
    if (e.dataTransfer.files.length > 0) {
        const dt = e.dataTransfer;
        try {
            document.getElementById('csvFileInput').files = dt.files;
        } catch(ignore) {}
        onFileChosen({ files: dt.files });
    }
});

function openDeleteModal(folderName, fileCount) {
    pendingDeleteFolder = folderName;
    document.getElementById('deleteFolderName').textContent = '"' + folderName + '"';
    document.getElementById('deleteFileCount').textContent  = fileCount;
    openModal('deleteModal');
}

function confirmFolderDelete() {
    if (!pendingDeleteFolder) return;
    const btn = document.getElementById('btnConfirmDelete');
    btn.disabled = true;
    btn.innerHTML = '<span class="mini-spin"></span> Deleting...';

    fetch(CTX + '/apps/csvgenerator/folderManageServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=delete&folderName=' + encodeURIComponent(pendingDeleteFolder)
    })
    .then(r => r.json())
    .then(data => {
        closeModal('deleteModal');
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-trash"></i> Yes, Delete';
        if (data.status === 'ok') {
            showToast('success', '✓ ' + data.message);
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast('error', '✗ ' + data.message);
        }
    })
    .catch(() => { closeModal('deleteModal'); showToast('error', '✗ Request failed.'); });
}

function openModal(id)  { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
function closeIfOverlay(e, id) { if (e.target === document.getElementById(id)) closeModal(id); }

function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;')
              .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function showToast(type, msg) {
    const t = document.getElementById('toast');
    t.className = type; t.textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 3200);
}
</script>
</body>
</html>
