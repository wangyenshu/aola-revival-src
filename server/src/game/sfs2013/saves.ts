// 存档 files (the 工具箱's 导出存档 / 导入存档), one format for both modes. The page's own
// game (单机模式, web/saves.js) exports every key of its store; a shared server (联机模式)
// exports one 奥拉. Either file goes into either mode:
//
//   {format: "aola-revival-save", version: 1, saved: "<ISO time>", data: {<store key>: value}}
//
// The keys are the store's: "user/<encodeURIComponent(name)>" an 奥拉's record, "uid/<id>"
// the name of an id, "meta/nextUserId" the last id given; a page's file also has the page's
// boards ("parkour/board" …) and the 足迹 of its homes ("visits/<id>").
//
// A server's file holds the 奥拉 without what is the server's alone: the password, and the
// friends (ids of that server's players). An imported 奥拉 keeps those of the server's
// (and its id and name there): only the game in it comes from the file.

export const SAVE_FORMAT = "aola-revival-save";
export const SAVE_VERSION = 1;
/** An 奥拉's record in a file, as JSON in UTF-8 bytes, at most (a Durable Object value is at most 2 MB). */
export const SAVE_RECORD_MAX = 1_500_000;

/** The UTF-8 size of a value as JSON (what a store keeps). */
export const jsonBytes = (v: unknown) => new TextEncoder().encode(JSON.stringify(v)).length;
/** An import's request body, at most: the file and a little more. */
export const SAVE_BODY_MAX = 2_000_000;

export interface SaveFile {
  format: string;
  version: number;
  saved?: string;
  data: Record<string, unknown>;
}

/** The fields of a record that are the server's, never a file's. */
const SERVER_FIELDS = ["id", "name", "pass", "friends", "friendAsks"] as const;

/** The kinds the game's code expects of a record's fields (game.ts UserRecord and the others). */
const KINDS: Record<string, "array" | "object" | "number" | "string" | "boolean"> = {
  pets: "array",
  storage: "array",
  training: "array",
  plants: "array",
  items: "object",
  house: "object",
  tasks: "object",
  robot: "object",
  boosts: "object",
  hatch: "object",
  gameLevels: "object",
  gathered: "object",
  gameCoins: "object",
  dailyFights: "object",
  bossWins: "object",
  boardDay: "object",
  tower: "object",
  saplings: "object",
  sevenstar: "object",
  kings: "object",
  wushen: "object",
  gods: "object",
  score: "number",
  xingbi: "number",
  jingdou: "number",
  aobi: "number",
  nextPetId: "number",
  followPet: "number",
  catchExp: "number",
  nextPlantId: "number",
  avatar: "string",
  createdAt: "string",
  kit: "boolean",
  vip: "boolean",
};

const kindOf = (v: unknown) => (Array.isArray(v) ? "array" : v === null ? "null" : typeof v);
const isObject = (v: unknown): v is Record<string, unknown> => kindOf(v) === "object";
const num = (v: unknown, lo: number, hi: number): number | undefined =>
  typeof v === "number" && Number.isFinite(v) ? Math.max(lo, Math.min(hi, v)) : undefined;
const int = (v: unknown, lo: number, hi: number): number | undefined => {
  const n = num(v, lo, hi);
  return n === undefined ? undefined : Math.trunc(n);
};
const str = (v: unknown, max: number): string | undefined => (typeof v === "string" ? v.slice(0, max) : undefined);
const nums = (v: unknown, n: number, lo: number, hi: number): number[] | undefined => {
  if (!Array.isArray(v) || v.length !== n) return undefined;
  const out = v.map((x) => num(x, lo, hi));
  return out.every((x) => x !== undefined) ? (out as number[]) : undefined;
};

/**
 * A 亚比 of a file rebuilt from the fields the game's code reads (pets.ts PetRecord), each of its
 * kind and in range; anything else is left out. null: not a 亚比 (no id, race or level). The
 * battle code reads these fields where no request catches an error (亚比对战's timer), so none
 * may be of another kind.
 */
export function fitPet(v: unknown): Record<string, unknown> | null {
  if (!isObject(v)) return null;
  const id = int(v.id, 1, 1e9), race = int(v.race, 1, 1e7), level = int(v.level, 1, 100);
  if (id === undefined || race === undefined || level === undefined) return null;
  const skills = (Array.isArray(v.skills) ? v.skills : []).flatMap((k) => {
    if (!isObject(k)) return [];
    const sid = int(k.id, 0, 1e7), max = int(k.max, 0, 1000), pp = int(k.pp, 0, 1000);
    return sid === undefined ? [] : [{ id: sid, name: str(k.name, 32) ?? "", pp: Math.min(pp ?? max ?? 0, max ?? 1000), max: max ?? pp ?? 0 }];
  });
  const out: Record<string, unknown> = {
    id,
    race,
    level,
    exp: num(v.exp, 0, 1e12) ?? 0,
    hp: num(v.hp, 0, 1e7) ?? 0,
    character: str(v.character, 16) ?? "",
    skills: skills.slice(0, 8),
    got: str(v.got, 32) ?? "",
  };
  const nick = str(v.nick, 32);
  if (nick !== undefined) out.nick = nick;
  if (Array.isArray(v.learned)) out.learned = v.learned.flatMap((x) => (int(x, 0, 1e7) === undefined ? [] : [int(x, 0, 1e7)!])).slice(0, 500);
  const iv = nums(v.iv, 6, 0, 31), ev = nums(v.ev, 6, 0, 1e6), mul = nums(v.mul, 6, 0, 1e4);
  if (iv && ev) {
    out.iv = iv.map(Math.trunc);
    out.ev = ev;
  }
  if (mul) out.mul = mul;
  const mod = str(v.mod, 64);
  if (mod !== undefined) out.mod = mod;
  if (typeof v.fixed === "boolean") out.fixed = v.fixed;
  if (isObject(v.buff) && int(v.buff.i, 0, 5) !== undefined && num(v.buff.add, -1e6, 1e6) !== undefined) {
    out.buff = { i: int(v.buff.i, 0, 5), add: num(v.buff.add, -1e6, 1e6) };
  }
  if (Array.isArray(v.cards)) out.cards = v.cards.slice(0, 3).map((x) => int(x, 0, 1e7) ?? 0);
  return out;
}

