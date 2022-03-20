


ServiWin v1.71
Copyright (c) 2003 - 2018 Nir Sofer



Description
===========

ServiWin utility displays the list of installed drivers and services on
your system. For some of them, additional useful information is
displayed: file description, version, product name, company that created
the driver file, and more.
In addition, ServiWin allows you to easily stop, start, restart, pause,
and continue service or driver, change the startup type of service or
driver (automatic, manual, disabled, boot or system), save the list of
services and drivers to file, or view HTML report of installed
services/drivers in your default browser.



Versions History
================


* Version 1.71:
  o Added option to export services/drivers list of external drive
    from command-line, for example:
    ServiWin.exe /shtml services "c:\temp\serv.html" K:\Windows

* Version 1.70:
  o Added 'Process ID' column.

* Version 1.66:
  o When there is an error in 'Change Status' or 'Change Startup
    Type' actions, the error message is displayed in the bottom status
    bar, in red color.
  o Added x64 build.

* Version 1.65:
  o Added 'Run As Administrator' option (Ctrl+F11), which allows you
    to easily run ServiWin as administrator on Windows Vista/7/8/2008.
    You should use this option when you want to change the status of
    services.

* Version 1.63:
  o Added 'Auto Size Columns+Headers' option.

* Version 1.62:
  o ServiWin now reads the StartOverride Registry key (Added on
    Windows 8) when using the offline mode.

* Version 1.61:
  o Fixed a crash problem with 'Put Icon On Tray' feature.

* Version 1.60:
  o Added 'Put Icon On Tray' option.

* Version 1.57:
  o In drivers list, ServiWin now displays the filename and version
    information, even if the driver path is not specified in the Registry.

* Version 1.56:
  o Fixed bug: The 'Add Header Line To CSV/Tab-Delimited File' option
    didn't affect the result when saving the services list from
    command-line.
  o Fixed the xml file created from /sxml command-line option.
  o Fixed the flickering while scrolling the services list.

* Version 1.55:
  o Added 'Show Only Non-Windows Services' option, under the Options
    menu. When it's turned on, ServiWin displays only the services that
    are not detected as a part of Windows operating system. The detection
    is made according to the 'Product Name' value.

* Version 1.50:
  o Added /LoadFromList command-line option, which allows you to load
    only the desired services, for example:
    ServiWin.exe /LoadFromList WZCSVC Spooler Schedule LmHosts Browser
    RemoteRegistry

* Version 1.48:
  o Fixed bug: When saving the services/drivers list of a remote
    computer from command-line, ServiWin saved the services/drivers of
    the local machine.
  o Fixed issue: csv/tab-delimited files were corrupted when a
    service description had CR/LF characters.

* Version 1.47:
  o Added 'Add Header Line To CSV/Tab-Delimited File' option. When
    this option is turned on, the column names are added as the first
    line when you export to csv or tab-delimited file.

* Version 1.46:
  o Added 2 command-line options: /start_services to start ServiWin
    with services list and /start_drivers to start ServiWin with drivers
    list.

* Version 1.45:
  o Fixed bug: For some services, ServiWin failed to detect the .exe
    file properly
  o Added 'Command-Line' column, which displays the full service
    command-line, including parameters.
  o Added 'Google Search - Executable Name' and 'Google Search -
    Service Name' options, which allow you to easily search information
    about the service in Google.

* Version 1.40:
  o Added 'Open Item In RegEdit' option.
  o Added 'Show Numbers' option, which allows you to display the
    numeric values for Status, Startup Type, and Error Control.

* Version 1.38:
  o Fixed a bug that appeared in v1.37: When saving from
    command-line, ServiWin ignored the services/devices parameter.

* Version 1.37:
  o Added sorting command-line options.

* Version 1.36:
  o Fixed bug in properties window: The window was too small to
    display all fields.

* Version 1.35:
  o Added new column: Last Write Time
  o Added the option to save as xml file and comma-delimited file.

* Version 1.33:
  o Fixed bug: The main window lost the focus when the user switched
    to another application and then returned back to ServiWin.

* Version 1.32:
  o The configuration is now saved to a file, instead of the Registry.

