package main

import c "../component"
import k "kashmir:."

demo_checkbox :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size) * 3, context.temp_allocator)
	for size in c.Size {
		name := k.doc_format(doc, "%v", size)
		append(&sizes, c.checkbox(doc, {size = size, label = name}))
		append(
			&sizes,
			c.checkbox(
				doc,
				{size = size, label = k.doc_format(doc, "%v checked", size), checked = true},
			),
		)
		append(
			&sizes,
			c.checkbox(
				doc,
				{
					size = size,
					label = k.doc_format(doc, "%v indeterminate", size),
					indeterminate = true,
				},
			),
		)
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius) * 2, context.temp_allocator)
	for radius in c.Radius {
		name := k.doc_format(doc, "%v", radius)
		append(&radii, c.checkbox(doc, {radius = radius, label = name}))
		append(
			&radii,
			c.checkbox(
				doc,
				{radius = radius, label = k.doc_format(doc, "%v checked", radius), checked = true},
			),
		)
	}

	return k.div(
		doc,
		{},
		demo_section(
			doc,
			"States",
			c.checkbox(doc, {name = "a", label = "Unchecked"}),
			c.checkbox(doc, {name = "b", label = "Checked", checked = true}),
			c.checkbox(
				doc,
				{name = "c", label = "Indeterminate (click to clear)", indeterminate = true},
			),
			c.checkbox(doc, {name = "d", label = "Disabled", disabled = true}),
			c.checkbox(
				doc,
				{name = "e", label = "Disabled and checked", disabled = true, checked = true},
			),
			c.checkbox(
				doc,
				{name = "f", label = "Error", error = true, aria_described_by = "error-hint"},
			),
		),
		demo_section(doc, "Size", ..sizes[:]),
		demo_section(doc, "Radius", ..radii[:]),
		demo_section(
			doc,
			"No visible label",
			c.checkbox(doc, {name = "g", aria_label = "Select row 1"}),
			c.checkbox(doc, {name = "h", aria_label = "Select row 2", checked = true}),
		),
		demo_section(
			doc,
			"In a form: the URL shows what was submitted",
			k.form(
				doc,
				{method = .get},
				c.checkbox(
					doc,
					{
						id = "terms",
						name = "terms",
						value = "yes",
						label = "I agree to the terms",
						required = true,
					},
				),
				c.checkbox(
					doc,
					{
						name = "news",
						value = "weekly",
						label = "Send me the newsletter",
						checked = true,
					},
				),
				c.button(doc, {type = .submit}, k.text(doc, "Submit")),
			),
		),
		k.p(
			doc,
			{id = "error-hint", class = "demo__note"},
			k.text(doc, "The error checkbox points here with aria-describedby."),
		),
	)
}
