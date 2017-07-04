
NET USE \\192.168.65.253\e /u:\totvs1 totvs@2015
ROBOCOPY "C:\TOTVS12" "\\192.168.65.253\e\Backup_SRV_192_168_65_254\TOTVS12" /MIR /MT:10  /Z /R:2 /W:2 /XF *.cdx *.job *.lck *.idx *.int /LOG:C:\TOTVS12\backupRoboCopy.log 

ROBOCOPY "C:\MSSQLBACKUP" "\\192.168.65.253\e\Backup_SRV_192_168_65_254\MSSQLBACKUP" /MIR /MT:10  /Z /R:2 /W:2 /LOG:C:\MSSQLBACKUP\backupRoboCopy.log 

