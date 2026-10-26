package main

import c "../component"
import k "kashmir:."

stepper_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "stepper"),
		k.text(
			doc,
			" is a numbered sequence of steps. Give it the index of the current step and the rest follows: earlier steps are completed, later ones upcoming, so an impossible sequence cannot be written. The state is also spoken after each title.",
		),
	)
}

stepper_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

demo_stepper :: proc(doc: ^k.Doc) -> k.Node_Id {
	plain := [?]c.Step_Item{{title = "Account"}, {title = "Profile"}, {title = "Review"}}
	described := [?]c.Step_Item {
		{title = "Account", description = "Your email and password"},
		{title = "Profile", description = "Name and photo"},
		{title = "Review", description = "Check and submit"},
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(&sizes, c.stepper(doc, {steps = plain[:], current = 1, size = size}))
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		stepper_section(
			doc,
			"Horizontal",
			"The default. current = 1 makes Account completed and Profile the active step.",
			c.stepper(doc, {steps = plain[:], current = 1}),
		),
		stepper_section(
			doc,
			"With descriptions",
			"A description sits under the title.",
			c.stepper(doc, {steps = described[:], current = 1}),
		),
		stepper_section(
			doc,
			"Vertical",
			"The same steps stacked, for a narrow column.",
			k.div(
				doc,
				{style = "max-width: 20rem"},
				c.stepper(doc, {steps = described[:], current = 1, vertical = true}),
			),
		),
		stepper_section(
			doc,
			"Size",
			"The shared Size enum: the numbered circle is 2, 2.5 or 3rem.",
			k.div(
				doc,
				{style = "display: flex; flex-direction: column; gap: var(--spacing-6)"},
				..sizes[:],
			),
		),
		stepper_section(
			doc,
			"Not started and all done",
			"current = 0 starts at the first step. current equal to the step count completes every step and marks none as current.",
			k.div(
				doc,
				{style = "display: flex; flex-direction: column; gap: var(--spacing-6)"},
				c.stepper(doc, {steps = plain[:], current = 0, aria_label = "Not started"}),
				c.stepper(doc, {steps = plain[:], current = 3, aria_label = "All done"}),
			),
		),
	)
}
