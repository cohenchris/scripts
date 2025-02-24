# Standalone Helpers

This is a collection of scripts that I have written which automate certain day-to-day tasks on my machine.
They are completely standalone and require no externally-managed environment variables.

This directory is intended to be appended to the system $PATH.

---

## `update`
1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker container images
4. Remove all unused cached docker container images


## `wifi`
Dmenu-based wifi network selector.
Utilizes `nmcli` to scan for available networks and presents them in a friendly list.
The user may then navigate this list using arrow keys or vim directional bindings (h/j/k/l) and select the desired network by pressing Enter.


## `extract [FILE...]`
There are many different types of compressed files, each of which requires a different extraction program.
This script allows an unlimited number of arguments to be passed.
It will loop through each argument and use the correct extraction program based on the file extension.


## `mailsync`
1. Sync all emails using `mbsync`
2. Index synced emails using `notmuch`
3. Notify the user about any new unread emails
4. Sync contacts using `vdirsyncer`

Synced email may be viewed with a local client such as `neomutt`.


## `rotdir`
Helper script for the `nsxiv` image-viewing program.
When I open an image using this program, this script allows me to press next/previous keys to scroll through all images in the current directory.
This script "rotates" the content of a directory based on the first chosen file.
For example, if I open the 15th image, pressing next will show me the 16th image.

This script was pulled directly from Luke Smith's dotfiles [here](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/rotdir).


## `lfub`
This is a wrapper script for lf that allows it to create image previews with ueberzug.

This script was pulled directly from Luke Smith's dotfiles [here](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/lfub)


## `mytex [compile, create, edit] [FILENAME]`
This script helps automate common LaTeX commands that I use.
The user will pass a filename as an argument.

Behavior differs depending on the subcommand:
`compile`
  - This script will compile the source file into a PDF.
`create`
  - This script will spit out a file (name provided as an argument) which contains a very simple LaTeX template.
`edit`
  - This script will compile that source file into a PDF, display the PDF, and open the source file in vim.


## `batocera [mount, unmount]`
I have an Intel NUC [Batocera](https://batocera.org/) emulation station in my living room.
From their website, "Batocera.linux is an open-source and completely free retro-gaming distribution that can be copied to a USB stick or an SD card with the aim of turning any computer/nano computer into a gaming console during a game or permanently."
It's a pain to manually import games from a USB stick, so this script allows mounting/unmounting of Batocera's `/userdata` directory.

`batocera mount` mounts Batocera's `/userdata` directory to a newly created `./batocera` directory in the current working directory.

`batocera unmount` unmounts and removes the local `./batocera` directory.


## `mvdl [FILE]`
This script takes in a file of newline-separated music video youtube URLs.
This script is an attempt to automate the process of renaming music video files for Plex such that Plex will match the video with a track.
You may read about this naming process [here](https://support.plex.tv/articles/205568377-adding-local-artist-and-music-videos/)

This script is pretty hardcoded to my personal environment and directory structure.

It will first download each video.
Then, it will attempt to find a matching track file.
If there is a match, it will rename the downloaded music video according to the standard linked above.
If there is no match, it will rename the downloaded music video to a cleaner, more readable version.


## `random-wallpaper`
Selects and random image from the `${XDG_DATA_HOME}/wallpapers` directory and sets it as the user's wallpaper.
