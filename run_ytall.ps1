# =================================================================
# ytall Project - v17.1
# =================================================================

# --- 0. Parameters ---
param(
    # Used by the bootstrapper to delete the original script file after a successful move.
    [string]$OriginalPath
)

# --- 1. Bootstrapper ---
# This section makes the script a portable installer.
if ($OriginalPath -eq "" -and $MyInvocation.MyCommand.Path) {
    try {
        $initialScriptPath = $MyInvocation.MyCommand.Path
        $currentDir = Split-Path -Path $initialScriptPath -Parent
        $currentFolderName = Split-Path $currentDir -Leaf

        if ($currentFolderName -ne 'ytall') {
            Write-Host ">>> ytall 부트스트래퍼: 1단계 설치를 시작합니다..." -ForegroundColor Green
            $ytallDir = Join-Path $currentDir "ytall"
            
            if (-not (Test-Path $ytallDir -PathType Container)) {
                Write-Host " -> 'ytall' 폴더를 생성합니다: $ytallDir" -ForegroundColor Cyan
                New-Item -Path $ytallDir -ItemType Directory | Out-Null
            }

            $newScriptPath = Join-Path $ytallDir (Split-Path $initialScriptPath -Leaf)

            Write-Host " -> 스크립트를 'ytall' 폴더로 복사합니다..." -ForegroundColor Cyan
            Copy-Item -Path $initialScriptPath -Destination $newScriptPath -Force

            Write-Host " -> 'ytall' 폴더 내에서 2단계 설치를 계속합니다..." -ForegroundColor Cyan
            Write-Host " -> 이 창은 잠시 후 자동으로 닫힙니다." -ForegroundColor Yellow
            
            $mainScriptPathToRun = Join-Path $ytallDir "run_ytall.ps1"
            $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$mainScriptPathToRun`" -OriginalPath `"$initialScriptPath`""
            Start-Process powershell.exe -ArgumentList $arguments
            
            Start-Sleep -Seconds 3
            return
        }
    } catch {
        Write-Host "부트스트래퍼 실행 중 심각한 오류가 발생했습니다: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        return
    }
}
# --- End of Bootstrapper ---


# --- 2. Path and Configuration ---
$ErrorActionPreference = "Stop"
$baseDir = $PSScriptRoot 
$detailsDir = Join-Path $baseDir "details"
$engineDir = Join-Path $baseDir "engine"
$tempDir = Join-Path $baseDir "temp"
$convertDir = Join-Path $baseDir "Convert"
$completeDir = Join-Path $baseDir "Complete"
$logFile = Join-Path $detailsDir "debug_log.txt"
$cookieFile = Join-Path $detailsDir "cookies.txt"
$mp3ListFile = Join-Path $baseDir "mp3.txt"
$mp4ListFile = Join-Path $baseDir "mp4.txt"
$readmeFile = Join-Path $baseDir "README.md"
$eulaAcceptedFile = Join-Path $detailsDir "eula_accepted.txt"
$licenseFile = Join-Path $detailsDir "LICENSE"
$configFile = Join-Path $detailsDir "config.ini"
$ytDlpPath = Join-Path $engineDir "yt-dlp.exe"
$ffmpegPath = Join-Path $engineDir "ffmpeg.exe"
$ffprobePath = Join-Path $engineDir "ffprobe.exe"
$ytDlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"

# --- Content Strings ---
$eulaText = @'
==============================[ 법적 고지 (End User License Agreement) ]==============================

**1. 약관 동의**
본 스크립트를 사용하는 것은, 아래의 모든 내용을 완전히 이해하고 동의하는 것으로 간주됩니다.

**2. 목적 및 의도된 사용 범위**
이 스크립트는 자동화된 콘텐츠 다운로드 및 변환을 돕는 도구입니다. 이 도구는 오직 다음과 같은 목적으로만 사용되어야 합니다:
-   사용자 본인이 저작권을 소유한 콘텐츠
-   저작권자가 다운로드를 명시적으로 허용한 콘텐츠 (예: 크리에이티브 커먼즈(CC) 라이선스)
-   개인적이고 비상업적인 용도의 보관 (공정 이용 등 법률이 허용하는 범위 내)

**3. 금지 사항**
-   상업적 목적의 재배포, 재판매, 또는 기타 영리 활동을 위해 이 스크립트를 사용하는 것을 엄격히 금지합니다.
-   이 스크립트는 어떠한 기술적 보호조치(DRM 등)도 우회하지 않으며, 그러한 목적으로 설계되지 않았습니다.

