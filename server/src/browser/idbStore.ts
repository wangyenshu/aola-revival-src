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
    // Done when the transaction is: a write is kept only once it commits (a full disk fails
    // there, after the request itself succeeded).
    return new Promise((resolve, reject) => {
      const t = db.transaction("kv", mode);
      const req = fn(t.objectStore("kv"));
      t.oncomplete = () => resolve(req.result);
      t.onabort = () => reject(t.error ?? req.error ?? new Error("IndexedDB transaction aborted"));
      t.onerror = () => reject(t.error ?? req.error);
    });
  }

  async get<T>(key: string): Promise<T | undefined> {
    const v = await this.tx("readonly", (s) => s.get(key));
    return v === undefined ? undefined : (JSON.parse(v as string) as T);
  }

  async set<T>(key: string, value: T): Promise<void> {
    await this.setText(key, JSON.stringify(value));
  }

  async setText(key: string, json: string): Promise<void> {
    await this.tx("readwrite", (s) => s.put(json, key));
  }

  async delete(key: string): Promise<void> {
    await this.tx("readwrite", (s) => s.delete(key));
  }

  async keys(prefix = ""): Promise<string[]> {
    const all = (await this.tx("readonly", (s) => s.getAllKeys())) as IDBValidKey[];
    return all.map(String).filter((k) => k.startsWith(prefix)).sort();
  }
}
