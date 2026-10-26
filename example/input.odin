package main

import c "../component"
import k "kashmir:."

input_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "One proc per kind of field: "),
		doc_code(doc, "input_email"),
		k.text(doc, ", "),
		doc_code(doc, "input_number"),
		k.text(doc, ", "),
		doc_code(doc, "input_date"),
		k.text(doc, " and so on. Each has its own props, so a "),
		doc_code(doc, "pattern"),
		k.text(
			doc,
			" on a number or a string where a date belongs does not compile. What a type cannot say (a date that is not a date, ",
		),
		doc_code(doc, "min"),
		k.text(doc, " above "),
		doc_code(doc, "max"),
		k.text(doc, ") asserts when the page is built."),
	)
}

// A row of inputs, each given room to breathe.
input_row :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(doc, {class = "input-demo__row"}, ..children)
}

// One proc: its API name as the heading, an optional one-line note, the demo rows, then a
// rule. A rule closes every section, the last one included.
input_section :: proc(doc: ^k.Doc, api, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, doc_code(doc, api)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

demo_input :: proc(doc: ^k.Doc) -> k.Node_Id {
	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		label := k.doc_format(doc, "%v", size)
		append(&sizes, c.input_text(doc, {size = size, placeholder = label, aria_label = label}))
	}

	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		label := k.doc_format(doc, "%v", radius)
		append(
			&radii,
			c.input_text(doc, {radius = radius, placeholder = label, aria_label = label}),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		input_section(
			doc,
			"input_text",
			"Size, radius and state are shared by every kind, so they are shown once, here.",
			input_row(
				doc,
				c.input_text(doc, {placeholder = "Text", aria_label = "Text"}),
				c.input_text(doc, {value = "Typed text", aria_label = "With a value"}),
				c.input_text(
					doc,
					{
						name = "code",
						pattern = "[A-Z]{3}-[0-9]{3}",
						max_length = 7,
						placeholder = "ABC-123",
						aria_label = "Code like ABC-123",
					},
				),
			),
			input_row(doc, ..sizes[:]),
			input_row(doc, ..radii[:]),
			input_row(
				doc,
				c.input_text(doc, {value = "Normal", aria_label = "Normal"}),
				c.input_text(
					doc,
					{
						value = "Not valid",
						error = true,
						aria_label = "With error",
						aria_described_by = "input-error-hint",
					},
				),
				c.input_text(doc, {value = "Disabled", disabled = true, aria_label = "Disabled"}),
				c.input_text(
					doc,
					{value = "Read only", read_only = true, aria_label = "Read only"},
				),
				c.input_text(
					doc,
					{placeholder = "Required", required = true, aria_label = "Required"},
				),
			),
			k.p(
				doc,
				{id = "input-error-hint", class = "demo__note"},
				k.text(doc, "The error field points here with aria-describedby."),
			),
		),
		input_section(
			doc,
			"input_email",
			"The browser shows an email keyboard and checks the address.",
			input_row(
				doc,
				c.input_email(
					doc,
					{
						name = "email",
						autocomplete = .email,
						required = true,
						placeholder = "Email",
						aria_label = "Email",
					},
				),
				c.input_email(doc, {value = "ada@example.com", aria_label = "With a value"}),
			),
		),
		input_section(
			doc,
			"input_username",
			"Sets the username hint, and turns off auto-capitalising and spell-checking.",
			input_row(
				doc,
				c.input_username(doc, {placeholder = "Username", aria_label = "Username"}),
			),
		),
		input_section(
			doc,
			"input_tel",
			"The browser shows a telephone keypad.",
			input_row(
				doc,
				c.input_tel(
					doc,
					{placeholder = "+1 555 0100", autocomplete = .tel, aria_label = "Telephone"},
				),
				c.input_tel(
					doc,
					{
						pattern = "[0-9+ ]{7,15}",
						placeholder = "Digits only",
						aria_label = "Telephone, digits only",
					},
				),
			),
		),
		input_section(
			doc,
			"input_url",
			"The browser checks that the value is a URL.",
			input_row(
				doc,
				c.input_url(
					doc,
					{placeholder = "https://example.com", autocomplete = .url, aria_label = "URL"},
				),
				c.input_url(doc, {value = "https://odin-lang.org", aria_label = "With a value"}),
			),
		),
		input_section(
			doc,
			"input_search",
			"",
			input_row(
				doc,
				c.input_search(doc, {placeholder = "Search", aria_label = "Search"}),
				c.input_search(doc, {value = "components", aria_label = "With a value"}),
			),
		),
		input_section(
			doc,
			"input_password",
			"There is no value field: a password never goes in the page.",
			input_row(
				doc,
				c.input_password(
					doc,
					{
						name = "pw",
						autocomplete = .new,
						min_length = 8,
						placeholder = "New password (8+)",
						aria_label = "New password",
					},
				),
				c.input_password(
					doc,
					{autocomplete = .current, placeholder = "Password", aria_label = "Password"},
				),
			),
		),
		input_section(
			doc,
			"input_number",
			"min, max and step are numbers. Try 150 in the first field.",
			input_row(
				doc,
				c.input_number(
					doc,
					{
						name = "age",
						min = 0.0,
						max = 120.0,
						step = 1.0,
						value = 30.0,
						aria_label = "Age, 0 to 120",
					},
				),
				c.input_number(
					doc,
					{
						name = "price",
						min = 0.0,
						step = 0.25,
						value = 9.5,
						aria_label = "Price in quarters",
					},
				),
				c.input_number(doc, {placeholder = "0", aria_label = "Number"}),
			),
		),
		input_section(
			doc,
			"input_range",
			"A slider always has a value, so it has no required and no placeholder.",
			input_row(
				doc,
				c.input_range(
					doc,
					{name = "volume", min = 0.0, max = 100.0, value = 40.0, aria_label = "Volume"},
				),
				c.input_range(
					doc,
					{name = "big", size = .large, value = 70.0, aria_label = "Large slider"},
				),
				c.input_range(
					doc,
					{name = "err", error = true, value = 20.0, aria_label = "Slider with error"},
				),
				c.input_range(
					doc,
					{name = "off", disabled = true, value = 60.0, aria_label = "Disabled slider"},
				),
			),
		),
		input_section(
			doc,
			"input_date",
			"The value and the bounds are Input_Date. Try a date in 2025.",
			input_row(
				doc,
				c.input_date(
					doc,
					{
						name = "due",
						min = c.Input_Date{2026, 1, 1},
						max = c.Input_Date{2026, 12, 31},
						value = c.Input_Date{2026, 6, 15},
						aria_label = "Due date in 2026",
					},
				),
				c.input_date(doc, {aria_label = "Date"}),
			),
		),
		input_section(
			doc,
			"input_datetime",
			"A date and a time with no timezone. The value is Input_Datetime.",
			input_row(
				doc,
				c.input_datetime(
					doc,
					{
						name = "meeting",
						min = c.Input_Datetime{{2026, 1, 1}, 0, 0},
						max = c.Input_Datetime{{2026, 12, 31}, 23, 59},
						value = c.Input_Datetime{{2026, 6, 15}, 14, 30},
						aria_label = "Meeting time in 2026",
					},
				),
				c.input_datetime(doc, {aria_label = "Date and time"}),
			),
		),
		input_section(
			doc,
			"input_time",
			"A min after the max is an overnight range, which the browser accepts.",
			input_row(
				doc,
				c.input_time(
					doc,
					{
						name = "open",
						value = c.Input_Time{9, 30},
						min = c.Input_Time{8, 0},
						max = c.Input_Time{18, 0},
						step = 900,
						aria_label = "Opening time, 8:00 to 18:00",
					},
				),
				c.input_time(
					doc,
					{
						name = "night",
						min = c.Input_Time{22, 0},
						max = c.Input_Time{6, 0},
						value = c.Input_Time{23, 0},
						aria_label = "Night shift, 22:00 to 06:00",
					},
				),
			),
		),
		input_section(
			doc,
			"input_month",
			"",
			input_row(
				doc,
				c.input_month(
					doc,
					{
						name = "month",
						value = c.Input_Month{2026, 3},
						min = c.Input_Month{2026, 1},
						max = c.Input_Month{2026, 12},
						aria_label = "Month in 2026",
					},
				),
				c.input_month(doc, {aria_label = "Month"}),
			),
		),
		input_section(
			doc,
			"input_week",
			"Checked against the ISO calendar: 2026 has 53 weeks, 2027 has 52.",
			input_row(
				doc,
				c.input_week(
					doc,
					{name = "week", value = c.Input_Week{2026, 53}, aria_label = "Week"},
				),
				c.input_week(doc, {aria_label = "Week, empty"}),
			),
		),
		input_section(
			doc,
			"input_color",
			"The value is Input_Color, three bytes, so it can not be malformed.",
			input_row(
				doc,
				c.input_color(
					doc,
					{
						name = "accent",
						value = c.Input_Color{37, 99, 235},
						aria_label = "Accent colour",
					},
				),
				c.input_color(
					doc,
					{
						name = "c-lg",
						size = .large,
						radius = .pilled,
						value = c.Input_Color{239, 68, 68},
						aria_label = "Large pilled colour",
					},
				),
				c.input_color(
					doc,
					{
						name = "c-sm",
						size = .small,
						radius = .none,
						value = c.Input_Color{16, 185, 129},
						aria_label = "Small square colour",
					},
				),
			),
		),
		input_section(
			doc,
			"input_file",
			"accept is a plain string, and getting it right is the caller's job.",
			input_row(
				doc,
				c.input_file(doc, {name = "one", accept = "image/*", aria_label = "One image"}),
				c.input_file(
					doc,
					{
						name = "many",
						multiple = true,
						accept = ".pdf,.docx",
						aria_label = "Several documents",
						size = .large,
					},
				),
				c.input_file(doc, {name = "err", error = true, aria_label = "File with error"}),
			),
		),
		input_section(
			doc,
			"input_hidden",
			"Draws nothing. Submit the form and the address bar shows the hidden value going along with the visible one.",
			input_row(
				doc,
				k.form(
					doc,
					{
						method = .get,
						style = "display: flex; gap: var(--spacing-3); align-items: center; width: 100%",
					},
					c.input_hidden(doc, {name = "csrf", value = "a1b2c3"}),
					c.input_text(
						doc,
						{
							name = "q",
							placeholder = "Type, then submit",
							aria_label = "Visible field",
						},
					),
					c.button(doc, {type = .submit}, k.text(doc, "Submit")),
				),
			),
		),
	)
}
