/**
 * Score a shadowing recording against the original media segment.
 * Returns 0–100 using envelope correlation + spectral band similarity + pitch similarity.
 */
export async function scoreShadowRecording(
  mediaUrl: string,
  start: number,
  end: number,
  recordingBlob: Blob
): Promise<number> {
  let origBuf: AudioBuffer;
  let recBuf: AudioBuffer;

  try {
    const ac = new AudioContext();
    try {
      [origBuf, recBuf] = await Promise.all([
        fetchAndDecode(ac, mediaUrl),
        recordingBlob.arrayBuffer().then((ab) => ac.decodeAudioData(ab.slice(0))),
      ]);
    } catch (decodeErr) {
      console.warn('[audioScore] decode failed, trying fallback:', decodeErr);
      try {
        const recAb = await recordingBlob.arrayBuffer();
        const offline = new OfflineAudioContext(1, 1, 48000);
        const decoded = await offline.decodeAudioData(recAb.slice(0));
        const duration = decoded.length / decoded.sampleRate;
        const targetLen = Math.ceil(duration * 48000);
        const renderCtx = new OfflineAudioContext(1, targetLen, 48000);
        const srcNode = renderCtx.createBufferSource();
        srcNode.buffer = decoded;
        srcNode.connect(renderCtx.destination);
        srcNode.start();
        recBuf = await renderCtx.startRendering();
        origBuf = await fetchAndDecode(ac, mediaUrl);
      } catch (fallbackErr) {
        console.error('[audioScore] fallback decode also failed:', fallbackErr);
        await ac.close();
        return 0;
      }
    }
    await ac.close();
  } catch (err) {
    console.error('[audioScore] scoring failed:', err);
    return 0;
  }

  const sampleRate = origBuf.sampleRate;
  const startSample = Math.max(0, Math.floor(start * sampleRate));
  const endSample = Math.min(origBuf.length, Math.floor(end * sampleRate));
  if (endSample - startSample < sampleRate * 0.15) {
    return 0;
  }

  const origMono = sliceMono(origBuf, startSample, endSample);
  const recMono = toMono(recBuf);

  const silenceThreshold = 0.01;
  const origTrimmed = trimSilence(origMono, silenceThreshold);
  const recTrimmed = trimSilence(recMono, silenceThreshold);
  if (origTrimmed.length < sampleRate * 0.1 || recTrimmed.length < sampleRate * 0.05) {
    return 0;
  }

  const aligned = resample(recTrimmed, origTrimmed.length);

  const envScore = computeEnvelopeScore(origTrimmed, aligned);

  const specScore = computeSpectralScore(origTrimmed, aligned);

  const pitchScore = computePitchScore(origTrimmed, aligned);

  const raw = envScore * 0.4 + specScore * 0.35 + pitchScore * 0.25;
  return Math.round(Math.max(0, Math.min(100, raw * 100)));
}

function computeEnvelopeScore(orig: Float32Array, rec: Float32Array): number {
  const hop = 512;
  const origEnv = rmsEnvelope(orig, hop);
  const recEnv = rmsEnvelope(rec, hop);

  const corr = correlation(origEnv, recEnv);

  const origEnergy = energy(orig);
  const recEnergy = energy(rec);
  const energyRatio = origEnergy > 1e-8 ? Math.min(recEnergy / origEnergy, 1) : 0;

  const corrWeight = 0.7;
  const energyWeight = 0.3;
  const score = corr * corrWeight + energyRatio * energyWeight;
  return Math.max(0, score);
}

function computeSpectralScore(orig: Float32Array, rec: Float32Array): number {
  const fftSize = 2048;
  const hop = fftSize >> 2;
  const nFrames = Math.max(1, Math.floor((orig.length - fftSize) / hop) + 1);
  const nFramesRec = Math.max(1, Math.floor((rec.length - fftSize) / hop) + 1);
  const minFrames = Math.min(nFrames, nFramesRec);
  if (minFrames < 1) return 0;

  const nBands = 6;
  const bandEdges = [0, 300, 600, 1200, 2400, 4800, 8000];
  let totalSim = 0;

  for (let f = 0; f < minFrames; f++) {
    const origBands = computeBandEnergies(orig, f * hop, fftSize, bandEdges, nBands);
    const recBands = computeBandEnergies(rec, f * hop, fftSize, bandEdges, nBands);
    totalSim += cosineSimilarity(origBands, recBands);
  }

  return totalSim / minFrames;
}

