package component

import k "kashmir:."

// ---------- constants ----------

TOAST_MESSAGE_BYTES_MAX :: 1024
TOAST_TITLE_BYTES_MAX :: 256
TOAST_TOASTS_MAX :: 5 // on screen at once, and rendered by the server in one container
TOAST_CONTAINER_EXTRAS_MAX :: 6

Toast_Position :: enum u8 {
	bottom_right,
	bottom_left,
	bottom_center,
	top_right,
	top_left,
	top_center,
}

// Both the class suffix (toast-container--{name}), the container id suffix and the value the
// script matches on.
@(private)
toast_position_names := [Toast_Position]string {
	.bottom_right  = "bottom-right",
	.bottom_left   = "bottom-left",
	.bottom_center = "bottom-center",
	.top_right     = "top-right",
	.top_left      = "top-left",
	.top_center    = "top-center",
}

// ---------- props ----------

// One notice, as the server renders it into a container.
Toast_Props :: struct {
	using base: k.Base, // id, class (appended after the generated ones), style, attributes
	variant:    Alert_Variant, // the same four meanings as alert: Info, Success, Warning, Danger
	title:      string, // optional bold heading
	message:    string, // required, plain text
}

// A fixed region at a corner of the screen that holds toasts.
//
//   toast_container(doc, {position = .bottom_right})
//   toast_container(doc, {toasts = {{variant = .success, message = "Profile saved"}}})
//
// Put one in the layout, near the end of <body>. Toasts the server already knows about (a
// message after a redirect) go in toasts and show with no script; they stay until closed.
// The rest are made by script, from the container's template:
//
//   showToast("Saved", "success", "Profile")      // from application code
//
//   trigger := c.toast_trigger("Saved", variant = .success)   // declaratively
//   c.button(doc, {attributes = trigger[:]}, k.text(doc, "Save"))
//
// The container is the only live region (polite, not atomic, so a new toast is read alone).
// Warning and Danger toasts also carry role="alert" and do not close by themselves unless
// showToast is given a duration; Info and Success close after 5 seconds. The countdown pauses
// while the pointer or focus is on the toast, Escape closes the focused one, and at most
// TOAST_TOASTS_MAX stay on screen (the oldest goes first). Messages are always inserted as
// text.
//
// There is one container per position: the script finds it by position, so two at the same
// place would both show every toast, and id is refused. A toast is a fixed-position element,
// and a modal dialog opened with showModal sits above it in the browser's top layer.
//
// Asserts: at most TOAST_TOASTS_MAX toasts; each message non-empty and within
// TOAST_MESSAGE_BYTES_MAX, each title within TOAST_TITLE_BYTES_MAX; no id.
Toast_Container_Props :: struct {
	using base:  k.Base, // class (appended after the generated ones), style, attributes; id is refused
	position:    Toast_Position,
	toasts:      []Toast_Props, // already showing when the page loads
	label:       string, // the region's name; default "Notifications"
	close_label: string, // the close buttons' name; default "Close notification"
}

// ---------- procs ----------

// Composition order: toast-container toast-container--{position} [class]
toast_container :: proc(doc: ^k.Doc, props: Toast_Container_Props) -> k.Node_Id {
	assert(props.id == "", "toast_container id is derived from the position, so id is refused")
	assert(
		len(props.toasts) <= TOAST_TOASTS_MAX,
		"toast_container toasts exceeds TOAST_TOASTS_MAX",
	)

	position := toast_position_names[props.position]
	close_label := props.close_label != "" ? props.close_label : "Close notification"

	// Each toast is the container's child, then the template that script copies from.
	children: [TOAST_TOASTS_MAX + 1]k.Node_Id
	for toast_props, index in props.toasts {
		children[index] = toast(doc, toast_props, close_label)
	}
	children[len(props.toasts)] = toast_template(doc, close_label)

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + TOAST_CONTAINER_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"toast_container attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	extras := [?]k.Attribute {
		k.role("region"),
		k.attribute("aria-label", props.label != "" ? props.label : "Notifications"),
		k.attribute("aria-live", "polite"),
		k.attribute("aria-atomic", "false"),
		k.attribute("data-controller", "keralam-toast"),
		k.attribute("data-keralam-toast-position-value", position),
	}
	copy(attributes[attributes_count:], extras[:])
	attributes_count += len(extras)

	base := props.base
	base.id = k.doc_format(doc, "toast-container-%s", position)
	base.class = toast_container_class(doc, props, position)
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, ..children[:len(props.toasts) + 1])
}

