package main

import c "../component"
import k "kashmir:."

demo_button :: proc(doc: ^k.Doc) -> k.Node_Id {
	label :: proc(doc: ^k.Doc, text: string) -> k.Node_Id {return k.text(doc, text)}

	// Button CSS styles only these variants so far.
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
			append(&variants, c.button(doc, {variant = variant, shape = shape}, label(doc, name)))
		}
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(&sizes, c.button(doc, {size = size}, label(doc, k.doc_format(doc, "%v", size))))
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		append(
			&radii,
			c.button(doc, {radius = radius}, label(doc, k.doc_format(doc, "%v", radius))),
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
			c.button(doc, {disabled = true}, label(doc, "Disabled")),
			c.button(doc, {aria_disabled = true}, label(doc, "Aria disabled")),
			c.button(doc, {loading = true}, label(doc, "Loading")),
		),
		demo_section(
			doc,
			"Type",
			k.form(
				doc,
				{},
				c.button(doc, {type = .submit}, label(doc, "Submit")),
				c.button(doc, {type = .reset}, label(doc, "Reset")),
			),
		),
	)
}
