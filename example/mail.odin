package main

import c "../component"
import k "kashmir:."

demo_mail :: proc(doc: ^k.Doc) -> k.Node_Id {
	return k.div(
		doc,
		{},
		demo_section(
			doc,
			"Mailto link",
			c.mail(doc, {email = "support@example.com"}, k.text(doc, "Email support")),
		),
		demo_section(
			doc,
			"With rich content and label",
			c.mail(
				doc,
				{email = "hello@example.com", aria_label = "Send an email to hello@example.com"},
				k.strong(doc, {}, k.text(doc, "Need help?")),
				k.text(doc, " Email us."),
			),
		),
	)
}
