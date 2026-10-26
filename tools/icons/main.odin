package main

// Generates the Phosphor icon table and font CSS from the @phosphor-icons/web npm package.
//
//   make icons        (needs make deps once)
//
// Writes two files that are committed, so building the library never needs node_modules:
//   component/icon_names.odin           Icon_Name enum, font file names and font version
//   frontend/css/base/phosphor.css      font-family rules and one rule per icon
//
// Neither file says where the fonts are served from. That is the caller's decision:
// it declares the @font-face rules (see readme.md).
//
// Phosphor ships six fonts that share codepoints, so one rule per icon serves every
// weight. The generator checks that, and fails if a future release breaks it.

import "core:fmt"
import "core:os"
import "core:strings"

PACKAGE_DIRECTORY :: "node_modules/@phosphor-icons/web"
TABLE_PATH :: "component/icon_names.odin"
CSS_PATH :: "frontend/css/base/phosphor.css"

ICON_COUNT_MAX :: 4096
SCAN_COUNT_MAX :: 1 << 16 // rule scans per stylesheet
FILE_BYTES_MAX :: 1 << 22 // 4 MiB per input file
NAME_BYTES_MAX :: 64
IDENTIFIERS_PER_LINE :: 4

// ---------- constants ----------

odin_keywords := [?]string {
	"package",
	"union",
	"map",
	"struct",
	"enum",
	"proc",
	"import",
	"foreign",
	"defer",
	"switch",
	"case",
	"when",
	"where",
	"return",
	"using",
	"cast",
	"transmute",
	"bit_set",
	"bit_field",
	"distinct",
	"dynamic",
	"context",
	"typeid",
	"matrix",
	"break",
	"continue",
	"fallthrough",
	"if",
	"else",
	"for",
	"in",
	"do",
	"not_in",
	"or_else",
	"or_return",
	"or_break",
	"or_continue",
	"inline",
	"no_inline",
	"auto_cast",
}

weights := [?]Weight {
	{"regular", "regular", "Phosphor", "Phosphor", "ph"},
	{"thin", "thin", "Phosphor-Thin", "Phosphor-Thin", "ph-thin"},
	{"light", "light", "Phosphor-Light", "Phosphor-Light", "ph-light"},
	{"bold", "bold", "Phosphor-Bold", "Phosphor-Bold", "ph-bold"},
	{"fill", "fill", "Phosphor-Fill", "Phosphor-Fill", "ph-fill"},
	{"duotone", "duotone", "Phosphor-Duotone", "Phosphor-Duotone", "ph-duotone"},
}

Weight :: struct {
	member:    string, // Icon_Weight member
	directory: string,
	file:      string, // font file, without extension
	family:    string,
	class:     string,
}

Rule :: struct {
	name:      string,
	codepoint: string, // hex digits
}

fail :: proc(format: string, arguments: ..any) -> ! {
	fmt.eprintf("icons: ")
	fmt.eprintfln(format, ..arguments)
	os.exit(1)
}

read_text :: proc(path: string) -> string {
	content, error := os.read_entire_file(path, context.allocator)
	if error != nil do fail("cannot read %s: %v (run make deps)", path, error)
	if len(content) > FILE_BYTES_MAX do fail("%s exceeds %d bytes", path, FILE_BYTES_MAX)
	return string(content)
}

name_valid :: proc(name: string) -> bool {
	if len(name) == 0 || len(name) > NAME_BYTES_MAX do return false
	for character in transmute([]u8)name {
		is_lower := character >= 'a' && character <= 'z'
		is_digit := character >= '0' && character <= '9'
		if !is_lower && !is_digit && character != '-' do return false
	}
	return true
}

hex_valid :: proc(hex: string) -> bool {
	if len(hex) == 0 || len(hex) > 6 do return false
	for character in transmute([]u8)hex {
		is_digit := character >= '0' && character <= '9'
		is_hex := character >= 'a' && character <= 'f'
		if !is_digit && !is_hex do return false
	}
	return true
}

