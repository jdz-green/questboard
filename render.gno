package questboard

import (
	"strconv"
	"strings"
)

// Render shows the board in gnoweb. Path "" shows every quest, "open" and
// "done" filter by status, and "quest/<id>" shows one quest.
func Render(path string) string {
	path = strings.TrimSpace(path)

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
