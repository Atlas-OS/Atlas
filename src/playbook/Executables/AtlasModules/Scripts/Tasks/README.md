# Atlas Task Scripts

YAML task entries invoke these scripts with this Windows PowerShell 5.1-safe form:

    & (Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasModules\Scripts\Tasks\<script>.ps1')

The call operator receives the string returned by Join-Path as the command path. This avoids passing a command token that contains literal quote characters.
