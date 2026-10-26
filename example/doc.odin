package main

// Helpers for the documentation layout every component page shares:
//
//   section.doc-section
//     header.doc-section__header   title and a description
//     div.doc-demo > div.doc-demo__preview
//       div.doc-demo__group        a titled example with its own description
//         div.doc-demo__list       the examples themselves

import k "kashmir:."

// The paragraph under a page title. Mix k.text and doc_code in it.
doc_section_description :: proc(doc: ^k.Doc, parts: ..k.Node_Id) -> k.Node_Id {
	return k.p(doc, {class = "doc-section__description"}, ..parts)
}

// Inline code inside a description.
doc_code :: proc(doc: ^k.Doc, text: string) -> k.Node_Id {
	return k.code(doc, {}, k.text(doc, text))
}

// A paragraph for a group; mix k.text and doc_code in it.
doc_description :: proc(doc: ^k.Doc, parts: ..k.Node_Id) -> k.Node_Id {
	return k.p(doc, {class = "doc-demo__description"}, ..parts)
}

// A titled example. content is placed after the description.
doc_group :: proc(
	doc: ^k.Doc,
	title: string,
	description: k.Node_Id,
	content: ..k.Node_Id,
) -> k.Node_Id {
	children := make([dynamic]k.Node_Id, 0, len(content) + 2, context.temp_allocator)
	append(&children, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	append(&children, description)
	append(&children, ..content)
	return k.div(doc, {class = "doc-demo__group"}, ..children[:])
}

// The row the examples sit in. Pass class "doc-demo__list--column" to stack them.
doc_list :: proc(doc: ^k.Doc, props: k.Base, children: ..k.Node_Id) -> k.Node_Id {
	base := props
	base.class =
		props.class != "" ? k.doc_format(doc, "doc-demo__list %s", props.class) : "doc-demo__list"
	return k.div(doc, base, ..children)
}
