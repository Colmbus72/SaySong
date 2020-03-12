# SaySong
```
  ______              ______
 / _____)            / _____)
( (____  _____ _   _( (____   ___  ____   ____
 \____ \(____ | | | |\____ \ / _ \|  _ \ / _  |
 _____) ) ___ | |_| |_____) ) |_| | | | ( (_| |
(______/\_____|\__  (______/ \___/|_| |_|\___ |
              (____/                    (_____|
```

## System Requirements

`ffmpeg`
`say` OR `espeak`
`curl`

## Usage

SaySong will write all songs lyrics and mp3s under ~/SaySong/

-a | Artist
-s | Song
-v | Voice

### Examples

    ./say_song.sh -a "Talking Heads" -s "Once in a Lifetime" -v "Daniel"

    ./say_song.sh -a "Kanye West" -s "Follow God"