function computePitchScore(orig: Float32Array, rec: Float32Array): number {
  const frameSize = 1024;
  const hop = frameSize >> 1;
  const nFrames = Math.max(1, Math.floor((orig.length - frameSize) / hop) + 1);
  const nFramesRec = Math.max(1, Math.floor((rec.length - frameSize) / hop) + 1);
  const minFrames = Math.min(nFrames, nFramesRec);
  if (minFrames < 2) return 0.5;

  let matchCount = 0;
  let voicedCount = 0;

  for (let f = 0; f < minFrames; f++) {
    const origPitch = detectPitch(orig, f * hop, frameSize);
    const recPitch = detectPitch(rec, f * hop, frameSize);

    const origVoiced = origPitch > 50;
    const recVoiced = recPitch > 50;

    if (origVoiced || recVoiced) {
      voicedCount++;
      if (origVoiced && recVoiced) {
        const ratio = Math.min(origPitch, recPitch) / Math.max(origPitch, recPitch);
        if (ratio > 0.7) matchCount++;
      } else if (!origVoiced && !recVoiced) {
        matchCount++;
      }
    }
  }

  if (voicedCount === 0) return 0.5;
  return matchCount / voicedCount;
}

function detectPitch(samples: Float32Array, offset: number, frameSize: number): number {
  const minF0 = 60;
  const maxF0 = 500;
  const sr = 48000;
  const minLag = Math.floor(sr / maxF0);
  const maxLag = Math.min(Math.floor(sr / minF0), frameSize >> 1);

  let bestLag = 0;
  let bestCorr = 0;
  let energy = 0;

  for (let i = 0; i < frameSize && offset + i < samples.length; i++) {
    energy += samples[offset + i] * samples[offset + i];
  }
  energy = Math.sqrt(energy / frameSize);
  if (energy < 0.005) return 0;

  for (let lag = minLag; lag <= maxLag; lag++) {
    let num = 0;
    let denA = 0;
    let denB = 0;
    const n = Math.min(frameSize - lag, samples.length - offset - lag);
    for (let i = 0; i < n; i++) {
      const a = samples[offset + i];
      const b = samples[offset + i + lag];
      num += a * b;
      denA += a * a;
      denB += b * b;
    }
    const den = Math.sqrt(denA * denB);
    if (den < 1e-12) continue;
    const c = num / den;
    if (c > bestCorr) {
      bestCorr = c;
      bestLag = lag;
    }
  }

  if (bestCorr < 0.3 || bestLag === 0) return 0;
  return sr / bestLag;
}

function computeBandEnergies(
  samples: Float32Array,
  offset: number,
  fftSize: number,
  bandEdges: number[],
  nBands: number
): Float32Array {
  const re = new Float32Array(fftSize);
  const im = new Float32Array(fftSize);
  const sr = 48000;

  for (let j = 0; j < fftSize; j++) {
    const idx = offset + j;
    const s = idx >= 0 && idx < samples.length ? samples[idx] : 0;
    const w = 0.5 * (1 - Math.cos((2 * Math.PI * j) / (fftSize - 1)));
    re[j] = s * w;
  }
  fft(re, im);

  const bands = new Float32Array(nBands);
  const binHz = sr / fftSize;
  for (let k = 1; k < fftSize >> 1; k++) {
    const freq = k * binHz;
    const mag = re[k] * re[k] + im[k] * im[k];
    for (let b = 0; b < nBands; b++) {
      if (freq >= bandEdges[b] && freq < bandEdges[b + 1]) {
        bands[b] += mag;
        break;
      }
    }
  }

  let maxBand = 0;
  for (let b = 0; b < nBands; b++) if (bands[b] > maxBand) maxBand = bands[b];
  if (maxBand > 1e-12) for (let b = 0; b < nBands; b++) bands[b] /= maxBand;

  return bands;
}

function cosineSimilarity(a: Float32Array, b: Float32Array): number {
  const n = Math.min(a.length, b.length);
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < n; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  const den = Math.sqrt(normA * normB);
  if (den < 1e-12) return 0;
  return Math.max(0, dot / den);
}

function energy(samples: Float32Array): number {
  let sum = 0;
  for (let i = 0; i < samples.length; i++) sum += samples[i] * samples[i];
  return Math.sqrt(sum / samples.length);
}

