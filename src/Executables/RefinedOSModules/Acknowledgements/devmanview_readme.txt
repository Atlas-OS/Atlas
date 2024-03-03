


DevManView v1.77
Copyright (c) 2009 - 2022 Nir Sofer
Web site: https://www.nirsoft.net



Description
===========

DevManView is an alternative to the standard Device Manager of Windows,
which displays all devices and their properties in flat table, instead of
tree viewer. In addition to displaying the devices of your local
computer, DevManView also allows you view the devices list of another
computer on your network, as long as you have administrator access rights
to this computer.
DevManView can also load the devices list from external instance of
Windows and disable unwanted devices. This feature can be useful if you
have Windows operating system with booting problems, and you want to
disable the problematic device.



System Requirements
===================

DevManView works on any version of Windows, starting from Windows 2000
and up to Windows 11. For x64 version of Windows, you should download the
x64 version of DevManView, because the 32-bit version of DevManView
cannot disable/enable devices on x64 operating system.



Versions History
================


* Version 1.77:
  o Fixed bug: <br> tag was added to the XML file if the device name
    contained new line character.

* Version 1.76:
  o Added new quick filter option: Find a string begins with...

* Version 1.75:
  o Added option to change the sorting column from the menu (View ->
    Sort By). Like the column header click sorting, if you click again
    the same sorting menu item, it'll switch between ascending and
    descending order. Also, if you hold down the shift key while choosing
    the sort menu item, you'll get a secondary sorting.

* Version 1.72:
  o Fixed bug with sending the devices information to stdout by
    specifying an empty filename (e.g: DevManView.exe /scomma "" | more )

* Version 1.71:
  o Added 'Copy Clicked Cell' option to the right-click context menu,
    which copies to the clipboard the text of cell that you right-clicked
    with the mouse.

* Version 1.70:
  o Added new columns: Install Time, First Install Time, Connect
    Time, Disconnect Time.
  o 'Install Time' and 'First Install Time' fields are available
    starting from Windows 7.
  o 'Connect Time' and 'Disconnect Time' fields are available only on
    Windows 8 and Windows 10.
  o These new properties are taken from the
    'Properties\{83da6326-97a6-4088-9453-a1923f573b29}' Registry subkey
    of every device.

* Version 1.67:
  o Added the 'Uninstall Selected Devices' option to the context menu.

* Version 1.66:
  o Added 'Class Guid' column.

* Version 1.65:
  o Added option to create a shortcut on your desktop to enable,
    disable, or disable+enable the selected device (File -> Create
    Desktop Shortcut)
  o Added 'Automatically start the Remote Registry service' option.
    When this option is turned on, DevManView temporarily starts the
    Remote Regsitry service on the remote machine in order to get the
    devices information from the Registry and then stops or disables (if
    it was originally disabled) the service when it finishes.

* Version 1.60:
  o Added new option: 'Open Device Properties Window' (F2).
  o Added option to create a shortcut to the device properties window
    on your desktop ('Create Device Properties Shortcut On Desktop').

* Version 1.56:
  o Added /cfg command-line option to start DevManView with the
    specified config file.
  o When disabling/enabling devices from command-line, DevManView now
    returns the error code (instead of 0 in previous versions).

* Version 1.55:
  o You can now change the number of milliseconds to wait between
    disable and enable actions when using the 'Disable+Enable Selected
    Devices' option (or /disable_enable command-line option).
    In order to change it - edit the config file (DevManView.cfg) and
    change the 'DisableEnableWaitTime' value (The default is 100
    milliseconds).
  o You can now resize the properties window, and the last
    size/position of this window is saved in the .cfg file.

* Version 1.51:
  o Added 'Select All' and 'Deselect All' to the 'Column Settings'
    window.

* Version 1.50:
  o Added 'Quick Filter' feature (View -> Use Quick Filter or
    Ctrl+Q). When it's turned on, you can type a string in the text-box
    added under the toolbar and DevManView will instantly filter the
    devices list, showing only lines that contain the string you typed.

