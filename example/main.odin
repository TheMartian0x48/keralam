package main

// Demo server. One page per component at /component/<name>, an index at /.
//
//   make run            (listens on 127.0.0.1:8080)
//   make run PORT=3000
//
// Single threaded: one request is read, answered and closed before the next is
// accepted. Fine for a local demo, not for production.

import c "../component"
import "core:fmt"
import "core:net"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import k "kashmir:."

PORT_DEFAULT :: 8080
REQUEST_BYTES_MAX :: 1 << 13 // 8 KiB, longer requests are rejected
RECEIVE_TIMEOUT :: 5 * time.Second
COMPONENT_PATH_PREFIX :: "/component/"
ASSET_PATH_PREFIX :: "/assets/"
// Searched in order, relative to the working directory (the repo root under make run).
// keralam.css comes from the root assets/; anything else falls through to the demo's own files.
asset_directories :: [?]string{"assets", "example/css"}
ASSET_BYTES_MAX :: 1 << 24 // 16 MiB, larger files are not served

// ---------- constants ----------

// Add a component here and it gets a page and an index entry.
components := [?]Component_Demo {
	{name = "accordion", render = demo_accordion},
	{name = "alert", render = demo_alert},
	{name = "autocomplete", render = demo_autocomplete},
	{name = "badge", render = demo_badge},
	{name = "breadcrumb", render = demo_breadcrumb},
	{name = "button", render = demo_button},
	{name = "card", render = demo_card},
	{name = "checkbox", render = demo_checkbox},
	{name = "dialog", render = demo_dialog},
	{name = "divider", render = demo_divider, description = divider_description},
	{name = "drawer", render = demo_drawer, description = drawer_description},
	{name = "dropdown", render = demo_dropdown, description = dropdown_description},
	{name = "dropzone", render = demo_dropzone, description = dropzone_description},
	{name = "icon", render = demo_icon},
	{name = "image_preview", render = demo_image_preview, description = image_preview_description},
	{name = "input", render = demo_input, description = input_description},
	{name = "label", render = demo_label, description = label_description},
	{name = "link", render = demo_link},
	{name = "list", render = demo_list, description = list_description},
	{name = "mail", render = demo_mail},
	{name = "pagination", render = demo_pagination, description = pagination_description},
	{name = "progress", render = demo_progress, description = progress_description},
	{name = "radio", render = demo_radio, description = radio_description},
	{name = "select", render = demo_select, description = select_description},
	{name = "slider", render = demo_slider, description = slider_description},
	{name = "stepper", render = demo_stepper, description = stepper_description},
	{name = "table", render = demo_table, description = table_description},
	{name = "tabs", render = demo_tabs, description = tabs_description},
	{name = "textarea", render = demo_textarea, description = textarea_description},
	{name = "time", render = demo_time, description = time_description},
	{name = "timeline", render = demo_timeline, description = timeline_description},
	{name = "toast", render = demo_toast, description = toast_description},
	{name = "toggle", render = demo_toggle, description = toggle_description},
	{name = "tooltip", render = demo_tooltip, description = tooltip_description},
}

Component_Demo :: struct {
	name:        string,
	render:      proc(doc: ^k.Doc) -> k.Node_Id,
	description: proc(doc: ^k.Doc) -> k.Node_Id, // builds the header paragraph; nil = none
}

// ---------- pages ----------

// One sidebar row: a link, marked as the current page when it is.
sidebar_item :: proc(doc: ^k.Doc, href, label: string, is_current: bool) -> c.List_Item {
	attributes := is_current ? []k.Attribute{k.attribute("aria-current", "page")} : nil
	return {
		content = c.link(
			doc,
			{
				href = href,
				variant = is_current ? .primary : .secondary,
				shape = is_current ? .soft : .text,
				attributes = attributes,
			},
			k.text(doc, label),
		),
	}
}

