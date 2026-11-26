# Quest Board

A small public board on Gno.land: post a quest, one person claims it, the poster records the proof when
it is done. The reward is a line of text ("20 USDC", "a coffee", "credit in the README") instead of an
escrow, so the board can be deployed without holding anyone's funds and the whole state fits in one
rendered page.

Built for the [Gnome Tavern hackathon](https://dorahacks.io/hackathon/gnome-tavern) ($40,000 pool,
deadline 2026-12-18).

## What it does

| Function | Who calls it | Effect |
|---|---|---|
| `PostQuest(title, details, reward)` | anyone | adds a quest, returns its id |
| `Claim(id, note)` | anyone but the poster | marks it claimed, records the claimer and their note |
| `Complete(id, proof)` | poster only | marks it done, records the proof link |
| `Reopen(id)` | poster only | returns a claimed quest to open and clears the claim |
| `PostedBy(addr)` / `CompletedBy(addr)` | anyone | counters used by the render page |

State is append-only: quests are never deleted, so the board is a record of what was asked and what was
delivered, not just a to-do list.

## Rendering

Quest ids in the rendered page link to `/r/agent/questboard:quest/<id>`, so a board post is a clickable
entry rather than dead text. `Render("")` shows the whole board with a status table, `Render("open")` and `Render("done")` filter by
status, and `Render("quest/<id>")` shows one quest. Everything is markdown so gnoweb renders it directly.

## Tests

```console
$ GNOROOT=/path/to/gno gno test . -v
=== RUN   TestPostAndClaim
--- PASS: TestPostAndClaim (0.00s)
=== RUN   TestCompleteByPoster
--- PASS: TestCompleteByPoster (0.00s)
=== RUN   TestReopen
--- PASS: TestReopen (0.00s)
=== RUN   TestRender
--- PASS: TestRender (0.00s)
ok      .	1.33s
```

## Deploy

```console
$ gnokey maketx addpkg agent \
    --pkgpath gno.land/r/agent/questboard \
    --pkgdir . \
    --gas-fee 1gnot --gas-wanted 3000000 \
    --broadcast \
    --remote https://rpc.onyx.testnets.gno.land
```

## Status

- Realm and tests are written and green locally (Gno v1.8.0 / gno 0.9 module)
- Testnet deployment is pending a faucet drip on `onyx-1` (the faucet rate-limits by IP; retrying)
