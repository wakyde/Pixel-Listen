/**
 * Score a shadowing recording against the original media segment.
 * Returns 0–100 using envelope + spectral similarity (DTW-light).
 */
export async function scoreShadowRecording(
  mediaUrl: string,
  start: number,
  end: number,
  recordingBlob: Blob
): Promise<number> {
  try {
    const ac = new AudioContext();
    const [origBuf, recBuf] = await Promise.all([
      fetchAndDecode(ac, mediaUrl),
      recordingBlob.arrayBuffer().then((ab) => ac.decodeAudioData(ab.slice(0))),
    ]);

    const sampleRate = origBuf.sampleRate;
    const startSample = Math.max(0, Math.floor(start * sampleRate));
    const endSample = Math.min(origBuf.length, Math.floor(end * sampleRate));
    if (endSample - startSample < sampleRate * 0.15) {
      await ac.close();
      return 0;
    }

    const origMono = sliceMono(origBuf, startSample, endSample);
    const recMono = toMono(recBuf);

    // Resample recording to match original length via linear interpolation
    const aligned = resample(recMono, origMono.length);

    const origEnv = rmsEnvelope(origMono, 512);
    const recEnv = rmsEnvelope(aligned, 512);
    const envScore = correlation(origEnv, recEnv);

    const origSpec = spectralFlatnessProfile(origMono, 1024);
    const recSpec = spectralFlatnessProfile(aligned, 1024);
    const specScore = correlation(origSpec, recSpec);

    // Pitch-ish: zero-crossing rate similarity
    const origZcr = zeroCrossingRate(origMono, 1024);
    const recZcr = zeroCrossingRate(aligned, 1024);
    const zcrScore = 1 - Math.min(1, Math.abs(origZcr - recZcr) / Math.max(origZcr, 0.01));

    await ac.close();

    // Weighted blend — favor envelope (timing/energy) + spectrum
    const raw = envScore * 0.45 + specScore * 0.4 + zcrScore * 0.15;
    // Map correlation [-1,1] / [0,1] into meaningful learner scores
    const mapped = Math.max(0, Math.min(1, (raw + 0.15) / 1.15));
    return Math.round(mapped * 100);
  } catch {
    return 0;
  }
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
  // Normalize
  let max = 0;
  for (let i = 0; i < n; i++) if (out[i] > max) max = out[i];
  if (max > 1e-8) for (let i = 0; i < n; i++) out[i] /= max;
  return out;
}

function spectralFlatnessProfile(samples: Float32Array, frameSize: number): Float32Array {
  const hop = frameSize;
  const n = Math.max(1, Math.floor(samples.length / hop));
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const from = i * hop;
    let geometric = 0;
    let arithmetic = 0;
    let count = 0;
    for (let j = 0; j < frameSize && from + j < samples.length; j++) {
      const mag = Math.abs(samples[from + j]) + 1e-12;
      geometric += Math.log(mag);
      arithmetic += mag;
      count++;
    }
    if (count === 0) {
      out[i] = 0;
      continue;
    }
    const g = Math.exp(geometric / count);
    const a = arithmetic / count;
    out[i] = a > 0 ? g / a : 0;
  }
  return out;
}

function zeroCrossingRate(samples: Float32Array, hop: number): number {
  let crossings = 0;
  for (let i = 1; i < samples.length; i += Math.max(1, Math.floor(hop / 8))) {
    if (samples[i - 1] >= 0 !== samples[i] >= 0) crossings++;
  }
  return crossings / Math.max(1, samples.length / hop);
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
