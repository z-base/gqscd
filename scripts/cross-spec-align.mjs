import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { spawnSync } from 'node:child_process'

const root = process.cwd()
const configPath = resolve(root, 'gidas-alignment.config.json')
const agentsPath = resolve(root, 'AGENTS.md')
const buildScriptPath = resolve(root, '.gidas/alignment/build-alignment.ps1')

function toAbs(pathLike) {
  return resolve(root, pathLike)
}

function writeFailureReport(outDir, title, missingItems) {
  mkdirSync(outDir, { recursive: true })
  const lines = [
    '# Alignment Report',
    '',
    title,
    '',
    '## Missing inputs',
    ...missingItems.map((item) => `- ${item}`),
    '',
    'Provide the missing inputs and rerun `node scripts/cross-spec-align.mjs`.',
  ]
  writeFileSync(resolve(outDir, 'alignment-report.md'), `${lines.join('\n')}\n`, 'utf8')
}

if (!existsSync(configPath)) {
  const outDir = resolve(root, '.gidas/alignment')
  writeFailureReport(outDir, 'Preconditions failed. Alignment halted.', [
    'Missing required alignment config: gidas-alignment.config.json',
  ])
  process.exit(1)
}

const rawConfig = readFileSync(configPath, 'utf8')
const config = JSON.parse(rawConfig)
const outDir = config.outputDir ? toAbs(config.outputDir) : resolve(root, '.gidas/alignment')

const missing = []
if (!existsSync(agentsPath)) {
  missing.push('Missing AGENTS.md in repository root')
}

const self = config.self ?? {}
const peers = Array.isArray(config.peers) ? config.peers : []

for (const [label, p] of [
  ['SELF index', self.indexPath],
  ['SELF OpenAPI', self.openapiPath],
  ['SELF AGENTS', self.agentsPath],
]) {
  if (!p || !existsSync(toAbs(p))) {
    missing.push(`Missing ${label}: ${p ?? '(unset)'}`)
  }
}

if (peers.length === 0) {
  missing.push('No peer snapshot entries in gidas-alignment.config.json')
}

for (const peer of peers) {
  const specId = peer.specId ?? 'UNSPECIFIED-PEER'
  const indexPath = peer.indexPath
  if (!indexPath || !existsSync(toAbs(indexPath))) {
    missing.push(`Missing peer index (${specId}): ${indexPath ?? '(unset)'}`)
  }
  const openapiPath = peer.openapiPath
  if (!openapiPath || !existsSync(toAbs(openapiPath))) {
    missing.push(`Missing peer OpenAPI (${specId}): ${openapiPath ?? '(unset)'}`)
  }
}

if (missing.length > 0) {
  writeFailureReport(outDir, 'Peer snapshot loading failed. Alignment halted.', missing)
  process.exit(1)
}

if (!existsSync(buildScriptPath)) {
  writeFailureReport(outDir, 'Alignment build script missing. Alignment halted.', [
    'Missing required script: .gidas/alignment/build-alignment.ps1',
  ])
  process.exit(1)
}

const shell = process.platform === 'win32' ? 'powershell' : 'pwsh'
const run = spawnSync(
  shell,
  ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', buildScriptPath],
  {
    cwd: root,
    stdio: 'inherit',
  }
)

if (run.error) {
  throw run.error
}

process.exit(run.status ?? 1)
