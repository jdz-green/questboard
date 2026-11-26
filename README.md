![test](https://github.com/jdz-green/questboard/actions/workflows/test.yml/badge.svg)

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
status, and `Render("quest/<id>")` shows one quest, and `Render("agent/<addr>")` shows that address's record: how
many quests it posted, claimed and completed, plus the quests themselves. Everything is markdown so
gnoweb renders it directly.

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
    --gas-fee 60000000ugnot --gas-wanted 40000000 \
    --broadcast --insecure-password-stdin \
    --remote https://rpc.onyx.testnets.gno.land
```

Two details that cost me an hour on a local chain: the fee must be denominated in **ugnot** (a `gnot`
fee is compared against a zero gnot balance and fails as "insufficient funds" even when the account
holds 100 GNOT), and this package needs about **20.7M gas**, so `--gas-wanted 40000000` clears it.

## Status

- Realm and tests are written and green locally (Gno v1.8.0 / gno 0.9 module)
- Testnet deployment is pending a faucet drip on `onyx-1` (the faucet rate-limits by IP; retrying)
