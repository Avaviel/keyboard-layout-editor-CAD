# Publish the static KLE site to the gh-pages branch (same idea as YAKB's npm run deploy).
# Source stays on master. Generated js/css/fonts are gitignored there and only live on gh-pages.
#
# Usage (from repo root):
#   powershell -File deploy-pages.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$base = "https://www.keyboard-layout-editor.com"

$vendorFiles = @(
  "js/jquery.min.js","js/angular.min.js","js/angular-sanitize.min.js","js/angular-cookies.min.js",
  "js/ui-ace.min.js","js/ui-utils.min.js","js/ui-bootstrap-tpls-0.12.0.min.js","js/crypto-js.js",
  "js/marked.min.js","js/FileSaver.min.js","js/ng-file-upload.min.js","js/draganddrop.js",
  "js/bootstrap-colorpicker-module.min.js","js/doT.min.js","js/urlon.js","js/cssparser.min.js",
  "js/jsonl.min.js","js/html2canvas.min.js","js/ace.js",
  "js/mode-css.js","js/mode-json.js","js/mode-markdown.js","js/theme-textmate.js","js/ext-searchbox.js",
  "css/bootstrap.min.css","css/font-awesome.min.css","css/hint.min.css","css/colorpicker.min.css",
  "css/kb.css","css/kbd-webfont.css",
  "fonts/glyphicons-halflings-regular.eot","fonts/glyphicons-halflings-regular.svg",
  "fonts/glyphicons-halflings-regular.ttf","fonts/glyphicons-halflings-regular.woff",
  "fonts/glyphicons-halflings-regular.woff2",
  "fonts/fontawesome-webfont.ttf","fonts/fontawesome-webfont.eot","fonts/fontawesome-webfont.svg",
  "fonts/fontawesome-webfont.woff","fonts/fontawesome-webfont.woff2",
  "fonts/kbd-webfont.ttf","fonts/kbd-webfont.eot","fonts/kbd-webfont.svg","fonts/kbd-webfont.woff",
  "fonts/combining-diacritical.ttf","fonts/combining-diacritical.eot",
  "fonts/combining-diacritical.svg","fonts/combining-diacritical.woff"
)

function Ensure-VendorFiles {
  foreach ($rel in $vendorFiles) {
    $dest = Join-Path $root $rel
    if (Test-Path $dest) { continue }
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Write-Host "Downloading $rel"
    Invoke-WebRequest -Uri "$base/$rel" -OutFile $dest -UseBasicParsing
  }
}

function Copy-Into($src, $dst) {
  $dstDir = Split-Path $dst -Parent
  if ($dstDir -and -not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir | Out-Null
  }
  Copy-Item -LiteralPath $src -Destination $dst -Force
}

Ensure-VendorFiles

$stage = Join-Path $env:TEMP "kle-cad-gh-pages"
if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

$rootFiles = @(
  "index.html","kb.html","oauth.html",
  "kb.js","serial.js","render.js","extensions.js",
  "backgrounds.json","colors.json","keys.json","layouts.json","pickers.json","switches.json",
  "favicon.ico","nub.png",".nojekyll",
  "README.md","LICENSE.md","CHANGELOG.md","CONTRIB.md"
)
foreach ($f in $rootFiles) {
  $src = Join-Path $root $f
  if (Test-Path $src) { Copy-Into $src (Join-Path $stage $f) }
}

foreach ($dir in @("js","css","fonts","bg","samples")) {
  $src = Join-Path $root $dir
  if (Test-Path $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $stage $dir) -Recurse -Force
  }
}

# Project Pages lives under /keyboard-layout-editor-CAD/, so absolute /fonts/ URLs 404.
$kbCss = Join-Path $stage "css\kb.css"
if (Test-Path $kbCss) {
  $text = [System.IO.File]::ReadAllText($kbCss)
  $text = $text.Replace('url("/fonts/', 'url("../fonts/')
  $text = $text.Replace("url('/fonts/", "url('../fonts/")
  [System.IO.File]::WriteAllText($kbCss, $text)
}

Push-Location $stage
try {
  git init -b gh-pages | Out-Null
  git add -A
  git commit -m "Publish KLE CAD static site."
  git remote add origin "https://github.com/Avaviel/keyboard-layout-editor-CAD.git"
  git push -f origin gh-pages
  Write-Host "Published to origin/gh-pages"
} finally {
  Pop-Location
}
