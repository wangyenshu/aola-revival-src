// IndexedDB-backed Store for the offline browser copy (saves survive reloads).

import type { Store } from "../core/store.ts";

export class IdbStore implements Store {
  private readonly db: Promise<IDBDatabase>;

  constructor(name = "aola-revival") {
    this.db = new Promise((resolve, reject) => {
      const req = indexedDB.open(name, 1);
      req.onupgradeneeded = () => req.result.createObjectStore("kv");
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  private async tx<T>(mode: IDBTransactionMode, fn: (s: IDBObjectStore) => IDBRequest<T>): Promise<T> {
    const db = await this.db;
    return new Promise((resolve, reject) => {
      const req = fn(db.transaction("kv", mode).objectStore("kv"));
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async get<T>(key: string): Promise<T | undefined> {
    const v = await this.tx("readonly", (s) => s.get(key));
    return v === undefined ? undefined : (JSON.parse(v as string) as T);
  }

  async set<T>(key: string, value: T): Promise<void> {
    await this.tx("readwrite", (s) => s.put(JSON.stringify(value), key));
  }

  async delete(key: string): Promise<void> {
    await this.tx("readwrite", (s) => s.delete(key));
  }

  async keys(prefix = ""): Promise<string[]> {
    const all = (await this.tx("readonly", (s) => s.getAllKeys())) as IDBValidKey[];
    return all.map(String).filter((k) => k.startsWith(prefix)).sort();
  }
}
