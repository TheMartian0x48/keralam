package main

import c "../component"
import k "kashmir:."

countries := [?]c.Autocomplete_Option {
	{"us", "United States"},
	{"uk", "United Kingdom"},
	{"in", "India"},
	{"de", "Germany"},
	{"fr", "France"},
	{"jp", "Japan"},
	{"br", "Brazil"},
}

demo_autocomplete :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{},
		demo_section(
			doc,
			"Basic",
			c.autocomplete(
				doc,
				{name = "basic", placeholder = "Search countries", options = countries[:]},
			),
		),
		demo_section(
			doc,
			"Preselected (submits the value, shows the label)",
			c.autocomplete(
				doc,
				{name = "preselected", label = "Country", value = "in", options = countries[:]},
			),
		),
		demo_section(
			doc,
			"Error",
			c.autocomplete(
				doc,
				{
					name = "error",
					placeholder = "Search countries",
					error = true,
					options = countries[:],
				},
			),
		),
		demo_section(
			doc,
			"Disabled",
			c.autocomplete(
				doc,
				{
					name = "disabled",
					placeholder = "Search countries",
					value = "fr",
					disabled = true,
					options = countries[:],
				},
			),
		),
		demo_section(
			doc,
			"In a form: the URL shows what was submitted",
			k.form(
				doc,
				{style = "width: 100%", method = .get},
				c.autocomplete(
					doc,
					{
						id = "form-country",
						name = "country",
						label = "Country",
						required = true,
						options = countries[:],
					},
				),
				c.button(
					doc,
					{type = .submit, attributes = {k.attribute("id", "form-submit")}},
					k.text(doc, "Submit"),
				),
			),
		),
	)
}
