#!/bin/python3
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

load_dotenv()
PLEX_URL = os.getenv('PLEX_URL')
PLEX_TOKEN = os.getenv('PLEX_TOKEN')

# Place that the website expects data to be
WEBSITE_PUBLIC_DIR = os.getenv("WEBSITE_HTML_DIR")

account = MyPlexAccount(PLEX_TOKEN)
server = PlexServer(PLEX_URL, PLEX_TOKEN)

class Track:
    def __init__(self, title: str, rating: float):
        self.title = title
        self.rating = rating

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class Album:
    def __init__(self, title: str, artist: str, genres: List[str], label: str, year: int, tracks: List[Track], cover: str):
        self.title = title                                                      # album title
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



def scan_library() -> List[Artist]:
    artists = server.library.section("Music").searchArtists()
    library: List[Album] = []

    for artist in artists:
        for album in artist.albums():
            omit = False
            tracklist: List[Track] = []

            # If album only has 4 or fewer songs, we count it as an EP. Omit from JSON.
            if (len(album.tracks()) <= 4):
                print(f"omitting {album.title}")
                omit = True
                continue

            for track in album:
                # If album isn't fully rated, omit from JSON
                if track.userRating is None:
                    omit = True
                    break
                tracklist.append(Track(track.title, track.userRating))


            if not omit:
                # omit unrated albums
                library.append  (   Album   (
                                            album.title,
                                            artist.title,
                                            [genre.tag for genre in album.genres],
                                            album.studio,
                                            album.year,
                                            tracklist,
                                            f"{album.key}/thumb"
                                            )
                                )
        # omit artists with zero rated albums
#        if len(albumlist) > 0:
#            library.append(Artist(artist.title, albumlist, f"{artist.key}/thumb"))

    return library





library = scan_library()

os.chdir(WEBSITE_PUBLIC_DIR)

# Output library to a JSON file
with open("library.json", "w") as f:
    f.write(json.dumps(library, default=lambda o: o.__dict__, indent=4, ensure_ascii=True))

# Download all artist images and album art
metadata_dir = os.path.join(WEBSITE_PUBLIC_DIR, "metadata")
try:
    shutil.rmtree(metadata_dir)
except FileNotFoundError:
    pass

try:
    os.mkdir(metadata_dir)
except FileNotFoundError:
    pass

for album in library:
    # make artist directory, if it doesn't exist already
    artist_dir = os.path.join(metadata_dir, album.artist)
    try:
        os.mkdir(artist_dir)
    except FileExistsError:
        pass

    # download artist image
#    artist_image_path = os.path.join(artist_dir, "image.jpg")
#     if not os.path.isfile(artist_image_path):
#         # Only get image if it doesn't exist
#         with open(artist_image_path, "wb") as image:
#             response = requests.get(f"{PLEX_URL}{artist.image}?X-Plex-Token={PLEX_TOKEN}")
#             image.write(response.content)

    # make album directory
    album.title = album.title.replace("/", "+")  # temp fix for album titles with a slash - breaks the next statements
    album_dir = os.path.join(artist_dir, album.title)
    try:
        os.mkdir(album_dir)
    except FileExistsError:
        pass

    # download album art
    album_cover_path = os.path.join(album_dir, "cover.jpg")
    if not os.path.isfile(album_cover_path):
        # Only get cover if it doesn't exist
        with open(album_cover_path, "wb") as cover:
            response = requests.get(f"{PLEX_URL}{album.cover}?X-Plex-Token={PLEX_TOKEN}")
            cover.write(response.content)
        # Compress image
        try:
            img = Image.open(album_cover_path)
            img.save(album_cover_path, optimize=True, quality=20)
        except OSError:
            # Download again
            with open(album_cover_path, "wb") as cover:
                response = requests.get(f"{PLEX_URL}{album.cover}?X-Plex-Token={PLEX_TOKEN}")
                cover.write(response.content)
            pass