**4. 제3자 오픈소스 고지**
이 스크립트는 다음과 같은 강력한 오픈소스 도구들을 기반으로 동작합니다. 이 도구들은 스크립트 실행 시점에 각 공식 배포처에서 다운로드되며, 이 프로젝트에 의해 재배포되지 않습니다.
-   **yt-dlp:** The Unlicense (https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE)
-   **ffmpeg:** LGPL/GPL (https://www.ffmpeg.org/legal.html)

**5. 보증 부인 및 책임 제한 (No Warranty)**
본 스크립트는 어떠한 종류의 명시적 또는 묵시적 보증 없이 "있는 그대로(AS IS)" 제공됩니다. 상품성, 특정 목적에의 적합성, 비침해성에 대한 보증을 포함하되 이에 국한되지 않습니다.
개발자는 이 스크립트의 사용 또는 오용으로 인해 발생하는 모든 직접적, 간접적, 부수적, 결과적 손해(데이터 손실, 비즈니스 중단 등을 포함)에 대해 어떠한 경우에도 책임을 지지 않습니다.

**6. 사용자 책임**
-   YouTube, Google을 포함한 모든 플랫폼의 서비스 약관을 준수할 책임은 사용자에게 있습니다. 이 프로젝트는 해당 기업들과 아무런 제휴 관계가 없습니다.
-   사용자는 자신이 거주하는 국가 및 지역의 저작권법과 관련 법규를 모두 준수할 법적 책임이 있습니다.

==============================================================================================
'@
$readmeContent = @'
# YTall (Downloader Project)

유튜브 영상/음원을 편리하게 다운로드하고, 영상을 고품질로 인코딩하기 위한 PowerShell 스크립트입니다.

---

## 🚀 시작하기

1.  `run_ytall.ps1` 파일을 원하는 위치(예: 바탕화면)에 놓습니다.
2.  `run_ytall.ps1` 파일을 마우스 오른쪽 버튼으로 클릭하여 **[PowerShell에서 실행]**을 선택합니다.
    -   최초 실행 시, 스크립트가 알아서 `ytall` 폴더를 만들고, 필요한 모든 파일을 다운로드 및 설치합니다. (설치 후 원본 파일은 자동으로 삭제됩니다)
3.  법적 고지(EULA)에 동의(`y` 입력)하고, 바탕화면 바로가기 생성 여부(`y` 또는 `n`)를 선택하면 설치가 완료됩니다.
4.  설치가 끝나면 `README.md` 파일이 자동으로 열립니다. **(중요: 꼭 한번 읽어보세요!)**
5.  `ytall` 폴더 안의 `mp3.txt` 또는 `mp4.txt`에 다운로드할 유튜브 링크를 추가하고 저장합니다.
6.  바탕화면에 생성된 `YTall` 바로가기 또는 `ytall` 폴더 안의 `YTall.bat`을 실행하여 다운로드를 시작합니다.

---

## 🍪 쿠키(Cookie) 사용법 (성인인증 등)

로그인이 필요하거나 성인 인증이 필요한 영상을 다운로드하려면, 브라우저의 쿠키 값을 `details/cookies.txt` 파일에 복사해야 합니다. 아래 방법 중 하나를 선택하여 진행하세요.

**주의:** 쿠키는 민감한 개인정보를 포함할 수 있으므로, 절대로 이 파일을 타인과 공유하지 마십시오.

### 방법 1: 브라우저 확장 프로그램 사용 (권장)

가장 편리한 방법은 쿠키를 파일로 쉽게 내보내주는 확장 프로그램을 사용하는 것입니다.

*   **Chrome / Microsoft Edge:**
    (Edge는 Chrome과 동일한 기반으로 만들어져, Chrome 웹 스토어의 확장 프로그램을 대부분 지원합니다.)
    1.  **[Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)** 확장 프로그램을 설치합니다. (팀장님 추천)
    2.  쿠키를 가져오고 싶은 YouTube 페이지를 엽니다.
    3.  주소창 옆의 확장 프로그램 아이콘(자물쇠 모양)을 클릭한 후, **[Export]** 버튼을 누릅니다.
    4.  `cookies.txt` 파일이 다운로드됩니다.
    5.  다운로드된 `cookies.txt` 파일의 **내용 전체를 복사**하여, `ytall/details/` 폴더에 있는 `cookies.txt` 파일에 **덮어쓰기(붙여넣기)** 후 저장합니다.

*   **Firefox:**
    1.  **[cookies.txt](https://addons.mozilla.org/ko/firefox/addon/cookies-txt/)** 와 같은 쿠키 내보내기 애드온(Add-on)을 설치합니다.
    2.  쿠키를 가져오고 싶은 YouTube 페이지를 엽니다.
    3.  주소창 옆의 쿠키 모양 아이콘을 클릭한 후, **"Download cookies.txt"** 를 클릭합니다.
    4.  `cookies.txt` 파일이 다운로드됩니다.
    5.  다운로드된 `cookies.txt` 파일의 **내용 전체를 복사**하여, `ytall/details/` 폴더에 있는 `cookies.txt` 파일에 **덮어쓰기(붙여넣기)** 후 저장합니다.

---

### 방법 2: 개발자 도구 수동 사용 (확장 프로그램 미설치 시)

#### Chrome / Microsoft Edge에서 쿠키 추출하기

1.  다운로드하려는 영상이 있는 YouTube 페이지를 엽니다.
2.  키보드에서 **F12**를 눌러 **개발자 도구**를 엽니다.
3.  **[네트워크(Network)]** 탭을 클릭합니다.
4.  페이지를 새로고침(**F5**)합니다.
5.  목록에서 `watch?v=`로 시작하는 항목을 클릭합니다.
6.  오른쪽 창에서 **[헤더(Headers)]** 탭을 선택하고 **요청 헤더(Request Headers)** 섹션으로 스크롤합니다.
7.  `cookie:` 항목을 찾아 값 전체를 복사합니다.
8.  `ytall/details/cookies.txt` 파일에 붙여넣고 저장합니다.

#### Firefox에서 쿠키 추출하기

1.  다운로드하려는 영상이 있는 YouTube 페이지를 엽니다.
2.  **F12**를 눌러 **개발자 도구**를 엽니다.
3.  **[네트워크(Network)]** 탭을 클릭하고 페이지를 새로고침(**F5**)합니다.
4.  `watch?v=`로 시작하는 항목을 클릭합니다.
5.  오른쪽 창의 **[헤더(Headers)]** 탭을 선택하고 **요청 헤더(Request Headers)**를 찾습니다.
6.  `Cookie` 항목 값에 마우스 오른쪽 버튼을 클릭하고 **[모두 복사]**를 선택합니다.
7.  `ytall/details/cookies.txt` 파일에 붙여넣고 저장합니다.

---

## 🔧 고급 설정 (config.ini)

`details/config.ini` 파일을 수정하여 스크립트의 여러 동작을 제어할 수 있습니다.

### [Encoding] 섹션 (인코딩 관련)
-   **Encoder**: `gpu`(NVIDIA) 또는 `cpu` 인코더를 선택합니다. (NVIDIA 그래픽카드가 없으면 자동으로 cpu로 전환됩니다)
-   **Resolution**: 영상의 세로 해상도를 지정합니다. (예: 720, 1080)
-   **MaxRate**: 인코딩 시 최대 비트레이트를 제한하여 용량이 과도하게 커지는 것을 방지합니다. (예: 5M, 10M)
-   **GpuCq**: GPU 인코딩 품질 (낮을수록 고화질, 권장: 20-25)
-   **GpuPreset**: GPU 인코딩 속도/품질 균형. `p1`(가장 빠름) ~ `p7`(최고 품질)
-   **CpuCrf**: CPU 인코딩 품질 (낮을수록 고화질, 권장: 22-28)
-   **CpuPreset**: CPU 인코딩 속도/압축률. `ultrafast` ~ `veryslow`

### [General] 섹션 (일반 설정)
-   **EnableEncoding**: `true`로 설정하면, 다운로드된 MP4 영상을 HEVC(H.265) 코덱으로 다시 인코딩합니다. `false`로 설정하면 인코딩 과정을 건너뛰고 원본 파일을 그대로 사용합니다.
-   **ProcessPlaylists**: `true`로 설정하면, `mp3.txt`나 `mp4.txt`에 재생목록 링크가 있을 경우, 목록 안의 모든 영상/음원을 다운로드합니다. `false`로 두면 재생목록 링크 자체의 단일 영상만 받습니다.
    -   **참고:** 처리된 재생목록 링크는 목록 파일에서 자동으로 제거되며, 일부 영상이 실패했을 경우 그 영상의 개별 링크만 남습니다. 따라서 재생목록에 새 영상이 추가된 것을 다시 받으려면, 원본 재생목록 링크를 목록 파일에 다시 추가해주어야 합니다.
-   **PlaySoundOnComplete**: `true`로 설정하면 모든 작업이 끝났을 때 완료 알림음이 재생됩니다.
-   **MinFreeSpaceGB**: 스크립트 실행 시 최소 필요한 디스크 여유 공간(GB)을 지정합니다. 이보다 공간이 적으면 안전을 위해 작업이 중단됩니다.
-   **EmbedThumbnail**: `true`로 설정하면, MP3 다운로드 시 영상의 썸네일을 가져와 앨범 아트로 자동 삽입합니다.
-   **EmbedMetadata**: `true`로 설정하면, MP3 파일 내부에 곡 제목(title), 아티스트(artist), 작곡가(composer) 등의 메타데이터를 자동으로 기록합니다.
---

## ❤️ 개발자 후원 (Sponsorship)

이 프로젝트가 마음에 드셨다면, 개발자에게 작은 응원을 보내주세요. 더 좋은 프로젝트를 만드는 데 큰 힘이 됩니다!

-   [Ctee를 통해 응원하기](https://ctee.kr/place/rumuk)
'@
$licenseContent = @'
MIT License

Copyright (c) 2024 ytall Project Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@
$defaultConfigContent = @'
# ytall 설정 파일 (자세한 내용은 README.md 참조)
[Encoding]
Encoder = gpu
Resolution = 720
GpuCq = 23
GpuPreset = p7
MaxRate = 5M
CpuCrf = 24
CpuPreset = medium

[General]
# MP4 다운로드 후, HEVC(H.265)로 다시 인코딩할지 여부를 결정합니다.
# false로 설정하면, 다운로드된 원본 파일을 그대로 사용합니다. (속도 향상)
EnableEncoding = true
# true로 설정하면, 재생목록 링크 발견 시 목록 전체를 다운로드합니다.
ProcessPlaylists = false
# true로 설정하면, 모든 작업 완료 시 알림음이 재생됩니다.
PlaySoundOnComplete = true
# 다운로드 전 필요한 최소 디스크 여유 공간(GB)을 지정합니다.
MinFreeSpaceGB = 2
# true로 설정하면, MP3 다운로드 시 썸네일을 앨범 아트로 삽입합니다.
EmbedThumbnail = true
# true로 설정하면, MP3 파일 내부에 곡 제목, 아티스트, 작곡가(채널명) 메타데이터를 삽입합니다.
EmbedMetadata = false
'@
$batFileContent = @'
chcp 65001 > nul
setlocal
set "scriptPath=%~dp0run_ytall.ps1"
if not exist "%scriptPath%" (
    echo. & echo [ERROR] run_ytall.ps1 스크립트 파일을 찾을 수 없습니다. & echo.
    pause & exit /b 1
)
:: Use 'start' to launch PowerShell in a new window and detach it from the batch process.
:: This prevents the "Terminate batch job (Y/N)?" prompt on Ctrl+C.
start "YTall Downloader" powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%scriptPath%"
endlocal
exit /b 0
'@

# --- Global Settings & Hashes ---
$defaultConfig = @{ Encoder = "gpu"; Resolution = "720"; GpuCq = "23"; GpuPreset = "p7"; MaxRate = "5M"; CpuCrf = "24"; CpuPreset = "medium"; ProcessPlaylists = $false; PlaySoundOnComplete = $true; MinFreeSpaceGB = 2; EmbedThumbnail = $true; EnableEncoding = $true; EmbedMetadata = $false }
$IP_BAN_KEYWORDS = @("HTTP Error 429", "too many requests")
$COOKIE_KEYWORDS = @("HTTP Error 403", "sign in to confirm your age", "who have enabled it", "netscape format")
$COOLDOWN_SECONDS = 10

# --- Helper Functions ---
function Handle-CookieError {
    Write-Log "쿠키(Cookie) 문제로 다운로드에 실패했습니다. 기존 쿠키 파일을 비웁니다." -Color Yellow
    Clear-Content $cookieFile -ErrorAction SilentlyContinue
    Write-Log "성인 인증 영상 등을 받으려면, 새 쿠키 값을 'details/cookies.txt'에 붙여넣어야 합니다." -Color Yellow
    Write-Log "자세한 방법은 README.md 파일을 참고하세요. 파일을 자동으로 열어드립니다." -Color Cyan
    
    try {
        Start-Process notepad.exe $readmeFile
    } catch {
        Write-Log "README.md 파일을 여는 데 실패했습니다. 직접 'ytall' 폴더에서 파일을 확인해주세요." -Color Red
    }
    
    $script:haltScript = $true
    Write-Log "[CRITICAL] 작업을 중단합니다. 새 쿠키를 적용한 후 다시 실행해주세요." -Color Red
}

function Write-Log {
    param([string]$Message, [string]$Color = "Gray")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    if (Test-Path $logFile) { $logMessage | Out-File -FilePath $logFile -Append -Encoding utf8 }
    Write-Host $logMessage -ForegroundColor $Color
}

function Update-LinkFileAtomic {
    param([string]$FilePath, [System.Collections.Generic.List[string]]$RemainingList)
    $tempDirForAtomic = Join-Path $baseDir "temp"
    if (-not (Test-Path $tempDirForAtomic -PathType Container)) { New-Item -Path $tempDirForAtomic -ItemType Directory | Out-Null }
    $tempFileName = "$(Split-Path $FilePath -Leaf).tmp"
    $tempPath = Join-Path $tempDirForAtomic $tempFileName
    Set-Content -Path $tempPath -Value $RemainingList -Encoding utf8
    Move-Item -Path $tempPath -Destination $FilePath -Force
}

function Install-Deno {
    Write-Log "[INSTALL] Downloading Deno (JS runtime for yt-dlp)..." -Color Cyan
    $denoZipPath = Join-Path $tempDir "deno.zip"
    $denoUrl = "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"
    try {
        Invoke-WebRequest -Uri $denoUrl -OutFile $denoZipPath -UseBasicParsing
        Write-Log "-> deno.zip download complete. Extracting..." -Color Cyan
        Expand-Archive -Path $denoZipPath -DestinationPath $engineDir -Force
        Write-Log "-> Deno installed successfully." -Color Green
    } catch {
        Write-Log "[INSTALL] WARNING: Failed to install Deno. Some videos may fail to download. Error: $_" -Color Yellow
    } finally {
        if (Test-Path $denoZipPath) { Remove-Item $denoZipPath -Force -ErrorAction SilentlyContinue }
    }
}

function Install-YtDlp {
    Write-Log "[INSTALL] Downloading yt-dlp.exe..." -Color Cyan
    try {
        Invoke-WebRequest -Uri $ytDlpUrl -OutFile $ytDlpPath -UseBasicParsing
        Write-Log "-> yt-dlp download complete." -Color Green
    } catch {
        throw "FATAL: Failed to download yt-dlp.exe. Error: $_"
    }
}

function Install-Ffmpeg {
    Write-Log "[INSTALL] Downloading ffmpeg..." -Color Cyan
    $ffmpegZipPath = Join-Path $tempDir "ffmpeg.zip"
    $ffmpegExtractPath = Join-Path $tempDir "ffmpeg_extracted"
    
    try {
        # Dynamically find the latest ffmpeg build URL from the correct GitHub API
        Write-Log "-> Finding latest ffmpeg build from GyanD/codexffmpeg..." -Color Gray
        $apiUrl = "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $asset = $latestRelease.assets | Where-Object { $_.name -like '*essentials_build.zip' } | Select-Object -First 1
        
        if (-not $asset) {
            throw "Could not find a suitable ffmpeg asset (e.g., '...essentials_build.zip') in the latest GitHub release."
        }
        
        $dynamicFfmpegUrl = $asset.browser_download_url
        Write-Log "-> Found asset: $($asset.name). Downloading..." -Color Gray

        Invoke-WebRequest -Uri $dynamicFfmpegUrl -OutFile $ffmpegZipPath -UseBasicParsing
        Write-Log "-> ffmpeg.zip download complete. Extracting..." -Color Cyan
        Expand-Archive -Path $ffmpegZipPath -DestinationPath $ffmpegExtractPath -Force
        # The new zip structure might be different, let's find the bin directory more robustly
        $binDir = Get-ChildItem -Path $ffmpegExtractPath -Filter "bin" -Recurse -Directory | Select-Object -First 1
        if (-not $binDir) {
            # Fallback for flat structure
            $binDir = Get-ChildItem -Path $ffmpegExtractPath -Directory | Select-Object -First 1
        }

        $ffmpegSource = Join-Path $binDir.FullName "ffmpeg.exe"
        $ffprobeSource = Join-Path $binDir.FullName "ffprobe.exe"
        Move-Item -Path $ffmpegSource -Destination $engineDir -Force
        Move-Item -Path $ffprobeSource -Destination $engineDir -Force
        Write-Log "-> ffmpeg installation complete." -Color Green
        
        # Save the release tag for future update checks
        $versionFile = Join-Path $detailsDir "ffmpeg_version.txt"
        Set-Content -Path $versionFile -Value $latestRelease.tag_name
    } catch {
        throw "FATAL: Failed during ffmpeg installation. Error: $_"
    } finally {
        if (Test-Path $ffmpegZipPath) { Remove-Item $ffmpegZipPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path $ffmpegExtractPath) { Remove-Item $ffmpegExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Update-Engine {
    [CmdletBinding()]
    param()

    $updateCheckFile = Join-Path $detailsDir "last_update_check.txt"
    $updateCheckInterval = New-TimeSpan -Days 7
    $needsCheck = $true

    if (Test-Path $updateCheckFile) {
        try {
            $lastCheck = Get-Date (Get-Content $updateCheckFile)
            if ((Get-Date) - $lastCheck -lt $updateCheckInterval) {
                $needsCheck = $false
            }
        } catch {
            Write-Log "Could not parse date from '$updateCheckFile'. Forcing update check." -Color Yellow
        }
    }

    if (-not $needsCheck) {
        return
    }

    Write-Log "Checking for engine updates..." -Color Cyan

    # --- yt-dlp update check (version comparison) ---
    try {
        Write-Log "[Update] Checking yt-dlp version..." -Color Gray
        $localYtDlpVersion = (& $ytDlpPath --version).Trim()
        
        $githubApiUrl = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $githubApiUrl -UseBasicParsing
        $remoteYtDlpVersion = $latestRelease.tag_name.Trim()

        if ($localYtDlpVersion -ne $remoteYtDlpVersion) {
            Write-Log "-> New yt-dlp version found (Local: $localYtDlpVersion, Remote: $remoteYtDlpVersion). Updating..." -Color Yellow
            Install-YtDlp
        } else {
            Write-Log "-> yt-dlp is up to date." -Color Green
        }
    } catch {
        Write-Log "[Update] Failed to check for yt-dlp updates. Error: $_" -Color Red
    }

    # --- ffmpeg update check (release tag comparison) ---
    try {
        Write-Log "[Update] Checking ffmpeg version..." -Color Gray
        $ffmpegVersionFile = Join-Path $detailsDir "ffmpeg_version.txt"
        $localFfmpegTag = ""
        if (Test-Path $ffmpegVersionFile) {
            $localFfmpegTag = Get-Content $ffmpegVersionFile
        }

        $apiUrl = "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $remoteFfmpegTag = $latestRelease.tag_name

        if ($localFfmpegTag -ne $remoteFfmpegTag) {
            Write-Log "-> New ffmpeg build found (Local: $localFfmpegTag, Remote: $remoteFfmpegTag). Updating..." -Color Yellow
            Install-Ffmpeg
        } else {
            Write-Log "-> ffmpeg is up to date." -Color Green
        }
    } catch {
        Write-Log "[Update] Failed to check for ffmpeg updates. Error: $_" -Color Red
    }

    # --- Update the timestamp ---
    try {
        Set-Content -Path $updateCheckFile -Value (Get-Date).ToString("o")
    } catch {
        Write-Log "Failed to write update timestamp to $updateCheckFile" -Color Red
    }
    Write-Log "Finished checking for updates.`n"
}

function Ensure-EngineExists {
    [CmdletBinding()]
    param()
    
    $didInstall = $false
    Write-Log "Verifying required engine components..."
    
    $denoPath = Join-Path $engineDir "deno.exe"
    if (-not (Test-Path $denoPath -PathType Leaf)) {
        $didInstall = $true
        Install-Deno
    }

    if (-not (Test-Path $ytDlpPath -PathType Leaf)) {
        $didInstall = $true
        Install-YtDlp
    }
    
    if ((-not (Test-Path $ffmpegPath -PathType Leaf)) -or (-not (Test-Path $ffprobePath -PathType Leaf))) {
        $didInstall = $true
        Install-Ffmpeg
    }
    
    if (-not $didInstall) {
        Write-Log "-> All components present." -Color Green
    }
    Write-Log ""
    return $didInstall
}

function Get-Safe-FilePath {
    param(
        [PSCustomObject]$Info,
        [string]$Extension,
        [string]$TargetDir
    )
    # Restore the original format and use a blacklist for invalid chars to support all languages
    $safeOutputTitle = ($Info.channel + " - " + $Info.title) -replace '[\\/:*?"<>|]', '_'
    # Also, trim and collapse multiple spaces to keep it clean.
    $safeOutputTitle = $safeOutputTitle.Trim() -replace '\s+', ' '
    if ($safeOutputTitle.Length -gt 150) { $safeOutputTitle = $safeOutputTitle.Substring(0, 150) }
    $outputFile = Join-Path $TargetDir "$safeOutputTitle.$Extension"

    # Check for filename collisions and append a number if necessary
    $counter = 1
    $originalBaseName = [System.IO.Path]::GetFileNameWithoutExtension($outputFile)
    while (Test-Path $outputFile) {
        $newFilename = "$originalBaseName`_($counter).$Extension"
        $outputFile = Join-Path $TargetDir $newFilename
        $counter++
    }
    return $outputFile
}

function Invoke-YtDlp {
    param([array]$Arguments, [switch]$Silent, [switch]$NoCooldown)
    
    $output = [System.Collections.Generic.List[string]]::new()
    $progressShown = $false
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    
    try {
        & $ytDlpPath "--newline" "--color" "never" $Arguments 2>&1 | ForEach-Object {
            $line = $_.ToString()
            $output.Add($line)
            if ($line -match '^\[download\]\s+\d{1,3}(?:\.\d+)?%') {
                Write-Host ("`r" + $line.PadRight(120)) -NoNewline
                $progressShown = $true
            } else {
                if ($progressShown) { Write-Host "" }
                if (-not $Silent) {
                    Write-Log $line -Color "Yellow"
                }
                $progressShown = $false
            }
        }
    } finally {
        $ErrorActionPreference = $prevEAP
    }
    
    if ($progressShown) { Write-Host "" }
    
    if ($LASTEXITCODE -eq 0) {
        if (-not $NoCooldown) {
            Write-Log "-> yt-dlp execution finished. Cooling down for $COOLDOWN_SECONDS seconds..." -Color Gray
            Start-Sleep -Seconds $COOLDOWN_SECONDS
        } else {
            Write-Log "-> yt-dlp execution finished (cooldown skipped)." -Color DarkGray
        }
        return [PSCustomObject]@{ Status = 'Success'; Output = $output }
    }
    
    $outputString = $output -join [System.Environment]::NewLine
    $lowerOutput = $outputString.ToLower()
    
    foreach ($keyword in $IP_BAN_KEYWORDS) {
        if ($lowerOutput -match $keyword) { return [PSCustomObject]@{ Status = 'IpBanError'; Output = $outputString } }
    }
    foreach ($keyword in $COOKIE_KEYWORDS) {
        if ($lowerOutput -match $keyword) { return [PSCustomObject]@{ Status = 'CookieError'; Output = $outputString } }
    }
    
    return [PSCustomObject]@{ Status = 'GenericError'; Output = $outputString }
}

function Invoke-Ffmpeg {
    [CmdletBinding()]
    param(
        [array]$Arguments,
        [double]$TotalSeconds = 0,
        [datetime]$StartTime
    )

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $progressShown = $false
    
    try {
        & $ffmpegPath $Arguments 2>&1 | ForEach-Object {
            $line = $_.ToString()
            if ($line -like '*Late SEI is not implemented*') {
                # This is a non-critical warning we want to hide.
                continue
            }

            # Updated regex to capture speed
            if ($line -match "frame=\s*(\d+)\s*fps=\s*([\d\.]+).*time=\s*(\d{2}):(\d{2}):(\d{2})\.\d+.*speed=\s*([\d\.]+)x") {
                if ($TotalSeconds -gt 0) {
                    $frame = $Matches[1]
                    $hours = [int]$Matches[3]; $minutes = [int]$Matches[4]; $seconds = [int]$Matches[5]
                    $speed = $Matches[6]
                    $currentSeconds = ($hours * 3600) + ($minutes * 60) + $seconds
                    
                    if ($currentSeconds -gt 0) {
                        $percentage = ($currentSeconds / $TotalSeconds) * 100
                        $elapsedTime = (Get-Date) - $StartTime
                        $elapsedString = $elapsedTime.ToString('hh\:mm\:ss')
                        $etaSeconds = ($elapsedTime.TotalSeconds / $currentSeconds) * ($TotalSeconds - $currentSeconds)
                        if ($etaSeconds -lt 0) { $etaSeconds = 0 }
                        $eta = [System.TimeSpan]::FromSeconds($etaSeconds)
                        $etaString = $eta.ToString('hh\:mm\:ss')
                        
                        # Write the progress bar in pieces for coloring
                        Write-Host "`r[CONVERT] " -NoNewline
                        Write-Host ("[{0:N2}%]" -f $percentage) -ForegroundColor Yellow -NoNewline
                        
                        $restOfString = " Frame: {0} | Time: {1}:{2}:{3} | Speed: {4}x | Elapsed: {5} | ETA: {6}" -f $frame, $hours.ToString("00"), $minutes.ToString("00"), $seconds.ToString("00"), $speed, $elapsedString, $etaString
                        Write-Host $restOfString.PadRight(100) -NoNewline
                    }
                } else {
                    # Fallback for when duration is not available
                    $progressLine = "[CONVERT] " + $line.Trim()
                    Write-Host ("`r" + $progressLine.PadRight(120)) -NoNewline
                }
                $progressShown = $true
            } else {
                if ($progressShown) {
                    Write-Host ""
                    $progressShown = $false
                }
                Write-Host $line
            }
        }
    } finally {
        $ErrorActionPreference = $prevEAP
    }
    
    if ($progressShown) { Write-Host "" }

    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        Write-Log "ffmpeg process exited with a non-zero code: $LASTEXITCODE." -Color Red
        return $false
    }
}

function Parse-Config {
    param([string]$FilePath, [hashtable]$Defaults)
    
    $configFromFile = @{}
    if (Test-Path $FilePath) {
        Get-Content $FilePath | ForEach-Object {
            $line = $_.Trim()
            if ($line -and $line -notmatch '^\s*#' -and $line -match '=') {
                $key, $value = $line.Split('=', 2)
                $configFromFile[$key.Trim()] = $value.Trim()
            }
        }
    }
    
    $finalConfig = $Defaults.Clone()
    foreach ($key in $configFromFile.Keys) {
        if ($finalConfig.ContainsKey($key)) {
            $value = $configFromFile[$key]
            # Check if the default value is a boolean, if so, parse the string to a proper boolean
            if ($Defaults[$key] -is [bool]) {
                # Explicitly compare against 'true', case-insensitive. Other values become false.
                $finalConfig[$key] = ($value -eq 'true')
            } else {
                $finalConfig[$key] = $value
            }
        }
    }
    return [PSCustomObject]$finalConfig
}

function Process-UrlType {
    param(
        [ValidateSet('mp3', 'mp4')][string]$Type,
        [System.Collections.Generic.List[string]]$UrlList,
        [string]$LinkFile,
        [ref]$SucceededCount,
        [System.Collections.Generic.List[string]]$FailedUrlList
    )

    $urlsToProcess = [System.Collections.Generic.List[string]]::new($UrlList) # Iterate over a copy
    
    foreach ($url in $urlsToProcess) {
        if ($haltScript) { break }
        
        $playlistFullySuccessful = $true
        $failedVideosInPlaylist = [System.Collections.Generic.List[string]]::new()
        $isVideoList = $false # Initialize per-URL

        try {
            Write-Log "[$($Type.ToUpper())] Fetching metadata for URL: $url"
            $metaArguments = @("--dump-json", "--no-download", "--cookies", $cookieFile, "--ffmpeg-location", $engineDir, $url)
            if (-not $config.ProcessPlaylists) { $metaArguments += "--no-playlist" }

            $infoJsonOutput = & $ytDlpPath $metaArguments 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errorOutput = $infoJsonOutput -join "`n"; $lowerOutput = $errorOutput.ToLower(); $status = 'GenericError'
                foreach ($keyword in $IP_BAN_KEYWORDS) { if ($lowerOutput -match $keyword) { $status = 'IpBanError'; break } }
                foreach ($keyword in $COOKIE_KEYWORDS) { if ($lowerOutput -match $keyword) { $status = 'CookieError'; break } }
                throw $status
            }
            
            $allInfoJson = $infoJsonOutput | Where-Object { $_.TrimStart().StartsWith('{') }
            if (-not $allInfoJson) { throw "Could not find any JSON in yt-dlp output." }

            $isVideoList = $allInfoJson.Count -gt 1

            foreach ($jsonLine in $allInfoJson) {
                if ($haltScript) { throw "Script halted by user or critical error." }
                
                $script:completedTasks++
                $info = $null; $finalOutputFile = $null; $tempFile1 = $null; $tempFile2 = $null; $tempFile3 = $null; $tempFile2_orig = $null
                $videoSuccessful = $false
                try {
                    $info = $jsonLine | ConvertFrom-Json
                    Write-Log "[$($Type.ToUpper())] [$($script:completedTasks)/$($script:totalTasks)] Processing Video: $($info.title)"
                    
                    if ($Type -eq 'mp3') {
                        $finalOutputFile = Get-Safe-FilePath -Info $info -Extension "mp3" -TargetDir $completeDir
                        if ($config.EmbedThumbnail) {
                            $tempFile1 = Join-Path $tempDir "$($info.id).mp3"
                            $audioResult = Invoke-YtDlp -Arguments @("-N", "8", "--cookies", $cookieFile, "-x", "--audio-format", "mp3", "--ffmpeg-location", $engineDir, "-o", $tempFile1, $info.webpage_url, "--no-playlist")
                            if ($audioResult.Status -ne 'Success') { throw $audioResult.Status }
                            if ((Invoke-YtDlp -Arguments @("--skip-download", "--write-thumbnail", "--ffmpeg-location", $engineDir, "-o", (Join-Path $tempDir "%(id)s.%(ext)s"), $info.webpage_url, "--no-playlist") -Silent -NoCooldown).Status -eq 'Success') {
                                $tempFile2_orig = Get-ChildItem -Path $tempDir -Filter "$($info.id).*" | Where-Object { $_.Extension -in ".jpg", ".jpeg", ".png", ".webp" } | Select-Object -First 1
                                if ($tempFile2_orig) {
                                    $tempFile2 = Join-Path $tempDir "$($info.id).jpg"
                                    Invoke-Ffmpeg -Arguments @("-i", $tempFile2_orig.FullName, "-y", "-frames:v", "1", $tempFile2)
                                    if (-not (Invoke-Ffmpeg -Arguments @("-i", $tempFile1, "-i", $tempFile2, "-map", "0:a:0", "-map", "1:v:0", "-c:a", "copy", "-c:v", "mjpeg", "-disposition:v:0", "attached_pic", "-id3v2_version", "3", $finalOutputFile))) { throw "ffmpeg failed to embed thumbnail." }
                                } else {
                                    Write-Log "[MP3] WARNING: Thumbnail downloaded but could not be found. Moving audio without thumbnail." -Color Yellow
                                    Move-Item -Path $tempFile1 -Destination $finalOutputFile -Force
                                }
                            } else {
                                Write-Log "[MP3] WARNING: Thumbnail download failed, proceeding without it." -Color Yellow
                                Move-Item -Path $tempFile1 -Destination $finalOutputFile -Force
                            }
                        } else {
                            $dlResult = Invoke-YtDlp -Arguments @("-N", "8", "--cookies", $cookieFile, "-x", "--audio-format", "mp3", "--ffmpeg-location", $engineDir, "-o", $finalOutputFile, $info.webpage_url, "--no-playlist")
                            if ($dlResult.Status -ne 'Success') { throw $dlResult.Status }
                        }
                        if ($config.EmbedMetadata) {
                            $tempFile3 = Join-Path $tempDir "meta_$($info.id).mp3"
                            if ((Invoke-Ffmpeg -Arguments @("-i", $finalOutputFile, "-map", "0", "-c", "copy", "-metadata", "title=$($info.title)", "-metadata", "artist=$($info.channel)", "-metadata", "composer=$($info.channel)", "-y", $tempFile3))) {
                                Move-Item -Path $tempFile3 -Destination $finalOutputFile -Force
                            } else { Write-Log "[MP3] WARNING: Failed to embed metadata for '$($info.title)'. Continuing..." -Color Yellow }
                        }
                    } elseif ($Type -eq 'mp4') {
                        $tempFile1 = Join-Path $convertDir "$($info.id).mp4"
                        $dlResult = Invoke-YtDlp -Arguments @("-N", "8", "--cookies", $cookieFile, "--ffmpeg-location", $engineDir, "-f", "bestvideo[height<=$($config.Resolution)][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best", "--merge-output-format", "mp4", "-o", $tempFile1, $info.webpage_url, "--no-playlist")
                        if ($dlResult.Status -ne 'Success') { throw $dlResult.Status }
                        if (-not (Test-Path $tempFile1)) { throw "File not found in Convert dir after download." }
                        $finalOutputFile = Get-Safe-FilePath -Info $info -Extension "mp4" -TargetDir $completeDir
                        if ($config.EnableEncoding) {
                            $inputArgs = @(); $outputArgs = @()
                            if ($config.Encoder -eq 'gpu' -and (Test-Path (Join-Path $env:SystemRoot "System32\nvml.dll"))) { $inputArgs += @("-hwaccel", "cuda"); $outputArgs += @("-c:v", "hevc_nvenc", "-vf", "scale=-2:$($config.Resolution)", "-cq", $config.GpuCq, "-preset", $config.GpuPreset, "-maxrate", $config.MaxRate, "-c:a", "copy") }
                            else { $outputArgs += @("-c:v", "libx264", "-vf", "scale=-2:$($config.Resolution)", "-crf", $config.CpuCrf, "-preset", $config.CpuPreset, "-maxrate", $config.MaxRate, "-c:a", "copy") }
                            if (-not (Invoke-Ffmpeg -Arguments ($inputArgs + @("-y", "-i", $tempFile1) + $outputArgs + $finalOutputFile) -TotalSeconds $info.duration -StartTime (Get-Date))) { throw "ffmpeg encoding failed." }
                        } else { Move-Item -Path $tempFile1 -Destination $finalOutputFile -Force }
                    }
                    $videoSuccessful = $true
                    Write-Log "[$($Type.ToUpper())] SUCCESS: Processing complete for '$($info.title)'." -Color Green
                } catch {
                    $playlistFullySuccessful = $false
                    if ($info) { $failedVideosInPlaylist.Add($info.webpage_url) }
                    $errorMessage = $_.ToString()
                    Write-Log "[$($Type.ToUpper())] FAILED video '$(if ($info) { $info.title } else { 'N/A' })' from playlist '$url'. Error: $errorMessage" -Color Red
                    if ($errorMessage -like '*CookieError*' -or $errorMessage -like '*IpBanError*') { throw }
                } finally {
                    foreach($tempPath in @($tempFile1, $tempFile2, $tempFile3, $tempFile2_orig.FullName)) {
                        if ($tempPath -and (Test-Path $tempPath)) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
                    }
                    if (-not $videoSuccessful -and $finalOutputFile -and (Test-Path $finalOutputFile)) {
                        Write-Log "-> Cleaning up incomplete final file: $finalOutputFile" -Color Yellow
                        Remove-Item $finalOutputFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {
            $playlistFullySuccessful = $false
            $errorMessage = $_.ToString()
            Write-Log "[$($Type.ToUpper())] FAILED processing of URL '$url'. Error: $errorMessage" -Color Red
            if (-not $FailedUrlList.Contains($url)) { $FailedUrlList.Add($url) }
            if ($errorMessage -like '*CookieError*') { Handle-CookieError }
            elseif ($errorMessage -like '*IpBanError*') {
                $script:haltScript = $true
                Write-Log "[CRITICAL] IP가 차단된 것으로 보입니다. 잠시 후 다시 시도해주세요. 작업을 중단합니다." -Color Red
            }
        }
        
        $currentRemaining = [System.Collections.Generic.List[string]]::new($UrlList)
        if ($playlistFullySuccessful) {
            $currentRemaining.Remove($url)
            $SucceededCount.Value++
            Write-Log "[$($Type.ToUpper())] SUCCESS: Entire URL '$url' processed successfully." -Color Green
        } else {
            if ($isVideoList) {
                $currentRemaining.Remove($url)
                $currentRemaining.AddRange($failedVideosInPlaylist)
            }
            if (-not $FailedUrlList.Contains($url)) { $FailedUrlList.Add($url) }
            Write-Log "[$($Type.ToUpper())] PARTIAL/FAIL: URL '$url' had at least one failure. Failed videos will be retried." -Color Yellow
        }
        Update-LinkFileAtomic -FilePath $LinkFile -RemainingList $currentRemaining
        $UrlList.Clear()
        $UrlList.AddRange($currentRemaining)
    }
}

# --- Main Execution Block ---
$failedMp3Urls = [System.Collections.Generic.List[string]]::new(); $failedMp4Urls = [System.Collections.Generic.List[string]]::new(); $succeededMp3Count = 0; $succeededMp4Count = 0; $haltScript = $false; $jobRun = $true; $didPerformSetupActions = $false; $isCompleteFirstRun = $false

try {
    # This part of the bootstrapper logic remains in the main script to handle the post-move cleanup.
    if ($OriginalPath -and (Test-Path $OriginalPath)) { 
        1..3 | ForEach-Object {
            Start-Sleep -Seconds 1
            if (-not (Test-Path $OriginalPath)) { return } # Exit loop if already deleted
            Remove-Item -Path $OriginalPath -Force -ErrorAction SilentlyContinue 
        }
        if (Test-Path $OriginalPath) {
            Write-Log "-> WARNING: Could not delete the original script file. You may need to delete it manually: $OriginalPath" -Color Yellow
        }
    }
    
    # --- Initial Setup on First Run ---
    if (-not (Test-Path $detailsDir -PathType Container)) { 
        $didPerformSetupActions = $true
        New-Item -Path $detailsDir -ItemType Directory | Out-Null 
    }

    if (-not (Test-Path $eulaAcceptedFile -PathType Leaf)) { 
        $isCompleteFirstRun = $true
        $didPerformSetupActions = $true
        Write-Host ""
        Write-Host $eulaText -ForegroundColor Yellow
        $agreement = ""
        while ($agreement -ne 'y' -and $agreement -ne 'n') {
            $agreement = Read-Host "`n위 내용에 동의하십니까? [y/n]"
        }
        if ($agreement -ne 'y') { 
            Write-Host "동의하지 않아 중단합니다." -ForegroundColor Red
            return 
        }
        Set-Content -Path $eulaAcceptedFile -Value "EULA accepted on: $(Get-Date)"
        Write-Host "$([char]27)[92m동의 감사합니다.$([char]27)[0m" # Using bright green ANSI code
    }

    # Structure verification and file creation
    if (-not (Test-Path $logFile)) { New-Item -Path $logFile -ItemType File | Out-Null }
    Clear-Content $logFile
    Write-Host "======================================================" -ForegroundColor Magenta
    Write-Log "Starting ytall Downloader v17.1..." -Color Cyan
    Write-Host "======================================================" -ForegroundColor Magenta
    
    Write-Log "Verifying project structure..."
    foreach ($dir in @($engineDir, $tempDir, $convertDir, $completeDir)) { 
        Write-Log "--> Checking dir: $dir" -Color DarkGray
        if (-not (Test-Path $dir)) { 
            $didPerformSetupActions = $true
            Write-Log "--> Creating dir: $dir" -Color Yellow
            New-Item -Path $dir -ItemType Directory | Out-Null 
        } 
    }
    foreach ($file in @($mp3ListFile, $mp4ListFile, $cookieFile)) { 
        Write-Log "--> Checking file: $file" -Color DarkGray
        if (-not (Test-Path $file)) { 
            $didPerformSetupActions = $true
            Write-Log "--> Creating file: $file" -Color Yellow
            New-Item -Path $file -ItemType File | Out-Null 
        } 
    }
    Write-Log "--> Checking config file..." -Color DarkGray
    if (-not (Test-Path $configFile)) { 
        $didPerformSetupActions = $true
        Write-Log "--> Creating config file..." -Color Yellow
        Set-Content -Path $configFile -Value $defaultConfigContent -Encoding utf8 
    }

    Write-Log "--> Checking bat file..." -Color DarkGray
    $batFilePath = Join-Path $baseDir "YTall.bat"
    if (-not (Test-Path $batFilePath)) { 
        $didPerformSetupActions = $true
        Write-Log "--> Creating bat file..." -Color Yellow
        Set-Content -Path $batFilePath -Value $batFileContent -Encoding Ascii 
    }

    Write-Log "--> Checking readme file..." -Color DarkGray
    if (-not (Test-Path $readmeFile)) { 
        $didPerformSetupActions = $true
        Write-Log "--> Creating readme file..." -Color Yellow
        Set-Content -Path $readmeFile -Value $readmeContent -Encoding utf8 
    }
    Write-Log "--> Checking license file..." -Color DarkGray
    if (-not (Test-Path $licenseFile)) {
        $didPerformSetupActions = $true
        Write-Log "--> Creating license file..." -Color Yellow
        Set-Content -Path $licenseFile -Value $licenseContent -Encoding utf8
    }
    Write-Log "--> File checks complete." -Color DarkGray
    
    if ($didPerformSetupActions -and -not $isCompleteFirstRun) { 
        Write-Log "-> Project structure verified and repaired." -Color Green 
    }

    if (Ensure-EngineExists) { 
        $didPerformSetupActions = $true 
    }

    if ($isCompleteFirstRun) {
        Write-Log "==================== [ INSTALLATION COMPLETE ] ====================" -Color Green
        Write-Log "All necessary folders and files have been set up." -Color Green
        $createShortcut = ""
        while ($createShortcut -ne 'y' -and $createShortcut -ne 'n') {
            $createShortcut = Read-Host "바탕화면에 'YTall' 바로가기를 만드시겠습니까? [y/n]"
        }
        if ($createShortcut -eq 'y') { 
            try { 
                $wshell = New-Object -ComObject WScript.Shell
                $desktopPath = $wshell.SpecialFolders.Item("Desktop")
                $shortcutPath = Join-Path $desktopPath "YTall.lnk"
                $shortcut = $wshell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = "powershell.exe"
                $shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSScriptRoot\run_ytall.ps1`""
                $shortcut.WorkingDirectory = $baseDir
                $shortcut.IconLocation = "System32\imageres.dll,8"
                $shortcut.Save()
                Write-Log "-> 바탕화면에 'YTall' 바로가기를 생성했습니다." -Color Green 
            } catch { 
                Write-Log "-> 바로가기 생성에 실패했습니다. 오류: $_" -Color Red 
            } 
        }
        Write-Log "사용법을 숙지할 수 있도록 README.md 파일을 자동으로 열어드립니다." -Color Cyan
        try {
            Start-Process notepad.exe $readmeFile
        } catch {
            Write-Log "README.md 파일을 여는 데 실패했습니다. 직접 'ytall' 폴더에서 파일을 확인해주세요." -Color Red
        }
        Write-Log "작업을 중단합니다. mp3.txt 또는 mp4.txt에 링크를 추가하고 다시 실행해주세요." -Color Yellow
        $jobRun = $false
        return
    }
    
    # --- Regular Job Execution ---
    Update-Engine
    
    $config = Parse-Config -FilePath $configFile -Defaults $defaultConfig
    Write-Log "Config loaded. Encoder: $($config.Encoder.ToUpper()), Playlist Processing: $($config.ProcessPlaylists)" -Color Cyan
    
    # Check for free disk space
    try {
        if ($baseDir.StartsWith("\\")) {
            Write-Log "-> Skipping disk space check on UNC path." -Color Yellow
        } else {
            $drive = Get-PSDrive -Name $baseDir.Substring(0, 1)
            $minFreeBytes = [long]([double]$config.MinFreeSpaceGB * 1GB)
            if ($drive.Free -lt $minFreeBytes) {
                $availableGB = [math]::Round($drive.Free / 1GB, 2)
                throw "Insufficient disk space. Available: $($availableGB) GB, Required: $($config.MinFreeSpaceGB) GB. Halting."
            }
            Write-Log "Disk space check passed. Available: $([math]::Round($drive.Free / 1GB, 2)) GB" -Color Green
        }
    } catch {
        if ($_.Exception.Message -like '*Cannot convert value*') {
             Write-Log "[CRITICAL] Invalid value for 'MinFreeSpaceGB' in config.ini. Please use a number (e.g., 2 or 2.5)." -Color Red
        } else {
            Write-Log "[CRITICAL] $_" -Color Red
        }
        $jobRun = $false
        return
    }

    Get-ChildItem -Path $tempDir -File | Remove-Item -Force -ErrorAction SilentlyContinue

    $remainingMp3Urls = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $mp3ListFile) { 
        # Force the result into an array and explicitly cast to [string[]] for type safety with AddRange.
        $mp3content = [string[]]@(
            Get-Content $mp3ListFile -Encoding utf8 |
            Where-Object { $_.Trim() -ne "" } |
            Select-Object -Unique
        )
        if ($mp3content) { 
            $remainingMp3Urls.AddRange($mp3content) 
        } 
    }
    $remainingMp4Urls = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $mp4ListFile) { 
        # Force the result into an array and explicitly cast to [string[]] for type safety with AddRange.
        $mp4content = [string[]]@(
            Get-Content $mp4ListFile -Encoding utf8 |
            Where-Object { $_.Trim() -ne "" } |
            Select-Object -Unique
        )
        if ($mp4content) { 
            $remainingMp4Urls.AddRange($mp4content) 
        } 
    }

    if ($remainingMp3Urls.Count -eq 0 -and $remainingMp4Urls.Count -eq 0) { 
        $jobRun = $false
        Write-Log "No links to process. Exiting."
        return 
    }

    $totalTasks = $remainingMp3Urls.Count + $remainingMp4Urls.Count
    $completedTasks = 0
    Write-Log "Processing $totalTasks total tasks..."

    # --- MP3 Processing ---
    if ($remainingMp3Urls.Count -gt 0) {
        Write-Log "`n1. Starting MP3 processing..."
        Process-UrlType -Type 'mp3' -UrlList $remainingMp3Urls -LinkFile $mp3ListFile -SucceededCount ([ref]$succeededMp3Count) -FailedUrlList $failedMp3Urls
    }

    # --- MP4 Processing ---
    if (-not $haltScript -and $remainingMp4Urls.Count -gt 0) {
        Write-Log "`n2. Starting MP4 processing (Download & Encode)..."
        Process-UrlType -Type 'mp4' -UrlList $remainingMp4Urls -LinkFile $mp4ListFile -SucceededCount ([ref]$succeededMp4Count) -FailedUrlList $failedMp4Urls
    }
}
catch {
    Write-Log "An unexpected terminating error occurred: $($_.Exception.Message)" -Color Red
    Write-Log $_.ToString() -Color Red
}
finally {
    if ($jobRun -and -not $isCompleteFirstRun) {
        if ($config.PlaySoundOnComplete) {
            Write-Log "Playing completion sound..." -Color Cyan
            try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
        }
        Write-Host ""
        Write-Host "================== FINAL JOB REPORT ==================" -ForegroundColor Magenta
        Write-Host ""
        if ($haltScript) { 
            Write-Log "[HALTED] Script stopped early due to a critical error." -Color Yellow
            Write-Host "" 
        }
        
        Write-Host "[MP3] " -NoNewline; Write-Host "$($succeededMp3Count) succeeded" -ForegroundColor Green -NoNewline; Write-Host ". "; Write-Host "$($failedMp3Urls.Count) failed" -ForegroundColor Red -NoNewline; Write-Host "."
        Write-Host "[MP4] " -NoNewline; Write-Host "$($succeededMp4Count) succeeded" -ForegroundColor Green -NoNewline; Write-Host ". "; Write-Host "$($failedMp4Urls.Count) failed" -ForegroundColor Red -NoNewline; Write-Host "."

        Write-Host "" 
        Write-Host "======================================================" -ForegroundColor Magenta
        Write-Host ""
    }
    Write-Log "Process finished. Press Enter to exit..."
    Read-Host | Out-Null
}
