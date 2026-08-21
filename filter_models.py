import json

with open('/tmp/llmfit_200.json') as f:
    data = json.load(f)

models = data.get('models', [])
filtered = []
for m in models:
    p = m.get('params_b', 0)
    name = m.get('name', '').lower()
    if 6 < p < 15 and not m.get('is_moe', False):
        if any(kw in name for kw in ['embed', 'whisper', 'vision', 'audio', 'tts', 'tiny', 'clip', 'wav', 'vl', 'coder']):
            continue
        filtered.append(m)

filtered.sort(key=lambda x: x.get('score', 0), reverse=True)

print(f"{'Score':>5} {'TPS':>5} {'Fit':6s} {'Mem':>4s} {'Params':>8s} {'Ctx':>5s} | {'Runtime':5s} | {'Inst'} Name")
print('-' * 110)
for m in filtered[:30]:
    name = m.get('name', '?')
    score = m.get('score', 0)
    tps = m.get('estimated_tps', 0)
    fit = m.get('fit_level', '?')
    ctx = m.get('context_length', 0)
    rt = m.get('runtime_label', '?')
    mem = m.get('memory_required_gb', 0)
    params = m.get('parameter_count', '?')
    installed = 'Y' if m.get('installed') else ' '
    print(f'{score:5.0f} {tps:5.0f} {fit:6s} {mem:4.0f}GB {params:>8s} {ctx//1000:4d}k | {rt:5s} | {installed}  {name}')