package component

import k "kashmir:."

// ---------- constants ----------

BADGE_EXTRAS_MAX :: 3 // aria-label, aria-disabled, data-controller

// ---------- props ----------

// A small label for status, counts or categories.
//
//   badge(doc, {variant = .success, radius = .pilled}, k.text(doc, "Active"))
//
// Badges are informative by default. When dismissible, give them a meaningful
// aria_label. The zero value is a medium, solid, primary badge.
Badge_Props :: struct {
	using base:  k.Base, // id, class (appended after the generated classes), style, attributes

	// appearance
	variant:     Variant, // see component.odin
	shape:       Shape, // see component.odin
	size:        Size, // see component.odin
	radius:      Radius, // see component.odin
	icon:        Maybe(k.Node_Id), // optional leading icon; a Node_Id of 0 is a real node, so it needs Maybe

	// behaviour
	dismissible: bool, // shows a removal button

	// state
	disabled:    bool, // mutes colors and removes the removal button

	// accessibility
	aria_label:  string,
}

Badge_Group_Props :: struct {
	using base: k.Base,
	aria_label: string, // accessible label for the collection
}

// ---------- procs ----------

// Composition order: badge badge--{variant} badge--{shape} badge--{size}
// [badge--{radius}] [badge--dismissible] [badge--disabled] [class]
badge :: proc(doc: ^k.Doc, props: Badge_Props, children: ..k.Node_Id) -> k.Node_Id {
	// k.span copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + BADGE_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"badge attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	removable := props.dismissible && !props.disabled
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}
	if props.disabled {
		attributes[attributes_count] = k.attribute("aria-disabled", "true")
		attributes_count += 1
	}
	if removable {
		attributes[attributes_count] = k.attribute("data-controller", "keralam-badge")
		attributes_count += 1
	}

	leading := k.NODE_NONE
	if icon_node, has_icon := props.icon.?; has_icon {
		leading = k.span(
			doc,
			{class = "badge__icon", attributes = {k.attribute("aria-hidden", "true")}},
			icon_node,
		)
	}
	text := k.span(doc, {class = "badge__text"}, ..children)

	dismiss := k.NODE_NONE
	if removable {
		dismiss = button(
			doc,
			{
				class = "badge__dismiss",
				variant = .secondary,
				shape = .text,
				size = .small,
				attributes = {
					k.attribute("aria-label", "Remove"),
					k.attribute("data-action", "keralam-badge#dismiss"),
				},
			},
			icon(doc, {name = .x, size = .small}),
		)
	}

	base := props.base
	base.class = badge_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.span(doc, base, leading, text, dismiss)
}

// A flex container with consistent spacing between badges.
badge_group :: proc(doc: ^k.Doc, props: Badge_Group_Props, children: ..k.Node_Id) -> k.Node_Id {
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(attributes_count + 2 <= ATTRIBUTES_MAX, "badge group attributes exceeds ATTRIBUTES_MAX")
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role("group")
	attributes_count += 1
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}

	base := props.base
	base.class =
		props.class != "" ? k.doc_format(doc, "badge-group %s", props.class) : "badge-group"
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, ..children)
}

@(private)
badge_class :: proc(doc: ^k.Doc, props: Badge_Props) -> string {
	dismissible_class := props.dismissible ? " badge--dismissible" : ""
	disabled_class := props.disabled ? " badge--disabled" : ""
	return appearance_class(
		doc,
		"badge",
		props.variant,
		props.shape,
		props.size,
		props.radius,
		k.doc_format(doc, "%s%s", dismissible_class, disabled_class),
		props.class,
	)
}
