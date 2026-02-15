#!/usr/bin/env node
import { exec } from 'child_process';
import { writeFile, unlink } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { promisify } from 'util';
import readline from 'readline';

const execAsync = promisify(exec);
const MAX_BUFFER = 10 * 1024 * 1024;
const MAX_FILES_IN_BODY = 20;

const createInterface = () => readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const ask = (rl, prompt) => new Promise((resolve) => {
  rl.question(prompt, (answer) => resolve(answer.trim()));
});

const normalizeOutput = (value) => value.replace(/\s+$/, '');

const runGit = async (args, { allowFailure = false } = {}) => {
  const command = `git ${args}`;
  try {
    const { stdout, stderr } = await execAsync(command, { maxBuffer: MAX_BUFFER });
    return { stdout: normalizeOutput(stdout), stderr: normalizeOutput(stderr) };
  } catch (error) {
    const stdout = normalizeOutput(error.stdout || '');
    const stderr = normalizeOutput(error.stderr || '');
    if (!allowFailure) {
      if (stdout) process.stdout.write(`${stdout}\n`);
      if (stderr) process.stderr.write(`${stderr}\n`);
      throw new Error(`Command failed: ${command}`);
    }
    return { stdout, stderr, error };
  }
};

const parseStatus = (statusText) => statusText
  .split('\n')
  .map((line) => line.trimEnd())
  .filter(Boolean)
  .map((line) => {
    const code = line.slice(0, 2);
    let filePart = line.slice(3).trim();
    if (filePart.includes('->')) {
      filePart = filePart.split('->').pop().trim();
    }
    return { code, file: filePart };
  });

const classifyChange = (code) => {
  const primary = code[0] === ' ' ? code[1] : code[0];
  switch (primary) {
    case 'A':
    case '?':
      return 'add';
    case 'D':
      return 'remove';
    case 'R':
      return 'rename';
    case 'C':
      return 'copy';
    case 'M':
    case 'U':
    default:
      return 'update';
  }
};

const buildSubject = (entries) => {
  if (entries.length === 1) {
    const verb = classifyChange(entries[0].code);
    return `chore: ${verb} ${entries[0].file}`;
  }

  const counts = { add: 0, remove: 0, rename: 0, copy: 0, update: 0 };
  for (const entry of entries) {
    counts[classifyChange(entry.code)] += 1;
  }

  const total = entries.length;
  const onlyAdds = counts.add === total;
  const onlyRemoves = counts.remove === total;

  if (onlyAdds) {
    return `chore: add ${total} ${total === 1 ? 'file' : 'files'}`;
  }
  if (onlyRemoves) {
    return `chore: remove ${total} ${total === 1 ? 'file' : 'files'}`;
  }

  return `chore: update ${total} ${total === 1 ? 'file' : 'files'}`;
};

const buildBody = (entries) => {
  const files = entries.map((entry) => entry.file);
  if (files.length === 0) {
    return '';
  }

  const listed = files.slice(0, MAX_FILES_IN_BODY);
  const remaining = files.length - listed.length;

  const lines = ['Files:', ...listed.map((file) => `- ${file}`)];
  if (remaining > 0) {
    lines.push(`- ...and ${remaining} more`);
  }

  return lines.join('\n');
};

const generateCommitMessage = (entries) => {
  const subject = buildSubject(entries);
  const body = buildBody(entries);
  return body ? `${subject}\n\n${body}` : subject;
};

const readMultilineMessage = async (rl) => {
  console.log('Enter commit message. Finish with an empty line:');
  const lines = [];
  while (true) {
    const line = await ask(rl, '> ');
    if (!line) {
      break;
    }
    lines.push(line);
  }
  return lines.join('\n').trim();
};

const confirmMessage = async (rl, message) => {
  let current = message;
  while (true) {
    console.log(`\nProposed commit message:\n---\n${current}\n---\n`);
    const answer = (await ask(rl, 'Use this commit message? (y)es/(e)dit/(n)o: ')).toLowerCase();
    if (answer === 'y' || answer === 'yes') {
      return { confirmed: true, message: current };
    }
    if (answer === 'n' || answer === 'no') {
      return { confirmed: false, message: current };
    }
    if (answer === 'e' || answer === 'edit') {
      const edited = await readMultilineMessage(rl);
      if (edited) {
        current = edited;
      } else {
        console.log('Commit message cannot be empty.');
      }
    }
  }
};

const quotePath = (value) => `"${value.replace(/"/g, '\\"')}"`;

const main = async () => {
  try {
    await runGit('rev-parse --show-toplevel');
  } catch (error) {
    console.error('Not a git repository.');
    process.exit(1);
  }

  const status = await runGit('status --porcelain');
  if (!status.stdout) {
    console.log('No changes to commit.');
    return;
  }

  console.log(`Detected changes:\n${status.stdout}`);

  await runGit('add -A');

  const staged = await runGit('diff --cached --stat');
  if (staged.stdout) {
    console.log(`\nStaged changes:\n${staged.stdout}`);
  }

  const entries = parseStatus(status.stdout);
  const proposedMessage = generateCommitMessage(entries);

  const rl = createInterface();
  let confirmation;
  try {
    confirmation = await confirmMessage(rl, proposedMessage);
  } finally {
    rl.close();
  }

  if (!confirmation.confirmed) {
    console.log('Commit canceled.');
    return;
  }

  const messageFile = join(tmpdir(), `commit-message-${Date.now()}.txt`);
  await writeFile(messageFile, confirmation.message, 'utf8');

  try {
    await runGit(`commit -F ${quotePath(messageFile)}`);
  } finally {
    await unlink(messageFile).catch(() => {});
  }

  await runGit('push');
};

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
