# [NetBackup DB backups browser and restore test](https://github.com/pfzim/netbackup-db-test-restore)

Scripts for automated testing MS SQL database backups

## Installation

- Create DB and tables: `database.sql`
- Fill configs: `inc.config.php` and `inc.config.ps1`
- Schedule script `NetBackupFillDB.ps1` at NetBackup server - it fill DB with info about existing backups.
- Schedule script `NetBackupDBTestRestore.ps1` at test server where you want restore backups.
