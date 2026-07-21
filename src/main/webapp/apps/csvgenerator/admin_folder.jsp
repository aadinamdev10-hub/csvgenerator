<%@ page import="java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    @SuppressWarnings("unchecked")
    List<String> csvFiles = (List<String>) request.getAttribute("csvFiles");
    if (csvFiles == null) csvFiles = new ArrayList<>();

    @SuppressWarnings("unchecked")
    Map<String,String> descriptions = (Map<String,String>) request.getAttribute("descriptions");
    if (descriptions == null) descriptions = new HashMap<>();

    String folder = (String) request.getAttribute("folder");
    if (folder == null) folder = "";

    String success  = request.getParameter("success");
    String deleted  = request.getParameter("deleted");
    String delError = request.getParameter("error");
    String ctx      = request.getContextPath();

    String folderHtml = folder.replace("&","&amp;").replace("<","&lt;")
                               .replace(">","&gt;").replace("\"","&quot;");
    String folderJs   = folder.replace("\\","\\\\").replace("'","\\'");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin — <%= folderHtml %></title>
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
        --danger: #e71d36;
        --border: #e2e8f0;
        --shadow: 0 10px 30px rgba(30, 144, 255, 0.05);
        --radius: 12px;
    }

    * { box-sizing:border-box; margin:0; padding:0; }
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

    .top-bar { display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:15px; margin-bottom:25px; }
    .section-title {
        font-size: 22px;
        font-weight: 700;
        color: var(--secondary);
        display: flex;
        align-items: center;
        gap: 10px;
        word-break: break-all;
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
    .btn-back {
        background: var(--surface);
        color: var(--text-muted);
        border: 1px solid var(--border);
    }
    .btn-back:hover {
        background: var(--background);
        color: var(--text-main);
    }

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
    table { width: 100%; border-collapse: collapse; text-align: left; }
    th {
        background: #1e90ff;
        color: white;
        padding: 14px 16px;
        font-weight: 600;
        font-size: 13px;
    }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border); font-size: 13.5px; vertical-align: middle; }
    
    th:nth-child(1), td:nth-child(1) { width: 75px; text-align: center; }
    th:nth-child(2), td:nth-child(2) { width: 320px; }
    th:nth-child(4), td:nth-child(4) { width: 220px; text-align: center; }

    tr:nth-child(even) td { background: #fbfdff; }
    tr:hover td { background: var(--primary-light); }

    .actions { display: flex; gap: 8px; justify-content: center; }

    .btn-view-report {
        padding: 8px 16px;
        background: linear-gradient(135deg, var(--primary), #0073e6);
        color: white;
        border: none;
        border-radius: 8px;
        font-weight: 700;
        font-size: 12.5px;
        cursor: pointer;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        transition: all 0.2s;
        white-space: nowrap;
    }
    .btn-view-report:hover {
        background: linear-gradient(135deg, #0073e6, #0059b3);
        transform: translateY(-1px);
    }

    .btn-delete-file {
        padding: 8px 14px;
        background: #fff5f5;
        color: var(--danger);
        border: 1px solid rgba(231,29,54,0.1);
        border-radius: 8px;
        font-weight: 700;
        font-size: 12.5px;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        transition: all 0.2s;
        white-space: nowrap;
    }
    .btn-delete-file:hover {
        background: var(--danger);
        color: white;
        transform: translateY(-1px);
    }

    /* Modal */
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
    .modal-overlay.active { display: flex; }
    .modal {
        background: white;
        border-radius: var(--radius);
        padding: 32px;
        width: 440px;
        max-width: 95%;
        box-shadow: 0 20px 50px rgba(0,0,0,0.15);
        animation: popIn 0.2s ease;
        text-align: center;
        border: 1px solid var(--border);
    }
    @keyframes popIn { from { transform: scale(0.92); opacity: 0; } to { transform: scale(1); opacity: 1; } }
    .modal .icon-warn { font-size: 42px; color: var(--danger); margin-bottom: 12px; }
    .modal h2 { font-size: 19px; color: var(--secondary); margin-bottom: 10px; font-weight: 700; }
    .modal p  { font-size: 13.5px; color: var(--text-muted); margin-bottom: 24px; line-height: 1.6; }
    .modal p strong { color: var(--danger); word-break: break-all; }
    .modal-actions { display: flex; gap: 12px; justify-content: center; }
    
    .btn-confirm-del {
        padding: 10px 22px;
        background: var(--danger);
        color: white;
        border: none;
        border-radius: 8px;
        font-weight: 600;
        cursor: pointer;
        font-size: 13.5px;
        display: inline-flex;
        align-items: center;
        gap: 6px;
    }
    .btn-confirm-del:hover { background: #b71c1c; }

    .empty-state { text-align: center; padding: 60px 20px; color: var(--text-muted); }
    .empty-state i { font-size: 40px; color: #cbd5e1; display: block; margin-bottom: 12px; }

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
            <i class="fa-solid fa-folder-open"></i> Folder: <%= folderHtml %>
        </div>
        <a href="<%= ctx %>/apps/csvgenerator/admin_index.jsp" class="btn btn-back">
            <i class="fa-solid fa-arrow-left"></i> Back to Folders
        </a>
    </div>

    <% if ("1".equals(success)) { %>
        <div class="alert alert-success">
            <i class="fa-solid fa-circle-check"></i> File uploaded successfully.
        </div>
    <% } else if ("1".equals(deleted)) { %>
        <div class="alert alert-success">
            <i class="fa-solid fa-circle-check"></i> File deleted successfully from disk and database.
        </div>
    <% } else if (delError != null) { %>
        <div class="alert alert-error">
            <i class="fa-solid fa-circle-xmark"></i> Operation failed. Please try again.
        </div>
    <% } %>

    <div class="search-box">
        <i class="fa-solid fa-magnifying-glass"></i>
        <input type="text" id="searchInput" placeholder="Search files..." onkeyup="searchFile()">
    </div>

    <% if (csvFiles.isEmpty()) { %>
        <div class="empty-state">
            <i class="fa-solid fa-file-csv"></i>
            No CSV files found in this folder.
        </div>
    <% } else { %>
    <div class="table-wrap">
        <table id="fileTable">
            <thead>
                <tr>
                    <th>Sr No</th>
                    <th>File Name</th>
                    <th>Description</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <%
                int sr = 1;
                for (String fileName : csvFiles) {
                    String desc = descriptions.getOrDefault(fileName, "");
                    String fileHtml = fileName.replace("&","&amp;").replace("<","&lt;")
                                              .replace(">","&gt;").replace("\"","&quot;");
                    String fileJs   = fileName.replace("\\","\\\\").replace("'","\\'");
            %>
                <tr>
                    <td style="text-align:center;"><%= sr++ %></td>
                    <td style="font-weight:600; color: var(--secondary);">
                        <i class="fa-solid fa-file-csv" style="color:var(--success);margin-right:8px;font-size:16px;"></i>
                        <%= fileHtml %>
                    </td>
                    <td>
                        <%= (desc == null || desc.trim().isEmpty())
                            ? "<span style='color:#cbd5e1;font-style:italic;'>No description</span>"
                            : desc.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;") %>
                    </td>
                    <td>
                        <div class="actions">
                            <a href="<%= ctx %>/apps/csvgenerator/AdminViewServlet?folder=<%= folderHtml %>&file=<%= fileHtml %>"
                               class="btn-view-report">
                                <i class="fa-solid fa-eye"></i> View Report
                            </a>
                            <button class="btn-delete-file"
                                    onclick="openFileDeleteModal('<%= fileJs %>')">
                                <i class="fa-solid fa-trash"></i> Delete
                            </button>
                        </div>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<div class="footer">
    © 2026 Application Portal (App), Main Campus
</div>

<!-- Delete File Modal -->
<div class="modal-overlay" id="deleteFileModal">
    <div class="modal">
        <div class="icon-warn"><i class="fa-solid fa-triangle-exclamation"></i></div>
        <h2>Delete File?</h2>
        <p>You are about to permanently delete<br>
           <strong id="deleteFileName"></strong><br>
           This will remove it from disk and the database and will no longer be visible to users.
        </p>
        <div class="modal-actions">
            <button class="btn btn-outline" onclick="closeFileDeleteModal()">Cancel</button>
            <form id="deleteFileForm" method="post" action="<%= ctx %>/apps/csvgenerator/AdminDeleteServlet" style="display:inline;">
                <input type="hidden" name="folder" value="<%= folderHtml %>">
                <input type="hidden" name="file"   id="deleteFileInput" value="">
                <button type="submit" class="btn-confirm-del">
                    <i class="fa-solid fa-trash"></i> Yes, Delete
                </button>
            </form>
        </div>
    </div>
</div>

<script>
function openFileDeleteModal(fileName) {
    document.getElementById('deleteFileName').textContent  = fileName;
    document.getElementById('deleteFileInput').value       = fileName;
    document.getElementById('deleteFileModal').classList.add('active');
}
function closeFileDeleteModal() {
    document.getElementById('deleteFileModal').classList.remove('active');
}
document.getElementById('deleteFileModal').addEventListener('click', function(e) {
    if (e.target === this) closeFileDeleteModal();
});
function searchFile() {
    const q = document.getElementById('searchInput').value.toLowerCase();
    document.querySelectorAll('#fileTable tbody tr').forEach(r => {
        r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
}
</script>
</body>
</html>
