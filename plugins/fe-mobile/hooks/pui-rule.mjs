#!/usr/bin/env node
// src/pui/** 파일을 Read/Edit/Write 하기 직전에 PUI 코드 컨벤션을 컨텍스트로 주입한다.
// .claude/rules 의 paths 스코프 rule(플러그인으로 배포 불가)을 대신한다.
// 세션당 한 번만 주입한다(같은 규칙을 반복해서 넣어 컨텍스트를 낭비하지 않도록).
import { readFileSync, existsSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

const PUI_PATH = /(^|\/)src\/pui\//;
const RULE_FILE = join(dirname(fileURLToPath(import.meta.url)), '..', 'rules', 'pui-code-convention.md');

let input = {};
try {
  input = JSON.parse(readFileSync(0, 'utf8') || '{}');
} catch {
  process.exit(0);
}

const filePath = input.tool_input?.file_path ?? '';
if (!PUI_PATH.test(filePath)) process.exit(0);

const markerDir = join(tmpdir(), 'fe-skills-pui-rule');
const marker = join(markerDir, String(input.session_id ?? 'unknown'));
if (existsSync(marker)) process.exit(0);

let rule;
try {
  rule = readFileSync(RULE_FILE, 'utf8').replace(/^---\n[\s\S]*?\n---\n/, '');
} catch {
  process.exit(0);
}

mkdirSync(markerDir, { recursive: true });
writeFileSync(marker, '');

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: `src/pui 파일을 다룬다. 아래 PUI 코드 컨벤션을 반드시 따른다.\n\n${rule}`,
    },
  }),
);
