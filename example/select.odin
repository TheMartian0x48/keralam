package main

import c "../component"
import k "kashmir:."

select_countries :: [?]c.Input_Select_Option {
	{"us", "United States", false},
	{"uk", "United Kingdom", false},
	{"in", "India", false},
	{"jp", "Japan", false},
}

select_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "input_select"),
		k.text(doc, " is a dropdown choice on the native "),
		doc_code(doc, "<select>"),
		k.text(
			doc,
			", so the browser keeps its picker, its mobile wheel and its keyboard handling. It is an input: the size, radius, error and disabled styles are the same as ",
		),
		doc_code(doc, "input_text"),
		k.text(doc, ". The "),
		doc_code(doc, "value"),
		k.text(doc, " picks the selected option, so two selected options can not be written."),
	)
}

// A block of the select page: the API name, a note, the demos, then a rule.
select_section :: proc(doc: ^k.Doc, title, note: string, rows: ..k.Node_Id) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(rows) + 3, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	if note != "" do append(&children, doc_description(doc, k.text(doc, note)))
	append(&children, ..rows)
	append(&children, c.divider(doc, {}))
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

select_column :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return doc_list(
		doc,
		{class = "doc-demo__list--column", style = "max-width: 24rem; align-items: stretch"},
		..children,
	)
}

demo_select :: proc(doc: ^k.Doc) -> k.Node_Id {
	countries := select_countries
	with_disabled := [?]c.Input_Select_Option {
		{"a", "Available", false},
		{"b", "Sold out", true},
		{"c", "Available too", false},
	}
	groups := [?]c.Input_Select_Group {
		{
			"Europe",
			{{"uk", "United Kingdom", false}, {"fr", "France", false}, {"de", "Germany", false}},
			false,
		},
		{"Asia", {{"in", "India", false}, {"jp", "Japan", false}}, false},
		{"Closed", {{"x", "Not available", false}}, true},
	}

	sizes := make([dynamic]k.Node_Id, 0, len(c.Size), context.temp_allocator)
	for size in c.Size {
		label := k.doc_format(doc, "%v", size)
		append(
			&sizes,
			c.input_select(
				doc,
				{size = size, placeholder = label, options = countries[:], aria_label = label},
			),
		)
	}
	radii := make([dynamic]k.Node_Id, 0, len(c.Radius), context.temp_allocator)
	for radius in c.Radius {
		label := k.doc_format(doc, "%v", radius)
		append(
			&radii,
			c.input_select(
				doc,
				{radius = radius, placeholder = label, options = countries[:], aria_label = label},
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		select_section(
			doc,
			"Basic",
			"A select with no placeholder always has an option selected, so it always submits a value.",
			select_column(
				doc,
				c.input_select(
					doc,
					{name = "plain", options = countries[:], aria_label = "Country"},
				),
				c.input_select(
					doc,
					{
						name = "chosen",
						value = "in",
						options = countries[:],
						aria_label = "Country, India chosen",
					},
				),
			),
		),
		select_section(
			doc,
			"Placeholder",
			"The prompt is an empty, disabled option, shown muted until a choice is made. An empty value selects it.",
			select_column(
				doc,
				c.input_select(
					doc,
					{
						name = "prompt",
						placeholder = "Choose a country",
						options = countries[:],
						aria_label = "Country",
					},
				),
				c.input_select(
					doc,
					{
						name = "prompt-chosen",
						placeholder = "Choose a country",
						value = "jp",
						options = countries[:],
						aria_label = "Country, Japan chosen",
					},
				),
			),
		),
		select_section(
			doc,
			"Groups",
			"Titled sets of options. A whole group can be disabled. Give groups or options, not both.",
			select_column(
				doc,
				c.input_select(
					doc,
					{
						name = "grouped",
						placeholder = "Choose a country",
						groups = groups[:],
						aria_label = "Country, grouped",
					},
				),
			),
		),
		select_section(
			doc,
			"Size and radius",
			"The shared Size and Radius enums, as on input_text.",
			select_column(doc, ..sizes[:]),
			select_column(doc, ..radii[:]),
		),
		select_section(
			doc,
			"State",
			"A disabled option is listed but can not be picked. Making it the value asserts: it would look chosen and the form would drop it.",
			select_column(
				doc,
				c.input_select(
					doc,
					{
						name = "stock",
						value = "a",
						options = with_disabled[:],
						aria_label = "Stock, with a sold-out option",
					},
				),
				c.input_select(
					doc,
					{
						placeholder = "With an error",
						error = true,
						aria_described_by = "select-error-hint",
						options = countries[:],
						aria_label = "With an error",
					},
				),
				k.p(
					doc,
					{id = "select-error-hint", class = "demo__note"},
					k.text(doc, "The error select points here with aria-describedby."),
				),
				c.input_select(
					doc,
					{
						placeholder = "Disabled",
						disabled = true,
						options = countries[:],
						aria_label = "Disabled",
					},
				),
			),
		),
		select_section(
			doc,
			"In a form",
			"required needs a placeholder, so there is an unchosen state to leave. Submit without choosing and the browser stops the form.",
			select_column(
				doc,
				k.form(
					doc,
					{
						method = .get,
						style = "display: flex; flex-direction: column; gap: var(--spacing-4); align-items: flex-start; width: 100%",
					},
					c.input_select(
						doc,
						{
							id = "form-country",
							name = "country",
							placeholder = "Choose a country",
							required = true,
							options = countries[:],
							aria_label = "Country",
						},
					),
					c.button(doc, {type = .submit}, k.text(doc, "Submit")),
				),
			),
		),
	)
}
