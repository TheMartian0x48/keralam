package main

import c "../component"
import k "kashmir:."

THEME_PATH :: "/theme"

// Whatever the controller offers; the value is the data-theme name, "system" means none.
theme_names := [?]c.Input_Select_Option {
	{value = "system", label = "System"},
	{value = "light", label = "Light"},
	{value = "dark", label = "Dark"},
	{value = "gruvbox-dark", label = "Gruvbox dark"},
	{value = "gruvbox-light", label = "Gruvbox light"},
	{value = "nord", label = "Nord"},
	{value = "solarized-dark", label = "Solarized dark"},
	{value = "dracula", label = "Dracula"},
}

// Every colour token, in groups, so a theme can be judged at a glance.
Theme_Group :: struct {
	title:  string,
	tokens: []string,
}

theme_groups := [?]Theme_Group {
	{
		"Background",
		{
			"--color-bg",
			"--color-bg-primary",
			"--color-bg-secondary",
			"--color-bg-tertiary",
			"--color-bg-overlay",
		},
	},
	{
		"Text",
		{
			"--color-text",
			"--color-text-primary",
			"--color-text-secondary",
			"--color-text-muted",
			"--color-text-disabled",
			"--color-text-inverse",
		},
	},
	{"Border", {"--color-border", "--color-border-dark", "--color-border-light"}},
	{
		"Primary",
		{
			"--color-primary",
			"--color-primary-dark",
			"--color-primary-darker",
			"--color-primary-light",
			"--color-primary-subtle-bg",
			"--color-primary-subtle-text",
		},
	},
	{"Secondary", {"--color-secondary", "--color-secondary-dark", "--color-secondary-light"}},
	{"Success", {"--color-success", "--color-success-subtle-bg", "--color-success-subtle-text"}},
	{"Warning", {"--color-warning", "--color-warning-text", "--color-warning-subtle-bg"}},
	{
		"Danger",
		{
			"--color-danger",
			"--color-danger-dark",
			"--color-danger-darker",
			"--color-danger-subtle-bg",
			"--color-danger-subtle-text",
		},
	},
	{"Info", {"--color-info", "--color-info-subtle-bg", "--color-info-subtle-text"}},
}

// The picker in the sidebar. keralam-theme saves the choice and sets data-theme.
theme_picker :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{class = "sidebar__theme", attributes = {k.attribute("data-controller", "keralam-theme")}},
		c.label(doc, {for_ = "theme-select"}, k.text(doc, "Theme")),
		c.input_select(
			doc,
			{
				common = {
					base = {
						id = "theme-select",
						attributes = {k.attribute("data-action", "change->keralam-theme#choose")},
					},
				},
				options = theme_names[:],
			},
		),
	)
}

theme_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(
			doc,
			"Every colour a component uses is one of these tokens, so a theme is a block of overrides and no component CSS changes. Pick a theme in the sidebar and these swatches, and every other page, follow it. The built-in light and dark are in keralam.css; the named themes are in keralam-themes.css, which a page opts into.",
		),
	)
}

demo_theme :: proc(doc: ^k.Doc) -> k.Node_Id {
	groups := make([dynamic]k.Node_Id, 0, len(theme_groups), context.temp_allocator)
	for group in theme_groups {
		swatches := make([dynamic]k.Node_Id, 0, len(group.tokens), context.temp_allocator)
		for token in group.tokens {
			append(
				&swatches,
				k.div(
					doc,
					{class = "swatch"},
					k.span(
						doc,
						{
							class = "swatch__colour",
							style = k.doc_format(doc, "background-color: var(%s)", token),
							attributes = {k.attribute("data-token", token)},
						},
					),
					k.code(doc, {class = "swatch__name"}, k.text(doc, token)),
				),
			)
		}
		append(
			&groups,
			k.div(
				doc,
				{class = "doc-demo__group"},
				k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, group.title)),
				k.div(doc, {class = "swatches"}, ..swatches[:]),
				c.divider(doc, {}),
			),
		)
	}

	components := k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, "Components in this theme")),
		doc_list(
			doc,
			{},
			c.button(doc, {}, k.text(doc, "Primary")),
			c.button(doc, {variant = .danger}, k.text(doc, "Danger")),
			c.button(doc, {shape = .outline}, k.text(doc, "Outline")),
			c.badge(doc, {variant = .success}, k.text(doc, "Success")),
			c.badge(doc, {variant = .warning}, k.text(doc, "Warning")),
			c.input_text(
				doc,
				{name = "sample", placeholder = "A text field", aria_label = "Sample"},
			),
		),
		c.alert(
			doc,
			{variant = .info, shape = .soft, title = "Info"},
			k.text(doc, "An alert in this theme."),
		),
		c.divider(doc, {}),
	)

	children := make([dynamic]k.Node_Id, 0, len(groups) + 1, context.temp_allocator)
	append(&children, components)
	append(&children, ..groups[:])
	return k.div(doc, {class = "doc-demo__preview-inner"}, ..children[:])
}
