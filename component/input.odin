package component

import "core:math"
import "core:strconv"
import "core:strings"
import k "kashmir:."

// One proc and one props struct per kind of field. The type is in the name, so a pattern
// on a number, a step on text or a string where a date belongs are compile errors: the
// field does not exist. What can not be a type rule asserts when the page is built.
//
//   input_email(doc, {name = "email", placeholder = "you@example.com", required = true})
//   input_number(doc, {name = "age", min = 0.0, max = 120.0, step = 1.0})
//   input_date(doc, {name = "due", min = Input_Date{2026, 1, 1}})
//   input_password(doc, {name = "pw", autocomplete = .new, min_length = 8})
//   input_range(doc, {name = "volume", min = 0.0, max = 100.0, value = 40.0})
//   input_color(doc, {name = "accent", value = Input_Color{37, 99, 235}})
//   input_file(doc, {name = "upload", accept = "image/*", multiple = true})
//
// input is a proc group over all of them, for when you name the props type:
//
//   input(Input_Email_Props{name = "email"})   // not input({name = "email"}): ambiguous
//
// Asserts, for what a type can not say:
//   min <= max, min_length <= max_length, step > 0, finite numbers
//   a date is a real date (not 30 February), a time is a real time, a week exists
//   read_only and disabled together, or required and disabled together
//   type="password" never carries a value; there is no field for one
//
// Not here, on purpose: submit, reset and button (use the button component), checkbox and
// radio (their own components), and image (a legacy button). input_toggle, an on/off switch
// built on a checkbox, is in toggle.odin and is in the `input` group below.
//
// Which fields a kind has follows the HTML spec, which I checked in Chrome: placeholder
// exists only on the text-like kinds and number; read_only does not exist on range,
// color or file (browsers ignore it there); required does not exist on range or color
// (a slider and a colour picker always have a value). The procs for those kinds leave the
// field out, so it can not be written.

// ---------- enums and constants ----------

// What a browser may offer to fill in. Each text-like field has its own set in its own
// enum, so a hint can not be put on a field it does not suit. unset omits the attribute.
Input_Text_Autocomplete :: enum u8 {
	unset,
	off,
	name,
	organization,
	address_level1, // province or state
	address_level2, // city or locality
	postal_code,
	country,
}

Input_Email_Autocomplete :: enum u8 {
	unset,
	off,
	email,
	username,
}

Input_Tel_Autocomplete :: enum u8 {
	unset,
	off,
	tel,
}

Input_Url_Autocomplete :: enum u8 {
	unset,
	off,
	url,
}

Input_Username_Autocomplete :: enum u8 {
	username, // zero value: a username field wants this hint
	off,
}

Input_Password_Autocomplete :: enum u8 {
	unset,
	off,
	current, // signing in
	new, // choosing a password
}

@(private)
input_text_autocomplete_names := [Input_Text_Autocomplete]string {
	.unset          = "",
	.off            = "off",
	.name           = "name",
	.organization   = "organization",
	.address_level1 = "address-level1",
	.address_level2 = "address-level2",
	.postal_code    = "postal-code",
	.country        = "country",
}

@(private)
input_email_autocomplete_names := [Input_Email_Autocomplete]string {
	.unset    = "",
	.off      = "off",
	.email    = "email",
	.username = "username",
}

@(private)
input_tel_autocomplete_names := [Input_Tel_Autocomplete]string {
	.unset = "",
	.off   = "off",
	.tel   = "tel",
}

@(private)
input_url_autocomplete_names := [Input_Url_Autocomplete]string {
	.unset = "",
	.off   = "off",
	.url   = "url",
}

@(private)
input_username_autocomplete_names := [Input_Username_Autocomplete]string {
	.username = "username",
	.off      = "off",
}

@(private)
input_password_autocomplete_names := [Input_Password_Autocomplete]string {
	.unset   = "",
	.off     = "off",
	.current = "current-password",
	.new     = "new-password",
}

INPUT_NUMBER_BYTES_MAX :: 512 // a float printed in full: 1e308 is 309 digits
INPUT_EXTRAS_MAX :: 3 // aria-invalid, aria-label, aria-describedby

// ---------- shared props ----------

// A calendar date, rendered as YYYY-MM-DD.
Input_Date :: struct {
	year:  u16,
	month: u8,
	day:   u8,
}

