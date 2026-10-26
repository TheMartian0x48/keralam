package main

import c "../component"
import k "kashmir:."

progress_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "progress"),
		k.text(doc, " is a bar and "),
		doc_code(doc, "progress_circular"),
		k.text(
			doc,
			" a ring, drawn with CSS. A screen reader is given the real value and maximum (37 of 50), not a percentage. Indeterminate is only on when asked for: a value of 0 is a bar at 0. A value outside 0 to max is clamped, since it usually comes from a sum that can overshoot by a rounding step.",
		),
	)
}

// A block of the progress page: the title, a note, the demos, then a rule.
progress_section :: proc(doc: ^k.Doc, title, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

progress_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 28rem; align-items: stretch"},
		..children,
	)
}

progress_row :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(doc, {style = "align-items: center; gap: var(--spacing-6)"}, ..children)
}

demo_progress :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.progress(
				doc,
				{
					value = 60,
					size = size,
					label = k.doc_format(doc, "%v", size),
					show_value = true,
				},
			),
		)
	}

	values := make([dynamic]k.Node_Id, 0, 5, context.temp_allocator)
	for value in ([?]f64{0, 25, 50, 75, 100}) {
		append(
			&values,
			c.progress(
				doc,
				{
					value = value,
					aria_label = k.doc_format(doc, "%.0f percent", value),
					show_value = true,
					label = k.doc_format(doc, "%.0f", value),
				},
			),
		)
	}

	rings := make([dynamic]k.Node_Id, 0, 5, context.temp_allocator)
	for diameter in ([?]u32{24, 32, 48, 64, 96}) {
		append(
			&rings,
			c.progress_circular(
				doc,
				{
					value = 70,
					diameter = diameter,
					thickness = diameter >= 64 ? 6 : 4,
					show_value = diameter >= 48,
					aria_label = k.doc_format(doc, "%d pixel ring", diameter),
				},
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		progress_section(
			doc,
			"Linear",
			"A label names the bar, and show_value adds the percentage. The percentage text is hidden from a screen reader, which is told the real value instead.",
			progress_column(
				doc,
				c.progress(doc, {value = 40, label = "Uploading photos", show_value = true}),
			),
		),
		progress_section(
			doc,
			"Values",
			"From empty to full. A bar at 0 is a bar at 0, not a spinner.",
			progress_column(doc, ..values[:]),
		),
		progress_section(
			doc,
			"Size",
			"The shared Size enum: the bar is 4, 8 or 12px thick.",
			progress_column(doc, ..sizes[:]),
		),
		progress_section(
			doc,
			"A maximum that is not 100",
			"37 of 50 files is 74% of the bar, and a screen reader is told 37 of 50.",
			progress_column(
				doc,
				c.progress(
					doc,
					{value = 37, max = f64(50), label = "37 of 50 files", show_value = true},
				),
			),
		),
		progress_section(
			doc,
			"Clamped",
			"A value past the end, or below zero, draws a full or empty bar. NaN and infinity assert.",
			progress_column(
				doc,
				c.progress(doc, {value = 130, label = "130 of 100", show_value = true}),
				c.progress(doc, {value = -20, label = "-20 of 100", show_value = true}),
			),
		),
		progress_section(
			doc,
			"Indeterminate",
			"For an unknown duration. There is no number, so show_value is refused. With reduced motion the bar sits still at half strength.",
			progress_column(
				doc,
				c.progress(doc, {indeterminate = true, label = "Loading"}),
				c.progress(doc, {indeterminate = true, aria_label = "Working", size = .large}),
			),
		),
		progress_section(
			doc,
			"Circular",
			"A ring with the percentage inside when there is room: it must be at least 32px across the hole. Thickness is in pixels.",
			progress_row(doc, ..rings[:]),
		),
		progress_section(
			doc,
			"Spinner",
			"progress_circular with indeterminate. It has no visible label, so aria_label is required.",
			progress_row(
				doc,
				c.progress_circular(doc, {indeterminate = true, aria_label = "Loading"}),
				c.progress_circular(
					doc,
					{
						indeterminate = true,
						diameter = 48,
						thickness = 5,
						aria_label = "Still loading",
					},
				),
				c.progress_circular(
					doc,
					{value = 0, diameter = 48, thickness = 5, aria_label = "Zero, not a spinner"},
				),
			),
		),
	)
}
