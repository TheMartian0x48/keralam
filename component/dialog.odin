package component

import k "kashmir:."

// ---------- enums ----------

// Maximum width of the dialog. medium is first so the zero value is the stock width.
Dialog_Size :: enum u8 {
	medium, // ~32rem
	small, // ~24rem
	large, // ~42rem
	extra_large, // ~56rem
}

@(private)
dialog_size_names := [Dialog_Size]string {
	.medium      = "md",
	.small       = "sm",
	.large       = "lg",
	.extra_large = "xl",
}

// ---------- constants ----------

DIALOG_FOOTER_CHILDREN_MAX :: 8 // a row of actions, not a toolbar
DIALOG_EXTRAS_MAX :: 5 // aria-labelledby, aria-describedby, aria-modal, data-controller, plus headroom

// ---------- props ----------

// A modal window on the native <dialog> element: the browser handles focus
// trapping, the backdrop and Escape.
//
//   dialog(doc, {id = "confirm", title = "Confirm"}, k.text(doc, "Proceed?"))
//
// A dialog stays hidden until opened. Open it with no script from any button:
//
//   button(doc, {attributes = {k.attribute("command", "show-modal"), k.attribute("commandfor", "confirm")}}, ...)
//
// (the declarative command attributes need Chrome 135, Safari 18.4 or Firefox 144).
// The close button works through the keralam-dialog controller in keralam.js.
Dialog_Props :: struct {
	using base:  k.Base, // id (generated when empty), class (appended after the generated classes), style, attributes

	// content
	title:       string, // heading at the top, and the dialog's accessible name
	description: string, // optional detail text, wired up as aria-describedby

	// appearance
	size:        Dialog_Size,
}

// ---------- procs ----------

// Composition order: dialog dialog--{size} [class]
dialog :: proc(doc: ^k.Doc, props: Dialog_Props, children: ..k.Node_Id) -> k.Node_Id {
	// Unique within a page without global state: node counts only grow.
	dialog_id := props.id != "" ? props.id : k.doc_format(doc, "dlg%d", doc.nodes_count)
	title_id := k.doc_format(doc, "%s-title", dialog_id)
	description_id := k.doc_format(doc, "%s-desc", dialog_id)

	// k.dialog copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DIALOG_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"dialog attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.attribute("aria-labelledby", title_id)
	attributes_count += 1
	if props.description != "" {
		attributes[attributes_count] = k.attribute("aria-describedby", description_id)
		attributes_count += 1
	}
	attributes[attributes_count] = k.attribute("aria-modal", "true")
	attributes_count += 1
	attributes[attributes_count] = k.attribute("data-controller", "keralam-dialog")
	attributes_count += 1

	close_button := button(
		doc,
		{
			class = "dialog__close",
			variant = .secondary,
			shape = .text,
			size = .small,
			attributes = {
				k.attribute("aria-label", "Close dialog"),
				k.attribute("data-action", "keralam-dialog#close"),
			},
		},
		icon(doc, {name = .x, size = .small}),
	)

	header := k.div(
		doc,
		{class = "dialog__header"},
		k.h3(doc, {id = title_id, class = "dialog__title"}, k.text(doc, props.title)),
		k.div(doc, {class = "dialog__close-wrapper"}, close_button),
	)

	description_node := k.NODE_NONE
	if props.description != "" {
		description_node = k.p(
			doc,
			{id = description_id, class = "dialog__description"},
			k.text(doc, props.description),
		)
	}

	base := props.base
	base.id = dialog_id
	base.class = dialog_class(doc, props)
	base.attributes = attributes[:attributes_count]

	return k.dialog(
		doc,
		{base = base},
		k.div(
			doc,
			{class = "dialog__content"},
			header,
			description_node,
			k.div(doc, {class = "dialog__body"}, ..children),
		),
	)
}

// A row for the dialog's primary and secondary actions.
dialog_footer :: proc(doc: ^k.Doc, props: k.Base, children: ..k.Node_Id) -> k.Node_Id {
	assert(len(children) > 0, "dialog footer has no actions")
	assert(len(children) <= DIALOG_FOOTER_CHILDREN_MAX, "dialog footer children exceeds DIALOG_FOOTER_CHILDREN_MAX")
	base := props
	base.class =
		props.class != "" ? k.doc_format(doc, "dialog__footer %s", props.class) : "dialog__footer"
	return k.div(doc, base, ..children)
}

@(private)
dialog_class :: proc(doc: ^k.Doc, props: Dialog_Props) -> string {
	size := dialog_size_names[props.size]
	if props.class == "" do return k.doc_format(doc, "dialog dialog--%s", size)
	return k.doc_format(doc, "dialog dialog--%s %s", size, props.class)
}
