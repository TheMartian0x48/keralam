package component

import "core:strings"
import k "kashmir:."

// ---------- enums ----------

// How a long line is treated. soft is first: it is the browser default, a line wraps on
// screen and is submitted as one line.
Input_Textarea_Wrap :: enum u8 {
	soft,
	hard, // line breaks are added to the submitted text where it wrapped
	off, // no wrapping; the field scrolls sideways (code, logs)
}

@(private)
input_textarea_wrap_names := [Input_Textarea_Wrap]k.Textarea_Wrap {
	.soft = .soft,
	.hard = .hard,
	.off  = .off,
}

// Which handle the user gets to drag. vertical is first, as in the browser.
Input_Textarea_Resize :: enum u8 {
	vertical,
	none,
	both,
	auto, // grows with its content, with no script: Chrome and Edge only for now
}

@(private)
input_textarea_resize_names := [Input_Textarea_Resize]string {
	.vertical = "vertical",
	.none     = "none",
	.both     = "both",
	.auto     = "auto",
}

INPUT_TEXTAREA_ROWS_MAX :: 1000

// ---------- props ----------

// A multi-line text field.
//
//   input_textarea(doc, {name = "bio", placeholder = "Tell us about yourself", rows = 4})
//
// It is an input: it takes the same size, radius, error and disabled styles as input_text,
// and placeholder, required and read_only come from the same group of fields. Height comes
// from rows, not from CSS.
//
// A browser drops one newline straight after <textarea>, so a value that starts with a
// newline would lose it. The value is written with one extra newline in front, which the
// parser eats, so any value reads back exactly as given.
//
// resize = .auto sizes the field to its content with the field-sizing property, which
// Chrome and Edge support; other browsers show a normal textarea with the vertical handle.
//
// Asserts: min_length > max_length, rows over INPUT_TEXTAREA_ROWS_MAX, and read_only or
// required together with disabled.
Input_Textarea_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	rows:         u32, // visible lines; 0 = the browser's default (2)
	min_length:   u32, // 0 = unset
	max_length:   u32, // 0 = unset
	wrap:         Input_Textarea_Wrap,
	resize:       Input_Textarea_Resize,
	autocomplete: Input_Text_Autocomplete,
}

// ---------- procs ----------

// Composition order: input input--{size} [input--{radius}] [input--error] [input--disabled] textarea textarea--resize-{resize} [class]
input_textarea :: proc(doc: ^k.Doc, props: Input_Textarea_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	assert(props.rows <= INPUT_TEXTAREA_ROWS_MAX, "textarea rows exceeds INPUT_TEXTAREA_ROWS_MAX")

	// k.textarea copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + INPUT_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"textarea attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	if props.error {
		attributes[attributes_count] = k.attribute("aria-invalid", "true")
		attributes_count += 1
	}
	if props.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", props.aria_label)
		attributes_count += 1
	}
	if props.aria_described_by != "" {
		attributes[attributes_count] = k.attribute("aria-describedby", props.aria_described_by)
		attributes_count += 1
	}

	base := props.base
	base.class = input_textarea_class(doc, props)
	base.attributes = attributes[:attributes_count]

	// The parser drops one newline right after the tag. A leading "\n" in front of the
	// value is that newline, so the value itself comes through untouched. Kashmir escapes
	// the text, and writes the "\n" as a literal newline.
	content := k.text(doc, strings.concatenate({"\n", props.value}, context.temp_allocator))

	return k.textarea(
		doc,
		{
			base = base,
			name = props.name,
			placeholder = props.placeholder,
			autocomplete = input_text_autocomplete_names[props.autocomplete],
			rows = props.rows,
			min_length = props.min_length,
			max_length = props.max_length,
			wrap = input_textarea_wrap_names[props.wrap],
			disabled = props.disabled,
			read_only = props.read_only,
			required = props.required,
		},
		content,
	)
}

@(private)
input_textarea_class :: proc(doc: ^k.Doc, props: Input_Textarea_Props) -> string {
	return k.doc_format(
		doc,
		"%s textarea textarea--resize-%s",
		input_class(doc, props.common, "input"),
		input_textarea_resize_names[props.resize],
	)
}
