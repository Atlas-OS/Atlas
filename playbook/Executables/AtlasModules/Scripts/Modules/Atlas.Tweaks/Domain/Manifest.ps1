# Atlas.Tweaks domain: tweak manifest loading.
#
# The manifest (Scripts\Tweaks\tweaks.manifest.psd1) defines category order, the
# tweak files inside each category, standalone routes and deliberately disabled
# definitions. ParentModes records the fresh/upgrade modes allowed by the AME shim
# which invokes each PowerShell route; the validator composes that outer gate with
# each definition's OnUpgrade gate so an enabled-but-unreachable tweak cannot ship.

$script:AtlasTweakManifestKeys = @('Categories', 'Standalone', 'Disabled')
$script:AtlasTweakCategoryKeys = @('Name', 'ParentModes', 'Tweaks')
$script:AtlasTweakStandaloneKeys = @('Slug', 'ParentModes')
$script:AtlasTweakDisabledKeys = @('Slug', 'Reason')
$script:AtlasTweakParentModes = @('Fresh', 'Upgrade')

function Get-AtlasTweakManifest {
    <#
    .SYNOPSIS
        Loads the tweak manifest. Use Test-AtlasTweakManifest for full shape and
        execution-graph validation.
    #>
    param(
        [string]$Path
    )

    if (-not $Path) {
        $Path = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Tweaks\tweaks.manifest.psd1'
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak manifest not found: '$Path'."
    }

    $manifest = Import-AtlasDataFile -LiteralPath $Path
    if (-not $manifest.ContainsKey('Categories')) {
        throw "Tweak manifest '$Path' has no 'Categories' key."
    }

    return $manifest
}

