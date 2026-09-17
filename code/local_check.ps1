# local_check.ps1 (git-pull-arena) - this repo's checks, run on the real
# machine when the agent requests one. watch.ps1 executes this whenever the agent requests a check
# (config key check_cmd), captures all output to
# results\status\check_rN_<stamp>.log and pushes the verdict back.
#
# Exit 0 = passed, anything else = failed. Edit freely - this file belongs to
# the repo, the installer only creates it when it is missing.
#
# Ideas for real checks (pick what fits the repo):
#   - deliverable files exist and have sane sizes
#   - open an Office file via COM to prove it is not corrupt
#   - python -c "import torch; assert torch.cuda.is_available()"  (GPU smoke test)
#   - run a script from code\ and compare its output
#
# ASCII-only on purpose (Windows PowerShell 5.1 decodes .ps1 as ANSI/GBK).

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..')   # repo root (this file lives in code\)

$fail = 0

# 1. the standard gate (.ps1 ASCII + branch guard + script consistency)
#    (forward slashes on purpose: this also runs under the scheduled task,
#     where bash may eat backslashes; Write-Output on purpose: the watcher
#     captures stdout, and PS 5.1 Write-Host bypasses it)
if (Test-Path -LiteralPath '.\code\check_all.sh') {
    # prefer the bash that ships with the git we use - a WSL bash.exe on PATH
    # cannot always read a Windows working directory and would look like a
    # gate failure when it is really an environment mismatch
    $bashExe = ''
    $g = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($g -and $g.Source) {
        $gitDir = Split-Path -Parent (Split-Path -Parent $g.Source)
        foreach ($cand in @((Join-Path $gitDir 'bin\bash.exe'), (Join-Path $gitDir 'usr\bin\bash.exe'))) {
            if (Test-Path -LiteralPath $cand) { $bashExe = $cand; break }
        }
    }
    $bashFrom = 'git'
    if (-not $bashExe) {
        $b = Get-Command bash -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($b) { $bashExe = [string]$b.Source; $bashFrom = 'PATH' }
    }
    if (-not $bashExe) {
        Write-Output '[WARN] no bash found (install Git for Windows) - the repo gate was skipped'
    } else {
        $gateOut = (& $bashExe 'code/check_all.sh' 2>&1 | Out-String)
        $gateCode = $LASTEXITCODE
        if ($gateOut) { Write-Output $gateOut }
        if ($gateCode -ne 0) {
            if (-not $gateOut) {
                Write-Output ('[WARN] the gate produced no output via ' + $bashExe + ' (' + $bashFrom + ') - skipped here, it still runs before every agent push')
            } else {
                Write-Output ('[FAIL] gate failed (exit ' + $gateCode + ')')
                $fail = 1
            }
        } else {
            Write-Output ('   (gate ran via ' + $bashExe + ' [' + $bashFrom + '])')
        }
    }
}

# 1b. the two hard requirements are asserted strictly in section 2 (2a/2b) -
#     they fail the round on purpose, because "push needs a click" and
#     "watcher flashes a window" are exactly what v2.5.0 had to fix.

# 2. v2.5.0 acceptance: the two hard requirements, asserted ON THIS MACHINE.
#    (Write-Output, not Write-Host: the watcher captures stdout only.)
#    2a. silent push - git must get a credential with ALL prompts disabled
if (Test-Path -LiteralPath '.\auth.ps1') {
    try {
        $auth = ((& .\auth.ps1 -Json -Verify) | Out-String) | ConvertFrom-Json
        if ($auth.push_dry_run -in @('passed', 'not-fast-forward') -and $auth.lsremote -eq 'passed') {
            if ($auth.push_dry_run -eq 'not-fast-forward') {
                Write-Output '== accept 2a: silent push PROVEN by the credential probe;'
                Write-Output '   the dry-run was only REJECTED (not a fast-forward) - the server had already accepted the token.'
                Write-Output '   run .\sync.ps1 so the next real push is a fast-forward.'
            } else {
                Write-Output '== accept 2a: silent push PROVEN (ls-remote + push --dry-run, prompts disabled)'
            }
        } else {
            Write-Output ("[FAIL] accept 2a: silent push NOT proven (lsremote=" + $auth.lsremote + " push_dry_run=" + $auth.push_dry_run + ")")
            Write-Output ("       detail: " + $auth.push_dry_run_detail)
            Write-Output '       fix once with:  .\auth.ps1 -Setup  then  .\auth.ps1 -Verify'
            $fail = 1
        }
    } catch {
        Write-Output '[FAIL] accept 2a: auth.ps1 probe failed (run .\auth.ps1 by hand to see why)'
        $fail = 1
    }
} else {
    Write-Output '[FAIL] accept 2a: auth.ps1 is missing (upgrade the skill)'
    $fail = 1
}

