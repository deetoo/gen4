# gen4 scripts

Script now does pre-migration checks, and post-migration verification.

- 1.1a added Bomgar, Trend post checks.
- 1.1a added FixNTP post-migration function.
- 1.2a added post-migration report to compare before and after server status.
- 1.3a added vmware tools version check pre/post migration.
- 1.3b fixed broken check for removal of open-vm-tools on Ubuntu, removed CheckNTP, because we fix it in --post

TODO:
 I want to add a version check to make sure the running script is always the latest version.
