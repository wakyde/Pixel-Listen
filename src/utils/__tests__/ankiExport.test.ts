/**
 * Test file for the new Anki multi-format functionality
 * This file contains unit tests for the new features
 */

import type { ClozeConfig, AnkiCardFormat } from '../../types';
import { buildMultiFormatCards } from '../ankiExport';

// Helper function for tests
function assert(condition: boolean, message: string): void {
  if (!condition) {
    console.error(`❌ Test failed: ${message}`);
    throw new Error(message);
  } else {
    console.log(`✓ ${message}`);
  }
}

// Test 1: Colloquial format card generation
function testColloquialFormat(): void {
  const item = {
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 10,
    end: 15,
    formats: [{ format: 'colloquial' as AnkiCardFormat }],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 1, 'Colloquial format should generate 1 card');
  assert(
    cards[0].front === 'This is a translation.',
    'Colloquial front should be translation'
  );
  assert(cards[0].back === 'This is a test sentence.', 'Colloquial back should be English text');
  assert(cards[0].tags.includes('colloquial'), 'Card should have colloquial tag');
}

// Test 2: Listening review format card generation
function testListeningReviewFormat(): void {
  const item = {
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 10,
    end: 15,
    formats: [{ format: 'listening_review' as AnkiCardFormat }],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 1, 'Listening review format should generate 1 card');
  assert(
    cards[0].front === '[AUDIO]',
    'Listening review front should be [AUDIO] placeholder'
  );
  assert(cards[0].back.includes('This is a test sentence.'), 'Back should contain English');
  assert(
    cards[0].back.includes('This is a translation.'),
    'Back should contain translation'
  );
  assert(cards[0].tags.includes('listening-review'), 'Card should have listening-review tag');
}

// Test 3: Cloze deletion format card generation
function testClozeDelectionFormat(): void {
  const clozeConfig: ClozeConfig = {
    originalText: 'This is a test sentence.',
    blanks: [
      { start: 5, end: 7 }, // "is"
      { start: 10, end: 14 }, // "test"
    ],
  };

  const item = {
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 10,
    end: 15,
    formats: [{ format: 'cloze_deletion' as AnkiCardFormat, clozeConfig }],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 1, 'Cloze deletion format should generate 1 card');
  assert(
    cards[0].front.includes('______'),
    'Cloze front should contain blanks'
  );
  assert(cards[0].back.includes('is'), 'Cloze back should contain answer "is"');
  assert(cards[0].back.includes('test'), 'Cloze back should contain answer "test"');
  assert(cards[0].tags.includes('cloze-deletion'), 'Card should have cloze-deletion tag');
}

// Test 4: Multiple formats on single item
function testMultipleFormats(): void {
  const clozeConfig: ClozeConfig = {
    originalText: 'This is a test sentence.',
    blanks: [{ start: 5, end: 7 }], // "is"
  };

  const item = {
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 10,
    end: 15,
    formats: [
      { format: 'colloquial' as AnkiCardFormat },
      { format: 'listening_review' as AnkiCardFormat },
      { format: 'cloze_deletion' as AnkiCardFormat, clozeConfig },
    ],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 3, 'Should generate 3 cards for 3 formats');

  // Check each format was generated
  const hasColloquial = cards.some((card) => card.tags.includes('colloquial'));
  const hasListeningReview = cards.some((card) => card.tags.includes('listening-review'));
  const hasCloze = cards.some((card) => card.tags.includes('cloze-deletion'));

  assert(hasColloquial, 'Should have colloquial card');
  assert(hasListeningReview, 'Should have listening review card');
  assert(hasCloze, 'Should have cloze deletion card');
}

// Test 5: Format with native translation only (no English translation)
function testNativeTranslationOnly(): void {
  const item = {
    text: 'This is a test sentence.',
    translation: undefined,
    nativeTranslation: '这是一个测试句子。',
    start: 10,
    end: 15,
    formats: [{ format: 'colloquial' as AnkiCardFormat }],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 1, 'Should generate card with native translation');
  assert(
    cards[0].front === '这是一个测试句子。',
    'Front should use native translation when English is missing'
  );
}

// Test 6: Empty formats array should not generate cards
function testEmptyFormats(): void {
  const item = {
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 10,
    end: 15,
    formats: [],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards.length === 0, 'Empty formats array should generate no cards');
}

// Test 7: Audio/video timestamps are preserved
function testMediaTimestamps(): void {
  const item = {
    text: 'Test',
    translation: 'Test translation',
    nativeTranslation: undefined,
    start: 5.5,
    end: 10.2,
    formats: [{ format: 'colloquial' as AnkiCardFormat }],
  };

  const cards = buildMultiFormatCards(item);
  assert(cards[0].audioStart === 5.5, 'Audio start timestamp should be preserved');
  assert(cards[0].audioEnd === 10.2, 'Audio end timestamp should be preserved');
}

// Run all tests
export function runAllTests(): void {
  console.log('\n🧪 Running Anki multi-format tests...\n');

  try {
    testColloquialFormat();
    testListeningReviewFormat();
    testClozeDelectionFormat();
    testMultipleFormats();
    testNativeTranslationOnly();
    testEmptyFormats();
    testMediaTimestamps();

    console.log('\n✅ All tests passed!\n');
  } catch (error) {
    console.error('\n❌ Tests failed:', error);
    throw error;
  }
}