// A date and time with no timezone, rendered as YYYY-MM-DDTHH:MM.
Input_Datetime :: struct {
	using date: Input_Date,
	hour:       u8,
	minute:     u8,
}

// A time of day, rendered as HH:MM.
Input_Time :: struct {
	hour:   u8,
	minute: u8,
}

// A month of a year, rendered as YYYY-MM.
Input_Month :: struct {
	year:  u16,
	month: u8,
}

// An ISO 8601 week, rendered as YYYY-Www. Some years have 52 weeks and some 53.
Input_Week :: struct {
	year: u16,
	week: u8,
}

// A colour, rendered as #rrggbb. The type is three bytes, so it can not be malformed.
Input_Color :: struct {
	r: u8,
	g: u8,
	b: u8,
}

// What every field has. Embedded with `using`, so these are plain fields on each props
// struct: input_email(doc, {name = "e", size = .large, error = true}). Fields that only
// some kinds have (placeholder, read_only, required) are on those kinds' structs instead.
Input_Common :: struct {
	using base:        k.Base, // id, class (appended after the generated classes), style, attributes
	name:              string,

	// appearance
	size:              Size, // see component.odin
	radius:            Radius, // see component.odin

	// state
	disabled:          bool,
	error:             bool, // sets aria-invalid and the error styling

	// accessibility
	aria_label:        string,
	aria_described_by: string, // id of an element with more context, e.g. an error message
}

// What the text-like kinds and number add: they show a placeholder, can be read-only,
// and can be required.
Input_Entry :: struct {
	using common: Input_Common,
	placeholder:  string,
	required:     bool,
	read_only:    bool,
}

// What the date family, time, month, week and file add: required and read-only, but no
// placeholder (browsers do not show one on these).
Input_Picker :: struct {
	using common: Input_Common,
	required:     bool,
	read_only:    bool,
}

// ---------- props, one per kind ----------

Input_Text_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	min_length:   u32, // 0 = unset
	max_length:   u32, // 0 = unset
	pattern:      string, // a regular expression the whole value must match
	autocomplete: Input_Text_Autocomplete,
}

Input_Email_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	min_length:   u32,
	max_length:   u32,
	pattern:      string,
	autocomplete: Input_Email_Autocomplete,
}

// A login name: text with the username hint on, and no capitals or spell-checking
// forced on the browser.
Input_Username_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	min_length:   u32,
	max_length:   u32,
	pattern:      string,
	autocomplete: Input_Username_Autocomplete,
}

Input_Tel_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	min_length:   u32,
	max_length:   u32,
	pattern:      string,
	autocomplete: Input_Tel_Autocomplete,
}

Input_Url_Props :: struct {
	using entry:  Input_Entry,
	value:        string,
	min_length:   u32,
	max_length:   u32,
	pattern:      string,
	autocomplete: Input_Url_Autocomplete,
}

Input_Search_Props :: struct {
	using entry: Input_Entry,
	value:       string,
	min_length:  u32,
	max_length:  u32,
	pattern:     string,
}

// There is no value field: a password in the page source is a leak.
Input_Password_Props :: struct {
	using entry:  Input_Entry,
	min_length:   u32,
	max_length:   u32,
	pattern:      string,
	autocomplete: Input_Password_Autocomplete,
}

Input_Number_Props :: struct {
	using entry: Input_Entry,
	value:       Maybe(f64),
	min:         Maybe(f64),
	max:         Maybe(f64),
	step:        Maybe(f64), // greater than zero
}

Input_Date_Props :: struct {
	using picker: Input_Picker,
	value:        Maybe(Input_Date),
	min:          Maybe(Input_Date),
	max:          Maybe(Input_Date),
}

Input_Datetime_Props :: struct {
	using picker: Input_Picker,
	value:        Maybe(Input_Datetime),
	min:          Maybe(Input_Datetime),
	max:          Maybe(Input_Datetime),
}

// A time of day. min greater than max is allowed: it means overnight, "from 22:00 to
// 06:00", which the browser accepts.
Input_Time_Props :: struct {
	using picker: Input_Picker,
	value:        Maybe(Input_Time),
	min:          Maybe(Input_Time),
	max:          Maybe(Input_Time),
	step:         Maybe(u32), // seconds, greater than zero; 60 is the default
}

Input_Month_Props :: struct {
	using picker: Input_Picker,
	value:        Maybe(Input_Month),
	min:          Maybe(Input_Month),
	max:          Maybe(Input_Month),
}

