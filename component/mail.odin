package component

import k "kashmir:."

// ---------- constants ----------

MAIL_EXTRAS_MAX :: 1 // aria-label

// ---------- props ----------

// A mailto link.
//
//   mail(doc, {email = "support@example.com"}, k.text(doc, "Email us"))
Mail_Props :: struct {
	using base: k.Base, // id, class (appended after "mail"), style, attributes
	email:      string, // the mailto target address
	aria_label: string, // hidden description for screen readers
}

// ---------- procs ----------

mail :: proc(doc: ^k.Doc, props: Mail_Props, children: ..k.Node_Id) -> k.Node_Id {
	assert(props.email != "", "mail needs an email address")

	// k.a copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + MAIL_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"mail attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}

	base := props.base
	base.class = props.class != "" ? k.doc_format(doc, "mail %s", props.class) : "mail"
	base.attributes = attributes[:attributes_count]

	// The address is escaped as an attribute value on render, so it cannot break out.
	return k.a(doc, {base = base, href = k.doc_format(doc, "mailto:%s", props.email)}, ..children)
}
