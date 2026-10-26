package component

import "core:strings"
import k "kashmir:."

// ---------- constants ----------

TABS_MAX :: 32
TABS_EXTRAS_MAX :: 10 // role, aria-selected, aria-controls, tabindex, data-value, data-state, data-keralam-tabs-target, data-action, aria-label, headroom

// ---------- props ----------

// One tab: its button and its panel, kept together so every button has a panel.
//
// The label is title (plain text) or label (a node, for an icon next to text). A tab whose
// label is a node and has no visible words needs aria_label. The button's id is derived from
// the value, so id on the base is refused.
Tab :: struct {
	using base: k.Base, // class (appended after tabs__trigger), style, attributes; id is refused
	value:      string, // names the tab inside this tabs: non-empty, no spaces, used once
	title:      string, // the label as text
	label:      Maybe(k.Node_Id), // the label as a node, built first; instead of title
	panel:      k.Node_Id, // the content, built first
	disabled:   bool,
	aria_label: string, // the name when the label is only an icon
}

// A row (or column) of tabs, with one panel showing at a time. WAI-ARIA tabs: arrow keys move
// between tabs, Home and End jump to the ends, and only the selected tab is in the tab order.
// Needs keralam.js (the keralam-tabs controller).
//
//   tabs(doc, {tabs = {{value = "a", title = "One", panel = k.text(doc, "First")}, {value = "b", title = "Two", panel = k.text(doc, "Second")}}})
//
// Without script the selected panel is still readable and the others are hidden, but the
// buttons do nothing.
//
// The ids come from this tabs' own id, so two sets on one page can use the same values.
//
// Asserts: 1 to TABS_MAX tabs; each value non-empty, free of spaces and used once; a label
// given as exactly one of title and label; a node label with an aria_label; selected naming
// an enabled tab, or at least one enabled tab when selected is nil.
Tabs_Props :: struct {
	using base: k.Base, // id (generated when empty), class, style, attributes
	tabs:       []Tab,
	selected:   Maybe(string), // the value shown first; nil = the first enabled tab
	size:       Size, // see component.odin
	vertical:   bool, // buttons in a column at the side; Up and Down move between them
}

// ---------- procs ----------

// Composition order: tabs tabs--{size} [tabs--vertical] [class]
tabs :: proc(doc: ^k.Doc, props: Tabs_Props) -> k.Node_Id {
	tabs_count := len(props.tabs)
	assert(tabs_count >= 1, "tabs needs at least one tab")
	assert(tabs_count <= TABS_MAX, "tabs exceeds TABS_MAX")

	selected_index := tabs_selected_index(props)
	root_id := props.id != "" ? props.id : k.doc_format(doc, "tb%d", doc.nodes_count)

	triggers: [TABS_MAX]k.Node_Id
	panels: [TABS_MAX]k.Node_Id
	for tab, index in props.tabs {
		triggers[index] = tabs_trigger(doc, tab, root_id, index == selected_index)
		panels[index] = tabs_panel(doc, tab, root_id, index == selected_index)
	}

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + TABS_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"tabs attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)
	attributes[attributes_count] = k.attribute("data-controller", "keralam-tabs")
	attributes[attributes_count + 1] = k.attribute(
		"data-keralam-tabs-active-value",
		props.tabs[selected_index].value,
	)
	attributes[attributes_count + 2] = k.attribute(
		"data-keralam-tabs-orientation-value",
		props.vertical ? "vertical" : "horizontal",
	)
	attributes_count += 3

	list := k.div(
		doc,
		{
			class = "tabs__list",
			attributes = {
				k.role("tablist"),
				k.attribute("aria-orientation", props.vertical ? "vertical" : "horizontal"),
			},
		},
		..triggers[:tabs_count],
	)

	children: [TABS_MAX + 1]k.Node_Id
	children[0] = list
	copy(children[1:], panels[:tabs_count])

	base := props.base
	base.id = root_id
	base.class = tabs_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, ..children[:tabs_count + 1])
}

