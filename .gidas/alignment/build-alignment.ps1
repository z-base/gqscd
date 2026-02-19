$ErrorActionPreference = 'Stop'

$root = Resolve-Path '.'
$outDir = Join-Path $root '.gidas\alignment'

function Normalize-Text {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  $decoded = [System.Net.WebUtility]::HtmlDecode($Text)
  $noTags = $decoded -replace '<[^>]+>', ' '
  ($noTags -replace '\s+', ' ').Trim()
}

function Normalize-Term {
  param([string]$Text)
  $t = Normalize-Text $Text
  $t = $t.ToLowerInvariant()
  $t = $t -replace '[_-]+', ' '
  $t = $t -replace '[^a-z0-9 ]', ' '
  $t = ($t -replace '\s+', ' ').Trim()
  if ($t.Length -gt 3 -and $t.EndsWith('s')) {
    $t = $t.Substring(0, $t.Length - 1)
  }
  return $t
}

function Slugify {
  param([string]$Text)
  $t = Normalize-Text $Text
  $t = $t.ToLowerInvariant()
  $t = $t -replace '[^a-z0-9 ]', ' '
  $t = ($t -replace '\s+', '-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($t)) { return 'unspecified-term' }
  return $t
}

function Hash-Text {
  param([string]$Text)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
  }
  finally {
    $sha.Dispose()
  }
}

