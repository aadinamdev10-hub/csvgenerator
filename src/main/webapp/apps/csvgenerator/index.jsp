<%@ page import="java.io.*, java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    @SuppressWarnings("unchecked")
    List<String> folderList = (List<String>) request.getAttribute("folderList");
    if (folderList == null) {
        response.sendRedirect("/apps/apps/csvgenerator/fileListServlet");
        return;
    }

    @SuppressWarnings("unchecked")
    Map<String, Integer> generatedCountMap =
        (Map<String, Integer>) request.getAttribute("generatedCountMap");
    if (generatedCountMap == null) generatedCountMap = new HashMap<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSV Folder Explorer</title>
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

        .section-title {
            font-size: 22px;
            font-weight: 700;
            color: var(--secondary);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .section-title i { color: var(--primary); }

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

        /* ── Table ── */
        .table-wrap { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border); }
        table { width: 100%; border-collapse: collapse; min-width: 600px; text-align: left; }
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
        th:nth-child(4), td:nth-child(4) { width: 140px; text-align: center; }

        tr:nth-child(even) td { background: #fbfdff; }
        tr:hover td { background: var(--primary-light); }

        .btn-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, var(--primary), #0073e6);
            color: white;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            text-decoration: none;
            transition: all 0.2s;
            box-shadow: 0 2px 8px rgba(30, 144, 255, 0.2);
        }
        .btn-icon:hover {
            background: linear-gradient(135deg, #0073e6, #0059b3);
            transform: translateY(-1px) scale(1.05);
        }

        .count-badge {
            background: var(--primary-light);
            padding: 6px 14px;
            border-radius: 20px;
            color: var(--primary);
            font-weight: 600;
            font-size: 12px;
            border: 1px solid rgba(30, 144, 255, 0.1);
        }
        .count-badge.zero {
            background: var(--background);
            color: var(--text-muted);
            border: 1px solid var(--border);
        }

        .no-folders {
            padding: 60px;
            text-align: center;
            color: var(--text-muted);
            font-size: 15px;
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
    <img src="/apps/apps/csvgenerator/logo.png" alt="App Logo">
</div>

<div class="container">
    <div class="section-title">
        <i class="fa-solid fa-folder-tree"></i> CSV Folder Explorer
    </div>

    <div class="search-box">
        <i class="fa-solid fa-magnifying-glass"></i>
        <input type="text" id="searchInput" placeholder="Search folder name..." onkeyup="searchFolder()">
    </div>

    <div class="table-wrap">
        <table id="folderTable">
            <thead>
                <tr>
                    <th>Sr No</th>
                    <th>Folder Name</th>
                    <th>Generated Reports</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody id="folderTableBody">
            <%
                if (folderList.isEmpty()) {
            %>
                <tr>
                    <td colspan="4" class="no-folders">
                        <i class="fa-solid fa-folder-open"
                           style="font-size:36px;display:block;margin-bottom:12px;color:#cbd5e1;"></i>
                        No folders found. Admin needs to create folders and upload files first.
                    </td>
                </tr>
            <%
                } else {
                    int sr = 1;
                    for (String folderName : folderList) {
                        int count = generatedCountMap.getOrDefault(folderName, 0);
            %>
                <tr>
                    <td style="text-align:center;"><%= sr++ %></td>
                    <td style="font-weight:600; color: var(--secondary);">
                        <i class="fa-solid fa-folder" style="color:#f59e0b; margin-right:10px; font-size:16px;"></i>
                        <%= folderName %>
                    </td>
                    <td style="text-align:center;">
                        <span class="count-badge <%= count == 0 ? "zero" : "" %>">
                            <%= count %> file<%= count != 1 ? "s" : "" %>
                        </span>
                    </td>
                    <td style="text-align:center;">
                        <a href="/apps/apps/csvgenerator/folderCsvServlet?folder=<%= folderName %>"
                           class="btn-icon" title="Open Folder">
                            <i class="fa-solid fa-folder-open"></i>
                        </a>
                    </td>
                </tr>
            <%
                    }
                }
            %>
            </tbody>
        </table>
    </div>
</div>

<div class="footer">
    © 2026 Application Portal (App), Main Campus
</div>

<script>
function searchFolder() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    document.querySelectorAll("#folderTableBody tr").forEach(row => {
        const folderNameCell = row.cells[1];
        if (folderNameCell) {
            const match = folderNameCell.textContent.toLowerCase().includes(input);
            row.style.display = match ? "" : "none";
        }
    });
}
</script>
</body>
</html>
