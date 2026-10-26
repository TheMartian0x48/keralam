package component

import k "kashmir:."

// ---------- constants ----------

DROPZONE_FILES_MAX :: u32(100)
DROPZONE_BYTES_MAX :: u32(2_147_483_647) // 2 GiB less one, the most a u32 can say
DROPZONE_TEXT_BYTES_MAX :: 256
DROPZONE_EXTRAS_MAX :: 8

// ---------- props ----------

// A file picker that is also a drop target, with a list of the chosen files.
//
//   dropzone(doc, {name = "files", multiple = true, accept = "image/*", help = "PNG or JPG, up to 2 MB", max_bytes = 2_000_000})
//
// The control is input_file, hidden behind the whole area, so a click, a drop and a paste all
// end up in the form field under name. Needs keralam.js to take drops and pastes, to list the
// files, and to enforce the limits; without it the area is still a label for the file input,
// so a click opens the file chooser and the choice submits, it just is not listed.
//
// accept, a single-file zone, max_files and max_bytes are checked in script, with a message
// ("report.pdf is larger than 2 MB") in a polite live region. Script is not a security
// boundary: check the same things when the upload arrives.
//
// error is a message, not a flag: it sets aria-invalid on the input and is read with it. A
// dropzone has its own label, so it does not go in form_field.
//
// Asserts: label, help and error within DROPZONE_TEXT_BYTES_MAX; max_files at most
// DROPZONE_FILES_MAX and max_bytes at most DROPZONE_BYTES_MAX; max_files above 1 only with
// multiple; and those of input_file.
Dropzone_Props :: struct {
	using base:   k.Base, // id (generated when empty), class, style, attributes: all on the wrapper
	name:         string, // the form field name
	label:        string, // default "Click to upload or drag and drop"
	help:         string, // under the label, e.g. the formats allowed
	error:        string, // a validation message; sets the invalid state
	accept:       string, // what to offer, e.g. "image/*" or ".pdf"; also enforced for drops
	multiple:     bool,
	max_files:    u32, // 0 = no limit; a single-file zone keeps one
	max_bytes:    u32, // per file; 0 = no limit
	required:     bool,
	disabled:     bool,
	size:         Size, // see component.odin: the minimum height
	radius:       Radius, // see component.odin
	remove_label: string, // default "Remove"; each button reads "Remove report.pdf"
}

// ---------- procs ----------

