<%@ page import="java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    @SuppressWarnings("unchecked")
    List<List<String>> csvData = (List<List<String>>) request.getAttribute("csvData");
    if (csvData == null) csvData = new ArrayList<>();

    String folder = (String) request.getAttribute("folder");
    String file   = (String) request.getAttribute("file");
    if (folder == null) folder = "";
    if (file   == null) file   = "";

    List<String>       headers  = csvData.size() > 0 ? csvData.get(0) : new ArrayList<>();
    List<List<String>> dataRows = csvData.size() > 1 ? csvData.subList(1, csvData.size()) : new ArrayList<>();

    String ctx = request.getContextPath();

    String folderHtml = folder.replace("&","&amp;").replace("<","&lt;")
                               .replace(">","&gt;").replace("\"","&quot;");
    String fileHtml   = file.replace("&","&amp;").replace("<","&lt;")
                             .replace(">","&gt;").replace("\"","&quot;");

    String description = (String) request.getAttribute("description");
    if (description == null) description = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin View — <%= fileHtml %></title>
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

        .top-bar { display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:14px; margin-bottom:18px; }
        .report-title {
            font-size: 20px;
            font-weight: 700;
            color: var(--secondary);
            display: flex;
            align-items: center;
            gap: 10px;
            word-break: break-all;
        }
        .report-title i { color: var(--primary); }

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

        .stats-bar { display:flex; gap:12px; flex-wrap:wrap; margin-bottom:24px; }
        .stat-chip {
            background: var(--primary-light);
            border: 1px solid rgba(30, 144, 255, 0.15);
            border-radius: 8px;
            padding: 10px 16px;
            font-size: 13px;
            color: var(--primary);
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 2px 6px rgba(30, 144, 255, 0.02);
        }
        .stat-chip strong { color: var(--secondary); font-weight: 700; }

        /* ── Controls Row ── */
        .controls-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 16px;
        }
        .search-box {
            position: relative;
            width: 320px;
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

        .pagination-limit {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13.5px;
            color: var(--text-muted);
        }
        .pagination-limit select {
            padding: 8px 12px;
            border: 1.5px solid var(--border);
            border-radius: 6px;
            outline: none;
            cursor: pointer;
            font-family: inherit;
        }

        /* Table wrap */
        .table-wrap {
            overflow: auto;
            max-height: 68vh;
            border-radius: 8px;
            border: 1px solid var(--border);
            box-shadow: 0 4px 12px rgba(0,0,0,0.01);
            background: var(--surface);
        }
        table { width: 100%; border-collapse: collapse; min-width: 500px; text-align: left; }

        thead th {
            position: sticky;
            top: 0;
            z-index: 2;
            background: #1e90ff;
            color: white;
            padding: 14px 16px;
            font-weight: 600;
            font-size: 13px;
            white-space: nowrap;
            border-right: 1px solid rgba(255,255,255,0.15);
            cursor: pointer;
            user-select: none;
            transition: background 0.15s;
        }
        thead th:hover { background: #0077e6; }
        thead th.sr-col {
            background: #1565c0;
            text-align: center;
            width: 70px;
            cursor: default;
        }
        thead th.sr-col:hover { background: #1565c0; }
        thead th i { margin-left: 6px; font-size: 11px; opacity: 0.8; }

        tbody td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            font-size: 13.5px;
            color: var(--text-main);
            white-space: nowrap;
        }
        tbody td.sr-col {
            text-align: center;
            background: var(--primary-light);
            color: var(--primary);
            font-weight: 700;
        }
        tbody tr:nth-child(even) td { background: #fbfdff; }
        tbody tr:hover td { background: var(--primary-light) !important; transition: background 0.1s; }

        .no-data { padding: 60px; text-align: center; color: var(--text-muted); font-size: 15px; }

        /* Pagination controls */
        .pagination-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 16px;
            flex-wrap: wrap;
            gap: 12px;
        }
        .pagination-info { font-size: 13.5px; color: var(--text-muted); }
        .pagination-buttons { display: flex; gap: 6px; }
        .page-btn {
            min-width: 36px;
            height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 8px;
            border: 1px solid var(--border);
            border-radius: 6px;
            background: var(--surface);
            color: var(--text-main);
            font-weight: 600;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.15s;
        }
        .page-btn:hover { background: var(--background); border-color: var(--text-muted); }
        .page-btn.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }
        .page-btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
            background: var(--background);
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
    </style>
</head>
<body>

<div class="header">
    <img src="<%= ctx %>/apps/csvgenerator/logo.png" alt="App Logo">
</div>
<div class="admin-bar">Logged in as <span>ADMIN</span></div>

<div class="container">
    <div class="top-bar">
        <div class="report-title">
            <i class="fa-solid fa-table"></i> <%= fileHtml %>
            <small style="font-size:13.5px;color:var(--text-muted);margin-left:10px;font-weight:600;">— <%= folderHtml %></small>
        </div>
        <a href="<%= ctx %>/apps/csvgenerator/AdminFolderServlet?folder=<%= folderHtml %>" class="btn btn-back">
            <i class="fa-solid fa-arrow-left"></i> Back to Folder
        </a>
    </div>

    <div class="stats-bar">
        <div class="stat-chip"><i class="fa-solid fa-list-ol"></i> Total Rows: <strong><%= dataRows.size() %></strong></div>
        <div class="stat-chip"><i class="fa-solid fa-table-columns"></i> Columns: <strong><%= headers.size() %></strong></div>
        <div class="stat-chip"><i class="fa-solid fa-folder"></i> Folder: <strong><%= folderHtml %></strong></div>
    </div>

    <% if (description != null && !description.trim().isEmpty()) { %>
    <div style="background:#f8fafc; border-left:4px solid var(--primary); padding:12px 16px; border-radius:6px; font-size:13.5px; color:var(--text-muted); font-style:italic; margin-bottom:20px; border: 1px solid var(--border); border-left-width: 4px;">
        <i class="fa-solid fa-circle-info" style="color:var(--primary); margin-right:8px;"></i> <%= description %>
    </div>
    <% } %>

    <div class="controls-row">
        <div class="search-box">
            <i class="fa-solid fa-magnifying-glass"></i>
            <input type="text" id="searchInput" placeholder="Search table data..." onkeyup="onSearchChange()">
        </div>
        <div class="pagination-limit">
            Rows per page:
            <select id="pageSizeSelect" onchange="onPageSizeChange()">
                <option value="25">25</option>
                <option value="50">50</option>
                <option value="100">100</option>
                <option value="all">All</option>
            </select>
        </div>
    </div>

    <div class="table-wrap">
        <table id="reportTable">
            <thead>
                <tr>
                    <th class="sr-col">Sr No</th>
                    <%
                        int colIndex = 0;
                        for (String col : headers) {
                            String colHtml = col.replace("&","&amp;").replace("<","&lt;")
                                               .replace(">","&gt;").replace("\"","&quot;");
                    %>
                        <th onclick="sortByColumn(<%= colIndex++ %>)">
                            <%= colHtml %> <i class="fa-solid fa-sort"></i>
                        </th>
                    <% } %>
                </tr>
            </thead>
            <tbody id="tableBody">
                <!-- Dynamically populated via JS -->
            </tbody>
        </table>
    </div>

    <div class="pagination-row">
        <div class="pagination-info" id="paginationInfo">Showing 0 to 0 of 0 entries</div>
        <div class="pagination-buttons" id="paginationButtons"></div>
    </div>
</div>

<div class="footer">
    © 2026 Application Portal (App), Main Campus
</div>

<script>
    const headers = [
        <% for (int i = 0; i < headers.size(); i++) { %>
            "<%= headers.get(i).replace("\"", "\\\"") %>"<%= i < headers.size() - 1 ? "," : "" %>
        <% } %>
    ];

    const allData = [
        <% for (int r = 0; r < dataRows.size(); r++) { 
            List<String> row = dataRows.get(r);
        %>
            [
                <% for (int c = 0; c < headers.size(); c++) {
                    String cell = (c < row.size()) ? row.get(c) : "";
                    if (cell == null) cell = "";
                %>
                    "<%= cell.replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") %>"<%= c < headers.size() - 1 ? "," : "" %>
                <% } %>
            ]<%= r < dataRows.size() - 1 ? "," : "" %>
        <% } %>
    ];

    let filteredData = [...allData];
    let currentPage = 1;
    let pageSize = 25;
    let sortColumnIndex = -1;
    let sortDirection = 1;

    window.addEventListener('DOMContentLoaded', () => {
        renderTable();
    });

    function renderTable() {
        const body = document.getElementById('tableBody');
        body.innerHTML = '';

        if (filteredData.length === 0) {
            body.innerHTML = '<tr><td colspan="' + (headers.length + 1) + '" class="no-data">' +
                '<i class="fa-solid fa-circle-info" style="font-size:26px;margin-bottom:10px;display:block;color:#ccc;"></i>' +
                'No matching entries found' +
                '</td></tr>';
            updatePagination(0);
            return;
        }

        const size = pageSize === 'all' ? filteredData.length : parseInt(pageSize);
        const start = (currentPage - 1) * size;
        const end = Math.min(start + size, filteredData.length);

        const pageData = filteredData.slice(start, end);

        pageData.forEach((row, index) => {
            const tr = document.createElement('tr');
            
            const srCell = document.createElement('td');
            srCell.className = 'sr-col';
            srCell.textContent = start + index + 1;
            tr.appendChild(srCell);

            row.forEach(cell => {
                const td = document.createElement('td');
                td.textContent = cell.trim() === '' ? '—' : cell;
                tr.appendChild(td);
            });

            body.appendChild(tr);
        });

        updatePagination(filteredData.length);
    }

    function updatePagination(totalRows) {
        const info = document.getElementById('paginationInfo');
        const buttons = document.getElementById('paginationButtons');
        buttons.innerHTML = '';

        if (totalRows === 0) {
            info.textContent = 'Showing 0 to 0 of 0 entries';
            return;
        }

        const size = pageSize === 'all' ? totalRows : parseInt(pageSize);
        const start = (currentPage - 1) * size + 1;
        const end = Math.min(currentPage * size, totalRows);

        info.textContent = 'Showing ' + start + ' to ' + end + ' of ' + totalRows + ' entries';

        const totalPages = Math.ceil(totalRows / size);
        if (totalPages <= 1) return;

        const prev = document.createElement('button');
        prev.className = 'page-btn';
        prev.innerHTML = '<i class="fa-solid fa-chevron-left"></i>';
        prev.disabled = currentPage === 1;
        prev.onclick = () => { currentPage--; renderTable(); };
        buttons.appendChild(prev);

        addPageButton(1, buttons);

        if (currentPage > 3) {
            const dot = document.createElement('span');
            dot.textContent = '...';
            dot.style.padding = '0 6px';
            buttons.appendChild(dot);
        }

        const startPage = Math.max(2, currentPage - 1);
        const endPage = Math.min(totalPages - 1, currentPage + 1);

        for (let i = startPage; i <= endPage; i++) {
            addPageButton(i, buttons);
        }

        if (currentPage < totalPages - 2) {
            const dot = document.createElement('span');
            dot.textContent = '...';
            dot.style.padding = '0 6px';
            buttons.appendChild(dot);
        }

        if (totalPages > 1) {
            addPageButton(totalPages, buttons);
        }

        const next = document.createElement('button');
        next.className = 'page-btn';
        next.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
        next.disabled = currentPage === totalPages;
        next.onclick = () => { currentPage++; renderTable(); };
        buttons.appendChild(next);
    }

    function addPageButton(page, container) {
        const btn = document.createElement('button');
        btn.className = 'page-btn' + (currentPage === page ? ' active' : '');
        btn.textContent = page;
        btn.onclick = () => { currentPage = page; renderTable(); };
        container.appendChild(btn);
    }

    function onPageSizeChange() {
        pageSize = document.getElementById('pageSizeSelect').value;
        currentPage = 1;
        renderTable();
    }

    function onSearchChange() {
        const q = document.getElementById('searchInput').value.toLowerCase();
        filteredData = allData.filter(row => 
            row.some(cell => cell.toLowerCase().includes(q))
        );
        currentPage = 1;
        renderTable();
    }

    function sortByColumn(colIdx) {
        if (sortColumnIndex === colIdx) {
            sortDirection *= -1;
        } else {
            sortColumnIndex = colIdx;
            sortDirection = 1;
        }

        document.querySelectorAll('thead th i').forEach((icon, i) => {
            if (i === 0) return;
            const idx = i - 1;
            if (idx === sortColumnIndex) {
                icon.className = sortDirection === 1 ? 'fa-solid fa-sort-up' : 'fa-solid fa-sort-down';
            } else {
                icon.className = 'fa-solid fa-sort';
            }
        });

        filteredData.sort((a, b) => {
            let valA = a[colIdx].trim();
            let valB = b[colIdx].trim();

            const numA = parseFloat(valA);
            const numB = parseFloat(valB);

            if (!isNaN(numA) && !isNaN(numB)) {
                return (numA - numB) * sortDirection;
            }

            return valA.localeCompare(valB, undefined, { numeric: true, sensitivity: 'base' }) * sortDirection;
        });

        currentPage = 1;
        renderTable();
    }
</script>
</body>
</html>
