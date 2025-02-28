# Scripts

Scripts that I have written over the course of my homelab journey.

---

## Backups
[`backup/`](backup/)

Scripts to seamlessly backup different parts of the system.
They are heavily driven by the .env file, but all generally assume a backup system which includes 1 backup on the local machine and 1 backup on a remote backup server (whether this be another computer on your network or a remote Backblaze storage bucket).




## Standalone Helpers
[`bin/`](bin/)

Dependency-free system scripts which are added to the PATH and can be run from the command line.

These focus on generic everyday automations.
Think of these as scripts that can be easily moved from system to system with zero effort (assuming the correct packages are installed).
For example, one of the scripts in here is a file extraction wrapper which uses different programs depending on the file extension - this can be dropped on any system that supports bash.




## OS Management
[`os/`](os/)

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and services for various systems.
Some may have CATASTROPHIC consequences if used incorrectly, so they should be read and fully understood before use.




## System Automation
[`system/`](system/)

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.
For example, one of the scripts in here nukes a Docker container stack, cleans things up, and restarts them all - obviously, not all systems will be running a Docker container stack, so this is not immediately portable across different systems.
