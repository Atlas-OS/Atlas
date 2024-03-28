---
title: Rebuild Performance Counters
description: Manually rebuilds performance counters to ensure that there is no issues with them
actions:
    # https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
  - !run: {exe: 'lodctr', args: '/r'}
  - !run: {exe: 'lodctr', args: '/r'}
  - !run: {exe: 'winmgmt', args: '/resyncperf'}
