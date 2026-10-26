package main

// One realistic form that uses every input control.
//
// A sign-up and profile form for an imaginary clinic. Each control that sits under a label
// goes through form_field, which hands the control its id and its aria-describedby, so the
// label, the control and the help or error text are wired by construction. Controls that
// carry their own label (checkbox, radio group, toggle) are used directly.
//
// A control proc can not capture variables, so what varies between the clean form and the
// failed-submit form is read from the package-level form_state.

import c "../component"
import k "kashmir:."

FORM_PATH :: "/form"

// ---------- constants ----------

form_countries :: [?]c.Input_Select_Option {
	{"us", "United States", false},
	{"uk", "United Kingdom", false},
	{"in", "India", false},
	{"jp", "Japan", false},
}
form_regions :: [?]c.Input_Select_Group {
	{"Europe", {{"uk", "United Kingdom", false}, {"fr", "France", false}, {"de", "Germany", false}}, false},
	{"Asia", {{"in", "India", false}, {"jp", "Japan", false}}, false},
	{"Americas", {{"us", "United States", false}, {"br", "Brazil", false}}, false},
}
form_plans :: [?]c.Radio_Option{{"free", "Free", false}, {"pro", "Pro", false}, {"clinic", "Clinic", true}}

// /form shows the clean form; /form?errors shows the same form after a failed submit, with
// a message on several fields.
Form_State :: struct {
	errors: bool,
}

form_state: Form_State

// A message for a field, or nothing when the form is clean.
form_error :: proc(message: string) -> string {
	return form_state.errors ? message : ""
}

// The help text, left out when the field is showing an error instead (form_field takes one
// message at a time, because the CSS shows one).
form_help :: proc(text: string, error: string) -> string {
	return form_state.errors && error != "" ? "" : text
}

// ---------- the controls, one proc each ----------
// Each passes the wiring straight through: id, error and aria_described_by.

