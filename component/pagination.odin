package component

import k "kashmir:."

// ---------- constants ----------

PAGINATION_PAGES_MAX :: 1_000_000
PAGINATION_SIBLINGS_MAX :: 5
PAGINATION_SLOTS_MAX :: 2 * PAGINATION_SIBLINGS_MAX + 5 // the most entries a control ever shows
PAGINATION_EXTRAS_MAX :: 1 // aria-label
PAGINATION_ELLIPSIS :: u32(0) // in a page list, 0 stands for a gap: pages are numbered from 1

// ---------- props ----------

// A page navigation bar: previous and next, and the page numbers between, with a gap
// ("...") where pages are left out.
//
//   pagination(doc, {current = 3, total = 20, href_prefix = "/users?page=", prev_next = true})
//
// It shows a fixed number of entries (2 * siblings + 5) however far you page, so the
// control does not change width as you click through, and a gap always stands for at least
// two pages: where only one would be hidden, that page is shown instead.
//
// With one page or none there is nothing to navigate, and node_none is returned, which
// element() skips: an empty result set needs no check by the caller.
//
// On a narrow screen the page numbers are hidden and only previous and next remain, so
// prev_next needs to be set for the control to be usable there.
//
// current comes from the caller, usually from a query string. A value outside 1 to total
// asserts, so clamp it where you read the request.
//
// Asserts: href_prefix is not empty and is not a script URL; current is within 1 to total
// when there are pages; siblings and total are within their caps.
Pagination_Props :: struct {
	using base:  k.Base, // id, class (appended after the generated classes), style, attributes
	current:     u32, // the page being shown, counted from 1
	total:       u32, // the number of pages; 0 or 1 renders nothing
	href_prefix: string, // the page number is appended to it: "/users?page="
	siblings:    Maybe(u32), // pages shown each side of the current one; nil = 1
	size:        Size, // see component.odin
	prev_next:   bool, // show the previous and next links
	prev_label:  string, // default "Previous"
	next_label:  string, // default "Next"
	aria_label:  string, // names the navigation; default "Pagination"
}

// ---------- procs ----------

// The entries to show, in order: page numbers, and PAGINATION_ELLIPSIS (0) for a gap. Always
// pagination_slots entries when there are more pages than that, else every page.
//
// Near the start the first 2 * siblings + 3 pages are shown, then a gap, then the last page;
// near the end the mirror of that; between, first, gap, a window around the current page,
// gap, last. The three cases are chosen so a gap never stands for just one page.
pagination_pages :: proc(
	current, total, siblings: u32,
) -> (
	pages: [PAGINATION_SLOTS_MAX]u32,
	count: u32,
) {
	assert(total >= 1 && total <= PAGINATION_PAGES_MAX, "pagination total is out of range")
	assert(current >= 1 && current <= total, "pagination current is outside 1 to total")
	assert(
		siblings <= PAGINATION_SIBLINGS_MAX,
		"pagination siblings exceeds PAGINATION_SIBLINGS_MAX",
	)

	slots := 2 * siblings + 5
	if total <= slots {
		for page in u32(1) ..= total {
			pages[count] = page
			count += 1
		}
		return
	}

	edge := 2 * siblings + 3 // pages shown at the end that has no gap
	if current <= siblings + 3 {
		for page in u32(1) ..= edge {
			pages[count] = page
			count += 1
		}
		pages[count] = PAGINATION_ELLIPSIS
		pages[count + 1] = total
		count += 2
	} else if current + siblings + 2 >= total {
		pages[count] = 1
		pages[count + 1] = PAGINATION_ELLIPSIS
		count += 2
		for page in total - edge + 1 ..= total {
			pages[count] = page
			count += 1
		}
	} else {
		pages[count] = 1
		pages[count + 1] = PAGINATION_ELLIPSIS
		count += 2
		for page in current - siblings ..= current + siblings {
			pages[count] = page
			count += 1
		}
		pages[count] = PAGINATION_ELLIPSIS
		pages[count + 1] = total
		count += 2
	}
	assert(count == slots, "pagination did not fill its slots")
	return
}

