package main

import c "../component"
import k "kashmir:."

textarea_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "input_textarea"),
		k.text(
			doc,
			" is a multi-line text field. It is an input, so it takes the same size, radius, error and disabled styles as ",
		),
		doc_code(doc, "input_text"),
		k.text(doc, ", and its height comes from "),
		doc_code(doc, "rows"),
		k.text(doc, ". A value that starts with a newline keeps it."),
	)
}

// A block of the textarea page: the API name, a note, the demos, then a rule.
textarea_section :: proc(doc: ^k.Doc, title, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

textarea_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 32rem"},
		..children,
	)
}

demo_textarea :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		label := k.doc_format(doc, "%v", size)
		append(
			&sizes,
			c.input_textarea(
				doc,
				{size = size, rows = 2, placeholder = label, aria_label = label},
			),
		)
	}

	resizes := make([dynamic]k.Node_Id, 0, len(c.Input_Textarea_Resize), context.temp_allocator)
	for resize in c.Input_Textarea_Resize {
		label := k.doc_format(doc, "%v", resize)
		append(
			&resizes,
			c.input_textarea(doc, {resize = resize, rows = 2, value = label, aria_label = label}),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		textarea_section(
			doc,
			"Basic",
			"rows sets the height in lines; the browser default is 2.",
			textarea_column(
				doc,
				c.input_textarea(
					doc,
					{
						name = "bio",
						placeholder = "Tell us about yourself",
						rows = 4,
						aria_label = "Bio",
					},
				),
				c.input_textarea(
					doc,
					{
						value = "A value that\nspans two lines.",
						rows = 3,
						aria_label = "With a value",
					},
				),
			),
		),
		textarea_section(
			doc,
			"Size and radius",
			"The shared Size and Radius enums, as on input_text.",
			textarea_column(doc, ..sizes[:]),
			textarea_column(
				doc,
				c.input_textarea(
					doc,
					{radius = .rounded, rows = 2, placeholder = "Rounded", aria_label = "Rounded"},
				),
				c.input_textarea(
					doc,
					{radius = .none, rows = 2, placeholder = "Square", aria_label = "Square"},
				),
			),
		),
		textarea_section(
			doc,
			"Resize",
			"Which handle the user gets. Auto grows with the text, with no script, in Chrome and Edge; elsewhere it is a normal textarea. Type into the Auto field to see it.",
			textarea_column(doc, ..resizes[:]),
		),
		textarea_section(
			doc,
			"Wrap",
			"Off stops wrapping and scrolls sideways, for code or logs. Hard adds line breaks to the submitted text where it wrapped.",
			textarea_column(
				doc,
				c.input_textarea(
					doc,
					{
						wrap = .soft,
						rows = 2,
						value = "Soft: a long line wraps on screen and is submitted as one line. Soft: a long line wraps on screen and is submitted as one line.",
						aria_label = "Soft wrap",
					},
				),
				c.input_textarea(
					doc,
					{
						wrap = .off,
						rows = 2,
						value = "Off: a long line stays on one line and the field scrolls sideways instead of wrapping it. Off: a long line stays on one line.",
						aria_label = "No wrap",
					},
				),
			),
		),
		textarea_section(
			doc,
			"Leading newline",
			"A browser drops one newline right after the tag, so a value that starts with one would lose it. The component writes the value with an extra newline in front, so the first field below really starts with a blank line.",
			textarea_column(
				doc,
				c.input_textarea(
					doc,
					{
						value = "\nStarts with a blank line",
						rows = 3,
						aria_label = "Starts with a newline",
					},
				),
				c.input_textarea(
					doc,
					{value = "Starts with text", rows = 3, aria_label = "Starts with text"},
				),
			),
		),
		textarea_section(
			doc,
			"State",
			"error sets aria-invalid and the red styling; point aria_described_by at the message.",
			textarea_column(
				doc,
				c.input_textarea(doc, {value = "Normal", rows = 2, aria_label = "Normal"}),
				c.input_textarea(
					doc,
					{
						value = "Not valid",
						error = true,
						rows = 2,
						aria_label = "With error",
						aria_described_by = "textarea-error-hint",
					},
				),
				k.p(
					doc,
					{id = "textarea-error-hint", class = "demo__note"},
					k.text(doc, "The error field points here with aria-describedby."),
				),
				c.input_textarea(
					doc,
					{value = "Disabled", disabled = true, rows = 2, aria_label = "Disabled"},
				),
				c.input_textarea(
					doc,
					{value = "Read only", read_only = true, rows = 2, aria_label = "Read only"},
				),
				c.input_textarea(
					doc,
					{placeholder = "Required", required = true, rows = 2, aria_label = "Required"},
				),
			),
		),
		textarea_section(
			doc,
			"In a form",
			"max_length limits what can be typed. Submit and read the address bar for what is sent.",
			textarea_column(
				doc,
				k.form(
					doc,
					{
						method = .get,
						style = "display: flex; flex-direction: column; gap: var(--spacing-4); align-items: flex-start; width: 100%",
					},
					c.input_textarea(
						doc,
						{
							name = "message",
							max_length = 40,
							rows = 3,
							value = "Hello,\nworld",
							placeholder = "Up to 40 characters",
							aria_label = "Message, up to 40 characters",
						},
					),
					c.button(doc, {type = .submit}, k.text(doc, "Submit")),
				),
			),
		),
	)
}
