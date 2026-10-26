package component

import k "kashmir:."

// ---------- constants ----------

STEPPER_STEPS_MAX :: 64
STEPPER_ITEM_EXTRAS_MAX :: 1 // aria-current

// ---------- props ----------

// One step. Its state is not stored here: it follows from Stepper_Props.current.
Step_Item :: struct {
	using base:  k.Base, // id, class (appended after the generated ones), style, attributes
	title:       string, // required
	description: string, // optional, below the title
}

// A numbered sequence of steps, horizontal or vertical.
//
//   stepper(doc, {current = 1, steps = {{title = "Account"}, {title = "Profile"}, {title = "Review"}}})
//
// Steps before current are completed (a check mark), the step at current is the active one
// (aria-current="step"), and the rest are upcoming. current equal to the number of steps
// means every step is done. Deriving the states from one index means a sequence like two
// active steps, or a completed step after an upcoming one, cannot be written.
//
// The state is also spoken: each title is followed by hidden text such as "(current)". The
// three words are props so they can be translated.
//
// Asserts: 1 to STEPPER_STEPS_MAX steps; every title non-empty; current at most the number
// of steps.
Stepper_Props :: struct {
	using base:      k.Base, // id, class (appended after the generated ones), style, attributes
	steps:           []Step_Item,
	current:         u32, // 0-based index of the active step
	size:            Size, // see component.odin: the numbered circle is 2, 2.5 or 3rem
	vertical:        bool, // stack the steps; default is a row
	aria_label:      string, // the sequence's name; default "Progress steps"
	completed_label: string, // default "(completed)"
	current_label:   string, // default "(current)"
	upcoming_label:  string, // default "(upcoming)"
}

// ---------- procs ----------

// Composition order: stepper stepper--{horizontal|vertical} stepper--{size} [class]
stepper :: proc(doc: ^k.Doc, props: Stepper_Props) -> k.Node_Id {
	steps_count := u32(len(props.steps))
	assert(steps_count >= 1, "stepper needs at least one step")
	assert(steps_count <= STEPPER_STEPS_MAX, "stepper steps exceeds STEPPER_STEPS_MAX")
	assert(props.current <= steps_count, "stepper current is past the last step")

	state_labels := [3]string {
		props.completed_label != "" ? props.completed_label : "(completed)",
		props.current_label != "" ? props.current_label : "(current)",
		props.upcoming_label != "" ? props.upcoming_label : "(upcoming)",
	}

	items: [STEPPER_STEPS_MAX]k.Node_Id
	for step, index in props.steps {
		assert(step.title != "", "stepper step needs a title")
		position := u32(index)
		completed := position < props.current
		active := position == props.current

		indicator := k.div(
			doc,
			{class = "stepper__indicator", attributes = {k.attribute("aria-hidden", "true")}},
			completed ? icon(doc, {name = .check, size = .small}) : k.span(doc, {}, k.text(doc, k.doc_format(doc, "%d", position + 1))),
		)
		state_label := state_labels[completed ? 0 : (active ? 1 : 2)]
		title := k.span(
			doc,
			{class = "stepper__title"},
			k.text(doc, step.title),
			k.span(
				doc,
				{class = "visually-hidden"},
				k.text(doc, k.doc_format(doc, " %s", state_label)),
			),
		)
		content := k.div(
			doc,
			{class = "stepper__content"},
			title,
			step.description != "" ? k.p(doc, {class = "stepper__description"}, k.text(doc, step.description)) : k.NODE_NONE,
		)

		// k.li copies the slice into the Doc, so a bounded stack buffer is enough.
		attributes: [ATTRIBUTES_MAX]k.Attribute
		attributes_count := len(step.attributes)
		assert(
			attributes_count + STEPPER_ITEM_EXTRAS_MAX <= ATTRIBUTES_MAX,
			"stepper step attributes exceeds ATTRIBUTES_MAX",
		)
		copy(attributes[:], step.attributes)
		if active && props.current < steps_count {
			attributes[attributes_count] = k.attribute("aria-current", "step")
			attributes_count += 1
		}

		item_base := step.base
		item_base.class = stepper_item_class(doc, completed, active, step.class)
		item_base.attributes = attributes[:attributes_count]
		items[index] = k.li(doc, {base = item_base}, indicator, content)
	}

	nav_attributes: [ATTRIBUTES_MAX]k.Attribute
	nav_attributes_count := len(props.attributes)
	assert(nav_attributes_count + 1 <= ATTRIBUTES_MAX, "stepper attributes exceeds ATTRIBUTES_MAX")
	copy(nav_attributes[:], props.attributes)
	nav_attributes[nav_attributes_count] = k.attribute(
		"aria-label",
		props.aria_label != "" ? props.aria_label : "Progress steps",
	)
	nav_attributes_count += 1

	base := props.base
	base.class = stepper_class(doc, props)
	base.attributes = nav_attributes[:nav_attributes_count]
	return k.nav(
		doc,
		base,
		k.ol(doc, {class = "stepper__list", attributes = {k.role("list")}}, ..items[:steps_count]),
	)
}

@(private)
stepper_class :: proc(doc: ^k.Doc, props: Stepper_Props) -> string {
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"stepper stepper--%s stepper--%s%s%s",
		props.vertical ? "vertical" : "horizontal",
		size_names[props.size],
		separator,
		props.class,
	)
}

@(private)
stepper_item_class :: proc(doc: ^k.Doc, completed, active: bool, class: string) -> string {
	state := completed ? "completed" : (active ? "active" : "inactive")
	separator := class != "" ? " " : ""
	return k.doc_format(doc, "stepper__item stepper__item--%s%s%s", state, separator, class)
}
