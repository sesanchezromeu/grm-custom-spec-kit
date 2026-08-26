#Requires -Version 5.1
<#
    ConvertTo-MarkdownFromHtml.ps1

    Deterministic HTML to Markdown conversion for Azure DevOps work item
    fields, with completeness and structure verification.

    Normative specification: references/fidelity-contract.md sections 3 and 4.

    Two modes (D-P13-01):
      dot-sourced with no arguments  -> defines ConvertTo-MarkdownFromHtml and
                                        does nothing else
      -HtmlPath <file> | -HtmlText   -> converts and prints, for manual testing

    ASCII only. Windows PowerShell 5.1 reads a .ps1 without BOM as ANSI, and a
    reinterpreted multi-byte character can produce a typographic quote, which
    the parser accepts as a string delimiter. One such character breaks the
    whole file.

    No regular expressions are used to interpret the markup. Nesting depth
    carries business meaning and a regex approach does not preserve it.

    F-08 verification (P16c, D-P16c-01). The rule is not relaxed, it is measured
    correctly. Until P16c the two sides were measured with different criteria:
    the source side recorded a depth per li visited in the DOM, and the payload
    side ran a regular expression over the final Markdown that counted every
    line shaped like a list item. A work item written by pasting plain text with
    leading dashes has no list in its DOM and many list-shaped lines in its
    text, so the comparison rejected a conversion that had lost nothing.

    The converter now records, at the moment it writes them, the literal line
    and the depth of every list item it emits. Verification asserts that those
    lines are still present in the final Markdown, in order, with an indentation
    that encodes their depth. Any remaining list-shaped line did not come from a
    list in the source: it is ignored for the verdict and reported as a warning,
    because it is source text, not lost structure.
#>

[CmdletBinding()]
param(
    [string]$HtmlPath,
    [string]$HtmlText
)

# ---------------------------------------------------------------------------
# Tag inventory (D-P13-02)
# ---------------------------------------------------------------------------

$GRM_BLOCK_TAGS = @(
    'HTML','BODY','P','DIV','UL','OL','LI','H1','H2','H3','H4','H5','H6',
    'PRE','TABLE','THEAD','TBODY','TFOOT','TR','TD','TH','BLOCKQUOTE','HR'
)

$GRM_INLINE_TAGS = @(
    'STRONG','B','EM','I','A','CODE','SPAN','U','SUP','SUB','FONT','SMALL',
    'LABEL','ABBR','MARK','S','STRIKE','DEL','INS','IMG','BR','WBR','TIME','VAR','KBD','SAMP','Q'
)

# ---------------------------------------------------------------------------
# Text normalization, shared by both sides of the F-07 comparison
# ---------------------------------------------------------------------------

function Get-PbiTextTokens {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    $t = $Text -replace ([string][char]0x00A0), ' '   # non-breaking space
    $t = $t -replace ([string][char]0x200B), ''       # zero-width space

    # Markdown link and image syntax reduces to its visible text.
    $t = $t -replace '!\[([^\]]*)\]\([^)]*\)', '$1'
    $t = $t -replace '\[([^\]]*)\]\([^)]*\)', '$1'

    # List markers, heading hashes, blockquote markers, fences.
    $t = $t -replace '(?m)^\s*([-*+]|\d+\.)\s+', ' '
    $t = $t -replace '(?m)^\s*#{1,6}\s+', ' '
    $t = $t -replace '(?m)^\s*>\s?', ' '
    $t = $t -replace '(?m)^\s*```.*$', ' '

    # Emphasis, code and table pipes carry no text.
    $t = $t -replace '[*_`|]', ''

    $t = $t -replace '\s+', ' '

    $tokens = @($t.Trim() -split ' ' | Where-Object { $_ -ne '' })

    # Table separator rows are structure, not content.
    return @($tokens | Where-Object { $_ -notmatch '^[:\-=]+$' })
}

# ---------------------------------------------------------------------------
# DOM helpers. MSHTML upper-cases tag names and omits optional closing tags,
# so comparisons are case-insensitive and the tree is always walked.
# ---------------------------------------------------------------------------

