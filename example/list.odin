package main

import c "../component"
import k "kashmir:."

list_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "list"),
		k.text(doc, " is a vertical list of rows, on a "),
		doc_code(doc, "<ul>"),
		k.text(doc, ", or an "),
		doc_code(doc, "<ol>"),
		k.text(
			doc,
			" when numbered. The rows are data, so the list can check them as a set: an icon list gives every row an icon, and any other marker gives none.",
		),
	)
}

// A block of the list page: the title, a note, the demos, then a rule.
list_section :: proc(doc: ^k.Doc, title, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

list_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 28rem; align-items: stretch"},
		..children,
	)
}

// Three rows, each built fresh: a node has one parent.
list_rows :: proc(doc: ^k.Doc) -> []c.List_Item {
	rows := make([]c.List_Item, 3, context.temp_allocator)
	rows[0] = {
		content = k.text(doc, "Register an account"),
	}
	rows[1] = {
		content = k.text(doc, "Verify your email"),
	}
	rows[2] = {
		content = k.text(doc, "Choose a plan"),
	}
	return rows
}

demo_list :: proc(doc: ^k.Doc) -> k.Node_Id {
	markers := make([dynamic]k.Node_Id, 0, len(c.List_Marker), context.temp_allocator)
	for marker in c.List_Marker {
		if marker == .icon do continue
		append(
			&markers,
			c.list(
				doc,
				{
					marker = marker,
					aria_label = k.doc_format(doc, "%v list", marker),
					items = list_rows(doc),
				},
			),
		)
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.list(
				doc,
				{
					marker = .bulleted,
					size = size,
					aria_label = k.doc_format(doc, "%v list", size),
					items = list_rows(doc),
				},
			),
		)
	}

	features := make([]c.List_Item, 3, context.temp_allocator)
	features[0] = {
		content = k.text(doc, "Typed props"),
		icon    = c.icon(doc, {name = .check, size = .small}),
	}
	features[1] = {
		content = k.text(doc, "Asserts on mistakes"),
		icon    = c.icon(doc, {name = .info, size = .small}),
	}
	features[2] = {
		content = k.text(doc, "Works without script"),
		icon    = c.icon(doc, {name = .star, size = .small}),
	}

	states := make([]c.List_Item, 4, context.temp_allocator)
	states[0] = {
		content = k.text(doc, "An ordinary row"),
	}
	states[1] = {
		content = k.text(doc, "The current row"),
		active  = true,
	}
	states[2] = {
		content  = k.text(doc, "A disabled row"),
		disabled = true,
	}
	states[3] = {
		content = k.text(doc, "Another ordinary row"),
	}

	rich := make([]c.List_Item, 3, context.temp_allocator)
	rich[0] = {
		content = k.span(
			doc,
			{},
			k.strong(doc, {}, k.text(doc, "Ada")),
			k.text(doc, " wrote the first program"),
		),
	}
	rich[1] = {
		content = k.span(
			doc,
			{},
			k.text(doc, "Read "),
			c.link(
				doc,
				{href = "/component/link", shape = .text},
				k.text(doc, "the link component"),
			),
		),
	}
	rich[2] = {
		content = k.span(
			doc,
			{},
			k.text(doc, "Press "),
			k.code(doc, {}, k.text(doc, "Escape")),
			k.text(doc, " to close"),
		),
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		list_section(
			doc,
			"Markers",
			"Plain is the zero value. Numbered renders an ordered list, so a screen reader announces it as one.",
			list_column(doc, ..markers[:]),
		),
		list_section(
			doc,
			"Icon",
			"Every row gives an icon. Build each one fresh; a node has one parent.",
			list_column(
				doc,
				c.list(doc, {marker = .icon, aria_label = "Features", items = features}),
			),
		),
		list_section(
			doc,
			"Size",
			"The shared Size enum. Each size owns the gap between rows and the font size.",
			list_column(doc, ..sizes[:]),
		),
		list_section(
			doc,
			"Divided",
			"A rule between rows, none after the last.",
			list_column(
				doc,
				c.list(doc, {divided = true, aria_label = "Divided list", items = list_rows(doc)}),
			),
		),
		list_section(
			doc,
			"Active and disabled",
			"Active colours the row. It is a look only; a screen reader hears nothing different. Disabled mutes the row and sets aria-disabled.",
			list_column(
				doc,
				c.list(doc, {marker = .bulleted, aria_label = "States", items = states}),
			),
		),
		list_section(
			doc,
			"Rich content",
			"A row's content is a node, so it can hold bold text, a link or code.",
			list_column(
				doc,
				c.list(doc, {marker = .bulleted, aria_label = "Rich rows", items = rich}),
			),
		),
	)
}
