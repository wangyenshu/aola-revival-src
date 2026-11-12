// Work on named things one after another: a call waits for the calls before it that name any
// of the same keys; calls on other keys run alongside. The accounts (game.ts: one name's login,
// sign-up, rename, import …) and the records everyone writes (a 排行榜, the wishes of the
// balloon) take their turns here, so a slow one (an import ending a game, a password's hash)
// holds up only what shares its keys.
//
// A call must not wait, inside its function, for a call on one of its own keys (it would wait for
// itself); the keys a call takes inside another's are others ("#id" inside a name's).

export class KeyedLocks {
  private readonly tails = new Map<string, Promise<void>>();

  run<T>(keys: readonly string[], f: () => Promise<T> | T): Promise<T> {
    const ks = [...new Set(keys)];
    const before: Promise<void>[] = [];
    for (const k of ks) {
      const t = this.tails.get(k);
      if (t) before.push(t);
    }
    const r = (before.length ? Promise.all(before) : Promise.resolve()).then(() => f());
    const tail = r.then(
      () => {},
      () => {},
    );
    for (const k of ks) this.tails.set(k, tail);
    // Keys nobody waits on go (no end of names kept).
    void tail.then(() => {
      for (const k of ks) if (this.tails.get(k) === tail) this.tails.delete(k);
    });
    return r;
  }

  /** Keys being worked on or waited for now (the tests). */
  get size(): number {
    return this.tails.size;
  }
}

/** One after another (a module's own record of everyone's, where no KeyedLocks is given). */
export function serial(): <T>(f: () => Promise<T>) => Promise<T> {
  let last: Promise<unknown> = Promise.resolve();
  return <T>(f: () => Promise<T>): Promise<T> => {
    const r = last.then(f, f);
    last = r.catch(() => {});
    return r;
  };
}
