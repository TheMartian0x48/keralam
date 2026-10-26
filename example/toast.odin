package main

import c "../component"
import k "kashmir:."

toast_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "toast_container"),
		k.text(
			doc,
			" is a fixed region at a corner of the screen, and the page's only live region, so a toast is announced once. Toasts the server knows about go in it directly; the rest are made by script from a button's data attributes or from showToast. Info and success close after 5 seconds, warning and danger stay until closed, the countdown pauses while the pointer or focus is on a toast, and Escape closes the focused one.",
		),
	)
}

toast_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

toast_trigger_button :: proc(
	doc: ^k.Doc,
	label, message, title: string,
	variant: c.Alert_Variant,
	position: c.Toast_Position,
	id: string,
) -> k.Node_Id {
	trigger := c.toast_trigger(message, title, variant, position)
	return c.button(
		doc,
		{id = id, shape = .outline, attributes = trigger[:]},
		k.text(doc, label),
	)
}

demo_toast :: proc(doc: ^k.Doc) -> k.Node_Id {
	variants := make([dynamic]k.Node_Id, 0, len(c.Alert_Variant), context.temp_allocator)
	for variant in c.Alert_Variant {
		append(
			&variants,
			toast_trigger_button(
				doc,
				k.doc_format(doc, "%v", variant),
				k.doc_format(doc, "This is a %v message.", variant),
				k.doc_format(doc, "%v", variant),
				variant,
				.bottom_right,
				k.doc_format(doc, "toast-variant-%d", int(variant)),
			),
		)
	}

	positions := make([dynamic]k.Node_Id, 0, len(c.Toast_Position), context.temp_allocator)
	for position in c.Toast_Position {
		append(
			&positions,
			toast_trigger_button(
				doc,
				k.doc_format(doc, "%v", position),
				"Shown at this corner.",
				"",
				.info,
				position,
				k.doc_format(doc, "toast-position-%d", int(position)),
			),
		)
	}

	// One container per position: the script finds it by position. The page has all six.
	containers := make([dynamic]k.Node_Id, 0, len(c.Toast_Position), context.temp_allocator)
	for position in c.Toast_Position {
		if position == .bottom_right {
			append(
				&containers,
				c.toast_container(
					doc,
					{
						position = position,
						toasts = {
							{variant = .success, title = "Rendered by the server", message = "No script made this one. It stays until closed."},
						},
					},
				),
			)
		} else {
			append(&containers, c.toast_container(doc, {position = position}))
		}
	}

	sections := [?]k.Node_Id {
		toast_section(
			doc,
			"Variants",
			"The same four meanings as alert. Warning and danger have role=\"alert\" and do not close by themselves.",
			doc_list(doc, {}, ..variants[:]),
		),
		toast_section(
			doc,
			"Positions",
			"Six corners. Each has its own container, so a toast goes where its trigger says.",
			doc_list(doc, {}, ..positions[:]),
		),
		toast_section(
			doc,
			"Many at once",
			"At most five stay on screen: the oldest goes first.",
			doc_list(
				doc,
				{},
				toast_trigger_button(doc, "Show one", "One more.", "", .info, .bottom_right, "toast-many"),
			),
		),
		toast_section(
			doc,
			"From code",
			"Application code calls window.showToast(message, type, title, position, { duration }) for the same result.",
			k.NODE_NONE,
		),
	}

	children := make([dynamic]k.Node_Id, 0, len(sections) + len(containers), context.temp_allocator)
	append(&children, ..sections[:])
	append(&children, ..containers[:])
	return k.div(doc, {class = "doc-demo__preview-inner"}, ..children[:])
}