function Extract-SectionStarts {
  param([string]$Raw)
  $sections = @()
  $matches = [regex]::Matches($Raw, '<section\b([^>]*)>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  foreach ($m in $matches) {
    $attrs = $m.Groups[1].Value
    $idMatch = [regex]::Match($attrs, 'id\s*=\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $id = if ($idMatch.Success) { $idMatch.Groups[1].Value } else { $null }
    $sections += [ordered]@{
      index = $m.Index
      id = $id
    }
  }
  return $sections
}

function Get-Nearest-SectionId {
  param($Sections, [int]$Position)
  $candidates = $Sections | Where-Object { $_.index -le $Position -and $_.id }
  if ($candidates.Count -eq 0) { return 'unspecified' }
  return $candidates[-1].id
}

function Extract-Terms {
  param([string]$Raw, $Sections)
  $terms = @()
  $matches = [regex]::Matches(
    $Raw,
    '<dt>\s*<dfn(?<attrs>[^>]*)>(?<term>.*?)</dfn>.*?</dt>\s*<dd>(?<def>.*?)</dd>',
    [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )

  foreach ($m in $matches) {
    $attrs = $m.Groups['attrs'].Value
    $termText = Normalize-Text $m.Groups['term'].Value
    $defText = Normalize-Text $m.Groups['def'].Value
    if ([string]::IsNullOrWhiteSpace($termText)) { continue }

    $idMatch = [regex]::Match($attrs, 'id\s*=\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $termId = if ($idMatch.Success) { $idMatch.Groups[1].Value } else { Slugify $termText }
    $sectionId = Get-Nearest-SectionId -Sections $Sections -Position $m.Index

    $terms += [ordered]@{
      term_text = $termText
      term_id = $termId
      anchor = "#$termId"
      section_anchor = "#$sectionId"
      definition_excerpt_hash = Hash-Text (Normalize-Term $defText)
      definition_text_excerpt = if ($defText.Length -gt 300) { $defText.Substring(0, 300) } else { $defText }
    }
  }

  return $terms
}

function Extract-Clauses {
  param([string]$Raw, $Sections)
  $clauses = @()
  $idMatches = [regex]::Matches($Raw, 'id\s*=\s*"(?<id>(?:req-[a-z0-9-]+|REQ-[A-Z0-9-]+))"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

  foreach ($m in $idMatches) {
    $anchorId = $m.Groups['id'].Value
    $start = $m.Index
    $len = [Math]::Min(1600, $Raw.Length - $start)
    $snippet = $Raw.Substring($start, $len)

    $endMatch = [regex]::Match($snippet, '</(?:p|li|span|div|td)>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($endMatch.Success) {
      $snippet = $snippet.Substring(0, $endMatch.Index + $endMatch.Length)
    }

    $reqMatch = [regex]::Match($snippet, 'REQ-[A-Z0-9-]+')
    $clauseId = if ($reqMatch.Success) { $reqMatch.Value } else { Anchor-To-ReqId $anchorId }
    if (-not $clauseId) { continue }

    $text = Normalize-Text $snippet
    $norm = Normalize-Term $text
    $keywords = @('MUST NOT','SHOULD NOT','NOT RECOMMENDED','RECOMMENDED','MUST','SHOULD','MAY','OPTIONAL','REQUIRED') |
      Where-Object { $text -match [regex]::Escape($_) }
    $sectionId = Get-Nearest-SectionId -Sections $Sections -Position $m.Index

    $clauses += [ordered]@{
      clause_id = $clauseId
      anchor = "#$anchorId"
      section_anchor = "#$sectionId"
      kind = 'requirement'
      normative_keywords_used = $keywords
      text_excerpt_hash = Hash-Text $norm
    }
  }

  return $clauses
}

function Extract-CrossSpecRefs {
  param([string]$Raw)
  $refs = @()

  $hrefMatches = [regex]::Matches($Raw, 'href\s*=\s*"([^"]*(?:z-base\.github\.io\/(?:gdis|gqscd|gqts)\/?[^\"]*))"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  foreach ($m in $hrefMatches) {
    $refs += [ordered]@{ type = 'href'; value = $m.Groups[1].Value }
  }

  $labelMatches = [regex]::Matches($Raw, '\[(GDIS-CORE|GQSCD-CORE|GQTS-CORE)\]')
  foreach ($m in $labelMatches) {
    $refs += [ordered]@{ type = 'label'; value = $m.Groups[1].Value }
  }

  $refs | Sort-Object type, value -Unique
}

function Anchor-To-ReqId {
  param([string]$AnchorId)
  if ($AnchorId -match '^REQ-[A-Z0-9-]+$') {
    return $AnchorId
  }
  if ($AnchorId -match '^(?i:req-[a-z0-9-]+)$') {
    return ('REQ-' + $AnchorId.Substring(4).ToUpperInvariant())
  }
  return $null
}

function Get-MapKeys {
  param($Object)
  if ($null -eq $Object) { return @() }
  if ($Object -is [System.Collections.IDictionary]) {
    return @($Object.Keys)
  }
  return @($Object.PSObject.Properties.Name)
}

function Get-MapValue {
  param($Object, [string]$Key)
  if ($null -eq $Object) { return $null }
  if ($Object -is [System.Collections.IDictionary]) {
    return $Object[$Key]
  }
  return $Object.$Key
}

function Parse-OpenApi {
  param([string]$Path)

  if (-not (Test-Path $Path)) { return $null }
  $raw = Get-Content -Raw $Path

  $hasConvert = $null -ne (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)
  if (-not $hasConvert) {
    $lines = $raw -split "`r?`n"
    $operations = @()
    $schemas = @()
    $currentPath = $null
    $currentMethod = $null
    $currentOperationId = $null
    $currentReqs = @()
    $lastReqFieldWasList = $false

    $buildParsedOperation = {
      param(
        [string]$PathName,
        [string]$MethodName,
        [string]$OperationId,
        $Requirements
      )
      if (-not $PathName -or -not $MethodName) { return }
      $reqSet = @($Requirements | Where-Object { $_ } | Sort-Object -Unique)
      $contract = "{0}|{1}|{2}|{3}" -f $MethodName.ToUpperInvariant(), $PathName, [string]$OperationId, ($reqSet -join ',')
      return [ordered]@{
        operationId = [string]$OperationId
        method = $MethodName.ToUpperInvariant()
        path = $PathName
        x_requirement = $reqSet
        request_media_types = @()
        response_media_types = @()
        contract_hash = Hash-Text $contract
      }
    }

    foreach ($line in $lines) {
      if ($line -match '^  (/.+):\s*$') {
        $op = & $buildParsedOperation -PathName $currentPath -MethodName $currentMethod -OperationId $currentOperationId -Requirements $currentReqs
        if ($op) { $operations += $op }
        $currentPath = $Matches[1]
        $currentMethod = $null
        $currentOperationId = $null
        $currentReqs = @()
        $lastReqFieldWasList = $false
        continue
      }

      if ($line -match '^    (get|post|put|delete|patch|options|head|trace):\s*$') {
        $op = & $buildParsedOperation -PathName $currentPath -MethodName $currentMethod -OperationId $currentOperationId -Requirements $currentReqs
        if ($op) { $operations += $op }
        $currentMethod = $Matches[1]
        $currentOperationId = $null
        $currentReqs = @()
        $lastReqFieldWasList = $false
        continue
      }

      if (-not $currentMethod) { continue }

      if ($line -match '^      operationId:\s*([A-Za-z0-9._-]+)\s*$') {
        $currentOperationId = $Matches[1]
        continue
      }

      if ($line -match '^      x-[a-z0-9-]*requirements?:\s*(.*)\s*$') {
        $value = $Matches[1].Trim()
        $lastReqFieldWasList = [string]::IsNullOrWhiteSpace($value)
        if (-not $lastReqFieldWasList -and $value -match 'REQ-[A-Z0-9-]+') {
          $currentReqs += ([regex]::Matches($value, 'REQ-[A-Z0-9-]+') | ForEach-Object { $_.Value })
        }
        continue
      }

      if ($lastReqFieldWasList -and $line -match '^        -\s*(REQ-[A-Z0-9-]+)\s*$') {
        $currentReqs += $Matches[1]
        continue
      }
    }

    $op = & $buildParsedOperation -PathName $currentPath -MethodName $currentMethod -OperationId $currentOperationId -Requirements $currentReqs
    if ($op) { $operations += $op }

    # Minimal schema-name extraction fallback when YAML cmdlets are unavailable.
    $inSchemas = $false
    foreach ($line in $lines) {
      if ($line -match '^  schemas:\s*$') {
        $inSchemas = $true
        continue
      }
      if ($inSchemas -and $line -match '^  [a-zA-Z]') {
        $inSchemas = $false
      }
      if ($inSchemas -and $line -match '^    ([A-Za-z0-9_.-]+):\s*$') {
        $name = $Matches[1]
        $schemas += [ordered]@{
          name = $name
          json_pointer = "#/components/schemas/$name"
          key_constraints_hash = Hash-Text $name
        }
      }
    }

    return [ordered]@{
      operations = $operations
      schemas = $schemas
      note = 'Parsed with regex fallback (ConvertFrom-Yaml unavailable).'
    }
  }

  $doc = $raw | ConvertFrom-Yaml

  $operations = @()
  if ($doc.paths) {
    foreach ($pathName in (Get-MapKeys $doc.paths)) {
      $pathObj = Get-MapValue -Object $doc.paths -Key $pathName
      foreach ($method in @('get','post','put','delete','patch','options','head','trace')) {
        $op = Get-MapValue -Object $pathObj -Key $method
        if ($null -eq $op) { continue }

        $reqFields = @(Get-MapKeys $op | Where-Object { $_ -match '^x-.*requirement' })
        $reqs = @()
        foreach ($rf in $reqFields) {
          $value = Get-MapValue -Object $op -Key $rf
          if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            foreach ($v in $value) { if ($v) { $reqs += [string]$v } }
          }
          elseif ($value) {
            $reqs += [string]$value
          }
        }

        $reqMedia = @()
        $requestBody = Get-MapValue -Object $op -Key 'requestBody'
        $requestContent = if ($requestBody) { Get-MapValue -Object $requestBody -Key 'content' } else { $null }
        if ($requestContent) {
          $reqMedia += Get-MapKeys $requestContent
        }

        $respMedia = @()
        $responses = Get-MapValue -Object $op -Key 'responses'
        if ($responses) {
          foreach ($respCode in (Get-MapKeys $responses)) {
            $respObj = Get-MapValue -Object $responses -Key $respCode
            $respContent = if ($respObj) { Get-MapValue -Object $respObj -Key 'content' } else { $null }
            if ($respContent) { $respMedia += Get-MapKeys $respContent }
          }
        }

        $operationId = [string](Get-MapValue -Object $op -Key 'operationId')
        $contract = "{0}|{1}|{2}|{3}|{4}" -f $method.ToUpperInvariant(), $pathName, $operationId, (($reqMedia | Sort-Object -Unique) -join ','), (($respMedia | Sort-Object -Unique) -join ',')

        $operations += [ordered]@{
          operationId = $operationId
          method = $method.ToUpperInvariant()
          path = $pathName
          x_requirement = ($reqs | Where-Object { $_ } | Sort-Object -Unique)
          request_media_types = ($reqMedia | Sort-Object -Unique)
          response_media_types = ($respMedia | Sort-Object -Unique)
          contract_hash = Hash-Text $contract
        }
      }
    }
  }

  $schemas = @()
  if ($doc.components -and $doc.components.schemas) {
    foreach ($schemaName in (Get-MapKeys $doc.components.schemas)) {
      $schemaValue = Get-MapValue -Object $doc.components.schemas -Key $schemaName
      $json = $schemaValue | ConvertTo-Json -Compress -Depth 40
      $schemas += [ordered]@{
        name = $schemaName
        json_pointer = "#/components/schemas/$schemaName"
        key_constraints_hash = Hash-Text $json
      }
    }
  }

  return [ordered]@{
    operations = $operations
    schemas = $schemas
  }
}

function Build-SpecIndex {
  param(
    [string]$SpecId,
    [string]$Repo,
    [string]$IndexPath,
    [string]$OpenApiPath,
    [string]$AgentsPath
  )

  if (-not (Test-Path $IndexPath)) {
    throw "Missing index.html at $IndexPath"
  }

  $raw = Get-Content -Raw $IndexPath
  $sections = Extract-SectionStarts $raw

  $index = [ordered]@{
    spec_id = $SpecId
    repo = $Repo
    commit_or_version = 'unspecified'
    files = [ordered]@{
      index_html = (Resolve-Path $IndexPath).Path
      openapi_yaml = if ($OpenApiPath -and (Test-Path $OpenApiPath)) { (Resolve-Path $OpenApiPath).Path } else { $null }
      agents_md = if ($AgentsPath -and (Test-Path $AgentsPath)) { (Resolve-Path $AgentsPath).Path } else { $null }
    }
    terms = Extract-Terms -Raw $raw -Sections $sections
    clauses = Extract-Clauses -Raw $raw -Sections $sections
    cross_spec_references = Extract-CrossSpecRefs -Raw $raw
    openapi = Parse-OpenApi -Path $OpenApiPath
  }

  return [ordered]@{
    index = $index
    raw = $raw
  }
}

function Determine-CanonicalOwner {
  param(
    [string]$NormalizedTerm,
    $Members,
    $SpecRawMap
  )

  if ($NormalizedTerm -match '(device|controller|signature creation|attestation|qscd|sole control|user intent|secure boot|trusted execution)') {
    return 'GQSCD-CORE'
  }
  if ($NormalizedTerm -match '(identity|pid|mrz|binding|binding credential|proof artifact|issuance|physical|gdis)') {
    return 'GDIS-CORE'
  }
  if ($NormalizedTerm -match '(event|log|replication|publication|verification material|descriptor|governance code|head digest|mechanical validity|did document|key history|status|gqts)') {
    return 'GQTS-CORE'
  }

  $bestSpec = $Members[0].spec_id
  $bestCount = -1
  foreach ($m in $Members) {
    $raw = $SpecRawMap[$m.spec_id]
    $term = [regex]::Escape($m.term_text)
    $count = [regex]::Matches($raw, $term, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
    if ($count -gt $bestCount) {
      $bestCount = $count
      $bestSpec = $m.spec_id
    }
  }

  return $bestSpec
}

$selfSpec = [ordered]@{
  spec_id = 'GQSCD-CORE'
  repo = 'z-base/gqscd'
  index_path = Join-Path $root 'index.html'
  openapi_path = Join-Path $root 'openapi.yaml'
  agents_path = Join-Path $root 'AGENTS.md'
}

$peerSpecs = @(
  [ordered]@{
    spec_id = 'GDIS-CORE'
    repo = 'z-base/gdis'
    index_path = Join-Path $root '..\gdis\index.html'
    openapi_path = Join-Path $root '..\gdis\openapi.yaml'
    agents_path = Join-Path $root '..\gdis\AGENTS.md'
  },
  [ordered]@{
    spec_id = 'GQTS-CORE'
    repo = 'z-base/gqts'
    index_path = Join-Path $root '..\gqts\index.html'
    openapi_path = Join-Path $root '..\gqts\openapi.yaml'
    agents_path = Join-Path $root '..\gqts\AGENTS.md'
  }
)

$missing = @()
foreach ($peer in $peerSpecs) {
  if (-not (Test-Path $peer.index_path)) {
    $missing += "Missing peer index: $($peer.index_path)"
  }
}

if ($missing.Count -gt 0) {
  $report = @()
  $report += '# Alignment Report'
  $report += ''
  $report += 'Peer snapshot loading failed. Alignment halted.'
  $report += ''
  $report += '## Missing inputs'
  foreach ($m in $missing) { $report += "- $m" }
  $report += ''
  $report += 'Provide the missing peer snapshots and rerun.'

  $reportPath = Join-Path $outDir 'alignment-report.md'
  Set-Content -Path $reportPath -Value ($report -join "`n") -Encoding utf8
  exit 0
}

$selfBuilt = Build-SpecIndex -SpecId $selfSpec.spec_id -Repo $selfSpec.repo -IndexPath $selfSpec.index_path -OpenApiPath $selfSpec.openapi_path -AgentsPath $selfSpec.agents_path
$peerBuilt = @()
foreach ($peer in $peerSpecs) {
  $peerBuilt += (Build-SpecIndex -SpecId $peer.spec_id -Repo $peer.repo -IndexPath $peer.index_path -OpenApiPath $peer.openapi_path -AgentsPath $peer.agents_path)
}

$selfIndex = $selfBuilt.index
$peerIndexes = @($peerBuilt | ForEach-Object { $_.index })

$selfPath = Join-Path $outDir 'spec-index.self.json'
$peerPath = Join-Path $outDir 'spec-index.peers.json'

$selfIndex | ConvertTo-Json -Depth 40 | Set-Content -Path $selfPath -Encoding utf8
$peerIndexes | ConvertTo-Json -Depth 40 | Set-Content -Path $peerPath -Encoding utf8

$allIndexes = @($selfIndex) + $peerIndexes
$rawBySpec = @{}
$rawBySpec[$selfIndex.spec_id] = $selfBuilt.raw
foreach ($p in $peerBuilt) {
  $rawBySpec[$p.index.spec_id] = $p.raw
}

# Term clustering
$termClusters = @{}
foreach ($idx in $allIndexes) {
  foreach ($term in $idx.terms) {
    $norm = Normalize-Term $term.term_text
    if (-not $termClusters.ContainsKey($norm)) {
      $termClusters[$norm] = @()
    }
    $termClusters[$norm] += [ordered]@{
      spec_id = $idx.spec_id
      term_text = $term.term_text
      anchor = $term.anchor
      term_id = $term.term_id
      definition_excerpt_hash = $term.definition_excerpt_hash
    }
  }
}

$canonicalTerms = @()
$termConflicts = @()
foreach ($entry in $termClusters.GetEnumerator() | Sort-Object Name) {
  $members = @($entry.Value)
  $specCount = (@($members.spec_id | Sort-Object -Unique)).Count
  if ($specCount -lt 2) { continue }

  $owner = Determine-CanonicalOwner -NormalizedTerm $entry.Name -Members $members -SpecRawMap $rawBySpec
  $ownerMember = $members | Where-Object { $_.spec_id -eq $owner } | Select-Object -First 1
  if ($null -eq $ownerMember) {
    $ownerMember = $members[0]
    $owner = $ownerMember.spec_id
  }

  $hashes = @($members.definition_excerpt_hash | Where-Object { $_ } | Sort-Object -Unique)
  if ($hashes.Count -gt 1) {
    $termConflicts += [ordered]@{
      type = 'term-definition-conflict'
      normalized_term = $entry.Name
      member_specs = @($members.spec_id | Sort-Object -Unique)
      definition_hashes = $hashes
    }
  }

  $canonicalTerms += [ordered]@{
    canonical_term = $ownerMember.term_text
    canonical_owner_spec_id = $owner
    canonical_anchor = "$owner$($ownerMember.anchor)"
    aliases = @($members.term_text | Sort-Object -Unique)
    members = $members
  }
}

# Canonical ownership overrides required by cross-spec posture.
$canonicalTerms += @(
  [ordered]@{
    canonical_term = 'proof artifact'
    canonical_owner_spec_id = 'GDIS-CORE'
    canonical_anchor = 'GDIS-CORE#evidence-artifact'
    aliases = @('proof artifact', 'evidence artifact')
    members = @()
  },
  [ordered]@{
    canonical_term = 'binding credential'
    canonical_owner_spec_id = 'GDIS-CORE'
    canonical_anchor = 'GDIS-CORE#gdis-binding-credential'
    aliases = @('binding credential', 'gdis binding credential')
    members = @()
  },
  [ordered]@{
    canonical_term = 'verification material'
    canonical_owner_spec_id = 'GQTS-CORE'
    canonical_anchor = 'GQTS-CORE#history-invariants'
    aliases = @('verification material')
    members = @()
  }
)

$canonicalTerms = @(
  $canonicalTerms |
    Sort-Object canonical_term, canonical_owner_spec_id
)

# Clause mapping and OpenAPI requirement namespace conflicts
$canonicalClauses = @()
$openapiConflicts = @()
$opsBySignature = @{}

foreach ($idx in $allIndexes) {
  if ($null -eq $idx.openapi -or $null -eq $idx.openapi.operations) { continue }
  foreach ($op in $idx.openapi.operations) {
    $sig = "$($op.method) $($op.path) | $($op.operationId)"
    if (-not $opsBySignature.ContainsKey($sig)) {
      $opsBySignature[$sig] = @()
    }
    $opsBySignature[$sig] += [ordered]@{
      spec_id = $idx.spec_id
      method = $op.method
      path = $op.path
      operationId = $op.operationId
      x_requirement = $op.x_requirement
      contract_hash = $op.contract_hash
    }
  }
}

foreach ($entry in $opsBySignature.GetEnumerator() | Sort-Object Name) {
  $members = @($entry.Value)
  if ((@($members.spec_id | Sort-Object -Unique)).Count -lt 2) { continue }

  $canonicalOwner = if (($members.spec_id -contains 'GQTS-CORE') -and $members[0].path -like '/.well-known/gidas/gqts/*') { 'GQTS-CORE' } else { $members[0].spec_id }
  $canonicalReq = @($members | Where-Object { $_.spec_id -eq $canonicalOwner } | Select-Object -First 1).x_requirement

  $canonicalClauses += [ordered]@{
    clause_concept = $entry.Name
    canonical_owner_spec_id = $canonicalOwner
    canonical_clause_id = ($canonicalReq | Select-Object -First 1)
    member_clause_ids = @($members | ForEach-Object { $_.x_requirement } | Where-Object { $_ } | Select-Object -Unique)
    members = $members
  }

  $allReqs = @($members | ForEach-Object { $_.x_requirement } | Where-Object { $_ } | Select-Object -Unique)
  $allHashes = @($members.contract_hash | Sort-Object -Unique)
  if ($allReqs.Count -gt 1) {
      $openapiConflicts += [ordered]@{
        type = 'requirement-id-namespace-conflict'
        operation = $entry.Name
        requirements = $allReqs
        member_specs = @($members.spec_id | Sort-Object -Unique)
      }
  }
  if ($allHashes.Count -gt 1) {
    $openapiConflicts += [ordered]@{
      type = 'operation-contract-conflict'
      operation = $entry.Name
      member_specs = @($members.spec_id | Sort-Object -Unique)
      contract_hashes = $allHashes
    }
  }
}

# Gaps
$allNormalizedTerms = @($termClusters.Keys)
$gaps = @()
foreach ($idx in $allIndexes) {
  $raw = $rawBySpec[$idx.spec_id]

  $termUseMatches = [regex]::Matches($raw, '\[=([^\]]+)=\]')
  foreach ($m in $termUseMatches) {
    $used = $m.Groups[1].Value
    $norm = Normalize-Term $used
    if ($norm -and -not ($allNormalizedTerms -contains $norm)) {
      $gaps += [ordered]@{
        type = 'undefined-term'
        spec_id = $idx.spec_id
        term_used = $used
      }
    }
  }

  $knownReqIds = @()
  foreach ($cl in $idx.clauses) {
    if ($cl.clause_id -like 'REQ-*') { $knownReqIds += $cl.clause_id }
    $anchorRaw = ($cl.anchor -replace '^#', '')
    $anchorReq = Anchor-To-ReqId $anchorRaw
    if ($anchorReq) { $knownReqIds += $anchorReq }
  }
  $knownReqIds = @($knownReqIds | Sort-Object -Unique)
  $mentionedReqs = @([regex]::Matches($raw, 'REQ-[A-Z0-9-]+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
  foreach ($rid in $mentionedReqs) {
    if (-not ($knownReqIds -contains $rid)) {
      $gaps += [ordered]@{
        type = 'requirement-reference-without-anchor'
        spec_id = $idx.spec_id
        requirement_id = $rid
      }
    }
  }
}

$gaps = @(
  $gaps |
    Sort-Object type, spec_id, term_used, requirement_id -Unique
)

$crossSpecMap = [ordered]@{
  canonical_terms = $canonicalTerms
  canonical_clauses = $canonicalClauses
  conflicts = @($termConflicts + $openapiConflicts)
  gaps = $gaps
}

$crossPath = Join-Path $outDir 'cross-spec-map.json'
$crossSpecMap | ConvertTo-Json -Depth 50 | Set-Content -Path $crossPath -Encoding utf8

$report = @()
$report += '# Alignment Report'
$report += ''
$report += "Self spec: $($selfIndex.spec_id)"
$report += "Peers loaded: $($peerIndexes.Count)"
$report += ''
$report += '## Extraction Summary'
$report += "- Self terms: $($selfIndex.terms.Count)"
$report += "- Self clauses: $($selfIndex.clauses.Count)"
$report += "- Self OpenAPI operations: $(if ($selfIndex.openapi) { $selfIndex.openapi.operations.Count } else { 0 })"
$report += "- Peer terms: $(($peerIndexes | ForEach-Object { $_.terms.Count } | Measure-Object -Sum).Sum)"
$report += "- Peer clauses: $(($peerIndexes | ForEach-Object { $_.clauses.Count } | Measure-Object -Sum).Sum)"
$report += ''
$report += '## Key conflicts found'
if (($crossSpecMap.conflicts | Measure-Object).Count -eq 0) {
  $report += '- None.'
}
else {
  foreach ($c in $crossSpecMap.conflicts) {
    if ($c.type -eq 'requirement-id-namespace-conflict') {
      $report += "- requirement-id-namespace-conflict: $($c.operation) => $([string]::Join(', ', $c.requirements))"
    }
    elseif ($c.type -eq 'operation-contract-conflict') {
      $report += "- operation-contract-conflict: $($c.operation)"
    }
    elseif ($c.type -eq 'term-definition-conflict') {
      $report += "- term-definition-conflict: $($c.normalized_term)"
    }
    else {
      $report += "- $($c.type)"
    }
  }
}
$report += ''
$report += '## Remaining gaps'
if (($crossSpecMap.gaps | Measure-Object).Count -eq 0) {
  $report += '- None.'
}
else {
  foreach ($g in $crossSpecMap.gaps) {
    if ($g.type -eq 'undefined-term') {
      $report += "- undefined-term: $($g.spec_id) uses '$($g.term_used)' without a known definition."
    }
    elseif ($g.type -eq 'requirement-reference-without-anchor') {
      $report += "- requirement-reference-without-anchor: $($g.spec_id) references $($g.requirement_id) without a stable clause anchor."
    }
    else {
      $report += "- $($g.type)"
    }
  }
}
$report += ''
$report += '## Self-repo edit plan'
$report += '- Add `localBiblio` entries for GDIS-CORE, GQSCD-CORE, GQTS-CORE in `index.html`.'
$report += '- Add explicit stable IDs for cross-spec terms in this repo (`web profile`, `eu compatibility profile`).'
$report += '- No SELF OpenAPI ownership edits needed in this run (SELF has no GQTS-hosted endpoint definitions).'
$report += ''
$report += '## Changed files'
$report += '- Pending update after applying edits.'

$reportPath = Join-Path $outDir 'alignment-report.md'
Set-Content -Path $reportPath -Value ($report -join "`n") -Encoding utf8

Write-Output "Generated: $selfPath"
Write-Output "Generated: $peerPath"
Write-Output "Generated: $crossPath"
Write-Output "Generated: $reportPath"
