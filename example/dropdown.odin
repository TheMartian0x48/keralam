package main

import c "../component"
import k "kashmir:."

dropdown_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "A collapsible menu on the native "),
		doc_code(doc, "<details>"),
		k.text(doc, " element. It closes on an outside click, "),
		doc_code(doc, "Escape"),
		k.text(doc, " or a pick, and moves between items with the arrow keys, "),
		doc_code(doc, "Home"),
		k.text(doc, " and "),
		doc_code(doc, "End"),
		k.text(
			doc,
			". The trigger has its own styles and does not depend on the button component.",
		),
	)
}

// A fresh set of nodes each call: a node can only have one parent.
dropdown_actions :: proc(doc: ^k.Doc) -> []k.Node_Id {
	nodes := make([]k.Node_Id, 4, context.temp_allocator)
	nodes[0] = c.dropdown_item(doc, {label = "Edit", icon = .pencil_simple})
	nodes[1] = c.dropdown_item(doc, {label = "Duplicate", icon = .copy})
	nodes[2] = c.dropdown_divider(doc, {})
	nodes[3] = c.dropdown_item(doc, {label = "Delete", icon = .trash, danger = true})
	return nodes
}

demo_dropdown :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		doc_group(
			doc,
			"Basic",
			doc_description(
				doc,
				k.text(doc, "Each item is a "),
				doc_code(doc, "<button>"),
				k.text(doc, ", or a link when it has an "),
				doc_code(doc, "href"),
				k.text(doc, ". Set "),
				doc_code(doc, "danger"),
				k.text(doc, " on a destructive action."),
			),
			doc_list(
				doc,
				{style = "min-height: 14rem; align-items: flex-start"},
				c.dropdown(doc, {id = "dd-basic", label = "Options"}, ..dropdown_actions(doc)),
			),
		),
		doc_group(
			doc,
			"Labels and dividers",
			doc_description(
				doc,
				k.text(doc, "A "),
				doc_code(doc, "dropdown_label"),
				k.text(doc, " names a group and is not selectable. A "),
				doc_code(doc, "dropdown_divider"),
				k.text(doc, " separates groups."),
			),
			doc_list(
				doc,
				{style = "min-height: 18rem; align-items: flex-start"},
				c.dropdown(
					doc,
					{id = "dd-groups", label = "Account"},
					c.dropdown_label(doc, {}, k.text(doc, "Signed in as ada")),
					c.dropdown_item(
						doc,
						{label = "Profile", href = "/component/dropdown", icon = .user},
					),
					c.dropdown_item(
						doc,
						{label = "Settings", href = "/component/dropdown", icon = .gear},
					),
					c.dropdown_divider(doc, {}),
					c.dropdown_label(doc, {}, k.text(doc, "Danger zone")),
					c.dropdown_item(doc, {label = "Sign out", icon = .sign_out, danger = true}),
				),
			),
		),
		doc_group(
			doc,
			"Aligned to the end",
			doc_description(
				doc,
				k.text(doc, "Set "),
				doc_code(doc, "align = .end"),
				k.text(
					doc,
					" so the menu lines up with the trigger's right edge. Use it for a trigger near the end of a row.",
				),
			),
			doc_list(
				doc,
				{style = "min-height: 14rem; justify-content: flex-end; align-items: flex-start"},
				c.dropdown(
					doc,
					{id = "dd-end", label = "Options", align = .end},
					..dropdown_actions(doc),
				),
			),
		),
		doc_group(
			doc,
			"Opening a dialog from an item",
			doc_description(
				doc,
				k.text(doc, "A button item takes its behaviour from "),
				doc_code(doc, "attributes"),
				k.text(
					doc,
					". This one opens the drawer below with the declarative command attributes, and the menu closes when it is picked.",
				),
			),
			doc_list(
				doc,
				{style = "min-height: 10rem; align-items: flex-start"},
				c.dropdown(
					doc,
					{id = "dd-drawer", label = "Actions"},
					c.dropdown_item(
						doc,
						{
							label = "Open settings drawer",
							icon = .gear,
							attributes = {
								k.attribute("command", "show-modal"),
								k.attribute("commandfor", "dd-drawer-target"),
							},
						},
					),
				),
				c.drawer(
					doc,
					{id = "dd-drawer-target", title = "Settings"},
					k.text(doc, "Opened from a dropdown item."),
				),
			),
		),
	)
}