async function fetchAndDecode(ac: AudioContext, url: string): Promise<AudioBuffer> {
  const res = await fetch(url);
  const ab = await res.arrayBuffer();
  return ac.decodeAudioData(ab.slice(0));
}

function toMono(buf: AudioBuffer): Float32Array {
  const len = buf.length;
  const out = new Float32Array(len);
  const chs = buf.numberOfChannels;
  for (let i = 0; i < len; i++) {
    let sum = 0;
    for (let c = 0; c < chs; c++) sum += buf.getChannelData(c)[i];
    out[i] = sum / chs;
  }
  return out;
}

function sliceMono(buf: AudioBuffer, start: number, end: number): Float32Array {
  const mono = toMono(buf);
  return mono.slice(start, end);
}

function trimSilence(samples: Float32Array, threshold: number): Float32Array {
  let start = 0;
  while (start < samples.length && Math.abs(samples[start]) < threshold) start++;
  let end = samples.length;
  while (end > start && Math.abs(samples[end - 1]) < threshold) end--;
  return samples.slice(start, end);
}

function resample(input: Float32Array, targetLen: number): Float32Array {
  if (input.length === targetLen) return input;
  if (input.length === 0 || targetLen <= 0) return new Float32Array(Math.max(0, targetLen));
  const out = new Float32Array(targetLen);
  const ratio = (input.length - 1) / Math.max(1, targetLen - 1);
  for (let i = 0; i < targetLen; i++) {
    const src = i * ratio;
    const i0 = Math.floor(src);
    const i1 = Math.min(input.length - 1, i0 + 1);
    const t = src - i0;
    out[i] = input[i0] * (1 - t) + input[i1] * t;
  }
  return out;
}

function rmsEnvelope(samples: Float32Array, hop: number): Float32Array {
  const n = Math.max(1, Math.floor(samples.length / hop));
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let sum = 0;
    const from = i * hop;
    const to = Math.min(samples.length, from + hop);
    for (let j = from; j < to; j++) sum += samples[j] * samples[j];
    out[i] = Math.sqrt(sum / Math.max(1, to - from));
  }
  let max = 0;
  for (let i = 0; i < n; i++) if (out[i] > max) max = out[i];
  if (max > 1e-8) for (let i = 0; i < n; i++) out[i] /= max;
  return out;
}

function fft(re: Float32Array, im: Float32Array): void {
  const n = re.length;
  if (n <= 1) return;
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    while (j & bit) {
      j ^= bit;
      bit >>= 1;
    }
    j ^= bit;
    if (i < j) {
      let tmp = re[i]; re[i] = re[j]; re[j] = tmp;
      tmp = im[i]; im[i] = im[j]; im[j] = tmp;
    }
  }
  for (let len = 2; len <= n; len <<= 1) {
    const halfLen = len >> 1;
    const angle = (-2 * Math.PI) / len;
    const wRe = Math.cos(angle);
    const wIm = Math.sin(angle);
    for (let i = 0; i < n; i += len) {
      let curRe = 1;
      let curIm = 0;
      for (let j = 0; j < halfLen; j++) {
        const tRe = curRe * re[i + j + halfLen] - curIm * im[i + j + halfLen];
        const tIm = curRe * im[i + j + halfLen] + curIm * re[i + j + halfLen];
        re[i + j + halfLen] = re[i + j] - tRe;
        im[i + j + halfLen] = im[i + j] - tIm;
        re[i + j] += tRe;
        im[i + j] += tIm;
        const newCurRe = curRe * wRe - curIm * wIm;
        curIm = curRe * wIm + curIm * wRe;
        curRe = newCurRe;
      }
    }
  }
}

function correlation(a: Float32Array, b: Float32Array): number {
  const n = Math.min(a.length, b.length);
  if (n < 2) return 0;
  let meanA = 0;
  let meanB = 0;
  for (let i = 0; i < n; i++) {
    meanA += a[i];
    meanB += b[i];
  }
  meanA /= n;
  meanB /= n;
  let num = 0;
  let denA = 0;
  let denB = 0;
  for (let i = 0; i < n; i++) {
    const da = a[i] - meanA;
    const db = b[i] - meanB;
    num += da * db;
    denA += da * da;
    denB += db * db;
  }
  const den = Math.sqrt(denA * denB);
  if (den < 1e-12) return 0;
  return num / den;
}