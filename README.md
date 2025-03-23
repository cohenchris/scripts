# Scripts

One-stop shop for various homelab scripts.

I've categorized these into a few different categories:

1. Scripts that are run once
     - Operations that you need to perform only once on a fresh install.
     - Think OS install/configuration, systemd services, etc.
2. Ultra-portable scripts that are run arbitrarily
    - Operations that any computer can run regardless of how it is being used
    - Think file management, package updates, display configuration, etc
    - No configuration required from the user - could be placed directly in `/usr/bin` on any system
3. Scripts that are run arbitrarily, but must be configured to your specific environment
    - Operations that may be semi-generic, but require the user to specify exactly how they are using their system
    - Think service management, automations to mount/unmount very specific drives/devices, etc.
4. Scripts that are specialized for backing up various facets of my network
   - This could have gone under #3, but I've written enough of these scripts that they deserve their own category.




# Table of Contents

- [OS Configuration](#OS-Configuration)
- [Generic Bin](#Generic-Bin)
- [System Automation](#System-Automation)
- [Backups](#Backups)




## OS Configuration
[`os/`](os/)

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and services for various systems.
Some may have CATASTROPHIC consequences if used incorrectly, so they should be read and fully understood before use.




## Generic Bin
[`bin/`](bin/)

Dependency-free system scripts which are intended to be added to PATH and run from the command line.

These focus on generic everyday automations.
Think of these as scripts that can be easily moved from system to system with zero effort (assuming the correct packages are installed).
For example, one of the scripts in here is a file extraction wrapper which uses different programs depending on the file extension - this can be dropped on any system that supports bash.




## System Automation
[`system/`](system/)

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.
For example, one of the scripts in here nukes a Docker container stack, cleans things up, and restarts them all - obviously, not all systems will be running a Docker container stack, so this is not immediately portable across different systems.




## Backups
[`backup/`](backup/)

Scripts which backup various devices and services.
They are heavily driven by the .env file, but all generally assume a backup system which includes 1 backup on the local machine and 1 backup on a remote backup server (whether this be another computer on your network or a remote Backblaze storage bucket).
