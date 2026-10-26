package component

import "core:encoding/json"
import k "kashmir:."

// ---------- constants ----------

AUTOCOMPLETE_OPTIONS_MAX :: 1024
AUTOCOMPLETE_JSON_BYTES_MAX :: 1 << 16 // 64 KiB of options as JSON
AUTOCOMPLETE_EXTRAS_MAX :: 3 // data-controller, options value, initial value, data-action

// ---------- props ----------

Autocomplete_Option :: struct {
	value: string `json:"value"`, // the machine value a form submits
	label: string `json:"label"`, // the text shown in the list
}

// A text input with a searchable dropdown. Filtering and keyboard navigation run in
// the keralam-autocomplete Stimulus controller; this proc renders the markup and the
// options.
//
//   autocomplete(doc, {name = "country", value = "us", options = {{"us", "United States"}, {"uk", "United Kingdom"}}})
//
// A form submits the option's value, never its label. The visible input shows the
// label and has no name; a hidden input next to it carries the name and the value,
// and the controller keeps the two in step. Text that is not an option submits an
// empty value, so required means "pick one".
Autocomplete_Props :: struct {
	using base:  k.Base, // id (goes on the root; generated when empty), class, style, attributes
	input_id:    string, // id of the visible input, for a <label for>; a <div> root can not be labelled
	name:        string, // form field name, carried by the hidden input
	placeholder: string,
	label:       string, // accessible label
	options:     []Autocomplete_Option,
	value:       string, // the initially selected option's value; "" or an unknown value starts empty
	disabled:    bool,
	required:    bool,
	error:       bool,

	// accessibility
	aria_described_by: string, // id of an element with more context, e.g. an error message; goes on the visible input
}

// ---------- procs ----------

// Composition order: autocomplete [autocomplete--disabled] [class]
autocomplete :: proc(doc: ^k.Doc, props: Autocomplete_Props) -> k.Node_Id {
	assert(
		len(props.options) <= AUTOCOMPLETE_OPTIONS_MAX,
		"autocomplete options exceeds AUTOCOMPLETE_OPTIONS_MAX",
	)

	// Unique within a page without global state: node counts only grow, so two
	// autocompletes in one Doc never get the same number.
	root_id := props.id != "" ? props.id : k.doc_format(doc, "ac%d", doc.nodes_count)
	listbox_id := k.doc_format(doc, "autocomplete-listbox-%s", root_id)

	// The label of the selected option is what the visible input starts with.
	initial_label := ""
	initial_value := ""
	for option in props.options {
		if option.value == props.value && props.value != "" {
			initial_label = option.label
			initial_value = option.value
			break
		}
	}

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + AUTOCOMPLETE_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"autocomplete attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.attribute("data-controller", "keralam-autocomplete")
	attributes_count += 1
	attributes[attributes_count] = k.attribute(
		"data-keralam-autocomplete-options-value",
		autocomplete_options_json(doc, props.options),
	)
	attributes_count += 1
	attributes[attributes_count] = k.attribute(
		"data-keralam-autocomplete-initial-value",
		initial_label,
	)
	attributes_count += 1
	attributes[attributes_count] = k.attribute(
		"data-action",
		"click@window->keralam-autocomplete#clickOutside",
	)
	attributes_count += 1

	// The visible input has no name: the hidden one is what a form submits.
	input_attributes := [?]k.Attribute {
		k.attribute("data-keralam-autocomplete-target", "input"),
		k.attribute("autocomplete", "off"),
		k.role("combobox"),
		k.attribute("aria-haspopup", "listbox"),
		k.attribute("aria-expanded", "false"),
		k.attribute("aria-controls", listbox_id),
		k.attribute("aria-label", props.label != "" ? props.label : props.placeholder),
		k.attribute("aria-describedby", props.aria_described_by),
		k.attribute(
			"data-action",
			"input->keralam-autocomplete#search keydown->keralam-autocomplete#navigate focus->keralam-autocomplete#focusOpen click->keralam-autocomplete#focusOpen blur->keralam-autocomplete#commit",
		),
		k.attribute("aria-invalid", props.error ? "true" : ""),
	}
	input_class :=
		props.error ? "autocomplete__input autocomplete__input--error" : "autocomplete__input"

	base := props.base
	base.id = root_id
	base.class =
		props.class != "" ? k.doc_format(doc, "%s %s", autocomplete_class(props), props.class) : autocomplete_class(props)
	base.attributes = attributes[:attributes_count]

	return k.div(
		doc,
		base,
		k.div(
			doc,
			{class = "autocomplete__control"},
			k.input(
				doc,
				{
					base = {id = props.input_id, class = input_class, attributes = input_attributes[:]},
					placeholder = props.placeholder,
					value = initial_label,
					disabled = props.disabled,
					required = props.required,
				},
			),
			input_hidden(
				doc,
				{
					attributes = {k.attribute("data-keralam-autocomplete-target", "field")},
					name = props.name,
					value = initial_value,
					disabled = props.disabled,
				},
			),
			k.div(
				doc,
				{class = "autocomplete__indicator"},
				icon(doc, {name = .caret_down, size = .small}),
			),
		),
		k.ul(
			doc,
			{
				id = listbox_id,
				class = "autocomplete__menu",
				attributes = {
					k.attribute("data-keralam-autocomplete-target", "menu"),
					k.role("listbox"),
					k.attribute("aria-label", props.label),
					k.hidden(),
					k.attribute(
						"data-action",
						"mousedown->keralam-autocomplete#pressItem click->keralam-autocomplete#selectItem mouseover->keralam-autocomplete#highlightItem",
					),
				},
			},
		),
		k.div(
			doc,
			{
				class = "visually-hidden",
				attributes = {
					k.attribute("data-keralam-autocomplete-target", "announcer"),
					k.attribute("aria-live", "polite"),
					k.attribute("aria-atomic", "true"),
				},
			},
		),
	)
}

@(private)
autocomplete_class :: proc(props: Autocomplete_Props) -> string {
	return props.disabled ? "autocomplete autocomplete--disabled" : "autocomplete"
}

// The options as the JSON array the controller reads: [{"value":...,"label":...}].
// Marshalled by core:encoding/json, which escapes quotes, backslashes and control
// characters; kashmir then escapes the result as an attribute value.
@(private)
autocomplete_options_json :: proc(doc: ^k.Doc, options: []Autocomplete_Option) -> string {
	if len(options) == 0 do return "[]"

	data, error := json.marshal(options, {}, context.temp_allocator)
	assert(error == nil, "autocomplete options could not be encoded")
	assert(
		len(data) <= AUTOCOMPLETE_JSON_BYTES_MAX,
		"autocomplete options exceeds AUTOCOMPLETE_JSON_BYTES_MAX",
	)
	return k.doc_format(doc, "%s", string(data))
}
