package questboard

import (
	"testing"

	"gno.land/p/nt/testutils/v0"
	"gno.land/p/nt/uassert/v0"
)

var (
	alice = testutils.TestAddress("alice")
	bob   = testutils.TestAddress("bob")
	carol = testutils.TestAddress("carol")
)

func TestPostAndClaim(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(alice))
	id := PostQuest(cross(cur), "Write a README", "one page", "20 USDC")
	uassert.Equal(t, 1, id)
	uassert.Equal(t, 1, Count())

	q, ok := GetQuest(id)
	uassert.True(t, ok)
	uassert.Equal(t, StatusOpen, q.Status)
	uassert.Equal(t, alice, q.Poster)
	uassert.Equal(t, "Write a README", q.Title)
	uassert.Equal(t, "20 USDC", q.Reward)

	testing.SetRealm(testing.NewUserRealm(bob))
	Claim(cross(cur), id, "I can do this tonight")

	q, _ = GetQuest(id)
	uassert.Equal(t, StatusClaimed, q.Status)
	uassert.Equal(t, bob, q.Claimer)
	uassert.Equal(t, "I can do this tonight", q.Note)
}

func TestCompleteByPoster(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(alice))
	PostQuest(cross(cur), "Ship a realm", "", "fame")

	testing.SetRealm(testing.NewUserRealm(bob))
	Claim(cross(cur), 2, "on it")

	testing.SetRealm(testing.NewUserRealm(alice))
	Complete(cross(cur), 2, "https://example.com/proof")

	q, _ := GetQuest(2)
	uassert.Equal(t, StatusDone, q.Status)
	uassert.Equal(t, "https://example.com/proof", q.Proof)
	uassert.Equal(t, 1, len(ByStatus(StatusDone)))
}

func TestReopen(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(alice))
	PostQuest(cross(cur), "Reopen me", "", "x")

	testing.SetRealm(testing.NewUserRealm(carol))
	Claim(cross(cur), 3, "claim")

	testing.SetRealm(testing.NewUserRealm(alice))
	Reopen(cross(cur), 3)

	q, _ := GetQuest(3)
	uassert.Equal(t, StatusOpen, q.Status)
	uassert.Equal(t, address(""), q.Claimer)
	uassert.Equal(t, 1, len(ByStatus(StatusOpen)))
}

func TestRender(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(alice))
	PostQuest(cross(cur), "Render check", "details here", "10 USDC")

	out := Render("")
	uassert.True(t, len(out) > 0)
	uassert.True(t, len(Render("open")) > 0)
	uassert.True(t, len(Render("quest/1")) > 0)
}

func TestStats(cur realm, t *testing.T) {
	// State is shared across tests in this package, so assert deltas.
	beforePosted := PostedBy(alice)
	beforeDone := CompletedBy(bob)

	testing.SetRealm(testing.NewUserRealm(alice))
	id := PostQuest(cross(cur), "Count me", "", "x")

	testing.SetRealm(testing.NewUserRealm(bob))
	Claim(cross(cur), id, "mine")

	testing.SetRealm(testing.NewUserRealm(alice))
	Complete(cross(cur), id, "proof")

	uassert.Equal(t, beforePosted+1, PostedBy(alice))
	uassert.Equal(t, beforeDone+1, CompletedBy(bob))
	uassert.Equal(t, 0, CompletedBy(alice))
}

func TestAgentPage(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(alice))
	id := PostQuest(cross(cur), "Profile me", "", "x")

	testing.SetRealm(testing.NewUserRealm(bob))
	Claim(cross(cur), id, "mine")

	out := Render("agent/" + alice.String())
	uassert.True(t, len(out) > 0)
	out = Render("agent/" + bob.String())
	uassert.True(t, len(out) > 0)
}
