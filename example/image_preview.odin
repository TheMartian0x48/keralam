package main

import c "../component"
import k "kashmir:."

// Inline SVG pictures, so the demo needs no files and no network. Each has a distinct
// shape (wider than tall, or taller) so every fit mode visibly differs.
IMAGE_PREVIEW_PICTURE_WIDE :: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='200'%3E%3Crect width='400' height='200' fill='%232563eb'/%3E%3Ccircle cx='200' cy='100' r='70' fill='%23fbbf24'/%3E%3C/svg%3E"
IMAGE_PREVIEW_PICTURE_TALL :: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='400'%3E%3Crect width='200' height='400' fill='%2316a34a'/%3E%3Ccircle cx='100' cy='200' r='70' fill='%23fbbf24'/%3E%3C/svg%3E"

image_preview_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "image_preview"),
		k.text(
			doc,
			" is a box with a fixed aspect ratio. The ratio is two numbers, so there is no string to sanitise. An image needs an alt, or decorative = true. With no src it shows a camera placeholder; the camera is an icon, so the icon font must be provided.",
		),
	)
}

image_preview_section :: proc(doc: ^k.Doc, title, note: string, row: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		row,
		c.divider(doc, {}),
	)
}

// Each preview sits in a fixed-width cell, so widths do not depend on the page.
image_preview_row :: proc(doc: ^k.Doc, cells: ..k.Node_Id) -> k.Node_Id {
	return doc_list(doc, {style = "align-items: flex-start; gap: var(--spacing-6)"}, ..cells)
}

image_preview_cell :: proc(doc: ^k.Doc, caption: string, preview: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{style = "width: 12rem; display: flex; flex-direction: column; gap: var(--spacing-2)"},
		preview,
		k.small(doc, {}, k.text(doc, caption)),
	)
}

demo_image_preview :: proc(doc: ^k.Doc) -> k.Node_Id {
	ratios := make([dynamic]k.Node_Id, 0, 4, context.temp_allocator)
	for ratio in ([?]c.Image_Ratio{{16, 9}, {4, 3}, {1, 1}, {3, 4}}) {
		append(
			&ratios,
			image_preview_cell(
				doc,
				k.doc_format(doc, "%d : %d", ratio.width, ratio.height),
				c.image_preview(
					doc,
					{
						src = IMAGE_PREVIEW_PICTURE_WIDE,
						alt = "A yellow sun on blue",
						ratio = ratio,
					},
				),
			),
		)
	}

	fits := make([dynamic]k.Node_Id, 0, len(c.Image_Preview_Fit), context.temp_allocator)
	for fit in c.Image_Preview_Fit {
		append(
			&fits,
			image_preview_cell(
				doc,
				k.doc_format(doc, "%v", fit),
				c.image_preview(
					doc,
					{
						src = IMAGE_PREVIEW_PICTURE_TALL,
						alt = "A yellow sun on green",
						ratio = c.Image_Ratio{1, 1},
						fit = fit,
					},
				),
			),
		)
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		append(
			&radii,
			image_preview_cell(
				doc,
				k.doc_format(doc, "%v", radius),
				c.image_preview(
					doc,
					{
						src = IMAGE_PREVIEW_PICTURE_WIDE,
						alt = "A yellow sun on blue",
						ratio = c.Image_Ratio{1, 1},
						radius = radius,
					},
				),
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		image_preview_section(
			doc,
			"Ratio",
			"Width over height as two numbers. With none given the box is 16:9.",
			image_preview_row(doc, ..ratios[:]),
		),
		image_preview_section(
			doc,
			"Fit",
			"A tall picture in a square box. Cover crops, Contain shows all of it, Fill stretches it, None keeps its natural size.",
			image_preview_row(doc, ..fits[:]),
		),
		image_preview_section(
			doc,
			"Radius",
			"The shared Radius enum.",
			image_preview_row(doc, ..radii[:]),
		),
		image_preview_section(
			doc,
			"Placeholder",
			"No src. The placeholder is named by alt when there is one, otherwise by its text.",
			image_preview_row(
				doc,
				image_preview_cell(doc, "default", c.image_preview(doc, {})),
				image_preview_cell(
					doc,
					"alt and text",
					c.image_preview(
						doc,
						{
							alt = "Profile photo, none chosen",
							placeholder_text = "Add a photo",
							ratio = c.Image_Ratio{1, 1},
						},
					),
				),
			),
		),
		image_preview_section(
			doc,
			"Decorative",
			"The picture adds nothing a screen reader needs, so alt is written empty.",
			image_preview_row(
				doc,
				image_preview_cell(
					doc,
					"decorative",
					c.image_preview(doc, {src = IMAGE_PREVIEW_PICTURE_WIDE, decorative = true}),
				),
			),
		),
	)
}
