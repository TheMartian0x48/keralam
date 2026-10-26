package component

import k "kashmir:."

// ---------- enums ----------

Card_Variant :: enum u8 {
	outlined, // flat with a border (default)
	flat, // no border, subtle background
}

@(private)
card_variant_names := [Card_Variant]string {
	.outlined = "outlined",
	.flat     = "flat",
}

// ---------- constants ----------

CARD_CHILDREN_MAX :: 64

// ---------- props ----------

// A container for related content, with an optional cover image, header and footer.
//
//   card(doc, {header = k.text(doc, "Title"), footer = k.text(doc, "Updated today")}, k.text(doc, "Main content."))
//
// Header and footer are nodes you build first. A node can only have one parent, so build
// a fresh one for every card: reusing one props struct for two cards asserts. The header
// is wrapped in an h3. Nil means no header or footer.
//
// To make a whole card a link, wrap it in an anchor yourself.
Card_Props :: struct {
	using base: k.Base, // id, class (appended after the generated classes), style, attributes

	// appearance
	variant:    Card_Variant,

	// media
	image:      string, // cover image URL
	image_alt:  string, // empty marks the image as decorative

	// sections
	header:     Maybe(k.Node_Id), // nil = no header; a Node_Id of 0 is a real node, so it needs Maybe
	footer:     Maybe(k.Node_Id), // nil = no footer
}

// ---------- procs ----------

// Composition order: card card--{variant} [class]
card :: proc(doc: ^k.Doc, props: Card_Props, children: ..k.Node_Id) -> k.Node_Id {
	assert(len(children) <= CARD_CHILDREN_MAX, "card children exceeds CARD_CHILDREN_MAX")
	// An image with no address renders a broken picture; an alt with no image is lost.
	assert(props.image != "" || props.image_alt == "", "card has image_alt but no image")

	media := k.NODE_NONE
	if props.image != "" {
		media = k.div(
			doc,
			{class = "card__media"},
			k.img(doc, {src = props.image, alt = props.image_alt, loading = .lazy}),
		)
	}

	header := k.NODE_NONE
	if header_node, has_header := props.header.?; has_header {
		header = k.div(
			doc,
			{class = "card__header"},
			k.h3(doc, {class = "card__title"}, header_node),
		)
	}

	footer := k.NODE_NONE
	if footer_node, has_footer := props.footer.?; has_footer {
		footer = k.div(doc, {class = "card__footer"}, footer_node)
	}

	base := props.base
	base.class = card_class(doc, props)
	return k.article(
		doc,
		base,
		media,
		header,
		k.div(doc, {class = "card__content"}, ..children),
		footer,
	)
}

@(private)
card_class :: proc(doc: ^k.Doc, props: Card_Props) -> string {
	variant := card_variant_names[props.variant]
	if props.class == "" do return k.doc_format(doc, "card card--%s", variant)
	return k.doc_format(doc, "card card--%s %s", variant, props.class)
}
