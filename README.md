# YTall
A PowerShell-based YouTube downloader powered by yt-dlp.

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