* Version 1.48:
  o When you connect a remote computer or external Registry file,
    DevManView now displays the computer or directory information in the
    window title.

* Version 1.47:
  o DevManView now displays an error message when it fails to
    disable/enable a device.

* Version 1.46:
  o Fixed the problem with 'Put Icon On Tray' option.

* Version 1.45:
  o Added 'Show Only Devices With Location String' option.
  o Added 'Auto Size Columns On Load' option.

* Version 1.43:
  o Added 'Container ID' column.

* Version 1.42:
  o Added secondary sorting support: You can now get a secondary
    sorting, by holding down the shift key while clicking the column
    header. Be aware that you only have to hold down the shift key when
    clicking the second/third/fourth column. To sort the first column you
    should not hold down the Shift key.
  o Fixed to display date/time values according to daylight saving
    time settings.

* Version 1.41:
  o Added 'Clear Recent Files List' for the 'Recent Disabled Devices
    Profile' option.

* Version 1.40:
  o Added /use_wildcard command-line option. You can use it with
    /disable, /enable, /disable_enable , and /uninstall commmand-line
    options to specify wildcard instead of full name, for example:
    DevManView.exe /disable "USBSTOR\CdRom&???_*" /use_wildcard
    Use it very carefully !!

* Version 1.35:
  o Added 'Recent Disabled Devices Profile' submenu, which allows you
    to easily load the recent 10 profiles you saved.

* Version 1.30:
  o Added 'Save Disabled Devices Profile' and 'Load Disabled Devices
    Profile' options. You can now save the list of all devices that are
    currently disabled into a simple config file. Later, when you want to
    load the same disabled devices configuration, you can load the file
    using the 'Load Disabled Devices Profile' option, and then DevManView
    will disable all devices found in the file and enable all other
    devices that are not stored in the file.
  o Added /load_disabled_profile and /save_disabled_profile
    command-line options.
  o Added 'Auto Size Columns+Headers' option, which allows you to
    automatically resize the columns according to the row values and
    column headers.
  o Fixed issue: Dialog-boxes opened in the wrong monitor, on
    multi-monitors system.

* Version 1.27:
  o Changed the Registry key that is used to get the value of 'Device
    Registry Time 1', under Windows Vista/7/2008. In previous versions,
    this field usually displayed the same value for all devices under
    Windows Vista/7/2008.

* Version 1.26:
  o Added 'Start As Hidden' option. When this option and 'Put Icon On
    Tray' option are turned on, the main window of DevManView will be
    invisible on start.

* Version 1.25:
  o Added 'Put Icon On Tray' option.

* Version 1.23:
  o Added a second Device Registry Time value, which usually displays
    the installation time of the device.

* Version 1.22:
  o Added 'Mark Odd/Even Rows' option, under the View menu. When it's
    turned on, the odd and even rows are displayed in different color, to
    make it easier to read a single line.

* Version 1.21:
  o Added 'Mark Connected Devices' option. When it's turned on,
    connected devices are marked with green background color.

* Version 1.20:
  o Added 'Open .INF File' option (The .inf file is opened in Notepad)
  o Added 'Google Search - Device Name' for searching the device name
    in Google.
  o Added 'Drive Letter' column, which displays the drive letter for
    devices with assigned drive letter.

* Version 1.15:
  o Added command-line options to disable, enable, and uninstall a
    device (Use them very carefully !!) - /enable , /disable ,
    /disable_enable , and /uninstall

* Version 1.12:
  o You can now send the devices information to stdout by specifying
    an empty filename ("") in the save command-line options. (For
    example: DevManView.exe /stext "" > c:\temp\devices.txt)

* Version 1.11:
  o Added 'Add Header Line To CSV/Tab-Delimited File' option. When
    this option is turned on, the column names are added as the first
    line when you export to csv or tab-delimited file.

