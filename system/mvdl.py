#!/usr/bin/env python3

# This script takes either a file of youtube URLs (separated by newlines) or a
#   youtube playlist URL as input
# It will first download each video
# Then, it will attempt to find a matching track file
# If a match is found, the music video will be renamed to match the track,
#   which will cause the music video to show up in Plex for that track

import argparse
import difflib
import re
import sys
from pathlib import Path

try:
    import yt_dlp
except ImportError:
    print("yt-dlp is not installed as a Python package. Install it with: pip install yt-dlp", file=sys.stderr)
    sys.exit(1)


COLORS = {
    "SUCCESS": "\033[32m",
    "WARN": "\033[93m",
    "ERROR": "\033[31m",
    "INFO": "\033[94m",
}
NC = "\033[0m"

# Audio file types we expect to find in a Plex artist's music directory
AUDIO_EXTENSIONS = {"mp3", "flac", "m4a", "aac", "ogg", "opus", "wav", "wma", "alac", "aiff"}

# How similar a video title has to be to a track title (via difflib) to count as a match
MATCH_CUTOFF = 0.6


# log(log_level, message)
#   log_level - importance of log message
#   message   - message to log
#
# Log a message with pretty colors depending on log_level
def log(log_level, message):
    if not log_level or not message:
        raise ValueError("log() requires both a log_level and a message")

    if log_level not in COLORS:
        raise ValueError(f"Unknown log_level: {log_level!r}")

    sys.stdout.write(f"{COLORS[log_level]}{message}{NC}")
    sys.stdout.flush()


# _normalize_title(text)
#
# Shared cleanup tail for both music video titles and track file titles:
# strip everything but letters/digits/whitespace (Unicode-aware), collapse
# whitespace, and lowercase
def _normalize_title(text):
    cleaned = "".join(ch for ch in text if ch.isalnum() or ch.isspace())
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned.lower()


# clean_music_video_title(name_to_clean)
#   name_to_clean - music video title to clean up
#
# Youtube music video titles are obviously not standardized, so this just does its best
# I attempt to handle two different title formats:
#   1. "Artist Name - Track Title [trackHashGeneratedByYTDL].extension"
#   2. "Artist Name - Track Title (feat. Second Artist) [trackHashGeneratedByYTDL].extension"
#
# This function tries to extract the title by taking the string after the '-'. and before either the first '[' or '('
def clean_music_video_title(name_to_clean):
    if not name_to_clean:
        return ""

    # Take an educated guess where the track name starts, and cut out everything before it
    if "-" in name_to_clean:
        # If there's a '-', cut out a substring after that.
        cleaned = name_to_clean.split("-", 1)[1]
    elif '"' in name_to_clean:
        # Else, if there's a double quote, cut out a substring after that
        cleaned = name_to_clean.split('"', 1)[1]
    elif "＂" in name_to_clean:
        # Another type of double quote
        cleaned = name_to_clean.split("＂", 1)[1]
    elif "'" in name_to_clean:
        # Else, if there's a single quote, cut out a substring after that
        cleaned = name_to_clean.split("'", 1)[1]
    else:
        # The rest of the cleaning relies on the 'cleaned' variable, so make sure it's set
        cleaned = name_to_clean

    # Take an educated guess where the track ends by truncating after either the first '(' or '['
    cleaned = cleaned.split("(", 1)[0]
    cleaned = cleaned.split("[", 1)[0]

    # Remove "Official Music Video" or "Official Video"
    cleaned = re.sub(r"official music video|official video", "", cleaned, count=1, flags=re.IGNORECASE)

    return _normalize_title(cleaned)


# clean_track_file(track_filename)
#
# Plex music files should be standardized in the following formats:
#   "Artist Name - Album Name - TrackNum - Title.extension"
#   "Artist Name - Album Name - TrackNum - Title (feat. Second Artist).extension"
#
# This function extracts the title for the track file name
def clean_track_file(track_filename):
    if not track_filename:
        return ""

    # Remove extension
    cleaned = Path(track_filename).stem

    # Remove everything before the last hyphen
    cleaned = cleaned.split(" - ")[-1]

    # Remove everything after the last opening parenthesis, if present
    cleaned = cleaned.split(" (", 1)[0]

    return _normalize_title(cleaned)


