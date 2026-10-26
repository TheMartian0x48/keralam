package main

import c "../component"
import k "kashmir:."

demo_alert :: proc(doc: ^k.Doc) -> k.Node_Id {
	label :: proc(doc: ^k.Doc, text: string) -> k.Node_Id {return k.text(doc, text)}

	combinations := make(
		[dynamic]k.Node_Id,
		0,
		len(c.Alert_Variant) * len(c.Shape),
		context.temp_allocator,
	)
	for shape in c.Shape {
		for variant in c.Alert_Variant {
			name := k.doc_format(doc, "%v %v", variant, shape)
			append(
				&combinations,
				c.alert(
					doc,
					{variant = variant, shape = shape, title = name},
					label(doc, "Something happened."),
				),
			)
		}
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Variant and shape", ..combinations[:]),
		demo_section(
			doc,
			"Options",
			c.alert(doc, {shape = .soft}, label(doc, "No title, just a message.")),
			c.alert(
				doc,
				{shape = .soft, hide_icon = true, title = "No icon"},
				label(doc, "The icon is hidden."),
			),
			c.alert(
				doc,
				{shape = .soft, variant = .success, dismissible = true, title = "Dismissible"},
				label(doc, "Close me, or press Escape."),
			),
			c.alert(
				doc,
				{shape = .soft, variant = .warning, dismiss_timeout = 8000, title = "Timed"},
				label(doc, "Gone after eight seconds."),
			),
		),
	)
}
