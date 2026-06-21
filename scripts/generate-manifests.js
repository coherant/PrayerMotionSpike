#!/usr/bin/env node
// Usage: node scripts/generate-manifests.js
// Parses docs/audio-manifest.md and writes JSON manifests under Resources/Audio/.

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const MANIFEST_MD = path.join(ROOT, "docs", "audio-manifest.md");
const RESOURCES_AUDIO = path.join(ROOT, "PrayerMotionSpike", "Resources", "Audio");
const RECITERS_DIR = path.join(RESOURCES_AUDIO, "Reciters");
const NARRATION_DIR = path.join(RESOURCES_AUDIO, "Narration", "en");
// Single consolidated output avoids Xcode flattening multiple manifest.json to bundle root.
const CONSOLIDATED_OUT = path.join(RESOURCES_AUDIO, "audio-manifest.json");

// ---------------------------------------------------------------------------
// Markdown table parser
// ---------------------------------------------------------------------------

function parseSection(md, heading) {
  const headingRe = new RegExp(`^## ${heading}\\s*$`, "m");
  const match = md.match(headingRe);
  if (!match) throw new Error(`Section "## ${heading}" not found in audio-manifest.md`);

  const after = md.slice(match.index);
  // Skip the heading line itself, then find the next ## section
  const firstNewline = after.indexOf("\n");
  const afterHeading = after.slice(firstNewline);
  const nextSectionPos = afterHeading.search(/^## /m);
  const section = nextSectionPos === -1 ? after : after.slice(0, firstNewline + nextSectionPos);

  const tableLines = section
    .split("\n")
    .filter((l) => l.trim().startsWith("|") && !l.trim().startsWith("|---"));

  if (tableLines.length < 2) throw new Error(`No table found under "## ${heading}"`);

  const header = tableLines[0]
    .split("|")
    .map((c) => c.trim())
    .filter(Boolean);
  const rows = tableLines.slice(1).map((line) =>
    line
      .split("|")
      .map((c) => c.trim())
      .filter(Boolean)
  );

  return { header, rows };
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

const warnings = [];
const errors = [];

function warn(msg) {
  warnings.push(`  ⚠  ${msg}`);
}

function error(msg) {
  errors.push(`  ✘  ${msg}`);
}

function checkFile(filePath, phraseKey, context) {
  if (!fs.existsSync(filePath)) {
    error(`Missing file for phrase "${phraseKey}" (${context}): ${filePath}`);
  }
}

// ---------------------------------------------------------------------------
// Build reciter manifests
// ---------------------------------------------------------------------------

function buildReciterManifests(md) {
  const { header, rows } = parseSection(md, "Reciters");

  // header[0] = "phrase_key", header[1..] = reciter ids
  const reciterIds = header.slice(1);

  // Accumulate { reciterId: { phraseKey: filename } }
  const manifests = {};
  for (const rid of reciterIds) {
    manifests[rid] = {};
  }

  for (const row of rows) {
    const phraseKey = row[0];
    if (!phraseKey) { warn("Reciters table: row with empty phrase_key, skipping"); continue; }

    for (let i = 0; i < reciterIds.length; i++) {
      const rid = reciterIds[i];
      const filename = row[i + 1] || "";
      if (!filename) {
        warn(`Reciters table: blank filename for phrase "${phraseKey}" / reciter "${rid}"`);
      }
      manifests[rid][phraseKey] = filename;

      if (filename) {
        const filePath = path.join(RECITERS_DIR, rid, "ar", filename);
        checkFile(filePath, phraseKey, `Reciters/${rid}/ar`);
      }
    }
  }

  return Object.fromEntries(
    reciterIds.map((rid) => [
      rid,
      {
        displayName: rid.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()),
        language: "ar",
        files: manifests[rid],
      },
    ])
  );
}

// ---------------------------------------------------------------------------
// Build English narration manifest
// ---------------------------------------------------------------------------

function buildNarrationManifest(md) {
  const { header, rows } = parseSection(md, "English Narration");

  const fileColumnIdx = header.findIndex((h) => h.toLowerCase() === "file");
  if (fileColumnIdx === -1) throw new Error('English Narration table must have a "File" column');

  const files = {};
  for (const row of rows) {
    const phraseKey = row[0];
    if (!phraseKey) { warn("English Narration table: row with empty phrase_key, skipping"); continue; }

    const filename = row[fileColumnIdx] || "";
    if (!filename) {
      warn(`English Narration table: blank filename for phrase "${phraseKey}"`);
    }
    files[phraseKey] = filename;

    if (filename) {
      const filePath = path.join(NARRATION_DIR, filename);
      checkFile(filePath, phraseKey, "Narration/en");
    }
  }

  return { language: "en", files };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

try {
  const md = fs.readFileSync(MANIFEST_MD, "utf8");
  console.log("\nGenerating manifests from docs/audio-manifest.md...\n");

  const reciters = buildReciterManifests(md);
  const narration = buildNarrationManifest(md);

  const consolidated = { reciters, narration: { en: narration } };
  fs.mkdirSync(RESOURCES_AUDIO, { recursive: true });
  fs.writeFileSync(CONSOLIDATED_OUT, JSON.stringify(consolidated, null, 2));
  console.log(`  Wrote ${path.relative(ROOT, CONSOLIDATED_OUT)}`);

  console.log("\nValidation:");
  if (warnings.length === 0 && errors.length === 0) {
    console.log("  ✓  No issues found.");
  } else {
    for (const w of warnings) console.warn(w);
    for (const e of errors) console.error(e);
  }

  if (errors.length > 0) {
    console.error(`\n${errors.length} error(s). Fix missing files before shipping.\n`);
    process.exit(1);
  } else {
    console.log(`\nDone. ${warnings.length} warning(s).\n`);
  }
} catch (err) {
  console.error(`\nFatal: ${err.message}\n`);
  process.exit(1);
}