// Collects, in file order, every `<prefix><name><pseudo> { ... content: "\<hex>" ... }`.
// Rules for the other pseudo-element are skipped. Any rule that does not have the
// expected shape fails the run, so a changed stylesheet is noticed and not misread.
parse_rules :: proc(path, text, prefix, pseudo: string) -> [dynamic]Rule {
	rules: [dynamic]Rule
	remaining := text
	for _ in 0 ..< SCAN_COUNT_MAX {
		start := strings.index(remaining, prefix)
		if start < 0 do return rules

		after_prefix := remaining[start + len(prefix):]
		colon := strings.index_byte(after_prefix, ':')
		close := strings.index_byte(after_prefix, '}')
		if colon < 0 || close < 0 || colon > close do fail("%s: malformed rule after %q", path, prefix)
		remaining = after_prefix[close:]

		name := after_prefix[:colon]
		if !name_valid(name) do fail("%s: unexpected icon name %q", path, name)

		body := after_prefix[colon:close]
		if !strings.has_prefix(body, pseudo) || len(body) <= len(pseudo) || body[len(pseudo)] != ' ' do continue

		marker :: `content: "\`
		at := strings.index(body, marker)
		if at < 0 do fail("%s: %s%s has no content", path, prefix, name)
		hex := body[at + len(marker):]
		end := strings.index_byte(hex, '"')
		if end < 0 || !hex_valid(hex[:end]) do fail("%s: %s%s has a bad codepoint", path, prefix, name)

		if len(rules) == ICON_COUNT_MAX do fail("%s: more than %d icons", path, ICON_COUNT_MAX)
		append(&rules, Rule{name, hex[:end]})
	}
	fail("%s: more than %d rule scans", path, SCAN_COUNT_MAX)
}

load_rules :: proc(weight: Weight, pseudo: string) -> [dynamic]Rule {
	path := fmt.tprintf("%s/src/%s/style.css", PACKAGE_DIRECTORY, weight.directory)
	prefix := fmt.tprintf(".%s.ph-", weight.class)
	return parse_rules(path, read_text(path), prefix, pseudo)
}

package_version :: proc() -> string {
	path := PACKAGE_DIRECTORY + "/package.json"
	text := read_text(path)
	marker :: `"version": "`
	at := strings.index(text, marker)
	if at < 0 do fail("%s has no version", path)
	rest := text[at + len(marker):]
	end := strings.index_byte(rest, '"')
	if end <= 0 do fail("%s has a bad version", path)
	return rest[:end]
}

// "arrow-bend-up" -> "arrow_bend_up". A name that is an Odin keyword gets an
// "_icon" suffix: "package" -> "package_icon".
member_name :: proc(name: string) -> string {
	member, _ := strings.replace_all(name, "-", "_", context.allocator)
	for keyword in odin_keywords {
		if member == keyword do return strings.concatenate({member, "_icon"}, context.allocator)
	}
	return member
}

main :: proc() {
	version := package_version()
	regular := load_rules(weights[0], ":before")
	if len(regular) == 0 do fail("no icons found in the regular stylesheet")

	// Every name becomes an enum member, so it must be distinct and must not collide
	// with the member that means "no icon" or with a weight class.
	seen: map[string]string
	for rule in regular {
		member := member_name(rule.name)
		if member == "none" do fail("icon %q collides with Icon_Name.none", rule.name)
		if member in seen do fail("icons %q and %q are both %s", seen[member], rule.name, member)
		seen[member] = rule.name
		for weight in weights {
			if fmt.tprintf("ph-%s", rule.name) == weight.class do fail("icon %q collides with class %s", rule.name, weight.class)
		}
	}

	// The shared-codepoint assumption: bold, fill, light and thin must match regular exactly.
	for weight in weights[1:len(weights) - 1] {
		rules := load_rules(weight, ":before")
		if len(rules) != len(regular) do fail("%s has %d icons, regular has %d", weight.directory, len(rules), len(regular))
		for rule, index in rules {
			if rule != regular[index] do fail("%s differs from regular at %q", weight.directory, rule.name)
		}
	}

	// Duotone draws two glyphs: :before (same codepoint as regular, faded) and :after.
	// Some icons have no duotone form at all.
	duotone := weights[len(weights) - 1]
	duotone_before := load_rules(duotone, ":before")
	duotone_after := load_rules(duotone, ":after")
	regular_codepoints: map[string]string
	for rule in regular do regular_codepoints[rule.name] = rule.codepoint
	duotone_names: map[string]bool
	for rule in duotone_before {
		if regular_codepoints[rule.name] != rule.codepoint do fail("duotone differs from regular at %q", rule.name)
		duotone_names[rule.name] = true
	}
	for rule in duotone_after {
		if !(rule.name in duotone_names) do fail("duotone has :after without :before for %q", rule.name)
	}

	write_table(version, regular[:], duotone_names)
	write_css(version, regular[:], duotone_after[:])
	fmt.printfln(
		"icons: %s and %s <- @phosphor-icons/web %s (%d icons, %d without duotone)",
		TABLE_PATH,
		CSS_PATH,
		version,
		len(regular),
		len(regular) - len(duotone_before),
	)
}

write_table :: proc(version: string, regular: []Rule, duotone_names: map[string]bool) {
	b := strings.builder_make()
	fmt.sbprintfln(
		&b,
		"// Code generated by tools/icons from @phosphor-icons/web %s. DO NOT EDIT.",
		version,
	)
	strings.write_string(&b, "package component\n\n")

	strings.write_string(
		&b,
		"// Every Phosphor icon. none is first so the zero value draws nothing.\n",
	)
	strings.write_string(&b, "Icon_Name :: enum u16 {\n\tnone,\n")
	for rule in regular do fmt.sbprintfln(&b, "\t%s,", member_name(rule.name))
	strings.write_string(&b, "}\n\n")

	strings.write_string(
		&b,
		"// Kebab-case name as it appears in the Phosphor class, e.g. ph-arrow-bend-up.\n",
	)
	strings.write_string(
		&b,
		"@(private)\nicon_name_classes := [Icon_Name]string {\n\t.none = \"\",\n",
	)
	for rule in regular do fmt.sbprintfln(&b, "\t.%s = %q,", member_name(rule.name), rule.name)
	strings.write_string(&b, "}\n\n")

	strings.write_string(
		&b,
		"// Font file for each weight, as shipped by @phosphor-icons/web. The caller serves\n",
	)
	strings.write_string(
		&b,
		"// them and declares @font-face for the families in phosphor.css (see readme.md).\n",
	)
	fmt.sbprintfln(&b, "icon_font_version :: %q", version)
	strings.write_string(&b, "icon_font_files := [Icon_Weight]string {\n")
	for weight in weights {
		fmt.sbprintfln(&b, "\t.%s = \"%s.woff2\",", weight.member, weight.file)
	}
	strings.write_string(&b, "}\n\n")

	strings.write_string(
		&b,
		"// Duotone has no form for a few icons; drawing one would show a blank.\n",
	)
	strings.write_string(
		&b,
		"icon_duotone_available :: proc(name: Icon_Name) -> bool {\n\t#partial switch name {\n\tcase ",
	)
	missing := 0
	for rule in regular {
		if rule.name in duotone_names do continue
		if missing > 0 {
			strings.write_string(&b, missing % IDENTIFIERS_PER_LINE == 0 ? ",\n\t     " : ", ")
		}
		fmt.sbprintf(&b, ".%s", member_name(rule.name))
		missing += 1
	}
	strings.write_string(&b, ":\n\t\treturn false\n\t}\n\treturn true\n}\n")

	if error := os.write_entire_file(TABLE_PATH, strings.to_string(b)); error != nil {
		fail("cannot write %s: %v", TABLE_PATH, error)
	}
}

write_css :: proc(version: string, regular: []Rule, duotone_after: []Rule) {
	b := strings.builder_make()
	fmt.sbprintfln(
		&b,
		"/* Generated by tools/icons from @phosphor-icons/web %s. Do not edit.",
		version,
	)
	strings.write_string(
		&b,
		" *\n * Font-family rules and one rule per icon. All weights share codepoints, so the rule\n",
	)
	strings.write_string(&b, " * per icon is shared too. The weight class only picks the font.\n")
	strings.write_string(
		&b,
		" *\n * There is no @font-face here: where the fonts are served from is the caller's\n",
	)
	strings.write_string(
		&b,
		" * decision. Declare one @font-face per weight you use, with the family names below. */\n\n",
	)

	classes := make([dynamic]string, 0, len(weights), context.temp_allocator)
	for weight in weights do append(&classes, fmt.tprintf(".%s", weight.class))
	strings.write_string(&b, strings.join(classes[:], ", ", context.temp_allocator))
	strings.write_string(
		&b,
		" {\n    font-style: normal;\n    font-weight: normal;\n    font-variant: normal;\n",
	)
	strings.write_string(
		&b,
		"    text-transform: none;\n    letter-spacing: 0;\n    line-height: 1;\n",
	)
	strings.write_string(
		&b,
		"    -webkit-font-smoothing: antialiased;\n    -moz-osx-font-smoothing: grayscale;\n}\n\n",
	)

	// !important keeps browser extensions that swap fonts from replacing the icon font.
	for weight in weights {
		fmt.sbprintfln(
			&b,
			".%s {{\n    font-family: \"%s\" !important;\n}}\n",
			weight.class,
			weight.family,
		)
	}

	strings.write_string(&b, ".ph-duotone::before {\n    opacity: 0.2;\n}\n\n")
	strings.write_string(&b, ".ph-duotone::after {\n    margin-left: -1em;\n}\n\n")

	for rule in regular {
		fmt.sbprintfln(&b, ".ph-%s::before {{ content: \"\\%s\"; }}", rule.name, rule.codepoint)
	}
	strings.write_string(&b, "\n")
	for rule in duotone_after {
		fmt.sbprintfln(
			&b,
			".ph-duotone.ph-%s::after {{ content: \"\\%s\"; }}",
			rule.name,
			rule.codepoint,
		)
	}

	if error := os.write_entire_file(CSS_PATH, strings.to_string(b)); error != nil {
		fail("cannot write %s: %v", CSS_PATH, error)
	}
}
