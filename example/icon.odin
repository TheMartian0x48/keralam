package main

import c "../component"
import k "kashmir:."

demo_icon :: proc(doc: ^k.Doc) -> k.Node_Id {
	// A few common icons; Icon_Name has all 1,530.
	names := [?]c.Icon_Name {
		.check,
		.x,
		.info,
		.warning,
		.check_circle,
		.x_circle,
		.caret_down,
		.arrow_left,
		.arrow_right,
		.magnifying_glass,
		.house,
		.gear,
		.user,
		.bell,
		.trash,
		.pencil_simple,
	}

	weights := make([dynamic]k.Node_Id, 0, len(c.Icon_Weight), context.temp_allocator)
	for weight in c.Icon_Weight {
		append(
			&weights,
			c.icon(
				doc,
				{
					name = .heart,
					weight = weight,
					size = .large,
					aria_label = k.doc_format(doc, "%v", weight),
				},
			),
		)
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(&sizes, c.icon(doc, {name = .heart, size = size}))
	}

	gallery := make([dynamic]k.Node_Id, 0, len(names), context.temp_allocator)
	for name in names {
		append(&gallery, c.icon(doc, {name = name, aria_label = k.doc_format(doc, "%v", name)}))
	}


	all_icons := make([dynamic]k.Node_Id, 0, len(c.Icon_Name), context.temp_allocator)
	for name in c.Icon_Name {
		append(&all_icons, c.icon(doc, {name = name, aria_label = k.doc_format(doc, "%v", name)}))
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Common icons", ..gallery[:]),
		demo_section(doc, "Weight", ..weights[:]),
		demo_section(doc, "Size", ..sizes[:]),
		demo_section(
			doc,
			"Color",
			k.span(
				doc,
				{style = "color: var(--color-primary)"},
				c.icon(doc, {name = .check_circle, weight = .fill}),
			),
			k.span(
				doc,
				{style = "color: var(--color-danger)"},
				c.icon(doc, {name = .x_circle, weight = .fill}),
			),
		),
		demo_section(doc, "All Icons", ..all_icons[:]),
	)
}
