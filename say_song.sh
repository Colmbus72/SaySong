#!/bin/bash
#
# Script Name: saysong.sh
#
# Author: Cameron Dudley
# Date : 03/11/20
#
# Description: This script reads in an artist (-a) and song title (-s),
#              grabs the lyrics from azlyrics, and creates an mp3 file
#              with the specified voice (-v) speaking the song using say
#              or espeak.
#
# Run Information: Run ./saysong.sh -a artist -s songname -v voice
#                  It will try to strip the spaces if you prefer the
#                  format "Song Name"
#
#                  The voice argument is optional
#
#               Example Usage:
#
#                  ./saysong.sh -a talkingheads -s onceinalifetime -v Daniel
#
#                  ./saysong.sh -a "Talking Heads" -s Once in a Lifetime" -v Daniel
#
# Error Log: Any errors or output associated with the script will be output to stdout
#

command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is required but is not installed. Aborting."; exit 1; }

if [ -x "$(command -v say)" ]
then
    COMMAND="say"
elif [ -x "$(command -v espeak)" ]
then
    COMMAND="espeak"
fi

if [ ! "$COMMAND" ]
then
    echo "say or espeak is required but is not installed. Aborting."
    exit 1
fi

# get command line arguments
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -a|--artist)
    ARTIST="$2"
    shift
    ;;
    -s|--song)
    SONG="$2"
    shift
    ;;
    -v|--voice)
    VOICE="$2"
    shift
    ;;
    -d|--delete-lyrics)
    REMOVE_LYRICS=1
    ;;
esac
shift
done

# Validate Arguments
if [ "$COMMAND" = "say" ]
then
    if [ -n "$VOICE" ] && ! $(say -v? | cut -d ' ' -f1 | grep -qi "$VOICE")
    then
        echo "Cannot find voice: $VOICE. Please try one of these:"
        say -v?
        exit 1;
    fi
else
    if [ ! "$VOICE" ]
    then
        VOICE="default"
    fi
    if ! $(espeak --voices | awk '{print $4}' | sed -n '1!p' | grep -qi "$VOICE")
    then
        echo "Cannot find voice: $VOICE. Please try one of these:"
        espeak --voices
        exit 1;
    fi
fi

if [ ! "$SONG" ]
then
    echo "Please use -s or --song to specify which song."
    exit 1
fi

if [ ! "$ARTIST" ]
then
    echo "Please use -a or --artist to specify which artist sings the song."
    exit 1
fi

DIR=~/SaySong/$ARTIST

mkdir -p "$DIR"

echo "Getting $SONG by $ARTIST"

LYRICS_FILE_PATH="$DIR/$SONG.txt"
RAW_FILE_PATH="$DIR/$SONG.$( if [ "$COMMAND" = "say" ]; then echo "aiff"; else echo "wav"; fi )"
MP3_FILE_PATH="$DIR/$SONG.mp3"

LYRIC_ARTIST=$(echo "$ARTIST" | tr [:upper:] [:lower:] | tr -cd [:alnum:])
LYRIC_SONG=$(echo "$SONG" | tr [:upper:] [:lower:] | tr -cd [:alnum:])

curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" "https://www.azlyrics.com/lyrics/$LYRIC_ARTIST/$LYRIC_SONG.html" | grep "<br>" | sed -E 's/(<\/?br?>)|(<a.*.<\/a>)|(<span.*.<\/span>)|(<i>.*.<\/i>)|(<div.*)|(&quot;)//g' | sed -n '1!p' | sed '$d' > "$LYRICS_FILE_PATH"

if grep -q "We have a large, legal, every day growing universe of lyrics where stars of all genres and ages shine" "$LYRICS_FILE_PATH"
then
    echo "Cannot find song: \"$SONG\" by \"$ARTIST\""
    rm "$LYRICS_FILE_PATH"
    if [ ! "$(ls -A "$DIR")" ] 
    then
        rmdir "$DIR"
    fi
    exit 1
fi

echo "Saying Song"

$COMMAND -f "$LYRICS_FILE_PATH" -v "$VOICE" $( if [ "$COMMAND" = "say" ]; then printf %s -o; else printf %s -w; fi ) "$RAW_FILE_PATH"

if [[ $REMOVE_LYRICS = 1 ]]
then
    echo "Removing lyrics"
    rm -f "$LYRICS_FILE_PATH"
fi

echo "Converting to mp3"
ffmpeg -guess_layout_max 0 -i "$RAW_FILE_PATH" -hide_banner -loglevel panic -y -ac 2 -f mp3 "$MP3_FILE_PATH" 2>&1 &

MPEGPID=$!
while $(ps -p "$MPEGPID" > /dev/null); do sleep 1; done

echo "Removing raw file"
rm "$RAW_FILE_PATH"

echo "DONE!"
