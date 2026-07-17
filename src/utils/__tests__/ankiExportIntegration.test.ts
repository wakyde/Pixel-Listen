/**
 * Integration test for Anki multi-format shopping cart feature
 * Tests the complete workflow: adding items, selecting formats, generating cards
 */

import type { AnkiCartItem, ClozeConfig } from '../../types';
import { buildMultiFormatCards } from '../ankiExport';

// Test helper
function log(title: string, message?: string): void {
  console.log(`\n📌 ${title}`);
  if (message) console.log(`   ${message}`);
}

function success(message: string): void {
  console.log(`   ✅ ${message}`);
}

function error(message: string): void {
  console.error(`   ❌ ${message}`);
  throw new Error(message);
}

// Mock cart item data
const mockCartItems: AnkiCartItem[] = [
  {
    id: '1',
    cueIds: ['cue-1'],
    text: 'How are you doing today?',
    translation: '你今天怎么样？',
    nativeTranslation: undefined,
    start: 0,
    end: 3.5,
    addedAt: Date.now(),
    formats: [{ format: 'colloquial' }],
  },
  {
    id: '2',
    cueIds: ['cue-2', 'cue-3'],
    text: 'I think we should go there.',
    translation: '我认为我们应该去那里。',
    nativeTranslation: undefined,
    start: 5,
    end: 8.5,
    addedAt: Date.now(),
    formats: [
      { format: 'colloquial' },
      { format: 'listening_review' },
    ],
  },
];

// Integration test 1: Single format export
function testSingleFormatExport(): void {
  log('Test 1: Single Format Export', 'Basic colloquial format card generation');

  const item = mockCartItems[0];
  const cards = buildMultiFormatCards(item);

  if (cards.length !== 1) error(`Expected 1 card, got ${cards.length}`);
  if (cards[0].front !== item.translation) error('Front should be translation');
  if (cards[0].back !== item.text) error('Back should be English text');
  if (!cards[0].tags.includes('colloquial')) error('Should have colloquial tag');

  success('Single format export working correctly');
}

// Integration test 2: Multiple formats export
function testMultipleFormatsExport(): void {
  log('Test 2: Multiple Formats Export', 'Generating multiple card types from single item');

  const item = mockCartItems[1];
  const cards = buildMultiFormatCards(item);

  if (cards.length !== 2) error(`Expected 2 cards, got ${cards.length}`);

  const colloquialCard = cards.find((c) => c.tags.includes('colloquial'));
  const listeningCard = cards.find((c) => c.tags.includes('listening-review'));

  if (!colloquialCard) error('Should have colloquial card');
  if (!listeningCard) error('Should have listening review card');

  if (colloquialCard!.front !== item.translation)
    error('Colloquial front should be translation');
  if (!listeningCard!.front.includes('[AUDIO]'))
    error('Listening card front should have [AUDIO]');
  if (!listeningCard!.back.includes(item.text))
    error('Listening card back should have English text');

  success('Multiple formats export working correctly');
}

// Integration test 3: Full export with all items
function testFullExport(): void {
  log('Test 3: Full Cart Export', 'Exporting all items with their formats');

  const allCards = mockCartItems.flatMap((item) => buildMultiFormatCards(item));

  // Item 1: 1 format = 1 card
  // Item 2: 2 formats = 2 cards
  // Total: 3 cards
  if (allCards.length !== 3) error(`Expected 3 total cards, got ${allCards.length}`);

  // Verify tags diversity
  const hasColloquial = allCards.some((c) => c.tags.includes('colloquial'));
  const hasListening = allCards.some((c) => c.tags.includes('listening-review'));
  const allHaveCartTag = allCards.every((c) => c.tags.includes('cart'));

  if (!hasColloquial) error('Should have at least one colloquial card');
  if (!hasListening) error('Should have at least one listening card');
  if (!allHaveCartTag) error('All cards should have cart tag');

  success('Full export working correctly');
}

