# Generic Bin

Dependency-free system scripts which are intended to be added to PATH and run from the command line.

These focus on generic everyday automations.
Think of these as scripts that can be easily moved from system to system with zero effort (assuming the correct packages are installed).
For example, one of the scripts in here is a file extraction wrapper which uses different programs depending on the file extension - this can be dropped on any system that supports bash.




# Table of Contents

- [System Update](#System-Update)
- [Wifi Network Selector](#Wifi-Network-Selector)
- [Archive Extraction](#Archive-Extraction)
- [Local E-Mail Sync](#Local-E-Mail-Sync)
- [LF File Manager Image Navigation](#LF-File-Manager-Image-Navigation)
- [LF File Manager Wrapper for Image Viewing](#LF-File-Manager-Wrapper-for-Image-Viewing)
- [LaTeX Shortcuts](#LaTeX-Shortcuts)
- [Music Video Downloader](#Music-Video-Downloader)
- [Set Random Wallpaper](#Set-Random-Wallpaper)
- [Blue Light Filter](#Blue-Light-Filter)
- [Email Lookup](#Email-Lookup)
- [Fuzzel-Based Pinentry](#Fuzzel-Based-Pinentry)
- [Notification Wrapper](#Notification-Wrapper)




## System Update
[`update`](update)

This script is meant to run on a system running the `paru` AUR helper package manager (likely Arch Linux).
It also assumes that the user has a docker-compose stack located at `/home/${USER}/server.

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker-compose images
4. Remove all dangling docker container images


## Wifi Network Selector
[`wifi-selector`](wifi-selector)

Fuzzel-based wifi network selector.
Utilizes `nmcli` to scan for available networks and presents them in a friendly list.
The user may then navigate this list using arrow keys or vim directional bindings (h/j/k/l) and select the desired network by pressing Enter.
Please note that this script requires the use of a Wayland display manager.




## Archive Extraction
[`extract [FILE...]`](extract)

There are many different types of compressed files, each of which requires a different extraction program.
This script allows an unlimited number of arguments to be passed, each of which should be some sort of compressed file.
It will loop through each argument and use the correct extraction program based on the file extension.




## Local E-Mail Sync
[`mailsync`](mailsync)

1. Sync all emails using `mbsync`
2. Index synced emails using `notmuch`
3. Notify the user about any new unread emails
4. Sync contacts using `vdirsyncer`

Synced email may be viewed with a local client such as `neomutt`.




## LF File Manager Wrapper for Image Viewing
[`lf-wrapper`](lf-wrapper)

This is a wrapper script for lf. It does the following:
    - Sets up environment for ueberzug image previewing
    - On exit, `cd` to the last active directory
        - For this to work, this wrapper must be sourced instead of called directly

This script is a combination of the ueuberzug wrapper pulled from Luke Smith's dotfiles [here](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/lfub), and lfcd logic pulled from the official lf repository [here](https://github.com/gokcehan/lf/blob/master/etc/lfcd.sh).




## LaTeX Shortcuts
[`mytex [compile,create,edit] [FILENAME]`](mytex)

This script helps automate common LaTeX commands that I use.
The user will pass a filename as an argument.

Behavior differs depending on the subcommand:

`compile <tex_source_file>` compiles the source file into a PDF.

`create <filename>` spits out a file (name provided as an argument) which contains a very simple LaTeX template.

`edit <tex_source_file>` compiles the source file into a PDF, open the PDF, and open the source file in vim.




## Music Video Downloader
[`mvdl [FILE]`](mvdl)

This script reads in a file which contains newline-separated YouTube music video URLs.
If there is a music file and music video file with the same name, Plex can automatically detect this and associate the two files.
If there is a music file with an associated music video file, Plex will allow you to play either file.
This script is an attempt to automate the process of pulling + renaming music videos for this feature.
You may read about this naming process [here](https://support.plex.tv/articles/205568377-adding-local-artist-and-music-videos/).

This script is pretty hardcoded to my personal environment and directory structure.

1. User points the script to music and music video directories
2. Download each video
3. Based on the title of the music video, attempt to find a matching music file
4. If a match is found, rename the downloaded music video according to the standard linked above
5. If a match is not found, rename the downloaded music video to a cleaner, more readable version




## Set Random Wallpaper
[`random-wallpaper`](random-wallpaper)

Selects and random image from the `${XDG_DATA_HOME}/wallpapers` directory and sets it as the user's wallpaper.
Please note that this script requires the use of a Wayland display manager.




## Blue Light Filter
[`bluelightfilter [up,down,kill]`](bluelightfilter)

This script helps manage blue light filtering on Wayland using `wl-gammarelay-rs`.

`up` increases the orange intensity

`down` decreases the orange intensity

`kill` resets the filter to default




## Email Lookup
[`email-lookup [query]`](email-lookup)

Searches for an email address matching 'query' in your local khard address book.
This is intended to be used for autocompletion by another program, like neomutt.




## Fuzzel-Based Pinentry
[`pinentry-fuzzel`](pinentry-fuzzel)

Incredibly simple pinentry handler using fuzzel.
I often use this to unlock my GPG keyring.




## Notification Wrapper
[`notify [LOW,NORMAL,CRITICAL] [message1] [message2]`](notify)

Easy-to-use notify-send wrapper for sending desktop notifications.
Used by many of the scripts in this repository.
