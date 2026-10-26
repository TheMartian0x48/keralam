package main

import c "../component"
import k "kashmir:."

demo_link :: proc(doc: ^k.Doc) -> k.Node_Id {
	label :: proc(doc: ^k.Doc, text: string) -> k.Node_Id {return k.text(doc, text)}

	// Link shares button CSS, which styles only these variants so far.
	variants_styled := [?]c.Variant{.primary, .secondary, .danger}
	variants := make(
		[dynamic]k.Node_Id,
		0,
		len(variants_styled) * len(c.Shape),
		context.temp_allocator,
	)
	for variant in variants_styled {
		for shape in c.Shape {
			name := k.doc_format(doc, "%v %v", variant, shape)
			append(
				&variants,
				c.link(doc, {href = "#", variant = variant, shape = shape}, label(doc, name)),
			)
		}
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.link(doc, {href = "#", size = size}, label(doc, k.doc_format(doc, "%v", size))),
		)
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		append(
			&radii,
			c.link(
				doc,
				{href = "#", radius = radius},
				label(doc, k.doc_format(doc, "%v", radius)),
			),
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
			"Navigation",
			c.link(doc, {href = "/component/button"}, label(doc, "Same tab")),
			c.link(
				doc,
				{href = "https://odin-lang.org", target = "_blank", shape = .outline},
				label(doc, "New tab (rel added)"),
			),
			c.link(doc, {href = "/component/button", disabled = true}, label(doc, "Disabled")),
		),
	)
}