* Version 1.31:
  o Fixed bug: In offline mode, the services/drivers list was loaded
    from wrong ControlSet.
  o In properties window, the description field is now displayed in
    5-lines text-box.

* Version 1.30:
  o Offline mode - Allows you to view all services/drivers and change
    the startup type in another instance of Windows operating system.
    (/offline command-line option)
  o A tooltip is displayed when a string in a column is longer than
    the column length.

* Version 1.20:
  o Added find dialog-box.
  o Added accelerator keys.
  o Added toolbar buttons for Start, Restart, and Stop actions.
  o Added /remote command-line option
  o New column: Dependencies
  o New column: Error Control
  o New column: Last Error - Displays an error message when
    starting/stopping service is failed.

* Version 1.11: Added support for Windows XP visual styles.
* Version 1.10:
  o Started/Disabled services are marked with different colors.
  o Ability to translate to other languages.
  o The "copy" option nows copies the services/drivers information as
    tab-delimited text, so you can paste it directly to Excel.

* Version 1.00 - First release.



System Requirement
==================

This utility works under Windows 2000, Windows NT, Windows XP, Windows
Server 2003/2008, Windows Vista, Windows 7, Windows 8, and Windows 10.
Windows 98 and Windows ME are not supported. Under Windows Vista/7/8 - If
you want to change the status of services, you must right-click the
ServiWin.exe and choose 'Run As Administrator'. If only want to watch the
services/devices list, you can also run it as non-admin user.



Using ServiWin
==============

This utility is a standalone executable, so it doesn't require any
installation process or additional DLLs. Just run the executable
(serviwin.exe) and start using it.
The main window displays the list of all drivers or services, according
to your selection. You can switch between drivers list and services list
by selecting the desired list from the View menu, or simply use the F7
and F8 keys.
You can select one or more drivers or services from the list, and then
change their status (Stop, Start, Restart, Pause, or Continue) or their
startup type (Automatic, Manual, Disabled, Boot, or System). You can also
save the selected items to text or HTML file (Ctrl + S) or copy this
information to the clipboard.

Warning: Changing the status or the startup type of some drivers or
services may cause to your operating system to work improperly. Do not
disable or stop drivers/services if you are not 100% sure about what you
are doing.



Connecting To Another Computer
==============================

ServiWin allows you to work with drivers/services list of another
computer on your LAN. In order to do that, you must be connected to the
other computer with administrator privileges, as well as admin shares
(\\computer\drive$) should be enabled on that computer.



Offline Mode
============

Starting from version 1.30, ServiWin allows you to connect another
instance of Windows operating system. In this offline mode, you cannot
stop or start a service (because the other operating system is not really
running...), but you can change the "Startup Type" of a service, so the
next time that the other operating system is loaded, the service will be
started or won't be started according to the startup type that you chooe.

In order to use ServiWin in offline mode, run ServiWin with /offline
command-line option, and specify the Windows directory of the operating
system that you want to load. For example:
serviwin.exe /offline e:\windows

Be aware that when using this offline mode, the 'SYSTEM' registry file of
the other operating system is temporarily loaded as a new hive under
HKEY_LOCAL_MACHINE.



Colors In ServiWin
==================

Starting from v1.10, ServiWin marks the services and drivers with
different colors according to the following rules:


Blue
All started services/drivers are painted with this color.
ForeColorStarted
BackColorStarted


Red
All disabled services/drivers are painted with this color.
ForeColorDisabled
BackColorDisabled


Purple
All services/drivers that starts automatically by the operating systems
(with 'Automatic' and 'Boot' Startup types) but they are not currently
running.
ForeAutoNotStarted
BackAutoNotStarted


For advanced users only: If you want to view the services/drivers in
different colors, add the approprite line (according to the above table)
to serviwin.cfg, for example:
ForeColorStarted=10551295
Each color value is DWORD value that represents the color in RGB format.
For example: If you want to mark all started services with yellow
background color, add BackColorStarted value as DWORD containing 10551295
(0xA0FFFF).



Command-Line Options
====================

