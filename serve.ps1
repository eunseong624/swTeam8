# Danjimate MVP local server (Windows PowerShell 5.1+). No install needed.
# Serves this folder at http://localhost:PORT so the camera and face models work.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path.TrimEnd('\','/')
$mime = @{
  '.html'='text/html; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.json'='application/json';
  '.bin'='application/octet-stream'; '.css'='text/css; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg';
  '.svg'='image/svg+xml'; '.md'='text/plain; charset=utf-8'; '.txt'='text/plain; charset=utf-8'; '.ico'='image/x-icon'
}
$listener = $null
foreach ($p in 8000, 8765, 5500, 8080) {
  $l = New-Object System.Net.HttpListener
  $l.Prefixes.Add("http://localhost:$p/")
  try { $l.Start(); $listener = $l; $port = $p; break } catch { $l.Close() }
}
if (-not $listener) { Write-Host 'Could not open a local port. Open index.html directly instead.'; exit 1 }
$url = "http://localhost:$port/"
Write-Host ''
Write-Host "  Danjimate MVP is running: $url"
Write-Host '  Keep this window open during the demo. Close it to stop.'
Write-Host ''
if ($env:DANJI_NO_BROWSER -ne '1') {
  try { Start-Process 'chrome.exe' $url -ErrorAction Stop } catch { Start-Process $url }
}
while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $res = $ctx.Response
  try {
    $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    if ($rel -eq '' -or $rel.EndsWith('/')) { $rel = $rel + 'index.html' }
    $full = [IO.Path]::GetFullPath((Join-Path $root $rel))
    if ($full.StartsWith($root) -and (Test-Path -LiteralPath $full -PathType Leaf)) {
      $bytes = [IO.File]::ReadAllBytes($full)
      $ext = [IO.Path]::GetExtension($full).ToLower()
      if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] } else { $res.ContentType = 'application/octet-stream' }
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.StatusCode = 404 }
  } catch { $res.StatusCode = 500 }
  finally { $res.OutputStream.Close() }
}
