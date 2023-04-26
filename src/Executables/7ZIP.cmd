@echo off
setlocal EnableDelayedExpansion

:: Configure 7-Zip options
reg add "HKCU\SOFTWARE\7-Zip\FM\Columns" /v "RootFolder" /t REG_BINARY /d "0100000000000000010000000400000001000000A0000000" /f
reg add "HKCU\SOFTWARE\7-Zip\Options" /v "ContextMenu" /t REG_DWORD /d "1024" /f
reg add "HKCU\SOFTWARE\7-Zip\Options" /v "ElimDupExtract" /t REG_DWORD /d "0" /f
reg add "HKCU\SOFTWARE\Classes\.001" /ve /t REG_SZ /d "7-Zip.001" /f
reg add "HKCU\SOFTWARE\Classes\.7z" /ve /t REG_SZ /d "7-Zip.7z" /f
reg add "HKCU\SOFTWARE\Classes\.apfs" /ve /t REG_SZ /d "7-Zip.apfs" /f
reg add "HKCU\SOFTWARE\Classes\.arj" /ve /t REG_SZ /d "7-Zip.arj" /f
reg add "HKCU\SOFTWARE\Classes\.bz2" /ve /t REG_SZ /d "7-Zip.bz2" /f
reg add "HKCU\SOFTWARE\Classes\.bzip2" /ve /t REG_SZ /d "7-Zip.bzip2" /f
reg add "HKCU\SOFTWARE\Classes\.cab" /ve /t REG_SZ /d "7-Zip.cab" /f
reg add "HKCU\SOFTWARE\Classes\.cpio" /ve /t REG_SZ /d "7-Zip.cpio" /f
reg add "HKCU\SOFTWARE\Classes\.deb" /ve /t REG_SZ /d "7-Zip.deb" /f
reg add "HKCU\SOFTWARE\Classes\.dmg" /ve /t REG_SZ /d "7-Zip.dmg" /f
reg add "HKCU\SOFTWARE\Classes\.esd" /ve /t REG_SZ /d "7-Zip.esd" /f
reg add "HKCU\SOFTWARE\Classes\.fat" /ve /t REG_SZ /d "7-Zip.fat" /f
reg add "HKCU\SOFTWARE\Classes\.gz" /ve /t REG_SZ /d "7-Zip.gz" /f
reg add "HKCU\SOFTWARE\Classes\.gzip" /ve /t REG_SZ /d "7-Zip.gzip" /f
reg add "HKCU\SOFTWARE\Classes\.hfs" /ve /t REG_SZ /d "7-Zip.hfs" /f
reg add "HKCU\SOFTWARE\Classes\.iso" /ve /t REG_SZ /d "7-Zip.iso" /f
reg add "HKCU\SOFTWARE\Classes\.lha" /ve /t REG_SZ /d "7-Zip.lha" /f
reg add "HKCU\SOFTWARE\Classes\.lzh" /ve /t REG_SZ /d "7-Zip.lzh" /f
reg add "HKCU\SOFTWARE\Classes\.lzma" /ve /t REG_SZ /d "7-Zip.lzma" /f
reg add "HKCU\SOFTWARE\Classes\.ntfs" /ve /t REG_SZ /d "7-Zip.ntfs" /f
reg add "HKCU\SOFTWARE\Classes\.rar" /ve /t REG_SZ /d "7-Zip.rar" /f
reg add "HKCU\SOFTWARE\Classes\.rpm" /ve /t REG_SZ /d "7-Zip.rpm" /f
reg add "HKCU\SOFTWARE\Classes\.squashfs" /ve /t REG_SZ /d "7-Zip.squashfs" /f
reg add "HKCU\SOFTWARE\Classes\.swm" /ve /t REG_SZ /d "7-Zip.swm" /f
reg add "HKCU\SOFTWARE\Classes\.tar" /ve /t REG_SZ /d "7-Zip.tar" /f
reg add "HKCU\SOFTWARE\Classes\.taz" /ve /t REG_SZ /d "7-Zip.taz" /f
reg add "HKCU\SOFTWARE\Classes\.tbz" /ve /t REG_SZ /d "7-Zip.tbz" /f
reg add "HKCU\SOFTWARE\Classes\.tbz2" /ve /t REG_SZ /d "7-Zip.tbz2" /f
reg add "HKCU\SOFTWARE\Classes\.tgz" /ve /t REG_SZ /d "7-Zip.tgz" /f
reg add "HKCU\SOFTWARE\Classes\.tpz" /ve /t REG_SZ /d "7-Zip.tpz" /f
reg add "HKCU\SOFTWARE\Classes\.txz" /ve /t REG_SZ /d "7-Zip.txz" /f
reg add "HKCU\SOFTWARE\Classes\.vhd" /ve /t REG_SZ /d "7-Zip.vhd" /f
reg add "HKCU\SOFTWARE\Classes\.vhdx" /ve /t REG_SZ /d "7-Zip.vhdx" /f
reg add "HKCU\SOFTWARE\Classes\.wim" /ve /t REG_SZ /d "7-Zip.wim" /f
reg add "HKCU\SOFTWARE\Classes\.xar" /ve /t REG_SZ /d "7-Zip.xar" /f
reg add "HKCU\SOFTWARE\Classes\.xz" /ve /t REG_SZ /d "7-Zip.xz" /f
reg add "HKCU\SOFTWARE\Classes\.z" /ve /t REG_SZ /d "7-Zip.z" /f
reg add "HKCU\SOFTWARE\Classes\.zip" /ve /t REG_SZ /d "7-Zip.zip" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.001" /ve /t REG_SZ /d "001 Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.001\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,9" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.001\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.7z" /ve /t REG_SZ /d "7z Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.7z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,0" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.7z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.apfs" /ve /t REG_SZ /d "apfs Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.apfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,25" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.apfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.arj" /ve /t REG_SZ /d "arj Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.arj\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,4" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.arj\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bz2" /ve /t REG_SZ /d "bz2 Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bzip2" /ve /t REG_SZ /d "bzip2 Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bzip2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.bzip2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cab" /ve /t REG_SZ /d "cab Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cab\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,7" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cab\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cpio" /ve /t REG_SZ /d "cpio Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cpio\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,12" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.cpio\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.deb" /ve /t REG_SZ /d "deb Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.deb\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,11" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.deb\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.dmg" /ve /t REG_SZ /d "dmg Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.dmg\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,17" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.dmg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.esd" /ve /t REG_SZ /d "esd Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.esd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.esd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.fat" /ve /t REG_SZ /d "fat Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.fat\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,21" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.fat\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gz" /ve /t REG_SZ /d "gz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gzip" /ve /t REG_SZ /d "gzip Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gzip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.gzip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.hfs" /ve /t REG_SZ /d "hfs Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.hfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,18" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.hfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.iso" /ve /t REG_SZ /d "iso Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.iso\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,8" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.iso\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lha" /ve /t REG_SZ /d "lha Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lha\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lha\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzh" /ve /t REG_SZ /d "lzh Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzh\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzh\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzma" /ve /t REG_SZ /d "lzma Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzma\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,16" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.lzma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.ntfs" /ve /t REG_SZ /d "ntfs Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.ntfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,22" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.ntfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rar" /ve /t REG_SZ /d "rar Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,3" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rpm" /ve /t REG_SZ /d "rpm Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rpm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,10" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.rpm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.squashfs" /ve /t REG_SZ /d "squashfs Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.squashfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,24" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.squashfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.swm" /ve /t REG_SZ /d "swm Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.swm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.swm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tar" /ve /t REG_SZ /d "tar Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,13" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.taz" /ve /t REG_SZ /d "taz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.taz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.taz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz" /ve /t REG_SZ /d "tbz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz2" /ve /t REG_SZ /d "tbz2 Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tbz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tgz" /ve /t REG_SZ /d "tgz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tgz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tgz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tpz" /ve /t REG_SZ /d "tpz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tpz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.tpz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.txz" /ve /t REG_SZ /d "txz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.txz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.txz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhd" /ve /t REG_SZ /d "vhd Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhdx" /ve /t REG_SZ /d "vhdx Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhdx\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.vhdx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.wim" /ve /t REG_SZ /d "wim Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.wim\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.wim\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xar" /ve /t REG_SZ /d "xar Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,19" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xz" /ve /t REG_SZ /d "xz Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.xz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.z" /ve /t REG_SZ /d "z Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.zip" /ve /t REG_SZ /d "zip Archive" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.zip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,1" /f
reg add "HKCU\SOFTWARE\Classes\7-Zip.zip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\.001" /ve /t REG_SZ /d "7-Zip.001" /f
reg add "HKLM\SOFTWARE\Classes\.7z" /ve /t REG_SZ /d "7-Zip.7z" /f
reg add "HKLM\SOFTWARE\Classes\.apfs" /ve /t REG_SZ /d "7-Zip.apfs" /f
reg add "HKLM\SOFTWARE\Classes\.arj" /ve /t REG_SZ /d "7-Zip.arj" /f
reg add "HKLM\SOFTWARE\Classes\.bz2" /ve /t REG_SZ /d "7-Zip.bz2" /f
reg add "HKLM\SOFTWARE\Classes\.bzip2" /ve /t REG_SZ /d "7-Zip.bzip2" /f
reg add "HKLM\SOFTWARE\Classes\.cab" /ve /t REG_SZ /d "7-Zip.cab" /f
reg add "HKLM\SOFTWARE\Classes\.cpio" /ve /t REG_SZ /d "7-Zip.cpio" /f
reg add "HKLM\SOFTWARE\Classes\.deb" /ve /t REG_SZ /d "7-Zip.deb" /f
reg add "HKLM\SOFTWARE\Classes\.dmg" /ve /t REG_SZ /d "7-Zip.dmg" /f
reg add "HKLM\SOFTWARE\Classes\.esd" /ve /t REG_SZ /d "7-Zip.esd" /f
reg add "HKLM\SOFTWARE\Classes\.fat" /ve /t REG_SZ /d "7-Zip.fat" /f
reg add "HKLM\SOFTWARE\Classes\.gz" /ve /t REG_SZ /d "7-Zip.gz" /f
reg add "HKLM\SOFTWARE\Classes\.gzip" /ve /t REG_SZ /d "7-Zip.gzip" /f
reg add "HKLM\SOFTWARE\Classes\.hfs" /ve /t REG_SZ /d "7-Zip.hfs" /f
reg add "HKLM\SOFTWARE\Classes\.iso" /ve /t REG_SZ /d "7-Zip.iso" /f
reg add "HKLM\SOFTWARE\Classes\.lha" /ve /t REG_SZ /d "7-Zip.lha" /f
reg add "HKLM\SOFTWARE\Classes\.lzh" /ve /t REG_SZ /d "7-Zip.lzh" /f
reg add "HKLM\SOFTWARE\Classes\.lzma" /ve /t REG_SZ /d "7-Zip.lzma" /f
reg add "HKLM\SOFTWARE\Classes\.ntfs" /ve /t REG_SZ /d "7-Zip.ntfs" /f
reg add "HKLM\SOFTWARE\Classes\.rar" /ve /t REG_SZ /d "7-Zip.rar" /f
reg add "HKLM\SOFTWARE\Classes\.rpm" /ve /t REG_SZ /d "7-Zip.rpm" /f
reg add "HKLM\SOFTWARE\Classes\.squashfs" /ve /t REG_SZ /d "7-Zip.squashfs" /f
reg add "HKLM\SOFTWARE\Classes\.swm" /ve /t REG_SZ /d "7-Zip.swm" /f
reg add "HKLM\SOFTWARE\Classes\.tar" /ve /t REG_SZ /d "7-Zip.tar" /f
reg add "HKLM\SOFTWARE\Classes\.taz" /ve /t REG_SZ /d "7-Zip.taz" /f
reg add "HKLM\SOFTWARE\Classes\.tbz" /ve /t REG_SZ /d "7-Zip.tbz" /f
reg add "HKLM\SOFTWARE\Classes\.tbz2" /ve /t REG_SZ /d "7-Zip.tbz2" /f
reg add "HKLM\SOFTWARE\Classes\.tgz" /ve /t REG_SZ /d "7-Zip.tgz" /f
reg add "HKLM\SOFTWARE\Classes\.tpz" /ve /t REG_SZ /d "7-Zip.tpz" /f
reg add "HKLM\SOFTWARE\Classes\.txz" /ve /t REG_SZ /d "7-Zip.txz" /f
reg add "HKLM\SOFTWARE\Classes\.vhd" /ve /t REG_SZ /d "7-Zip.vhd" /f
reg add "HKLM\SOFTWARE\Classes\.vhdx" /ve /t REG_SZ /d "7-Zip.vhdx" /f
reg add "HKLM\SOFTWARE\Classes\.wim" /ve /t REG_SZ /d "7-Zip.wim" /f
reg add "HKLM\SOFTWARE\Classes\.xar" /ve /t REG_SZ /d "7-Zip.xar" /f
reg add "HKLM\SOFTWARE\Classes\.xz" /ve /t REG_SZ /d "7-Zip.xz" /f
reg add "HKLM\SOFTWARE\Classes\.z" /ve /t REG_SZ /d "7-Zip.z" /f
reg add "HKLM\SOFTWARE\Classes\.zip" /ve /t REG_SZ /d "7-Zip.zip" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.001" /ve /t REG_SZ /d "001 Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.001\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,9" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.001\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.7z" /ve /t REG_SZ /d "7z Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.7z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,0" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.7z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.apfs" /ve /t REG_SZ /d "apfs Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.apfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,25" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.apfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.arj" /ve /t REG_SZ /d "arj Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.arj\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,4" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.arj\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bz2" /ve /t REG_SZ /d "bz2 Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bzip2" /ve /t REG_SZ /d "bzip2 Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bzip2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.bzip2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cab" /ve /t REG_SZ /d "cab Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cab\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,7" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cab\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cpio" /ve /t REG_SZ /d "cpio Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cpio\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,12" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.cpio\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.deb" /ve /t REG_SZ /d "deb Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.deb\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,11" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.deb\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.dmg" /ve /t REG_SZ /d "dmg Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.dmg\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,17" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.dmg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.esd" /ve /t REG_SZ /d "esd Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.esd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.esd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.fat" /ve /t REG_SZ /d "fat Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.fat\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,21" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.fat\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gz" /ve /t REG_SZ /d "gz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gzip" /ve /t REG_SZ /d "gzip Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gzip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.gzip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.hfs" /ve /t REG_SZ /d "hfs Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.hfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,18" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.hfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.iso" /ve /t REG_SZ /d "iso Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.iso\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,8" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.iso\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lha" /ve /t REG_SZ /d "lha Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lha\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lha\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzh" /ve /t REG_SZ /d "lzh Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzh\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzh\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzma" /ve /t REG_SZ /d "lzma Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzma\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,16" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.lzma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.ntfs" /ve /t REG_SZ /d "ntfs Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.ntfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,22" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.ntfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rar" /ve /t REG_SZ /d "rar Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,3" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rpm" /ve /t REG_SZ /d "rpm Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rpm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,10" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.rpm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.squashfs" /ve /t REG_SZ /d "squashfs Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.squashfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,24" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.squashfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.swm" /ve /t REG_SZ /d "swm Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.swm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.swm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tar" /ve /t REG_SZ /d "tar Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,13" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.taz" /ve /t REG_SZ /d "taz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.taz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.taz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz" /ve /t REG_SZ /d "tbz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz2" /ve /t REG_SZ /d "tbz2 Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tbz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tgz" /ve /t REG_SZ /d "tgz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tgz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tgz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tpz" /ve /t REG_SZ /d "tpz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tpz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.tpz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.txz" /ve /t REG_SZ /d "txz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.txz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.txz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhd" /ve /t REG_SZ /d "vhd Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhdx" /ve /t REG_SZ /d "vhdx Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhdx\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.vhdx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.wim" /ve /t REG_SZ /d "wim Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.wim\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.wim\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xar" /ve /t REG_SZ /d "xar Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,19" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xz" /ve /t REG_SZ /d "xz Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.xz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.z" /ve /t REG_SZ /d "z Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.zip" /ve /t REG_SZ /d "zip Archive" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.zip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,1" /f
reg add "HKLM\SOFTWARE\Classes\7-Zip.zip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f

exit /b 0