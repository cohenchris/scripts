# Generic Bin

Dependency-free system scripts which are intended to be added to PATH and run from the command line.

These focus on generic everyday automations.
Think of these as scripts that can be easily moved from system to system with zero effort (assuming the correct packages are installed).
For example, one of the scripts in here is a file extraction wrapper which uses different programs depending on the file extension - this can be dropped on any system that supports bash.




# Table of Contents

- [System Update](#System-Update)
- [WiFi Selection Menu](#WiFi-Selection-Menu)
- [Archive Extraction](#Archive-Extraction)
- [Local E-Mail Sync](#Local-E-Mail-Sync)
- [LF File Manager Wrapper](#LF-File-Manager-Wrapper)
- [LaTeX Shortcuts](#LaTeX-Shortcuts)
- [Music Video Downloader](#Music-Video-Downloader)
- [Set Random Wallpaper](#Set-Random-Wallpaper)
- [Email Lookup](#Email-Lookup)
- [Fuzzel-Based Pinentry](#Fuzzel-Based-Pinentry)
- [Notification Wrapper](#Notification-Wrapper)
- [Screenshot Wrapper](#Screenshot-Wrapper)
- [VPN Selection Menu](#VPN-Selection-Menu)
- [Fuzzel Askpass](#Fuzzel-Askpass)
- [Unicode Character Selection Menu](#Unicode-Character-Selection-Menu)



## System Update
[`update`](update)

This script is meant to run on a system running the `paru` AUR helper package manager (likely Arch Linux).
It also assumes that the user has a docker-compose stack located at `/home/${USER}/server.

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker-compose images
4. Remove all dangling docker container images
5. Mirror EFI boot partitions on mirrored ZFS root pool


## WiFi Selection Menu
[`wifi-menu`](wifi-menu)

Fuzzel-based wifi network selection menu.
Utilizes `nmcli` to scan for available networks and presents them in a friendly list.
The user may then navigate this list using arrow keys or vim directional bindings (h/j/k/l) and select the desired network by pressing Enter.




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




## LF File Manager Wrapper
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




## Email Lookup
[`email-lookup [query]`](email-lookup)

Searches for an email address matching 'query' in your local khard address book.
This is intended to be used for autocompletion by another program, like neomutt.




## Fuzzel-Based Pinentry
[`fuzzel-pinentry`](fuzzel-pinentry)

Incredibly simple pinentry handler using fuzzel.
I often use this to unlock my GPG keyring.

To configure this program as pinentry for unlocking your GPG keyring, the following line should be in your `gpg-agent.conf` file:

```sh
pinentry-program /path/to/fuzzel-pinentry
```




## Notification Wrapper
[`notify [GOOD,NORMAL,CRITICAL] [message1] [message2]`](notify)

Easy-to-use notify-send wrapper for sending desktop notifications.
Used by many of the scripts in this repository.




## Screenshot Wrapper
[`screenshot`](screenshot)

Screenshot utility wrapper script that vastly improves quality-of-life.
Notifies the user about what is happening, status of the screenshot, and where it is saved.
It will also open up a file manager at the location where the screenshot is saved.




## VPN Selection Menu
[`vpn-menu`](vpn-menu)

Fuzzel-based Wireguard VPN server selection menu.
Relies on config files present in `${XDG_CONFIG_HOME}/wireguard` to scan for configured VPN server endpoints and presents them in a selectable list.
The user may then navigate this list using arrow keys or vim directional bindings (h/j/k/l) and select the desired VPN server by pressing Enter.




## Fuzzel Askpass
[`fuzzel-askpass`](fuzzel-askpass)

Fuzzel-based askpass entry program.
Intended to be used with sudo as a graphical password prompt.

```sh
export SUDO_ASKPASS="/path/to/fuzzel-askpass"
sudo -A <command>
```




## Unicode Character Selection Menu
[`unicode-char-menu`](unicode-char-menu)

Fuzzel-based selection menu for unicode characters which would otherwise be impossible to type.
This script relies on files in the `${XDG_DATA_HOME}/chars`.
Each file that resides in this directory should be in one of the following formats:

```sh
<character> <description>
📁 file folder
📂 open file folder
🗂️ card index dividers
```

OR

```sh
<character> <description>; <unicode_hex_identifier>
  address-book; f2b9
  address-card; f2bb
  adjust; f042
```
