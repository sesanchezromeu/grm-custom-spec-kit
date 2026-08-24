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
        Lines        = [System.Collections.Generic.List[string]]::new()
        SourceDepths = [System.Collections.Generic.List[int]]::new()
        Warnings     = [System.Collections.Generic.List[string]]::new()
        Failure      = $null
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
    param($State, [string]$Text, [string]$Indent, [string]$Marker)

    $parts = @($Text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($parts.Count -eq 0) { return }

    Add-Line $State ($Indent + $Marker + $parts[0])
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
                Add-ListItemText $State ([string]$child.nodeValue) $indent '- '
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

        # F-08: depth recorded from the DOM, not from the generated Markdown.
        $State.SourceDepths.Add($Depth) | Out-Null

        $marker = if ($ordered) { "$index. " } else { '- ' }
        $text   = Get-InlineMarkdown -Node $child -State $State -SkipLists
        Add-ListItemText $State $text $indent $marker
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
                $State.SourceDepths.Add(0) | Out-Null
                Add-ListItemText $State (Get-InlineMarkdown -Node $child -State $State -SkipLists) '' '- '
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
# Depth profile of the generated Markdown
# ---------------------------------------------------------------------------

function Get-MarkdownDepthProfile {
    param([string]$Markdown)
    $depths = [System.Collections.Generic.List[int]]::new()
    if ([string]::IsNullOrWhiteSpace($Markdown)) { return @() }
    foreach ($line in ($Markdown -split "`r?`n")) {
        if ($line -match '^(\s*)([-*+]|\d+\.)\s+\S') {
            $depths.Add([int]([math]::Floor($Matches[1].Length / 2))) | Out-Null
        }
    }
    return @($depths.ToArray())
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

    # --- F-07: textual completeness ---------------------------------------
    $sourceText = ''
    try { $sourceText = [string]$body.innerText } catch { }
    $sourceTokens  = Get-PbiTextTokens $sourceText
    $payloadTokens = Get-PbiTextTokens $markdown

    $result.source_tokens  = $sourceTokens.Count
    $result.payload_tokens = $payloadTokens.Count

    # --- F-08: structure ---------------------------------------------------
    $result.source_depths  = @($state.SourceDepths.ToArray())
    $result.payload_depths = Get-MarkdownDepthProfile $markdown

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

    if ($result.source_depths.Count -ne $result.payload_depths.Count) {
        $result.detail = ("list item count differs, {0} in the source and {1} in the payload" -f $result.source_depths.Count, $result.payload_depths.Count)
        return $result
    }
    for ($i = 0; $i -lt $result.source_depths.Count; $i++) {
        if ($result.source_depths[$i] -ne $result.payload_depths[$i]) {
            $result.detail = ("nesting depth of list item {0} differs, source {1} and payload {2}" -f $i, $result.source_depths[$i], $result.payload_depths[$i])
            return $result
        }
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