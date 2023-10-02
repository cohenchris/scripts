#!/bin/python3.11

from __future__ import division             # allows division to be float by default
from plexapi.myplex import MyPlexAccount
from plexapi.server import PlexServer
from typing import List
import json
import os
import requests
import shutil
from PIL import Image
from dotenv import load_dotenv


#####################################
# Prepare environment and load Plex #
#####################################
RED = "\033[91m"
GREEN = "\033[92m"
BLUE = "\033[94m"
YELLOW = "\033[93m"
RESET = "\033[0m"

load_dotenv()
PLEX_URL = os.getenv('PLEX_URL')
PLEX_TOKEN = os.getenv('PLEX_TOKEN')

# Place that the website expects data to be
WEBSITE_PUBLIC_DIR = os.getenv("WEBSITE_HTML_DIR")

account = MyPlexAccount(PLEX_TOKEN)
session = requests.Session()
session.verify = False
requests.packages.urllib3.disable_warnings()
server = PlexServer(PLEX_URL, PLEX_TOKEN, session)

##################################
########## JSON Defines ##########
##################################
class Track:
    def __init__(self, name: str, rating: float):
        self.name = name 
        self.rating = rating

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class Album:
    def __init__(self, name: str, artist: str, genres: List[str], label: str, year: int, tracks: List[Track], cover: str):
        self.name = name                                                        # album name
        self.artist = artist
        self.genres = ", ".join(genres) if len(genres) > 0 else "[no genres]"   # genres (comma-separated)
        self.label = label if label is not None else "[no label]"               # label released
        self.year = year                                                        # release year
        self.tracks = tracks                                                    # array of Track objects
        self.cover = cover                                                      # uri to cover of the album 

        # favorites
        highest = max(self.tracks, key=lambda t: t.rating).rating
        self.favorites = []
        [self.favorites.append(track) for track in self.tracks if track.rating == highest]

        # overall album rating
        total = 0
        [total := total + track.rating for track in self.tracks]
        self.rating = round((total / len(self.tracks)), 2)

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class Artist:
    def __init__(self, name: str, albums: List[Album], image: str):
        self.name = name        # name of artist
        self.albums = albums    # array of Album objects
        self.image = image      # uri to image of the artist

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)

##################################
######## Helper Functions ########
##################################
def convert_to_webp(source):
    root, ext = os.path.splitext(source)
    destination = root + ".webp"

    try:
        image = Image.open(source)
        image.save(destination, format="webp", quality=1)

        os.remove(source);
    except:
        # Some artist images are not available, skip errors with these
        pass

    return destination

##################################
########## Library Scan ##########
##################################
def scan_library() -> List[Artist]:
    # Scan all artists
    artists = server.library.section("Music").searchArtists()
    library: List[Artist] = []

    # Iterate through each artist
    for artist in artists:
        albumlist: List[Album] = []
        artist_log_str = ""
        
        # Iterate through each of the artist's albums
        for album in artist.albums():
            omitAlbum = False
            tracklist: List[Track] = []

            # Determine eligible albums
            if (len(album.tracks()) <= 4):
                # If album only has 4 or fewer songs, we count it as an EP. Omit from JSON.
                artist_log_str += YELLOW + f"\t{album.title} (<4 songs)\n" + RESET
                omitAlbum = True
                continue
            
            # Iterate through each track in the given album, reading the rating from each track
            for track in album:
                # If album isn't fully rated, omit from JSON
                if track.userRating is None:
                    omitAlbum = True
                    break
                tracklist.append(Track(track.title, track.userRating))

            # Add album to output, if it is eligible
            if not omitAlbum:
                # add fully-rated albums
                artist_log_str += GREEN + f"\t{album.title}\n" + RESET
                albumlist.append(Album(
                                       album.title,
                                       artist.title,
                                       [genre.tag for genre in album.genres],
                                       album.studio,
                                       album.year,
                                       tracklist,
                                       f"{album.key}/thumb"
                                      )
                                 )
            else:
                # omit unrated albums
                artist_log_str += RED + f"\t{album.title} (unrated)\n" + RESET

        # Determine eligible artists
        if len(albumlist) > 0:
            # Sort albums high-low rating in their respective arrays
            albumlist = sorted(albumlist, key=lambda album: album.rating, reverse=True)

            # Add artists with 1 or more rated albums
            artist_log_str = BLUE + f"{artist.title}\n" + RESET + artist_log_str
            library.append(Artist(artist.title, albumlist, f"{artist.key}/thumb"))
        else:
            # If the artist has no rated albums, omit from JSON
            artist_log_str = BLUE + f"OMITTING {artist.title} (no fully-rated albums available)\n" + RESET + artist_log_str

        print(artist_log_str)

    return library


##########################
########## Main ##########
##########################

# Scan library for eligible albums
library = scan_library()
os.chdir(WEBSITE_PUBLIC_DIR)

music_dir = os.path.join(WEBSITE_PUBLIC_DIR, "music")

# Remove existing music directory tree, if it exists
try:
    shutil.rmtree(music_dir)
except FileNotFoundError:
    pass

os.mkdir(music_dir)
os.chdir(music_dir)

# Write eligible album JSON to a file
with open("library.json", "w") as f:
    f.write(json.dumps(library, default=lambda o: o.__dict__, indent=4, ensure_ascii=True))

# Download all metadata (artist images and album art)
metadata_dir = os.path.join(music_dir, "metadata")

# Create new metadata directory
os.mkdir(metadata_dir)

# For each valid artist/albums, create a directory for each artist, with supporting metadata
for artist in library:
    # make artist directory, if it doesn't exist already
    artist_dir = os.path.join(metadata_dir, artist.name)
    os.mkdir(artist_dir)
    # download artist image
    artist_image_path = os.path.join(artist_dir, "image.jpg")
    with open(artist_image_path, "wb") as image:
        response = requests.get(f"{PLEX_URL}{artist.image}?X-Plex-Token={PLEX_TOKEN}", verify=False)
        image.write(response.content)
    # Convert to webp for better performance
    convert_to_webp(artist_image_path)

    for album in artist.albums:
        # make album directories
        album.name = album.name.replace("/", "+")  # temp fix for album names with a slash - breaks the next statements
        album_dir = os.path.join(artist_dir, album.name)
        try:
            os.mkdir(album_dir)
        except FileExistsError:
            pass

        # download album art
        album_cover_path = os.path.join(album_dir, "cover.jpg")
        if not os.path.isfile(album_cover_path):
            # Only get cover if it doesn't exist
            with open(album_cover_path, "wb") as cover:
                response = requests.get(f"{PLEX_URL}{album.cover}?X-Plex-Token={PLEX_TOKEN}", verify=False)
                cover.write(response.content)
            # Convert to webp for better performance
            convert_to_webp(album_cover_path)

