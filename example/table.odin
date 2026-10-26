package main

import c "../component"
import k "kashmir:."

table_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "table"),
		k.text(
			doc,
			" takes columns and rows as data, so every heading gets scope=\"col\", a row header gets scope=\"row\", and a row cannot have the wrong number of cells. It needs a caption or an aria_label. A table that can scroll is focusable, so a keyboard can scroll it. Sorting and selection are not part of it.",
		),
	)
}

table_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

table_team_columns :: [?]c.Table_Column {
	{title = "Name"},
	{title = "Role"},
	{title = "Age", align = .end},
}

// Rows are built with a fixed number of cells, in a fixed-size buffer: no allocation, no growth.
table_team_rows :: proc(doc: ^k.Doc, rows: ^[5]c.Table_Row, cells: ^[5][3]c.Table_Cell) -> []c.Table_Row {
	names := [5]string{"Ada Lovelace", "Grace Hopper", "Alan Turing", "Katherine Johnson", "Margaret Hamilton"}
	roles := [5]string{"Analyst", "Admiral", "Mathematician", "Physicist", "Engineer"}
	ages := [5]string{"36", "85", "41", "101", "88"}
	for index in 0 ..< 5 {
		cells[index] = {{text = names[index]}, {text = roles[index]}, {text = ages[index]}}
		rows[index] = {cells = cells[index][:]}
	}
	return rows[:]
}

demo_table :: proc(doc: ^k.Doc) -> k.Node_Id {
	columns := table_team_columns

	basic_rows: [5]c.Table_Row
	basic_cells: [5][3]c.Table_Cell
	striped_rows: [5]c.Table_Row
	striped_cells: [5][3]c.Table_Cell
	header_rows: [5]c.Table_Row
	header_cells: [5][3]c.Table_Cell
	scroll_rows: [5]c.Table_Row
	scroll_cells: [5][3]c.Table_Cell

	header_rows_slice := table_team_rows(doc, &header_rows, &header_cells)
	for &row in header_rows_slice do row.header = true

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	size_rows: [len(c.Size)][5]c.Table_Row
	size_cells: [len(c.Size)][5][3]c.Table_Cell
	for size, index in c.Size {
		append(
			&sizes,
			c.table(
				doc,
				{
					id = k.doc_format(doc, "table-size-%d", int(size)),
					caption = k.doc_format(doc, "%v", size),
					columns = columns[:],
					rows = table_team_rows(doc, &size_rows[index], &size_cells[index]),
					size = size,
				},
			),
		)
	}

	component_cells := [?]c.Table_Cell {
		{text = "Build"},
		{content = c.badge(doc, {variant = .success}, k.text(doc, "Passing"))},
		{content = c.link(doc, {href = "#log"}, k.text(doc, "View log"))},
	}
	other_cells := [?]c.Table_Cell {
		{text = "Deploy"},
		{content = c.badge(doc, {variant = .danger}, k.text(doc, "Failed"))},
		{content = c.link(doc, {href = "#log"}, k.text(doc, "View log"))},
	}
	component_rows := [?]c.Table_Row{{cells = component_cells[:]}, {cells = other_cells[:]}}
	component_columns := [?]c.Table_Column{{title = "Job"}, {title = "Status"}, {title = "Details", align = .center}}

	icon_columns := [?]c.Table_Column{{title = "Name"}, {header_label = "Actions", align = .end}}
	icon_cells_a := [?]c.Table_Cell{{text = "Report.pdf"}, {content = c.icon(doc, {name = .download_simple, size = .small})}}
	icon_rows := [?]c.Table_Row{{cells = icon_cells_a[:]}}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		table_section(
			doc,
			"Basic",
			"Headings are scope=\"col\". The caption names the table. Numbers are aligned on the end edge.",
			c.table(
				doc,
				{
					id = "table-basic",
					caption = "Team",
					columns = columns[:],
					rows = table_team_rows(doc, &basic_rows, &basic_cells),
				},
			),
		),
		table_section(
			doc,
			"Striped and hover",
			"Alternate rows and a highlight under the pointer.",
			c.table(
				doc,
				{
					id = "table-striped",
					caption = "Team",
					columns = columns[:],
					rows = table_team_rows(doc, &striped_rows, &striped_cells),
					striped = true,
					hover = true,
				},
			),
		),
		table_section(
			doc,
			"Row headers",
			"header = true on a row makes its first cell a row header, scope=\"row\".",
			c.table(
				doc,
				{id = "table-header", caption = "Team", columns = columns[:], rows = header_rows_slice},
			),
		),
		table_section(
			doc,
			"Size",
			"The shared Size enum sets the cell padding and the text.",
			k.div(
				doc,
				{style = "display: flex; flex-direction: column; gap: var(--spacing-6)"},
				..sizes[:],
			),
		),
		table_section(
			doc,
			"Cells with components",
			"A cell can hold a node: a badge, a link, a button. Build one per cell.",
			c.table(
				doc,
				{id = "table-components", aria_label = "Pipeline", columns = component_columns[:], rows = component_rows[:]},
			),
		),
		table_section(
			doc,
			"An icon-only column",
			"A column with no title needs header_label, which is read to a screen reader and not shown.",
			c.table(
				doc,
				{id = "table-icon", aria_label = "Downloads", columns = icon_columns[:], rows = icon_rows[:]},
			),
		),
		table_section(
			doc,
			"Scrolling with a sticky header",
			"max_height is in rem. The headings stay while the rows scroll, and Tab reaches the region so the arrow keys scroll it.",
			c.table(
				doc,
				{
					id = "table-scroll",
					caption = "Team",
					columns = columns[:],
					rows = table_team_rows(doc, &scroll_rows, &scroll_cells),
					max_height = u32(8),
					sticky_header = true,
				},
			),
		),
		table_section(
			doc,
			"Empty",
			"With no rows the table says so, instead of showing a bare header.",
			c.table(doc, {id = "table-empty", caption = "Team", columns = columns[:], empty_text = "Nobody here yet"}),
		),
	)
}
