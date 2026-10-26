package component

import k "kashmir:."

// ---------- enums ----------

// Which edge of the trigger the menu lines up with. Start is first so the zero value
// is the stock alignment. Go's `Right` is End here, because the CSS is written in
// logical terms (inline-start / inline-end) and so also works right-to-left.
Dropdown_Align :: enum u8 {
	start,
	end,
}

// ---------- constants ----------

DROPDOWN_EXTRAS_MAX :: 3 // aria-label, role, and headroom

// ---------- props ----------

// A collapsible menu on the native <details> and <summary> elements. The trigger
// has its own styles in dropdown.css and does not depend on button.
//
//   dropdown(doc, {label = "Options"},
//       dropdown_item(doc, {label = "Edit", icon = .pencil_simple}),
//       dropdown_item(doc, {label = "Delete", icon = .trash, danger = true}))
//
// The keralam-dropdown controller (in keralam.js) closes it on an outside click, on
// Escape, and after a pick, and moves between items with the arrow keys, Home and
// End. Without JavaScript it still opens and closes on a click of the trigger.
//
// The menu is position: absolute, so an ancestor with overflow: hidden clips it.
Dropdown_Props :: struct {
	using base: k.Base, // id (goes on the <details>; generated when empty), class, style, attributes
	label:      string, // text on the trigger
	align:      Dropdown_Align,
	aria_label: string, // accessible name for the trigger
}

// One entry in the menu. With an href it is a link, otherwise a button; give a button
// its behaviour through attributes (a data-action, or command and commandfor).
// id, class and attributes go on the link or button itself.
Dropdown_Item_Props :: struct {
	using base: k.Base,
	label:      string,
	href:       string, // set: <a>; empty: <button type="button">
	icon:       Icon_Name, // .none draws nothing
	danger:     bool, // destructive styling
	aria_label: string,
}

// ---------- procs ----------

// Composition order: dropdown [dropdown--end] [class]
dropdown :: proc(doc: ^k.Doc, props: Dropdown_Props, children: ..k.Node_Id) -> k.Node_Id {
	// Unique within a page without global state: node counts only grow.
	dropdown_id := props.id != "" ? props.id : k.doc_format(doc, "dd%d", doc.nodes_count)
	menu_id := k.doc_format(doc, "%s-menu", dropdown_id)

	// k.details copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DROPDOWN_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"dropdown attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute("data-controller", "keralam-dropdown")
	attributes_count += 1

	trigger_attributes: [4]k.Attribute
	trigger_count := 0
	trigger_attributes[trigger_count] = k.attribute("aria-expanded", "false")
	trigger_count += 1
	trigger_attributes[trigger_count] = k.attribute("aria-controls", menu_id)
	trigger_count += 1
	trigger_attributes[trigger_count] = k.attribute("aria-haspopup", "menu")
	trigger_count += 1
	if props.aria_label != "" {
		trigger_attributes[trigger_count] = k.attribute("aria-label", props.aria_label)
		trigger_count += 1
	}

	trigger := k.summary(
		doc,
		{class = "dropdown__trigger", attributes = trigger_attributes[:trigger_count]},
		k.span(doc, {}, k.text(doc, props.label)),
		icon(doc, {class = "dropdown__arrow", name = .caret_down, size = .small}),
	)
	menu := k.div(
		doc,
		{id = menu_id, class = "dropdown__menu", attributes = {k.role("menu")}},
		..children,
	)

	base := props.base
	base.id = dropdown_id
	base.class = dropdown_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.details(doc, {base = base}, trigger, menu)
}

// Composition order: dropdown__item [dropdown__item--danger] [class]
dropdown_item :: proc(doc: ^k.Doc, props: Dropdown_Item_Props) -> k.Node_Id {
	assert(link_href_safe(props.href), "dropdown item href uses a script scheme")

	// k.a and k.button copy the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DROPDOWN_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"dropdown item attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.role("menuitem")
	attributes_count += 1
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}

	base := props.base
	base.class = dropdown_item_class(doc, props)
	base.attributes = attributes[:attributes_count]

	glyph := props.icon != .none ? icon(doc, {name = props.icon, size = .small}) : k.NODE_NONE
	text := k.text(doc, props.label)

	if props.href != "" {
		return k.a(doc, {base = base, href = props.href}, glyph, text)
	}
	return k.button(doc, {base = base, type = .button}, glyph, text)
}

// A horizontal separator between groups of items.
dropdown_divider :: proc(doc: ^k.Doc, props: k.Base) -> k.Node_Id {
	// An <hr> is a void element: the id and class are all it can carry.
	assert(len(props.attributes) <= ATTRIBUTES_MAX, "dropdown divider attributes exceeds ATTRIBUTES_MAX")
	base := props
	base.class =
		props.class != "" ? k.doc_format(doc, "dropdown__divider %s", props.class) : "dropdown__divider"
	return k.hr(doc, base)
}

// A non-interactive heading for a group of items.
dropdown_label :: proc(doc: ^k.Doc, props: k.Base, children: ..k.Node_Id) -> k.Node_Id {
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + 1 <= ATTRIBUTES_MAX,
		"dropdown label attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.role("presentation")
	attributes_count += 1

	base := props
	base.class =
		props.class != "" ? k.doc_format(doc, "dropdown__label %s", props.class) : "dropdown__label"
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, ..children)
}

@(private)
dropdown_class :: proc(doc: ^k.Doc, props: Dropdown_Props) -> string {
	end_class := props.align == .end ? " dropdown--end" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(doc, "dropdown%s%s%s", end_class, separator, props.class)
}

@(private)
dropdown_item_class :: proc(doc: ^k.Doc, props: Dropdown_Item_Props) -> string {
	danger_class := props.danger ? " dropdown__item--danger" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(doc, "dropdown__item%s%s%s", danger_class, separator, props.class)
}
