@{
    Name        = 'Disable Spell Checking'
    Description = 'Turns off spell checking, autocorrection, text suggestions and double-tap space for the touch keyboard.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableAutocorrection'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableDoubleTapSpace'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnablePredictionSpaceInsertion'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableSpellchecking'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\TabletTip\1.7'; Name = 'EnableTextPrediction'; Type = 'DWord'; Data = 0 }
    )
}