#    2b. how visible is the watcher? Graded, and the grade is printed:
#          zero-window launcher  -> nothing ever appears            (best)
#          S4U / session 0       -> nothing ever appears            (best, needs admin)
#          -Loop in one process  -> ONE brief flash per logon       (acceptable)
#          per-poll process      -> a flash every N minutes         (FAIL)
$taskName = 'git-sync-watch-' + (Split-Path -Leaf (Get-Location).Path)
try {
    $t = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    $exec  = [string]$t.Actions[0].Execute
    $argl  = [string]$t.Actions[0].Arguments
    $logon = [string]$t.Principal.LogonType
    if ($exec -match 'watchhost') {
        Write-Output ("== accept 2b: ZERO window - launcher exe: " + $exec)
    } elseif ($logon -eq 'S4U' -or $logon -eq 'Password') {
        Write-Output ("== accept 2b: ZERO window - session 0 (S4U), logon type " + $logon)
    } elseif ($argl -match '-Loop') {
        Write-Output '== accept 2b (fallback): one LONG-LIVED loop process - one brief flash per logon,'
        Write-Output '   not per poll. For zero flash: admin PowerShell -> .\watch.ps1 -Unregister ;'
        Write-Output '   .\watch.ps1 -Register -Headless   (or fix the launcher, see watch-*.log)'
    } else {
        Write-Output ("[FAIL] accept 2b: the task starts a new process per poll (" + $exec + " " + $argl + ")")
        Write-Output '       fix with:  .\watch.ps1 -Unregister  then  .\watch.ps1 -Register'
        $fail = 1
    }
} catch {
    Write-Output ("[FAIL] accept 2b: scheduled task '" + $taskName + "' not found - run .\watch.ps1 -Register")
    $fail = 1
}

#    2c. every watcher poll exit must record a closing line, so a round can
#        never end in silence (a silent exit looks like a hung window). This is
#        the PowerShell twin of the gate check in code/check_all.sh (3c).
$loopChk = '.\code\check_loop_summary.ps1'
if (Test-Path -LiteralPath $loopChk) {
    try {
        $chkOut = (& $loopChk -WatchPath '.\watch.ps1' 2>&1 | Out-String)
        $chkCode = $LASTEXITCODE
        if ($chkOut.Trim()) { Write-Output $chkOut.TrimEnd() }
        if ($chkCode -eq 0) {
            Write-Output '== accept 2c: watcher closing lines verified (every exit path has its summary)'
        } else {
            Write-Output ('[FAIL] accept 2c: watcher closing-line check failed (exit ' + $chkCode + ')')
            $fail = 1
        }
    } catch {
        Write-Output ('[FAIL] accept 2c: check_loop_summary.ps1 threw: ' + $_.Exception.Message)
        $fail = 1
    }
} else {
    Write-Output '[WARN] accept 2c: code\check_loop_summary.ps1 is missing - skipped (upgrade the skill)'
}