function Test-AtlasTweakManifest {
    <#
    .SYNOPSIS
        Validates the tweak manifest and its complete definition/execution graph.
    .DESCRIPTION
        Returns one problem record (Path + Problem) per issue. Validation covers the
        exact manifest shape and value types, duplicate categories and slugs, missing
        referenced files, complete classification of every definition, and effective
        fresh/upgrade reachability after composing ParentModes with OnUpgrade.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string]$TweaksRoot
    )

    $problems = New-Object System.Collections.Generic.List[object]

    function Add-ManifestProblem {
        param([string]$Problem)
        $problems.Add([pscustomobject]@{ Path = $Path; Problem = $Problem })
    }

    function Test-ExactKeys {
        param(
            [hashtable]$Table,
            [string[]]$Expected,
            [string]$Label
        )

        foreach ($key in @($Table.Keys)) {
            if ($key -notin $Expected) {
                Add-ManifestProblem -Problem "$Label has unknown key '$key'."
            }
        }
        foreach ($key in $Expected) {
            if (-not $Table.ContainsKey($key)) {
                Add-ManifestProblem -Problem "$Label is missing required key '$key'."
            }
        }
    }

    function Test-ManifestArray {
        param(
            [object]$Value,
            [string]$Label
        )

        if (-not ($Value -is [array])) {
            Add-ManifestProblem -Problem "$Label must be an array."
            return $false
        }
        return $true
    }

    function Test-Slug {
        param(
            [object]$Value,
            [string]$Label,
            [bool]$RequireCategory
        )

        if (-not ($Value -is [string]) -or [string]::IsNullOrWhiteSpace([string]$Value)) {
            Add-ManifestProblem -Problem "$Label must be a non-empty string."
            return $false
        }

        $slug = [string]$Value
        if ($slug -match '\\' -or $slug -match '^/' -or $slug -match '/$' -or
            $slug -match '(^|/)\.\.?(/|$)' -or $slug -match '\.psd1$' -or
            $slug -notmatch '^[A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*$') {
            Add-ManifestProblem -Problem "$Label '$slug' must be a safe forward-slash path without an extension or traversal."
            return $false
        }
        if ($RequireCategory -and $slug.IndexOf('/') -lt 1) {
            Add-ManifestProblem -Problem "$Label '$slug' must start with its category name."
            return $false
        }
        return $true
    }

    function Get-ParentModes {
        param(
            [hashtable]$Entry,
            [string]$Label
        )

        if (-not $Entry.ContainsKey('ParentModes')) {
            return @()
        }
        if (-not (Test-ManifestArray -Value $Entry['ParentModes'] -Label "$Label ParentModes")) {
            return @()
        }

        $modes = @()
        foreach ($mode in @($Entry['ParentModes'])) {
            if (-not ($mode -is [string]) -or $mode -notin $script:AtlasTweakParentModes) {
                Add-ManifestProblem -Problem "$Label ParentModes entries must be 'Fresh' or 'Upgrade'."
                continue
            }
            if ($mode -in $modes) {
                Add-ManifestProblem -Problem "$Label has duplicate ParentModes entry '$mode'."
                continue
            }
            $modes += $mode
        }

        if ($modes.Count -eq 0) {
            Add-ManifestProblem -Problem "$Label must allow at least one parent mode."
        }
        return $modes
    }

    function Add-Classification {
        param(
            [string]$Slug,
            [string]$Classification,
            [string[]]$ParentModes
        )

        $key = $Slug.ToLowerInvariant()
        if ($classifications.ContainsKey($key)) {
            Add-ManifestProblem -Problem "Tweak slug '$Slug' is classified more than once (as '$($classifications[$key].Classification)' and '$Classification')."
            return
        }
        $classifications[$key] = [pscustomobject]@{
            Slug           = $Slug
            Classification = $Classification
            ParentModes    = @($ParentModes)
        }
    }

    function Test-EnabledDefinition {
        param(
            [string]$Slug,
            [string[]]$ParentModes
        )

        $definitionPath = Join-Path -Path $TweaksRoot -ChildPath (($Slug -replace '/', '\') + '.psd1')
        if (-not (Test-Path -LiteralPath $definitionPath -PathType Leaf)) {
            Add-ManifestProblem -Problem "Enabled tweak '$Slug' does not resolve to a definition file."
            return
        }

        try {
            $definition = Import-AtlasDataFile -LiteralPath $definitionPath
        }
        catch {
            Add-ManifestProblem -Problem "Enabled tweak '$Slug' cannot be loaded: $($_.Exception.Message)"
            return
        }

        $allowedModes = @('Fresh', 'Upgrade')
        if ($definition.ContainsKey('OnUpgrade')) {
            switch ([string]$definition['OnUpgrade']) {
                'Skip' { $allowedModes = @('Fresh') }
                'Only' { $allowedModes = @('Upgrade') }
                'Both' { $allowedModes = @('Fresh', 'Upgrade') }
                default {
                    Add-ManifestProblem -Problem "Enabled tweak '$Slug' has invalid OnUpgrade '$($definition['OnUpgrade'])'."
                    return
                }
            }
        }

        $effectiveModes = @($ParentModes | Where-Object { $_ -in $allowedModes })
        if ($effectiveModes.Count -eq 0) {
            Add-ManifestProblem -Problem "Enabled tweak '$Slug' is unreachable: parent modes [$($ParentModes -join ', ')] do not intersect OnUpgrade '$($definition['OnUpgrade'])'."
        }
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak manifest validation target not found: '$Path'."
    }
    if (-not $TweaksRoot) {
        $TweaksRoot = Split-Path -Path $Path -Parent
    }
    if (-not (Test-Path -LiteralPath $TweaksRoot -PathType Container)) {
        throw "Tweaks root not found: '$TweaksRoot'."
    }
    $TweaksRoot = (Resolve-Path -LiteralPath $TweaksRoot).Path

    try {
        $manifest = Import-AtlasDataFile -LiteralPath $Path
    }
    catch {
        Add-ManifestProblem -Problem "Manifest does not load as a PowerShell data file: $($_.Exception.Message)"
        return $problems.ToArray()
    }

    if (-not ($manifest -is [hashtable])) {
        Add-ManifestProblem -Problem 'Manifest root must be a hashtable.'
        return $problems.ToArray()
    }

    Test-ExactKeys -Table $manifest -Expected $script:AtlasTweakManifestKeys -Label 'Manifest'

    $classifications = @{}
    $categoryNames = @{}

    if ($manifest.ContainsKey('Categories') -and
        (Test-ManifestArray -Value $manifest['Categories'] -Label 'Manifest Categories')) {
        foreach ($category in @($manifest['Categories'])) {
            if (-not ($category -is [hashtable])) {
                Add-ManifestProblem -Problem 'Manifest Categories entries must be hashtables.'
                continue
            }

            Test-ExactKeys -Table $category -Expected $script:AtlasTweakCategoryKeys -Label 'Category entry'
            $name = $null
            if ($category.ContainsKey('Name') -and $category['Name'] -is [string] -and
                -not [string]::IsNullOrWhiteSpace([string]$category['Name']) -and
                [string]$category['Name'] -match '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                $name = [string]$category['Name']
                $nameKey = $name.ToLowerInvariant()
                if ($categoryNames.ContainsKey($nameKey)) {
                    Add-ManifestProblem -Problem "Duplicate category name '$name'."
                }
                else {
                    $categoryNames[$nameKey] = $true
                }
            }
            else {
                Add-ManifestProblem -Problem 'Category Name must be a non-empty kebab-case string.'
            }

            $parentModes = @(Get-ParentModes -Entry $category -Label "Category '$name'")
            if (-not $category.ContainsKey('Tweaks') -or
                -not (Test-ManifestArray -Value $category['Tweaks'] -Label "Category '$name' Tweaks")) {
                continue
            }
            if (@($category['Tweaks']).Count -eq 0) {
                Add-ManifestProblem -Problem "Category '$name' must enable at least one tweak."
            }

            foreach ($relativeSlugValue in @($category['Tweaks'])) {
                if (-not (Test-Slug -Value $relativeSlugValue -Label "Category '$name' tweak slug" -RequireCategory $false)) {
                    continue
                }
                if (-not $name) {
                    continue
                }

                $fullSlug = "$name/$relativeSlugValue"
                Add-Classification -Slug $fullSlug -Classification 'Category' -ParentModes $parentModes
                Test-EnabledDefinition -Slug $fullSlug -ParentModes $parentModes
            }
        }
    }

    if ($manifest.ContainsKey('Standalone') -and
        (Test-ManifestArray -Value $manifest['Standalone'] -Label 'Manifest Standalone')) {
        foreach ($entry in @($manifest['Standalone'])) {
            if (-not ($entry -is [hashtable])) {
                Add-ManifestProblem -Problem 'Manifest Standalone entries must be hashtables.'
                continue
            }

            Test-ExactKeys -Table $entry -Expected $script:AtlasTweakStandaloneKeys -Label 'Standalone entry'
            $parentModes = @(Get-ParentModes -Entry $entry -Label 'Standalone entry')
            if (-not $entry.ContainsKey('Slug') -or
                -not (Test-Slug -Value $entry['Slug'] -Label 'Standalone tweak slug' -RequireCategory $true)) {
                continue
            }

            $slug = [string]$entry['Slug']
            $slugCategory = $slug.Substring(0, $slug.IndexOf('/')).ToLowerInvariant()
            if (-not $categoryNames.ContainsKey($slugCategory)) {
                Add-ManifestProblem -Problem "Standalone tweak '$slug' is not classified under a manifest category."
            }
            Add-Classification -Slug $slug -Classification 'Standalone' -ParentModes $parentModes
            Test-EnabledDefinition -Slug $slug -ParentModes $parentModes
        }
    }

    if ($manifest.ContainsKey('Disabled') -and
        (Test-ManifestArray -Value $manifest['Disabled'] -Label 'Manifest Disabled')) {
        foreach ($entry in @($manifest['Disabled'])) {
            if (-not ($entry -is [hashtable])) {
                Add-ManifestProblem -Problem 'Manifest Disabled entries must be hashtables.'
                continue
            }

            Test-ExactKeys -Table $entry -Expected $script:AtlasTweakDisabledKeys -Label 'Disabled entry'
            if (-not $entry.ContainsKey('Slug') -or
                -not (Test-Slug -Value $entry['Slug'] -Label 'Disabled tweak slug' -RequireCategory $true)) {
                continue
            }

            $slug = [string]$entry['Slug']
            $slugCategory = $slug.Substring(0, $slug.IndexOf('/')).ToLowerInvariant()
            if (-not $categoryNames.ContainsKey($slugCategory)) {
                Add-ManifestProblem -Problem "Disabled tweak '$slug' is not classified under a manifest category."
            }
            if (-not $entry.ContainsKey('Reason') -or -not ($entry['Reason'] -is [string]) -or
                [string]::IsNullOrWhiteSpace([string]$entry['Reason'])) {
                Add-ManifestProblem -Problem "Disabled tweak '$slug' must record a non-empty Reason."
            }
            Add-Classification -Slug $slug -Classification 'Disabled' -ParentModes @()

            $definitionPath = Join-Path -Path $TweaksRoot -ChildPath (($slug -replace '/', '\') + '.psd1')
            if (-not (Test-Path -LiteralPath $definitionPath -PathType Leaf)) {
                Add-ManifestProblem -Problem "Disabled tweak '$slug' does not resolve to a definition file."
            }
        }
    }

    $rootPrefix = $TweaksRoot.TrimEnd('\') + '\'
    foreach ($file in Get-ChildItem -LiteralPath $TweaksRoot -Filter '*.psd1' -Recurse -File) {
        if ($file.Name -eq 'tweaks.manifest.psd1') {
            continue
        }
        $relativePath = $file.FullName.Substring($rootPrefix.Length)
        $slug = ($relativePath -replace '\\', '/' -replace '\.psd1$', '')
        if (-not $classifications.ContainsKey($slug.ToLowerInvariant())) {
            Add-ManifestProblem -Problem "Tweak definition '$slug' is unclassified; add it to Categories, Standalone or Disabled."
        }
    }

    return $problems.ToArray()
}
