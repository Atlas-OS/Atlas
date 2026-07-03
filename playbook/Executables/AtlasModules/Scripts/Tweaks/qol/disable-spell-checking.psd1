@{
    Name        = 'Disable Spell Checking'
    Description = 'Disables spell checking for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableAutocorrection'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableDoubleTapSpace'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnablePredictionSpaceInsertion'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableSpellchecking'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableTextPrediction'; Type = 'DWord'; Data = 0 }
    )
}
