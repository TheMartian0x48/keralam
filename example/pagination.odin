package main

import c "../component"
import k "kashmir:."

pagination_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "pagination"),
		k.text(
			doc,
			" is a page navigation bar: previous and next, the page numbers between, and a gap where pages are left out. It shows a fixed number of entries however far you page, so the control does not change width, and a gap always stands for at least two pages. On a narrow screen only previous and next remain.",
		),
	)
}

// A block of the pagination page: the title, a note, the demos, then a rule.
pagination_section :: proc(doc: ^k.Doc, title, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

PAGINATION_PREFIX :: "/component/pagination?page="

demo_pagination :: proc(doc: ^k.Doc) -> k.Node_Id {
	// Every position of a 20 page control, to see the width stay the same.
	positions := make([dynamic]k.Node_Id, 0, 9, context.temp_allocator)
	for current in ([?]u32{1, 3, 4, 5, 10, 16, 17, 18, 20}) {
		append(
			&positions,
			k.div(
				doc,
				{class = "pagination-demo__row"},
				k.span(
					doc,
					{class = "pagination-demo__caption"},
					k.text(doc, k.doc_format(doc, "page %d", current)),
				),
				c.pagination(
					doc,
					{
						current = current,
						total = 20,
						href_prefix = PAGINATION_PREFIX,
						aria_label = k.doc_format(doc, "Page %d of 20", current),
					},
				),
			),
		)
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		append(
			&sizes,
			c.pagination(
				doc,
				{
					current = 5,
					total = 12,
					size = size,
					prev_next = true,
					href_prefix = PAGINATION_PREFIX,
					aria_label = k.doc_format(doc, "%v pagination", size),
				},
			),
		)
	}

	siblings := make([dynamic]k.Node_Id, 0, 4, context.temp_allocator)
	for count in ([?]u32{0, 1, 2, 3}) {
		append(
			&siblings,
			k.div(
				doc,
				{class = "pagination-demo__row"},
				k.span(
					doc,
					{class = "pagination-demo__caption"},
					k.text(doc, k.doc_format(doc, "siblings %d", count)),
				),
				c.pagination(
					doc,
					{
						current = 15,
						total = 40,
						siblings = count,
						href_prefix = PAGINATION_PREFIX,
						aria_label = k.doc_format(doc, "%d siblings", count),
					},
				),
			),
		)
	}

	column := proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
		return doc_list(
			doc,
			{class = "doc-demo__list--column", style = "align-items: flex-start"},
			..children,
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		pagination_section(
			doc,
			"Moving through 20 pages",
			"Every control below shows 7 entries. Near the start there is a gap before the last page, in the middle a gap on both sides, near the end a gap after the first. A gap never hides a single page.",
			column(doc, ..positions[:]),
		),
		pagination_section(
			doc,
			"Previous and next",
			"prev_next adds the two links. At either end the unavailable one is a disabled span, not a link. Labels can be changed.",
			column(
				doc,
				c.pagination(
					doc,
					{
						current = 1,
						total = 8,
						prev_next = true,
						href_prefix = PAGINATION_PREFIX,
						aria_label = "First page",
					},
				),
				c.pagination(
					doc,
					{
						current = 4,
						total = 8,
						prev_next = true,
						href_prefix = PAGINATION_PREFIX,
						aria_label = "Middle page",
					},
				),
				c.pagination(
					doc,
					{
						current = 8,
						total = 8,
						prev_next = true,
						href_prefix = PAGINATION_PREFIX,
						aria_label = "Last page",
					},
				),
				c.pagination(
					doc,
					{
						current = 4,
						total = 8,
						prev_next = true,
						prev_label = "Back",
						next_label = "Forward",
						href_prefix = PAGINATION_PREFIX,
						aria_label = "Custom labels",
					},
				),
			),
		),
		pagination_section(
			doc,
			"Size",
			"The shared Size enum: button height and text.",
			column(doc, ..sizes[:]),
		),
		pagination_section(
			doc,
			"Siblings",
			"How many pages show on each side of the current one. Each setting has its own fixed width: 2 * siblings + 5 entries.",
			column(doc, ..siblings[:]),
		),
		pagination_section(
			doc,
			"Few pages, and none",
			"With 5 pages or fewer there is no gap. With one page or none the control renders nothing, so there is nothing to check at the call site.",
			column(
				doc,
				c.pagination(
					doc,
					{
						current = 2,
						total = 5,
						href_prefix = PAGINATION_PREFIX,
						aria_label = "Five pages",
					},
				),
				c.pagination(
					doc,
					{
						current = 1,
						total = 1,
						href_prefix = PAGINATION_PREFIX,
						aria_label = "One page",
					},
				),
				k.p(
					doc,
					{class = "demo__note"},
					k.text(doc, "The control for one page is above this line, and is empty."),
				),
			),
		),
	)
}