// Composition order: pagination pagination--{size} [pagination--prev-next] [class]
pagination :: proc(doc: ^k.Doc, props: Pagination_Props) -> k.Node_Id {
	assert(props.href_prefix != "", "pagination needs an href_prefix")
	assert(link_href_safe(props.href_prefix), "pagination href_prefix uses a script scheme")
	assert(props.total <= PAGINATION_PAGES_MAX, "pagination total exceeds PAGINATION_PAGES_MAX")
	assert(
		props.total == 0 || (props.current >= 1 && props.current <= props.total),
		"pagination current is outside 1 to total",
	)
	siblings := props.siblings.? or_else 1
	assert(
		siblings <= PAGINATION_SIBLINGS_MAX,
		"pagination siblings exceeds PAGINATION_SIBLINGS_MAX",
	)

	if props.total <= 1 do return k.NODE_NONE

	pages, pages_count := pagination_pages(props.current, props.total, siblings)

	items: [PAGINATION_SLOTS_MAX + 2]k.Node_Id
	items_count := 0
	if props.prev_next {
		items[items_count] = pagination_step(doc, props, .previous)
		items_count += 1
	}
	for page in pages[:pages_count] {
		items[items_count] = k.li(
			doc,
			{class = "pagination__item pagination__item--page"},
			pagination_page(doc, props, page),
		)
		items_count += 1
	}
	if props.prev_next {
		items[items_count] = pagination_step(doc, props, .next)
		items_count += 1
	}

	// k.nav copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + PAGINATION_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"pagination attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute(
		"aria-label",
		props.aria_label != "" ? props.aria_label : "Pagination",
	)
	attributes_count += 1

	// Every page link is as wide as the widest page number, so the bar does not change width
	// as the current page moves between one-digit and two-digit numbers.
	digits: u32 = 1
	for remaining := props.total; remaining >= 10; remaining /= 10 {
		digits += 1
	}
	base := props.base
	base.style = k.doc_format(
		doc,
		"--pagination-digits: %d%s%s",
		digits,
		props.style != "" ? "; " : "",
		props.style,
	)
	base.class = pagination_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.nav(doc, base, k.ul(doc, {class = "pagination__list"}, ..items[:items_count]))
}

@(private)
Pagination_Step :: enum u8 {
	previous,
	next,
}

// The previous or next entry: a link, or a disabled span at either end.
@(private)
pagination_step :: proc(doc: ^k.Doc, props: Pagination_Props, step: Pagination_Step) -> k.Node_Id {
	previous := step == .previous
	target := previous ? props.current - 1 : props.current + 1
	enabled := previous ? props.current > 1 : props.current < props.total

	label := previous ? props.prev_label : props.next_label
	if label == "" do label = previous ? "Previous" : "Next"
	direction := previous ? "prev" : "next"

	arrow := icon(
		doc,
		{class = "pagination__icon", name = previous ? .arrow_left : .arrow_right, size = .small},
	)
	text := k.span(
		doc,
		{class = k.doc_format(doc, "pagination__%s-text", direction)},
		k.text(doc, label),
	)

	if !enabled {
		return k.li(
			doc,
			{class = "pagination__item"},
			k.span(
				doc,
				{
					class = k.doc_format(
						doc,
						"pagination__link pagination__link--%s pagination__link--disabled",
						direction,
					),
					attributes = {k.attribute("aria-disabled", "true")},
				},
				previous ? arrow : text,
				previous ? text : arrow,
			),
		)
	}
	return k.li(
		doc,
		{class = "pagination__item"},
		k.a(
			doc,
			{
				base = {
					class = k.doc_format(doc, "pagination__link pagination__link--%s", direction),
					attributes = {
						k.attribute(
							"aria-label",
							k.doc_format(
								doc,
								"Go to %s page, page %d",
								direction == "prev" ? "previous" : "next",
								target,
							),
						),
					},
				},
				href = k.doc_format(doc, "%s%d", props.href_prefix, target),
			},
			previous ? arrow : text,
			previous ? text : arrow,
		),
	)
}

// A page number, the current page, or a gap.
@(private)
pagination_page :: proc(doc: ^k.Doc, props: Pagination_Props, page: u32) -> k.Node_Id {
	if page == PAGINATION_ELLIPSIS {
		return k.span(
			doc,
			{class = "pagination__ellipsis", attributes = {k.attribute("aria-hidden", "true")}},
			k.text(doc, "..."),
		)
	}
	number := k.text(doc, k.doc_format(doc, "%d", page))
	if page == props.current {
		return k.span(
			doc,
			{
				class = "pagination__link pagination__link--current",
				attributes = {k.attribute("aria-current", "page")},
			},
			number,
		)
	}
	return k.a(
		doc,
		{
			base = {
				class = "pagination__link",
				attributes = {k.attribute("aria-label", k.doc_format(doc, "Go to page %d", page))},
			},
			href = k.doc_format(doc, "%s%d", props.href_prefix, page),
		},
		number,
	)
}

@(private)
pagination_class :: proc(doc: ^k.Doc, props: Pagination_Props) -> string {
	prev_next_class := props.prev_next ? " pagination--prev-next" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"pagination pagination--%s%s%s%s",
		size_names[props.size],
		prev_next_class,
		separator,
		props.class,
	)
}
