export interface DictionarySection {
  title: string;
  items: string[];
}

export interface DictionaryTooltipResult {
  query: string;
  english: DictionarySection[];
  chinese: DictionarySection[];
  note?: string;
}

async function fetchEnglishDefinition(term: string): Promise<DictionarySection[]> {
  const url = `https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(term)}`;
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error('No English dictionary entry');
    const data = await res.json();
    if (!Array.isArray(data) || data.length === 0) throw new Error('No entries');
    const entry = data[0];
    const phonetic = entry.phonetic || entry.phonetics?.[0]?.text;
    const meanings = entry.meanings || [];
    const sections: DictionarySection[] = [];
    if (phonetic) {
      sections.push({ title: 'Pronunciation', items: [phonetic] });
    }
    for (const meaning of meanings.slice(0, 3)) {
      const definitions = (meaning.definitions || [])
        .slice(0, 3)
        .map((def: any) => {
          const example = def.example ? ` Example: ${def.example}` : '';
          return `(${meaning.partOfSpeech}) ${def.definition}${example}`;
        });
      if (definitions.length > 0) {
        sections.push({ title: meaning.partOfSpeech || 'Definition', items: definitions });
      }
    }
    if (sections.length === 0) {
      sections.push({ title: 'Definition', items: ['No English definition found.'] });
    }
    return sections;
  } catch {
    return [{ title: 'English lookup', items: ['No English dictionary entry found.'] }];
  }
}

async function fetchChineseDefinition(term: string, apiKey?: string): Promise<DictionarySection[]> {
  const zhUrl = `https://api.dictionaryapi.dev/api/v2/entries/zh/${encodeURIComponent(term)}`;
  try {
    const res = await fetch(zhUrl);
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        const entry = data[0];
        const sections: DictionarySection[] = [];
        if (entry.meanings) {
          for (const meaning of entry.meanings.slice(0, 3)) {
            const defs = (meaning.definitions || [])
              .slice(0, 3)
              .map((def: any) => def.definition || '');
            if (defs.length > 0) {
              sections.push({ title: meaning.partOfSpeech || 'Meaning', items: defs });
            }
          }
        }
        if (sections.length > 0) return sections;
      }
    }
  } catch {
    // ignore
  }

  if (!apiKey) {
    return [{ title: 'Chinese lookup', items: ['Chinese dictionary unavailable without API key.'] }];
  }

  try {
    const payload = {
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content:
            'You are a Chinese-English dictionary assistant. Provide concise definitions, usage notes, and example sentences in English.',
        },
        {
          role: 'user',
          content: `Look up this Chinese word/phrase and return JSON with keys: meaning, usage, examples. Word: "${term}"`,
        },
      ],
      temperature: 0.2,
    };
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error('Chinese lookup failed');
    const data = await res.json();
    const content = data.choices?.[0]?.message?.content ?? '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error('No JSON');
    const parsed = JSON.parse(jsonMatch[0]);
    const sections: DictionarySection[] = [];
    if (parsed.meaning) sections.push({ title: 'Meaning', items: [parsed.meaning] });
    if (parsed.usage) sections.push({ title: 'Usage', items: [parsed.usage] });
    if (parsed.examples) {
      const examples = Array.isArray(parsed.examples) ? parsed.examples : [parsed.examples];
      sections.push({ title: 'Examples', items: examples.slice(0, 3) });
    }
    if (sections.length > 0) return sections;
  } catch {
    // ignore
  }

  return [{ title: 'Chinese lookup', items: ['No Chinese dictionary entry found.'] }];
}

export async function lookupDictionary(
  term: string,
  apiKey?: string
): Promise<DictionaryTooltipResult> {
  const query = term.trim();
  const english = await fetchEnglishDefinition(query);
  const chinese = await fetchChineseDefinition(query, apiKey);
  return {
    query,
    english,
    chinese,
  };
}
