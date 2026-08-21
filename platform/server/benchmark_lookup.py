"""Benchmark word lookup speed across Ollama models."""
import asyncio
import time
import httpx
import sys

OLLAMA_URL = "http://localhost:11434"
TEST_WORD = "ambitious"

# Models downloaded last night (sorted by size)
# Already tested, skip these
_TESTED = {"qwen2.5:1.5b", "qwen2.5:3b", "qwen2.5:7b", "llama3.1:8b",
           "deepseek-r1:8b", "deepseek-r1:14b", "qwen3.6:latest"}

# New models to test
MODELS = [
    "hermes3:8b",
    "gemma4:12b",
    "gemma4:latest",
]

SYSTEM_PROMPT = (
    "You are an expert English lexicographer. "
    "You MUST return ONLY a valid JSON object. No markdown, no explanation, no code blocks."
)

PROMPT = (
    f'Word to analyze: "{TEST_WORD}"\n\n'
    f'Return a JSON object with these fields. '
    f'Fields ending in _en must be in English. '
    f'Fields ending in _zh must be in Chinese. '
    f'Fields named "meaning" and "difference" must be in Chinese.\n\n'
    f'JSON structure:\n'
    f'{{\n'
    f'  "word": "{TEST_WORD}",\n'
    f'  "phonetic_us": "IPA notation",\n'
    f'  "senses": [\n'
    f'    {{"definition_en": "English definition using simple words", '
    f'"definition_zh": "Chinese definition"}}\n'
    f'  ],\n'
    f'  "examples": [\n'
    f'    {{"sentence_en": "English example sentence", '
    f'"sentence_zh": "Chinese example sentence"}}\n'
    f'  ],\n'
    f'  "collocations": [\n'
    f'    {{"phrase": "English collocation", "meaning": "Chinese meaning"}}\n'
    f'  ],\n'
    f'  "confusable_words": [\n'
    f'    {{"word": "English similar word", "meaning": "Chinese meaning", '
    f'"difference": "Chinese explanation"}}\n'
    f'  ]\n'
    f'}}\n\n'
    f'IMPORTANT RULES:\n'
    f'1. definition_en, sentence_en, phrase, word: Write in ENGLISH only\n'
    f'2. definition_zh, sentence_zh, meaning, difference: Write in Chinese only\n'
    f'3. Use A1-level simple English words for definition_en\n'
    f'4. Use standard US IPA for phonetic_us\n'
    f'5. Provide 1-3 senses, 2 examples, 2-3 collocations, 1-2 confusable words\n'
    f'6. Return ONLY the JSON object, nothing else'
)


async def test_model(client: httpx.AsyncClient, model: str) -> dict:
    started = time.time()
    try:
        resp = await client.post(
            f"{OLLAMA_URL}/v1/chat/completions",
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": PROMPT},
                ],
                "temperature": 0.3,
            },
            timeout=120.0,
        )
        elapsed = time.time() - started

        if resp.status_code == 200:
            data = resp.json()
            content = data["choices"][0]["message"]["content"]
            return {
                "model": model,
                "time": elapsed,
                "status": "OK",
                "tokens": len(content),
                "content_preview": content[:80].replace("\n", " "),
            }
        else:
            return {
                "model": model,
                "time": elapsed,
                "status": f"HTTP {resp.status_code}",
                "tokens": 0,
                "content_preview": resp.text[:100],
            }
    except Exception as e:
        elapsed = time.time() - started
        return {
            "model": model,
            "time": elapsed,
            "status": f"ERROR: {e}",
            "tokens": 0,
            "content_preview": "",
        }


async def main():
    print("=" * 70)
    print(f"  Word Lookup Benchmark — word: '{TEST_WORD}'")
    print("=" * 70)
    print(f"{'Model':<22} {'Time':>8} {'Tokens':>7}  Status")
    print("-" * 70)

    results = []
    async with httpx.AsyncClient(timeout=120.0) as client:
        for model in MODELS:
            sys.stdout.write(f"  {model:<20} ...")
            sys.stdout.flush()

            result = await test_model(client, model)
            results.append(result)

            time_str = f"{result['time']:.2f}s"
            print(f"\r  {model:<20} {time_str:>8} {result['tokens']:>7}  {result['status']}")

    print("-" * 70)
    print("\n  Ranked by speed:")
    ranked = sorted(results, key=lambda r: r["time"] if r["status"] == "OK" else 999)
    for i, r in enumerate(ranked, 1):
        flag = "  ← CURRENT" if r["model"] == "qwen3.6:latest" else ""
        time_str = f"{r['time']:.2f}s"
        print(f"  {i}. {r['model']:<20} {time_str:>8}  {r['content_preview'][:60]}...{flag}")

    print()


if __name__ == "__main__":
    asyncio.run(main())