Input_Week_Props :: struct {
	using picker: Input_Picker,
	value:        Maybe(Input_Week),
	min:          Maybe(Input_Week),
	max:          Maybe(Input_Week),
}

// A slider. It always has a value (the middle of its range if you give none), so there
// is no required, and no placeholder or read_only: browsers ignore them here.
Input_Range_Props :: struct {
	using common: Input_Common,
	value:        Maybe(f64),
	min:          Maybe(f64), // browser default 0
	max:          Maybe(f64), // browser default 100
	step:         Maybe(f64), // greater than zero
}

// A colour picker. It always has a value (black if you give none), so there is no
// required, and no placeholder or read_only.
Input_Color_Props :: struct {
	using common: Input_Common,
	value:        Maybe(Input_Color),
}

// A file chooser. A browser never lets a page set a file's value, so there is none.
// A form that uploads needs enctype="multipart/form-data" on the form, not here.
Input_File_Props :: struct {
	using picker: Input_Picker,
	accept:       string, // what to offer, e.g. "image/*" or ".pdf,.docx"; the caller's to get right
	multiple:     bool,
	capture:      k.Input_Capture, // on phones: use the front or back camera
}

// A field the user never sees: it carries a value to the server or to a script, such as
// a CSRF token, a record id, or the real value behind a label. It never renders, so it
// has none of the shared fields (no size, radius, error or ARIA) and no styles.
//
// name is not required: a hidden field with no name is not submitted, but a script can
// still read it, which is how the autocomplete uses one.
Input_Hidden_Props :: struct {
	using base: k.Base, // id, attributes; a class has nothing to style
	name:       string,
	value:      string,
	disabled:   bool, // a disabled field is not submitted
}

// ---------- procs ----------

input :: proc {
	input_color,
	input_date,
	input_datetime,
	input_email,
	input_file,
	input_hidden,
	input_month,
	input_number,
	input_password,
	input_range,
	input_search,
	input_select,
	input_tel,
	input_text,
	input_textarea,
	input_time,
	input_url,
	input_week,

	// extras: not an HTML input type, but part of the family
	input_toggle,
	input_username,
}

input_text :: proc(doc: ^k.Doc, props: Input_Text_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .text,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_text_autocomplete_names[props.autocomplete],
		},
	)
}

input_email :: proc(doc: ^k.Doc, props: Input_Email_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .email,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_email_autocomplete_names[props.autocomplete],
		},
	)
}

input_username :: proc(doc: ^k.Doc, props: Input_Username_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .text,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_username_autocomplete_names[props.autocomplete],
			autocapitalize = .none,
		},
		extra = {k.spellcheck(false)},
	)
}

input_tel :: proc(doc: ^k.Doc, props: Input_Tel_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .tel,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_tel_autocomplete_names[props.autocomplete],
		},
	)
}

input_url :: proc(doc: ^k.Doc, props: Input_Url_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .url,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_url_autocomplete_names[props.autocomplete],
		},
	)
}

input_search :: proc(doc: ^k.Doc, props: Input_Search_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .search,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = props.value,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
		},
	)
}

input_password :: proc(doc: ^k.Doc, props: Input_Password_Props) -> k.Node_Id {
	input_assert_text(
		props.common,
		props.required,
		props.read_only,
		props.min_length,
		props.max_length,
	)
	return input_render(
		doc,
		props.common,
		{
			type = .password,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			min_length = props.min_length,
			max_length = props.max_length,
			pattern = props.pattern,
			autocomplete = input_password_autocomplete_names[props.autocomplete],
		},
	)
}

input_number :: proc(doc: ^k.Doc, props: Input_Number_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_finite(value), "input value must be finite")
	assert(!has_low || input_finite(low), "input min must be finite")
	assert(!has_high || input_finite(high), "input max must be finite")
	assert(!has_low || !has_high || low <= high, "input min is greater than max")
	step, has_step := props.step.?
	assert(!has_step || (input_finite(step) && step > 0), "input step must be positive and finite")

	return input_render(
		doc,
		props.common,
		{
			type = .number,
			placeholder = props.placeholder,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_number_text(doc, value) : "",
			min = has_low ? input_number_text(doc, low) : "",
			max = has_high ? input_number_text(doc, high) : "",
			step = has_step ? input_number_text(doc, step) : "",
		},
	)
}

