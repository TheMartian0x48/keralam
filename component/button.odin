package component

import k "kashmir:."

// ---------- enums ----------

Button_Type :: enum u8 {
	button, // zero value: never falls back to the browser default (submit)
	submit,
	reset,
}

@(private)
button_type_names := [Button_Type]string {
	.button = "button",
	.submit = "submit",
	.reset  = "reset",
}

// ---------- constants ----------

ATTRIBUTES_MAX :: 32 // caller attributes plus the ones this component adds
EXTRAS_MAX :: 3 // aria-disabled, aria-busy, autofocus

// ---------- props ----------

// The API is split into orthogonal dimensions:
//   variant: the color family
//   shape:   the fill style
//   size:    the vertical scale
//   radius:  the corner rounding
//
//   button(doc, {variant = .danger, shape = .outline}, k.text(doc, "Delete"))
//
// The zero value is a medium, solid, primary button of type "button".
Button_Props :: struct {
	using base:    k.Base, // id, class (appended after the generated classes), style, attributes

	// appearance
	variant:       Variant, // see component.odin
	shape:         Shape, // see component.odin
	size:          Size, // see component.odin
	radius:        Radius, // see component.odin

	// behaviour
	type:          Button_Type,

	// state
	disabled:      bool, // standard disabled attribute
	aria_disabled: bool, // looks disabled but stays focusable
	loading:       bool, // adds btn--loading and aria-busy="true"
	autofocus:     bool, // focused on initial mount
}

// ---------- procs ----------

// Composition order: btn btn--{variant} btn--{shape} btn--{size} [btn--{radius}] [btn--loading] [class]
button :: proc(doc: ^k.Doc, props: Button_Props, children: ..k.Node_Id) -> k.Node_Id {
	// k.button copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + EXTRAS_MAX <= ATTRIBUTES_MAX,
		"button attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	if props.aria_disabled {
		attributes[attributes_count] = k.attribute("aria-disabled", "true")
		attributes_count += 1
	}
	if props.loading {
		attributes[attributes_count] = k.attribute("aria-busy", "true")
		attributes_count += 1
	}
	if props.autofocus {
		attributes[attributes_count] = k.autofocus()
		attributes_count += 1
	}

	base := props.base
	base.class = button_class(doc, props)
	base.attributes = attributes[:attributes_count]

	return k.button(
		doc,
		{base = base, type = button_kashmir_type(props.type), disabled = props.disabled},
		..children,
	)
}

@(private)
button_kashmir_type :: proc(type: Button_Type) -> k.Button_Type {
	switch type {
	case .button:
		return .button
	case .submit:
		return .submit
	case .reset:
		return .reset
	}
	unreachable()
}

@(private)
button_class :: proc(doc: ^k.Doc, props: Button_Props) -> string {
	loading_class := props.loading ? " btn--loading" : ""
	return appearance_class(
		doc,
		"btn",
		props.variant,
		props.shape,
		props.size,
		props.radius,
		loading_class,
		props.class,
	)
}
