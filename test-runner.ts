import { runAllTests } from './utils/__tests__/ankiExport.test';

// Run tests when module loads
console.log('🚀 Anki Multi-Format Feature Tests');
console.log('=' .repeat(50));

try {
  runAllTests();
  console.log('✅ All feature tests completed successfully!');
} catch (error) {
  console.error('❌ Tests failed:', error);
  process.exit(1);
}
