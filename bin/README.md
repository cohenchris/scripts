# Standalone Helpers

Dependency-free system scripts which are added to the PATH and can be run from the command line.

These focus on generic everyday automations.
Think of these as scripts that can be easily moved from system to system with zero effort (assuming the correct packages are installed).
For example, one of the scripts in here is a file extraction wrapper which uses different programs depending on the file extension - this can be dropped on any system that supports bash.

---

## System Update
[`update`](update)

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker container images
4. Remove all unused cached docker container images


## Wifi Network Selector
[`wifi`](wifi)

Dmenu-based wifi network selector.
Utilizes `nmcli` to scan for available networks and presents them in a friendly list.
The user may then navigate this list using arrow keys or vim directional bindings (h/j/k/l) and select the desired network by pressing Enter.




## Archive Extraction
[`extract [FILE...]`](extract)

There are many different types of compressed files, each of which requires a different extraction program.
This script allows an unlimited number of arguments to be passed.
It will loop through each argument and use the correct extraction program based on the file extension.




## Local E-Mail Sync
[`mailsync`](mailsync)

1. Sync all emails using `mbsync`
2. Index synced emails using `notmuch`
3. Notify the user about any new unread emails
4. Sync contacts using `vdirsyncer`

Synced email may be viewed with a local client such as `neomutt`.




## LF File Manager Image Navigation
[`rotdir`](rotdir)

Helper script for image viewing in 'lf' file manager.
When I open an image using this program, this script allows me to press next/previous keys to scroll through all images in the current directory.
This script "rotates" the content of a directory based on the first chosen file.
For example, if I open the 15th image, pressing next will show me the 16th image.

This script was pulled directly from Luke Smith's dotfiles [here](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/rotdir).




## LF File Manager Wrapper for Image Viewing
[`lfwrapper`](lfwrapper)

This is a wrapper script for lf that allows it to create image previews with ueberzug.

This script was pulled directly from Luke Smith's dotfiles [here](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/lfub)




## LaTeX Shortcuts
[`mytex [compile, create, edit] [FILENAME]`](mytex)

This script helps automate common LaTeX commands that I use.
The user will pass a filename as an argument.

Behavior differs depending on the subcommand:
`compile`
  - This script will compile the source file into a PDF.
`create`
  - This script will spit out a file (name provided as an argument) which contains a very simple LaTeX template.
`edit`
  - This script will compile that source file into a PDF, display the PDF, and open the source file in vim.




## Music Video Downloader
[`mvdl [FILE]`](mvdl)

This script takes in a file of newline-separated music video youtube URLs.
This script is an attempt to automate the process of renaming music video files for Plex such that Plex will match the video with a track.
You may read about this naming process [here](https://support.plex.tv/articles/205568377-adding-local-artist-and-music-videos/)

This script is pretty hardcoded to my personal environment and directory structure.

It will first download each video.
Then, it will attempt to find a matching track file.
If there is a match, it will rename the downloaded music video according to the standard linked above.
If there is no match, it will rename the downloaded music video to a cleaner, more readable version.




## Set Random Wallpaper
[`random-wallpaper`](random-wallpaper)

Selects and random image from the `${XDG_DATA_HOME}/wallpapers` directory and sets it as the user's wallpaper.
