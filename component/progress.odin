package component

import "core:math"
import k "kashmir:."

// ---------- constants ----------

PROGRESS_MAXIMUM_DEFAULT :: f64(100)
PROGRESS_EXTRAS_MAX :: 5 // role, aria-valuenow, aria-valuemin, aria-valuemax (or aria-busy), the name
PROGRESS_DIAMETER_DEFAULT :: u32(24)
PROGRESS_DIAMETER_MIN :: u32(12)
PROGRESS_DIAMETER_MAX :: u32(512)
PROGRESS_THICKNESS_DEFAULT :: u32(3)
PROGRESS_INNER_FOR_VALUE_MIN :: u32(32) // room inside the ring for "100%"

// ---------- props ----------

// A horizontal progress bar.
//
//   progress(doc, {value = 40, label = "Uploading", show_value = true})
//   progress(doc, {indeterminate = true, aria_label = "Loading"})
//
// A value outside 0 to max is clamped, because it usually comes from a sum (bytes sent
// over bytes total) that can overshoot by a rounding step; NaN, infinity and a max that is
// not positive are programmer errors and assert. Indeterminate is only on when asked for:
// a value of 0 is a bar at 0.
//
// A progressbar needs a name. A visible label names it; with none, give aria_label. The
// screen reader is given the real value and max (37 of 50, not 74), and the percentage
// text beside the bar is hidden from it so the two are not read as one number.
//
// Asserts: max is positive and finite; value is finite unless indeterminate; a name is
// given; show_value is not combined with indeterminate (an unknown duration has no number).
Progress_Props :: struct {
	using base:    k.Base, // id (on the bar; generated when empty), class, style, attributes
	value:         f64, // 0 to max
	max:           Maybe(f64), // the value that means 100%; nil = 100
	label:         string, // visible text above the bar, which also names it
	show_value:    bool, // the percentage as text, beside the label
	size:          Size, // see component.odin: the bar is 4, 8 or 12px thick
	indeterminate: bool, // an unknown duration
	aria_label:    string, // the name when there is no visible label
}

// A ring-shaped progress indicator or spinner, drawn with CSS.
//
//   progress_circular(doc, {value = 75, show_value = true, diameter = 48, aria_label = "Upload"})
//   progress_circular(doc, {indeterminate = true, aria_label = "Loading"})
//
// It has no visible label, so aria_label is required. The same clamping, indeterminate and
// value rules as progress apply.
//
// Asserts: those of progress, and diameter within PROGRESS_DIAMETER_MIN to
// PROGRESS_DIAMETER_MAX; thickness at least 1 and less than half the diameter; and with
// show_value, enough room inside the ring for the text.
Progress_Circular_Props :: struct {
	using base:    k.Base, // id, class, style (appended after the component's), attributes
	value:         f64, // 0 to max
	max:           Maybe(f64), // nil = 100
	diameter:      u32, // in pixels; 0 = PROGRESS_DIAMETER_DEFAULT
	thickness:     u32, // the ring's width in pixels; 0 = PROGRESS_THICKNESS_DEFAULT
	show_value:    bool, // the percentage in the middle
	indeterminate: bool, // a spinner
	aria_label:    string, // required: the ring has no visible label
}

// ---------- procs ----------

// Composition order: progress progress--{size} [progress--indeterminate] [class]
progress :: proc(doc: ^k.Doc, props: Progress_Props) -> k.Node_Id {
	maximum := props.max.? or_else PROGRESS_MAXIMUM_DEFAULT
	progress_check(props.value, maximum, props.indeterminate, props.show_value)
	assert(props.label != "" || props.aria_label != "", "progress needs a label or an aria_label")

	value := clamp(props.value, 0, maximum)
	percent := value / maximum * 100

	// Unique within a page without global state: node counts only grow.
	bar_id := props.id != "" ? props.id : k.doc_format(doc, "pg%d", doc.nodes_count)
	label_id := k.doc_format(doc, "%s-label", bar_id)

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + PROGRESS_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"progress attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("progressbar")
	attributes_count += 1
	if props.indeterminate {
		attributes[attributes_count] = k.attribute("aria-busy", "true")
		attributes_count += 1
	} else {
		attributes[attributes_count] = k.attribute("aria-valuenow", input_number_text(doc, value))
		attributes[attributes_count + 1] = k.attribute("aria-valuemin", "0")
		attributes[attributes_count + 2] = k.attribute(
			"aria-valuemax",
			input_number_text(doc, maximum),
		)
		attributes_count += 3
	}
	if props.label != "" {
		attributes[attributes_count] = k.attribute("aria-labelledby", label_id)
	} else {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
	}
	attributes_count += 1

	bar := k.div(
		doc,
		{
			class = "progress__bar",
			style = props.indeterminate ? "" : k.doc_format(doc, "width: %.2f%%", percent),
		},
	)

	base := props.base
	base.id = bar_id
	base.class = progress_class(doc, props)
	base.attributes = attributes[:attributes_count]
	track := k.div(doc, base, bar)

	header := k.NODE_NONE
	if props.label != "" || props.show_value {
		label_node :=
			props.label != "" ? k.span(doc, {id = label_id, class = "progress-label"}, k.text(doc, props.label)) : k.NODE_NONE
		value_node := k.NODE_NONE
		if props.show_value {
			value_node = k.span(
				doc,
				{class = "progress-value", attributes = {k.attribute("aria-hidden", "true")}},
				k.text(doc, k.doc_format(doc, "%d%%", u32(math.round(percent)))),
			)
		}
		header = k.div(doc, {class = "progress-header"}, label_node, value_node)
	}
	return k.div(doc, {class = "progress-container"}, header, track)
}