// current is the component being shown, or "" for the index and error pages.
page :: proc(doc: ^k.Doc, title, current: string, body: ..k.Node_Id) -> k.Node_Id {
	component_items := make([dynamic]c.List_Item, 0, len(components), context.temp_allocator)
	for component in components {
		href := k.doc_format(doc, "%s%s", COMPONENT_PATH_PREFIX, component.name)
		append(
			&component_items,
			sidebar_item(doc, href, component.name, component.name == current),
		)
	}
	example_items := [?]c.List_Item {
		sidebar_item(doc, THEME_PATH, "theme tokens", current == "theme"),
		sidebar_item(doc, FORM_PATH, "sign-up form", current == "form"),
	}

	return k.html(
		doc,
		{attributes = {k.lang("en")}},
		k.head(
			doc,
			{},
			k.meta(doc, {charset = "utf-8"}),
			k.meta(doc, {name = "viewport", content = "width=device-width, initial-scale=1"}),
			k.title_(doc, {}, k.text(doc, title)),
			// Preload the regular font so icons do not flash blank while it loads.
			// The URL must match the @font-face exactly, or the browser fetches it twice.
			k.link(
				doc,
				{
					rel = "preload",
					href = fmt.tprintf(
						"%s%s?v=%s",
						ASSET_PATH_PREFIX,
						c.icon_font_files[.regular],
						c.icon_font_version,
					),
					as_ = .font,
					type = "font/woff2",
					cross_origin = .anonymous,
				},
			),
			k.link(doc, {rel = "stylesheet", href = "/assets/keralam.css"}),
			k.link(doc, {rel = "stylesheet", href = "/assets/keralam-themes.css"}),
			k.link(doc, {rel = "stylesheet", href = "/assets/example.css"}),
			k.script(doc, {src = "/assets/keralam.js", defer_ = true}),
		),
		k.body(
			doc,
			{},
			k.div(
				doc,
				{class = "layout"},
				k.nav(
					doc,
					{class = "sidebar"},
					k.a(doc, {class = "sidebar__brand", href = "/"}, k.text(doc, "keralam")),
					theme_picker(doc),
					k.h2(doc, {class = "sidebar__heading"}, k.text(doc, "Components")),
					c.list(doc, {size = .small, items = component_items[:]}),
					k.h2(
						doc,
						{class = "sidebar__heading sidebar__heading--spaced"},
						k.text(doc, "Examples"),
					),
					c.list(doc, {size = .small, items = example_items[:]}),
				),
				k.main_(doc, {class = "showcase"}, ..body),
			),
		),
	)
}

page_index :: proc(doc: ^k.Doc) -> k.Node_Id {
	return page(
		doc,
		"keralam",
		"",
		k.h1(doc, {class = "showcase__title"}, k.text(doc, "Pick a component")),
	)
}

page_not_found :: proc(doc: ^k.Doc) -> k.Node_Id {
	return page(
		doc,
		"Not found",
		"",
		k.h1(doc, {class = "showcase__title"}, k.text(doc, "Not found")),
	)
}

page_form :: proc(doc: ^k.Doc) -> k.Node_Id {
	return page(
		doc,
		"form",
		"form",
		k.section(
			doc,
			{class = "doc-section"},
			k.header(
				doc,
				{class = "doc-section__header"},
				k.h1(doc, {class = "doc-section__title"}, k.text(doc, "Sign-up form")),
				form_description(doc),
			),
			k.div(
				doc,
				{class = "doc-demo"},
				k.div(doc, {class = "doc-demo__preview"}, demo_form(doc)),
			),
		),
	)
}

page_theme :: proc(doc: ^k.Doc) -> k.Node_Id {
	return page(
		doc,
		"theme",
		"theme",
		k.section(
			doc,
			{class = "doc-section"},
			k.header(
				doc,
				{class = "doc-section__header"},
				k.h1(doc, {class = "doc-section__title"}, k.text(doc, "Theme tokens")),
				theme_description(doc),
			),
			k.div(
				doc,
				{class = "doc-demo"},
				k.div(doc, {class = "doc-demo__preview"}, demo_theme(doc)),
			),
		),
	)
}

page_component :: proc(doc: ^k.Doc, component: Component_Demo) -> k.Node_Id {
	description := component.description != nil ? component.description(doc) : k.NODE_NONE
	return page(
		doc,
		component.name,
		component.name,
		k.section(
			doc,
			{class = "doc-section"},
			k.header(
				doc,
				{class = "doc-section__header"},
				k.h1(doc, {class = "doc-section__title"}, k.text(doc, component.name)),
				description,
			),
			k.div(
				doc,
				{class = "doc-demo"},
				k.div(doc, {class = "doc-demo__preview"}, component.render(doc)),
			),
		),
	)
}

// ---------- demos ----------

demo_section :: proc(doc: ^k.Doc, heading: string, children: ..k.Node_Id) -> k.Node_Id {
	return k.section(
		doc,
		{class = "demo"},
		k.h2(doc, {class = "demo__heading"}, k.text(doc, heading)),
		k.div(doc, {class = "demo__stage"}, ..children),
	)
}

// ---------- server ----------

// Returns the page for a request target, built into doc.
route :: proc(doc: ^k.Doc, target: string) -> (root: k.Node_Id, status: string) {
	if target == "/" do return page_index(doc), "200 OK"
	if target == FORM_PATH do return page_form(doc), "200 OK"
	if target == THEME_PATH do return page_theme(doc), "200 OK"

	if strings.has_prefix(target, COMPONENT_PATH_PREFIX) {
		name := target[len(COMPONENT_PATH_PREFIX):]
		for component in components {
			if component.name == name do return page_component(doc, component), "200 OK"
		}
	}
	return page_not_found(doc), "404 Not Found"
}

// Parses "GET /path HTTP/1.1". Only GET is served.
request_target :: proc(request: string) -> (target, query: string, ok: bool) {
	line_end := strings.index(request, "\r\n")
	if line_end < 0 do return "", "", false

	parts := strings.split(request[:line_end], " ", context.temp_allocator)
	if len(parts) != 3 || parts[0] != "GET" do return "", "", false
	if !strings.has_prefix(parts[1], "/") do return "", "", false

	mark := strings.index_byte(parts[1], '?')
	if mark < 0 do return parts[1], "", true
	return parts[1][:mark], parts[1][mark + 1:], true
}

