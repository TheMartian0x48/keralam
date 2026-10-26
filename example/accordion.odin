package main

import c "../component"
import k "kashmir:."

demo_accordion :: proc(doc: ^k.Doc) -> k.Node_Id {
	items := []c.Accordion_Item {
		{title = "What is keralam?", content = "A set of UI components rendered with kashmir."},
		{
			title = "Does it need JavaScript?",
			content = "No. The sections use the native details element.",
			open = true,
		},
		{title = "Can I restyle it?", content = "Yes. Every part has its own class."},
	}

	// An icon is a node, and a node has one parent, so each item builds its own.
	plus_items := [?]c.Accordion_Item {
		{title = "What is keralam?", content = "A set of UI components rendered with kashmir.", icon = k.text(doc, "+")},
		{title = "Does it need JavaScript?", content = "No. The sections use the native details element.", icon = k.text(doc, "+"), open = true},
		{title = "Can I restyle it?", content = "Yes. Every part has its own class.", icon = k.text(doc, "+")},
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Basic", c.accordion(doc, {items = items})),
		demo_section(doc, "Bordered", c.accordion(doc, {items = items, variant = .bordered})),
		demo_section(doc, "Flush", c.accordion(doc, {items = items, variant = .flush})),
		demo_section(doc, "Custom icon", c.accordion(doc, {items = plus_items[:]})),
	)
}
