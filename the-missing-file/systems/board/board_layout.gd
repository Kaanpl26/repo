class_name BoardLayout
## Where each note goes on the evidence wall. No UI.
##
## Evidence and statements are laid out in a grid with wide gaps between the
## rows. Each conclusion is placed in a gap, as near as possible to the middle
## of the two cards it came from, so the red threads stay short. A note the
## player has moved keeps the position they gave it.

const NOTE := Vector2(400, 230)       # space reserved for an evidence or statement note
const SMALL := Vector2(340, 110)      # a conclusion note
const PITCH := Vector2(470, 390)
const COLS := 4
const MARGIN := 110.0
const TOP := 150.0                    # room above the first row for conclusions


## Evidence and statements on the wall. With show_all false only live cards
## (see Hints.card_live) and the ids in "extra" are included.
static func grid_cards(show_all: bool = true, extra: Array = []) -> Array:
	var out: Array = []
	for id in GameState.evidence + GameState.testimony:
		if show_all or id in extra or Hints.card_live(id):
			out.append(id)
	return out


## Conclusions on the wall.
static func shown_insight(id: String, show_all: bool, extra: Array) -> bool:
	return GameState.has_insight(id) and (show_all or id in extra or Hints.card_live(id))


static func canvas_size(show_all: bool = true, extra: Array = []) -> Vector2:
	var rows := maxi(1, ceili(grid_cards(show_all, extra).size() / float(COLS)))
	return Vector2(MARGIN * 2 + COLS * PITCH.x - (PITCH.x - NOTE.x), MARGIN * 2 + TOP + rows * PITCH.y)


static func note_size(card_id: String) -> Vector2:
	return SMALL if CaseDB.card_kind(card_id) == "insight" else NOTE


## Returns {card id: Vector2 top-left position} for every card the player holds.
static func positions(show_all: bool = true, extra: Array = []) -> Dictionary:
	var pos := {}
	var stored: Dictionary = GameState.board_layout
	var cards := grid_cards(show_all, extra)
	for i in cards.size():
		var id: String = cards[i]
		pos[id] = Vector2(MARGIN + (i % COLS) * PITCH.x, MARGIN + TOP + (i / COLS) * PITCH.y)
	for id in cards:
		if stored.has(id):
			pos[id] = Vector2(stored[id][0], stored[id][1])

	var size := canvas_size(show_all, extra)
	var rows := maxi(1, ceili(cards.size() / float(COLS)))
	var taken: Array = []      # rectangles of conclusions already placed
	for id in CaseDB.insights:       # file order, so a conclusion's sources come first
		if not shown_insight(id, show_all, extra):
			continue
		if stored.has(id):
			pos[id] = Vector2(stored[id][0], stored[id][1])
			taken.append(Rect2(pos[id], SMALL))
			continue
		var middle := Vector2(size.x / 2.0, MARGIN + TOP / 2.0)
		var sources: Array = CaseDB.insights[id]["cards"]
		if pos.has(sources[0]) and pos.has(sources[1]):
			middle = (pos[sources[0]] + note_size(sources[0]) / 2.0 + pos[sources[1]] + note_size(sources[1]) / 2.0) / 2.0
		pos[id] = _free_spot(middle, rows, size, taken)
		taken.append(Rect2(pos[id], SMALL))
	return pos


## The free place in a gap between rows that is nearest to "middle".
static func _free_spot(middle: Vector2, rows: int, size: Vector2, taken: Array) -> Vector2:
	var best := Vector2.ZERO
	var best_d := INF
	for gap in rows + 1:
		var y := MARGIN + TOP + gap * PITCH.y - (PITCH.y - NOTE.y) / 2.0 - SMALL.y / 2.0
		if gap == 0:
			y = MARGIN + (TOP - SMALL.y) / 2.0
		for step in 13:
			# 0, +1, -1, +2, -2 ... note-widths to the side
			var dx := float((step + 1) / 2) * (SMALL.x + 20.0) * (1.0 if step % 2 == 1 else -1.0)
			var x := clampf(middle.x - SMALL.x / 2.0 + dx, MARGIN / 2.0, size.x - SMALL.x - MARGIN / 2.0)
			var rect := Rect2(Vector2(x, y), SMALL)
			var free := true
			for other in taken:
				if rect.grow(8).intersects(other):
					free = false
					break
			if not free:
				continue
			var d := (rect.get_center() - middle).length_squared()
			if d < best_d:
				best_d = d
				best = rect.position
	if best_d == INF:       # completely full: stack it at the top; the player can move it
		best = Vector2(MARGIN, MARGIN / 2.0)
	return best