// The attributes that make an element show a toast when clicked. Spread them into the
// element's attributes (keep the array in a variable, then slice it). The script reads them,
// so no inline handler is needed.
//
// Needs a container at the same position on the page; with none, the click does nothing.
toast_trigger :: proc(
	message: string,
	title := "",
	variant := Alert_Variant.info,
	position := Toast_Position.bottom_right,
) -> [4]k.Attribute {
	assert(message != "", "toast_trigger needs a message")
	assert(
		len(message) <= TOAST_MESSAGE_BYTES_MAX,
		"toast_trigger message exceeds TOAST_MESSAGE_BYTES_MAX",
	)
	assert(
		len(title) <= TOAST_TITLE_BYTES_MAX,
		"toast_trigger title exceeds TOAST_TITLE_BYTES_MAX",
	)
	return {
		k.attribute("data-toast-message", message),
		k.attribute("data-toast-title", title),
		k.attribute("data-toast-type", alert_variant_names[variant]),
		k.attribute("data-toast-position", toast_position_names[position]),
	}
}

@(private)
toast :: proc(doc: ^k.Doc, props: Toast_Props, close_label: string) -> k.Node_Id {
	assert(props.message != "", "toast needs a message")
	assert(
		len(props.message) <= TOAST_MESSAGE_BYTES_MAX,
		"toast message exceeds TOAST_MESSAGE_BYTES_MAX",
	)
	assert(len(props.title) <= TOAST_TITLE_BYTES_MAX, "toast title exceeds TOAST_TITLE_BYTES_MAX")

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(attributes_count + 3 <= ATTRIBUTES_MAX, "toast attributes exceeds ATTRIBUTES_MAX")
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute("aria-atomic", "true")
	attributes[attributes_count + 1] = k.attribute("tabindex", "0")
	attributes_count += 2
	if props.variant == .warning || props.variant == .danger {
		attributes[attributes_count] = k.role("alert")
		attributes_count += 1
	}

	variant := alert_variant_names[props.variant]
	separator := props.class != "" ? " " : ""
	base := props.base
	base.class = k.doc_format(doc, "toast toast--%s%s%s", variant, separator, props.class)
	base.attributes = attributes[:attributes_count]

	return k.div(
		doc,
		base,
		k.div(
			doc,
			{class = "toast__icon", attributes = {k.attribute("aria-hidden", "true")}},
			icon(doc, {name = alert_icon(props.variant), size = .small}),
		),
		k.div(
			doc,
			{class = "toast__content"},
			props.title != "" ? k.div(doc, {class = "toast__title"}, k.text(doc, props.title)) : k.NODE_NONE,
			k.div(doc, {class = "toast__message"}, k.text(doc, props.message)),
		),
		toast_close(doc, close_label),
	)
}

// What the script copies for each new toast. It holds an icon for every variant and the
// script keeps the one that matches.
@(private)
toast_template :: proc(doc: ^k.Doc, close_label: string) -> k.Node_Id {
	icons: [len(Alert_Variant)]k.Node_Id
	for variant in Alert_Variant {
		icons[variant] = k.span(
			doc,
			{
				attributes = {
					k.attribute("data-keralam-toast-icon", alert_variant_names[variant]),
					k.hidden(),
				},
			},
			icon(doc, {name = alert_icon(variant), size = .small}),
		)
	}

	return k.template(
		doc,
		{base = {attributes = {k.attribute("data-keralam-toast-target", "template")}}},
		k.div(
			doc,
			{
				class = "toast",
				attributes = {k.attribute("aria-atomic", "true"), k.attribute("tabindex", "0")},
			},
			k.div(
				doc,
				{class = "toast__icon", attributes = {k.attribute("aria-hidden", "true")}},
				..icons[:],
			),
			k.div(
				doc,
				{class = "toast__content"},
				k.div(
					doc,
					{
						class = "toast__title",
						attributes = {k.attribute("data-keralam-toast-part", "title")},
					},
				),
				k.div(
					doc,
					{
						class = "toast__message",
						attributes = {k.attribute("data-keralam-toast-part", "message")},
					},
				),
			),
			toast_close(doc, close_label),
		),
	)
}

@(private)
toast_close :: proc(doc: ^k.Doc, close_label: string) -> k.Node_Id {
	return k.button(
		doc,
		{
			base = {
				class = "toast__close",
				attributes = {
					k.attribute("aria-label", close_label),
					k.attribute("data-action", "click->keralam-toast#dismiss"),
				},
			},
			type = .button,
		},
		icon(doc, {name = .x, size = .small}),
	)
}

@(private)
toast_container_class :: proc(
	doc: ^k.Doc,
	props: Toast_Container_Props,
	position: string,
) -> string {
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"toast-container toast-container--%s%s%s",
		position,
		separator,
		props.class,
	)
}
