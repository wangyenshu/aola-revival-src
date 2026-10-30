// Node implementations of Store and Recorder backed by plain files.

import { appendFileSync, mkdirSync, promises as fs } from "node:fs";
import path from "node:path";
import type { FrameRecord, Recorder } from "../core/recorder.ts";
import type { Store } from "../core/store.ts";

/** One JSON file per key under dir (keys like "user/10001" become user/10001.json). */
export class JsonFileStore implements Store {
  private readonly dir: string;
  constructor(dir: string) {
    this.dir = path.resolve(dir);
  }

  private file(key: string): string {
    const safe = key.split("/").map((s) => encodeURIComponent(s)).join(path.sep);
    return path.join(this.dir, safe + ".json");
  }

  async get<T>(key: string): Promise<T | undefined> {
    try {
      return JSON.parse(await fs.readFile(this.file(key), "utf8")) as T;
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code === "ENOENT") return undefined;
      throw e;
    }
  }

  async set<T>(key: string, value: T): Promise<void> {
    const f = this.file(key);
    await fs.mkdir(path.dirname(f), { recursive: true });
    const tmp = f + ".tmp";
    await fs.writeFile(tmp, JSON.stringify(value, null, 1));
    await fs.rename(tmp, f);
  }

  async delete(key: string): Promise<void> {
    await fs.rm(this.file(key), { force: true });
  }

  async keys(prefix = ""): Promise<string[]> {
    const out: string[] = [];
    const walk = async (d: string, parts: string[]): Promise<void> => {
      let entries;
      try {
        entries = await fs.readdir(d, { withFileTypes: true });
      } catch {
        return;
      }
      for (const e of entries) {
        if (e.isDirectory()) await walk(path.join(d, e.name), [...parts, decodeURIComponent(e.name)]);
        else if (e.name.endsWith(".json")) out.push([...parts, decodeURIComponent(e.name.slice(0, -5))].join("/"));
      }
    };
    await walk(this.dir, []);
    return out.filter((k) => k.startsWith(prefix)).sort();
  }
}

/** Appends every frame record to a JSONL file. */
export class JsonlRecorder implements Recorder {
  private readonly file: string;
  constructor(file: string) {
    this.file = file;
    mkdirSync(path.dirname(path.resolve(file)), { recursive: true });
  }
  record(r: FrameRecord): void {
    appendFileSync(this.file, JSON.stringify(r) + "\n");
  }
}
