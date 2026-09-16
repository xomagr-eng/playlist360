# PLAYLIST 360 - local offline server (no install, no internet, localhost only)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$ports = @(8080, 8081, 8082, 8090, 8181)
$listener = $null
$port = $null
foreach ($p in $ports) {
  try {
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add("http://localhost:$p/")
    $l.Start()
    $listener = $l; $port = $p; break
  } catch { if ($l) { try { $l.Close() } catch {} } }
}
if (-not $listener) { Write-Host 'No free port (8080-8181).'; Read-Host 'Press Enter to exit'; exit 1 }

$mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8';
  '.js'='application/javascript; charset=utf-8'; '.mjs'='application/javascript; charset=utf-8';
  '.css'='text/css; charset=utf-8'; '.json'='application/json; charset=utf-8';
  '.webmanifest'='application/manifest+json; charset=utf-8';
  '.png'='image/png'; '.svg'='image/svg+xml; charset=utf-8'; '.ico'='image/x-icon';
  '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.gif'='image/gif';
  '.mp3'='audio/mpeg'; '.m4a'='audio/mp4'; '.wav'='audio/wav'; '.ogg'='audio/ogg';
  '.flac'='audio/flac'; '.woff2'='font/woff2'
}

$url = "http://localhost:$port/index.html"
Write-Host ''
Write-Host '  ======================================='
Write-Host '        PLAYLIST 360' -ForegroundColor Red
Write-Host '  ======================================='
Write-Host ''
Write-Host "  URL:  $url"
Write-Host '  Runs fully OFFLINE (local only).'
Write-Host '  CLOSE this window to stop.'
Write-Host ''
Start-Process $url

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request; $res = $ctx.Response
    $res.Headers['Cache-Control'] = 'no-cache'
    $rel = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'index.html' }
    $path = Join-Path $root $rel
    $full = [System.IO.Path]::GetFullPath($path)
    if ($full.StartsWith([System.IO.Path]::GetFullPath($root)) -and (Test-Path $full -PathType Leaf)) {
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] }
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $m = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $res.OutputStream.Write($m, 0, $m.Length)
    }
    $res.OutputStream.Close()
  } catch {}
}
