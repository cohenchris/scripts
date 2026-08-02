# ZFS Data Pool Disaster Recovery

Scripts to recreate a ZFS data pool from nothing (drive died, nothing left) or to replace a single still-working drive in a data pool (drive is failing but still readable).

These scripts are for **data pools only** (`backups`, `files`, `media`) - they intentionally do not touch the system/root ZFS pool. Root pool recovery is handled separately - see [Replace and Resilver a Drive in a ZFS Root Pool](../arch/README.md#Replace-and-Resilver-a-Drive-in-a-ZFS-Root-Pool) and its OPNSense counterpart.

Each script only acts on its own pool and is safe to `source` - sourcing just defines `recreate_from_nothing()` and `replace_drive()` without running anything. Nothing happens until you either execute the script directly with `fresh` or `replace`, or call one of the functions yourself after sourcing.




---

## Testing Status

**These scripts are destructive.** The checkboxes below track which functionality has actually been exercised against a real drive failure/replacement, as opposed to just written and dry-run tested. Treat anything unchecked as unverified - read the script fully and consider a `DEBUG=1` dry run before trusting it on real hardware.

- [ ] `backups.sh fresh` - recreate the `backups` pool from nothing
- [ ] `backups.sh replace` - replace a still-working drive in the `backups` pool
- [ ] `files.sh fresh` - recreate the `files` pool from nothing
- [x] `files.sh replace` - replace a still-working drive in the `files` pool
- [ ] `media.sh fresh` - recreate the `media` pool from nothing
- [ ] `media.sh replace` - replace a still-working drive in the `media` pool

---




# Table of Contents

- [Backups Pool Recovery](#Backups-Pool-Recovery)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Files Pool Recovery](#Files-Pool-Recovery)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Media Pool Recovery](#Media-Pool-Recovery)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [Common Behavior](#Common-Behavior)




## Backups Pool Recovery
[`backups.sh`](backups.sh)

Disaster recovery for the `backups` pool. This pool is the local store for this repo's [Borg](https://www.borgbackup.org) backup repositories (see [`../../backup/`](../../backup/)) - it holds the backups *for* other pools and services, not backups of itself.

Because of that, `fresh` does not restore any data into this pool - there is nothing to restore locally by design. The only other copy of this pool's contents lives on the remote backup server; the script prints a reminder to restore from there manually if needed, rather than doing it automatically.

### Prerequisites
- You are root
- The replacement/target drive is physically attached to the system

### Use
```sh
sudo ./backups.sh fresh     # pool is gone entirely - rebuild it from a blank/replacement drive
sudo ./backups.sh replace   # pool is intact - swap one still-working drive for a new one
```

See [Common Behavior](#Common-Behavior) below for `DEBUG`, device selection, and sourcing.




## Files Pool Recovery
[`files.sh`](files.sh)

Disaster recovery for the `files` pool. `fresh` recreates the pool and then restores its contents from the local Borg repository maintained by [`../../backup/files.sh`](../../backup/files.sh) (with a fallback variable in the script to restore from the remote backup server instead, if the `backups` pool is also gone).

### Prerequisites
- You are root
- The replacement/target drive is physically attached to the system
- The `backups` pool (or the remote backup server, if using the fallback) has the Borg repository this pool restores from

### Use
```sh
sudo ./files.sh fresh     # pool is gone entirely - rebuild it and restore from borg
sudo ./files.sh replace   # pool is intact - swap one still-working drive for a new one
```

See [Common Behavior](#Common-Behavior) below for `DEBUG`, device selection, and sourcing.




## Media Pool Recovery
[`media.sh`](media.sh)

Disaster recovery for the `media` pool, a 2-way mirror. Only a subset of this pool's contents are actually protected by this repo's backup tooling ([`../../backup/music.sh`](../../backup/music.sh)) - the rest (video/photo/podcast-style content that can be re-downloaded or re-ripped) is intentionally not backed up.

Because of that, `fresh` only restores the protected subset after recreating the mirror, and prints a clear list of what was **not** restored and needs to be manually re-acquired.

### Prerequisites
- You are root
- Both replacement/target drives are physically attached to the system (for `fresh`)
- The `backups` pool (or the remote backup server, if using the fallback) has the Borg repository and rsync backup this pool restores from

### Use
```sh
sudo ./media.sh fresh     # both drives gone entirely - rebuild the mirror and restore what's backed up
sudo ./media.sh replace   # pool is intact - swap one still-working drive for a new one
```

See [Common Behavior](#Common-Behavior) below for `DEBUG`, device selection, and sourcing.




## Common Behavior

All three scripts share the same shape:

- **No surprises on source or bare execution.** `source backups.sh` (or `files.sh`/`media.sh`) only defines `recreate_from_nothing()` and `replace_drive()` - nothing runs. Executing the script directly with no argument, an invalid argument, or `-h`/`--help` prints a usage menu instead of doing anything.
- **Interactive device selection.** No device paths are hardcoded. When a device is needed, the script lists real disks on the system (or, for `replace`, the pool's actual current member devices) and asks you to pick one by number - it also flags any disk already in use by an existing pool.
- **New/replacement drives are always wiped first** (`sgdisk --zap-all`) since they can't be assumed blank, then confirmed with a y/N prompt before anything destructive happens.
- **`replace` uses `zpool replace`**, ZFS's live resilver mechanism - it clones the pool's data from the old drive onto the new one while the pool stays online, then the old drive drops out of the pool automatically once the resilver finishes.
- **Borg passphrases are never captured by the script.** Borg is invoked directly wherever a repo needs to be read, so it prompts you on the terminal.
- **`DEBUG=0` (default) runs for real; `DEBUG=1` dry-runs everything** that would modify the system - every command is logged (`[CMD] ...`) either way, but under `DEBUG=1` it's logged and skipped instead of executed:
  ```sh
  DEBUG=1 sudo ./files.sh fresh
  ```
