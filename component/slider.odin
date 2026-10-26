package component

import k "kashmir:."

// ---------- constants ----------

SLIDER_UNIT_BYTES_MAX :: 8
SLIDER_EXTRAS_MAX :: 4 // data-controller, unit value, plus headroom
SLIDER_INPUT_EXTRAS_MAX :: 2 // data-keralam-slider-target, data-action

// ---------- props ----------

// An input_range with a label and a live readout, and a track that fills up to the thumb.
//
//   slider(doc, {name = "volume", label = "Volume", value = 40.0, show_value = true, unit = "%"})
//
// It is a wrapper: the control is input_range, with its checks (finite numbers, min below
// max, value inside the range, step above zero), so use input_range directly when the slider
// needs no label of its own, for example under a form_field. A slider carries its own label,
// like checkbox and toggle, so it does not go in form_field.
//
// The keralam-slider controller updates the fill and the readout while the thumb moves. The
// readout is an <output> tied to the slider, not a live region: a screen reader announces
// the slider's own value as it changes, once. Without script both show the starting value
// and the slider still works.
//
// Asserts: a name, either label or aria_label; unit at most SLIDER_UNIT_BYTES_MAX bytes; and
// those of input_range.
Slider_Props :: struct {
	using base:        k.Base, // wrapper: id (generated when empty), class, style, attributes
	name:              string, // the form field name
	label:             string, // the visible name; also what the readout sits beside
	aria_label:        string, // the name when there is no visible label
	aria_described_by: string,
	value:             Maybe(f64), // browser default: the middle of the range
	min:               Maybe(f64), // 0
	max:               Maybe(f64), // 100
	step:              Maybe(f64), // browser default 1
	show_value:        bool, // the number beside the label
	unit:              string, // shown after the number, e.g. "%" or " px"
	size:              Size, // see component.odin
	disabled:          bool,
	error:             bool, // sets aria-invalid and the error styling
}

// ---------- procs ----------

// Composition order: slider-container [class]
slider :: proc(doc: ^k.Doc, props: Slider_Props) -> k.Node_Id {
	assert(props.label != "" || props.aria_label != "", "slider needs a label or an aria_label")
	assert(len(props.unit) <= SLIDER_UNIT_BYTES_MAX, "slider unit exceeds SLIDER_UNIT_BYTES_MAX")

	low := props.min.? or_else 0.0
	high := props.max.? or_else 100.0
	// The browser puts an unset value in the middle of the range.
	value := props.value.? or_else low + (high - low) / 2
	percent := high > low ? clamp((value - low) / (high - low) * 100, 0, 100) : 0

	// Unique within a page without global state: node counts only grow.
	wrapper_id := props.id != "" ? props.id : k.doc_format(doc, "sl%d", doc.nodes_count)
	input_id := k.doc_format(doc, "%s-input", wrapper_id)

	input_attributes := [SLIDER_INPUT_EXTRAS_MAX]k.Attribute {
		k.attribute("data-keralam-slider-target", "input"),
		k.attribute("data-action", "input->keralam-slider#update"),
	}
	control := input_range(
		doc,
		{
			common = {
				base = {
					id = input_id,
					style = k.doc_format(doc, "--slider-pct: %.2f%%", percent),
					attributes = input_attributes[:],
				},
				name = props.name,
				size = props.size,
				disabled = props.disabled,
				error = props.error,
				aria_label = props.label == "" ? props.aria_label : "",
				aria_described_by = props.aria_described_by,
			},
			value = props.value,
			min = props.min,
			max = props.max,
			step = props.step,
		},
	)

	header := k.NODE_NONE
	if props.label != "" || props.show_value {
		label_node := k.NODE_NONE
		if props.label != "" {
			label_node = label(
				doc,
				{class = "slider-label", for_ = input_id, disabled = props.disabled},
				k.text(doc, props.label),
			)
		}
		value_node := k.NODE_NONE
		if props.show_value {
			value_node = k.output(
				doc,
				{
					class = "slider-value",
					for_ = input_id,
					attributes = {k.attribute("data-keralam-slider-target", "output")},
				},
				k.text(doc, k.doc_format(doc, "%s%s", input_number_text(doc, value), props.unit)),
			)
		}
		header = k.div(doc, {class = "slider-header"}, label_node, value_node)
	}

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + SLIDER_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"slider attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute("data-controller", "keralam-slider")
	attributes[attributes_count + 1] = k.attribute("data-keralam-slider-unit-value", props.unit)
	attributes_count += 2

	base := props.base
	base.id = wrapper_id
	base.class =
		props.class != "" ? k.doc_format(doc, "slider-container %s", props.class) : "slider-container"
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, header, control)
}