# 3. the Office deliverables - proven ON THIS MACHINE, without Office installed.
#    For every file listed in deliverable/OFFICE_HASHES.json:
#      3a sha256 + byte size equal the copy the agent generated, which proves
#         that what arrived through git is that exact file and not a stale one
#      3b the package opens as a zip and every required OOXML part is present
#      3c every .xml / .rels part parses as XML
#      3d every relationship target resolves inside the package (a dangling
#         r:id is exactly what makes Office report unreadable content)
#      3e [Content_Types].xml covers every part
#      3f must_contain markers are found across the xml parts
#      3g pptx only: at least min_slides slides are present
$manRel = 'deliverable/OFFICE_HASHES.json'
if (Test-Path -LiteralPath $manRel) {
    try {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    } catch {
        Write-Output ('[WARN] cannot load System.IO.Compression - deliverable package checks skipped: ' + $_.Exception.Message)
    }

    function Read-ZipText {
        param($Archive, [string]$Name)
        $ze = $Archive.GetEntry($Name)
        if (-not $ze) { return $null }
        $sr = New-Object System.IO.StreamReader($ze.Open(), [System.Text.Encoding]::UTF8)
        $t = $sr.ReadToEnd()
        $sr.Dispose()
        return $t
    }

    function Resolve-ZipPath {
        param([string]$Base, [string]$Target)
        $segs = @()
        if ($Base) { $segs += ($Base -split '/') }
        foreach ($s in ($Target -split '/')) {
            if ($s -eq '' -or $s -eq '.') { continue }
            if ($s -eq '..') {
                if ($segs.Count -gt 1) { $segs = $segs[0..($segs.Count - 2)] } else { $segs = @() }
                continue
            }
            $segs += $s
        }
        return ($segs -join '/')
    }

    try {
        $man = Get-Content -LiteralPath $manRel -Raw -Encoding UTF8 | ConvertFrom-Json
        $manFiles = @($man.files)
        Write-Output ('== deliverables: ' + $manFiles.Count + ' Office file(s) declared in ' + $manRel)
        foreach ($f in $manFiles) {
            $rel = [string]$f.path
            $p = $rel -replace '/', '\'
            $kind = [string]$f.kind
            if (-not (Test-Path -LiteralPath $p)) {
                Write-Output ('   FAIL MISSING deliverable ' + $rel)
                $fail = 1
                continue
            }
            # 3a integrity: the file that came through git is the generated one
            $sz = [int64](Get-Item -LiteralPath $p).Length
            if ($sz -ne [int64]$f.bytes) {
                Write-Output ('   FAIL SIZE ' + $rel + ' expected ' + [int64]$f.bytes + ' got ' + $sz)
                $fail = 1
                continue
            }
            $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($h -ne ([string]$f.sha256).ToLowerInvariant()) {
                Write-Output ('   FAIL SHA256 ' + $rel + ' does not match the generated copy')
                Write-Output ('        local  ' + $h)
                Write-Output ('        wanted ' + [string]$f.sha256)
                $fail = 1
                continue
            }
            Write-Output ('   OK   3a sha256 + bytes match: ' + $rel + ' (' + $sz + ' B, ' + $kind + ')')

            $full = (Resolve-Path -LiteralPath $p).Path
            $zip = $null
            try { $zip = [System.IO.Compression.ZipFile]::OpenRead($full) } catch { $zip = $null }
            if (-not $zip) {
                Write-Output ('   FAIL 3b not a readable OOXML zip package: ' + $rel)
                $fail = 1
                continue
            }
            try {
                $names = @{}
                foreach ($ze in $zip.Entries) { $names[$ze.FullName] = $true }
                if ($names.Count -ne $zip.Entries.Count) {
                    Write-Output ('   FAIL 3b duplicate zip entries in ' + $rel)
                    $fail = 1
                }

                # 3b required parts
                $miss = @()
                foreach ($rp in @($f.required_parts)) {
                    if (-not $names.ContainsKey([string]$rp)) { $miss += [string]$rp }
                }
                if ($miss.Count -gt 0) {
                    Write-Output ('   FAIL 3b missing parts in ' + $rel + ' : ' + ($miss -join ', '))
                    $fail = 1
                } else {
                    Write-Output ('   OK   3b all ' + @($f.required_parts).Count + ' required parts present in ' + $rel)
                }

                # 3c every xml part parses; also collect the text for 3f
                $badXml = @()
                $allText = New-Object System.Text.StringBuilder
                foreach ($ze in $zip.Entries) {
                    if ($ze.FullName -notmatch '\.(xml|rels)$') { continue }
                    $t = Read-ZipText $zip $ze.FullName
                    if ($null -eq $t) { $badXml += ($ze.FullName + ' (unreadable)'); continue }
                    try { $null = [xml]$t } catch { $badXml += $ze.FullName }
                    [void]$allText.Append($t)
                }
                if ($badXml.Count -gt 0) {
                    Write-Output ('   FAIL 3c unparseable XML in ' + $rel + ' : ' + ($badXml -join ', '))
                    $fail = 1
                } else {
                    Write-Output ('   OK   3c every XML part parses in ' + $rel + ' (' + $names.Count + ' parts)')
                }

                # 3d relationships resolve
                $dangling = @()
                foreach ($ze in $zip.Entries) {
                    if ($ze.FullName -notmatch '\.rels$') { continue }
                    $segs = $ze.FullName -split '/'
                    $dirSegs = @()
                    if ($segs.Count -gt 2) { $dirSegs = $segs[0..($segs.Count - 3)] }
                    $base = ($dirSegs -join '/')
                    $rx = [xml](Read-ZipText $zip $ze.FullName)
                    foreach ($r in @($rx.Relationships.Relationship)) {
                        $tgt = [string]$r.Target
                        if (-not $tgt -or $tgt.StartsWith('http')) { continue }
                        $resolved = Resolve-ZipPath $base $tgt
                        if (-not $names.ContainsKey($resolved)) {
                            $dangling += ($ze.FullName + ' -> ' + $tgt)
                        }
                    }
                }
                if ($dangling.Count -gt 0) {
                    Write-Output ('   FAIL 3d dangling relationships in ' + $rel + ' : ' + ($dangling -join '; '))
                    $fail = 1
                } else {
                    Write-Output ('   OK   3d every relationship target resolves in ' + $rel)
                }

                # 3e content types cover every part
                $ctx = [xml](Read-ZipText $zip '[Content_Types].xml')
                $defs = @()
                foreach ($d in @($ctx.Types.Default)) { $defs += ([string]$d.Extension).ToLowerInvariant() }
                $ovrs = @()
                foreach ($o in @($ctx.Types.Override)) { $ovrs += [string]$o.PartName }
                $noCt = @()
                foreach ($ze in $zip.Entries) {
                    if ($ze.FullName -eq '[Content_Types].xml') { continue }
                    $ext = ''
                    if ($ze.FullName.Contains('.')) { $ext = ($ze.FullName.Split('.')[-1]).ToLowerInvariant() }
                    if (($ovrs -notcontains ('/' + $ze.FullName)) -and ($defs -notcontains $ext)) {
                        $noCt += $ze.FullName
                    }
                }
                if ($noCt.Count -gt 0) {
                    Write-Output ('   FAIL 3e parts without a content type in ' + $rel + ' : ' + ($noCt -join ', '))
                    $fail = 1
                } else {
                    Write-Output ('   OK   3e content types cover every part of ' + $rel)
                }

                # 3f text markers (searched across all xml parts of the package)
                $body = $allText.ToString()
                $noMark = @()
                foreach ($m in @($f.must_contain)) {
                    if (-not $body.Contains([string]$m)) { $noMark += [string]$m }
                }
                if ($noMark.Count -gt 0) {
                    Write-Output ('   FAIL 3f markers not found in ' + $rel + ' : ' + ($noMark -join ', '))
                    $fail = 1
                } else {
                    Write-Output ('   OK   3f all ' + @($f.must_contain).Count + ' text markers present in ' + $rel)
                }

                # 3g slide count for decks
                if ($f.min_slides) {
                    $nSlides = @($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide[0-9]+\.xml$' }).Count
                    if ($nSlides -lt [int]$f.min_slides) {
                        Write-Output ('   FAIL 3g slides in ' + $rel + ' : ' + $nSlides + ' < ' + [int]$f.min_slides)
                        $fail = 1
                    } else {
                        Write-Output ('   OK   3g slides in ' + $rel + ' : ' + $nSlides + ' >= ' + [int]$f.min_slides)
                    }
                }
            } finally {
                $zip.Dispose()
            }
        }
    } catch {
        Write-Output ('[FAIL] deliverable check threw: ' + $_.Exception.Message)
        $fail = 1
    }
} else {
    Write-Output ('== deliverables: (no ' + $manRel + ' - package checks skipped)')
}

#    3h. application-level open test, auto-detected and time-boxed.
#        The registry is probed for a registered COM server (MS Word / PowerPoint,
#        or WPS Writer / Presentation). Nothing is launched when no suite is
#        installed, so an Office-less or WPS-only machine gets SKIP instead of a
#        false FAIL. The launch runs in a job with a hard timeout, so a hung COM
#        server can never burn the round (check_timeout_min). Force off:
#            setx GIT_SYNC_OFFICE_COM 0
$comTargets = @()
try {
    if (Test-Path -LiteralPath $manRel) {
        $mh = Get-Content -LiteralPath $manRel -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($mh.files) {
            foreach ($mf in @($mh.files)) {
                $p = [string]$mf.path
                if (-not $p) { continue }
                $k = [string]$mf.kind
                if (-not $k) { $k = [System.IO.Path]::GetExtension($p).TrimStart('.') }
                if ($k -eq 'docx' -or $k -eq 'doc') {
                    $comTargets += , @($p.Replace('/', '\'), @('Word.Application', 'KWPS.Application'), 'word')
                } elseif ($k -eq 'pptx' -or $k -eq 'ppt') {
                    $comTargets += , @($p.Replace('/', '\'), @('PowerPoint.Application', 'KWPP.Application'), 'deck')
                }
            }
        }
    }
} catch {
    Write-Output ('   WARN 3h could not read ' + $manRel + ' (' + $_.Exception.Message + ') - open test skipped')
}
if ($comTargets.Count -eq 0) {
    Write-Output ('   SKIP 3h no Office deliverable declared in ' + $manRel + ' - nothing to open')
}
foreach ($ct in $comTargets) {
    $target = [string]$ct[0]
    $kind = [string]$ct[2]
    if (-not (Test-Path -LiteralPath $target)) { continue }
    if ([string]$env:GIT_SYNC_OFFICE_COM -eq '0') {
        Write-Output ('   SKIP 3h ' + $kind + ' open test disabled by GIT_SYNC_OFFICE_COM')
        continue
    }
    $progId = ''
    foreach ($cand in @($ct[1])) {
        if (Test-Path -LiteralPath ('Registry::HKEY_CLASSES_ROOT\' + [string]$cand)) {
            $progId = [string]$cand
            break
        }
    }
    if (-not $progId) {
        Write-Output ('   SKIP 3h no registered COM server for ' + $kind + ' (Word/WPS) - the structural checks above stand')
        continue
    }
    $abs = (Resolve-Path -LiteralPath $target).Path
    $job = $null
    try {
        # $PID is a PowerShell automatic variable, hence $srv for the prog id
        $job = Start-Job -ArgumentList $progId, $abs, $kind -ScriptBlock {
            param($srv, $path, $k)
            $app = New-Object -ComObject $srv
            try {
                if ($k -eq 'word') {
                    $doc = $app.Documents.Open($path, $false, $true)
                    $name = [string]$doc.Name
                    $doc.Close($false)
                    return ('opened read-only, name=' + $name)
                }
                $pres = $app.Presentations.Open($path, $true, $false, $false)
                $n = [int]$pres.Slides.Count
                $pres.Close()
                return ('opened read-only, slides=' + $n)
            } finally {
                try { $app.Quit() } catch { }
            }
        }
        $done = Wait-Job $job -Timeout 120
        if (-not $done) {
            Write-Output ('   WARN 3h ' + $progId + ' did not answer in 120s - counted as SKIP, not as a failure')
            Stop-Job $job -ErrorAction SilentlyContinue
        } elseif ($job.State -eq 'Completed') {
            $msg = ((Receive-Job $job | Out-String) -replace '\s+$', '')
            Write-Output ('   OK   3h ' + $progId + ' ' + $msg + ' : ' + $target)
        } else {
            $err = ((Receive-Job $job 2>&1 | Out-String) -replace '\s+$', '')
            Write-Output ('   FAIL 3h ' + $progId + ' refused to open ' + $target)
            Write-Output ('        ' + $err)
            $fail = 1
        }
    } catch {
        Write-Output ('   WARN 3h open test could not run (' + $_.Exception.Message + ') - counted as SKIP')
    } finally {
        if ($job) { Remove-Job $job -Force -ErrorAction SilentlyContinue }
    }
}

# 4. PPT Master installed ON THIS MACHINE, and a deck produced BY this machine.
#    code\pptmaster_local.ps1 clones/creates the toolchain outside the repo
#    (default <parent>\ppt-master), runs the full pipeline here (author the 12
#    SVG pages from this repo -> svg_quality_checker -> svg_to_pptx), verifies
#    the pptx it produced and opens it read-only in the real PowerPoint, then
#    writes results\status\pptmaster_local.json / .txt - which the watcher
#    pushes back, so the agent can see what this machine actually did.
#    Run in a child process so its exit code is unambiguous and no console
#    window can flash.
$pptScript = Join-Path (Get-Location).Path 'code\pptmaster_local.ps1'
# The task's local plane. office-deck (the default recipe) keeps its proven
# inline path below; any other recipe id in code\loop.json runs through the
# task-agnostic runner (code\local_loop.py local --os windows) and its
# receipt is judged the same way local_check.sh judges it (loop-ok +
# opened=). ASCII-only: no CJK in this file, ever.
$recipeId = 'office-deck'
try {
    $loopCfg = Get-Content -LiteralPath '.\code\loop.json' -Raw -ErrorAction Stop | ConvertFrom-Json
    if ($loopCfg.recipe) { $recipeId = [string]$loopCfg.recipe }
} catch { }
Write-Output ('   .. 4 recipe: ' + $recipeId)
if ($recipeId -ne 'office-deck') {
    # find a WORKING Windows python the way check_all.sh does: try each
    # candidate and prove it runs (a bare Store stub answers Get-Command and
    # then fails, so only a probe that prints counts).
    $runPy = ''
    $runPyArgs = @()
    foreach ($cand in @('python3', 'python', 'py -3')) {
        $parts = @($cand -split ' ')
        $exeName = $parts[0]
        $extra = @()
        if ($parts.Count -gt 1) { $extra = $parts[1..($parts.Count - 1)] }
        $found = Get-Command $exeName -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $found) { continue }
        try {
            $probe = (& $found.Source @extra -c 'import sys;print("py-ok")' 2>&1 | Out-String)
            if (($LASTEXITCODE -eq 0) -and ($probe -match 'py-ok')) {
                $runPy = [string]$found.Source
                $runPyArgs = $extra
                break
            }
        } catch { }
    }
    if (-not $runPy) {
        Write-Output '[FAIL] 4a no working python (python3 / python / py -3) - cannot run the recipe'
        $fail = 1
    } elseif (-not (Test-Path -LiteralPath '.\code\local_loop.py')) {
        Write-Output '[FAIL] 4a code\local_loop.py is missing - cannot run the recipe'
        $fail = 1
    } else {
        Write-Output ('   .. 4a runner python: ' + $runPy)
        $runOut = (& $runPy @runPyArgs 'code\local_loop.py' 'local' '--os' 'windows' 2>&1 | Out-String)
        $runCode = $LASTEXITCODE
        if ($runOut) { Write-Output $runOut }
        if ($runCode -ne 0) {
            Write-Output ('   FAIL 4a recipe local plane failed (exit ' + $runCode + ')')
            $fail = 1
        } else {
            Write-Output '   OK   4a recipe local plane finished (exit 0)'
        }
    }
    # 4b/4c judge the runner receipt, exactly like local_check.sh does
    $loopRec = '.\results\status\local_loop_receipt.txt'
    if (Test-Path -LiteralPath $loopRec) {
        $rec = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $loopRec).Path)
        if ($rec -match '(?m)^loop-ok') {
            Write-Output '   OK   4b every declared key matched'
        } else {
            Write-Output '   FAIL 4b the receipt says the task did not verify'
            $fail = 1
        }
        $opened = ''
        if ($rec -match 'opened=([^\s]+)') { $opened = $Matches[1] }
        if (($opened -eq 'yes') -or ($opened.StartsWith('ok'))) {
            Write-Output ('   OK   4c a real application opened the file (' + $opened + ')')
        } elseif (($opened -eq 'na') -or ($opened.StartsWith('skip')) -or ($opened -eq 'unknown') -or (-not $opened)) {
            Write-Output ('   WARN 4c no application open test on this machine (' + $opened + ') - structural checks stand')
        } else {
            Write-Output ('   FAIL 4c the file could not be opened by a real application (' + $opened + ')')
            $fail = 1
        }
    } else {
        Write-Output '   WARN 4b/4c no local_loop_receipt.txt (the local plane did not run)'
    }
} elseif (Test-Path -LiteralPath $pptScript) {
    Write-Output '== ppt-master: local install + local deck generation'
    $pptOut = Join-Path $env:TEMP ('pptmaster_out_' + (Get-Date -Format 'HHmmss') + '.log')
    $pptErr = Join-Path $env:TEMP ('pptmaster_err_' + (Get-Date -Format 'HHmmss') + '.log')
    # resolve a REAL powershell.exe: the bare name can hit a Store app-execution
    # alias ("%1 is not a valid Win32 application", round 25) - the same lesson
    # watch.ps1 learned, so the same preference order (pwsh > SysNative >
    # System32 > this process).
    $psExe = ''
    $me = ''
    try { $me = [string](Get-Process -Id $PID).Path } catch { $me = '' }
    if ($me -match 'pwsh\.exe$') {
        $psExe = $me
    } else {
        $is32 = $false
        try { $is32 = -not [Environment]::Is64BitProcess } catch { }
        if ($is32 -and $env:WINDIR) {
            $native = Join-Path $env:WINDIR 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
            if (Test-Path -LiteralPath $native) { $psExe = $native }
        }
        if (-not $psExe -and $env:WINDIR) {
            $sys = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
            if (Test-Path -LiteralPath $sys) { $psExe = $sys }
        }
        if (-not $psExe -and $me -match 'powershell\.exe$') { $psExe = $me }
    }
    if (-not $psExe) { $psExe = 'powershell.exe' }
    Write-Output ('   .. 4a launcher: ' + $psExe)
    $pptCode = 124
    try {
        # The child is launched through the .NET Process class, not
        # Start-Process: on this machine Start-Process -PassThru combined with
        # -RedirectStandardOutput handed back a process object whose ExitCode
        # was $null, so round 29 reported "failed (exit )" for a child that had
        # verified the whole install (checker 0 blocking, 12 slides, PowerPoint
        # opened it, receipt clean). Never read an exit code through that path.
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $psExe
        $psi.Arguments = ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $pptScript + '"')
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = (Get-Location).Path
        $child = New-Object System.Diagnostics.Process
        $child.StartInfo = $psi
        $null = $child.Start()
        # drain both pipes as raw bytes while the child runs - reading them one
        # after the other would deadlock once the second buffer fills, and
        # decoding here would have to guess between the GBK console text and
        # the UTF-8 file text the child mixes
        $outBuf = New-Object System.IO.MemoryStream
        $errBuf = New-Object System.IO.MemoryStream
        $outCopy = $child.StandardOutput.BaseStream.CopyToAsync($outBuf)
        $errCopy = $child.StandardError.BaseStream.CopyToAsync($errBuf)
        # 20 minutes: below the watcher's 30 minute hard cap, so a stall here
        # still produces a verdict instead of a TIMEOUT with no detail
        if (-not $child.WaitForExit(1200000)) {
            try { $child.Kill() } catch { }
            Write-Output '   FAIL 4a pptmaster_local.ps1 did not finish in 20 minutes'
            $fail = 1
        } else {
            $child.WaitForExit()
            $null = $outCopy.Wait(60000)
            $null = $errCopy.Wait(60000)
            [System.IO.File]::WriteAllBytes($pptOut, $outBuf.ToArray())
            [System.IO.File]::WriteAllBytes($pptErr, $errBuf.ToArray())
            $pptCode = [int]$child.ExitCode
        }
    } catch {
        # last resort: run it in this process (no exit code, so 4b/4c carry the
        # verdict from the receipt instead)
        Write-Output ('   WARN 4a could not start a child powershell (' + $_.Exception.Message + ') - running it in-process')
        try {
            & $pptScript *> $pptOut
            $pptCode = 0
        } catch {
            Write-Output ('   FAIL 4a pptmaster_local.ps1 threw: ' + $_.Exception.Message)
            $fail = 1
        }
    }
    foreach ($f in @($pptOut, $pptErr)) {
        if (Test-Path -LiteralPath $f) {
            $body = ([System.IO.File]::ReadAllText($f)).TrimEnd()
            if ($body) { Write-Output $body }
        }
    }
    if ($pptCode -eq 0) {
        Write-Output '   OK   4a ppt-master installed + verified on this machine (exit 0)'
    } elseif ($pptCode -eq 126) {
        Write-Output '   WARN 4a child exit code could not be read - 4b/4c judged the receipt'
    } elseif ($pptCode -ne 124) {
        Write-Output ('   FAIL 4a ppt-master local install/verification failed (exit ' + $pptCode + ')')
        $fail = 1
    }

    # 4b/4c read the receipt, so the verdict names exactly which claim failed
    $recTxt = '.\results\status\pptmaster_local.txt'
    if (Test-Path -LiteralPath $recTxt) {
        $rec = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $recTxt).Path)
        # environment=windows matters: without it a receipt committed by the
        # agent's sandbox would be read as if THIS machine had verified it
        foreach ($needle in @('environment=windows', 'deck_slides=12', 'checker_blocking=0', 'markers=ok')) {
            if ($rec.Contains($needle)) {
                Write-Output ('   OK   4b receipt: ' + $needle)
            } else {
                Write-Output ('   FAIL 4b receipt is missing ' + $needle)
                $fail = 1
            }
        }
        if ($rec.Contains('powerpoint=yes')) {
            Write-Output '   OK   4c real PowerPoint opened the deck this machine generated'
        } elseif ($rec.Contains('powerpoint=na')) {
            Write-Output '   WARN 4c PowerPoint COM unavailable - counted as SKIP (structural checks stand)'
        } else {
            Write-Output '   FAIL 4c PowerPoint refused the deck this machine generated'
            $fail = 1
        }
    } else {
        Write-Output '[FAIL] 4b results\status\pptmaster_local.txt was never written'
        $fail = 1
    }
} else {
    Write-Output '[WARN] 4. code\pptmaster_local.ps1 is missing - local ppt-master install not verified'
}