* Version 1.10:
  o Added 'Disable+Enable Selected Devices' option (Disable and then
    enable again).

* Version 1.07:
  o Fixed issue: removed the wrong encoding from the xml string,
    which caused problems to some xml viewers. Also, removed invalid dot
    character from xml name of '.inf section'.
  o Fixed focus issue after save.

* Version 1.06:
  o Fixed bug: When saving the devices list from command-line,
    DevManView always saved all devices, without considering the
    show/hide settings, like /ShowLegacyDrivers parameter.

* Version 1.05:
  o Improved the 'Connected' column.
  o Added 'Show Only Connected Devices' option, which allows you to
    filter obsolete devices that are not currently connected.

* Version 1.00 - First release.



Using DevManView
================

DevManView doesn't require any installation process or additional dll
files. In order to start using it, simply run the executable file -
DevManView.exe
After running DevManView, the main window displays the list of all
devices found in your system. By default, non-plug and play drivers
(LegacyDriver) are not displayed, but you can add them by selecting the
'Show Non-Plug And Play Drivers' in the Options menu.
You can now select one or more than devices from the list, and then save
their details into text/html/xml/csv file (Ctrl+S) or copy them to the
clipboard (Ctrl+C) and then paste the data to Excel or other spreadsheet
application.
DevManView also allows you to disable, enable, and uninstall the selected
devices. However, you must be very careful when using the
disable/uninstall options, because disabling or uninstalling an essential
device might cause troubles to your operating system.



Connecting a remote computer on your network
============================================

DevManView allows you to connect another computer on your LAN, and view
the devices list in the remote computer. In order to successfully connect
the remote computer, you must have full administrator access to this
computer, and you may need to make a few configuration changes in the
remote computer in order to make it work. For more information, read this
Blog post: How to connect a remote Windows 7/Vista/XP computer with
NirSoft utilities.

After you get full admin rights to the remote computer, you can go to
'Advanced Options' window (F9), choose 'Remote Computer', and type the
computer name (something like \\MyComp or \\192.168.10.20).
When the remote computer is Windows 2000/XP/2003, you can also
disable/enable/uninstall a device in the remote computer. However, this
feature doesn't work on Windows 7/Vista, probably due to security changes
made in these operating systems.



Using DevManView on external instance of Windows
================================================

DevManView allows you to view the devices list stored in the Registry of
another instance of Windows operating system. In order to use this
feature, simply go to Advanced Options (F9), choose 'External Windows
Directory', and then type or choose the right Windows directory.
When you use this feature, you are also allowed to disable/enable the
selected devices. If you use this feature, DevManView write the
disabled/enabled information into the SYSTEM Registry file of the
selected Windows OS, so in the next time that this Windows is loaded, the
device will be disabled/enabled according to what you set with DevManView.
However, it's recommended to use this feature only on emergency cases
(For example, when a system cannot boot properly), and you should also
backup the SYSTEM registry file before making any change on external OS.



Using Another ControlSet
========================

By default, DevManView loads the devices from the default ControlSet,
which is the default ControlSet that is loaded by Windows. However, in
the 'Advanced Options' window, you can choose to view the devices of
'Last Known Good' ControlSet or any other ControlSet by its number. When
you use non-default ControlSet, disabling/enabling a device save the
changes in the Registry, so they'll take effect in the next time that
Windows is loaded with the selected ControlSet.



Command-Line Options
====================



/stext <Filename>
Save the list of devices into a regular text file.

/stab <Filename>
Save the list of devices into a tab-delimited text file.

/scomma <Filename>
Save the list of devices into a comma-delimited text file (csv).

/stabular <Filename>
Save the list of devices into a tabular text file.

/shtml <Filename>
Save the list of devices into HTML file (Horizontal).

/sverhtml <Filename>
Save the list of devices into HTML file (Vertical).

