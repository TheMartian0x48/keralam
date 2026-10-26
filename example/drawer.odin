package main

import c "../component"
import k "kashmir:."

drawer_position_ids := [c.Drawer_Position]string {
	.right  = "drawer-right",
	.left   = "drawer-left",
	.top    = "drawer-top",
	.bottom = "drawer-bottom",
}

drawer_position_labels := [c.Drawer_Position]string {
	.right  = "Right",
	.left   = "Left",
	.top    = "Top",
	.bottom = "Bottom",
}

drawer_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "A slide-over panel on the native "),
		doc_code(doc, "<dialog>"),
		k.text(
			doc,
			" element. It slides in from any screen edge, traps focus, and closes with the close button, ",
		),
		doc_code(doc, "Escape"),
		k.text(doc, " or a click on the backdrop. The page behind it does not scroll."),
	)
}

// Opens the drawer with the given id, with no script (the command attributes).
drawer_opener :: proc(doc: ^k.Doc, drawer_id, label: string) -> k.Node_Id {
	return c.button(
		doc,
		{
			attributes = {
				k.attribute("command", "show-modal"),
				k.attribute("commandfor", drawer_id),
			},
		},
		k.text(doc, label),
	)
}

demo_drawer :: proc(doc: ^k.Doc) -> k.Node_Id {
	position_openers := make([dynamic]k.Node_Id, 0, len(c.Drawer_Position), context.temp_allocator)
	drawers := make([dynamic]k.Node_Id, 0, len(c.Drawer_Position) + 1, context.temp_allocator)

	for position in c.Drawer_Position {
		label := drawer_position_labels[position]
		append(&position_openers, drawer_opener(doc, drawer_position_ids[position], label))
		append(
			&drawers,
			c.drawer(
				doc,
				{
					id = drawer_position_ids[position],
					title = label,
					description = k.doc_format(
						doc,
						"This drawer is anchored to the %s edge.",
						label,
					),
					position = position,
				},
				k.text(doc, "Press Escape, use the close button, or click the backdrop to close."),
			),
		)
	}

	long_body := make([dynamic]k.Node_Id, 0, 24, context.temp_allocator)
	for index in 1 ..= 24 {
		append(
			&long_body,
			k.p(
				doc,
				{},
				k.text(
					doc,
					k.doc_format(doc, "Paragraph %d of a body long enough to scroll.", index),
				),
			),
		)
	}
	append(
		&drawers,
		c.drawer(
			doc,
			{id = "drawer-wide", title = "Wide", style = "--drawer-size: 40rem"},
			k.text(doc, "This drawer sets --drawer-size to 40rem."),
		),
	)
	append(&drawers, c.drawer(doc, {id = "drawer-scroll", title = "Long content"}, ..long_body[:]))

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		doc_group(
			doc,
			"Positions",
			doc_description(
				doc,
				k.text(doc, "Set "),
				doc_code(doc, "position"),
				k.text(doc, " to pick the edge. Each button opens its drawer with "),
				doc_code(doc, `command="show-modal"`),
				k.text(doc, " (Chrome 135, Safari 18.4 or Firefox 144 or newer)."),
			),
			doc_list(doc, {}, ..position_openers[:]),
		),
		doc_group(
			doc,
			"Size",
			doc_description(
				doc,
				k.text(doc, "Set the "),
				doc_code(doc, "--drawer-size"),
				k.text(
					doc,
					" variable to change the width of a left or right drawer, or the max height of a top or bottom one. It defaults to 24rem and 50vh.",
				),
			),
			doc_list(doc, {}, drawer_opener(doc, "drawer-wide", "Open a 40rem drawer")),
		),
		doc_group(
			doc,
			"Long content",
			doc_description(
				doc,
				k.text(doc, "The body scrolls inside the panel and the page behind stays put."),
			),
			doc_list(doc, {}, drawer_opener(doc, "drawer-scroll", "Open a scrolling drawer")),
		),
		k.div(doc, {}, ..drawers[:]),
	)
}
