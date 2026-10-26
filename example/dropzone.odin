package main

import c "../component"
import k "kashmir:."

dropzone_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "dropzone"),
		k.text(
			doc,
			" is a file picker that also takes drops and pastes, with a list of the chosen files. The control is input_file behind the whole area, so a click works without script. Script lists the files and checks the type, the count and the size, with a message for each rejection. That is a convenience, not a security check: verify the same things when the upload arrives.",
		),
	)
}

dropzone_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

dropzone_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 32rem; align-items: stretch"},
		..children,
	)
}

demo_dropzone :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.dropzone(doc, {id = k.doc_format(doc, "dz-size-%d", int(size)), name = "size", size = size}),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		dropzone_section(
			doc,
			"Single file",
			"One file at a time: a second one replaces the first.",
			dropzone_column(doc, c.dropzone(doc, {id = "dz-single", name = "single", help = "Any file"})),
		),
		dropzone_section(
			doc,
			"Multiple files",
			"Each chosen file is listed with a button named after it.",
			dropzone_column(
				doc,
				c.dropzone(doc, {id = "dz-multiple", name = "many", multiple = true, help = "Drop several files"}),
			),
		),
		dropzone_section(
			doc,
			"Images only",
			"accept applies to dropped and pasted files too, not only to the chooser.",
			dropzone_column(
				doc,
				c.dropzone(
					doc,
					{
						id = "dz-images",
						name = "images",
						multiple = true,
						accept = "image/*",
						help = "PNG, JPG or GIF",
					},
				),
			),
		),
		dropzone_section(
			doc,
			"Limits",
			"At most two files, each under 1 KB. A file that breaks a limit is refused with a message.",
			dropzone_column(
				doc,
				c.dropzone(
					doc,
					{
						id = "dz-limits",
						name = "limited",
						multiple = true,
						max_files = 2,
						max_bytes = 1024,
						help = "Up to 2 files, 1 KB each",
					},
				),
			),
		),
		dropzone_section(
			doc,
			"Error",
			"error is a message. It sets aria-invalid on the input and is read with it.",
			dropzone_column(
				doc,
				c.dropzone(doc, {id = "dz-error", name = "failed", required = true, error = "Attach the signed form"}),
			),
		),
		dropzone_section(
			doc,
			"Disabled",
			"A disabled zone ignores drops, and the browser does not open the file instead.",
			dropzone_column(doc, c.dropzone(doc, {id = "dz-off", name = "off", disabled = true})),
		),
		dropzone_section(
			doc,
			"Size",
			"The shared Size enum sets the minimum height.",
			dropzone_column(doc, ..sizes[:]),
		),
	)
}
