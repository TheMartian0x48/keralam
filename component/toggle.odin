package component

import k "kashmir:."

// ---------- constants ----------

TOGGLE_EXTRAS_MAX :: 4 // role, aria-invalid, aria-label, aria-describedby

// ---------- props ----------

// An on/off switch for a setting that takes effect straight away. It is a native checkbox
// with role="switch", visually hidden, and a drawn track and thumb next to it.
//
//   input_toggle(doc, {name = "notifications", label = "Enable notifications", size = .large})
//
// It is a member of the input family because it submits like one (name=on when on, nothing
// when off, or `value` instead of "on"), and a checkbox for choosing among options is the
// checkbox component. Use a toggle for a single setting, a checkbox for agreeing or picking.
//
// As in checkbox, id and attributes go on the input, so a <label for> or a script finds
// it, and class goes on the wrapping label. The label always carries `for`: a generated
// id (tgl<N>, unique within the Doc) is used when you give none.
//
// Size is the shared Size enum.
Input_Toggle_Props :: struct {
	using base:        k.Base,

	// form
	name:              string,
	value:             string, // submitted when on; the browser sends "on" if empty
	label:             string, // text next to the switch

	// appearance
	size:              Size, // see component.odin

	// state
	checked:           bool, // starts on
	disabled:          bool,
	required:          bool, // must be on before the form submits
	error:             bool, // sets aria-invalid and the error styling

	// accessibility
	aria_label:        string, // the accessible name when there is no visible label
	aria_described_by: string, // id of an element with more context, e.g. an error message
}

// ---------- procs ----------

// Composition order: toggle toggle--{size} [toggle--disabled] [toggle--error] [class]
input_toggle :: proc(doc: ^k.Doc, props: Input_Toggle_Props) -> k.Node_Id {
	assert(props.label != "" || props.aria_label != "", "toggle needs a label or an aria_label")
	assert(!(props.required && props.disabled), "toggle is both required and disabled")

	// Unique within a page without global state: node counts only grow.
	toggle_id := props.id != "" ? props.id : k.doc_format(doc, "tgl%d", doc.nodes_count)

	// k.input copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + TOGGLE_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"toggle attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("switch")
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

	input_node := k.input(
		doc,
		{
			base = {
				id = toggle_id,
				class = "toggle__input",
				attributes = attributes[:attributes_count],
			},
			type = .checkbox,
			name = props.name,
			value = props.value,
			checked = props.checked,
			disabled = props.disabled,
			required = props.required,
		},
	)
	track := k.span(doc, {class = "toggle__track"}, k.span(doc, {class = "toggle__thumb"}))
	label_node :=
		props.label != "" ? k.span(doc, {class = "toggle__label"}, k.text(doc, props.label)) : k.NODE_NONE

	return k.label(
		doc,
		{base = {class = toggle_class(doc, props)}, for_ = toggle_id},
		input_node,
		track,
		label_node,
	)
}

@(private)
toggle_class :: proc(doc: ^k.Doc, props: Input_Toggle_Props) -> string {
	disabled_class := props.disabled ? " toggle--disabled" : ""
	error_class := props.error ? " toggle--error" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"toggle toggle--%s%s%s%s%s",
		size_names[props.size],
		disabled_class,
		error_class,
		separator,
		props.class,
	)
}
