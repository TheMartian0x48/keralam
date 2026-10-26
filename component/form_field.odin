package component

import k "kashmir:."

// ---------- constants ----------

FORM_FIELD_EXTRAS_MAX :: 1
FORM_FIELD_WALK_MAX :: 4096 // nodes visited looking for the control's id

// ---------- props ----------

// What a control needs to be part of a field. form_field makes these and passes them to
// the control proc, so the label's `for`, the control's id and its aria-describedby are
// one set of values and can not disagree.
Form_Field_Wiring :: struct {
	id:                string, // give the control this id, so the label's `for` finds it
	aria_described_by: string, // the help or error element's id; "" when there is neither
	error:             bool, // an error message is showing: build the control with error = true
}

// A control and its label, helper text and error message, as one field.
//
//   email_control :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
//       return c.input_email(doc, {id = w.id, name = "email", error = w.error, aria_described_by = w.aria_described_by})
//   }
//   c.form_field(doc, {label = "Email", help = "We never share it", control = email_control})
//
// The control is a proc, not a node, because the wiring has to exist before the control is
// built: a node's children are built before the node, so a finished control could not be
// given the label's id afterwards. A proc can not capture variables, so a control that
// needs data reads it from somewhere the proc can reach.
//
// This is for controls that sit under a label: the text-like inputs, textarea, select,
// file, color, range, date and time kinds. Checkbox, radio, radio_group and the toggle
// carry their own label, so use them directly.
//
// For autocomplete, give the field's id to input_id, not id: a label can only name a form
// control, and the autocomplete's root is a <div>.
//
// Asserts: label and control are given; error and help are not both set (the CSS shows
// one); and the control must really use the id it was given (see form_field_find_id).
Form_Field_Props :: struct {
	using base: k.Base, // id (generated when empty), class, style, attributes: all on the wrapper
	label:      string, // the field's name; required, a field with no name is not accessible
	required:   bool, // draws a "*" on the label; the control's own required is separate
	help:       string, // helper text under the control
	error:      string, // the validation message; sets the invalid state
	control:    proc(doc: ^k.Doc, wiring: Form_Field_Wiring) -> k.Node_Id,
}

// ---------- procs ----------

// Composition order: form-field [form-field--error] [class]
form_field :: proc(doc: ^k.Doc, props: Form_Field_Props) -> k.Node_Id {
	assert(props.label != "", "form field needs a label")
	assert(props.control != nil, "form field needs a control")
	assert(!(props.error != "" && props.help != ""), "form field has both error and help")

	// Unique within a page without global state: node counts only grow.
	field_id := props.id != "" ? props.id : k.doc_format(doc, "ff%d", doc.nodes_count)
	control_id := k.doc_format(doc, "%s-control", field_id)
	message_id :=
		props.error != "" ? k.doc_format(doc, "%s-error", field_id) : k.doc_format(doc, "%s-help", field_id)
	has_message := props.error != "" || props.help != ""

	wiring := Form_Field_Wiring {
		id                = control_id,
		aria_described_by = has_message ? message_id : "",
		error             = props.error != "",
	}
	control := props.control(doc, wiring)
	assert(
		form_field_find_id(doc, control, control_id),
		"form field control does not use the id it was given (set id = wiring.id)",
	)

	message := k.NODE_NONE
	if props.error != "" {
		message = k.div(
			doc,
			{id = message_id, class = "form-field__error", attributes = {k.role("alert")}},
			icon(doc, {name = .warning, size = .small}),
			k.span(doc, {}, k.text(doc, props.error)),
		)
	} else if props.help != "" {
		message = k.div(
			doc,
			{id = message_id, class = "form-field__help"},
			k.text(doc, props.help),
		)
	}

	base := props.base
	base.id = field_id
	base.class = form_field_class(doc, props)
	return k.div(
		doc,
		base,
		label(
			doc,
			{class = "form-field__label", for_ = control_id, required = props.required},
			k.text(doc, props.label),
		),
		k.div(doc, {class = "form-field__control"}, control),
		message,
	)
}

// Whether `id` is on `root` or one of the nodes below it. A control may wrap its input
// (select puts it in a container, autocomplete in a control row), so the whole subtree is
// searched, depth first, with a fixed stack and a fixed visit limit.
@(private)
form_field_find_id :: proc(doc: ^k.Doc, root: k.Node_Id, id: string) -> bool {
	stack: [FORM_FIELD_WALK_MAX]k.Node_Id
	stack_count := 0
	stack[stack_count] = root
	stack_count += 1

	for _ in 0 ..< FORM_FIELD_WALK_MAX {
		if stack_count == 0 do return false
		stack_count -= 1
		current := stack[stack_count]
		if current == k.NODE_NONE do continue

		node := doc.nodes[current]
		if node.base.id == id do return true
		for child := node.first_child; child != k.NODE_NONE; child = doc.nodes[child].next {
			if stack_count == FORM_FIELD_WALK_MAX do return false
			stack[stack_count] = child
			stack_count += 1
		}
	}
	return false
}

@(private)
form_field_class :: proc(doc: ^k.Doc, props: Form_Field_Props) -> string {
	error_class := props.error != "" ? " form-field--error" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(doc, "form-field%s%s%s", error_class, separator, props.class)
}
