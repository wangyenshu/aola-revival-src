// The revival's 沙盒 (not of 2013; the control bar's button under the 工具箱, rebuilt control
// SandboxPanel): fights the player sets up, a 关卡 of up to SANDBOX_MAX opponents fought one
// after another, each of any 亚比 that can fight, at a level up to SANDBOX_MAX_LEVEL, its stats
// multiplied as the player wants. A win brings no experience, effort points or evolution. With
// "heal" (the default), the bag's 亚比 have their 体力 and PP back before each fight.
//
//   SundriesExtension.revival_sandbox {lv, i}  -> revival_sandbox {res: 1, i, n, race, level}
//                                                 then the battle (2303, 2401 …) with the i-th
//                                                 opponent of the 关卡 lv (its JSON text), or a
//                                                 refusing 2303 and revival_sandbox {res: 0, msg: ""};
//                                              -> revival_sandbox {res: 0, msg} when lv is not a 关卡
//
// The 关卡 file (exported and imported by the panel; docs/SANDBOX.md):
//   {"format": "aola-revival-level", "version": 1, "name": "…", "heal": true,
//    "enemies": [{"race": 605, "level": 150, "hp": 100, "at": 100, "de": 100, "sa": 100, "sd": 100, "sp": 100}, …]}
// hp … sp are percentages of the stats the 亚比 has at that level (100: as it is).

import type { World, XtContext } from "./server.ts";
import { speciesOf, statsOf, type PetOwner, type PetTables } from "./pets.ts";

export const SANDBOX_FORMAT = "aola-revival-level";
export const SANDBOX_MAX = 10;
export const SANDBOX_MAX_LEVEL = 999;
/** Stat percentages allowed (1% to 100 times). */
export const SANDBOX_PCT: [number, number] = [1, 10000];
export const STAT_KEYS = ["hp", "at", "de", "sa", "sd", "sp"] as const;

export interface SandboxEnemy {
  race: number;
  level: number;
  /** Stat factors, hp first (1 = as it is). */
  mul: number[];
}

export interface SandboxLevel {
  name: string;
  /** The bag's 亚比 healed before each fight. */
  heal: boolean;
  enemies: SandboxEnemy[];
}

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));

/** A 关卡 from its JSON text, or the reason it is not one. `fights` says whether a race can fight. */
export function parseSandboxLevel(text: unknown, fights: (race: number) => boolean): SandboxLevel | string {
  let j: unknown;
  try {
    j = typeof text === "string" ? JSON.parse(text) : text;
  } catch {
    return "这不是关卡文件";
  }
  if (!j || typeof j !== "object") return "这不是关卡文件";
  const o = j as { format?: unknown; name?: unknown; heal?: unknown; enemies?: unknown };
  if (o.format !== undefined && o.format !== SANDBOX_FORMAT) return "这不是奥拉星的关卡文件";
  if (!Array.isArray(o.enemies) || o.enemies.length === 0) return "关卡里还没有对手";
  if (o.enemies.length > SANDBOX_MAX) return `一个关卡最多${SANDBOX_MAX}个对手`;
  const enemies: SandboxEnemy[] = [];
  for (const [i, e] of o.enemies.entries()) {
    if (!e || typeof e !== "object") return `第${i + 1}个对手不对`;
    const r = e as Record<string, unknown>;
    const race = Math.floor(Number(r.race));
    if (!(race > 0) || !fights(race)) return `第${i + 1}个对手（编号${r.race}）不能对战`;
    const level = clamp(Math.floor(Number(r.level)) || 1, 1, SANDBOX_MAX_LEVEL);
    const mul = STAT_KEYS.map((k) => {
      const v = r[k] === undefined ? 100 : Number(r[k]);
      return clamp(Number.isFinite(v) ? v : 100, SANDBOX_PCT[0], SANDBOX_PCT[1]) / 100;
    });
    enemies.push({ race, level, mul });
  }
  return { name: String(o.name ?? "").slice(0, 30), heal: o.heal !== false, enemies };
}

/** Starts the fight; false when it could not (a battle still open, no 亚比 able to fight: told in a 2303). */
export type SandboxBegin = (ctx: XtContext, race: number, level: number, sandbox: { mul: number[] }) => Promise<boolean>;

export interface SandboxDeps {
  load: (ctx: XtContext) => Promise<PetOwner>;
  save: (o: PetOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
  begin: SandboxBegin;
}

export function installSandbox(world: World, deps: SandboxDeps): void {
  world.xt("SundriesExtension.revival_sandbox", async (ctx) => {
    const t = await deps.tables();
    const lv = parseSandboxLevel(ctx.params.lv, (race) => !!speciesOf(t, race));
    if (typeof lv === "string") return ctx.reply({ res: 0, msg: lv });
    const i = clamp(Math.floor(Number(ctx.params.i)) || 0, 0, lv.enemies.length - 1);
    const e = lv.enemies[i];
    if (lv.heal) {
      const o = await deps.load(ctx);
      for (const p of o.pets ?? []) {
        p.hp = statsOf(p, t)[0];
        for (const s of p.skills ?? []) s.pp = s.max;
      }
      await deps.save(o);
    }
    // Told before the battle starts (the client then knows the opponent it waits for); a start
    // that is refused says so again, with no words of its own (the 2303 said why).
    ctx.reply({ res: 1, i, n: lv.enemies.length, race: e.race, level: e.level });
    if (!(await deps.begin(ctx, e.race, e.level, { mul: e.mul }))) ctx.reply({ res: 0, msg: "" });
  });
}