send_all :: proc(socket: net.TCP_Socket, data: string) {
	remaining := transmute([]byte)data
	// Each pass sends at least one byte or stops, so the loop is bounded by len(data).
	for _ in 0 ..< len(data) {
		if len(remaining) == 0 do return
		written, error := net.send_tcp(socket, remaining)
		if error != nil || written <= 0 do return
		remaining = remaining[written:]
	}
}

respond :: proc(
	socket: net.TCP_Socket,
	status, body: string,
	content_type := "text/html; charset=utf-8",
	cache_control := "no-cache",
) {
	header := fmt.tprintf(
		"HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: %s\r\nConnection: close\r\n\r\n",
		status,
		content_type,
		len(body),
		cache_control,
	)
	send_all(socket, header)
	send_all(socket, body)
}

asset_content_type :: proc(name: string) -> string {
	switch {
	case strings.has_suffix(name, ".css"):
		return "text/css; charset=utf-8"
	case strings.has_suffix(name, ".js"):
		return "text/javascript; charset=utf-8"
	case strings.has_suffix(name, ".svg"):
		return "image/svg+xml"
	case strings.has_suffix(name, ".woff2"):
		return "font/woff2"
	case strings.has_suffix(name, ".png"):
		return "image/png"
	}
	return "application/octet-stream"
}

// Fonts are cached for a year and never revalidated. That is safe because their
// URL carries the Phosphor version (?v=2.1.2), so an upgrade is a new URL.
// Everything else changes on every build, so it must revalidate.
asset_cache_control :: proc(name: string) -> string {
	if strings.has_suffix(name, ".woff2") do return "public, max-age=31536000, immutable"
	return "no-cache"
}

// A flat directory: no separators and no dot-prefixed names, so a request can
// never leave asset_directory.
asset_name_valid :: proc(name: string) -> bool {
	if len(name) == 0 || name[0] == '.' do return false
	return !strings.contains_any(name, "/\\\x00%")
}

// Returns false when the request was not for an asset.
serve_asset :: proc(socket: net.TCP_Socket, target: string) -> bool {
	if !strings.has_prefix(target, ASSET_PATH_PREFIX) do return false

	name := target[len(ASSET_PATH_PREFIX):]
	content: []byte
	if asset_name_valid(name) {
		for directory in asset_directories {
			path := fmt.tprintf("%s/%s", directory, name)
			read_error: os.Error
			content, read_error = os.read_entire_file(path, context.temp_allocator)
			if read_error == nil do break
			content = nil
		}
	}
	if content == nil || len(content) > ASSET_BYTES_MAX {
		respond(socket, "404 Not Found", "Not Found", "text/plain; charset=utf-8")
		fmt.printfln("404 Not Found %s", target)
		return true
	}

	respond(socket, "200 OK", string(content), asset_content_type(name), asset_cache_control(name))
	fmt.printfln("200 OK %s", target)
	return true
}

handle :: proc(socket: net.TCP_Socket) {
	defer net.close(socket)
	net.set_option(socket, .Receive_Timeout, RECEIVE_TIMEOUT)

	buffer: [REQUEST_BYTES_MAX]u8
	received, receive_error := net.recv_tcp(socket, buffer[:])
	if receive_error != nil || received <= 0 do return

	target, query, ok := request_target(string(buffer[:received]))
	if !ok {
		respond(socket, "400 Bad Request", "Bad Request")
		return
	}

	if serve_asset(socket, target) do return

	doc: k.Doc
	if !k.doc_init(&doc) {
		respond(socket, "500 Internal Server Error", "Internal Server Error")
		return
	}
	defer k.doc_destroy(&doc)

	form_state = {
		errors = query == "errors",
	}
	root, status := route(&doc, target)
	respond(socket, status, k.render_to_string(&doc, root, doctype = true))
	fmt.printfln("%s %s", status, target)
}

main :: proc() {
	port := PORT_DEFAULT
	if value, found := os.lookup_env("PORT", context.temp_allocator); found {
		parsed, parsed_ok := strconv.parse_int(value)
		if !parsed_ok || parsed < 1 || parsed > 65535 {
			fmt.eprintfln("invalid PORT %q", value)
			os.exit(1)
		}
		port = parsed
	}

	listener, listen_error := net.listen_tcp({address = net.IP4_Loopback, port = port})
	if listen_error != nil {
		fmt.eprintfln("cannot listen on port %d: %v", port, listen_error)
		os.exit(1)
	}
	defer net.close(listener)
	fmt.printfln("keralam demo on http://127.0.0.1:%d", port)

	// Serves until the process is killed.
	for {
		client, _, accept_error := net.accept_tcp(listener)
		if accept_error != nil do continue
		handle(client)
		free_all(context.temp_allocator)
	}
}