/** Owned materials (type -> id -> quantity): numbers only. */
function fitItems(v: unknown): Record<string, Record<string, number>> {
  const out: Record<string, Record<string, number>> = {};
  if (!isObject(v)) return out;
  for (const [type, ids] of Object.entries(v)) {
    if (!isObject(ids)) continue;
    const row: Record<string, number> = {};
    for (const [id, q] of Object.entries(ids)) {
      const n = int(q, 0, 1e9);
      if (n !== undefined) row[id] = n;
    }
    out[type] = row;
  }
  return out;
}

/** Whether this is a 存档 file (of either mode); why not, else null. */
export function fileProblem(file: unknown): string | null {
  if (!isObject(file) || file.format !== SAVE_FORMAT || !isObject(file.data)) return "这不是奥拉星的存档文件。";
  if (typeof file.version !== "number" || file.version > SAVE_VERSION) return "这个存档文件是更新的版本，这里读不了。";
  return null;
}

/** The 奥拉 in a file: name -> record (its "user/…" keys). */
export function rolesOf(file: SaveFile): Map<string, Record<string, unknown>> {
  const out = new Map<string, Record<string, unknown>>();
  for (const [k, v] of Object.entries(file.data)) {
    if (!k.startsWith("user/") || !isObject(v)) continue;
    let name: string;
    try {
      name = typeof v.name === "string" && v.name ? v.name : decodeURIComponent(k.slice("user/".length));
    } catch {
      continue;
    }
    out.set(name, v);
  }
  return out;
}

/** One 奥拉 as a file: the record without the server's own fields, its id's name, the id counter. */
export function playerFile(rec: { id: number; name: string } & Record<string, unknown>, key: string, saved: string): SaveFile {
  const copy = structuredClone(rec) as Record<string, unknown>;
  delete copy.pass;
  delete copy.friends;
  delete copy.friendAsks;
  return {
    format: SAVE_FORMAT,
    version: SAVE_VERSION,
    saved,
    // uid and the counter: the page that takes the file in knows the id, and gives the next 奥拉 another.
    data: { [key]: copy, [`uid/${rec.id}`]: rec.name, "meta/nextUserId": rec.id },
  };
}

/**
 * A file's record made this server's 奥拉's: what the game keeps comes from the file, the server's
 * own fields (id, name, password, friends) from the 奥拉 here. Fields of the wrong kind are dropped,
 * and 亚比 that are not 亚比 (no id or race) left out, so the game's code reads what it expects.
 */
export function adoptRecord(from: Record<string, unknown>, here: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(structuredClone(from))) {
    if ((SERVER_FIELDS as readonly string[]).includes(k)) continue;
    const want = KINDS[k];
    if (want && kindOf(v) !== want) continue;
    if (want === "number" && !Number.isFinite(v)) continue;
    out[k] = v;
  }
  // Rebuilt, and each id once in the bag and the 仓库 (an id twice would be one 亚比 to the game).
  const seen = new Set<unknown>();
  for (const k of ["pets", "storage"] as const) {
    if (!Array.isArray(out[k])) continue;
    out[k] = (out[k] as unknown[]).flatMap((p) => {
      const f = fitPet(p);
      if (!f || seen.has(f.id)) return [];
      seen.add(f.id);
      return [f];
    });
  }
  // The bag holds six (game.ts UserRecord): the rest go to the 仓库.
  if (Array.isArray(out.pets) && out.pets.length > 6) {
    out.storage = [...((out.storage as unknown[]) ?? []), ...out.pets.slice(6)];
    out.pets = out.pets.slice(0, 6);
  }
  if (out.items !== undefined) out.items = fitItems(out.items);
  // The 亚比 id counter (the last id given, pets.ts) at least the highest id there: a file whose
  // counter is behind would give an id twice.
  const ids = [...((out.pets as { id: number }[]) ?? []), ...((out.storage as { id: number }[]) ?? [])].map((p) => p.id);
  if (ids.length) out.nextPetId = Math.max(Number(out.nextPetId) || 0, ...ids);
  for (const k of SERVER_FIELDS) if (here[k] !== undefined) out[k] = structuredClone(here[k]);
  if (out.createdAt === undefined && here.createdAt !== undefined) out.createdAt = here.createdAt;
  return out;
}
