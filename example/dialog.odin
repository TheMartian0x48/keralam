package main

import c "../component"
import k "kashmir:."

// Opens the dialog with the given id, with no script (the command attributes).
dialog_opener :: proc(doc: ^k.Doc, dialog_id, label: string) -> k.Node_Id {
	return c.button(
		doc,
		{
			attributes = {
				k.attribute("command", "show-modal"),
				k.attribute("commandfor", dialog_id),
			},
		},
		k.text(doc, label),
	)
}

// Closes the dialog it sits in, declaratively, with no script either.
dialog_closer :: proc(doc: ^k.Doc, dialog_id, label: string, shape: c.Shape) -> k.Node_Id {
	return c.button(
		doc,
		{
			shape = shape,
			variant = shape == .solid ? .primary : .secondary,
			attributes = {k.attribute("command", "close"), k.attribute("commandfor", dialog_id)},
		},
		k.text(doc, label),
	)
}

demo_dialog :: proc(doc: ^k.Doc) -> k.Node_Id {
	openers := make([dynamic]k.Node_Id, 0, len(c.Dialog_Size) + 1, context.temp_allocator)
	dialogs := make([dynamic]k.Node_Id, 0, len(c.Dialog_Size) + 1, context.temp_allocator)

	for size in c.Dialog_Size {
		dialog_id := k.doc_format(doc, "dialog-%v", size)
		label := k.doc_format(doc, "%v", size)
		append(&openers, dialog_opener(doc, dialog_id, label))
		append(
			&dialogs,
			c.dialog(
				doc,
				{id = dialog_id, title = label, size = size},
				k.text(doc, "Press Escape, use the close button, or click the button below."),
			),
		)
	}

	append(&openers, dialog_opener(doc, "dialog-confirm", "With description and footer"))
	append(
		&dialogs,
		c.dialog(
			doc,
			{
				id = "dialog-confirm",
				title = "Delete this item?",
				description = "This cannot be undone.",
			},
			k.text(doc, "The item and everything inside it will be removed."),
			c.dialog_footer(
				doc,
				{},
				dialog_closer(doc, "dialog-confirm", "Cancel", .text),
				dialog_closer(doc, "dialog-confirm", "Delete", .solid),
			),
		),
	)

	return k.div(
		doc,
		{},
		demo_section(doc, "Open a dialog", ..openers[:]),
		k.p(
			doc,
			{class = "demo__note"},
			k.text(
				doc,
				"Opening uses the declarative command attributes (Chrome 135, Safari 18.4, Firefox 144 or newer).",
			),
		),
		k.div(doc, {}, ..dialogs[:]),
	)
}
