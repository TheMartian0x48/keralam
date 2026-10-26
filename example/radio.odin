package main

import c "../component"
import k "kashmir:."

radio_plans :: [?]c.Radio_Option {
	{"free", "Free", false},
	{"pro", "Pro", false},
	{"team", "Team", false},
}

radio_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "A choice where exactly one option is selected. "),
		doc_code(doc, "radio_group"),
		k.text(doc, " builds the "),
		doc_code(doc, "<fieldset>"),
		k.text(doc, " and "),
		doc_code(doc, "<legend>"),
		k.text(doc, " and checks the group is valid; "),
		doc_code(doc, "radio"),
		k.text(doc, " is the single control. The circle is always round, so there is no radius."),
	)
}

// A block of the radio page: the API name, a note, the demos, then a rule.
radio_section :: proc(doc: ^k.Doc, api, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, doc_code(doc, api)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

demo_radio :: proc(doc: ^k.Doc) -> k.Node_Id {
	plans := radio_plans
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.radio_group(
				doc,
				{
					name = k.doc_format(doc, "size-%v", size),
					legend = k.doc_format(doc, "%v", size),
					size = size,
					value = "pro",
					options = plans[:],
				},
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		radio_section(
			doc,
			"radio_group",
			"The group's value picks the selected option, so two can not be selected. Arrow keys move within a group.",
			doc_list(
				doc,
				{},
				c.radio_group(
					doc,
					{name = "plan", legend = "Choose a plan", value = "pro", options = plans[:]},
				),
				c.radio_group(
					doc,
					{
						name = "color",
						legend = "Pick a colour",
						direction = .row,
						value = "blue",
						options = {
							{"red", "Red", false},
							{"blue", "Blue", false},
							{"green", "Green", false},
						},
					},
				),
			),
		),
		radio_section(
			doc,
			"radio_group: size",
			"Small, Medium and Large use the shared Size enum.",
			doc_list(doc, {}, ..sizes[:]),
		),
		radio_section(
			doc,
			"radio_group: state",
			"An option can be disabled on its own, or the whole group. required and disabled together asserts.",
			doc_list(
				doc,
				{},
				c.radio_group(
					doc,
					{
						name = "one-off",
						legend = "One option disabled",
						value = "a",
						options = {
							{"a", "Available", false},
							{"b", "Not available", true},
							{"c", "Available too", false},
						},
					},
				),
				c.radio_group(
					doc,
					{
						name = "all-off",
						legend = "Whole group disabled",
						disabled = true,
						value = "pro",
						options = plans[:],
					},
				),
				c.radio_group(
					doc,
					{
						name = "bad",
						legend = "With an error",
						error = true,
						aria_described_by = "radio-error-hint",
						options = plans[:],
					},
				),
			),
			k.p(
				doc,
				{id = "radio-error-hint", class = "demo__note"},
				k.text(doc, "The error group points here with aria-describedby."),
			),
		),
		radio_section(
			doc,
			"radio_group: in a form",
			"Pick an option and submit: the address bar shows the selected value. required stops the form until one is chosen.",
			doc_list(
				doc,
				{},
				k.form(
					doc,
					{
						method = .get,
						style = "display: flex; flex-direction: column; gap: var(--spacing-4); align-items: flex-start",
					},
					c.radio_group(
						doc,
						{
							id = "form-plan",
							name = "plan",
							legend = "Choose a plan",
							required = true,
							options = plans[:],
						},
					),
					c.button(doc, {type = .submit}, k.text(doc, "Submit")),
				),
			),
		),
		radio_section(
			doc,
			"radio",
			"The single control, for when you wire the group yourself. Radios that share a name are one group.",
			doc_list(
				doc,
				{},
				c.radio(doc, {name = "solo", value = "a", label = "Option A", checked = true}),
				c.radio(doc, {name = "solo", value = "b", label = "Option B"}),
				c.radio(doc, {name = "solo", value = "c", label = "Disabled", disabled = true}),
				c.radio(doc, {name = "labelless", value = "x", aria_label = "No visible label"}),
			),
		),
	)
}
