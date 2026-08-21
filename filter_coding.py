import json

with open('/tmp/llmfit_tool.json') as f:
    data = json.load(f)

models = data.get('models', [])
print(f'Total tool-use models: {len(models)}\n')

# Filter for coding-related
coding = []
for m in models:
    name = m.get('name', '').lower()
    p = m.get('params_b', 0)
    # Filter: 6-40B, not vision/audio/embedding
    if p < 6:
        continue
    if any(kw in name for kw in ['vision', 'vl', 'audio', 'tts', 'embed', 'clip', 'wav']):
        continue
    coding.append(m)

coding.sort(key=lambda x: x.get('score', 0), reverse=True)

print(f"{'Score':>5} {'TPS':>5} {'Mem':>4s} {'Params':>8s} {'Ctx':>5s} | {'MoE':4s} | Name")
print('-' * 100)
for m in coding[:20]:
    name = m.get('name', '?')
    score = m.get('score', 0)
    tps = m.get('estimated_tps', 0)
    ctx = m.get('context_length', 0)
    mem = m.get('memory_required_gb', 0)
    params = m.get('parameter_count', '?')
    moe = 'Y' if m.get('is_moe') else ' '
    rt = m.get('runtime_label', '?')
    print(f'{score:5.0f} {tps:5.0f} {mem:4.0f}GB {params:>8s} {ctx//1000:4d}k | {moe:4s} | {rt:5s} | {name}')