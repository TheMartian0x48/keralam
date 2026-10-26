package component

import k "kashmir:."

// ---------- enums ----------

Accordion_Variant :: enum u8 {
	basic, // default style with minimal dividers
	bordered, // grouped style with full outer borders
	flush, // minimalist style without outer borders
}

@(private)
accordion_variant_names := [Accordion_Variant]string {
	.basic    = "basic",
	.bordered = "bordered",
	.flush    = "flush",
}

// ---------- constants ----------

ACCORDION_ITEMS_MAX :: 256

// ---------- props ----------

// One collapsible section.
Accordion_Item :: struct {
	using base: k.Base, // id, class (appended after accordion__item), style, attributes

	// content
	title:      string,
	content:    string, // plain text, escaped on render

	// appearance
	icon:       Maybe(k.Node_Id), // replaces the chevron on this item; nil = the chevron

	// state
	open:       bool, // initially expanded
}

// A vertically stacked set of headings that expand and collapse. Built on the
// native <details> and <summary> elements, so keyboard support comes for free.
//
//   accordion(doc, {items = {{title = "One", content = "First"}, {title = "Two", content = "Second", open = true}}})
//
// An item's icon is a node you build first. A node can only have one parent, so give
// every item its own: one icon node shared by two items asserts.
Accordion_Props :: struct {
	using base: k.Base,

	// content
	items:      []Accordion_Item,

	// appearance
	variant:    Accordion_Variant,
}

// ---------- procs ----------

// Composition order: accordion accordion--{variant} [class]
accordion :: proc(doc: ^k.Doc, props: Accordion_Props) -> k.Node_Id {
	assert(len(props.items) <= ACCORDION_ITEMS_MAX, "accordion items exceeds ACCORDION_ITEMS_MAX")

	items: [ACCORDION_ITEMS_MAX]k.Node_Id
	for item, index in props.items {
		items[index] = accordion_item(doc, item)
	}

	base := props.base
	base.class = accordion_class(doc, props)
	return k.div(doc, base, ..items[:len(props.items)])
}

@(private)
accordion_item :: proc(doc: ^k.Doc, item: Accordion_Item) -> k.Node_Id {
	icon_node, has_icon := item.icon.?
	if !has_icon do icon_node = icon(doc, {name = .caret_down, size = .small})

	base := item.base
	base.class =
		item.class != "" ? k.doc_format(doc, "accordion__item %s", item.class) : "accordion__item"

	return k.details(
		doc,
		{base = base, open = item.open},
		k.summary(
			doc,
			{class = "accordion__summary"},
			k.span(doc, {class = "accordion__title"}, k.text(doc, item.title)),
			k.div(
				doc,
				{class = "accordion__icon", attributes = {k.attribute("aria-hidden", "true")}},
				icon_node,
			),
		),
		k.div(
			doc,
			{class = "accordion__content", attributes = {k.role("region")}},
			k.div(doc, {class = "accordion__body"}, k.text(doc, item.content)),
		),
	)
}

@(private)
accordion_class :: proc(doc: ^k.Doc, props: Accordion_Props) -> string {
	variant := accordion_variant_names[props.variant]
	if props.class == "" do return k.doc_format(doc, "accordion accordion--%s", variant)
	return k.doc_format(doc, "accordion accordion--%s %s", variant, props.class)
}
