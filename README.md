# Scripts

One-stop shop for all of the scripts that I use for my home network.

I've categorized my these into a few different categories:

1. Scripts that are run once
     - Operations that you need to perform only once on a fresh install.
     - Think OS install/configuration, systemd services, etc.
2. Ultra-portable scripts that are run many times
    - Operations that any computer can run regardless of how it is being used
    - Think file management, package updates, display configuration, etc
    - No configuration required from the user - could be placed directly in `/usr/bin` on any system
3. Scripts that are run many times, but must be configured to your exact use case
    - Operations that may be semi-generic, but require the user to specify exactly how they are using their system
    - Think service management, automations to mount/unmount very specific drives/devices, etc.
4. Scripts that are specialized for backing up different facets of my devices
   - This could have gone under #3, but I've written enough of these scripts that they deserve their own category.


## OS Configuration
[`os/`](os/)

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and services for various systems.
Some may have CATASTROPHIC consequences if used incorrectly, so they should be read and fully understood before use.


## Generic
[`bin/`](bin/)

Dependency-free system scripts which are added to the PATH and can be run from the command line.

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

Scripts to seamlessly backup different parts of the system.
They are heavily driven by the .env file, but all generally assume a backup system which includes 1 backup on the local machine and 1 backup on a remote backup server (whether this be another computer on your network or a remote Backblaze storage bucket).
