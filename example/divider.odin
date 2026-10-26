package main

import c "../component"
import k "kashmir:."

divider_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "A visual rule used to separate content. Renders as a horizontal "),
		doc_code(doc, "<hr>"),
		k.text(doc, " by default and as an inline vertical bar when "),
		doc_code(doc, "orientation = .vertical"),
		k.text(doc, " is set. Carries "),
		doc_code(doc, `role="separator"`),
		k.text(doc, " and the matching "),
		doc_code(doc, "aria-orientation"),
		k.text(doc, " automatically."),
	)
}

// A paragraph with no margin, for blocks that are laid out by their parent.
divider_block :: proc(doc: ^k.Doc, class, text: string) -> k.Node_Id {
	return k.div(doc, {class = class}, k.text(doc, text))
}

divider_section :: proc(doc: ^k.Doc, title, body: string) -> k.Node_Id {
	return k.div(
		doc,
		{class = "divider-demo__section"},
		k.h4(doc, {class = "divider-demo__section-title"}, k.text(doc, title)),
		k.p(doc, {}, k.text(doc, body)),
	)
}

// A toolbar button that shows text.
divider_tool_text :: proc(doc: ^k.Doc, label, aria_label, modifier: string) -> k.Node_Id {
	return k.button(
		doc,
		{
			class = k.doc_format(doc, "divider-demo__tool %s", modifier),
			attributes = {k.attribute("aria-label", aria_label)},
		},
		k.text(doc, label),
	)
}

// A toolbar button that shows an icon.
divider_tool_icon :: proc(doc: ^k.Doc, name: c.Icon_Name, aria_label: string) -> k.Node_Id {
	return k.button(
		doc,
		{class = "divider-demo__tool", attributes = {k.attribute("aria-label", aria_label)}},
		c.icon(doc, {name = name, size = .small}),
	)
}

divider_matrix_row :: proc(
	doc: ^k.Doc,
	orientation_name: string,
	orientation: c.Divider_Orientation,
	usage: string,
) -> k.Node_Id {
	sample_class :=
		orientation == .horizontal ? "divider-matrix__sample divider-matrix__sample--column" : "divider-matrix__sample"
	return k.tr(
		doc,
		{},
		k.th(doc, {scope = .row}, k.text(doc, orientation_name)),
		k.td(
			doc,
			{},
			k.div(
				doc,
				{class = sample_class},
				divider_block(doc, "divider-matrix__chip", "A"),
				c.divider(doc, {orientation = orientation}),
				divider_block(doc, "divider-matrix__chip", "B"),
			),
		),
		k.td(doc, {}, k.text(doc, usage)),
	)
}

