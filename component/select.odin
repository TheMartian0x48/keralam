package component

import k "kashmir:."

// ---------- constants ----------

INPUT_SELECT_OPTIONS_MAX :: 1000
INPUT_SELECT_GROUPS_MAX :: 64

// ---------- props ----------

// One choice in the list.
Input_Select_Option :: struct {
	value:    string, // submitted when chosen; not empty, and different from every other option's
	label:    string, // shown to the user; not empty
	disabled: bool, // listed, but can not be picked
}

// A titled set of options: an <optgroup>.
Input_Select_Group :: struct {
	label:    string, // not empty
	options:  []Input_Select_Option, // at least one
	disabled: bool, // every option in it
}

// A dropdown choice on the native <select>, so the browser keeps its picker, its mobile
// wheel and its keyboard handling. It is an input: it takes the same size, radius, error
// and disabled styles as input_text.
//
//   input_select(doc, {name = "country", placeholder = "Choose a country", options = {{"us", "United States", false}, {"uk", "United Kingdom", false}}})
//
// Give either options (a flat list) or groups (titled sets), not both.
//
// value picks the selected option, so two selected options can not be written. An empty
// value selects the placeholder. A select with no placeholder always has an option selected
// (the browser picks the first one), so it always submits something.
//
// A select has no read_only (browsers ignore it there), so there is no such field.
//
// Asserts, each a mistake the browser would quietly mishandle:
//   neither or both of options and groups; a group with no options or no label
//   an option with no value or no label; two options with the same value
//   value is empty or names an option, and that option is not disabled (a disabled option
//     looks chosen but the form drops it)
//   required without a placeholder (nothing to leave unchosen, so required does nothing)
//   required and disabled together
Input_Select_Props :: struct {
	using common: Input_Common,
	required:     bool, // needs a placeholder: the choice has to be made
	placeholder:  string, // the unchosen prompt, e.g. "Choose one"; its option can not be picked
	options:      []Input_Select_Option,
	groups:       []Input_Select_Group,
	value:        string, // the chosen option's value; "" shows the placeholder
	autocomplete: Input_Text_Autocomplete,
}

// ---------- procs ----------

// Composition order: input input--{size} [input--{radius}] [input--error] [input--disabled] [class] select
input_select :: proc(doc: ^k.Doc, props: Input_Select_Props) -> k.Node_Id {
	input_select_check(props)

	// k.select copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + INPUT_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"select attributes exceeds ATTRIBUTES_MAX",
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

	children: [INPUT_SELECT_OPTIONS_MAX + INPUT_SELECT_GROUPS_MAX + 1]k.Node_Id
	children_count := 0

	// The placeholder is an empty, disabled option. Kashmir skips an empty value, which
	// would leave an option whose value is its own text, so the attribute is forced.
	if props.placeholder != "" {
		children[children_count] = k.option(
			doc,
			{
				base = {attributes = {k.always("value", "")}},
				disabled = true,
				selected = props.value == "",
			},
			k.text(doc, props.placeholder),
		)
		children_count += 1
	}
	for option in props.options {
		children[children_count] = input_select_option_node(doc, option, props.value, false)
		children_count += 1
	}
	for group in props.groups {
		group_children: [INPUT_SELECT_OPTIONS_MAX]k.Node_Id
		for option, index in group.options {
			group_children[index] = input_select_option_node(
				doc,
				option,
				props.value,
				group.disabled,
			)
		}
		children[children_count] = k.optgroup(
			doc,
			{label = group.label, disabled = group.disabled},
			..group_children[:len(group.options)],
		)
		children_count += 1
	}

	base := props.base
	base.class = k.doc_format(doc, "%s select", input_class(doc, props.common, "input"))
	base.attributes = attributes[:attributes_count]

	select_node := k.select(
		doc,
		{
			base = base,
			name = props.name,
			required = props.required,
			disabled = props.disabled,
			autocomplete = input_text_autocomplete_names[props.autocomplete],
		},
		..children[:children_count],
	)
	indicator := k.span(
		doc,
		{class = "select__indicator"},
		icon(doc, {name = .caret_down, size = .small}),
	)
	return k.div(doc, {class = "select-container"}, select_node, indicator)
}

@(private)
input_select_option_node :: proc(
	doc: ^k.Doc,
	option: Input_Select_Option,
	value: string,
	group_disabled: bool,
) -> k.Node_Id {
	return k.option(
		doc,
		{
			value = option.value,
			disabled = option.disabled || group_disabled,
			selected = option.value == value,
		},
		k.text(doc, option.label),
	)
}

// ---------- asserts ----------

@(private)
input_select_check :: proc(props: Input_Select_Props) {
	option_count := len(props.options)
	group_count := len(props.groups)
	assert(!(option_count > 0 && group_count > 0), "select has both options and groups")
	assert(option_count > 0 || group_count > 0, "select has no options")
	assert(
		option_count <= INPUT_SELECT_OPTIONS_MAX,
		"select options exceeds INPUT_SELECT_OPTIONS_MAX",
	)
	assert(group_count <= INPUT_SELECT_GROUPS_MAX, "select groups exceeds INPUT_SELECT_GROUPS_MAX")
	assert(!(props.required && props.disabled), "select is both required and disabled")
	assert(!props.required || props.placeholder != "", "select is required but has no placeholder")

	total := option_count
	for group in props.groups {
		assert(group.label != "", "select group needs a label")
		assert(len(group.options) > 0, "select group has no options")
		total += len(group.options)
	}
	assert(total <= INPUT_SELECT_OPTIONS_MAX, "select options exceeds INPUT_SELECT_OPTIONS_MAX")

	// Every option, in order, checked against all the ones before it.
	seen: [INPUT_SELECT_OPTIONS_MAX]string
	seen_count := 0
	value_found := props.value == ""
	for option in props.options {
		input_select_check_option(option, props.value, false, seen[:seen_count], &value_found)
		seen[seen_count] = option.value
		seen_count += 1
	}
	for group in props.groups {
		for option in group.options {
			input_select_check_option(
				option,
				props.value,
				group.disabled,
				seen[:seen_count],
				&value_found,
			)
			seen[seen_count] = option.value
			seen_count += 1
		}
	}
	assert(value_found, "select value is not one of its options")
}

@(private)
input_select_check_option :: proc(
	option: Input_Select_Option,
	value: string,
	group_disabled: bool,
	before: []string,
	value_found: ^bool,
) {
	assert(option.value != "", "select option needs a value")
	assert(option.label != "", "select option needs a label")
	for earlier in before {
		assert(option.value != earlier, "select options share a value")
	}
	if option.value == value {
		value_found^ = true
		assert(!option.disabled && !group_disabled, "select value is a disabled option")
	}
}
