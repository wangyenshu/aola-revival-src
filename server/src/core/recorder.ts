// Every frame in and out is recorded. In listen mode this log *is* the
// reverse-engineering input: each unknown frame is a to-do item.

import { asciiPreview, fromUtf8, looksLikeText, toHex } from "./bytes.ts";

export interface FrameRecord {
  t: string;
  session: number;
  port: number;
  dir: "in" | "out" | "event";
  len: number;
  hex?: string;
  text?: string;
  note?: string;
}

export interface Recorder {
  record(r: FrameRecord): void;
}

export function frameRecord(
  session: number,
  port: number,
  dir: FrameRecord["dir"],
  bytes: Uint8Array | null,
  note?: string,
  maxHex = 4096,
): FrameRecord {
  const r: FrameRecord = { t: new Date().toISOString(), session, port, dir, len: bytes?.length ?? 0 };
  if (bytes) {
    r.hex = toHex(bytes, maxHex);
    r.text = looksLikeText(bytes) ? fromUtf8(bytes.subarray(0, maxHex)) : asciiPreview(bytes, 128);
  }
  if (note) r.note = note;
  return r;
}

export class MemoryRecorder implements Recorder {
  readonly records: FrameRecord[] = [];
  record(r: FrameRecord): void {
    this.records.push(r);
  }
}

export class ConsoleRecorder implements Recorder {
  record(r: FrameRecord): void {
    const head = `[${r.port}#${r.session}] ${r.dir.padEnd(5)} ${String(r.len).padStart(6)}B`;
    console.log(r.note ? `${head} ${r.note}` : `${head} ${r.text ?? ""}`.slice(0, 220));
  }
}

export class TeeRecorder implements Recorder {
  private readonly sinks: Recorder[];
  constructor(...sinks: Recorder[]) {
    this.sinks = sinks;
  }
  record(r: FrameRecord): void {
    for (const s of this.sinks) s.record(r);
  }
}