function Get-TagName {
    param($Node)
    $name = $null
    try { $name = $Node.tagName } catch { }
    if (-not $name) { return '' }
    return ([string]$name).ToUpperInvariant()
}

function Get-ChildNodeList {
    param($Node)
    $result = @()
    try {
        $children = $Node.childNodes
        if ($null -eq $children) { return @() }
        for ($i = 0; $i -lt $children.length; $i++) { $result += $children.item($i) }
    } catch { return @() }
    return $result
}

function Test-HasBlockChild {
    param($Node)
    foreach ($c in (Get-ChildNodeList $Node)) {
        if ($c.nodeType -ne 1) { continue }
        $tag = Get-TagName $c
        if ($GRM_BLOCK_TAGS -contains $tag) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Conversion state
# ---------------------------------------------------------------------------

function New-ConversionState {
    return @{
        Lines     = [System.Collections.Generic.List[string]]::new()
        # F-08: one entry per list item actually written, recorded where it is
        # written. Depth comes from the DOM walk, Line is the emitted text.
        ListItems = [System.Collections.Generic.List[object]]::new()
        Warnings  = [System.Collections.Generic.List[string]]::new()
        Failure   = $null
    }
}

function Add-Line {
    param($State, [string]$Line)
    $State.Lines.Add($Line) | Out-Null
}

function Add-Blank {
    param($State)
    if ($State.Lines.Count -eq 0) { return }
    if ($State.Lines[$State.Lines.Count - 1] -eq '') { return }
    $State.Lines.Add('') | Out-Null
}

function Set-Failure {
    param($State, [string]$Detail)
    if (-not $State.Failure) { $State.Failure = $Detail }
}

# ---------------------------------------------------------------------------
# Inline rendering
# ---------------------------------------------------------------------------

function Get-InlineMarkdown {
    param($Node, $State, [switch]$SkipLists)

    $sb = New-Object System.Text.StringBuilder

    foreach ($child in (Get-ChildNodeList $Node)) {

        if ($child.nodeType -eq 3) {
            $value = [string]$child.nodeValue
            if ($value) {
                $value = $value -replace ([string][char]0x00A0), ' '
                [void]$sb.Append($value)
            }
            continue
        }
        if ($child.nodeType -ne 1) { continue }

        $tag = Get-TagName $child

        if ($SkipLists -and ($tag -eq 'UL' -or $tag -eq 'OL')) { continue }

        switch ($tag) {

            'BR' {
                # H-05: inside a list item this is a line continuation, never a
                # new bullet. The caller re-indents continuation lines.
                [void]$sb.Append("`n")
            }
            { $_ -eq 'STRONG' -or $_ -eq 'B' } {
                $inner = (Get-InlineMarkdown -Node $child -State $State).Trim()
                if ($inner) { [void]$sb.Append('**' + $inner + '**') }
            }
            { $_ -eq 'EM' -or $_ -eq 'I' } {
                $inner = (Get-InlineMarkdown -Node $child -State $State).Trim()
                if ($inner) { [void]$sb.Append('*' + $inner + '*') }
            }
            'CODE' {
                $inner = (Get-InlineMarkdown -Node $child -State $State).Trim()
                if ($inner) { [void]$sb.Append('`' + $inner + '`') }
            }
            'A' {
                $inner = (Get-InlineMarkdown -Node $child -State $State).Trim()
                $href  = $null
                try { $href = [string]$child.getAttribute('href') } catch { }
                if ($inner -and $href) { [void]$sb.Append('[' + $inner + '](' + $href + ')') }
                elseif ($inner)        { [void]$sb.Append($inner) }
            }
            'IMG' {
                $alt = $null
                try { $alt = [string]$child.getAttribute('alt') } catch { }
                $State.Warnings.Add("An image was found and discarded from the payload; attachments are referenced, not embedded.") | Out-Null
                if ($alt) { [void]$sb.Append($alt) }
            }
            { $_ -eq 'P' -or $_ -eq 'DIV' -or $_ -eq 'BLOCKQUOTE' } {
                # A block wrapper inside inline content: keep the text, break the line.
                $inner = (Get-InlineMarkdown -Node $child -State $State -SkipLists:$SkipLists)
                if ($inner.Trim()) {
                    if ($sb.Length -gt 0) { [void]$sb.Append("`n") }
                    [void]$sb.Append($inner.Trim())
                }
            }
            default {
                if ($GRM_INLINE_TAGS -contains $tag) {
                    # Known inline decoration with no Markdown equivalent: unwrap.
                    [void]$sb.Append((Get-InlineMarkdown -Node $child -State $State -SkipLists:$SkipLists))
                }
                elseif ($GRM_BLOCK_TAGS -contains $tag) {
                    Set-Failure $State ("block element '$tag' found inside inline content")
                }
                else {
                    # Unknown inline element: unwrap, keep the text, warn.
                    $State.Warnings.Add("Unknown inline element '$tag' was unwrapped; its text was preserved.") | Out-Null
                    [void]$sb.Append((Get-InlineMarkdown -Node $child -State $State -SkipLists:$SkipLists))
                }
            }
        }
    }

    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Block rendering
# ---------------------------------------------------------------------------

function Add-ListItemText {
    param($State, [string]$Text, [string]$Indent, [string]$Marker, [int]$Depth)

    $parts = @($Text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($parts.Count -eq 0) { return }

    # D-P16c-03: the item is recorded here, at the single point where the
    # converter writes a bullet, and only when a line is actually produced.
    # Recording in the callers left two ways to disagree with reality: an empty
    # li recorded a depth and wrote nothing, and loose text inside a list wrote
    # a bullet and recorded nothing. Both failed F-08 for no reason.
    $line = $Indent + $Marker + $parts[0]
    $State.ListItems.Add(@{ Depth = $Depth; Line = $line }) | Out-Null

    Add-Line $State $line
    for ($i = 1; $i -lt $parts.Count; $i++) {
        # Continuation of the same item, aligned under its text.
        Add-Line $State ($Indent + '  ' + $parts[$i])
    }
}

function Convert-ListNode {
    param($Node, $State, [int]$Depth)

    $ordered = ((Get-TagName $Node) -eq 'OL')
    $index   = 1
    $indent  = ' ' * (2 * $Depth)

    foreach ($child in (Get-ChildNodeList $Node)) {
        if ($child.nodeType -eq 3) {
            if (([string]$child.nodeValue).Trim()) {
                $State.Warnings.Add("Loose text inside a list was preserved as an item.") | Out-Null
                Add-ListItemText $State ([string]$child.nodeValue) $indent '- ' $Depth
            }
            continue
        }
        if ($child.nodeType -ne 1) { continue }

        $tag = Get-TagName $child

        if ($tag -eq 'UL' -or $tag -eq 'OL') {
            # A list nested directly under a list, without an intervening li.
            Convert-ListNode -Node $child -State $State -Depth ($Depth + 1)
            continue
        }
        if ($tag -ne 'LI') {
            Set-Failure $State ("unexpected element '$tag' inside a list")
            continue
        }

        # F-08: depth comes from the DOM walk, never from the generated
        # Markdown. Add-ListItemText records it together with the line it writes.
        $marker = if ($ordered) { "$index. " } else { '- ' }
        $text   = Get-InlineMarkdown -Node $child -State $State -SkipLists
        Add-ListItemText $State $text $indent $marker $Depth
        $index++

        foreach ($sub in (Get-ChildNodeList $child)) {
            if ($sub.nodeType -ne 1) { continue }
            $subTag = Get-TagName $sub
            if ($subTag -eq 'UL' -or $subTag -eq 'OL') {
                Convert-ListNode -Node $sub -State $State -Depth ($Depth + 1)
            }
        }
    }
}

function Convert-TableNode {
    param($Node, $State)

    $rows = @()
    foreach ($tr in (Get-ChildNodeList $Node)) {
        if ($tr.nodeType -ne 1) { continue }
        $tag = Get-TagName $tr
        if ($tag -eq 'THEAD' -or $tag -eq 'TBODY' -or $tag -eq 'TFOOT') {
            foreach ($inner in (Get-ChildNodeList $tr)) {
                if ($inner.nodeType -eq 1 -and (Get-TagName $inner) -eq 'TR') { $rows += $inner }
            }
            continue
        }
        if ($tag -eq 'TR') { $rows += $tr }
    }
    if ($rows.Count -eq 0) { return }

    Add-Blank $State
    $first = $true
    foreach ($row in $rows) {
        $cells = @()
        foreach ($cell in (Get-ChildNodeList $row)) {
            if ($cell.nodeType -ne 1) { continue }
            $cellTag = Get-TagName $cell
            if ($cellTag -ne 'TD' -and $cellTag -ne 'TH') { continue }
            $cells += ((Get-InlineMarkdown -Node $cell -State $State) -replace "`n", ' ').Trim()
        }
        if ($cells.Count -eq 0) { continue }
        Add-Line $State ('| ' + ($cells -join ' | ') + ' |')
        if ($first) {
            Add-Line $State ('|' + (@('---') * $cells.Count -join '|') + '|')
            $first = $false
        }
    }
    Add-Blank $State
}

function Convert-BlockNode {
    param($Node, $State)

    foreach ($child in (Get-ChildNodeList $Node)) {

        if ($child.nodeType -eq 3) {
            $value = ([string]$child.nodeValue)
            if ($value.Trim()) {
                Add-Line $State ($value -replace ([string][char]0x00A0), ' ').Trim()
                Add-Blank $State
            }
            continue
        }
        if ($child.nodeType -ne 1) { continue }

        $tag = Get-TagName $child

        switch -Regex ($tag) {

            '^(UL|OL)$' {
                Add-Blank $State
                Convert-ListNode -Node $child -State $State -Depth 0
                Add-Blank $State
            }

            '^H[1-6]$' {
                $level = [int]$tag.Substring(1)
                $text  = ((Get-InlineMarkdown -Node $child -State $State) -replace "`n", ' ').Trim()
                if ($text) {
                    Add-Blank $State
                    Add-Line $State (('#' * $level) + ' ' + $text)
                    Add-Blank $State
                }
            }

            '^(P|DIV|BLOCKQUOTE)$' {
                if (Test-HasBlockChild $child) {
                    # Container: descend. H-05, empty wrappers vanish naturally.
                    Convert-BlockNode -Node $child -State $State
                }
                else {
                    $text = (Get-InlineMarkdown -Node $child -State $State)
                    if ($text.Trim()) {
                        $prefix = if ($tag -eq 'BLOCKQUOTE') { '> ' } else { '' }
                        foreach ($line in @($text -split "`n")) {
                            if ($line.Trim()) { Add-Line $State ($prefix + $line.Trim()) }
                        }
                        Add-Blank $State
                    }
                }
            }

            '^PRE$' {
                $text = [string]$child.innerText
                if ($text) {
                    Add-Blank $State
                    Add-Line $State '```'
                    foreach ($line in @($text -split "`r?`n")) { Add-Line $State $line }
                    Add-Line $State '```'
                    Add-Blank $State
                }
            }

            '^TABLE$' { Convert-TableNode -Node $child -State $State }

            '^HR$' { Add-Blank $State; Add-Line $State '---'; Add-Blank $State }

            '^BR$' { }

            '^LI$' {
                $State.Warnings.Add("A list item was found outside any list and was kept at the top level.") | Out-Null
                Add-ListItemText $State (Get-InlineMarkdown -Node $child -State $State -SkipLists) '' '- ' 0
            }

            '^(TR|TD|TH|THEAD|TBODY|TFOOT)$' {
                Set-Failure $State ("table element '$tag' found outside a table")
            }

            default {
                if ($GRM_INLINE_TAGS -contains $tag) {
                    $text = (Get-InlineMarkdown -Node $child -State $State)
                    if ($text.Trim()) {
                        foreach ($line in @($text -split "`n")) {
                            if ($line.Trim()) { Add-Line $State $line.Trim() }
                        }
                        Add-Blank $State
                    }
                }
                else {
                    # An unknown block element may carry structure. Unwrapping it
                    # is the failure mode of H-06: no text is lost and the rule is
                    # destroyed anyway.
                    Set-Failure $State ("unsupported block element '$tag'")
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# F-08 structure verification
# ---------------------------------------------------------------------------

# Depth encoded by the indentation of a line shaped like a list item, or -1
# when the line has no such shape. This recognizes a shape; it does not decide
# that the line came from a list.
function Get-ListLineDepth {
    param([string]$Line)
    if ($null -eq $Line) { return -1 }
    if ($Line -match '^(\s*)([-*+]|\d+\.)\s+\S') {
        return [int]([math]::Floor($Matches[1].Length / 2))
    }
    return -1
}

# Assert that every list item the converter wrote survives in the final
# Markdown, in order, with an indentation that encodes its depth. Surplus
# list-shaped lines are source text, not structure: they are returned to the
# caller for a warning and never affect the verdict.
function Test-ListStructure {
    param([string]$Markdown, $Items)

    $result = @{
        passed         = $false
        detail         = ''
        matched_depths = @()
        extra_lines    = @()
    }

    $lines = @()
    if (-not [string]::IsNullOrEmpty($Markdown)) { $lines = @($Markdown -split "`r?`n") }

    $expected = @($Items)
    $matched  = [System.Collections.Generic.List[int]]::new()
    $taken    = @{}
    $cursor   = 0

    for ($n = 0; $n -lt $expected.Count; $n++) {

        $item = $expected[$n]

        # F-08 invariant, checked on the line the converter itself wrote: two
        # spaces per level. A generator bug must not be reported as a source
        # problem.
        $written = Get-ListLineDepth ([string]$item.Line)
        if ($written -ne [int]$item.Depth) {
            $result.detail = ("list item {0} was written with an indentation that does not encode its depth {1}: '{2}'" -f $n, [int]$item.Depth, [string]$item.Line)
            return $result
        }

        $found = -1
        for ($i = $cursor; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -ceq [string]$item.Line) { $found = $i; break }
        }
        if ($found -lt 0) {
            $result.detail = ("list item {0} at depth {1} is missing from the payload: '{2}'" -f $n, [int]$item.Depth, [string]$item.Line)
            return $result
        }

        $taken[$found] = $true
        $matched.Add([int]$item.Depth) | Out-Null
        $cursor = $found + 1
    }

    $extra = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($taken.ContainsKey($i)) { continue }
        if ((Get-ListLineDepth $lines[$i]) -ge 0) { $extra.Add($lines[$i]) | Out-Null }
    }

    $result.matched_depths = @($matched.ToArray())
    $result.extra_lines    = @($extra.ToArray())
    $result.passed         = $true
    return $result
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

function ConvertTo-MarkdownFromHtml {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Html)

    $result = @{
        markdown       = ''
        passed         = $false
        detail         = ''
        source_tokens  = 0
        payload_tokens = 0
        source_depths  = @()
        payload_depths = @()
        warnings       = @()
    }

    if ([string]::IsNullOrWhiteSpace($Html)) {
        $result.detail = 'the source field is empty'
        return $result
    }

    $doc = $null
    try { $doc = New-Object -ComObject 'HTMLFile' }
    catch {
        $result.detail = 'the MSHTML component (HTMLFile) is not available in this environment'
        return $result
    }

    try {
        try {
            $doc.IHTMLDocument2_write($Html)
        }
        catch {
            # Some builds expose write() only, and it expects a byte array.
            $doc.write([System.Text.Encoding]::Unicode.GetBytes($Html))
        }
    }
    catch {
        $result.detail = 'the source HTML could not be parsed'
        return $result
    }

    $body = $null
    try { $body = $doc.body } catch { }
    if ($null -eq $body) {
        $result.detail = 'the parsed document has no body'
        return $result
    }

    $state = New-ConversionState
    Convert-BlockNode -Node $body -State $state

    $result.warnings = @($state.Warnings.ToArray())

    if ($state.Failure) {
        $result.detail = $state.Failure
        return $result
    }

    # Collapse the runs of blank lines the walk may have produced.
    $lines = @($state.Lines.ToArray())
    $clean = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if ($line -eq '' -and ($clean.Count -eq 0 -or $clean[$clean.Count - 1] -eq '')) { continue }
        $clean.Add($line) | Out-Null
    }
    while ($clean.Count -gt 0 -and $clean[$clean.Count - 1] -eq '') { $clean.RemoveAt($clean.Count - 1) }

    $markdown = ($clean -join "`n")
    $result.markdown = $markdown

    # --- F-08: structure ---------------------------------------------------
    # Evaluated first so that its warning is reported even when F-07 fails.
    $sourceDepths = [System.Collections.Generic.List[int]]::new()
    foreach ($item in $state.ListItems) { $sourceDepths.Add([int]$item.Depth) | Out-Null }
    $result.source_depths = @($sourceDepths.ToArray())

    $structure = Test-ListStructure -Markdown $markdown -Items $state.ListItems
    $result.payload_depths = @($structure.matched_depths)

    if ($structure.extra_lines.Count -gt 0) {
        $sample = [string]$structure.extra_lines[0]
        if ($sample.Length -gt 60) { $sample = $sample.Substring(0, 60) + '...' }
        $note = ''
        if ($state.ListItems.Count -eq 0) {
            # OBS-P16c-01. Zero recorded items reads as ambiguous between "the
            # source had no list" and "every list was lost". Only the first can
            # occur, and saying so is the difference between a structure that
            # was verified and one that never existed: a hierarchy flattened
            # before the HTML was stored is invisible to F-08 by construction.
            $note = ' The source contains no list at all, so no nesting was verified. Any hierarchy this text once had was flattened before the HTML was stored and cannot be detected or recovered here.'
        }
        $state.Warnings.Add(("F-08: {0} line(s) in the payload look like list items but do not come from a list in the source. The source writes them as plain text; they were copied verbatim and are not part of the structure check. First one: '{1}'.{2}" -f $structure.extra_lines.Count, $sample, $note)) | Out-Null
    }

    $result.warnings = @($state.Warnings.ToArray())

    # --- F-07: textual completeness ---------------------------------------
    $sourceText = ''
    try { $sourceText = [string]$body.innerText } catch { }
    $sourceTokens  = Get-PbiTextTokens $sourceText
    $payloadTokens = Get-PbiTextTokens $markdown

    $result.source_tokens  = $sourceTokens.Count
    $result.payload_tokens = $payloadTokens.Count

    if ($sourceTokens.Count -ne $payloadTokens.Count) {
        $result.detail = ("token count differs, {0} in the source and {1} in the payload" -f $sourceTokens.Count, $payloadTokens.Count)
        return $result
    }
    for ($i = 0; $i -lt $sourceTokens.Count; $i++) {
        if ($sourceTokens[$i] -cne $payloadTokens[$i]) {
            $result.detail = ("token {0} differs, source '{1}' and payload '{2}'" -f $i, $sourceTokens[$i], $payloadTokens[$i])
            return $result
        }
    }

    if (-not $structure.passed) {
        $result.detail = $structure.detail
        return $result
    }

    $result.passed = $true
    return $result
}

# ---------------------------------------------------------------------------
# Standalone mode (D-P13-01). Dot-sourcing with no arguments runs nothing.
# ---------------------------------------------------------------------------

if ($HtmlPath -or $HtmlText) {

    $input_ = $HtmlText
    if ($HtmlPath) {
        if (-not (Test-Path $HtmlPath)) {
            [Console]::Error.WriteLine("File not found: $HtmlPath")
            exit 1
        }
        $input_ = Get-Content -Path $HtmlPath -Encoding UTF8 -Raw
    }

    $r = ConvertTo-MarkdownFromHtml -Html $input_

    foreach ($w in $r.warnings) { [Console]::Error.WriteLine("warning: $w") }

    if (-not $r.passed) {
        [Console]::Error.WriteLine("Conversion verification failed: " + $r.detail)
        exit 1
    }

    [Console]::Error.WriteLine(("tokens: {0}  list items: {1}" -f $r.payload_tokens, $r.payload_depths.Count))
    Write-Output $r.markdown
    exit 0
}