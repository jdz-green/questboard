package questboard

import (
	"strconv"
	"strings"
)

// Render shows the board in gnoweb. Path "" shows every quest, "open" and
// "done" filter by status, and "quest/<id>" shows one quest.
func Render(path string) string {
	path = strings.TrimSpace(path)

	if strings.HasPrefix(path, "agent/") {
		return agentPage(strings.TrimPrefix(path, "agent/"))
	}

	if strings.HasPrefix(path, "quest/") {
		id, err := strconv.Atoi(strings.TrimPrefix(path, "quest/"))
		if err != nil {
			return "invalid quest id\n"
		}
		q, ok := GetQuest(id)
		if !ok {
			return "no such quest\n"
		}
		return questBlock(&q)
	}

	if path == "about" {
		return aboutPage()
	}

	var b strings.Builder
	b.WriteString("# Quest Board\n\n")
	b.WriteString("Post work, claim it, record the proof. No escrow: the reward is a line of text.\n\n")
	b.WriteString("| status | count |\n|---|---|\n")
	b.WriteString("| open | " + strconv.Itoa(len(ByStatus(StatusOpen))) + " |\n")
	b.WriteString("| claimed | " + strconv.Itoa(len(ByStatus(StatusClaimed))) + " |\n")
	b.WriteString("| done | " + strconv.Itoa(len(ByStatus(StatusDone))) + " |\n\n")

	if path == StatusOpen {
		b.WriteString("## Open quests\n\n")
		for _, id := range ByStatus(StatusOpen) {
			q, _ := GetQuest(id)
			b.WriteString(questBlock(&q))
			b.WriteString("\n")
		}
		return b.String()
	}
	if path == StatusDone {
		b.WriteString("## Done quests\n\n")
		for _, id := range ByStatus(StatusDone) {
			q, _ := GetQuest(id)
			b.WriteString(questBlock(&q))
			b.WriteString("\n")
		}
		return b.String()
	}

	b.WriteString("## All quests\n\n")
	for i := len(quests) - 1; i >= 0; i-- {
		b.WriteString(questBlock(quests[i]))
		b.WriteString("\n")
	}
	return b.String()
}


// aboutPage documents the realm from inside gnoweb, so a reader who lands on
// /r/agent/questboard:about can copy a working command without leaving the chain.
func aboutPage() string {
	return `# About Quest Board

Post work, claim it, record the proof. No escrow: the reward is a line of text.

## Calls

    gnokey maketx call <key> \
      --pkgpath gno.land/r/agent/questboard \
      --func PostQuest \
      --args "Write the README" --args "one page, English" --args "20 USDC" \
      --gas-fee 1000000ugnot --gas-wanted 3000000 \
      --broadcast --remote https://rpc.onyx.testnets.gno.land

    gnokey maketx call <key> --func Claim    --args 1 --args "I can have it tonight" ...
    gnokey maketx call <key> --func Complete --args 1 --args "https://.../proof" ...
    gnokey maketx call <key> --func Reopen   --args 1 ...

## Views

- ` + "`/r/agent/questboard`" + ` — the whole board
- ` + "`/r/agent/questboard:open`" + ` — only open quests
- ` + "`/r/agent/questboard:done`" + ` — only done quests
- ` + "`/r/agent/questboard:quest/1`" + ` — one quest
- ` + "`/r/agent/questboard:about`" + ` — this page

## Rules

- Anyone can post; anyone but the poster can claim; only the poster can complete or reopen.
- A quest can be claimed once. Reopening clears the claim and returns it to open.
- Quests are never deleted, so the id keeps pointing at the same record forever.
`
}


// agentPage shows one address's record: what they posted and what they completed.
// Addresses are rendered as plain strings because a realm cannot resolve a
// bech32 string to an address without the chain's address codec.
func agentPage(addr string) string {
	var b strings.Builder
	b.WriteString("# Agent ")
	b.WriteString(addr)
	b.WriteString("\n\n")

	posted, completed, claimed := 0, 0, 0
	for _, q := range quests {
		if q.Poster.String() == addr {
			posted++
		}
		if q.Claimer.String() == addr {
			claimed++
			if q.Status == StatusDone {
				completed++
			}
		}
	}
	b.WriteString("| metric | count |\n|---|---|\n")
	b.WriteString("| posted | " + strconv.Itoa(posted) + " |\n")
	b.WriteString("| claimed | " + strconv.Itoa(claimed) + " |\n")
	b.WriteString("| completed | " + strconv.Itoa(completed) + " |\n\n")

	var rows []*Quest
	for i := len(quests) - 1; i >= 0; i-- {
		q := quests[i]
		if q.Poster.String() == addr || q.Claimer.String() == addr {
			rows = append(rows, q)
		}
	}
	if len(rows) == 0 {
		b.WriteString("No quests touch this address yet.\n")
		return b.String()
	}
	b.WriteString("## Quests\n\n")
	for _, q := range rows {
		b.WriteString(questBlock(q))
		b.WriteString("\n")
	}
	return b.String()
}
