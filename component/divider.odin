package component

import k "kashmir:."

// ---------- enums ----------

Divider_Orientation :: enum u8 {
	horizontal, // a line for stacked content (default)
	vertical, // a line for inline content
}

@(private)
divider_orientation_names := [Divider_Orientation]string {
	.horizontal = "horizontal",
	.vertical   = "vertical",
}

// ---------- constants ----------

DIVIDER_EXTRAS_MAX :: 2 // role, aria-orientation

// ---------- props ----------

// A visual separator.
//
//   divider(doc, {label = "OR"})
//
// What it renders depends on the props, and ARIA follows:
//   horizontal         <hr>, which is already a separator
//   horizontal+label   <div role="separator"> with a line, the text, and a line
//   vertical           <div role="separator" aria-orientation="vertical">
//
// A vertical divider stretches to the height of a flex or grid parent (a toolbar, a
// button group). In any other parent it is a short 16px rule. A label only makes
// sense on a horizontal divider, so giving one to a vertical divider asserts.
Divider_Props :: struct {
	using base:  k.Base, // id, class (appended after the generated classes), style, attributes
	orientation: Divider_Orientation,
	label:       string, // optional text in the centre
}

// ---------- procs ----------

// Composition order: divider divider--{orientation} [divider--labelled] [class]
divider :: proc(doc: ^k.Doc, props: Divider_Props) -> k.Node_Id {
	assert(
		props.orientation == .horizontal || props.label == "",
		"divider label needs a horizontal divider",
	)

	base := props.base
	base.class = divider_class(doc, props)

	// A plain horizontal divider is an <hr>: no role needed.
	if props.orientation == .horizontal && props.label == "" {
		return k.hr(doc, base)
	}

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DIVIDER_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"divider attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("separator")
	attributes_count += 1
	attributes[attributes_count] = k.attribute(
		"aria-orientation",
		divider_orientation_names[props.orientation],
	)
	attributes_count += 1
	base.attributes = attributes[:attributes_count]

	if props.label == "" {
		return k.div(doc, base)
	}
	return k.div(
		doc,
		base,
		k.div(doc, {class = "divider__line"}),
		k.div(doc, {class = "divider__label"}, k.text(doc, props.label)),
		k.div(doc, {class = "divider__line"}),
	)
}

@(private)
divider_class :: proc(doc: ^k.Doc, props: Divider_Props) -> string {
	labelled_class := props.label != "" ? " divider--labelled" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"divider divider--%s%s%s%s",
		divider_orientation_names[props.orientation],
		labelled_class,
		separator,
		props.class,
	)
}