input_date :: proc(doc: ^k.Doc, props: Input_Date_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_date_valid(value), "input value is not a real date")
	assert(!has_low || input_date_valid(low), "input min is not a real date")
	assert(!has_high || input_date_valid(high), "input max is not a real date")
	assert(
		!has_low || !has_high || input_date_key(low) <= input_date_key(high),
		"input min is greater than max",
	)

	return input_render(
		doc,
		props.common,
		{
			type = .date,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_date_text(doc, value) : "",
			min = has_low ? input_date_text(doc, low) : "",
			max = has_high ? input_date_text(doc, high) : "",
		},
	)
}

input_datetime :: proc(doc: ^k.Doc, props: Input_Datetime_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_datetime_valid(value), "input value is not a real date and time")
	assert(!has_low || input_datetime_valid(low), "input min is not a real date and time")
	assert(!has_high || input_datetime_valid(high), "input max is not a real date and time")
	assert(
		!has_low || !has_high || input_datetime_key(low) <= input_datetime_key(high),
		"input min is greater than max",
	)

	return input_render(
		doc,
		props.common,
		{
			type = .datetime_local,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_datetime_text(doc, value) : "",
			min = has_low ? input_datetime_text(doc, low) : "",
			max = has_high ? input_datetime_text(doc, high) : "",
		},
	)
}

input_time :: proc(doc: ^k.Doc, props: Input_Time_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_time_valid(value), "input value is not a real time")
	assert(!has_low || input_time_valid(low), "input min is not a real time")
	assert(!has_high || input_time_valid(high), "input max is not a real time")
	step, has_step := props.step.?
	assert(!has_step || step > 0, "input step must be greater than zero")
	// min > max is deliberately allowed: it is an overnight range.

	return input_render(
		doc,
		props.common,
		{
			type = .time,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_time_text(doc, value) : "",
			min = has_low ? input_time_text(doc, low) : "",
			max = has_high ? input_time_text(doc, high) : "",
			step = has_step ? k.doc_format(doc, "%d", step) : "",
		},
	)
}

input_month :: proc(doc: ^k.Doc, props: Input_Month_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_month_valid(value), "input value is not a real month")
	assert(!has_low || input_month_valid(low), "input min is not a real month")
	assert(!has_high || input_month_valid(high), "input max is not a real month")
	assert(
		!has_low || !has_high || input_month_key(low) <= input_month_key(high),
		"input min is greater than max",
	)

	return input_render(
		doc,
		props.common,
		{
			type = .month,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_month_text(doc, value) : "",
			min = has_low ? input_month_text(doc, low) : "",
			max = has_high ? input_month_text(doc, high) : "",
		},
	)
}

input_week :: proc(doc: ^k.Doc, props: Input_Week_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	assert(!has_value || input_week_valid(value), "input value is not a real ISO week")
	assert(!has_low || input_week_valid(low), "input min is not a real ISO week")
	assert(!has_high || input_week_valid(high), "input max is not a real ISO week")
	assert(
		!has_low || !has_high || input_week_key(low) <= input_week_key(high),
		"input min is greater than max",
	)

	return input_render(
		doc,
		props.common,
		{
			type = .week,
			required = props.required,
			read_only = props.read_only,
			value = has_value ? input_week_text(doc, value) : "",
			min = has_low ? input_week_text(doc, low) : "",
			max = has_high ? input_week_text(doc, high) : "",
		},
	)
}

input_range :: proc(doc: ^k.Doc, props: Input_Range_Props) -> k.Node_Id {
	value, has_value := props.value.?
	low, has_low := props.min.?
	high, has_high := props.max.?
	step, has_step := props.step.?
	assert(!has_value || input_finite(value), "input value must be finite")
	assert(!has_low || input_finite(low), "input min must be finite")
	assert(!has_high || input_finite(high), "input max must be finite")
	assert(!has_step || (input_finite(step) && step > 0), "input step must be positive and finite")

	// A slider's range is its own: the browser clamps a value outside it. Check against
	// the browser defaults (0 to 100) when one end is left unset.
	effective_low := has_low ? low : 0.0
	effective_high := has_high ? high : 100.0
	assert(effective_low < effective_high, "input range min must be less than max")
	assert(
		!has_value || (value >= effective_low && value <= effective_high),
		"input range value is outside min and max",
	)

	return input_render(
		doc,
		props.common,
		{
			type = .range,
			value = has_value ? input_number_text(doc, value) : "",
			min = has_low ? input_number_text(doc, low) : "",
			max = has_high ? input_number_text(doc, high) : "",
			step = has_step ? input_number_text(doc, step) : "",
		},
		block = "input-range",
	)
}

