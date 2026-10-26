package component

import k "kashmir:."

// ---------- enums ----------

// Which way a group lays out its options. Column is first so the zero value is a stack.
Radio_Direction :: enum u8 {
	column,
	row,
}

// ---------- constants ----------

RADIO_EXTRAS_MAX :: 3 // aria-invalid, aria-label, aria-describedby
RADIO_OPTIONS_MAX :: 64
RADIO_GROUP_EXTRAS_MAX :: 4 // role, aria-label, aria-describedby, aria-required

// ---------- props ----------

// A custom-styled radio: a visually hidden native input for forms and accessibility, with
// a drawn circle next to it. It is always a circle, so there is no radius.
//
//   radio(doc, {name = "plan", value = "pro", label = "Pro", size = .large})
//
// A radio only means something in a group, and a group is a relationship the browser
// builds from a shared name. For that use radio_group, which builds the fieldset and
// legend and checks the group is valid. A lone radio is for when you wire the group
// yourself.
//
// As in checkbox, id and attributes go on the input, so a <label for> or a script
// elsewhere finds it, and class goes on the wrapping label.
Radio_Props :: struct {
	using base:        k.Base,

	// form
	name:              string, // radios with the same name form a group
	value:             string, // submitted when this radio is selected
	label:             string, // text next to the circle

	// appearance
	size:              Size, // see component.odin: Small 16px, Medium 20px (default), Large 24px

	// state
	checked:           bool,
	disabled:          bool,
	required:          bool, // marks the whole group as mandatory
	error:             bool, // sets aria-invalid and the error styling

	// accessibility
	aria_label:        string, // the accessible name when there is no visible label
	aria_described_by: string, // id of an element with more context, e.g. an error message
}

// One choice in a radio_group.
Radio_Option :: struct {
	value:    string, // must not be empty, and must differ from every other option's
	label:    string, // must not be empty
	disabled: bool,
}

// A set of choices where exactly one can be selected: a <fieldset role="radiogroup">
// with a <legend>, which is what gives the group its accessible name.
//
//   radio_group(doc, {
//       name = "plan", legend = "Choose a plan", value = "pro",
//       options = {{"free", "Free", false}, {"pro", "Pro", false}, {"team", "Team", false}},
//   })
//
// The group's value picks which option is selected, so two selected options can not be
// written. These assert, because each is a group the browser would quietly mishandle:
//   name is not empty (a nameless group does not group and submits nothing)
//   at least two options (one option is a checkbox) and at most RADIO_OPTIONS_MAX
//   every option has a label and a value, and no two values are equal
//   value is empty or names one of the options
//   legend or aria_label is given, so the group has a name for assistive technology
//   required and disabled together
Radio_Group_Props :: struct {
	using base:        k.Base, // id, class (appended after the generated classes), style, attributes: all on the fieldset
	name:              string,
	legend:            string, // the question the group answers
	options:           []Radio_Option,
	value:             string, // the selected option's value; "" selects none

	// appearance
	direction:         Radio_Direction,
	size:              Size, // see component.odin; applies to every option

	// state
	disabled:          bool, // every option
	required:          bool, // the group needs a choice before the form submits
	error:             bool, // every option shows the error styling

	// accessibility
	aria_label:        string, // used when there is no visible legend
	aria_described_by: string, // id of an element with more context, e.g. an error message
}

// ---------- procs ----------

// Composition order: radio radio--{size} [radio--disabled] [radio--error] [class]
radio :: proc(doc: ^k.Doc, props: Radio_Props) -> k.Node_Id {
	assert(!(props.required && props.disabled), "radio is both required and disabled")

	// k.input copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + RADIO_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"radio attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

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
				id = props.id,
				class = "radio__input",
				attributes = attributes[:attributes_count],
			},
			type = .radio,
			name = props.name,
			value = props.value,
			checked = props.checked,
			disabled = props.disabled,
			required = props.required,
		},
	)
	control := k.div(doc, {class = "radio__control"}, k.span(doc, {class = "radio__circle"}))
	label_node :=
		props.label != "" ? k.span(doc, {class = "radio__label"}, k.text(doc, props.label)) : k.NODE_NONE

	return k.label(doc, {class = radio_class(doc, props)}, input_node, control, label_node)
}

radio_group :: proc(doc: ^k.Doc, props: Radio_Group_Props) -> k.Node_Id {
	option_count := len(props.options)
	assert(props.name != "", "radio group needs a name")
	assert(option_count >= 2, "radio group needs at least two options")
	assert(option_count <= RADIO_OPTIONS_MAX, "radio group options exceeds RADIO_OPTIONS_MAX")
	assert(
		props.legend != "" || props.aria_label != "",
		"radio group needs a legend or an aria_label",
	)
	assert(!(props.required && props.disabled), "radio group is both required and disabled")

	selected_found := props.value == ""
	for option, index in props.options {
		assert(option.value != "", "radio option needs a value")
		assert(option.label != "", "radio option needs a label")
		for other in props.options[:index] {
			assert(option.value != other.value, "radio options share a value")
		}
		if option.value == props.value do selected_found = true
	}
	assert(selected_found, "radio group value is not one of its options")

	// k.fieldset copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + RADIO_GROUP_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"radio group attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("radiogroup")
	attributes_count += 1
	if props.legend == "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}
	if props.aria_described_by != "" {
		attributes[attributes_count] = k.attribute("aria-describedby", props.aria_described_by)
		attributes_count += 1
	}
	if props.required {
		attributes[attributes_count] = k.attribute("aria-required", "true")
		attributes_count += 1
	}

	nodes: [RADIO_OPTIONS_MAX + 1]k.Node_Id
	nodes_count := 0
	if props.legend != "" {
		nodes[nodes_count] = k.legend(
			doc,
			{class = "radio-group__legend"},
			k.text(doc, props.legend),
		)
		nodes_count += 1
	}
	for option in props.options {
		// A disabled radio does not take part in validation, so it carries no `required`:
		// the group is still required through its enabled options. (The single-radio
		// assert refuses required and disabled together, which this keeps true.)
		disabled := props.disabled || option.disabled
		nodes[nodes_count] = radio(
			doc,
			{
				name = props.name,
				value = option.value,
				label = option.label,
				size = props.size,
				checked = option.value == props.value,
				disabled = disabled,
				required = props.required && !disabled,
				error = props.error,
			},
		)
		nodes_count += 1
	}

	base := props.base
	base.class = radio_group_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.fieldset(doc, {base = base}, ..nodes[:nodes_count])
}

@(private)
radio_class :: proc(doc: ^k.Doc, props: Radio_Props) -> string {
	disabled_class := props.disabled ? " radio--disabled" : ""
	error_class := props.error ? " radio--error" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"radio radio--%s%s%s%s%s",
		size_names[props.size],
		disabled_class,
		error_class,
		separator,
		props.class,
	)
}

@(private)
radio_group_class :: proc(doc: ^k.Doc, props: Radio_Group_Props) -> string {
	row_class := props.direction == .row ? " radio-group--row" : ""
	disabled_class := props.disabled ? " radio-group--disabled" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"radio-group%s%s%s%s",
		row_class,
		disabled_class,
		separator,
		props.class,
	)
}
