package component

import "core:strings"
import k "kashmir:."

// ---------- constants ----------

LABEL_CHILDREN_MAX :: 64

// ---------- props ----------

// A form label: the visible name of a control, and a larger target to click or tap.
//
//   label(doc, {for_ = "username", required = true}, k.text(doc, "Username"))
//
// A label is tied to its control in one of two ways: for_ names the control's id, or the
// control sits inside the label's children. Either gives the control an accessible name
// and makes a click on the label focus it. for_ is left out when the control is a child.
//
// required draws a "*" for sighted users. It is hidden from assistive technology, so the
// control itself must also be required (input_text(doc, {required = true})); the label
// does not make anything required.
Label_Props :: struct {
	using base: k.Base, // id, class (appended after the generated classes), style, attributes
	for_:       string, // id of the control this names; `for` is a keyword in Odin
	required:   bool, // draw a "*" after the text
	disabled:   bool, // muted: use it when the control is disabled
}

// ---------- procs ----------

// Composition order: label [label--disabled] [class]
label :: proc(doc: ^k.Doc, props: Label_Props, children: ..k.Node_Id) -> k.Node_Id {
	assert(len(children) <= LABEL_CHILDREN_MAX, "label children exceeds LABEL_CHILDREN_MAX")
	// An id can not contain whitespace, so such a `for` matches nothing and fails silently.
	assert(!strings.contains_any(props.for_, " \t\r\n\f"), "label for_ is not a valid id")
	assert(!(props.required && props.disabled), "label is both required and disabled")

	nodes: [LABEL_CHILDREN_MAX + 1]k.Node_Id
	copy(nodes[:], children)
	nodes_count := len(children)
	if props.required {
		nodes[nodes_count] = k.span(
			doc,
			{class = "label__required", attributes = {k.attribute("aria-hidden", "true")}},
			k.text(doc, "*"),
		)
		nodes_count += 1
	}

	base := props.base
	base.class = label_class(doc, props)
	return k.label(doc, {base = base, for_ = props.for_}, ..nodes[:nodes_count])
}

@(private)
label_class :: proc(doc: ^k.Doc, props: Label_Props) -> string {
	disabled_class := props.disabled ? " label--disabled" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(doc, "label%s%s%s", disabled_class, separator, props.class)
}