/sxml <Filename>
Save the list of devices into XML file.

/sort <column>
This command-line option can be used with other save options for sorting
by the desired column. If you don't specify this option, the list is
sorted according to the last sort that you made from the user interface.
The <column> parameter can specify the column index (0 for the first
column, 1 for the second column, and so on) or the name of the column,
like "Device Name" and "Location". You can specify the '~' prefix
character (e.g: "~Device Name") if you want to sort in descending order.
You can put multiple /sort in the command-line if you want to sort by
multiple columns.

Examples:
DevManView.exe /shtml "f:\temp\devices.html" /sort 2 /sort ~1
DevManView.exe /shtml "f:\temp\devices.html" /sort "Service" /sort
"Device Name"

/nosort
When you specify this command-line option, the list will be saved without
any sorting.

/LoadFrom <value>
Specifies the 'Load From' value. 1 = Local Computer, 2 = Remote Computer,
3 = External Path.

/ComputerName <name>
Specifies the remote computer name to load the devices information
(Should be used with /LoadFrom 2)

/WinDir <path>
Specifies the Windows directory path of external instance of Windows.
(Should be used with /LoadFrom 3)

/ControlSet <value>
Specifies the ControlSet number. 0 = Default, 4096 = Last Known Good, All
Others = ControlSet Number.

/ShowLegacyDrivers <0 | 1>
Specifies whether to show legacy drivers. 0 = No, 1 = Yes.

/ShowOnlyConnected <0 | 1>
Specifies whether to show only connected devices. 0 = No, 1 = Yes.

/cfg <Filename>
Start DevManView with the specified configuration file. For example:
DevManView.exe /cfg "c:\config\dmv.cfg"
DevManView.exe /cfg "%AppData%\DevManView.cfg"



Enable/disable/uninstall a device from command-line
===================================================

You can use the following command-line options to
enable/disable/uninstall a device from command-line. You can specify the
device by its exact name, as appeared in the 'Device Name' column, for
example: DevManView.exe /disable "WD 2500BMV External USB Device"
You can also specify the value displayed in the Device Instance ID
column, for example: DevManView.exe /enable
"USBSTOR\Disk&Ven_WD&Prod_2500BMV_External&Rev_1.05\584953930578345789&0"

Use these command-line options very carefully, because
disabling/uninstalling the wrong device may cause severe system problems.



/disable <Device Name>
Disable the specified device.

/enable <Device Name>
Enable the specified device.

/disable_enable <Device Name>
Disable and then enable again the specified device.

/uninstall <Device Name>
Uninstall the specified device.

/use_wildcard
You can use it with /disable, /enable, /disable_enable , and /uninstall
commmand-line options to specify wildcard instead of full name, for
example:
DevManView.exe /disable "USBSTOR\CdRom&???_*" /use_wildcard

You must specify at least 5 characters in the device name wildcard,
otherwise it'll not work.

/save_disabled_profile <Config Filename>
Save all devices that are currently disabled into a simple config file.

/load_disabled_profile <Config Filename>
Load the config file that you previously saved with
/save_disabled_profile option, disable all devices found in this file,
and enable all other devices that are not stored in this file.



Translating DevManView to other languages
=========================================

In order to translate DevManView to other language, follow the
instructions below:
1. Run DevManView with /savelangfile parameter:
   DevManView.exe /savelangfile
   A file named DevManView_lng.ini will be created in the folder of
   DevManView utility.
2. Open the created language file in Notepad or in any other text
   editor.
3. Translate all string entries to the desired language. Optionally,
   you can also add your name and/or a link to your Web site.
   (TranslatorName and TranslatorURL values) If you add this information,
   it'll be used in the 'About' window.
4. After you finish the translation, Run DevManView, and all
   translated strings will be loaded from the language file.
   If you want to run DevManView without the translation, simply rename
   the language file, or move it to another folder.



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
