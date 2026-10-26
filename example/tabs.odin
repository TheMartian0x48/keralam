package main

import c "../component"
import k "kashmir:."

tabs_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "tabs"),
		k.text(
			doc,
			" takes a slice of tabs, each holding its value, label and panel, so every button has a panel. With nothing selected the first enabled tab is shown, and ids come from the set's own id, so two sets can use the same values. Arrow keys move between tabs, Home and End jump to the ends, and a disabled tab is skipped.",
		),
	)
}

tabs_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

// Three tabs with the same values every time, to show that ids do not collide.
tabs_account :: proc(doc: ^k.Doc, tabs_array: ^[3]c.Tab) -> []c.Tab {
	tabs_array^ = {
		{value = "overview", title = "Overview", panel = k.text(doc, "A summary of the account.")},
		{
			value = "billing",
			title = "Billing",
			panel = k.text(doc, "Invoices and payment methods."),
		},
		{value = "members", title = "Members", panel = k.text(doc, "Who can see this account.")},
	}
	return tabs_array[:]
}

demo_tabs :: proc(doc: ^k.Doc) -> k.Node_Id {
	first, second, third, fourth: [3]c.Tab
	disabled := [?]c.Tab {
		{value = "a", title = "Active", panel = k.text(doc, "The first tab is shown.")},
		{value = "b", title = "Archived", panel = k.text(doc, "Never shown."), disabled = true},
		{value = "c", title = "Settings", panel = k.text(doc, "Arrow keys skip Archived.")},
	}
	with_icons := [?]c.Tab {
		{
			value = "home",
			label = c.icon(doc, {name = .house, size = .small}),
			aria_label = "Home",
			panel = k.text(doc, "Icon only: the name comes from aria_label."),
		},
		{
			value = "mail",
			label = k.span(
				doc,
				{},
				c.icon(doc, {name = .envelope, size = .small}),
				k.text(doc, " Mail"),
			),
			aria_label = "Mail",
			panel = k.text(doc, "An icon beside text."),
		},
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	size_tabs: [len(c.Size)][3]c.Tab
	for size, index in c.Size {
		append(&sizes, c.tabs(doc, {tabs = tabs_account(doc, &size_tabs[index]), size = size}))
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		tabs_section(
			doc,
			"Default",
			"No selected value: the first tab is shown.",
			c.tabs(doc, {tabs = tabs_account(doc, &first)}),
		),
		tabs_section(
			doc,
			"Preselected",
			"selected = \"billing\" shows that tab first.",
			c.tabs(doc, {tabs = tabs_account(doc, &second), selected = "billing"}),
		),
		tabs_section(
			doc,
			"Disabled tab",
			"A disabled tab cannot be picked and the arrow keys step over it.",
			c.tabs(doc, {tabs = disabled[:]}),
		),
		tabs_section(
			doc,
			"Icons",
			"A label can be a node. With no words in it, aria_label names the tab.",
			c.tabs(doc, {tabs = with_icons[:]}),
		),
		tabs_section(
			doc,
			"Vertical",
			"The buttons in a column. Up and Down move between them.",
			c.tabs(doc, {tabs = tabs_account(doc, &third), vertical = true}),
		),
		tabs_section(
			doc,
			"Size",
			"The shared Size enum sets the buttons' text and padding.",
			k.div(
				doc,
				{style = "display: flex; flex-direction: column; gap: var(--spacing-6)"},
				..sizes[:],
			),
		),
		tabs_section(
			doc,
			"Two sets, same values",
			"Both sets use \"overview\", \"billing\" and \"members\". Their ids differ, so each button controls its own panel.",
			k.div(
				doc,
				{style = "display: flex; flex-direction: column; gap: var(--spacing-6)"},
				c.tabs(doc, {tabs = tabs_account(doc, &fourth), selected = "members"}),
			),
		),
	)
}
