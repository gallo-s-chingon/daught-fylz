#!/bin/bash
# Author: @gallo-s-chingon with help from ChatGPT and Perplexity to refactor my old cobbled togeth mess of functions
# version history at
# https://gist.github.com/gallo-s-chingon/fe64e5a249d3aef1ab8a254f4409174e
# Script to create blog posts for sucias.xyz

# Constants
BLOG_DIR="_blog"
EPISODE_DIR="_posts"
FEATURED_DIR="_feat"
DEFAULT_DESCRIPTION_FILE="tanim.txt"
WORK_DIR="$SCS/_posts/"
# Functions

# Prompt user and get input, with validation
prompt_input() {
    local prompt="$1"
    local regex="$2"
    local input
    while true; do
        read -e -p "$prompt: " input
        if [[ $input =~ $regex ]]; then
            echo "$input"
            break
        else
            echo "( ���)� Invalid input. Try again."
        fi
    done
}

# Create a post
create_post() {
    local type="$1"
    local dir="$2"
    local title
    local description
    local link_type
    local link
    local excerpt
    local post_date
    local year
    local month
    local day
    local embed_code
    local post_name

    cd "$WORK_DIR" || exit

    read -e -p "Did you copy the show description? (y/n): " answer
    [[ $answer == "y" ]] || { echo "Copy the show description with 'hyper + h' dumbass"; return 1; }

    # Get the year for the blog post
    while true; do
        read -e -p "When will this be posted? (YY or YYYY): " answer
        if [[ $answer =~ ^[0-9]{2}$ ]]; then
            year="20$answer"
            break
        elif [[ $answer =~ ^[0-9]{4}$ ]]; then
            year="$answer"
            break
        elif [[ $answer =~ (now|today|tom|tomorrow|manana|ma�ana) ]]; then
            if [[ $answer =~ (now|today) ]]; then
                post_date=$(date +%Y-%m-%d)
            elif [[ $answer =~ (tom|tomorrow|manana|ma�ana) ]]; then
                post_date=$(date -d '+1 day' +%Y-%m-%d)
            fi
            break
        else
            echo "Invalid year format. Please try again."
        fi
    done

    # Get the month for the blog post
    while true; do
        read -e -p "What month will this blog be posted? (1-12): " month
        if [[ $month =~ ^[1-9]|1[0-2]$ ]]; then
            month=$(printf "%02d" $month)
            break
        else
            echo "Enter a valid month number (1-12)."
        fi
    done

    # Print a 3-month calendar for the specified year and month
    if [[ -z $post_date ]]; then
        ncal -3 -m "$month" "$year"
    fi

    # Get the day for the blog post if $post_date is empty
    if [[ -z $post_date ]]; then
        while true; do
            read -e -p "What day will this blog be posted? (1-31): " day
            if [[ $day =~ ^[1-9]|[12][0-9]|3[01]$ ]]; then
                day=$(printf "%02d" $day)
                break
            else
                echo "Enter a valid day number (1-31)."
            fi
        done
    fi

    # Check if post_date is still empty
    if [[ -z $post_date ]]; then
        post_date="$year-$month-$day"
    fi

    description=$(cat "$CONF/$DEFAULT_DESCRIPTION_FILE") # Paste description from show notes
    read -e -p "Title: " title          # Episode title

    # Ask for the link type (Spotify or YouTube)
    link_type=$(prompt_input "What type of link is this? (Spotify/YouTube)" "^(Spotify|YouTube|spot|spotify|youtube|yt)$")

    if [[ $link_type =~ (Spotify|spotify|spot) ]]; then
        read -e -p "Paste Spotify link: " link
        shortLink=$(echo "${link%%\?*}" | cut -d "/" -f5)
        embed_code="<iframe src='https://open.spotify.com/embed/episode/$shortLink' width='80%' height='232' frameborder='0' allowtransparency='true' allow='encrypted-media'></iframe>"
    elif [[ $link_type =~ (YouTube|youtube|yt) ]]; then
        read -e -p "Paste YouTube link: " link
        shortLink=$(echo "$link" | rev | cut -d "/" -f 1 | rev)
        embed_code="{% include video id='$shortLink' provider='youtube' %}"
    fi

    # Extract the first line of the description for the excerpt
    excerpt=$(echo "$description" | head -1)
    # Replace colons with hyphens in the excerpt to avoid YAML conflicts
    excerpt_clean=$(echo "$excerpt" | sed 's/[:,.!?&'"'"'"]//g')
    # Convert the title to lowercase with hyphens instead of spaces
    post_title_lowercase=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | tr -cd '[:alnum:]-')
    # Construct the post file name
    post_name="$year-$month-$day-$post_title_lowercase.md"

    # Create the post file and write the content
    touch "$post_name"
    echo "---
title: $title
date: $post_date
excerpt: '$excerpt_clean'
header:
  teaser: /images/$episode_image
  overlay_image: /images/show-logo.png
  overlay_filter: 0.5
---

$embed_code

$description

# Mentioned items


" >>"$post_name"

    nvim "$post_name"
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <type> (epi, feat, blog)"
    exit 1
fi

case "$1" in
    "epi") create_post "Episode" "$EPISODE_DIR" ;;
    "feat") create_post "Featured" "$FEATURED_DIR" ;;
    "blog") create_post "Blog" "$BLOG_DIR" ;;
    *) echo "Invalid post type. Please use 'epi', 'feat', or 'blog'." && exit 1 ;;
esac