// Composition order: dropzone dropzone--{size} [dropzone--{radius}] [dropzone--error] [dropzone--disabled] [class]
dropzone :: proc(doc: ^k.Doc, props: Dropzone_Props) -> k.Node_Id {
	assert(
		len(props.label) <= DROPZONE_TEXT_BYTES_MAX,
		"dropzone label exceeds DROPZONE_TEXT_BYTES_MAX",
	)
	assert(
		len(props.help) <= DROPZONE_TEXT_BYTES_MAX,
		"dropzone help exceeds DROPZONE_TEXT_BYTES_MAX",
	)
	assert(
		len(props.error) <= DROPZONE_TEXT_BYTES_MAX,
		"dropzone error exceeds DROPZONE_TEXT_BYTES_MAX",
	)
	assert(props.max_files <= DROPZONE_FILES_MAX, "dropzone max_files exceeds DROPZONE_FILES_MAX")
	assert(props.max_bytes <= DROPZONE_BYTES_MAX, "dropzone max_bytes exceeds DROPZONE_BYTES_MAX")
	assert(props.max_files <= 1 || props.multiple, "dropzone max_files above 1 needs multiple")

	// Unique within a page without global state: node counts only grow.
	root_id := props.id != "" ? props.id : k.doc_format(doc, "dz%d", doc.nodes_count)
	input_id := k.doc_format(doc, "%s-input", root_id)
	message_id := k.doc_format(doc, "%s-message", root_id)
	help_id := k.doc_format(doc, "%s-help", root_id)
	status_id := k.doc_format(doc, "%s-status", root_id)

	// The input names the help and the error, in that order.
	described_by := ""
	if props.error != "" {
		described_by =
			props.help != "" ? k.doc_format(doc, "%s %s", message_id, help_id) : message_id
	} else if props.help != "" {
		described_by = help_id
	}

	input_attributes := [?]k.Attribute {
		k.attribute("data-keralam-dropzone-target", "fileInput"),
		k.attribute("data-action", "change->keralam-dropzone#change"),
	}
	control := input_file(
		doc,
		{
			common = {
				base = {
					id = input_id,
					class = "dropzone__input visually-hidden",
					attributes = input_attributes[:],
				},
				name = props.name,
				disabled = props.disabled,
				error = props.error != "",
				aria_described_by = described_by,
			},
			required = props.required,
			accept = props.accept,
			multiple = props.multiple,
		},
	)

	label_text := props.label != "" ? props.label : "Click to upload or drag and drop"
	content := k.span(
		doc,
		{
			class = "dropzone__content",
			attributes = {k.attribute("data-keralam-dropzone-target", "content")},
		},
		k.span(
			doc,
			{class = "dropzone__icon-wrapper", attributes = {k.attribute("aria-hidden", "true")}},
			icon(doc, {name = .cloud_arrow_up, size = .large}),
		),
		k.span(doc, {class = "dropzone__text"}, k.text(doc, label_text)),
		props.help != "" ? k.span(doc, {id = help_id, class = "dropzone__help"}, k.text(doc, props.help)) : k.NODE_NONE,
	)
	preview := k.span(
		doc,
		{
			class = "dropzone__preview",
			attributes = {k.attribute("data-keralam-dropzone-target", "preview"), k.hidden()},
		},
		k.span(
			doc,
			{class = "dropzone__icon-wrapper", attributes = {k.attribute("aria-hidden", "true")}},
			icon(doc, {name = .file_text, size = .large}),
		),
		k.span(doc, {class = "dropzone__text"}, k.text(doc, "Click, drop or paste to replace")),
	)
	// The label holds only inline content, so it is valid HTML: spans, not divs and paragraphs.
	area := label(doc, {class = "dropzone__label", for_ = input_id}, content, preview)

	file_list := k.ul(
		doc,
		{
			class = "dropzone__file-list",
			attributes = {
				k.attribute("data-keralam-dropzone-target", "fileList"),
				k.attribute("aria-label", "Selected files"),
			},
		},
	)
	status := k.div(
		doc,
		{
			id = status_id,
			class = "visually-hidden",
			attributes = {
				k.role("status"),
				k.attribute("aria-live", "polite"),
				k.attribute("data-keralam-dropzone-target", "status"),
			},
		},
	)
	message := k.NODE_NONE
	if props.error != "" {
		message = k.div(
			doc,
			{id = message_id, class = "dropzone__error", attributes = {k.role("alert")}},
			icon(doc, {name = .warning, size = .small}),
			k.span(doc, {}, k.text(doc, props.error)),
		)
	}
	rejections := k.div(
		doc,
		{
			class = "dropzone__rejections",
			attributes = {k.role("alert"), k.attribute("data-keralam-dropzone-target", "rejections")},
		},
	)

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + DROPZONE_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"dropzone attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	extras := [?]k.Attribute {
		k.attribute("data-controller", "keralam-dropzone"),
		k.attribute(
			"data-action",
			"dragover->keralam-dropzone#dragover dragleave->keralam-dropzone#dragleave drop->keralam-dropzone#drop paste->keralam-dropzone#paste",
		),
		k.attribute("data-keralam-dropzone-disabled-value", props.disabled ? "true" : "false"),
		k.attribute("data-keralam-dropzone-multiple-value", props.multiple ? "true" : "false"),
		k.attribute("data-keralam-dropzone-accept-value", props.accept),
		k.attribute(
			"data-keralam-dropzone-max-files-value",
			k.doc_format(doc, "%d", props.max_files),
		),
		k.attribute(
			"data-keralam-dropzone-max-bytes-value",
			k.doc_format(doc, "%d", props.max_bytes),
		),
		k.attribute(
			"data-keralam-dropzone-remove-label-value",
			props.remove_label != "" ? props.remove_label : "Remove",
		),
	}
	copy(attributes[attributes_count:], extras[:])
	attributes_count += len(extras)

	base := props.base
	base.id = root_id
	base.class = dropzone_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.div(
		doc,
		base,
		k.div(doc, {class = "dropzone__area"}, control, area),
		file_list,
		rejections,
		status,
		message,
	)
}

@(private)
dropzone_class :: proc(doc: ^k.Doc, props: Dropzone_Props) -> string {
	radius_class :=
		props.radius == .default ? "" : k.doc_format(doc, " dropzone--%s", radius_names[props.radius])
	error_class := props.error != "" ? " dropzone--error" : ""
	disabled_class := props.disabled ? " dropzone--disabled" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"dropzone dropzone--%s%s%s%s%s%s",
		size_names[props.size],
		radius_class,
		error_class,
		disabled_class,
		separator,
		props.class,
	)
}
