package main

import c "../component"
import k "kashmir:."

tooltip_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "tooltip"),
		k.text(
			doc,
			" shows a short text beside a focusable element on hover or keyboard focus. The trigger is a proc that receives the tooltip's id, so the trigger's aria-describedby points at it and a screen reader reads the text. Escape hides it while the trigger keeps focus, and it stays open while the pointer is over it. It does not move to stay on screen, so pick a position with room.",
		),
	)
}

tooltip_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

tooltip_row :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{style = "align-items: center; gap: var(--spacing-8); padding: var(--spacing-10) var(--spacing-12)"},
		..children,
	)
}

tooltip_trigger_save :: proc(doc: ^k.Doc, wiring: c.Tooltip_Wiring) -> k.Node_Id {
	return c.button(doc, {attributes = {k.attribute("aria-describedby", wiring.id)}}, k.text(doc, "Save"))
}

tooltip_trigger_position :: proc(doc: ^k.Doc, wiring: c.Tooltip_Wiring) -> k.Node_Id {
	return c.button(
		doc,
		{shape = .outline, attributes = {k.attribute("aria-describedby", wiring.id)}},
		k.text(doc, "Hover or focus"),
	)
}

tooltip_trigger_icon :: proc(doc: ^k.Doc, wiring: c.Tooltip_Wiring) -> k.Node_Id {
	return c.button(
		doc,
		{
			shape = .text,
			attributes = {k.attribute("aria-label", "Help"), k.attribute("aria-describedby", wiring.id)},
		},
		c.icon(doc, {name = .question}),
	)
}

tooltip_trigger_link :: proc(doc: ^k.Doc, wiring: c.Tooltip_Wiring) -> k.Node_Id {
	return c.link(
		doc,
		{href = "#terms", attributes = {k.attribute("aria-describedby", wiring.id)}},
		k.text(doc, "Terms"),
	)
}

demo_tooltip :: proc(doc: ^k.Doc) -> k.Node_Id {
	positions := make([dynamic]k.Node_Id, 0, len(c.Tooltip_Position), context.temp_allocator)
	for position in c.Tooltip_Position {
		append(
			&positions,
			c.tooltip(
				doc,
				{
					content = k.doc_format(doc, "%v", position),
					position = position,
					trigger = tooltip_trigger_position,
				},
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		tooltip_section(
			doc,
			"Positions",
			"Top is the default. The bubble sits beside the trigger on the side you pick.",
			tooltip_row(doc, ..positions[:]),
		),
		tooltip_section(
			doc,
			"On a button",
			"The button names its own action. The tooltip adds a hint, read as a description.",
			tooltip_row(doc, c.tooltip(doc, {content = "Saves a draft without publishing", trigger = tooltip_trigger_save})),
		),
		tooltip_section(
			doc,
			"On an icon button",
			"An icon button needs its own aria_label. The tooltip tells sighted users what it does.",
			tooltip_row(
				doc,
				c.tooltip(doc, {content = "Help about this page", position = .right, trigger = tooltip_trigger_icon}),
			),
		),
		tooltip_section(
			doc,
			"On a link",
			"Any focusable element works.",
			tooltip_row(doc, c.tooltip(doc, {content = "Opens the terms of service", trigger = tooltip_trigger_link})),
		),
		tooltip_section(
			doc,
			"Long text",
			"The bubble wraps at 20rem.",
			tooltip_row(
				doc,
				c.tooltip(
					doc,
					{
						content = "This is a longer explanation that does not fit on one line, so the bubble wraps it instead of running off the edge of the screen.",
						trigger = tooltip_trigger_save,
					},
				),
			),
		),
	)
}
