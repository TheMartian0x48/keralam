package component

import "core:strings"
import k "kashmir:."

// ---------- constants ----------

LINK_EXTRAS_MAX :: 2 // aria-disabled, tabindex

// ---------- props ----------

// An anchor for navigation, with its own stylesheet (link.css). Use button for
// actions that stay on the current page.
//
//   link(doc, {href = "/profile", variant = .primary, shape = .outline}, k.text(doc, "View Profile"))
//
// The zero value is a medium, solid, primary link.
Link_Props :: struct {
	using base: k.Base, // id, class (appended after the generated classes), style, attributes

	// appearance
	variant:    Variant, // see component.odin
	shape:      Shape, // see component.odin
	size:       Size, // see component.odin
	radius:     Radius, // see component.odin

	// navigation
	href:       string, // must not use a script scheme, see link_href_safe
	target:     string, // e.g. "_blank" for a new tab
	rel:        string, // defaults to "noopener noreferrer" when target is "_blank"

	// state and accessibility
	disabled:   bool, // drops href, leaves the tab order and ignores pointer events
	aria_label: string, // required for icon-only links
}

// ---------- procs ----------

// Composition order: link link--{variant} link--{shape} link--{size} [link--{radius}] [link--disabled] [class]
link :: proc(doc: ^k.Doc, props: Link_Props, children: ..k.Node_Id) -> k.Node_Id {
	assert(link_href_safe(props.href), "link href uses a script scheme")

	// k.a copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + LINK_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"link attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	if props.disabled {
		attributes[attributes_count] = k.attribute("aria-disabled", "true")
		attributes_count += 1
		attributes[attributes_count] = k.attribute("tabindex", "-1")
		attributes_count += 1
	}

	base := props.base
	base.class = link_class(doc, props)
	base.attributes = attributes[:attributes_count]

	// A disabled anchor has no href: that is what makes it non-interactive.
	return k.a(
		doc,
		{
			base = base,
			href = props.disabled ? "" : props.href,
			target = props.target,
			rel = link_rel(props),
		},
		..children,
	)
}

// Rejects javascript:, data: and vbscript: URLs. Browsers ignore ASCII control
// characters and spaces at the start of a URL and inside its scheme, so those are
// stripped before comparing.
link_href_safe :: proc(href: string) -> bool {
	scheme_prefixes :: [?]string{"javascript:", "data:", "vbscript:"}
	scheme_bytes_max :: 16 // longer than any prefix above

	compact: [scheme_bytes_max]u8
	compact_count := 0
	for character in transmute([]u8)href {
		if character <= ' ' do continue // control characters and spaces
		if compact_count == scheme_bytes_max do break
		compact[compact_count] = character
		compact_count += 1
	}

	lowered := strings.to_lower(string(compact[:compact_count]), context.temp_allocator)
	for prefix in scheme_prefixes {
		if strings.has_prefix(lowered, prefix) do return false
	}
	return true
}

@(private)
link_rel :: proc(props: Link_Props) -> string {
	if props.rel != "" do return props.rel
	return props.target == "_blank" ? "noopener noreferrer" : ""
}

@(private)
link_class :: proc(doc: ^k.Doc, props: Link_Props) -> string {
	disabled_class := props.disabled ? " link--disabled" : ""
	return appearance_class(
		doc,
		"link",
		props.variant,
		props.shape,
		props.size,
		props.radius,
		disabled_class,
		props.class,
	)
}
