package component

import k "kashmir:."

// ---------- constants ----------

TABLE_COLUMNS_MAX :: 64
TABLE_ROWS_MAX :: 1000 // a bigger table is paginated, see pagination
TABLE_HEIGHT_REM_MIN :: u32(4)
TABLE_HEIGHT_REM_MAX :: u32(100)
TABLE_TEXT_BYTES_MAX :: 1024

// Where a column's text sits. Start is first so the zero value is the stock look. Use End for
// numbers so their digits line up.
Table_Align :: enum u8 {
	start,
	center,
	end,
}

@(private)
table_align_names := [Table_Align]string {
	.start  = "",
	.center = "center",
	.end    = "end",
}

// ---------- props ----------

// A column: its heading and where its cells' text sits.
Table_Column :: struct {
	title:        string, // required, unless header_label names an icon-only column
	align:        Table_Align,
	header_label: string, // the name when the heading is empty; read instead of the title
}

// A cell holds plain text or a node you built first (a badge, a link, a button), not both.
// A node must be built fresh for each cell: a node can have only one parent.
Table_Cell :: struct {
	text:    string, // escaped on render
	content: Maybe(k.Node_Id),
	align:   Maybe(Table_Align), // this cell only; nil = the column's
}

Table_Row :: struct {
	using base: k.Base, // id, class (appended after table__row), style, attributes
	cells:      []Table_Cell, // exactly as many as there are columns
	header:     bool, // the first cell is a row header (<th scope="row">)
}

// A data table in a bordered, scrollable container.
//
//   table(doc, {
//       caption = "Team",
//       columns = {{title = "Name"}, {title = "Age", align = .end}},
//       rows = {{cells = {{text = "Ada"}, {text = "36"}}}},
//   })
//
// The headings and the rows are data, not free-form children: every heading gets
// scope="col", a row header gets scope="row", and a row cannot have the wrong number of
// cells. The table needs a name, shown as a visible caption or given as aria_label. Zero
// rows shows empty_text across the table, so it does not collapse to a bare header.
//
// A scrolling container can only be scrolled with a keyboard if it can take focus, so one
// that can scroll is focusable and labelled (role="region"). Sorting, selecting and resizing
// columns are not part of this component (see task.md).
//
// Asserts: 1 to TABLE_COLUMNS_MAX columns and at most TABLE_ROWS_MAX rows; a caption or an
// aria_label; every heading has a title or a header_label; every row has one cell per column;
// a cell has text or content, not both; sticky_header needs max_height, which is TABLE_HEIGHT_REM_MIN
// to TABLE_HEIGHT_REM_MAX rem.
Table_Props :: struct {
	using base:    k.Base, // id, class (appended after the generated ones), style, attributes: on the <table>
	columns:       []Table_Column,
	rows:          []Table_Row,
	caption:       string, // a visible summary above the table
	aria_label:    string, // the name when there is no caption
	empty_text:    string, // shown when there are no rows; default "No data"
	size:          Size, // see component.odin: the cell padding and text
	striped:       bool, // alternate row backgrounds
	hover:         bool, // highlight the row under the pointer
	max_height:    Maybe(u32), // in rem; the table scrolls past this
	sticky_header: bool, // pin the headings while the body scrolls; needs max_height
}

// ---------- procs ----------

