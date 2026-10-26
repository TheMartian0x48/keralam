package component

import k "kashmir:."

// ---------- enums ----------

// Severity of an alert. info is first so the zero value is a neutral message,
// not a success or an error. Alert has its own enum because it has no primary or
// secondary: those are button-style colors, these are meanings.
Alert_Variant :: enum u8 {
	info,
	success,
	warning,
	danger,
}

@(private)
alert_variant_names := [Alert_Variant]string {
	.info    = "info",
	.success = "success",
	.warning = "warning",
	.danger  = "danger",
}

// ---------- constants ----------

ALERT_EXTRAS_MAX :: 6 // role, aria-atomic, aria-label, data-controller, timeout value, data-action
ALERT_DISMISS_TIMEOUT_MAX :: 60 * 60 * 1000 // one hour in milliseconds

// ---------- props ----------

// An accessible feedback message for form validation, notifications and inline
// status.
//
//   alert(doc, {variant = .success, shape = .soft, title = "Saved"}, k.text(doc, "Profile updated."))
//
// warning and danger are announced assertively (role="alert"); the others are
// polite (role="status"). Shape is the shared Shape enum: its zero value is
// solid, so pass .soft for the quiet look.
Alert_Props :: struct {
	using base:      k.Base, // id, class (appended after the generated classes), style, attributes

	// appearance
	variant:         Alert_Variant,
	shape:           Shape, // see component.odin
	title:           string, // optional bold heading
	hide_icon:       bool,

	// behaviour
	dismissible:     bool, // shows a close button
	dismiss_timeout: u32, // auto-dismiss after this many milliseconds, 0 = stays

	// accessibility
	aria_label:      string,
}

// ---------- procs ----------

// Composition order: alert alert--{variant} alert--{shape} [class]
alert :: proc(doc: ^k.Doc, props: Alert_Props, children: ..k.Node_Id) -> k.Node_Id {
	assert(
		props.dismiss_timeout <= ALERT_DISMISS_TIMEOUT_MAX,
		"alert dismiss_timeout exceeds one hour",
	)

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + ALERT_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"alert attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	attributes[attributes_count] = k.role(alert_role(props.variant))
	attributes_count += 1
	attributes[attributes_count] = k.attribute("aria-atomic", "true")
	attributes_count += 1
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}
	if props.dismissible || props.dismiss_timeout > 0 {
		attributes[attributes_count] = k.attribute("data-controller", "keralam-alert")
		attributes_count += 1
		attributes[attributes_count] = k.attribute(
			"data-keralam-alert-timeout-value",
			k.doc_format(doc, "%d", props.dismiss_timeout),
		)
		attributes_count += 1
		attributes[attributes_count] = k.attribute(
			"data-action",
			"keydown.Escape@window->keralam-alert#maybeEscape",
		)
		attributes_count += 1
	}

	icon_node := k.NODE_NONE
	if !props.hide_icon {
		icon_node = k.div(
			doc,
			{class = "alert__icon"},
			icon(doc, {name = alert_icon(props.variant), size = .small}),
		)
	}

	title_node :=
		props.title != "" ? k.h4(doc, {class = "alert__title"}, k.text(doc, props.title)) : k.NODE_NONE
	content := k.div(
		doc,
		{class = "alert__content"},
		title_node,
		k.div(doc, {class = "alert__body"}, ..children),
	)

	close_node := k.NODE_NONE
	if props.dismissible {
		close_node = k.div(
			doc,
			{class = "alert__close_container"},
			button(
				doc,
				{
					class = "alert__close",
					variant = .secondary,
					shape = .text,
					size = .small,
					attributes = {
						k.attribute("aria-label", "Dismiss"),
						k.attribute("data-action", "keralam-alert#dismiss"),
					},
				},
				icon(doc, {name = .x, size = .small}),
			),
		)
	}

	base := props.base
	base.class = alert_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, icon_node, content, close_node)
}

// "alert" interrupts assistive technology, "status" waits its turn.
@(private)
alert_role :: proc(variant: Alert_Variant) -> string {
	switch variant {
	case .warning, .danger:
		return "alert"
	case .info, .success:
		return "status"
	}
	unreachable()
}

@(private)
alert_icon :: proc(variant: Alert_Variant) -> Icon_Name {
	switch variant {
	case .info:
		return .info
	case .success:
		return .check_circle
	case .warning:
		return .warning
	case .danger:
		return .x_circle
	}
	unreachable()
}

@(private)
alert_class :: proc(doc: ^k.Doc, props: Alert_Props) -> string {
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"alert alert--%s alert--%s%s%s",
		alert_variant_names[props.variant],
		shape_names[props.shape],
		separator,
		props.class,
	)
}
