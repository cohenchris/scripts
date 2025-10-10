#!/bin/python3

import plexapi.server
import sys
import requests

if len(sys.argv) != 3:
    print("Usage: plex-server-maintenance-broadcast.py <plex URL> <plex token>")
    exit(1)

PLEX_URL = sys.argv[1]
PLEX_TOKEN = sys.argv[2]

try:
    server = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN)
except requests.exceptions.ConnectionError as e:
    print("ERROR: Bad URL! Unable to connect to Plex")
    exit(1)
except plexapi.exceptions.Unauthorized as e:
    print("ERROR: Bad API key! Unable to connect to Plex")
    exit(1)

sessions = server.sessions()
for session in sessions:
    # Log session details
    print(f"Stopping Plex playback session ID #{session.sessionKey}:")
    
    print(f"\tUser \"{session.user.username}\" is ", end="")

    if session.type == "movie":
        print(f"watching a movie")
        print(f"\t{session.title}")

    elif session.type == "episode":
        print(f"watching TV")
        print(f"\t{session.grandparentTitle} - S{session.parentIndex:02}E{session.index:02} - {session.title}")

    elif session.type == "track":
        print(f"listening to music")
        print(f"\t{session.grandparentTitle} - {session.parentTitle} - {session.title}")
    
    print()

    # Stop the session
    try:
        session.stop(reason="Sorry! Going down for daily automated backup, should only take a few minutes!")
    except AttributeError as e:
        # Attempting to stop a PlexAmp session always throws a weird error here, seems to be a bug in plexapi.
        # Just ignore it.
        pass