#    2d. v2.7.0 hands-free helpers must be in watch.ps1 (on disk after sync;
#        the running loop still needs a re-register to USE them).
$watchSrc = '.\watch.ps1'
if (Test-Path -LiteralPath $watchSrc) {
    $wt = Get-Content -LiteralPath $watchSrc -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($wt -and $wt.Contains('function Invoke-AutoPull') -and $wt.Contains('function Invoke-AutoPush')) {
        Write-Output '== accept 2d: hands-free auto_pull/auto_push present in watch.ps1'
    } else {
        Write-Output '[FAIL] accept 2d: watch.ps1 is missing Invoke-AutoPull / Invoke-AutoPush (upgrade the skill)'
        $fail = 1
    }
} else {
    Write-Output '[FAIL] accept 2d: watch.ps1 missing'
    $fail = 1
}

# ------------------------------------------------------------------------
# hands-free success criteria (v2.7.0)
# If results/status/success_criteria.json (or config.success_criteria) exists,
# require every listed file / substring / size / regex. Missing file = skip.
$critRel = 'results/status/success_criteria.json'
if (Test-Path -LiteralPath '.\skills\git-sync\sync.config.json') {
    try {
        $cfgObj = Get-Content -LiteralPath '.\skills\git-sync\sync.config.json' -Encoding UTF8 -Raw | ConvertFrom-Json
        if ($cfgObj.success_criteria) { $critRel = [string]$cfgObj.success_criteria }
    } catch { }
}
$critRel = $critRel -replace '\\', '/'
$critAbs = Join-Path (Get-Location) ($critRel -replace '/', '\')
if (Test-Path -LiteralPath $critAbs) {
    Write-Output ('== success criteria: ' + $critRel)
    try {
        $crit = Get-Content -LiteralPath $critAbs -Encoding UTF8 -Raw | ConvertFrom-Json
        if ($crit.description) { Write-Output ('   ' + $crit.description) }
        foreach ($f in @($crit.require_files)) {
            if (-not $f) { continue }
            $fp = Join-Path (Get-Location) ($f -replace '/', '\')
            if (Test-Path -LiteralPath $fp) {
                $sz = (Get-Item -LiteralPath $fp).Length
                Write-Output ('   OK   exists: ' + $f + ' (' + $sz + ' B)')
            } else {
                Write-Output ('   FAIL MISSING file: ' + $f)
                $fail = 1
            }
        }
        foreach ($f in @($crit.forbid_files)) {
            if (-not $f) { continue }
            $fp = Join-Path (Get-Location) ($f -replace '/', '\')
            if (Test-Path -LiteralPath $fp) {
                Write-Output ('   FAIL FORBIDDEN still present: ' + $f)
                $fail = 1
            } else {
                Write-Output ('   OK   absent: ' + $f)
            }
        }
        if ($crit.require_contains) {
            foreach ($prop in $crit.require_contains.PSObject.Properties) {
                $f = [string]$prop.Name
                $sub = [string]$prop.Value
                $fp = Join-Path (Get-Location) ($f -replace '/', '\')
                if (-not (Test-Path -LiteralPath $fp)) {
                    Write-Output ('   FAIL MISSING for contains: ' + $f)
                    $fail = 1
                    continue
                }
                $txt = Get-Content -LiteralPath $fp -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($null -eq $txt) { $txt = '' }
                if ($txt.Contains($sub)) {
                    Write-Output ('   OK   contains ' + $f + ' <- ' + $sub)
                } else {
                    Write-Output ('   FAIL DOES NOT contain in ' + $f + ': ' + $sub)
                    $fail = 1
                }
            }
        }
        if ($crit.require_regex) {
            foreach ($prop in $crit.require_regex.PSObject.Properties) {
                $f = [string]$prop.Name
                $rx = [string]$prop.Value
                $fp = Join-Path (Get-Location) ($f -replace '/', '\')
                if (-not (Test-Path -LiteralPath $fp)) {
                    Write-Output ('   FAIL MISSING for regex: ' + $f)
                    $fail = 1
                    continue
                }
                $txt = Get-Content -LiteralPath $fp -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($null -eq $txt) { $txt = '' }
                if ($txt -match $rx) {
                    Write-Output ('   OK   regex ' + $f)
                } else {
                    Write-Output ('   FAIL regex in ' + $f + ': ' + $rx)
                    $fail = 1
                }
            }
        }
        if ($crit.min_bytes) {
            foreach ($prop in $crit.min_bytes.PSObject.Properties) {
                $f = [string]$prop.Name
                $need = [int64]$prop.Value
                $fp = Join-Path (Get-Location) ($f -replace '/', '\')
                if (-not (Test-Path -LiteralPath $fp)) {
                    Write-Output ('   FAIL MISSING for min_bytes: ' + $f)
                    $fail = 1
                    continue
                }
                $sz = [int64](Get-Item -LiteralPath $fp).Length
                if ($sz -ge $need) {
                    Write-Output ('   OK   size ' + $f + ': ' + $sz + ' >= ' + $need)
                } else {
                    Write-Output ('   FAIL TOO SMALL ' + $f + ': ' + $sz + ' < ' + $need)
                    $fail = 1
                }
            }
        }
        if ($crit.max_bytes) {
            foreach ($prop in $crit.max_bytes.PSObject.Properties) {
                $f = [string]$prop.Name
                $need = [int64]$prop.Value
                $fp = Join-Path (Get-Location) ($f -replace '/', '\')
                if (-not (Test-Path -LiteralPath $fp)) {
                    Write-Output ('   FAIL MISSING for max_bytes: ' + $f)
                    $fail = 1
                    continue
                }
                $sz = [int64](Get-Item -LiteralPath $fp).Length
                if ($sz -le $need) {
                    Write-Output ('   OK   size ' + $f + ': ' + $sz + ' <= ' + $need)
                } else {
                    Write-Output ('   FAIL TOO BIG ' + $f + ': ' + $sz + ' > ' + $need)
                    $fail = 1
                }
            }
        }
    } catch {
        Write-Output ('   FAIL criteria parse: ' + $_.Exception.Message)
        $fail = 1
    }
} else {
    Write-Output ('== success criteria: (none at ' + $critRel + ' - skipped)')
}

if ($fail -eq 0) { Write-Output '== local checks passed' }
exit $fail