# extract_track_name(track_path)
#   track_path - track path from which to extract a title string
#
# Returns the file name without its extension
def extract_track_name(track_path):
    if not track_path:
        return ""

    return Path(track_path).stem


# find_match(dir_to_search, track_to_find)
#   dir_to_search - music directory to search for a file whose name matches track_to_find
#   track_to_find - title string of video for which we would like to find a track file match
#
# This function assists in matching the downloaded music video to a track file on this computer.
# It uses difflib to find the closest-matching track title, rather than requiring an exact substring
# match, since video/track titles are rarely formatted identically.
def find_match(dir_to_search, track_to_find):
    if not dir_to_search or not track_to_find:
        return ""

    # Map cleaned track title -> every track file that cleans down to that title
    candidates = {}
    for track_file in Path(dir_to_search).rglob("*"):
        if not track_file.is_file() or track_file.name.startswith("."):
            continue

        if track_file.suffix.lstrip(".").lower() not in AUDIO_EXTENSIONS:
            continue

        cleaned_track_title = clean_track_file(track_file.name)
        if not cleaned_track_title:
            continue

        candidates.setdefault(cleaned_track_title, []).append(track_file)

    if not candidates:
        return ""

    best_titles = difflib.get_close_matches(track_to_find, candidates.keys(), n=1, cutoff=MATCH_CUTOFF)
    if not best_titles:
        return ""

    matches = candidates[best_titles[0]]

    # We only succeed if there's exactly one file with the best-matching title
    if len(matches) != 1:
        return ""

    return extract_track_name(matches[0])


# unique_destination(path)
#
# If path doesn't already exist, return it as-is. Otherwise, find a numbered variant that doesn't
# exist yet, so a rename never silently clobbers an existing file.
def unique_destination(path):
    if not path.exists():
        return path

    n = 2
    while True:
        candidate = path.with_name(f"{path.stem} ({n}){path.suffix}")
        if not candidate.exists():
            return candidate
        n += 1


# YtdlpLogger
#
# Routes yt-dlp's own log messages through log(), and tracks whether an error occurred during the
# most recent download so we can tell a genuine failure apart from a "already downloaded" skip
# (both surface as extract_info() returning None).
class YtdlpLogger:
    def __init__(self):
        self.had_error = False

    def debug(self, msg):
        pass

    def warning(self, msg):
        log("WARN", f"{msg}\n")

    def error(self, msg):
        self.had_error = True
        log("ERROR", f"{msg}\n")


# extract_downloaded_paths(info)
#
# Given a yt-dlp info dict (for a single video or a playlist), return the paths of every file that
# was actually written to disk.
def extract_downloaded_paths(info):
    if info is None:
        return []

    entries = info.get("entries")
    if entries is None:
        entries = [info]

    paths = []
    for entry in entries:
        if not entry:
            continue
        for requested in entry.get("requested_downloads") or []:
            filepath = requested.get("filepath")
            if filepath:
                paths.append(Path(filepath))

    return paths


#################### MAIN ####################

