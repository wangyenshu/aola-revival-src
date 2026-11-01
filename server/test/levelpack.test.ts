// The 沙盒 关卡 editor's pure logic (tools/level-editor/pack.js; docs/SANDBOX.md, format version 2):
// checking packs against the format and its limits, version 1 to 2, ids, renames and merging.
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { test } from "node:test";
import { crc32, deflateSync, inflateRawSync, inflateSync } from "node:zlib";

const require = createRequire(import.meta.url);
const P = require("../../tools/level-editor/pack.js");

interface Problem {
  severity: "error" | "warning";
  where: string;
  message: string;
  loc: { kind: string; image?: string; level?: number; room?: number; index?: number; spawn?: string; member?: number };
}
type Obj = Record<string, any>;

/** A PNG data: URL of a w×h picture of one gray level (rows deflated, so even 2880×560 is small). */
function png(w: number, h: number, gray = 200): string {
  const chunk = (type: string, data: Buffer) => {
    const head = Buffer.alloc(4);
    head.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(body));
    return Buffer.concat([head, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; // bit depth; colour type 0: gray
  const raw = Buffer.alloc(h * (w + 1), gray);
  for (let y = 0; y < h; y++) raw[y * (w + 1)] = 0;
  const file = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
  return "data:image/png;base64," + file.toString("base64");
}

/** A JPEG data: URL with only the markers the size is read from (SOI, APP0, SOF0, EOI). */
function jpeg(w: number, h: number): string {
  const b = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0,
    0xff, 0xc0, 0x00, 0x11, 0x08, h >> 8, h & 255, w >> 8, w & 255, 3, 1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1,
    0xff, 0xd9,
  ]);
  return "data:image/jpeg;base64," + b.toString("base64");
}

const BG = png(960, 560);
const WIDE = png(1440, 560, 180);

/** Two 关卡: l1 of two rooms joined both ways, a door to l2 and a 通关 door; l2 of one room. */
function samplePack(): Obj {
  return {
    format: "aola-revival-level",
    version: 2,
    name: "测试包",
    author: "",
    images: { bg1: BG, bg2: WIDE, mask1: png(96, 56, 0), tree: png(40, 60, 90), fg1: png(960, 560, 255), photo: jpeg(960, 560) },
    levels: [
      {
        id: "l1",
        name: "第一关",
        heal: true,
        start: "r1",
        next: "l2",
        rooms: [
          {
            id: "r1",
            name: "入口",
            background: "bg1",
            mask: "mask1",
            overlay: "fg1",
            music: "music/fbaixi.mp3",
            props: [{ image: "tree", at: [300, 200], front: false }],
            spawns: { start: [480, 470], fromr2: [800, 420] },
            doors: [
              { rect: [900, 300, 60, 160], to: "r2", spawn: "fromr1", open: "always", label: "下一个房间" },
              { rect: [0, 300, 40, 160], to: "l2/r1", open: "cleared" },
            ],
            enemies: [{ id: "e1", at: [600, 380], name: "守卫", boss: false, team: [{ race: 43, level: 60 }, { race: 1, level: 5, hp: 200, sp: 50 }] }],
          },
          {
            id: "r2",
            name: "深处",
            background: "bg2",
            props: [{ image: "tree", at: [700, 150], front: true }],
            spawns: { start: [100, 450], fromr1: [120, 400] },
            doors: [
              { rect: [0, 300, 60, 160], to: "r1", spawn: "fromr2" },
              { rect: [1300, 0, 100, 60], to: "#finish", open: "cleared", label: "通关" },
            ],
            enemies: [{ id: "boss", at: [1000, 420], name: "首领", boss: true, team: [{ race: 605, level: 999, hp: 10000, at: 1 }] }],
          },
        ],
      },
      {
        id: "l2",
        name: "第二关",
        start: "r1",
        rooms: [
          {
            id: "r1",
            background: "photo",
            spawns: { start: [480, 470] },
            doors: [
              { rect: [900, 300, 60, 160], to: "#finish" },
              { rect: [0, 300, 60, 160], to: "#exit", label: "回去" },
            ],
          },
        ],
      },
    ],
  };
}

