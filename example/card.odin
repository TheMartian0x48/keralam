package main

import c "../component"
import k "kashmir:."

// An inline SVG, so the demo makes no external request.
CARD_PLACEHOLDER_IMAGE :: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 180"><rect width="320" height="180" fill="%23dbeafe"/><circle cx="240" cy="55" r="22" fill="%2393c5fd"/><path d="M0 180l90-80 70 60 50-40 110 60z" fill="%2360a5fa"/></svg>`

// A header or footer is a node, and a node has one parent, so each card builds its own.
card_title :: proc(doc: ^k.Doc) -> k.Node_Id {return k.text(doc, "Card title")}
card_footer :: proc(doc: ^k.Doc) -> k.Node_Id {return k.text(doc, "Updated today")}

demo_card :: proc(doc: ^k.Doc) -> k.Node_Id {
	body :: proc(doc: ^k.Doc) -> k.Node_Id {
		return k.text(
			doc,
			"Cards group related information. This one has a few lines of body text to show how the content area flows.",
		)
	}

	variants := make([dynamic]k.Node_Id, 0, len(c.Card_Variant), context.temp_allocator)
	for variant in c.Card_Variant {
		append(
			&variants,
			c.card(doc, {variant = variant, header = card_title(doc), footer = card_footer(doc)}, body(doc)),
		)
	}

	return k.div(
		doc,
		{},
		demo_section(doc, "Variants (outlined, flat)", ..variants[:]),
		demo_section(
			doc,
			"Cover image",
			c.card(
				doc,
				{
					image = CARD_PLACEHOLDER_IMAGE,
					image_alt = "A landscape illustration",
					header = card_title(doc),
					footer = card_footer(doc),
				},
				body(doc),
			),
			c.card(
				doc,
				{variant = .flat, image = CARD_PLACEHOLDER_IMAGE, header = card_title(doc)},
				body(doc),
			),
		),
		demo_section(
			doc,
			"Body only, and header only",
			c.card(doc, {}, body(doc)),
			c.card(doc, {variant = .flat, header = card_title(doc)}, body(doc)),
		),
		demo_section(
			doc,
			"Whole card as a link (wrap it yourself)",
			k.a(doc, {href = "/component/button"}, c.card(doc, {header = card_title(doc)}, body(doc))),
		),
	)
}
