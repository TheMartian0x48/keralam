package component

import k "kashmir:."

// ---------- constants ----------

TIMELINE_ITEMS_MAX :: 256
TIMELINE_EXTRAS_MAX :: 1 // aria-label

Timeline_Layout :: enum u8 {
	default, // a line down the left, events to its right
	alternate, // a line down the middle, events on alternating sides (from 768px wide)
	compact, // title and time only, for dense feeds
}

@(private)
timeline_layout_names := [Timeline_Layout]string {
	.default   = "default",
	.alternate = "alternate",
	.compact   = "compact",
}

// ---------- props ----------

// One event.
//
// An item is completed or active, not both, and a coloured variant belongs to neither: those
// two own the marker colour. icon replaces the check a completed item would show, so it cannot
// be combined with completed.
Timeline_Item :: struct {
	using base: k.Base, // id, class (appended after the generated ones), style, attributes
	title:      string, // required
	time:       string, // what is shown, e.g. "2 hours ago"
	datetime:   string, // the machine-readable value of time; optional, needs time
	body:       Maybe(k.Node_Id), // the details, built first; refused in a compact timeline
	icon:       Maybe(k.Node_Id), // inside the marker; build one per item
	variant:    Maybe(Variant), // marker colour; nil = neutral
	active:     bool, // the current event
	completed:  bool, // a finished event, with a check in the marker
}

// A vertical list of events in order.
//
//   timeline(doc, {items = {{title = "Created", time = "Jan 1", completed = true}, {title = "Review", active = true}}})
//
// The marker is decoration, so its meaning is spoken instead: a completed or active item is
// followed by hidden text such as "(completed)". The words are props so they can be translated.
//
// Asserts: 1 to TIMELINE_ITEMS_MAX items; every title non-empty; per item, the combinations
// listed on Timeline_Item; datetime only with time; a body only outside the compact layout.
Timeline_Props :: struct {
	using base:      k.Base, // id, class (appended after the generated ones), style, attributes
	items:           []Timeline_Item,
	layout:          Timeline_Layout,
	aria_label:      string, // default "Timeline"
	completed_label: string, // default "(completed)"
	current_label:   string, // default "(current)"
}

// ---------- procs ----------

// Composition order: timeline timeline--{layout} [class]
timeline :: proc(doc: ^k.Doc, props: Timeline_Props) -> k.Node_Id {
	items_count := len(props.items)
	assert(items_count >= 1, "timeline needs at least one item")
	assert(items_count <= TIMELINE_ITEMS_MAX, "timeline items exceeds TIMELINE_ITEMS_MAX")

	completed_label := props.completed_label != "" ? props.completed_label : "(completed)"
	current_label := props.current_label != "" ? props.current_label : "(current)"

	nodes: [TIMELINE_ITEMS_MAX]k.Node_Id
	for item, index in props.items {
		nodes[index] = timeline_item(
			doc,
			item,
			props.layout,
			item.completed ? completed_label : current_label,
		)
	}

	// k.ol copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + TIMELINE_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"timeline attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute(
		"aria-label",
		props.aria_label != "" ? props.aria_label : "Timeline",
	)
	attributes_count += 1

	base := props.base
	base.class = timeline_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.ol(doc, {base = base}, ..nodes[:items_count])
}

@(private)
timeline_item :: proc(
	doc: ^k.Doc,
	item: Timeline_Item,
	layout: Timeline_Layout,
	state_label: string,
) -> k.Node_Id {
	assert(item.title != "", "timeline item needs a title")
	assert(!(item.completed && item.active), "timeline item cannot be completed and active")
	assert(
		item.variant == nil || !(item.completed || item.active),
		"timeline item variant is set, but completed and active own the marker colour",
	)
	assert(
		!(item.completed && item.icon != nil),
		"timeline item icon replaces the check of a completed item",
	)
	assert(item.datetime == "" || item.time != "", "timeline item datetime needs a time")
	assert(
		item.body == nil || layout != .compact,
		"timeline item body is not shown in the compact layout",
	)

	marker_content := k.NODE_NONE
	if icon_node, found := item.icon.?; found {
		marker_content = icon_node
	} else if item.completed {
		marker_content = icon(doc, {name = .check, size = .small})
	}
	marker := k.div(
		doc,
		{class = "timeline__marker", attributes = {k.attribute("aria-hidden", "true")}},
		marker_content,
	)

	title_children: [2]k.Node_Id
	title_children[0] = k.text(doc, item.title)
	title_count := 1
	if item.completed || item.active {
		title_children[1] = k.span(
			doc,
			{class = "visually-hidden"},
			k.text(doc, k.doc_format(doc, " %s", state_label)),
		)
		title_count = 2
	}
	title := k.span(doc, {class = "timeline__title"}, ..title_children[:title_count])

	time_node :=
		item.time != "" ? k.time(doc, {base = {class = "timeline__time"}, datetime = item.datetime}, k.text(doc, item.time)) : k.NODE_NONE
	header := k.div(doc, {class = "timeline__header"}, title, time_node)

	content_children: [2]k.Node_Id
	content_children[0] = header
	content_count := 1
	if body, found := item.body.?; found {
		content_children[1] = k.div(doc, {class = "timeline__body"}, body)
		content_count = 2
	}
	content := k.div(doc, {class = "timeline__content"}, ..content_children[:content_count])

	base := item.base
	base.class = timeline_item_class(doc, item)
	return k.li(doc, {base = base}, marker, content)
}

@(private)
timeline_class :: proc(doc: ^k.Doc, props: Timeline_Props) -> string {
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"timeline timeline--%s%s%s",
		timeline_layout_names[props.layout],
		separator,
		props.class,
	)
}

@(private)
timeline_item_class :: proc(doc: ^k.Doc, item: Timeline_Item) -> string {
	state_class := ""
	if item.completed do state_class = " timeline__item--completed"
	if item.active do state_class = " timeline__item--active"
	variant_class := ""
	if variant, found := item.variant.?; found {
		variant_class = k.doc_format(doc, " timeline__item--%s", variant_names[variant])
	}
	separator := item.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"timeline__item%s%s%s%s",
		state_class,
		variant_class,
		separator,
		item.class,
	)
}