// Composition order: circular-progress [circular-progress--indeterminate] [class]
progress_circular :: proc(doc: ^k.Doc, props: Progress_Circular_Props) -> k.Node_Id {
	maximum := props.max.? or_else PROGRESS_MAXIMUM_DEFAULT
	progress_check(props.value, maximum, props.indeterminate, props.show_value)
	assert(props.aria_label != "", "circular progress needs an aria_label")

	diameter := props.diameter != 0 ? props.diameter : PROGRESS_DIAMETER_DEFAULT
	thickness := props.thickness != 0 ? props.thickness : PROGRESS_THICKNESS_DEFAULT
	assert(
		diameter >= PROGRESS_DIAMETER_MIN && diameter <= PROGRESS_DIAMETER_MAX,
		"circular progress diameter is outside PROGRESS_DIAMETER_MIN to PROGRESS_DIAMETER_MAX",
	)
	assert(
		thickness * 2 < diameter,
		"circular progress thickness must be less than half the diameter",
	)
	assert(
		!props.show_value || diameter - 2 * thickness >= PROGRESS_INNER_FOR_VALUE_MIN,
		"circular progress has no room for its value: make the ring larger or thinner",
	)

	value := clamp(props.value, 0, maximum)
	percent := value / maximum * 100

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + PROGRESS_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"circular progress attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("progressbar")
	attributes_count += 1
	if props.indeterminate {
		attributes[attributes_count] = k.attribute("aria-busy", "true")
		attributes_count += 1
	} else {
		attributes[attributes_count] = k.attribute("aria-valuenow", input_number_text(doc, value))
		attributes[attributes_count + 1] = k.attribute("aria-valuemin", "0")
		attributes[attributes_count + 2] = k.attribute(
			"aria-valuemax",
			input_number_text(doc, maximum),
		)
		attributes_count += 3
	}
	attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
	attributes_count += 1

	own_style := k.doc_format(
		doc,
		"--progress-diameter: %dpx; --progress-thickness: %dpx; --progress-percent: %.2f",
		diameter,
		thickness,
		percent,
	)

	content := k.NODE_NONE
	if props.show_value {
		content = k.div(
			doc,
			{
				class = "circular-progress__content",
				attributes = {k.attribute("aria-hidden", "true")},
			},
			k.text(doc, k.doc_format(doc, "%d%%", u32(math.round(percent)))),
		)
	}

	base := props.base
	base.class =
		props.class != "" ? k.doc_format(doc, "%s %s", progress_circular_class(props.indeterminate), props.class) : progress_circular_class(props.indeterminate)
	base.style =
		props.style != "" ? k.doc_format(doc, "%s; %s", own_style, props.style) : own_style
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, k.div(doc, {class = "circular-progress__ring"}), content)
}

@(private)
progress_check :: proc(value, maximum: f64, indeterminate, show_value: bool) {
	assert(
		!math.is_nan(maximum) && !math.is_inf(maximum) && maximum > 0,
		"progress max must be positive and finite",
	)
	assert(
		indeterminate || (!math.is_nan(value) && !math.is_inf(value)),
		"progress value must be finite",
	)
	assert(!(show_value && indeterminate), "progress shows no value while indeterminate")
}

@(private)
progress_class :: proc(doc: ^k.Doc, props: Progress_Props) -> string {
	indeterminate_class := props.indeterminate ? " progress--indeterminate" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"progress progress--%s%s%s%s",
		size_names[props.size],
		indeterminate_class,
		separator,
		props.class,
	)
}

@(private)
progress_circular_class :: proc(indeterminate: bool) -> string {
	return(
		indeterminate ? "circular-progress circular-progress--indeterminate" : "circular-progress" \
	)
}
