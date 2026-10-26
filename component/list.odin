package component

import k "kashmir:."

// ---------- enums ----------

// What stands in front of each item. Plain is first so the zero value is a list with no
// markers. This is Go's `Variant`, renamed because Variant in this library means colour.
List_Marker :: enum u8 {
	plain, // nothing in front of the item
	bulleted, // a bullet
	numbered, // 1. 2. 3., on an <ol>
	icon, // an icon you give each item
}

@(private)
list_marker_names := [List_Marker]string {
	.plain    = "plain",
	.bulleted = "bulleted",
	.numbered = "numbered",
	.icon     = "icon",
}

// ---------- constants ----------

LIST_ITEMS_MAX :: 1000
LIST_EXTRAS_MAX :: 1 // aria-label

// ---------- props ----------

// One row.
List_Item :: struct {
	using base: k.Base, // id, class (appended after list__item), style, attributes
	content:    k.Node_Id, // what the row shows; a node, so it can hold links and bold text
	icon:       Maybe(k.Node_Id), // required for the Icon marker, refused for the others
	active:     bool, // highlights the row as the current one
	disabled:   bool, // mutes the row and marks it aria-disabled
}

// A vertical list of rows, on a <ul>, or on an <ol> when numbered.
//
//   list(doc, {marker = .Bulleted, items = {{content = k.text(doc, "First")}, {content = k.text(doc, "Second")}}})
//
// The rows are data, not child nodes, so the list can check them as a set. A node can only
// have one parent: build every content and icon fresh, and reusing one asserts.
//
// Asserts:
//   at least one item, and at most LIST_ITEMS_MAX
//   an Icon list gives every item an icon, and any other marker gives none (an icon in a
//     Plain list is ignored, and a missing one leaves a blank gap)
//   an item is not both active and disabled
//
// Active is a look only: it colours the row, and tells a screen reader nothing.
List_Props :: struct {
	using base: k.Base, // id, class (appended after the generated classes), style, attributes
	marker:     List_Marker,
	size:       Size, // see component.odin
	divided:    bool, // a rule between rows
	aria_label: string, // names the list for assistive technology
	items:      []List_Item,
}

// ---------- procs ----------

// Composition order: list list--{marker} list--{size} [list--divided] [class]
list :: proc(doc: ^k.Doc, props: List_Props) -> k.Node_Id {
	item_count := len(props.items)
	assert(item_count > 0, "list has no items")
	assert(item_count <= LIST_ITEMS_MAX, "list items exceeds LIST_ITEMS_MAX")

	has_icon_marker := props.marker == .icon
	for item in props.items {
		_, has_icon := item.icon.?
		assert(
			has_icon == has_icon_marker,
			has_icon_marker ? "icon list item has no icon" : "list item has an icon but the marker is not Icon",
		)
		assert(!(item.active && item.disabled), "list item is both active and disabled")
	}

	// k.ul and k.ol copy the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + LIST_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"list attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}

	rows: [LIST_ITEMS_MAX]k.Node_Id
	for item, index in props.items {
		rows[index] = list_item(doc, item)
	}

	base := props.base
	base.class = list_class(doc, props)
	base.attributes = attributes[:attributes_count]

	if props.marker == .numbered {
		return k.ol(doc, {base = base}, ..rows[:item_count])
	}
	return k.ul(doc, base, ..rows[:item_count])
}

@(private)
list_item :: proc(doc: ^k.Doc, item: List_Item) -> k.Node_Id {
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(item.attributes)
	assert(attributes_count + 1 <= ATTRIBUTES_MAX, "list item attributes exceeds ATTRIBUTES_MAX")
	copy(attributes[:], item.attributes)
	if item.disabled {
		attributes[attributes_count] = k.attribute("aria-disabled", "true")
		attributes_count += 1
	}

	icon_node := k.NODE_NONE
	if icon, has_icon := item.icon.?; has_icon {
		icon_node = k.span(
			doc,
			{class = "list__icon", attributes = {k.attribute("aria-hidden", "true")}},
			icon,
		)
	}

	base := item.base
	base.class = list_item_class(doc, item)
	base.attributes = attributes[:attributes_count]
	return k.li(
		doc,
		{base = base},
		icon_node,
		k.span(doc, {class = "list__content"}, item.content),
	)
}

@(private)
list_class :: proc(doc: ^k.Doc, props: List_Props) -> string {
	divided_class := props.divided ? " list--divided" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"list list--%s list--%s%s%s%s",
		list_marker_names[props.marker],
		size_names[props.size],
		divided_class,
		separator,
		props.class,
	)
}

@(private)
list_item_class :: proc(doc: ^k.Doc, item: List_Item) -> string {
	active_class := item.active ? " list__item--active" : ""
	disabled_class := item.disabled ? " list__item--disabled" : ""
	separator := item.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"list__item%s%s%s%s",
		active_class,
		disabled_class,
		separator,
		item.class,
	)
}
