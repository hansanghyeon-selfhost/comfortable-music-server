#!/bin/sh

# .env 파일에서 환경변수를 불러옵니다.
set -a
. ./.env
set +a

#################### 유튜브 음악 저장

# 유튜브 아이디를 스크립트 실행시에 받아와야한다.
read -p "저장하실 유튜브 아이디를 입력해주세요: " ytid

# 유튜브 아이디를 입력하지 않거나 공백이면 스크립트를 종료합니다.
if [ -z "$ytid" ]; then
    echo "유튜브 아이디를 입력하지 않았습니다. 스크립트를 종료합니다."
    exit 1
fi

# 이후 처리할 코드 작성
echo "입력한 유튜브 아이디는: $ytid 입니다."

# 유니크폴더 만들기
folder=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c 1-12)
echo "플레이리스트를 저장할 폴더입니다: $folder"
mkdir ../$folder

# 유니크폴더 플레이리스트 저장
cd ../$folder
echo "플레이리스트를 저장합니다 ...🏃‍♀️"
yt-dlp -x --audio-format mp3 --split-chapters -o "chapter:%(section_number)02d-%(section_title).200s.%(ext)s" $ytid

# 플레이리스트 앨범 커버 저장
echo "플레이리스트 앨범 커버를 저장합니다 ...🏃‍♀️"
yt-dlp --write-thumbnail --skip-download $ytid
convert *.webp cover.jpg
rm -rf *.webp

echo "뮤직 아카이브서버 라이브러리 스캔 ...🏃‍♀️"
curl -X POST "$JELLYFIN_SERVER_DOMAIN/Library/Refresh" \
    -H "X-Emby-Token: $JELLYFIN_SERVER_API_KEY"

sleep 3

#################### 앨범정보에서 타이틀 업데이트

## album.nfo 파일이 있는지 확인하고 없으면 종료
if [ ! -f album.nfo ]; then
    echo "album.nfo 파일을 찾을 수 없습니다. 스크립트를 종료합니다."
    exit 1
fi

# "01-", "02-" 등으로 시작하지 않는 mp3 파일 찾기
mp3_file=$(ls *.mp3 2>/dev/null | grep -vE '^[0-9]{2}-' | head -n 1)
if [ -z "$mp3_file" ]; then
    echo "유효한 mp3 파일을 찾을 수 없습니다. 스크립트를 종료합니다."
    exit 1
fi

# mp3 파일의 확장자 제거
title=$(basename "$mp3_file" .mp3)
title=$(echo "$title" | sed "s/ \[$ytid\]$//")

# album.nfo 파일의 <title> 태그를 webm 파일 이름으로 변경
sed -i "s|<title>.*</title>|<title>$title</title>|" album.nfo

# 변경 완료 메시지 출력
echo "album.nfo 파일의 <title> 태그가 '$title'로 변경되었습니다."

#################### 완료
echo "✅ 플레이리스트 저장 완료"