demo_divider :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},

		// 1. Hero
		doc_group(
			doc,
			"Hero — Card with Sections",
			doc_description(
				doc,
				k.text(
					doc,
					"A canonical real-world use: a single card split into labelled sections, with horizontal dividers separating each. The second section uses a labelled divider for an inline \"and\" feel.",
				),
			),
			doc_list(doc, {style = "max-width: 640px"}, c.card(doc, {header = k.text(doc, "Project Aurora")}, divider_section(
						doc,
						"Overview",
						"A short description of the project — what it is, who owns it, and the current status.",
					), c.divider(doc, {}), divider_section(doc, "Details", "Body content with finer detail — descriptions, metadata, supporting info."), c.divider(doc, {label = "and"}), divider_section(doc, "Actions", "Footer-adjacent actions and links would go here in a real card."))),
		),

		// 2. Basic horizontal
		doc_group(
			doc,
			"Basic — Horizontal",
			doc_description(
				doc,
				k.text(
					doc,
					"The simplest form — a thin horizontal rule between two stacked content blocks. Renders as ",
				),
				doc_code(doc, "<hr>"),
				k.text(doc, "."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 480px"},
				divider_block(doc, "divider-demo__content-block", "Preceding Content Block"),
				c.divider(doc, {}),
				divider_block(
					doc,
					"divider-demo__content-block divider-demo__content-block--muted",
					"Following Content Block",
				),
			),
		),

		// 3. Labelled
		doc_group(
			doc,
			"Labelled",
			doc_description(
				doc,
				k.text(doc, "Pass a "),
				doc_code(doc, "label"),
				k.text(
					doc,
					" string to render the divider with text in the middle. Common UX: \"Continue with Google\" / divider / email field, or an \"OR\" between alternatives.",
				),
			),
			doc_list(
				doc,
				{},
				k.div(
					doc,
					{class = "divider-demo__login"},
					c.button(doc, {shape = .outline}, k.text(doc, "Continue with Google")),
					c.divider(doc, {label = "Or continue with"}),
					c.input_email(
						doc,
						{placeholder = "Email Address", aria_label = "Email address"},
					),
					c.button(doc, {}, k.text(doc, "Sign In")),
				),
			),
		),

		// 4. Vertical
		doc_group(
			doc,
			"Vertical",
			doc_description(
				doc,
				k.text(doc, "Use "),
				doc_code(doc, "orientation = .vertical"),
				k.text(
					doc,
					" for inline controls inside a single row — toolbar groups, breadcrumb-like separators, and menu actions.",
				),
			),
			doc_list(
				doc,
				{},
				k.div(
					doc,
					{class = "divider-demo__toolbar"},
					divider_tool_text(doc, "B", "Format bold", "divider-demo__tool--bold"),
					divider_tool_text(doc, "I", "Format italic", "divider-demo__tool--italic"),
					divider_tool_text(
						doc,
						"U",
						"Format underline",
						"divider-demo__tool--underline",
					),
					c.divider(doc, {orientation = .vertical}),
					divider_tool_icon(doc, .text_align_left, "Alignment left"),
					divider_tool_icon(doc, .text_align_center, "Alignment center"),
				),
			),
		),

		// 5. Orientation matrix
		doc_group(
			doc,
			"Orientation Matrix",
			doc_description(
				doc,
				k.text(
					doc,
					"Two orientations. Pick based on the layout axis your content flows along.",
				),
			),
			k.div(
				doc,
				{class = "table-container"},
				k.div(
					doc,
					{class = "table-scroll"},
					k.table(
						doc,
						{
							class = "table",
							attributes = {k.attribute("aria-label", "Divider orientation matrix")},
						},
						k.thead(
							doc,
							{},
							k.tr(
								doc,
								{},
								k.th(doc, {scope = .col}, k.text(doc, "Orientation")),
								k.th(doc, {scope = .col}, k.text(doc, "Sample")),
								k.th(doc, {scope = .col}, k.text(doc, "When to use")),
							),
						),
						k.tbody(
							doc,
							{},
							divider_matrix_row(
								doc,
								"Horizontal",
								.horizontal,
								"Stacking sections in a card or sidebar, separating content blocks in modals.",
							),
							divider_matrix_row(
								doc,
								"Vertical",
								.vertical,
								"Toolbar separators, button groups, breadcrumb-like row markers.",
							),
						),
					),
				),
			),
		),

		// 6. Custom attributes
		doc_group(
			doc,
			"Custom Attributes",
			doc_description(
				doc,
				k.text(doc, "Pass any HTML attribute through "),
				doc_code(doc, "attributes"),
				k.text(doc, " — useful for testing hooks like "),
				doc_code(doc, "data-testid"),
				k.text(doc, "."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 480px"},
				divider_block(doc, "divider-demo__content-block", "Section A"),
				c.divider(
					doc,
					{
						id = "main-divider",
						attributes = {k.attribute("data-testid", "section-divider")},
					},
				),
				divider_block(
					doc,
					"divider-demo__content-block divider-demo__content-block--muted",
					"Section B",
				),
			),
		),
	)
}
