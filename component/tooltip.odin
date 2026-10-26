package component

import k "kashmir:."

// ---------- constants ----------

TOOLTIP_CONTENT_BYTES_MAX :: 512
TOOLTIP_WALK_MAX :: 4096 // nodes visited looking for the trigger's aria-describedby

Tooltip_Position :: enum u8 {
	top,
	bottom,
	left,
	right,
}

@(private)
tooltip_position_names := [Tooltip_Position]string {
	.top    = "top",
	.bottom = "bottom",
	.left   = "left",
	.right  = "right",
}

// ---------- props ----------

// What a trigger needs to be described by its tooltip. tooltip makes this and passes it to the
// trigger proc.
Tooltip_Wiring :: struct {
	id: string, // the tooltip's id: put it in the trigger's aria-describedby
}

// A short text that appears beside an element on hover or keyboard focus.
//
//   save_trigger :: proc(doc: ^k.Doc, w: c.Tooltip_Wiring) -> k.Node_Id {
//       return c.button(doc, {attributes = {k.attribute("aria-describedby", w.id)}}, k.text(doc, "Save"))
//   }
//   c.tooltip(doc, {content = "Saves a draft", trigger = save_trigger})
//
// The trigger is a proc, not a node, for the reason form_field's control is: its
// aria-describedby needs the tooltip's id, and a finished node cannot be given an attribute.
// tooltip makes the id, calls your proc, and checks that the trigger really carries it. A proc
// cannot capture variables, so a trigger that needs data reads it from somewhere the proc can
// reach.
//
// The trigger must be focusable (a button or a link), or a keyboard user never sees the text.
// Escape hides the tooltip while the trigger keeps focus, and it stays open while the pointer
// is over it (needs keralam.js; without script the tooltip still opens, it just can not be
// dismissed). The tooltip does not move to stay on screen: pick a position with room, and
// long text wraps at 20rem. Anything richer than a sentence is not a tooltip.
//
// Asserts: content non-empty and at most TOOLTIP_CONTENT_BYTES_MAX bytes; a trigger given; and
// the trigger carries aria-describedby with the id it was given (see tooltip_describes).
Tooltip_Props :: struct {
	using base: k.Base, // id (generated when empty), class, style, attributes: all on the wrapper
	content:    string, // the text; plain, escaped on render
	position:   Tooltip_Position,
	trigger:    proc(doc: ^k.Doc, wiring: Tooltip_Wiring) -> k.Node_Id,
}

// ---------- procs ----------

// Composition order: tooltip tooltip--{position} [class]
tooltip :: proc(doc: ^k.Doc, props: Tooltip_Props) -> k.Node_Id {
	assert(props.content != "", "tooltip needs content")
	assert(
		len(props.content) <= TOOLTIP_CONTENT_BYTES_MAX,
		"tooltip content exceeds TOOLTIP_CONTENT_BYTES_MAX",
	)
	assert(props.trigger != nil, "tooltip needs a trigger")

	// Unique within a page without global state: node counts only grow.
	wrapper_id := props.id != "" ? props.id : k.doc_format(doc, "tt%d", doc.nodes_count)
	content_id := k.doc_format(doc, "%s-content", wrapper_id)

	trigger := props.trigger(doc, {id = content_id})
	assert(
		tooltip_describes(doc, trigger, content_id),
		"tooltip trigger does not carry aria-describedby with the id it was given (use wiring.id)",
	)

	// k.span copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(attributes_count + 2 <= ATTRIBUTES_MAX, "tooltip attributes exceeds ATTRIBUTES_MAX")
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute("data-controller", "keralam-tooltip")
	attributes[attributes_count + 1] = k.attribute("data-action", "keydown->keralam-tooltip#dismiss")
	attributes_count += 2

	base := props.base
	base.id = wrapper_id
	base.class = tooltip_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.span(
		doc,
		base,
		trigger,
		k.span(
			doc,
			{id = content_id, class = "tooltip__content", attributes = {k.role("tooltip")}},
			k.text(doc, props.content),
		),
	)
}

// Whether `root` or a node below it has aria-describedby naming `id` (the attribute may hold
// several ids). The subtree is searched depth first with a fixed stack and a fixed visit limit.
@(private)
tooltip_describes :: proc(doc: ^k.Doc, root: k.Node_Id, id: string) -> bool {
	stack: [TOOLTIP_WALK_MAX]k.Node_Id
	stack_count := 0
	stack[stack_count] = root
	stack_count += 1

	for _ in 0 ..< TOOLTIP_WALK_MAX {
		if stack_count == 0 do return false
		stack_count -= 1
		current := stack[stack_count]
		if current == k.NODE_NONE do continue

		node := doc.nodes[current]
		for attribute in doc.attributes[node.attributes.start:][:node.attributes.count] {
			if attribute.key == "aria-describedby" && tooltip_token_found(attribute.value, id) do return true
		}
		for child := node.first_child; child != k.NODE_NONE; child = doc.nodes[child].next {
			if stack_count == TOOLTIP_WALK_MAX do return false
			stack[stack_count] = child
			stack_count += 1
		}
	}
	return false
}

// Whether `token` is one of the space-separated words of `value`.
@(private)
tooltip_token_found :: proc(value, token: string) -> bool {
	start := 0
	for index in 0 ..= len(value) {
		if index == len(value) || value[index] == ' ' {
			if index > start && value[start:index] == token do return true
			start = index + 1
		}
	}
	return false
}

@(private)
tooltip_class :: proc(doc: ^k.Doc, props: Tooltip_Props) -> string {
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"tooltip tooltip--%s%s%s",
		tooltip_position_names[props.position],
		separator,
		props.class,
	)
}
