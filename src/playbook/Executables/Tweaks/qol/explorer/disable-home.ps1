---
title: Disable File Explorer Home
description: Removes Home from File Explorer and opens File Explorer to This PC by default
builds: [ '>=22000' ]
actions:
  - !cmd:
    command: '"AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Home\Disable Home (default).cmd" /silent'
    exeDir: true
    wait: true
    runas: currentUserElevated
