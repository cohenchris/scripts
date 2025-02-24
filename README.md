# Homelab Scripts

This is a collection of scripts that I have written over the course of my homelab journey.

---

## OS Management
`arch/`

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and system services.
Some ma have CATASTROPHIC consequences if used incorrectly, so they should be read and fully understood before use.


## Backups
`backup/`

Scripts to seamlessly backup different parts of the system.
They are heavily driven by the .env file, but all generally assume a backup system which includes 1 backup on the local machine and 1 backup on a remote backup server (whether this be another computer on your network or a remote Backblaze storage bucket).

## Standalone Helpers
`bin/`

Dependency-free system scripts which are added to the PATH and can be run from the command line.
Rather than dealing with services that the user has explicitly set up, these typically deal with more generic system operations.


## System Automation
`system/`

System scripts with dependencies (must fill out .env file) which help manage and interact with the system.
Rather than dealing with generic system operations, these typically deal with services that the user has explicitly set up.
