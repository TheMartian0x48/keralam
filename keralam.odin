/*
keralam is a set of UI components for kashmir, the Odin HTML builder. Each component is a
proc that takes a ^k.Doc and returns a Node_Id, and has a matching stylesheet.

This package holds only this documentation. The components are in the subpackage
"component", so import that:

	import k "kashmir:."
	import c "keralam:component"

	c.button(doc, {variant = .Danger, shape = .Outline}, k.text(doc, "Delete"))
	c.input_email(doc, {name = "email", required = true})

Both are collections: build with
	-collection:kashmir=<path to kashmir>
	-collection:keralam=<path to this repository>

# How a component works

Every component takes the Doc first, then a props struct, then children, and returns a
Node_Id. The zero value of a props struct is the stock look, so c.button(doc, {}, ...) is a
medium, solid, primary button. A props struct embeds k.Base (id, class, style, attributes),
and the class you give is appended after the generated ones.

A node can have only one parent. A node you pass in (a card's header, an accordion item's
icon) must be built fresh for each use; reusing one asserts.

What a type cannot say asserts when the page is built, because it is a programmer error: a
date that is not a date, a minimum above a maximum, two selected radios, an option value
used twice. What a type can say is a compile error, so each input has its own proc and props
rather than one proc with a kind field.

Appearance is a handful of enums shared across components: Variant (colour), Shape (fill),
Size and Radius. A component uses only the ones that make sense for it.

# Components

Content and layout
	accordion, alert, badge (and badge_group), breadcrumb, card, divider, icon, label

Actions and navigation
	button, link, mail, dropdown (with dropdown_item, dropdown_divider, dropdown_label)

Overlays
	dialog (with dialog_footer), drawer

Form controls
	checkbox, radio and radio_group, autocomplete, and form_field, which lays a control out
	with its label and a help or error message and wires them together.

	The input family is one proc per kind, named input_<type>: input_text, input_email,
	input_username, input_tel, input_url, input_search, input_password, input_number,
	input_range, input_date, input_datetime, input_time, input_month, input_week,
	input_color, input_file, input_hidden, input_textarea, input_select and input_toggle.
	The proc group "input" covers all of them. Checkbox and radio are their own components,
	and submit, reset and button are the button component.

# What you provide

Styles and scripts are built from frontend/ into assets/keralam.css and assets/keralam.js
(make css, make js). The components emit class names and data attributes; your page loads
the two files. Behaviour that needs script (autocomplete, dropdown keyboard handling,
dialog and drawer closing, alert dismissal, indeterminate checkboxes) is in keralam.js, and
every other component works without it.

Colours are tokens, so a theme is a block of overrides. keralam.css has light and dark (the OS
preference, or data-theme="light|dark"); keralam-themes.css adds gruvbox, nord, solarized and
dracula, and a page opts in by linking it and setting data-theme. See readme.md.

Icons are drawn from the Phosphor font, and the library does not choose where the fonts are
served from: your page declares the @font-face rules. See readme.md for the files, the
family names and the caching headers.

# Where to look

readme.md covers the make targets, the inputs, form fields and icons. example/ is a server
that shows every component (make run) and a whole sign-up form at /form.
*/
package keralam
