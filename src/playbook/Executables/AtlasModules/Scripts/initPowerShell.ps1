$seperator = [IO.Path]::PathSeparator

# Add modules path
$env:PSModulePath += "$seperator" + "$PWD\AtlasModules\Scripts\Modules"

# Update PATH variable
$env:Path = [System.Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::Machine) + `
    $seperator + `
    [System.Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::User) 