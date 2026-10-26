package main

import c "../component"
import k "kashmir:."

demo_badge :: proc(doc: ^k.Doc) -> k.Node_Id {
	label :: proc(doc: ^k.Doc, text: string) -> k.Node_Id {return k.text(doc, text)}

	variants := make([dynamic]k.Node_Id, 0, len(c.Variant) * len(c.Shape), context.temp_allocator)
	for variant in c.Variant {
		for shape in c.Shape {
			name := k.doc_format(doc, "%v %v", variant, shape)
			append(&variants, c.badge(doc, {variant = variant, shape = shape}, label(doc, name)))
		}
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(&sizes, c.badge(doc, {size = size}, label(doc, k.doc_format(doc, "%v", size))))
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		append(
			&radii,
			c.badge(doc, {radius = radius}, label(doc, k.doc_format(doc, "%v", radius))),
		)
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Variant and shape", ..variants[:]),
		demo_section(doc, "Size", ..sizes[:]),
		demo_section(doc, "Radius", ..radii[:]),
		demo_section(
			doc,
			"State",
			c.badge(doc, {dismissible = true, aria_label = "Beta"}, label(doc, "Dismissible")),
			c.badge(doc, {disabled = true}, label(doc, "Disabled")),
			c.badge(
				doc,
				{dismissible = true, disabled = true},
				label(doc, "Disabled dismissible"),
			),
		),
		demo_section(
			doc,
			"Group",
			c.badge_group(
				doc,
				{aria_label = "Tags"},
				c.badge(doc, {variant = .info, shape = .soft}, label(doc, "odin")),
				c.badge(doc, {variant = .success, shape = .soft}, label(doc, "html")),
				c.badge(doc, {variant = .warning, shape = .soft}, label(doc, "css")),
			),
		),
	)
}
