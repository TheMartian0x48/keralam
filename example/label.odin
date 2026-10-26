package main

import c "../component"
import k "kashmir:."

label_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "The visible name of a form control. Name the control with "),
		doc_code(doc, "for_"),
		k.text(
			doc,
			", or put the control inside the label; either way a click on the label focuses it, and assistive technology reads the label as the control's name.",
		),
	)
}

demo_label :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		doc_group(
			doc,
			"For an id",
			doc_description(
				doc,
				doc_code(doc, "for_"),
				k.text(doc, " holds the control's id. Click the label and the field takes focus."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 24rem"},
				c.label(doc, {for_ = "label-username"}, k.text(doc, "Username")),
				c.input_username(doc, {id = "label-username", placeholder = "ada"}),
			),
		),
		doc_group(
			doc,
			"Required",
			doc_description(
				doc,
				doc_code(doc, "required"),
				k.text(doc, " draws a "),
				doc_code(doc, "*"),
				k.text(
					doc,
					" for sighted users and hides it from screen readers. It does not make the field required: set ",
				),
				doc_code(doc, "required"),
				k.text(doc, " on the input as well."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 24rem"},
				c.label(doc, {for_ = "label-email", required = true}, k.text(doc, "Email")),
				c.input_email(
					doc,
					{id = "label-email", required = true, placeholder = "ada@example.com"},
				),
			),
		),
		doc_group(
			doc,
			"Disabled",
			doc_description(
				doc,
				k.text(doc, "Mute the label to match a disabled field. "),
				doc_code(doc, "required"),
				k.text(doc, " and "),
				doc_code(doc, "disabled"),
				k.text(doc, " together assert."),
			),
			doc_list(
				doc,
				{class = "doc-demo__list--column", style = "max-width: 24rem"},
				c.label(doc, {for_ = "label-locked", disabled = true}, k.text(doc, "Account id")),
				c.input_text(doc, {id = "label-locked", value = "A-1042", disabled = true}),
			),
		),
		doc_group(
			doc,
			"Around the control",
			doc_description(
				doc,
				k.text(doc, "Put the control inside the label and leave "),
				doc_code(doc, "for_"),
				k.text(doc, " out. The label's content is not limited to text."),
			),
			doc_list(
				doc,
				{style = "max-width: 24rem"},
				c.label(
					doc,
					{},
					k.text(doc, "Newsletter "),
					k.strong(doc, {}, k.text(doc, "(weekly)")),
					c.input_text(doc, {name = "newsletter", placeholder = "you@example.com"}),
				),
			),
		),
	)
}
