param (
    [string]$Execute
)

switch ($Execute)
{
    'debloat' {
        
    }
    'misc' {
        
    }
    'networking' {
        
    }
    'performance' {
        
    }
    'privacy' {
        
    }
    'qol' {
        
    }
    'scripts' {
        
    }
    'security' {
        
    }
    default {
        Write-Output "Invalid execute option: $Execute"
    }
}
