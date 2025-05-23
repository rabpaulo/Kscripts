#!/bin/sh
help(){
    echo "Usage: kpfarchive.sh <idol>"
    echo "Options:"
    echo "  -s  Sort method (new, old, best)"
    echo "  -t  Time filter (day, week, month, year)"
    echo "  -n  Page limit for scraping"
    echo "  -h  Display this help message"
}
cache_dir="/tmp/kpfarchive"
mkdir -p "$cache_dir"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0"
LIMIT=50
DATE=""
SORT="new"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PINK='\033[1;35m'
PURPLE='\033[1;34m'
NC='\033[0m'

while getopts "s:t:n:h" flag; do
    case "${flag}" in
        s) SORT="${OPTARG}";;
        t) DATE="${OPTARG}";;
        n) LIMIT="${OPTARG}";;
        h) help && exit 0;;
        *) help && exit 1;;
    esac
done
shift $((OPTIND-1))
idol=$1
[ -z "$idol" ] && help && exit 1
shift $((OPTIND-1))

output_dir="kpfarchive/$idol"
mkdir -p "$output_dir/images"
mkdir -p "$output_dir/videos"

# Create separate files for videos and images
video_list="$cache_dir/${idol}_videos.m3u"
image_list="$cache_dir/${idol}_images.m3u"
touch "$video_list" "$image_list"

for page in $(seq 1 "$LIMIT"); do
    base="https://kpfarchive.com/api/posts?date=$DATE&from=&page=$page&s=$idol&sort=$SORT"
    temp="$cache_dir/curl"
    
    curl -s "$base" \
        -H "User-Agent: $USER_AGENT" > "$temp"
    
    cat "$temp" | grep -oP '(https://[^"]+\.(mp4|webm|gifv))' >> "$video_list"
    cat "$temp" | grep -oP 'https://www\.reddit\.com/gallery/[a-zA-Z0-9]+' >> "$image_list"
    cat "$temp" | grep -oP '(https://[^"]+\.(jpg|jpeg|png|gif))' >> "$image_list"
    
    if [ ! -s "$temp" ] || ([ ! -s "$video_list" ] && [ ! -s "$image_list" ]); then
        echo -e "${YELLOW}No more results found after page ${page}${NC}"
        break
    fi
    
    echo -e "${PURPLE}Scraping page:${NC} $page"
    sleep 1
done

gallery-dl -i "$video_list" -D "$output_dir/videos" -R 10
gallery-dl -i "$image_list" -D "$output_dir/images" -R 10

rm -rf "$cache_dir"
printf "${GREEN}Elapsed:${NC} %dm%ds\n" $((SECONDS/60)) $((SECONDS%60))