// Integration test 4: Cloze format workflow
function testClozeFormatWorkflow(): void {
  log('Test 4: Cloze Deletion Workflow', 'Creating and exporting cloze cards');

  const clozeConfig: ClozeConfig = {
    originalText: 'How are you doing today?',
    blanks: [
      { start: 0, end: 3 }, // "How"
      { start: 8, end: 11 }, // "you"
    ],
  };

  const item: AnkiCartItem = {
    id: '3',
    cueIds: ['cue-4'],
    text: 'How are you doing today?',
    translation: '你今天怎么样？',
    nativeTranslation: undefined,
    start: 10,
    end: 13,
    addedAt: Date.now(),
    formats: [{ format: 'cloze_deletion', clozeConfig }],
  };

  const cards = buildMultiFormatCards(item);

  if (cards.length !== 1) error(`Expected 1 cloze card, got ${cards.length}`);

  const clozeCard = cards[0];
  if (!clozeCard.tags.includes('cloze-deletion')) error('Should have cloze-deletion tag');
  if (!clozeCard.front.includes('______')) error('Cloze front should have blanks');
  if (!clozeCard.back.includes('How')) error('Cloze back should have answer');
  if (!clozeCard.back.includes('you')) error('Cloze back should have second answer');

  success('Cloze format workflow working correctly');
}

// Integration test 5: Mixed format cart
function testMixedFormatCart(): void {
  log('Test 5: Mixed Format Cart', 'Exporting cart with diverse formats');

  const clozeConfig: ClozeConfig = {
    originalText: 'I think we should go there.',
    blanks: [{ start: 2, end: 7 }], // "think"
  };

  const mixedItem: AnkiCartItem = {
    id: '4',
    cueIds: ['cue-5'],
    text: 'I think we should go there.',
    translation: '我认为我们应该去那里。',
    nativeTranslation: undefined,
    start: 15,
    end: 18,
    addedAt: Date.now(),
    formats: [
      { format: 'colloquial' },
      { format: 'listening_review' },
      { format: 'cloze_deletion', clozeConfig },
    ],
  };

  const cards = buildMultiFormatCards(mixedItem);

  if (cards.length !== 3) error(`Expected 3 cards for mixed format, got ${cards.length}`);

  const formats = [
    cards.find((c) => c.tags.includes('colloquial')),
    cards.find((c) => c.tags.includes('listening-review')),
    cards.find((c) => c.tags.includes('cloze-deletion')),
  ];

  for (const format of formats) {
    if (!format) error('All three formats should be present in export');
  }

  // Verify all cards have correct audio/video timestamps
  for (const card of cards) {
    if (card.audioStart !== 15 || card.audioEnd !== 18) {
      error('Audio/video timestamps should be preserved across formats');
    }
  }

  success('Mixed format cart exporting correctly');
}

// Integration test 6: Resource sharing verification
function testResourceSharing(): void {
  log('Test 6: Resource Sharing', 'Verify media resources are not duplicated');

  const item: AnkiCartItem = {
    id: '5',
    cueIds: ['cue-6'],
    text: 'This is a test sentence.',
    translation: 'This is a translation.',
    nativeTranslation: undefined,
    start: 20,
    end: 25,
    addedAt: Date.now(),
    formats: [
      { format: 'colloquial' },
      { format: 'listening_review' },
      { format: 'cloze_deletion', clozeConfig: { originalText: 'This is a test sentence.', blanks: [{ start: 0, end: 4 }] } },
    ],
  };

  const cards = buildMultiFormatCards(item);

  // All cards should reference the same media timestamps
  const timestamps = new Set(
    cards.map((c) => `${c.audioStart}-${c.audioEnd}`)
  );

  if (timestamps.size !== 1) {
    error('All cards from same item should share the same media timestamps');
  }

  success('Media resource sharing verified');
}

// Run all integration tests
export function runIntegrationTests(): void {
  console.log('\n' + '='.repeat(60));
  console.log('🧪 ANKI MULTI-FORMAT SHOPPING CART - INTEGRATION TESTS');
  console.log('='.repeat(60));

  try {
    testSingleFormatExport();
    testMultipleFormatsExport();
    testFullExport();
    testClozeFormatWorkflow();
    testMixedFormatCart();
    testResourceSharing();

    console.log('\n' + '='.repeat(60));
    console.log('✅ ALL INTEGRATION TESTS PASSED!');
    console.log('='.repeat(60) + '\n');
  } catch (err) {
    console.error('\n' + '='.repeat(60));
    console.error('❌ INTEGRATION TESTS FAILED');
    console.error('='.repeat(60) + '\n');
    throw err;
  }
}
