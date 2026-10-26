package main

import c "../component"
import k "kashmir:."

toggle_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "input_toggle"),
		k.text(doc, " is an on/off switch for one setting that takes effect straight away. It is a native checkbox with "),
		doc_code(doc, `role="switch"`),
		k.text(doc, ", so it submits like one and a screen reader announces it as a switch. For agreeing to something or picking among options, use the checkbox."),
	)
}

demo_toggle :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size) * 2, context.temp_allocator)
	for size in c.Size {
		name := k.doc_format(doc, "%v", size)
		append(&sizes, c.input_toggle(doc, {label = name, size = size}))
		append(&sizes, c.input_toggle(doc, {label = k.doc_format(doc, "%v on", size), size = size, checked = true}))
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		doc_group(
			doc,
			"Basic",
			doc_description(
				doc,
				k.text(doc, "Click it, or focus it and press "),
				doc_code(doc, "Space"),
				k.text(doc, ". Clicking the label text toggles it too."),
			),
			doc_list(
				doc,
				{},
				c.input_toggle(doc, {name = "notifications", label = "Enable notifications"}),
				c.input_toggle(doc, {name = "dark", label = "Dark mode", checked = true}),
			),
		),
		doc_group(
			doc,
			"Size",
			doc_description(doc, k.text(doc, "The shared "), doc_code(doc, "Size"), k.text(doc, " enum.")),
			doc_list(doc, {}, ..sizes[:]),
		),
		doc_group(
			doc,
			"Description",
			doc_description(
				doc,
				k.text(doc, "Put the longer explanation in an element of your own and point "),
				doc_code(doc, "aria_described_by"),
				k.text(doc, " at it; a screen reader reads it after the name."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 24rem; align-items: flex-start"},
				c.input_toggle(doc, {name = "marketing", label = "Marketing emails", aria_described_by = "toggle-hint"}),
				k.p(doc, {id = "toggle-hint", class = "demo__note"}, k.text(doc, "We send one email a month. You can turn it off any time.")),
			),
		),
		doc_group(
			doc,
			"State",
			doc_description(
				doc,
				doc_code(doc, "disabled"),
				k.text(doc, " dims it and blocks input; "),
				doc_code(doc, "error"),
				k.text(doc, " sets "),
				doc_code(doc, "aria-invalid"),
				k.text(doc, " and the red styling. "),
				doc_code(doc, "required"),
				k.text(doc, " and "),
				doc_code(doc, "disabled"),
				k.text(doc, " together assert."),
			),
			doc_list(
				doc,
				{},
				c.input_toggle(doc, {label = "Disabled off", disabled = true}),
				c.input_toggle(doc, {label = "Disabled on", disabled = true, checked = true}),
				c.input_toggle(doc, {label = "With an error", error = true}),
				c.input_toggle(doc, {label = "Error, on", error = true, checked = true}),
			),
		),
		doc_group(
			doc,
			"No visible label",
			doc_description(
				doc,
				k.text(doc, "Without text, give it an "),
				doc_code(doc, "aria_label"),
				k.text(doc, ". One or the other is required."),
			),
			doc_list(doc, {}, c.input_toggle(doc, {name = "quiet", aria_label = "Quiet mode"})),
		),
		doc_group(
			doc,
			"In a form",
			doc_description(
				doc,
				k.text(doc, "A switch that is on submits "),
				doc_code(doc, "name=on"),
				k.text(doc, ", or the "),
				doc_code(doc, "value"),
				k.text(doc, " you give it. One that is off sends nothing. Submit and read the address bar."),
			),
			doc_list(
				doc,
				{},
				k.form(
					doc,
					{method = .get, style = "display: flex; flex-direction: column; gap: var(--spacing-4); align-items: flex-start"},
					c.input_toggle(doc, {id = "form-wifi", name = "wifi", label = "Wi-Fi", checked = true}),
					c.input_toggle(doc, {id = "form-sync", name = "sync", value = "yes", label = "Sync (value=yes)"}),
					c.input_toggle(doc, {id = "form-tos", name = "tos", label = "I accept the terms", required = true}),
					c.button(doc, {type = .submit}, k.text(doc, "Submit")),
				),
			),
		),
	)
}