control_full_name :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_text(
		doc,
		{
			id = w.id,
			name = "full_name",
			placeholder = "Ada Lovelace",
			required = true,
			autocomplete = .name,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_username :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_username(
		doc,
		{
			id = w.id,
			name = "username",
			placeholder = "ada",
			required = true,
			min_length = 3,
			max_length = 20,
			pattern = "[a-z0-9_]+",
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_email :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_email(
		doc,
		{
			id = w.id,
			name = "email",
			placeholder = "ada@example.com",
			required = true,
			autocomplete = .email,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_phone :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_tel(
		doc,
		{
			id = w.id,
			name = "phone",
			placeholder = "+44 20 7946 0958",
			autocomplete = .tel,
			pattern = "[0-9+ ()-]{7,20}",
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_website :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_url(
		doc,
		{
			id = w.id,
			name = "website",
			placeholder = "https://example.com",
			autocomplete = .url,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_password :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_password(
		doc,
		{
			id = w.id,
			name = "password",
			placeholder = "At least 8 characters",
			required = true,
			min_length = 8,
			autocomplete = .new,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_confirm :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_password(
		doc,
		{
			id = w.id,
			name = "password_confirm",
			placeholder = "Type it again",
			required = true,
			min_length = 8,
			autocomplete = .new,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_birth_date :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_date(
		doc,
		{
			id = w.id,
			name = "birth_date",
			required = true,
			min = c.Input_Date{1900, 1, 1},
			max = c.Input_Date{2026, 12, 31},
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_age :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_number(
		doc,
		{
			id = w.id,
			name = "household",
			placeholder = "1",
			min = 1.0,
			max = 12.0,
			step = 1.0,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_country :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	groups := form_regions
	return c.input_select(
		doc,
		{
			id = w.id,
			name = "country",
			placeholder = "Choose a country",
			required = true,
			groups = groups[:],
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_city :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	cities := [?]c.Autocomplete_Option {
		{"lon", "London"},
		{"par", "Paris"},
		{"ber", "Berlin"},
		{"del", "Delhi"},
		{"tok", "Tokyo"},
		{"nyc", "New York"},
		{"sao", "São Paulo"},
	}
	return c.autocomplete(
		doc,
		{
			input_id = w.id,
			name = "city",
			label = "City",
			placeholder = "Start typing a city",
			options = cities[:],
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_search :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_search(
		doc,
		{
			id = w.id,
			name = "doctor",
			placeholder = "Name or speciality",
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_appointment :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_datetime(
		doc,
		{
			id = w.id,
			name = "appointment",
			required = true,
			min = c.Input_Datetime{{2026, 1, 1}, 8, 0},
			max = c.Input_Datetime{{2026, 12, 31}, 18, 0},
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_preferred_time :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_time(
		doc,
		{
			id = w.id,
			name = "preferred_time",
			min = c.Input_Time{8, 0},
			max = c.Input_Time{18, 0},
			step = 900,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_billing_month :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_month(
		doc,
		{
			id = w.id,
			name = "billing_month",
			value = c.Input_Month{2026, 11},
			min = c.Input_Month{2026, 1},
			max = c.Input_Month{2027, 12},
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_review_week :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_week(
		doc,
		{
			id = w.id,
			name = "review_week",
			value = c.Input_Week{2026, 53},
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_satisfaction :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_range(
		doc,
		{
			id = w.id,
			name = "satisfaction",
			min = 0.0,
			max = 10.0,
			step = 1.0,
			value = 7.0,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_accent :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_color(
		doc,
		{
			id = w.id,
			name = "accent",
			value = c.Input_Color{37, 99, 235},
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_avatar :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_file(
		doc,
		{
			id = w.id,
			name = "avatar",
			accept = "image/*",
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_reports :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_file(
		doc,
		{
			id = w.id,
			name = "reports",
			accept = ".pdf,.docx",
			multiple = true,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

control_notes :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_textarea(
		doc,
		{
			id = w.id,
			name = "notes",
			rows = 4,
			max_length = 500,
			placeholder = "Anything the doctor should know",
			resize = .auto,
			error = w.error,
			aria_described_by = w.aria_described_by,
		},
	)
}

// ---------- layout ----------

form_section :: proc(doc: ^k.Doc, title: string, children: ..k.Node_Id) -> k.Node_Id {
	nodes := make([dynamic]k.Node_Id, 0, len(children) + 2, context.temp_allocator)
	append(&nodes, k.h3(doc, {class = "doc-demo__group-title"}, k.text(doc, title)))
	append(&nodes, ..children)
	append(&nodes, c.divider(doc, {}))
	return k.div(doc, {class = "form-page__section"}, ..nodes[:])
}

// Fields side by side on a wide screen, stacked on a narrow one.
form_row :: proc(doc: ^k.Doc, children: ..k.Node_Id) -> k.Node_Id {
	return k.div(doc, {class = "form-page__row"}, ..children)
}

demo_form :: proc(doc: ^k.Doc) -> k.Node_Id {
	plans := form_plans
	interests := [?]string{"Cardiology", "Dermatology", "Dentistry", "Physiotherapy"}
	interest_nodes := make([dynamic]k.Node_Id, 0, len(interests), context.temp_allocator)
	for interest, index in interests {
		append(
			&interest_nodes,
			c.checkbox(
				doc,
				{
					name = "interests",
					value = interest,
					label = interest,
					checked = index == 0,
				},
			),
		)
	}

	return k.form(
		doc,
		{class = "form-page", method = .get, action = FORM_PATH},

		// A token the server would check. Hidden, so it draws nothing.
		c.input_hidden(doc, {name = "csrf", value = "d41d8cd98f00b204"}),

		form_section(
			doc,
			"About you",
			form_row(
				doc,
				c.form_field(doc, {id = "ff-name", label = "Full name", required = true, help = "As it appears on your ID", control = control_full_name}),
				c.form_field(doc, {id = "ff-username", label = "Username", required = true, help = form_help("3 to 20 letters, digits or underscores", "That username is taken"), error = form_error("That username is taken"), control = control_username}),
			),
			form_row(
				doc,
				c.form_field(doc, {id = "ff-email", label = "Email", required = true, error = form_error("Enter a valid email address"), control = control_email}),
				c.form_field(doc, {id = "ff-phone", label = "Phone", help = "Digits, spaces, + and brackets", control = control_phone}),
			),
			form_row(
				doc,
				c.form_field(doc, {id = "ff-birth", label = "Date of birth", required = true, control = control_birth_date}),
				c.form_field(doc, {id = "ff-household", label = "People in your household", help = "1 to 12", control = control_age}),
			),
			c.form_field(doc, {id = "ff-website", label = "Website", help = "Optional", control = control_website}),
		),

		form_section(
			doc,
			"Your account",
			form_row(
				doc,
				c.form_field(doc, {id = "ff-password", label = "Password", required = true, help = form_help("At least 8 characters", "Too short: use at least 8 characters"), error = form_error("Too short: use at least 8 characters"), control = control_password}),
				c.form_field(doc, {id = "ff-confirm", label = "Confirm password", required = true, control = control_confirm}),
			),
			c.radio_group(
				doc,
				{
					id = "rg-plan",
					name = "plan",
					legend = "Choose a plan",
					value = "pro",
					options = plans[:],
					direction = .row,
					required = true,
				},
			),
		),

		form_section(
			doc,
			"Where you are",
			form_row(
				doc,
				c.form_field(doc, {id = "ff-country", label = "Country", required = true, error = form_error("Choose a country"), control = control_country}),
				c.form_field(doc, {id = "ff-city", label = "City", help = "Pick from the list", control = control_city}),
			),
		),

		form_section(
			doc,
			"Your visit",
			form_row(
				doc,
				c.form_field(doc, {id = "ff-doctor", label = "Find a doctor", control = control_search}),
				c.form_field(doc, {id = "ff-appointment", label = "Appointment", required = true, help = "8:00 to 18:00 in 2026", control = control_appointment}),
			),
			form_row(
				doc,
				c.form_field(doc, {id = "ff-time", label = "Preferred time of day", help = "In 15 minute steps", control = control_preferred_time}),
				c.form_field(doc, {id = "ff-month", label = "Billing month", control = control_billing_month}),
			),
			c.form_field(doc, {id = "ff-week", label = "Review week", help = "2026 has 53 weeks", control = control_review_week}),
			k.div(doc, {class = "form-page__checks"}, ..interest_nodes[:]),
		),

		form_section(
			doc,
			"Profile",
			form_row(
				doc,
				c.form_field(doc, {id = "ff-satisfaction", label = "How was your last visit? (0 to 10)", control = control_satisfaction}),
				c.form_field(doc, {id = "ff-accent", label = "Accent colour", help = "Used in your portal", control = control_accent}),
			),
			form_row(
				doc,
				c.form_field(doc, {id = "ff-avatar", label = "Photo", help = form_help("An image", "That file is not an image"), error = form_error("That file is not an image"), control = control_avatar}),
				c.form_field(doc, {id = "ff-reports", label = "Reports", help = "PDF or Word, several allowed", control = control_reports}),
			),
			c.form_field(doc, {id = "ff-notes", label = "Notes", help = "Up to 500 characters", control = control_notes}),
		),

		form_section(
			doc,
			"Preferences",
			k.div(
				doc,
				{class = "form-page__toggles"},
				c.input_toggle(doc, {name = "newsletter", label = "Send me the monthly newsletter", checked = true}),
				c.input_toggle(doc, {name = "reminders", label = "Appointment reminders by text", checked = true}),
				c.input_toggle(doc, {name = "research", label = "Share anonymised data for research"}),
			),
			c.checkbox(doc, {name = "terms", value = "yes", label = "I accept the terms and the privacy notice", required = true, error = form_state.errors, id = "cb-terms"}),
		),

		k.div(
			doc,
			{class = "form-page__actions"},
			c.button(doc, {type = .submit}, k.text(doc, "Create account")),
			c.button(doc, {type = .reset, shape = .outline, variant = .secondary}, k.text(doc, "Reset")),
			c.link(doc, {href = form_state.errors ? FORM_PATH : FORM_PATH + "?errors", shape = .text}, k.text(doc, form_state.errors ? "Show the clean form" : "Show the form after a failed submit")),
		),
	)
}

form_description :: proc(doc: ^k.Doc) -> k.Node_Id {
	return doc_section_description(
		doc,
		k.text(doc, "One sign-up form that uses every input: text, "),
		doc_code(doc, "email"),
		k.text(doc, ", "),
		doc_code(doc, "tel"),
		k.text(doc, ", "),
		doc_code(doc, "url"),
		k.text(doc, ", "),
		doc_code(doc, "search"),
		k.text(doc, ", "),
		doc_code(doc, "password"),
		k.text(doc, ", "),
		doc_code(doc, "number"),
		k.text(doc, ", "),
		doc_code(doc, "range"),
		k.text(doc, ", the date family, "),
		doc_code(doc, "color"),
		k.text(doc, ", "),
		doc_code(doc, "file"),
		k.text(doc, ", "),
		doc_code(doc, "hidden"),
		k.text(doc, ", plus textarea, select, autocomplete, checkbox, radio group and toggle. Each labelled control goes through "),
		doc_code(doc, "form_field"),
		k.text(doc, ", which wires the label, the control and its message together."),
	)
}