const clone = (o: Obj): Obj => JSON.parse(JSON.stringify(o));
const check = (pack: unknown, opts?: Obj): Problem[] => P.validate(pack, opts);
const errors = (ps: Problem[]) => ps.filter((p) => p.severity === "error");
function has(ps: Problem[], severity: "error" | "warning", re: RegExp): Problem {
  const p = ps.find((x) => x.severity === severity && re.test(x.message));
  assert.ok(p, `expected a ${severity} matching ${re}; got:\n${ps.map((x) => `${x.severity} ${x.where}: ${x.message}`).join("\n")}`);
  return p!;
}

test("a well-formed pack has no problems, and what is written reads back the same", () => {
  const pack = samplePack();
  assert.deepEqual(check(pack), []);
  const held = P.normalize(pack);
  // Missing stats are 100, a missing level 1; empty lists and maps are there.
  assert.deepEqual(held.levels[0].rooms[0].enemies[0].team[0], { race: 43, level: 60, hp: 100, at: 100, de: 100, sa: 100, sd: 100, sp: 100 });
  assert.deepEqual(held.levels[1].rooms[0].enemies, []);
  assert.deepEqual(held.levels[1].rooms[0].props, []);
  const out = P.serialize(held);
  assert.deepEqual(check(out), []);
  assert.deepEqual(JSON.parse(P.stringify(out)), out);
  // Empty optional fields are left out; open and the booleans are written.
  const door = out.levels[1].rooms[0].doors[0];
  assert.deepEqual(door, { rect: [900, 300, 60, 160], to: "#finish", open: "always" });
  assert.equal("next" in out.levels[1], false);
  assert.equal(out.levels[1].heal, true);
  assert.equal("mask" in out.levels[1].rooms[0], false);
  assert.equal(P.packBytes(held), Buffer.byteLength(P.stringify(out)));
  // Points and opponents stay on one line, as in docs/SANDBOX.md.
  assert.match(P.stringify(out), /"spawns": \{ "start": \[480, 470\], "fromr2": \[800, 420\] \}/);
});

test("pictures: PNG and JPG sizes are read from the data, and their limits checked", () => {
  assert.deepEqual(P.imageInfo(WIDE), { mime: "png", type: "png", bytes: P.imageInfo(WIDE).bytes, width: 1440, height: 560, mismatch: false });
  assert.equal(P.imageInfo(jpeg(2000, 400)).width, 2000);
  assert.equal(P.imageInfo(jpeg(2000, 400)).height, 400);
  assert.match(P.imageInfo("data:image/gif;base64,R0lGODlhAQABAAAAACw=").error, /PNG 或 JPG/);
  assert.match(P.imageInfo("data:image/png;base64,abc def").error, /base64/);
  assert.match(P.imageInfo("data:image/png;base64," + Buffer.from("not a picture at all").toString("base64")).error, /不是 PNG 也不是 JPG/);

  const pack = samplePack();
  pack.images.huge = png(2881, 560);
  pack.images.tall = png(960, 561);
  pack.images.liar = "data:image/jpeg;base64," + BG.split(",")[1]; // a PNG said to be a JPG
  pack.levels[0].rooms[0].props.push({ image: "huge", at: [0, 0] }, { image: "tall", at: [0, 0] }, { image: "liar", at: [0, 0] });
  const ps = check(pack);
  const huge = has(ps, "error", /2881×560 太大/);
  assert.deepEqual(huge.loc, { kind: "image", image: "huge" });
  has(ps, "error", /960×561 太大/);
  has(ps, "warning", /标为 JPG，内容却是 PNG/);

  // A background sets the room's size: 560 high, 960 to 2880 wide (warnings), and its limits.
  const small = samplePack();
  small.images.bg1 = png(900, 500);
  const sp = check(small);
  has(sp, "warning", /背景高 500/);
  has(sp, "warning", /背景宽 900/);
  // A mask is scaled to the background: a different shape is warned about.
  const stretched = samplePack();
  stretched.images.mask1 = png(50, 50, 0);
  has(check(stretched), "warning", /长宽比/);
  // A picture no room uses makes the file bigger for nothing.
  const unused = samplePack();
  unused.images.spare = png(10, 10);
  assert.deepEqual(has(check(unused), "warning", /没有房间用到/).loc, { kind: "image", image: "spare" });
});

