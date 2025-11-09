#!/usr/bin/env bash
BASE_URL="https://download.quranicaudio.com/quran"
QARI=("muhammad_ayyoob_hq" "abdurrashid_sufi")
DEST_DIR="$HOME/Quran"


for j in "${!QARI[@]}"; do

  mkdir -p "$DEST_DIR/${QARI[j]}"

  for i in $(seq -w 1 114); do
    FILE="${i}.mp3"
    echo "Downloading $FILE to $DEST_DIR/${QARI[j]}"
    curl -sSL -o "${DEST_DIR}/${QARI[j]}/${FILE}" "${BASE_URL}/${QARI[j]}/${FILE}"
  done

echo "✅ All files saved in $DEST_DIR/${QARI[j]}"
done  

