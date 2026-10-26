package main

import c "../component"
import clock "core:time"
import k "kashmir:."

// 17 May 2024, 14:30:00 UTC: a fixed instant, so every reader sees the same moment.
time_instant :: proc() -> clock.Time {
	moment, _ := clock.datetime_to_time(2024, 5, 17, 14, 30, 0)
	return moment
}

// 31 December 2024, 23:30:00 UTC: already the next day in India and Japan.
time_instant_late :: proc() -> clock.Time {
	moment, _ := clock.datetime_to_time(2024, 12, 31, 23, 30, 0)
	return moment
}

time_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "time"),
		k.text(
			doc,
			" is a semantic <time> element. Its datetime attribute is always the instant in UTC. Without script the text is an English rendering in UTC; with keralam.js it is rewritten in the reader's locale and timezone, so two readers can see different text. Use Iso or utc to fix it.",
		),
	)
}

time_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}

demo_time :: proc(doc: ^k.Doc) -> k.Node_Id {
	formats := make([dynamic]k.Node_Id, 0, len(c.Time_Format), context.temp_allocator)
	for format in c.Time_Format {
		append(
			&formats,
			k.div(
				doc,
				{},
				k.text(doc, k.doc_format(doc, "%v: ", format)),
				c.time(
					doc,
					{
						id = k.doc_format(doc, "time-format-%d", int(format)),
						value = time_instant(),
						format = format,
					},
				),
			),
		)
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		time_section(
			doc,
			"Formats",
			"One instant in each format. Iso is never rewritten.",
			doc_list(doc, {class = "doc-demo__list--column"}, ..formats[:]),
		),
		time_section(
			doc,
			"The reader's zone, and UTC",
			"31 December 2024, 23:30 UTC. In the reader's zone it can be the next day; with utc the text is the same for everyone.",
			doc_list(
				doc,
				{class = "doc-demo__list--column"},
				k.div(
					doc,
					{},
					k.text(doc, "Reader's zone: "),
					c.time(
						doc,
						{id = "time-local", value = time_instant_late(), format = .date_time},
					),
				),
				k.div(
					doc,
					{},
					k.text(doc, "UTC: "),
					c.time(
						doc,
						{
							id = "time-utc",
							value = time_instant_late(),
							format = .date_time,
							utc = true,
						},
					),
				),
			),
		),
		time_section(
			doc,
			"In running text",
			"A date alone shows the full moment as its hover title.",
			k.p(
				doc,
				{},
				k.text(doc, "The release was published on "),
				c.time(doc, {id = "time-inline", value = time_instant(), format = .date}),
				k.text(doc, "."),
			),
		),
	)
}
