
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const data = @import("../data.zig");

const HEAD =
    \\<!doctype html>
    \\<html lang="en">
    \\<head>
    \\<meta charset="utf-8">
    \\<title>PQL Query Guide — Live Examples</title>
    \\<style>
    \\* { box-sizing: border-box; }
    \\body { margin:0; font-family: -apple-system, system-ui, sans-serif; color:#334155; background:#f8fafc; font-size:13px; }
    \\.navbar { background:white; border-bottom:1px solid #e2e8f0; padding:10px 24px; position:sticky; top:0; z-index:50; box-shadow:0 1px 2px rgba(0,0,0,0.03); display:flex; align-items:center; gap:10px; }
    \\.navbar-icon { color:#3b82f6; font-size:16px; }
    \\.navbar-title { font-size:14px; font-weight:600; color:#0f172a; }
    \\.wrap { max-width: 1100px; margin: 0 auto; padding: 20px 20px 80px; }
    \\.sub { color:#64748b; margin: 0 0 20px; font-size:12px; }
    \\.sec-head { font-size: 12px; font-weight:600; color:#475569; text-transform:uppercase; letter-spacing:0.04em; margin: 24px 0 8px; padding-bottom:4px; border-bottom: 1px solid #e2e8f0; }
    \\.q-block { background:white; border:1px solid #e2e8f0; border-radius:8px; padding:12px 14px; margin: 0 0 10px; }
    \\.q-head { display:flex; align-items:center; gap:10px; }
    \\.q-num { font-size:10px; font-weight:600; color:#94a3b8; min-width:34px; font-variant-numeric: tabular-nums; }
    \\.q-code { flex:1; margin:0; padding:6px 10px; background:#f1f5f9; border-radius:4px; font-family: ui-monospace, SF Mono, Consolas, monospace; font-size:12px; color:#0f172a; white-space:pre-wrap; word-break:break-word; }
    \\.q-actions { display:flex; gap:4px; }
    \\.q-btn { width:28px; height:28px; padding:0; font-size:13px; border:1px solid transparent; border-radius:4px; cursor:pointer; display:inline-flex; align-items:center; justify-content:center; }
    \\.q-btn:disabled { opacity:0.5; cursor:not-allowed; }
    \\.q-run { background:#3b82f6; color:white; }
    \\.q-run:hover { background:#2563eb; }
    \\.q-run.destructive { background:#dc2626; }
    \\.q-run.destructive:hover { background:#b91c1c; }
    \\.q-copy { background:#f1f5f9; color:#475569; border-color:#e2e8f0; }
    \\.q-copy:hover { background:#e2e8f0; color:#0f172a; }
    \\.q-copy.copied { background:#dcfce7; color:#15803d; border-color:#bbf7d0; }
    \\.q-result { display:none; margin-top:10px; border-top:1px solid #e2e8f0; padding-top:10px; }
    \\.q-result.open { display:block; }
    \\.r-bar { display:flex; align-items:center; gap:8px; cursor:pointer; user-select:none; font-size:11px; color:#64748b; margin-bottom:6px; }
    \\.r-bar .chev { display:inline-block; transition: transform 0.15s; color:#94a3b8; }
    \\.q-result.collapsed .r-bar .chev { transform: rotate(-90deg); }
    \\.q-result.collapsed .r-body { display:none; }
    \\.r-bar .pill { padding:1px 6px; background:#f1f5f9; border-radius:3px; }
    \\.r-bar .ok { color:#15803d; }
    \\.r-bar .err { color:#dc2626; }
    \\.r-table { width:100%; border-collapse:collapse; font-size:12px; background:white; border:1px solid #e2e8f0; border-radius:4px; overflow:hidden; white-space:nowrap; }
    \\.r-table th { text-align:left; padding:4px 8px; background:#f1f5f9; font-weight:600; color:#475569; border-bottom:1px solid #e2e8f0; font-size:11px; }
    \\.r-table td { padding:3px 8px; border-bottom:1px solid #f1f5f9; font-family: ui-monospace, SF Mono, Consolas, monospace; font-size:11px; color:#0f172a; vertical-align:top; }
    \\.r-table tr:last-child td { border-bottom:none; }
    \\.r-table tr.r-data:hover > td { background:#eff6ff; }
    \\.r-table .r-toggle { width:20px; text-align:center; padding-left:4px; padding-right:4px; }
    \\.r-table .r-toggle span { display:inline-block; width:14px; height:14px; line-height:13px; text-align:center; cursor:pointer; color:#3b82f6; font-weight:700; user-select:none; }
    \\.r-table .r-srn { color:#94a3b8; padding-left:6px; padding-right:6px; }
    \\.r-table .r-sub td { background:#f8fafc; padding:8px 8px 8px 28px; }
    \\.r-table .r-sub .sub-label { font-size:10px; font-weight:600; color:#64748b; text-transform:uppercase; letter-spacing:0.04em; margin-bottom:4px; display:block; }
    \\.r-cell .null { color:#cbd5e1; }
    \\.r-cell .nest { color:#94a3b8; font-style:italic; }
    \\.r-empty, .r-err { padding:10px; background:#f1f5f9; border-radius:4px; font-size:12px; color:#64748b; }
    \\.r-err { background:#fef2f2; color:#dc2626; }
    \\.r-scalar { padding:10px; background:#ecfdf5; border-radius:4px; font-family: ui-monospace, monospace; color:#15803d; font-weight:600; font-size:13px; }
    \\.spinner { display:inline-block; width:10px; height:10px; border:2px solid #e2e8f0; border-top-color:#3b82f6; border-radius:50%; animation:spin 0.7s linear infinite; }
    \\@keyframes spin { to { transform: rotate(360deg); } }
    \\</style>
    \\</head>
    \\<body>
    \\<nav class="navbar"><span class="navbar-icon">⚡</span><span class="navbar-title">PQL Query Guide — Live Examples</span>
    \\<button id="setup-btn" class="q-btn q-run" title="Create stores + indexes (idempotent — safe to re-run)" style="margin-left:auto; width:auto; padding:0 10px; height:24px; font-size:11px; gap:6px;">Setup schema</button>
    \\<span id="setup-status" style="font-size:11px; color:#64748b; margin-left:8px;"></span>
    \\</nav>
    \\<div class="wrap">
    \\<p class="sub">Every example from <code>yql-guide.md</code> runs against this app's planck/db. Read queries are safe; mutations (sections 22–24) prompt for confirmation. Click result header to collapse.</p>
    \\
;

const FOOT =
    \\<script>
    \\// Minimal port of planck/wb DataTable.vue + CellValue.vue — same
    \\// "+/-" expansion behavior, same look. Recursive: nested objects /
    \\// arrays render as their own sub-table when the user expands a row.
    \\
    \\function esc(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
    \\
    \\function isExpandable(v){return v!==null && typeof v==='object';}
    \\
    \\function renderCell(v){
    \\  if(v===null||v===undefined) return '<span class="null">-</span>';
    \\  if(Array.isArray(v)) return '<span class="nest">Array['+v.length+']</span>';
    \\  if(typeof v==='object') return '<span class="nest">{...}</span>';
    \\  return esc(v);
    \\}
    \\
    \\function columnsOf(rows){
    \\  const cols=new Set();
    \\  for(let i=0;i<Math.min(rows.length,100);i++){
    \\    const r=rows[i];
    \\    if(r && typeof r==='object' && !Array.isArray(r)){
    \\      Object.keys(r).forEach(k=>cols.add(k));
    \\    }
    \\  }
    \\  return [...cols];
    \\}
    \\
    \\// Returns { html, attachExpanders(tableEl) }
    \\function buildTable(data){
    \\  let isArr = Array.isArray(data);
    \\  let rows, cols;
    \\  if(isArr){
    \\    rows = data.filter(r => r && typeof r==='object' && !Array.isArray(r));
    \\    cols = columnsOf(rows);
    \\  }else{
    \\    rows = Object.entries(data).map(([k,v])=>({_key:k,_value:v}));
    \\    cols = ['Key','Value'];
    \\  }
    \\
    \\  let head = '<tr><th class="r-toggle"></th><th class="r-srn">#</th>';
    \\  head += cols.map(c=>'<th>'+esc(c)+'</th>').join('');
    \\  head += '</tr>';
    \\
    \\  let body = '';
    \\  rows.forEach((row, idx) => {
    \\    const expandables = isArr
    \\      ? Object.entries(row).filter(([,v])=>isExpandable(v))
    \\      : (isExpandable(row._value) ? [[row._key, row._value]] : []);
    \\    const hasExpand = expandables.length > 0;
    \\
    \\    body += '<tr class="r-data" data-row-idx="'+idx+'">';
    \\    body += '<td class="r-toggle">'+(hasExpand?'<span data-act="expand">+</span>':'')+'</td>';
    \\    body += '<td class="r-srn">'+(idx+1)+'</td>';
    \\    if(isArr){
    \\      cols.forEach(c => { body += '<td class="r-cell">'+renderCell(row[c])+'</td>'; });
    \\    }else{
    \\      body += '<td class="r-cell" style="color:#64748b;font-weight:500">'+esc(row._key)+'</td>';
    \\      body += '<td class="r-cell">'+renderCell(row._value)+'</td>';
    \\    }
    \\    body += '</tr>';
    \\
    \\    // Placeholder sub-row, filled when user clicks +.
    \\    if(hasExpand){
    \\      body += '<tr class="r-sub" data-sub-of="'+idx+'" style="display:none">';
    \\      body += '<td></td>';
    \\      body += '<td colspan="'+(cols.length+1)+'" class="r-sub-host"></td>';
    \\      body += '</tr>';
    \\    }
    \\  });
    \\
    \\  const tableHtml = '<table class="r-table"><thead>'+head+'</thead><tbody>'+body+'</tbody></table>';
    \\
    \\  return {
    \\    html: tableHtml,
    \\    rowsByIdx: rows,
    \\    isArr: isArr,
    \\    cols: cols,
    \\  };
    \\}
    \\
    \\function wireTable(tableEl, built){
    \\  tableEl.querySelectorAll('span[data-act="expand"]').forEach(btn => {
    \\    btn.addEventListener('click', (e) => {
    \\      e.stopPropagation();
    \\      const row = btn.closest('tr.r-data');
    \\      const idx = +row.dataset.rowIdx;
    \\      const sub = tableEl.querySelector('tr.r-sub[data-sub-of="'+idx+'"]');
    \\      if(!sub) return;
    \\      const open = sub.style.display !== 'none';
    \\      if(open){
    \\        sub.style.display = 'none';
    \\        btn.textContent = '+';
    \\        return;
    \\      }
    \\      // Render sub-tables on first expand.
    \\      const host = sub.querySelector('.r-sub-host');
    \\      if(!host.dataset.built){
    \\        const r = built.rowsByIdx[idx];
    \\        const entries = built.isArr
    \\          ? Object.entries(r).filter(([,v])=>isExpandable(v))
    \\          : [[r._key, r._value]];
    \\        const parts = [];
    \\        for(const [k, v] of entries){
    \\          parts.push('<span class="sub-label">'+esc(k)+'</span>');
    \\          const sb = buildTable(v);
    \\          parts.push('<div class="sub-host">'+sb.html+'</div>');
    \\          // We'll wire the nested table after insertion below.
    \\          host._pendingNested = host._pendingNested || [];
    \\          host._pendingNested.push(sb);
    \\        }
    \\        host.innerHTML = parts.join('');
    \\        // Wire nested tables in the order they appear.
    \\        const tables = host.querySelectorAll('table.r-table');
    \\        tables.forEach((t, i) => {
    \\          if (host._pendingNested && host._pendingNested[i]) wireTable(t, host._pendingNested[i]);
    \\        });
    \\        host.dataset.built = '1';
    \\        host._pendingNested = null;
    \\      }
    \\      sub.style.display = '';
    \\      btn.textContent = '−';
    \\    });
    \\  });
    \\}
    \\
    \\function renderResult(box, payload, count, elapsed){
    \\  const bar = '<div class="r-bar" data-act="toggle"><span class="chev">▾</span><span class="pill ok">ok</span><span>'+count+(count===1?' row':' rows')+'</span><span>'+elapsed+' ms</span><span style="margin-left:auto;color:#cbd5e1">click to collapse</span></div>';
    \\  if(!Array.isArray(payload)||payload.length===0){
    \\    box.innerHTML = bar + '<div class="r-body"><div class="r-empty">no rows</div></div>';
    \\    return;
    \\  }
    \\  // Scalar shortcut: single row + single key (count, sum, avg, …).
    \\  if(payload.length===1 && Object.keys(payload[0]).length===1){
    \\    const k = Object.keys(payload[0])[0]; const v = payload[0][k];
    \\    box.innerHTML = bar + '<div class="r-body"><div class="r-scalar">'+esc(k)+': '+(isExpandable(v)?esc(JSON.stringify(v)):esc(v))+'</div></div>';
    \\    return;
    \\  }
    \\  const built = buildTable(payload);
    \\  box.innerHTML = bar + '<div class="r-body">' + built.html + '</div>';
    \\  const tbl = box.querySelector('table.r-table');
    \\  if (tbl) wireTable(tbl, built);
    \\}
    \\
    \\async function runBlock(btn){
    \\  const block = btn.closest('.q-block');
    \\  const query = block.querySelector('.q-code').textContent;
    \\  const destructive = block.dataset.destructive === 'true';
    \\  if(destructive){
    \\    if(!confirm('This query mutates data:\n\n'+query+'\n\nProceed?'))return;
    \\  }
    \\  const box = block.querySelector('.q-result');
    \\  box.classList.add('open');
    \\  box.classList.remove('collapsed');
    \\  box.innerHTML = '<div class="r-bar"><span class="spinner"></span><span>running…</span></div>';
    \\  btn.disabled = true;
    \\  const t0 = performance.now();
    \\  try {
    \\    const r = await fetch('/api/pql/run', { method:'POST', headers:{'content-type':'application/json'}, body: JSON.stringify({ query }) });
    \\    const j = await r.json();
    \\    const elapsed = Math.round(performance.now()-t0);
    \\    if(!j.success){
    \\      box.innerHTML = '<div class="r-bar"><span class="chev">▾</span><span class="pill err">error</span><span>'+elapsed+' ms</span></div><div class="r-body"><div class="r-err">'+esc(j.error||'unknown error')+'</div></div>';
    \\      return;
    \\    }
    \\    renderResult(box, j.data, j.count ?? (Array.isArray(j.data)?j.data.length:0), elapsed);
    \\  } catch (e) {
    \\    box.innerHTML = '<div class="r-bar"><span class="chev">▾</span><span class="pill err">error</span></div><div class="r-body"><div class="r-err">'+esc(e.message)+'</div></div>';
    \\  } finally {
    \\    btn.disabled = false;
    \\  }
    \\}
    \\
    \\// Delegate bar clicks for collapse/expand.
    \\document.addEventListener('click', (e) => {
    \\  const bar = e.target.closest('.r-bar');
    \\  if (bar && bar.dataset.act === 'toggle') {
    \\    const result = bar.closest('.q-result');
    \\    if (result) result.classList.toggle('collapsed');
    \\  }
    \\});
    \\
    \\document.querySelectorAll('.q-run').forEach(b => {
    \\  if (b.id === 'setup-btn') return; // wired separately below
    \\  b.addEventListener('click', () => runBlock(b));
    \\});
    \\
    \\// Schema/index setup button — calls POST /api/setup which is
    \\// idempotent (existing stores/indexes count as "skipped").
    \\(function(){
    \\  const btn = document.getElementById('setup-btn');
    \\  const status = document.getElementById('setup-status');
    \\  if (!btn) return;
    \\  btn.addEventListener('click', async () => {
    \\    btn.disabled = true;
    \\    status.textContent = 'creating schema…';
    \\    status.style.color = '#64748b';
    \\    try {
    \\      const r = await fetch('/api/setup', { method: 'POST' });
    \\      const j = await r.json();
    \\      if (j.success) {
    \\        status.style.color = '#15803d';
    \\        status.textContent = 'stores: ' + j.stores.created + ' new, ' + j.stores.skipped + ' existing — indexes: ' + j.indexes.created + ' new, ' + j.indexes.skipped + ' existing';
    \\      } else {
    \\        status.style.color = '#dc2626';
    \\        status.textContent = 'failed: ' + (j.error || 'unknown error');
    \\      }
    \\    } catch (e) {
    \\      status.style.color = '#dc2626';
    \\      status.textContent = 'failed: ' + e.message;
    \\    } finally {
    \\      btn.disabled = false;
    \\    }
    \\  });
    \\})();
    \\
    \\document.querySelectorAll('.q-copy').forEach(b => b.addEventListener('click', async () => {
    \\  const code = b.closest('.q-block').querySelector('.q-code').textContent;
    \\  try {
    \\    await navigator.clipboard.writeText(code);
    \\    b.classList.add('copied');
    \\    const orig = b.innerHTML;
    \\    b.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
    \\    setTimeout(() => { b.classList.remove('copied'); b.innerHTML = orig; }, 1200);
    \\  } catch (e) {
    \\    b.title = 'Copy failed: ' + e.message;
    \\  }
    \\}));
    \\</script>
    \\</div></body></html>
;

pub fn handle(_: ?*anyopaque, allocator: std.mem.Allocator, _: *const Request, res: *Response) !void {
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);

    try out.appendSlice(allocator, HEAD);

    var current_section: u32 = 0;
    var idx_in_section: u32 = 0;
    for (data.items) |item| {
        if (item.section != current_section) {
            current_section = item.section;
            idx_in_section = 1;
            const head = try std.fmt.allocPrint(allocator,
                "<div class=\"sec-head\">{d}. {s}</div>\n",
                .{ item.section, item.section_title });
            defer allocator.free(head);
            try out.appendSlice(allocator, head);
        } else {
            idx_in_section += 1;
        }

        const block = try std.fmt.allocPrint(allocator,
            "<div class=\"q-block\" data-destructive=\"{s}\">" ++
                "<div class=\"q-head\"><span class=\"q-num\">{d}.{d}</span>" ++
                "<pre class=\"q-code\">{s}</pre>" ++
                "<div class=\"q-actions\">" ++
                "<button class=\"q-btn q-copy\" title=\"Copy query\" aria-label=\"Copy query\">" ++
                    "<svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">" ++
                    "<rect x=\"9\" y=\"9\" width=\"13\" height=\"13\" rx=\"2\"/><path d=\"M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1\"/></svg>" ++
                "</button>" ++
                "<button class=\"q-btn q-run{s}\" title=\"Run query\" aria-label=\"Run query\">▶</button>" ++
                "</div></div>" ++
                "<div class=\"q-result\"></div></div>\n",
            .{
                if (item.destructive) "true" else "false",
                item.section, idx_in_section,
                try htmlEscape(allocator, item.query),
                if (item.destructive) " destructive" else "",
            });
        defer allocator.free(block);
        try out.appendSlice(allocator, block);
    }

    try out.appendSlice(allocator, FOOT);
    try res.html(out.items);
}

fn htmlEscape(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (s) |c| {
        switch (c) {
            '<' => try out.appendSlice(allocator, "&lt;"),
            '>' => try out.appendSlice(allocator, "&gt;"),
            '&' => try out.appendSlice(allocator, "&amp;"),
            '"' => try out.appendSlice(allocator, "&quot;"),
            else => try out.append(allocator, c),
        }
    }
    return out.toOwnedSlice(allocator);
}
