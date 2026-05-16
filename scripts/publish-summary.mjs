#!/usr/bin/env node

import { readFileSync } from 'node:fs';

const inputPath = process.argv[2];

if (!inputPath) {
  console.error('Usage: node scripts/publish-summary.mjs <publish-output.json>');
  process.exit(1);
}

const publishResult = JSON.parse(readFileSync(inputPath, 'utf8'));
const objectChanges = publishResult.objectChanges ?? [];

const getObjectId = (change) => change.objectId ?? change.packageId ?? null;

const findCreatedObject = (predicate) => {
  const match = objectChanges.find((change) => change.type === 'created' && predicate(change));
  return match ? getObjectId(match) : null;
};

const publishedPackage = objectChanges.find((change) => change.type === 'published');
const packageId = publishedPackage?.packageId ?? null;
const registryId = findCreatedObject((change) =>
  change.objectType?.endsWith('::taskform::TaskFormRegistry'),
);
const upgradeCapId = findCreatedObject((change) => change.objectType === '0x2::package::UpgradeCap');
const digest = publishResult.digest ?? publishResult.effects?.transactionDigest ?? null;

const missing = [
  ['Package ID', packageId],
  ['TaskFormRegistry', registryId],
  ['UpgradeCap', upgradeCapId],
  ['Publish digest', digest],
].filter(([, value]) => !value);

console.log('\nTaskForm publish summary');
console.log('------------------------');
console.log(`Package ID:       ${packageId ?? 'NOT FOUND'}`);
console.log(`TaskFormRegistry: ${registryId ?? 'NOT FOUND'}`);
console.log(`UpgradeCap:       ${upgradeCapId ?? 'NOT FOUND'}`);
console.log(`Publish digest:   ${digest ?? 'NOT FOUND'}`);

console.log('\nFrontend constants');
console.log('------------------');
console.log(`PACKAGE_ID = '${packageId ?? '<package-id>'}'`);
console.log(`REGISTRY_ID = '${registryId ?? '<registry-id>'}'`);

console.log('\nDocs table');
console.log('----------');
console.log(`| Package | \`${packageId ?? '<package-id>'}\` |`);
console.log(`| TaskFormRegistry | \`${registryId ?? '<registry-id>'}\` |`);
console.log(`| UpgradeCap | \`${upgradeCapId ?? '<upgrade-cap-id>'}\` |`);

console.log('\nPublished.toml');
console.log('--------------');
console.log('[published.testnet]');
console.log(`published-at = "${packageId ?? '<package-id>'}"`);

if (missing.length > 0) {
  console.error(
    `\nCould not find: ${missing.map(([label]) => label).join(', ')}. Set PRINT_PUBLISH_JSON=1 to inspect raw Sui output.`,
  );
  process.exit(1);
}