// Checks every tab and returns the index of the one shown first.
@(private)
tabs_selected_index :: proc(props: Tabs_Props) -> int {
	first_enabled := -1
	named := -1
	for tab, index in props.tabs {
		assert(tab.value != "", "tab needs a value")
		assert(
			!strings.contains_any(tab.value, " \t\r\n\"'<>&"),
			"tab value has a space or markup character",
		)
		assert(tab.id == "", "tab id is derived from the value, so id is refused")
		_, has_label := tab.label.?
		assert((tab.title != "") != has_label, "tab needs exactly one of title and label")
		assert(!has_label || tab.aria_label != "", "tab with a node label needs an aria_label")
		for other in props.tabs[:index] {
			assert(other.value != tab.value, "tab value is used twice")
		}
		if !tab.disabled && first_enabled < 0 do first_enabled = index
		if selected, found := props.selected.?; found && selected == tab.value do named = index
	}

	if _, found := props.selected.?; found {
		assert(named >= 0, "tabs selected names no tab")
		assert(!props.tabs[named].disabled, "tabs selected names a disabled tab")
		return named
	}
	assert(first_enabled >= 0, "tabs needs one enabled tab")
	return first_enabled
}

@(private)
tabs_trigger :: proc(doc: ^k.Doc, tab: Tab, root_id: string, selected: bool) -> k.Node_Id {
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(tab.attributes)
	assert(
		attributes_count + TABS_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"tab attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], tab.attributes)

	extras := [?]k.Attribute {
		k.role("tab"),
		k.attribute("aria-selected", selected ? "true" : "false"),
		k.attribute("aria-controls", k.doc_format(doc, "%s-panel-%s", root_id, tab.value)),
		k.attribute("tabindex", selected ? "0" : "-1"),
		k.attribute("data-value", tab.value),
		k.attribute("data-state", selected ? "active" : "inactive"),
		k.attribute("data-keralam-tabs-target", "trigger"),
		k.attribute("data-action", "click->keralam-tabs#select keydown->keralam-tabs#navigate"),
		k.attribute("aria-label", tab.aria_label),
	}
	copy(attributes[attributes_count:], extras[:])
	attributes_count += len(extras)

	base := tab.base
	base.id = k.doc_format(doc, "%s-tab-%s", root_id, tab.value)
	base.class =
		tab.class != "" ? k.doc_format(doc, "tabs__trigger %s", tab.class) : "tabs__trigger"
	base.attributes = attributes[:attributes_count]

	label, has_label := tab.label.?
	if !has_label do label = k.text(doc, tab.title)
	return k.button(doc, {base = base, type = .button, disabled = tab.disabled}, label)
}

@(private)
tabs_panel :: proc(doc: ^k.Doc, tab: Tab, root_id: string, selected: bool) -> k.Node_Id {
	attributes: [7]k.Attribute
	attributes[0] = k.role("tabpanel")
	attributes[1] = k.attribute(
		"aria-labelledby",
		k.doc_format(doc, "%s-tab-%s", root_id, tab.value),
	)
	attributes[2] = k.attribute("tabindex", "0")
	attributes[3] = k.attribute("data-value", tab.value)
	attributes[4] = k.attribute("data-state", selected ? "active" : "inactive")
	attributes[5] = k.attribute("data-keralam-tabs-target", "panel")
	attributes_count := 6
	if !selected {
		attributes[attributes_count] = k.hidden()
		attributes_count += 1
	}

	return k.div(
		doc,
		{
			id = k.doc_format(doc, "%s-panel-%s", root_id, tab.value),
			class = "tabs__content",
			attributes = attributes[:attributes_count],
		},
		tab.panel,
	)
}

@(private)
tabs_class :: proc(doc: ^k.Doc, props: Tabs_Props) -> string {
	vertical_class := props.vertical ? " tabs--vertical" : ""
	separator := props.class != "" ? " " : ""
	return k.doc_format(
		doc,
		"tabs tabs--%s%s%s%s",
		size_names[props.size],
		vertical_class,
		separator,
		props.class,
	)
}