def main():
    parser = argparse.ArgumentParser(description="Download YouTube music videos and rename them to match a Plex artist's track files")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--infile", type=argparse.FileType("r"), help="Path to a text file containing newline-separated YouTube video URLs")
    group.add_argument("--playlist", help="YouTube playlist URL; every video in the playlist will be downloaded")
    args = parser.parse_args()

    artist_musicvideos_dir = Path.cwd()  # Artist's music video directory (script should be called there)
    artist_name = artist_musicvideos_dir.name  # Name of the artist we're working with
    artist_music_dir = (artist_musicvideos_dir / ".." / ".." / "music" / artist_name).resolve()  # Artist's music files directory

    # Confirm that these are right. If not, quit
    log("INFO", "Artist music videos location:   ")
    print(artist_musicvideos_dir)
    log("INFO", "Artist music files location:    ")
    print(artist_music_dir)

    print()

    try:
        log("WARN", "Are these settings correct? (y/N) ")
        yn = input()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(1)

    if yn.strip()[:1].lower() == "y":
        log("SUCCESS", "Great! Continuing...\n")
    else:
        # Take in manual paths
        log("ERROR", "Sorry about that! You will have to manually enter your information.\n\n")

        try:
            log("INFO", "Full path to the directory containing your artist's music videos: ")
            artist_musicvideos_dir = Path(input()).expanduser()
            print()

            log("INFO", "Full path to the directory containing your artist's music files: ")
            artist_music_dir = Path(input()).expanduser()
            print()
        except (EOFError, KeyboardInterrupt):
            print()
            sys.exit(1)

        # Restate what they've entered
        log("INFO", "NEW Artist music videos location:   ")
        print(artist_musicvideos_dir)
        log("INFO", "NEW Artist music files location:    ")
        print(artist_music_dir)

    print()

    if not artist_musicvideos_dir.is_dir():
        log("ERROR", f"Music videos directory does not exist: {artist_musicvideos_dir}\n")
        sys.exit(1)

    if not artist_music_dir.is_dir():
        log("ERROR", f"Music files directory does not exist: {artist_music_dir}\n")
        sys.exit(1)

    ytdlp_logger = YtdlpLogger()
    ydl_opts = {
        "quiet": True,
        "noprogress": True,
        "logger": ytdlp_logger,
        "ignoreerrors": True,
        "paths": {"home": str(artist_musicvideos_dir)},
        "outtmpl": "%(title)s [%(id)s].%(ext)s",
        "download_archive": str(artist_musicvideos_dir / ".mvdl_archive.txt"),
    }

    downloaded_paths = []
    failed_urls = []

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        if args.infile:
            lines = args.infile.read().splitlines()
            infile_path = Path(args.infile.name)
            args.infile.close()

            for line in lines:
                if not line.strip():
                    continue

                log("INFO", f"Downloading {line}...\n")
                ytdlp_logger.had_error = False
                info = ydl.extract_info(line, download=True)

                if info is None:
                    if ytdlp_logger.had_error:
                        failed_urls.append(line)
                    else:
                        log("INFO", "Already downloaded previously, skipping.\n")
                    continue

                downloaded_paths.extend(extract_downloaded_paths(info))

            infile_path.unlink()
        else:
            log("INFO", f"Downloading playlist {args.playlist}...\n")
            info = ydl.extract_info(args.playlist, download=True)

            if info is None:
                log("ERROR", f"Failed to download playlist: {args.playlist}\n")
                sys.exit(1)

            entries = info.get("entries")
            if entries is not None:
                total = len(entries)
                succeeded = sum(1 for entry in entries if entry)
                if succeeded < total:
                    log("WARN", f"{total - succeeded} of {total} playlist video(s) failed to download and were skipped\n")

            downloaded_paths.extend(extract_downloaded_paths(info))

    print()

    if failed_urls:
        log("WARN", f"{len(failed_urls)} URL(s) failed to download and were skipped:\n")
        for url in failed_urls:
            print(f"  {url}")
        print()

    if not downloaded_paths:
        log("WARN", "No new videos were downloaded.\n")

    # For each downloaded video, look for matches in the artist_music_dir
    for video_path in sorted(downloaded_paths):

        video_title = video_path.name
        video_extension = video_path.suffix.lstrip(".")

        log("INFO", f"Trying to find a match for \"{video_title}\"...\n")

        # Normalize input video file name
        clean_video_title = clean_music_video_title(video_title)

        # Attempt to find a match
        match_name = find_match(artist_music_dir, clean_video_title)

        if not match_name:
            # No match found... Rename in a generic manner
            log("ERROR", "Match not found :(\n")
            target_name = f"{clean_video_title}.{video_extension}"
        else:
            # Match found! Rename the video to mirror the match
            log("SUCCESS", f"Successful match with \"{match_name}\"\n")
            target_name = f"{match_name}.{video_extension}"

        dest = unique_destination(artist_musicvideos_dir / target_name)
        if dest.name != target_name:
            log("WARN", f"\"{target_name}\" already exists, saving as \"{dest.name}\" instead\n")

        video_path.rename(dest)

        print()

    print("Don't forget to refresh the Plex artist page!\n")


if __name__ == "__main__":
    main()
