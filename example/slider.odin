package main

import c "../component"
import k "kashmir:."

slider_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "slider"),
		k.text(doc, " is "),
		doc_code(doc, "input_range"),
		k.text(
			doc,
			" with a label, a live readout and a track that fills up to the thumb. The readout is an <output>, not a live region, so a screen reader announces the slider's own value once. Without script the fill and number show the starting value and the slider still works.",
		),
	)
}

slider_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

slider_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 28rem; align-items: stretch"},
		..children,
	)
}

demo_slider :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.slider(
				doc,
				{
					id = k.doc_format(doc, "slider-size-%d", int(size)),
					label = k.doc_format(doc, "%v", size),
					value = 60.0,
					show_value = true,
					size = size,
				},
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		slider_section(
			doc,
			"Basic",
			"The thumb at the middle of 0 to 100 when no value is given.",
			slider_column(
				doc,
				c.slider(doc, {id = "slider-basic", name = "basic", label = "Brightness"}),
			),
		),
		slider_section(
			doc,
			"With value",
			"show_value adds the number beside the label, and a unit goes after it.",
			slider_column(
				doc,
				c.slider(
					doc,
					{
						id = "slider-value",
						name = "volume",
						label = "Volume",
						value = 40.0,
						show_value = true,
						unit = "%",
					},
				),
			),
		),
		slider_section(
			doc,
			"Range and step",
			"min, max and step are the input's own. Here 0 to 1 in steps of 0.25.",
			slider_column(
				doc,
				c.slider(
					doc,
					{
						id = "slider-step",
						name = "opacity",
						label = "Opacity",
						min = 0.0,
						max = 1.0,
						step = 0.25,
						value = 0.5,
						show_value = true,
					},
				),
			),
		),
		slider_section(
			doc,
			"Size",
			"The shared Size enum sets the track and the thumb.",
			slider_column(doc, ..sizes[:]),
		),
		slider_section(
			doc,
			"Without a visible label",
			"aria_label names it when there is no room for text.",
			slider_column(
				doc,
				c.slider(
					doc,
					{
						id = "slider-quiet",
						name = "quiet",
						aria_label = "Quiet slider",
						value = 30.0,
					},
				),
			),
		),
		slider_section(
			doc,
			"Error and disabled",
			"Error turns the fill red and sets aria-invalid.",
			slider_column(
				doc,
				c.slider(
					doc,
					{
						id = "slider-error",
						label = "Too high",
						value = 90.0,
						show_value = true,
						error = true,
					},
				),
				c.slider(
					doc,
					{
						id = "slider-off",
						label = "Locked",
						value = 60.0,
						show_value = true,
						disabled = true,
					},
				),
			),
		),
	)
}
