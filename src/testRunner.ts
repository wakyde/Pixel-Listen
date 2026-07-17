#!/usr/bin/env node

/**
 * Test runner for Anki multi-format shopping cart feature
 * Run: npx ts-node src/testRunner.ts
 */

import { runAllTests } from './utils/__tests__/ankiExport.test';
import { runIntegrationTests } from './utils/__tests__/ankiExportIntegration.test';

async function main(): Promise<void> {
  try {
    // Run unit tests
    runAllTests();

    // Run integration tests  
    runIntegrationTests();

    console.log('\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!\n');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Tests failed:', error);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
