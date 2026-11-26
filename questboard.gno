// Package questboard is a small public board where anyone can post a quest,
// one person can claim it, and the poster records the proof when it is done.
//
// It is deliberately coin-free: the reward is a line of text the poster writes
// ("20 USDC", "a coffee", "credit in the README"), so the board can be deployed
// without holding anyone's funds, and the whole state fits in a render page.
package questboard

import (
	"errors"
	"strconv"
	"strings"
)

const (
	StatusOpen    = "open"
	StatusClaimed = "claimed"
	StatusDone    = "done"
)

var (
	ErrEmptyTitle    = errors.New("questboard: title is empty")
	ErrTitleTooLong  = errors.New("questboard: title is longer than 120 characters")
	ErrUnknownID     = errors.New("questboard: no quest with that id")
	ErrNotPoster     = errors.New("questboard: only the poster can do that")
	ErrAlreadyClaimed = errors.New("questboard: quest is already claimed")
	ErrNotOpen       = errors.New("questboard: quest is not open")
	ErrAlreadyDone   = errors.New("questboard: quest is already done")
	ErrEmptyNote     = errors.New("questboard: note is empty")
)

type Quest struct {
	ID      int
	Poster  address
	Title   string
	Details string
	Reward  string
	Status  string
	Claimer address
	Note    string
	Proof   string
}

var (
	quests []*Quest
	nextID = 1
)

// PostQuest adds a quest and returns its id. The caller becomes the poster.
func PostQuest(cur realm, title, details, reward string) int {
	if strings.TrimSpace(title) == "" {
		panic(ErrEmptyTitle)
	}
	if len(title) > 120 {
		panic(ErrTitleTooLong)
	}
	q := &Quest{
		ID:      nextID,
		Poster:  cur.Previous().Address(),
		Title:   title,
		Details: details,
		Reward:  reward,
		Status:  StatusOpen,
	}
	quests = append(quests, q)
	nextID++
	return q.ID
}

// Claim marks a quest as claimed by the caller. Only open quests can be claimed,
// and a quest can only be claimed once.
func Claim(cur realm, id int, note string) {
	q := mustQuest(id)
	if q.Status == StatusDone {
		panic(ErrAlreadyDone)
	}
	if q.Status != StatusOpen {
		panic(ErrAlreadyClaimed)
	}
	if strings.TrimSpace(note) == "" {
		panic(ErrEmptyNote)
	}
	q.Status = StatusClaimed
	q.Claimer = cur.Previous().Address()
	q.Note = note
}

// Complete records that the poster considers the quest finished, with proof.
func Complete(cur realm, id int, proof string) {
	q := mustQuest(id)
	if q.Poster != cur.Previous().Address() {
		panic(ErrNotPoster)
	}
	if q.Status != StatusClaimed {
		panic(ErrNotOpen)
	}
	q.Status = StatusDone
	q.Proof = proof
}

// Reopen returns a claimed quest to the open state, poster only.
func Reopen(cur realm, id int) {
	q := mustQuest(id)
	if q.Poster != cur.Previous().Address() {
		panic(ErrNotPoster)
	}
	if q.Status != StatusClaimed {
		panic(ErrNotOpen)
	}
	q.Status = StatusOpen
	q.Claimer = address("")
	q.Note = ""
}

func mustQuest(id int) *Quest {
	for _, q := range quests {
		if q.ID == id {
			return q
		}
	}
	panic(ErrUnknownID)
}

// GetQuest returns a copy of the quest with that id.
func GetQuest(id int) (Quest, bool) {
	for _, q := range quests {
		if q.ID == id {
			return *q, true
		}
	}
	return Quest{}, false
}

// Count returns the number of quests on the board.
func Count() int {
	return len(quests)
}

// ByStatus returns the ids of quests in the given status, newest first.
func ByStatus(status string) []int {
	ids := make([]int, 0, len(quests))
	for i := len(quests) - 1; i >= 0; i-- {
		if quests[i].Status == status {
			ids = append(ids, quests[i].ID)
		}
	}
	return ids
}

func statusLine(q *Quest) string {
	switch q.Status {
	case StatusOpen:
		return "open"
	case StatusClaimed:
		return "claimed by " + q.Claimer.String()
	case StatusDone:
		return "done, proof: " + q.Proof
	}
	return q.Status
}

func questBlock(q *Quest) string {
	var b strings.Builder
	b.WriteString("### #")
	b.WriteString(strconv.Itoa(q.ID))
	b.WriteString(" ")
	b.WriteString(q.Title)
	b.WriteString("\n")
	if q.Reward != "" {
		b.WriteString("*reward:* ")
		b.WriteString(q.Reward)
		b.WriteString("  \n")
	}
	b.WriteString("*status:* ")
	b.WriteString(statusLine(q))
	b.WriteString("  \n")
	b.WriteString("*poster:* ")
	b.WriteString(q.Poster.String())
	b.WriteString("\n")
	if q.Details != "" {
		b.WriteString("\n")
		b.WriteString(q.Details)
		b.WriteString("\n")
	}
	return b.String()
}
