# Homelab Scripts

This is a collection of helper scripts that I have written over the course of my entire homelab journey.

The scripts are organized as follows:

## `arch/`

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and system services.
Some of these may have CATASTROPHIC effects on your system, so please make sure you fully understand a script before running.

## `backup/`

Scripts to seamlessly backup different parts of the system.
These scripts are heavily driven by the .env file, but they all generally assume a backup system which includes 1 local backup on the local machine, 1 remote backup on a remote backup server (whether this be another computer on your network or a remote Backblaze storage bucket).
These scripts should not have any destructive capabilities, but please read about them before using.

## `bin/`

Dependency-free scripts which are added to the PATH and can be run from the command line.

## `system/`

Scripts with dependencies (must fill out .env file) which help manage and interact with the system.