test("the format's limits: pictures, 关卡, rooms, doors, opponents, teams, levels and stats", () => {
  const many = <T,>(n: number, f: (i: number) => T): T[] => Array.from({ length: n }, (_, i) => f(i));
  const base = () => samplePack();

  let p = base();
  for (let i = 0; i < 59; i++) p.images["x" + i] = BG; // 6 + 59 = 65
  has(check(p), "error", /最多 64 张图片/);

  p = base();
  p.levels = many(21, (i) => Object.assign(clone(samplePack().levels[1]), { id: "l" + i }));
  has(check(p), "error", /最多 20 个关卡/);

  p = base();
  p.levels[1].rooms = many(21, (i) => Object.assign(clone(samplePack().levels[1].rooms[0]), { id: "r" + (i + 1) }));
  has(check(p), "error", /最多 20 个房间/);

  p = base();
  const r1 = p.levels[0].rooms[0];
  r1.doors = many(17, (i) => ({ rect: [i * 50, 0, 40, 40], to: "#exit" }));
  r1.enemies = many(13, (i) => ({ id: "e" + i, at: [100 + i * 50, 400], team: [{ race: 1 }] }));
  r1.props = many(33, () => ({ image: "tree", at: [0, 0] }));
  r1.spawns = Object.fromEntries(many(17, (i): [string, number[]] => [i === 0 ? "start" : "s" + i, [10 + i * 50, 520]]));
  const ps = check(p);
  has(ps, "error", /最多 16 扇门/);
  has(ps, "error", /最多 12 个对手/);
  has(ps, "error", /最多 32 个道具/);
  has(ps, "error", /最多 16 个入口点/);

  p = base();
  const e1 = p.levels[0].rooms[0].enemies[0];
  e1.team = many(11, () => ({ race: 1, level: 1 }));
  has(check(p), "error", /队伍最多 10 只/);
  e1.team = [];
  has(check(p), "error", /队伍里还没有亚比/);
  e1.team = [
    { race: 0, level: 1000 },
    { race: "43", level: 1.5, hp: 0, at: 10001, de: 1, sd: 10000, sp: "100" },
  ];
  const tp = check(p);
  const race0 = has(tp, "error", /race 应为 1 以上的整数，现在是 0/);
  assert.deepEqual(race0.loc, { kind: "enemy", level: 0, room: 0, index: 0, member: 0 });
  assert.match(race0.where, /对手 1「守卫」 \(e1\) › 队伍第 1 只/);
  has(tp, "error", /race 应为 1 以上的整数，现在是 "43"/);
  has(tp, "error", /等级应为 1–999 的整数，现在是 1000/);
  has(tp, "error", /等级应为 1–999 的整数，现在是 1.5/);
  has(tp, "error", /体力（hp）应为 1–10000/);
  has(tp, "error", /攻击（at）应为 1–10000/);
  has(tp, "error", /速度（sp）应为 1–10000.*"100"/);
  assert.equal(errors(tp).filter((x) => /防御|特防/.test(x.message)).length, 0); // 1 and 10000 are allowed

  // Names: pack, author, 关卡 and rooms 30, door labels and opponents' names 20 (characters, not bytes).
  p = base();
  p.name = "关".repeat(31);
  p.author = "a".repeat(30);
  p.levels[0].rooms[0].doors[0].label = "门".repeat(21);
  p.levels[0].rooms[0].enemies[0].name = "守".repeat(20);
  const np = check(p);
  has(np, "error", /包的名字最多 30 个字/);
  has(np, "error", /门上的字最多 20 个字/);
  assert.equal(np.filter((x) => /作者|对手名字/.test(x.message)).length, 0);

  // 16 MB a file.
  p = base();
  p.images.bg1 = BG + "A".repeat(16_000_000);
  has(check(p), "error", /超过了 16 MB/);
});