input_color :: proc(doc: ^k.Doc, props: Input_Color_Props) -> k.Node_Id {
	// A colour picker has no placeholder, required or read_only; disabled is the only state.
	// Its value is three bytes, so it can not be malformed and needs no further check.
	value, has_value := props.value.?
	return input_render(
		doc,
		props.common,
		{
			type = .color,
			value = has_value ? k.doc_format(doc, "#%02x%02x%02x", value.r, value.g, value.b) : "",
		},
		block = "input-color",
	)
}

input_file :: proc(doc: ^k.Doc, props: Input_File_Props) -> k.Node_Id {
	input_assert_state(props.common, props.required, props.read_only)
	return input_render(
		doc,
		props.common,
		{
			type = .file,
			required = props.required,
			read_only = props.read_only,
			accept = props.accept,
			multiple = props.multiple,
			capture = props.capture,
		},
		block = "input-file",
	)
}

input_hidden :: proc(doc: ^k.Doc, props: Input_Hidden_Props) -> k.Node_Id {
	assert(len(props.attributes) <= ATTRIBUTES_MAX, "hidden input attributes exceeds ATTRIBUTES_MAX")
	// A hidden field that is also disabled with no name carries nothing anywhere.
	assert(props.name != "" || !props.disabled, "hidden input is disabled and has no name")
	return k.input(
		doc,
		{
			base = props.base,
			type = .hidden,
			name = props.name,
			value = props.value,
			disabled = props.disabled,
		},
	)
}

// ---------- the one renderer ----------

