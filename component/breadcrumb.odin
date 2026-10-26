package component

import k "kashmir:."

// ---------- constants ----------

BREADCRUMB_ITEMS_MAX :: 64
BREADCRUMB_ATTRIBUTES_MAX :: 16 // an item's own attributes plus aria-current

// ---------- props ----------

// One step in the trail. id and attributes go on the link or text; class goes on
// the list item, matching the Go API.
Breadcrumb_Item :: struct {
	using base: k.Base,
	label:      string,
	href:       string, // empty for a plain text item; ignored when current
	current:    bool, // the active page: rendered as text with aria-current="page"
}

// A navigation trail showing where the page sits in the site.
//
//   breadcrumb(doc, {items = {{label = "Home", href = "/"}, {label = "Users", href = "/users"}, {label = "Ada", current = true}}})
//
// The separator is drawn by CSS from each item's data-separator, so any string
// works, and it is marked decorative so screen readers do not read it out.
Breadcrumb_Props :: struct {
	using base: k.Base, // id, class (appended after "breadcrumb"), style, attributes
	items:      []Breadcrumb_Item,
	separator:  string, // defaults to "/"
	aria_label: string, // defaults to "Breadcrumb"
}

// ---------- procs ----------

breadcrumb :: proc(doc: ^k.Doc, props: Breadcrumb_Props) -> k.Node_Id {
	assert(
		len(props.items) <= BREADCRUMB_ITEMS_MAX,
		"breadcrumb items exceeds BREADCRUMB_ITEMS_MAX",
	)

	current_count := 0
	for item in props.items do current_count += item.current ? 1 : 0
	assert(current_count <= 1, "breadcrumb has more than one current item")

	// Cloned once: the borrowed string would otherwise have to outlive render for every item.
	separator := k.doc_format(doc, "%s", props.separator != "" ? props.separator : "/")

	nodes: [BREADCRUMB_ITEMS_MAX]k.Node_Id
	for item, index in props.items {
		nodes[index] = breadcrumb_item(doc, item, separator)
	}

	base := props.base
	base.class = props.class != "" ? k.doc_format(doc, "breadcrumb %s", props.class) : "breadcrumb"
	nav_attributes: [ATTRIBUTES_MAX]k.Attribute
	nav_attributes_count := len(props.attributes)
	assert(
		nav_attributes_count + 1 <= ATTRIBUTES_MAX,
		"breadcrumb attributes exceeds ATTRIBUTES_MAX",
	)
	copy(nav_attributes[:], props.attributes)
	nav_attributes[nav_attributes_count] = k.attribute(
		"aria-label",
		props.aria_label != "" ? props.aria_label : "Breadcrumb",
	)
	nav_attributes_count += 1
	base.attributes = nav_attributes[:nav_attributes_count]

	return k.nav(
		doc,
		base,
		k.ol(doc, {base = {class = "breadcrumb__list"}}, ..nodes[:len(props.items)]),
	)
}

@(private)
breadcrumb_item :: proc(doc: ^k.Doc, item: Breadcrumb_Item, separator: string) -> k.Node_Id {
	assert(link_href_safe(item.href), "breadcrumb href uses a script scheme")

	// k.a and k.span copy the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [BREADCRUMB_ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(item.attributes)
	assert(
		attributes_count + 1 <= BREADCRUMB_ATTRIBUTES_MAX,
		"breadcrumb item attributes exceeds BREADCRUMB_ATTRIBUTES_MAX",
	)
	copy(attributes[:], item.attributes)

	content: k.Node_Id
	if item.href != "" && !item.current {
		content = k.a(
			doc,
			{
				base = {
					id = item.id,
					class = "breadcrumb__link",
					attributes = attributes[:attributes_count],
				},
				href = item.href,
			},
			k.text(doc, item.label),
		)
	} else {
		if item.current {
			attributes[attributes_count] = k.attribute("aria-current", "page")
			attributes_count += 1
		}
		content = k.span(
			doc,
			{id = item.id, class = "breadcrumb__text", attributes = attributes[:attributes_count]},
			k.text(doc, item.label),
		)
	}

	item_class := item.current ? "breadcrumb__item breadcrumb__item--current" : "breadcrumb__item"
	if item.class != "" do item_class = k.doc_format(doc, "%s %s", item_class, item.class)

	return k.li(
		doc,
		{base = {class = item_class, attributes = {k.attribute("data-separator", separator)}}},
		content,
	)
}