General syntax:
serviwin [/save type] [drivers | services] [filename] {\\computer} {/sort
[column name]}

The [/save type] may contain one of the following values:


/stext
Saves the list of all drivers/services into a regular text file.

/stab
Saves the list of all drivers/services into a tab-delimited text file.

/scomma
Saves the list of all drivers/services into a comma-delimited text file.

/sxml
Saves the list of all drivers/services into a xml file.

/stabular
Saves the list of all drivers/services into a tabular text file.

/shtml
Saves the list of all drivers/services into horizontal HTML file.

/sverhtml
Saves the list of all drivers/services into vertical HTML file.

The second parameter specifies whether to save the 'services' list or the
'drivers' list.
The [filename] parameter specifies the filename to save the
services/drivers list.
The remote computer parameter, {\\computer} is optional. If you omit this
parameter, the drivers/services list will be loaded from the local
computer.
You can also specify the Windows directory of external drive instead of
computer name in order to load the services/drivers list from external
drive.

The /sort command-line option can be used with other save options for
sorting by the desired column. If you don't specify this option, the list
is sorted according to the last sort that you made from the user
interface. The <column> parameter can specify the column index (0 for the
first column, 1 for the second column, and so on) or the name of the
column, like "Name" and "Display Name". You can specify the '~' prefix
character (e.g: "~Status") if you want to sort in descending order. You
can put multiple /sort in the command-line if you want to sort by
multiple columns.


Examples:

serviwin.exe  /shtml services "c:\temp\serv.html" \\comp1
serviwin.exe  /stext drivers "c:\temp\drv.txt"
serviwin.exe  /shtml services "c:\temp\serv.html" /sort "Display Name"
serviwin.exe  /shtml services "c:\temp\serv.html" K:\Windows


Starting from version 1.20, you can use the /remote parameter in order to
start ServiWin with the specified remote computer (without saving the
drivers/services to file). For example:

serviwin.exe  /remote \\comp10


In order to successfully get full admin access to the remote computer,
read this Blog post: How to connect a remote Windows 7/Vista/XP computer
with NirSoft utilities.

Starting from version 1.30, you can use /offline parameter in order to
connect another instance of Windows operating system. For example:

serviwin.exe  /offline d:\windows


You can also start ServiWin with the services list by using
/start_services parameter or with the drivers list, by using
/start_drivers parameter:

serviwin.exe /start_services
serviwin.exe /start_drivers


Starting from version 1.50, you can instruct ServiWin to load only the
desired services by using the /LoadFromList command-line option. You can
specify the desired services by their name, display name, or the .exe
file. Here's a few examples:

serviwin.exe /LoadFromList WZCSVC Spooler Schedule LmHosts Browser RemoteRegistry
serviwin.exe /LoadFromList svchost.exe
serviwin.exe /LoadFromList "C:\WINDOWS\System32\ups.exe"




Translating to another language
===============================

ServiWin allows you to easily translate all menus, dialog-boxes, and
other strings to other languages.
In order to do that, follow the instructions below:
1. Run ServiWin with /savelangfile parameter:
   serviwin.exe /savelangfile
   A file named serviwin_lng.ini will be created in the folder of
   ServiWin utility.
2. Open the created language file in Notepad or in any other text
   editor.
3. Translate all menus, dialog-boxes, and string entries to the
   desired language.
4. After you finish the translation, Run ServiWin, and all translated
   strings will be loaded from the language file.
   If you want to run ServiWin without the translation, simply rename the
   language file, or move it to another folder.



License
=======

This utility is released as freeware. You are allowed to freely
distribute this utility via floppy disk, CD-ROM, Internet, or in any
other way, as long as you don't charge anything for this. If you
distribute this utility, you must include all files in the distribution
package, without any modification !



Disclaimer
==========

The software is provided "AS IS" without any warranty, either expressed
or implied, including, but not limited to, the implied warranties of
merchantability and fitness for a particular purpose. The author will not
be liable for any special, incidental, consequential or indirect damages
due to loss of data or any other reason.



Feedback
========

If you have any problem, suggestion, comment, or you found a bug in my
utility, you can send a message to nirsofer@yahoo.com