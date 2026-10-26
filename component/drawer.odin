package component

import k "kashmir:."

// ---------- enums ----------

// The screen edge the panel slides from.
Drawer_Position :: enum u8 {
	right, // default
	left,
	top,
	bottom,
}

@(private)
drawer_position_names := [Drawer_Position]string {
	.right  = "right",
	.left   = "left",
	.top    = "top",
	.bottom = "bottom",
}

// ---------- constants ----------

DRAWER_EXTRAS_MAX :: 4 // data-controller, data-action, aria-labelledby, aria-describedby

// ---------- props ----------

// A slide-over panel on the native <dialog> element: the browser handles focus
// trapping, the backdrop and Escape.
//
//   drawer(doc, {id = "menu", title = "Menu", position = .left}, k.text(doc, "Links..."))
//
// A drawer stays hidden until opened. Any of these opens it:
//
//   a button with command="show-modal" and commandfor="menu"
//     (declarative; Chrome 135, Safari 18.4 or Firefox 144 or newer)
//   window.dispatchEvent(new CustomEvent("drawer:open", {detail: "menu"}))
//
// Close it with the close button, Escape, or a click on the backdrop. The page
// does not scroll behind an open drawer. All of that comes from the keralam-drawer
// controller in keralam.js.
//
// Size is a CSS variable with a default: --drawer-size is the width of a left or
// right panel (default 24rem) and the max height of a top or bottom one (default
// 50vh). Set it with style, a class, or on any ancestor:
//
//   drawer(doc, {id = "menu", style = "--drawer-size: 40rem"}, ...)
//
// Title and description are plain text, escaped on render. An empty title or
// description is left out, along with its ARIA attribute.
Drawer_Props :: struct {
	using base:  k.Base, // id (generated when empty), class (appended after "drawer"), style, attributes

	// content
	title:       string,
	description: string, // wired up as aria-describedby

	// appearance
	position:    Drawer_Position,
}

// ---------- procs ----------

// Composition order: drawer [class] on the dialog; drawer__panel drawer__panel--{position} on the panel
drawer :: proc(doc: ^k.Doc, props: Drawer_Props, children: ..k.Node_Id) -> k.Node_Id {
	has_title := props.title != ""
	has_description := props.description != ""

	// Unique within a page without global state: node counts only grow.
	drawer_id := props.id != "" ? props.id : k.doc_format(doc, "drw%d", doc.nodes_count)
	title_id := k.doc_format(doc, "%s-title", drawer_id)
	description_id := k.doc_format(doc, "%s-desc", drawer_id)

	// k.dialog copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DRAWER_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"drawer attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.attribute("data-controller", "keralam-drawer")
	attributes_count += 1
	attributes[attributes_count] = k.attribute("data-action", "click->keralam-drawer#backdropClick")
	attributes_count += 1
	if has_title {
		attributes[attributes_count] = k.attribute("aria-labelledby", title_id)
		attributes_count += 1
	}
	if has_description {
		attributes[attributes_count] = k.attribute("aria-describedby", description_id)
		attributes_count += 1
	}

	heading := k.NODE_NONE
	if has_title {
		heading = k.h3(doc, {id = title_id, class = "drawer__title"}, k.text(doc, props.title))
	}

	close_button := button(
		doc,
		{
			class = "drawer__close",
			variant = .secondary,
			shape = .text,
			size = .small,
			attributes = {
				k.attribute("data-action", "keralam-drawer#close"),
				k.attribute("aria-label", "Close drawer"),
			},
		},
		icon(doc, {name = .x, size = .small}),
	)

	description_node := k.NODE_NONE
	if has_description {
		description_node = k.p(
			doc,
			{id = description_id, class = "drawer__description"},
			k.text(doc, props.description),
		)
	}

	panel := k.div(
		doc,
		{
			class = k.doc_format(
				doc,
				"drawer__panel drawer__panel--%s",
				drawer_position_names[props.position],
			),
		},
		k.div(
			doc,
			{class = "drawer__header"},
			heading,
			k.div(doc, {class = "drawer__close-wrapper"}, close_button),
		),
		description_node,
		k.div(doc, {class = "drawer__body"}, ..children),
	)

	base := props.base
	base.id = drawer_id
	base.class = props.class != "" ? k.doc_format(doc, "drawer %s", props.class) : "drawer"
	base.attributes = attributes[:attributes_count]
	return k.dialog(doc, {base = base}, panel)
}
