package main

import c "../component"
import k "kashmir:."

timeline_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		doc_code(doc, "timeline"),
		k.text(
			doc,
			" is a vertical list of events. The marker is decoration, so a completed or current event is followed by hidden text. Combinations that contradict each other, such as completed and active, or a body in the compact layout, assert.",
		),
	)
}

timeline_section :: proc(doc: ^k.Doc, title, note: string, content: k.Node_Id) -> k.Node_Id {
	return k.div(
		doc,
		{class = "doc-demo__group"},
		k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)),
		doc_description(doc, k.text(doc, note)),
		content,
		c.divider(doc, {}),
	)
}


demo_timeline :: proc(doc: ^k.Doc) -> k.Node_Id {
	history := [?]c.Timeline_Item {
		{
			title = "Created",
			time = "Jan 1",
			datetime = "2026-01-01",
			completed = true,
			body = k.text(doc, "Initial version"),
		},
		{
			title = "Reviewed",
			time = "Jan 5",
			datetime = "2026-01-05",
			completed = true,
			body = k.text(doc, "Two rounds of comments"),
		},
		{title = "Released", time = "Today", active = true, body = k.text(doc, "Going out now")},
		{title = "Retired", time = "Planned"},
	}
	compact := [?]c.Timeline_Item {
		{title = "Signed in", time = "2 minutes ago"},
		{title = "Changed password", time = "1 hour ago"},
		{title = "Exported report", time = "Yesterday", completed = true},
	}
	alternate := [?]c.Timeline_Item {
		{
			title = "Founded",
			time = "2019",
			completed = true,
			body = k.text(doc, "Three people and an idea"),
		},
		{
			title = "First release",
			time = "2021",
			completed = true,
			body = k.text(doc, "Shipped to ten customers"),
		},
		{
			title = "Growth",
			time = "2024",
			active = true,
			body = k.text(doc, "Opening a second office"),
		},
		{title = "Next", time = "2026", body = k.text(doc, "Still to come")},
	}
	colours := [?]c.Timeline_Item {
		{title = "Primary", variant = c.Variant.primary},
		{title = "Secondary", variant = c.Variant.secondary},
		{title = "Success", variant = c.Variant.success},
		{title = "Warning", variant = c.Variant.warning},
		{title = "Danger", variant = c.Variant.danger},
		{title = "Info", variant = c.Variant.info},
		{title = "Neutral"},
	}
	icons := [?]c.Timeline_Item {
		{
			title = "Uploaded",
			time = "10:02",
			icon = c.icon(doc, {name = .upload_simple, size = .small}),
			variant = c.Variant.info,
		},
		{
			title = "Approved",
			time = "10:40",
			icon = c.icon(doc, {name = .thumbs_up, size = .small}),
			variant = c.Variant.success,
		},
		{
			title = "Flagged",
			time = "11:15",
			icon = c.icon(doc, {name = .flag, size = .small}),
			variant = c.Variant.danger,
		},
	}

	return k.div(
		doc,
		{class = "doc-demo__preview-inner"},
		timeline_section(
			doc,
			"Default",
			"Finished events show a check, the current one is blue, and the rest are plain.",
			k.div(doc, {style = "max-width: 28rem"}, c.timeline(doc, {items = history[:]})),
		),
		timeline_section(
			doc,
			"Compact",
			"Title and time only, for dense feeds.",
			k.div(
				doc,
				{style = "max-width: 28rem"},
				c.timeline(doc, {items = compact[:], layout = .compact}),
			),
		),
		timeline_section(
			doc,
			"Alternate",
			"Events alternate sides of a centre line from 768px wide, and stack on a narrow screen.",
			c.timeline(doc, {items = alternate[:], layout = .alternate}),
		),
		timeline_section(
			doc,
			"Colours",
			"The shared Variant. A completed or active event owns its colour, so it takes none.",
			k.div(
				doc,
				{style = "max-width: 28rem"},
				c.timeline(doc, {items = colours[:], layout = .compact}),
			),
		),
		timeline_section(
			doc,
			"Icons",
			"An icon replaces the check. Build one per event.",
			k.div(
				doc,
				{style = "max-width: 28rem"},
				c.timeline(doc, {items = icons[:], layout = .compact}),
			),
		),
	)
}