// Every kind ends here, so the markup, classes and ARIA are written once. `fields` holds
// what differs by kind; common holds what is the same for all.
@(private)
input_render :: proc(
	doc: ^k.Doc,
	common: Input_Common,
	fields: k.Input_Props,
	extra: []k.Attribute = nil,
	block := "input",
) -> k.Node_Id {
	// k.input copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(common.attributes)
	assert(
		attributes_count + len(extra) + INPUT_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"input attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], common.attributes)
	for attribute in extra {
		attributes[attributes_count] = attribute
		attributes_count += 1
	}
	if common.error {
		attributes[attributes_count] = k.attribute("aria-invalid", "true")
		attributes_count += 1
	}
	if common.aria_label != "" {
		attributes[attributes_count] = k.attribute("aria-label", common.aria_label)
		attributes_count += 1
	}
	if common.aria_described_by != "" {
		attributes[attributes_count] = k.attribute("aria-describedby", common.aria_described_by)
		attributes_count += 1
	}

	base := common.base
	base.class = input_class(doc, common, block)
	base.attributes = attributes[:attributes_count]

	props := fields
	props.base = base
	props.name = common.name
	props.disabled = common.disabled
	return k.input(doc, props)
}

// Composition order: {block} {block}--{size} [{block}--{radius}] [{block}--error] [{block}--disabled] [class]
// The text boxes share the block "input"; range, color and file are not text boxes and
// have blocks of their own (input-range, input-color, input-file) in input.css.
@(private)
input_class :: proc(doc: ^k.Doc, common: Input_Common, block: string) -> string {
	radius_class :=
		common.radius == .default ? "" : k.doc_format(doc, " %s--%s", block, radius_names[common.radius])
	error_class := common.error ? k.doc_format(doc, " %s--error", block) : ""
	disabled_class := common.disabled ? k.doc_format(doc, " %s--disabled", block) : ""
	separator := common.class != "" ? " " : ""

	return k.doc_format(
		doc,
		"%s %s--%s%s%s%s%s%s",
		block,
		block,
		size_names[common.size],
		radius_class,
		error_class,
		disabled_class,
		separator,
		common.class,
	)
}

// ---------- asserts ----------

@(private)
input_assert_state :: proc(common: Input_Common, required, read_only: bool) {
	assert(!(read_only && common.disabled), "input is both read_only and disabled")
	assert(!(required && common.disabled), "input is both required and disabled")
}

@(private)
input_assert_text :: proc(
	common: Input_Common,
	required, read_only: bool,
	min_length, max_length: u32,
) {
	input_assert_state(common, required, read_only)
	assert(
		max_length == 0 || min_length <= max_length,
		"input min_length is greater than max_length",
	)
}

@(private)
input_finite :: proc(number: f64) -> bool {
	return !math.is_nan(number) && !math.is_inf(number)
}

// ---------- dates ----------

@(private)
input_days_in_month :: proc(year: u16, month: u8) -> u8 {
	switch month {
	case 2:
		leap := (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
		return leap ? 29 : 28
	case 4, 6, 9, 11:
		return 30
	}
	return 31
}

@(private)
input_date_valid :: proc(date: Input_Date) -> bool {
	if date.year < 1 || date.year > 9999 do return false
	if date.month < 1 || date.month > 12 do return false
	return date.day >= 1 && date.day <= input_days_in_month(date.year, date.month)
}

@(private)
input_datetime_valid :: proc(value: Input_Datetime) -> bool {
	return input_date_valid(value.date) && value.hour < 24 && value.minute < 60
}

@(private)
input_date_key :: proc(date: Input_Date) -> u32 {
	return u32(date.year) * 10000 + u32(date.month) * 100 + u32(date.day)
}

@(private)
input_datetime_key :: proc(value: Input_Datetime) -> u64 {
	return u64(input_date_key(value.date)) * 10000 + u64(value.hour) * 100 + u64(value.minute)
}

@(private)
input_time_valid :: proc(value: Input_Time) -> bool {
	return value.hour < 24 && value.minute < 60
}

@(private)
input_month_valid :: proc(value: Input_Month) -> bool {
	return value.year >= 1 && value.year <= 9999 && value.month >= 1 && value.month <= 12
}

@(private)
input_month_key :: proc(value: Input_Month) -> u32 {
	return u32(value.year) * 100 + u32(value.month)
}

// An ISO year has 53 weeks when 1 January is a Thursday, or a Wednesday in a leap year;
// otherwise 52. Weekday by Zeller-style arithmetic on the proleptic Gregorian calendar.
@(private)
input_weeks_in_year :: proc(year: u16) -> u8 {
	// The weekday of 31 December is p(y) = (y + y/4 - y/100 + y/400) mod 7, 0 = Sunday.
	// A year has 53 weeks when 31 December is a Thursday, or the year before ended on a
	// Wednesday. year is at most 9999, so the sum is below 25,000 and fits a u32; the
	// year before is year - 1, which is why year is at least 1 here (the caller checks).
	pattern :: proc(y: u32) -> u32 {return (y + y / 4 - y / 100 + y / 400) % 7}
	assert(year >= 1, "week year must be at least 1")
	y := u32(year)
	if pattern(y) == 4 || pattern(y - 1) == 3 do return 53
	return 52
}

@(private)
input_week_valid :: proc(value: Input_Week) -> bool {
	if value.year < 1 || value.year > 9999 do return false
	return value.week >= 1 && value.week <= input_weeks_in_year(value.year)
}

@(private)
input_week_key :: proc(value: Input_Week) -> u32 {
	return u32(value.year) * 100 + u32(value.week)
}

// ---------- text ----------

// The shortest text that reads back as the same number. write_float prefixes positive
// numbers with '+', which is not a valid HTML number, so it is dropped.
@(private)
input_number_text :: proc(doc: ^k.Doc, number: f64) -> string {
	buffer: [INPUT_NUMBER_BYTES_MAX]u8
	text := strconv.write_float(buffer[:], number, 'f', -1, 64)
	return k.doc_format(doc, "%s", strings.trim_prefix(text, "+"))
}

@(private)
input_date_text :: proc(doc: ^k.Doc, date: Input_Date) -> string {
	return k.doc_format(doc, "%04d-%02d-%02d", date.year, date.month, date.day)
}

@(private)
input_time_text :: proc(doc: ^k.Doc, value: Input_Time) -> string {
	return k.doc_format(doc, "%02d:%02d", value.hour, value.minute)
}

@(private)
input_month_text :: proc(doc: ^k.Doc, value: Input_Month) -> string {
	return k.doc_format(doc, "%04d-%02d", value.year, value.month)
}

@(private)
input_week_text :: proc(doc: ^k.Doc, value: Input_Week) -> string {
	return k.doc_format(doc, "%04d-W%02d", value.year, value.week)
}

@(private)
input_datetime_text :: proc(doc: ^k.Doc, value: Input_Datetime) -> string {
	return k.doc_format(
		doc,
		"%04d-%02d-%02dT%02d:%02d",
		value.year,
		value.month,
		value.day,
		value.hour,
		value.minute,
	)
}
