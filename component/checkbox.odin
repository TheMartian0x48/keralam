package component

import k "kashmir:."

// ---------- constants ----------

CHECKBOX_EXTRAS_MAX :: 5 // aria-invalid, aria-label, aria-describedby, data-indeterminate, target

// ---------- props ----------

// A custom-styled checkbox: a visually hidden native input for forms and
// accessibility, with a drawn control next to it.
//
//   checkbox(doc, {name = "terms", label = "I agree to the terms", size = .large})
//
// Size is the shared Size enum: Small 16px, Medium 20px (default), Large 24px box.
//
// As in the Go version, id and attributes go on the input, so a <label for> or a
// script elsewhere finds it, and class goes on the wrapping label.
//
// Indeterminate (the "select all" dash) is a DOM property with no HTML attribute,
// so it needs the keralam-checkbox controller from keralam.js. The controller sets it
// on connect, and the browser clears it when the user clicks. Without JavaScript
// the checkbox renders as a plain one.
Checkbox_Props :: struct {
	using base:        k.Base,

	// form
	name:              string,
	value:             string, // submitted when checked
	label:             string, // text next to the box

	// appearance
	size:              Size, // see component.odin
	radius:            Radius, // see component.odin; rounds the box, Pilled makes it a circle

	// state
	checked:           bool,
	indeterminate:     bool,
	disabled:          bool,
	required:          bool,
	error:             bool, // sets aria-invalid and the error styling

	// accessibility
	aria_label:        string, // the accessible name when there is no visible label
	aria_described_by: string, // id of an element with more context, e.g. an error message
}

// ---------- procs ----------

// Composition order: checkbox checkbox--{size} [checkbox--{radius}] [checkbox--disabled] [checkbox--error] [class]
checkbox :: proc(doc: ^k.Doc, props: Checkbox_Props) -> k.Node_Id {
	// k.input copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + CHECKBOX_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"checkbox attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.attribute("data-keralam-checkbox-target", "input")
	attributes_count += 1
	if props.error {
		attributes[attributes_count] = k.attribute("aria-invalid", "true")
		attributes_count += 1
	}
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}
	if props.aria_described_by != "" {
		attributes[attributes_count] = k.attribute("aria-describedby", props.aria_described_by)
		attributes_count += 1
	}
	if props.indeterminate {
		attributes[attributes_count] = k.attribute("data-indeterminate", "true")
		attributes_count += 1
	}

	input_base := k.Base {
		id         = props.id,
		class      = "checkbox__input",
		attributes = attributes[:attributes_count],
	}
	input_node := k.input(
		doc,
		{
			base = input_base,
			type = .checkbox,
			name = props.name,
			value = props.value,
			checked = props.checked,
			disabled = props.disabled,
			required = props.required,
		},
	)

	control := k.div(
		doc,
		{class = "checkbox__control"},
		icon(doc, {class = "checkbox__icon checkbox__icon--check", name = .check, size = .small}),
		icon(
			doc,
			{class = "checkbox__icon checkbox__icon--indeterminate", name = .minus, size = .small},
		),
	)

	label_node :=
		props.label != "" ? k.span(doc, {class = "checkbox__label"}, k.text(doc, props.label)) : k.NODE_NONE

	// The controller is only needed to apply the indeterminate property.
	root_base := k.Base {
		class = checkbox_class(doc, props),
	}
	if props.indeterminate {
		root_base.attributes = {k.attribute("data-controller", "keralam-checkbox")}
	}
	return k.label(doc, {base = root_base}, input_node, control, label_node)
}

@(private)
checkbox_class :: proc(doc: ^k.Doc, props: Checkbox_Props) -> string {
	radius_class :=
		props.radius == .default ? "" : k.doc_format(doc, " checkbox--%s", radius_names[props.radius])
	disabled_class := props.disabled ? " checkbox--disabled" : ""
	error_class := props.error ? " checkbox--error" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"checkbox checkbox--%s%s%s%s%s%s",
		size_names[props.size],
		radius_class,
		disabled_class,
		error_class,
		separator,
		props.class,
	)
}
