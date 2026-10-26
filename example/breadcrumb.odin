package main

import c "../component"
import k "kashmir:."

demo_breadcrumb :: proc(doc: ^k.Doc) -> k.Node_Id {
	trail := [?]c.Breadcrumb_Item {
		{label = "Home", href = "/"},
		{label = "Components", href = "/"},
		{label = "Breadcrumb", current = true},
	}

	separators := [?]string{"/", ">", "›", "→", "·", "»"}
	by_separator := make([dynamic]k.Node_Id, 0, len(separators), context.temp_allocator)
	for separator in separators {
		append(&by_separator, c.breadcrumb(doc, {items = trail[:], separator = separator}))
	}

	text_middle := [?]c.Breadcrumb_Item {
		{label = "Home", href = "/"},
		{label = "Archive"},
		{label = "2026", current = true},
	}

	long := [?]c.Breadcrumb_Item {
		{label = "Home", href = "/"},
		{label = "Documentation", href = "/"},
		{label = "Components", href = "/"},
		{label = "Navigation and wayfinding", href = "/"},
		{label = "Breadcrumbs with a very long title that needs truncating", current = true},
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Default", c.breadcrumb(doc, {items = trail[:]})),
		demo_section(doc, "Separators", ..by_separator[:]),
		demo_section(doc, "A text-only step", c.breadcrumb(doc, {items = text_middle[:]})),
		demo_section(doc, "Single item", c.breadcrumb(doc, {items = trail[2:]})),
		demo_section(
			doc,
			"Long trail (resize the window to see truncation)",
			c.breadcrumb(doc, {items = long[:]}),
		),
	)
}
