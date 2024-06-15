<img width="1012" alt="image" src="https://github.com/Hansanghyeon/comfortable-music/assets/42893446/13583931-5b39-4911-9444-740cb5263678">

## TL;DR

> [!TIP]
> `.env`파일은 명령어를 실행시킬 곳에 먼저 추가해주세요
> jellyfin server 도메인, jellyfin api 입력하는 단계가 제거됩니다.

```
sh -c "$(curl -sL https://api.github.com/repos/hansanghyeon-selfhost/comfortable-music-server/contents/scripts/download.sh | jq -r '.content' | base64 --decode)"
```

## Feature

- [x] 뮤직서버 (self-host)
- [x] 유튜브 음악 손쉽게 다운로드 받기 스크립트
- [ ] apt, brew 패키지로 만들기

## 쾌적한 음악 아카이브 서버 만들기

항상 사용하는 서비스가 아닌 아카이브 용도로 사용할 미디어플레이서 서버이다.
미디어 플레이어 서버중에 plex, jellyfin 등등 여러가지가 있다.

나는 이미 plex의 패스를 구매했다 `$119.99` 구매했지만 plex를 사용하지 않을 것이다

- why?
  - API 사용 불가능
  - 가벼운 애플리케이션
  - 기존 영상 미디어 서버와 분리

그래서 나는 jellyfin을 선택했다. 

😎 jellyfin을 경험하고 plex보다 더 좋다면 이쪽으로 모두 이주할 예정이다.

### 아카이브 서버를 왜 만드는가?

플레이리스트를 유튜브, 유튜브뮤직에서 제일 많이 듣는다 자주듣는 플레이리스트가 어느 순간 없어지는 것을 경험했다. 유튜브 자체 심의를 거쳐서 영상이 삭제될 수 도 있고 업로드 본인이 해당 영상을 삭제할 수도 있다.

그래서 나는 내가 원하는 음원들을 아카이빙하려한다.

### 음원을 어떻게 저장할 것인가?

플레이리스트안에 각각의 음원들을 구분해서 저장하고싶었다. 그래서 스포티파이? 스포티파이에서 음원자체를 저장해야겠다 생각했지만 스포티파이는 오프라인 저장을 지원하지만 해당 음원을 추출하는 것은 플랫폼 자체에서 벤할 수 있는 사례라고 한다.
그럼 유튜브 영상자체에서 저장해야겠다 생각했다. 스포티파이에 비해서 유튜브는 다운로드 받을 수 있는 방법이 많고 유명한 라이브러리도 존재한다.

https://github.com/yt-dlp/yt-dlp

해당 라이브러리를 사용해서 저장할 예정이다.

### 아카이빙 서버에서 yt-dlp 사용법 최적화하기

내가 저장하려하는 영상은 짧으면 1시간 길면 몇시간을 넘기는 영상이다. 그중에 챕터가 구분되어있는 영상을 위주로 아카이빙 하려한다.

#### 영상 음원 저장하기, 챕터별 구분

```shell
yt-dlp -x --audio-format mp3 --split-chapters -o "chapter:%(section_number)02d-%(section_title).200s.%(ext)s" {{youtube_video_id}}
```

#### 음원 썸네일 저장하기

```shell
yt-dlp --write-thumbnail --skip-download {{youtube_video_id}}
```

webp로 된 이미지를 imagemagick을 이용해서 jpg로 변경하기

```shell
convert *.webp cover.jpg
```

### jellyfin 라이브러리 스캔 빠르게하기

jellyfin은 영상파일 음악파일이 업로드되어도 자동적으로 스캔하지 않는다. jellyfin에서 `관리자 > 라이브러리 > 라이브러리 스캔` 이 단계를 거쳐야 저장된 음원이 라이브러리에 보이게된다.

어지럽다 스크립트를 통해 jellyfin api를 이용해서 자동화하자

```sh
curl -X POST "$JELLYFIN_SERVER_DOMAIN/Library/Refresh" \
    -H "X-Emby-Token: $JELLYFIN_SERVER_API_KEY"
```

간단한 API로 정말 빠르게 jellyfin 라이브러리를 스캔

### 플레이리스트 다운로드 스크립트

1. 유튜브 음악 저장
2. 유튜브 썸네일 저장
3. 썸네일 convert cover.jpg
4. jellyfin 라이브러리 스캔

매번 총 4단계를 모두 명령어를 통해서 하다보니 실수할때도있고 번거롭기도하다. 쉘스크립트를 이용해서 위 4개의 스크립트를 만든다.

`./scripts/download.sh` 해당 파일 참고
