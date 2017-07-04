
NET USE \\192.168.65.253\BackupSqlSrv /u:\backup jofas903j?
NET USE \\192.168.65.253\BackupTOTVS12 /u:\backup jofas903j?
ROBOCOPY "E:\TOTVS12" "\\192.168.65.253\BackupTOTVS12\TOTVS12" /ETA /MIR /MT:10  /Z /R:2 /W:2 /XF *.cdx *.job *.lck *.idx *.int /LOG:E:\TOTVS12\TOTVS12backupRoboCopy.log 
ROBOCOPY "E:\MSSQLSERVER\Backup" "\\192.168.65.253\BackupSqlSrv\MSSQLBACKUP" /ETA /MIR /MT:10  /Z /R:2 /W:2 /LOG:E:\TOTVS12\DBbackupRoboCopy.log 
NET USE \\192.168.65.253\BackupSqlSrv /DELETE
NET USE \\192.168.65.253\BackupSqlSrv /DELETE