// Composition order: table table--{size} [table--striped] [table--hover] [class]
table :: proc(doc: ^k.Doc, props: Table_Props) -> k.Node_Id {
	columns_count := len(props.columns)
	rows_count := len(props.rows)
	assert(columns_count >= 1, "table needs at least one column")
	assert(columns_count <= TABLE_COLUMNS_MAX, "table columns exceeds TABLE_COLUMNS_MAX")
	assert(rows_count <= TABLE_ROWS_MAX, "table rows exceeds TABLE_ROWS_MAX")
	assert(props.caption != "" || props.aria_label != "", "table needs a caption or an aria_label")
	assert(len(props.caption) <= TABLE_TEXT_BYTES_MAX, "table caption exceeds TABLE_TEXT_BYTES_MAX")
	assert(
		!props.sticky_header || props.max_height != nil,
		"table sticky_header needs max_height, or there is nothing to scroll past",
	)
	height, scrolls := props.max_height.?
	assert(
		!scrolls || (height >= TABLE_HEIGHT_REM_MIN && height <= TABLE_HEIGHT_REM_MAX),
		"table max_height is outside TABLE_HEIGHT_REM_MIN to TABLE_HEIGHT_REM_MAX",
	)

	head_cells: [TABLE_COLUMNS_MAX]k.Node_Id
	for column, index in props.columns {
		assert(
			column.title != "" || column.header_label != "",
			"table column needs a title or a header_label",
		)
		head_cells[index] = k.th(
			doc,
			{
				base = {class = table_cell_class(doc, "table__heading", column.align)},
				scope = .col,
			},
			column.title != "" ? k.text(doc, column.title) : k.span(doc, {class = "visually-hidden"}, k.text(doc, column.header_label)),
		)
	}
	head := k.thead(doc, {}, k.tr(doc, {}, ..head_cells[:columns_count]))

	body_rows := make([dynamic]k.Node_Id, 0, max(rows_count, 1), context.temp_allocator)
	for row in props.rows {
		append(&body_rows, table_row(doc, row, props.columns))
	}
	if rows_count == 0 {
		empty := props.empty_text != "" ? props.empty_text : "No data"
		append(
			&body_rows,
			k.tr(
				doc,
				{class = "table__empty"},
				k.td(doc, {base = {class = "table__empty-cell"}, col_span = u32(columns_count)}, k.text(doc, empty)),
			),
		)
	}
	body := k.tbody(doc, {}, ..body_rows[:])

	caption := props.caption != "" ? k.caption(doc, {class = "table__caption"}, k.text(doc, props.caption)) : k.NODE_NONE

	// k.table copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(attributes_count + 1 <= ATTRIBUTES_MAX, "table attributes exceeds ATTRIBUTES_MAX")
	copy(attributes[:], props.attributes)
	if props.caption == "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}

	base := props.base
	base.class = table_class(doc, props)
	base.attributes = attributes[:attributes_count]
	table_node := k.table(doc, base, caption, head, body)

	scroll_attributes: [4]k.Attribute
	scroll_count := 0
	scroll_style := ""
	if scrolls {
		scroll_attributes[0] = k.role("region")
		scroll_attributes[1] = k.attribute("tabindex", "0")
		scroll_attributes[2] = k.attribute("aria-label", props.caption != "" ? props.caption : props.aria_label)
		scroll_count = 3
		scroll_style = k.doc_format(doc, "--table-max-height: %drem", height)
	}
	scroll_class := "table-scroll"
	if scrolls do scroll_class = "table-scroll table-scroll--vertical"
	if props.sticky_header do scroll_class = "table-scroll table-scroll--vertical table-scroll--sticky-header"
	scroll := k.div(
		doc,
		{class = scroll_class, style = scroll_style, attributes = scroll_attributes[:scroll_count]},
		table_node,
	)
	return k.div(doc, {class = "table-container"}, scroll)
}

@(private)
table_row :: proc(doc: ^k.Doc, row: Table_Row, columns: []Table_Column) -> k.Node_Id {
	assert(
		len(row.cells) == len(columns),
		"table row has a different number of cells than the table has columns",
	)

	cells: [TABLE_COLUMNS_MAX]k.Node_Id
	for cell, index in row.cells {
		content, has_content := cell.content.?
		assert(!(cell.text != "" && has_content), "table cell has both text and content")
		assert(len(cell.text) <= TABLE_TEXT_BYTES_MAX, "table cell text exceeds TABLE_TEXT_BYTES_MAX")
		if !has_content do content = k.text(doc, cell.text)

		align := cell.align.? or_else columns[index].align
		class := table_cell_class(doc, "table__cell", align)
		if row.header && index == 0 {
			cells[index] = k.th(
				doc,
				{base = {class = table_cell_class(doc, "table__row-heading", align)}, scope = .row},
				content,
			)
		} else {
			cells[index] = k.td(doc, {base = {class = class}}, content)
		}
	}

	base := row.base
	base.class = row.class != "" ? k.doc_format(doc, "table__row %s", row.class) : "table__row"
	return k.tr(doc, base, ..cells[:len(row.cells)])
}

@(private)
table_cell_class :: proc(doc: ^k.Doc, block: string, align: Table_Align) -> string {
	if align == .start do return block
	return k.doc_format(doc, "%s %s--%s", block, block, table_align_names[align])
}

@(private)
table_class :: proc(doc: ^k.Doc, props: Table_Props) -> string {
	striped_class := props.striped ? " table--striped" : ""
	hover_class := props.hover ? " table--hover" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"table table--%s%s%s%s%s",
		size_names[props.size],
		striped_class,
		hover_class,
		separator,
		props.class,
	)
}
