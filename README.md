# gen4 scripts

pcheck.sh does the following:
- updates VMware tools to v10.1
- fixes legacy software repos
- saves disk information
- saves IP information
- saves port information
- checks for network connectivity
- checks for NOEXEC on /tmp
- checks for pre-migration scripts execution
- saves this info to /home/fhadmin/migrate.txt