test("ids, door targets and other references", () => {
  let p = samplePack();
  p.levels[0].rooms[1].id = "r 2";
  p.levels[1].id = "l1";
  p.levels[0].rooms[0].enemies[0].id = "守卫";
  p.images["bad id"] = BG;
  let ps = check(p);
  has(ps, "error", /房间编号 "r 2" 不对/);
  has(ps, "error", /关卡编号 l1 重复了/);
  has(ps, "error", /对手编号 "守卫" 不对/);
  has(ps, "error", /图片编号只能用/);

  p = samplePack();
  const [l1, l2] = p.levels;
  l1.start = "nowhere";
  l2.next = "l9";
  l1.rooms[1].background = "missing";
  l1.rooms[0].doors.push(
    { rect: [100, 0, 50, 50], to: "r9" },
    { rect: [200, 0, 50, 50], to: "l9/r1" },
    { rect: [300, 0, 50, 50], to: "l2/r1", spawn: "nope" },
    { rect: [400, 0, 50, 50], to: "l1/r2/x" },
    { rect: [500, 0, 50, 50], to: "#win" },
    { rect: [600, 0, 0, 50], to: "#finish", spawn: "start", open: "sometimes" },
  );
  l1.rooms[0].music = "bgm/fbaixi.ogg";
  ps = check(p);
  has(ps, "error", /起始房间 nowhere 不在这个关卡里/);
  has(ps, "error", /下一关 l9 不在这个包里/);
  has(ps, "error", /背景用的图片 missing 不在包里/);
  const r9 = has(ps, "error", /门通向的房间 r9 不在这个关卡里/);
  assert.deepEqual(r9.loc, { kind: "door", level: 0, room: 0, index: 2 });
  has(ps, "error", /门通向的关卡 l9 不在包里/);
  has(ps, "error", /目标房间 r1 里没有入口点 nope/);
  has(ps, "error", /门通向 "l1\/r2\/x" 不对/);
  has(ps, "error", /门通向 "#win" 不对/);
  has(ps, "error", /门的宽和高要大于 0/);
  has(ps, "error", /open 应为 "always" 或 "cleared"/);
  has(ps, "warning", /通关或离开的门用不到入口点/);
  has(ps, "error", /音乐 "bgm\/fbaixi.ogg" 应写成 music\//);

  // Likely mistakes are warnings.
  p = samplePack();
  p.levels[1].rooms[0].doors.push({ rect: [0, 0, 50, 50], to: "#exit", open: "cleared" }); // no opponents there
  p.levels[1].rooms[0].doors[0].rect = [450, 450, 60, 60]; // the start point is inside it
  p.levels[0].rooms[1].doors.shift(); // r2 still reachable from r1, but nothing leads back
  p.levels[0].rooms[0].doors[0] = { rect: [900, 300, 60, 160], to: "r1" }; // and now nothing leads to r2
  p.levels[0].rooms[1].enemies[0].id = "e1"; // the same opponent id in two rooms of a 关卡
  delete p.levels[0].rooms[0].spawns.start; // the start room without a start point
  p.levels[0].rooms[1].doors[0].to = "#exit"; // no 通关 door in l1
  ps = check(p);
  has(ps, "warning", /这个房间没有对手/);
  has(ps, "warning", /入口点 start 在这扇门里/);
  assert.deepEqual(has(ps, "warning", /从起始房间走不到这个房间/).loc, { kind: "room", level: 0, room: 1 });
  has(ps, "warning", /别的房间里也有/);
  has(ps, "warning", /没有名叫 start 的入口点/);
  has(ps, "warning", /没有通关的门/);
  has(ps, "warning", /门没写入口点，目标房间 r1 又没有 start 入口点/);

  // Positions on walls, when the caller can tell (the editor reads the masks).
  p = samplePack();
  const onWall = check(p, { wallAt: (room: Obj, x: number, y: number) => room.id === "r1" && y > 450 });
  has(onWall, "warning", /入口点站在墙里/);
  // Unknown 亚比, when the names are given.
  has(check(p, { names: { "1": "兔小子", "43": "小冰犬" } }), "warning", /图鉴里没有编号 605/);
});

test("mask pixels: alpha under 128 is floor; otherwise dark (luminance under 128) is wall", () => {
  assert.equal(P.isWallPixel(0, 0, 0, 255), true);
  assert.equal(P.isWallPixel(0, 0, 0, 128), true);
  assert.equal(P.isWallPixel(0, 0, 0, 127), false);
  assert.equal(P.isWallPixel(255, 255, 255, 255), false);
  assert.equal(P.isWallPixel(127, 127, 127, 255), true);
  assert.equal(P.isWallPixel(129, 129, 129, 255), false); // (128 gray sits on the line: computed as the game does)
  assert.equal(P.isWallPixel(255, 0, 0, 255), true); // pure red is dark (luminance 76)
});

test("a version-1 fight list becomes a pack of one 关卡 of one room", () => {
  const v1 = { format: "aola-revival-level", version: 1, name: "试炼", heal: false, enemies: [{ race: 43, level: 150, hp: 300 }, { race: 605 }] };
  assert.equal(P.detect(v1), "v1");
  assert.equal(P.detect({ enemies: [{ race: 1 }] }), "v1");
  assert.equal(P.detect(samplePack()), "v2");
  assert.equal(P.detect({ format: "other", enemies: [] }), null);
  assert.equal(P.detect([1, 2]), null);
  assert.deepEqual(check(v1), []);
  has(check({ enemies: Array.from({ length: 11 }, () => ({ race: 1 })) }), "error", /最多 10 个对手/);
  has(check({ enemies: [{ race: 1, level: 0 }] }), "error", /等级应为/);

  const pack = P.fromV1(v1);
  assert.equal(P.detect(pack), "v2");
  assert.deepEqual(check(P.serialize(pack)), []);
  assert.equal(pack.name, "试炼");
  const level = pack.levels[0];
  assert.equal(level.heal, false);
  assert.equal(level.rooms.length, 1);
  const room = level.rooms[0];
  assert.equal(level.start, room.id);
  assert.deepEqual(P.imageInfo(pack.images[room.background]).width, 960);
  assert.deepEqual(P.imageInfo(pack.images[room.background]).height, 560);
  // The opponents are one team, fought one after another as in version 1, missing values filled in.
  assert.equal(room.enemies.length, 1);
  assert.deepEqual(room.enemies[0].team, [
    { race: 43, level: 150, hp: 300, at: 100, de: 100, sa: 100, sd: 100, sp: 100 },
    { race: 605, level: 1, hp: 100, at: 100, de: 100, sa: 100, sd: 100, sp: 100 },
  ]);
  // A door that opens once they are beaten clears the 关卡.
  assert.deepEqual(room.doors.map((d: Obj) => [d.to, d.open]), [["#finish", "cleared"]]);
  assert.ok("start" in room.spawns);
  // A picture of the caller's own may be given.
  assert.equal(P.fromV1(v1, { background: WIDE }).images.bg, WIDE);
});

test("ids and file names", () => {
  assert.equal(P.sanitizeId("bg forest.jpg"), "bg_forest");
  assert.equal(P.sanitizeId("森林背景.png", "img1"), "img1");
  assert.equal(P.sanitizeId("a".repeat(40)), "a".repeat(32));
  assert.equal(P.sanitizeId("tree-2(copy).PNG"), "tree-2copy");
  assert.equal(P.uniqueId("r1", ["r1", "r2"]), "r3");
  assert.equal(P.uniqueId("bg", new Set(["bg"])), "bg-2");
  assert.equal(P.uniqueId("e1", (s: string) => s === "e1"), "e2");
  assert.equal(P.uniqueId("x".repeat(32), ["x".repeat(32)]).length, 32);
  assert.equal(P.idProblem("r 1", []), "编号只能用英文字母、数字、_ 和 -，最多 32 个");
  assert.equal(P.idProblem("r1", ["r1"], "r2"), "编号 r1 已经有了");
  assert.equal(P.idProblem("r1", ["r1"], "r1"), "");
  assert.equal(P.fileName("我的关卡包"), "aola-levels.json");
  assert.equal(P.fileName(""), "aola-levels.json");
  assert.equal(P.fileName("My Pack 2！第二版"), "aola-levels-MyPack2.json");
  assert.deepEqual(P.parseTarget("l2/r1"), { kind: "room", level: "l2", room: "r1" });
  assert.deepEqual(P.parseTarget("r2"), { kind: "room", level: null, room: "r2" });
  assert.deepEqual(P.parseTarget("#finish"), { kind: "finish" });
  assert.equal(P.parseTarget("a/b/c"), null);
});

test("renames keep every reference; merging renames what is taken", () => {
  const pack = P.normalize(samplePack());
  const [l1, l2] = pack.levels;
  P.renameRoom(pack, l1, l1.rooms[0], "hall");
  assert.equal(l1.start, "hall");
  assert.equal(l1.rooms[1].doors[0].to, "hall");
  P.renameLevel(pack, l2, "two");
  assert.equal(l1.next, "two");
  assert.equal(l1.rooms[0].doors[1].to, "two/r1");
  P.renameSpawn(pack, l1, l1.rooms[0], "fromr2", "back");
  assert.deepEqual(Object.keys(l1.rooms[0].spawns), ["start", "back"]);
  assert.equal(l1.rooms[1].doors[0].spawn, "back");
  P.renameImage(pack, "bg1", "meadow");
  assert.equal(l1.rooms[0].background, "meadow");
  assert.equal(Object.keys(pack.images)[0], "meadow");
  assert.deepEqual(P.imageUses(pack, "tree"), [
    { level: 0, room: 0, field: "prop", index: 0 },
    { level: 0, room: 1, field: "prop", index: 0 },
  ]);
  assert.deepEqual(P.doorsTo(pack, l2, "r1"), [{ level: 0, room: 0, index: 1 }]);
  assert.deepEqual(check(P.serialize(pack)), []);

  const into = P.normalize(samplePack());
  into.images.bg1 = png(960, 560, 10); // another picture under the same id
  const r = P.mergeInto(into, samplePack());
  assert.equal(r.added, 2);
  assert.deepEqual(r.levels, { l1: "l3", l2: "l4" });
  // bg1 is taken by another picture (and bg2 too): the incoming bg1 becomes bg3. The incoming
  // bg2 is the same picture as the bg2 there, so that one is used again.
  assert.equal(r.images.bg1, "bg3");
  assert.equal(r.images.bg2, "bg2");
  assert.equal(r.images.tree, "tree");
  assert.equal(into.levels[2].next, "l4");
  assert.equal(into.levels[2].rooms[0].doors[1].to, "l4/r1");
  assert.equal(into.levels[2].rooms[0].background, r.images.bg1);
  assert.equal(into.images[into.levels[2].rooms[0].background], BG);
  assert.deepEqual(errors(check(P.serialize(into))), []);
});

test("the PNG writer: chunks with good CRCs, rows that inflate back", () => {
  const px = new Uint8Array([0, 1, 2, 1, 0, 1, 2, 1, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 1]);
  const url = P.encodeIndexedPng(7, 3, px, [[255, 0, 0], [0, 255, 0, 128], [0, 0, 255]]);
  assert.deepEqual([P.imageInfo(url).width, P.imageInfo(url).height], [7, 3]);
  const buf = Buffer.from(url.split(",")[1], "base64");
  const types: string[] = [];
  let rows: Buffer | null = null;
  for (let i = 8; i < buf.length; ) {
    const len = buf.readUInt32BE(i);
    const type = buf.toString("ascii", i + 4, i + 8);
    types.push(type);
    assert.equal(buf.readUInt32BE(i + 8 + len), crc32(buf.subarray(i + 4, i + 8 + len)), `CRC of ${type}`);
    if (type === "IDAT") rows = inflateSync(buf.subarray(i + 8, i + 8 + len));
    i += 12 + len;
  }
  assert.deepEqual(types, ["IHDR", "PLTE", "tRNS", "IDAT", "IEND"]);
  assert.deepEqual([...rows!], [0, ...px.slice(0, 7), 0, ...px.slice(7, 14), 0, ...px.slice(14)]);
  // Long runs use back-references (the plain room picture is a few KB, not half a megabyte).
  const bg = P.placeholderBackground(960, 560);
  assert.deepEqual([P.imageInfo(bg).width, P.imageInfo(bg).height], [960, 560]);
  assert.ok(bg.length < 60_000, `placeholder is ${bg.length} chars`);
  const data = new Uint8Array(70_000).map((_, i) => (i % 300 < 150 ? 7 : i % 251));
  assert.deepEqual(new Uint8Array(inflateRawSync(Buffer.from(P._deflateRaw(data)))), data);
});

test("the example pack in docs/ is a clean pack", () => {
  const file = new URL("../../docs/examples/sandbox-pack-example.json", import.meta.url);
  if (!existsSync(file)) return;
  const text = readFileSync(file, "utf8");
  const pack = JSON.parse(text);
  assert.deepEqual(check(pack), []);
  assert.ok(text.length < 300_000);
  assert.equal(pack.levels.length, 2);
});
