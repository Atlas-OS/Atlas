In simple terms, each timer is *usually* set to Core 0, unless set by the developer. When DistributeTimers is enabled, timers can be distributed to any unparked logical processor. 

The effect of this will be highly dependent on your processor and it's core count. On Atlas installations, any logical processor count less than or equal to 6 means DistributeTimers is disabled.
Some may get stutters with it enabled on higher core counts, you will need to test for yourself.

REFERENCES:
Russinovich, M., Solomon, D. and Ionescu, A., 2012. Windows Internals, Part 2. 6th ed. Redmond, Washington: Microsoft Press.
https://docs.microsoft.com/en-us/windows/win32/winmsg/about-timers
