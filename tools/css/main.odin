package main

// Bundles each entry in bundles into one stylesheet by inlining every @import:
// frontend/css/main.css -> assets/keralam.css, and frontend/css/themes.css (the named
// themes, opt-in) -> assets/keralam-themes.css.
//
//   odin run tools/css            (or: make css)
//
// Imports resolve relative to the file that contains them. A specifier whose
// first directory does not exist beside that file is a package import
// (e.g. "quill/dist/quill.bubble.css"); it is read from node_modules/ when
// present and skipped with a warning otherwise. A missing local file fails.

import "core:fmt"
import "core:os"
import "core:path/slashpath"
import "core:strings"

PACKAGE_ROOT :: "node_modules"

IMPORT_DEPTH_MAX :: 4
IMPORT_COUNT_MAX :: 256
FILE_BYTES_MAX :: 1 << 22 // 4 MiB per source file
LINE_COUNT_MAX :: 1 << 16

Bundle_Target :: struct {
	entry_path:  string,
	output_path: string,
}

bundles :: [?]Bundle_Target {
	{"frontend/css/main.css", "assets/keralam.css"},
	{"frontend/css/themes.css", "assets/keralam-themes.css"},
}

Bundle :: struct {
	builder:       strings.Builder,
	import_count:  u32,
	skipped_count: u32,
}

// Extracts the specifier from `@import url('x');`, `@import url("x");` or `@import "x";`.
import_specifier :: proc(line: string) -> (specifier: string, ok: bool) {
	trimmed := strings.trim_space(line)
	if !strings.has_prefix(trimmed, "@import") do return "", false

	open := strings.index_any(trimmed, "'\"")
	if open < 0 do return "", false
	close := strings.index_byte(trimmed[open + 1:], trimmed[open])
	if close <= 0 do return "", false

	return trimmed[open + 1:][:close], true
}

// Returns the file to read for a specifier, or "" for a package that is not installed.
import_path :: proc(directory, specifier: string) -> (path: string, ok: bool) {
	local := slashpath.join({directory, specifier}, context.temp_allocator)
	first_segment, _, _ := strings.partition(specifier, "/")
	first_directory := slashpath.join({directory, first_segment}, context.temp_allocator)

	if os.exists(first_directory) || !strings.contains(specifier, "/") {
		return local, true // local import: a missing file is the caller's error
	}
	package_path := slashpath.join({PACKAGE_ROOT, specifier}, context.temp_allocator)
	return package_path, os.exists(package_path)
}

bundle_file :: proc(bundle: ^Bundle, path: string, depth: u32) -> bool {
	assert(depth <= IMPORT_DEPTH_MAX, "import depth exceeds IMPORT_DEPTH_MAX")

	content, read_error := os.read_entire_file(path, context.temp_allocator)
	if read_error != nil {
		fmt.eprintfln("css: cannot read %s: %v", path, read_error)
		return false
	}
	if len(content) > FILE_BYTES_MAX {
		fmt.eprintfln("css: %s exceeds %d bytes", path, FILE_BYTES_MAX)
		return false
	}

	directory := slashpath.dir(path, context.temp_allocator)
	remaining := string(content)
	for _ in 0 ..< LINE_COUNT_MAX {
		if len(remaining) == 0 do return true

		line: string
		line, _, remaining = strings.partition(remaining, "\n")
		specifier, is_import := import_specifier(line)
		if !is_import {
			strings.write_string(&bundle.builder, line)
			strings.write_byte(&bundle.builder, '\n')
			continue
		}

		bundle.import_count += 1
		if bundle.import_count > IMPORT_COUNT_MAX {
			fmt.eprintfln("css: more than %d imports", IMPORT_COUNT_MAX)
			return false
		}
		if depth == IMPORT_DEPTH_MAX {
			fmt.eprintfln("css: %s imports deeper than %d levels", path, IMPORT_DEPTH_MAX)
			return false
		}

		imported_path, found := import_path(directory, specifier)
		if !found {
			fmt.eprintfln(
				"css: skipped %q (package not installed in %s/)",
				specifier,
				PACKAGE_ROOT,
			)
			bundle.skipped_count += 1
			continue
		}
		fmt.sbprintfln(&bundle.builder, "/* %s */", imported_path)
		if !bundle_file(bundle, imported_path, depth + 1) do return false
	}
	fmt.eprintfln("css: %s exceeds %d lines", path, LINE_COUNT_MAX)
	return false
}

main :: proc() {
	for target in bundles {
		bundle: Bundle
		bundle.builder = strings.builder_make()
		defer strings.builder_destroy(&bundle.builder)

		if !bundle_file(&bundle, target.entry_path, 0) do os.exit(1)

		output := strings.to_string(bundle.builder)
		if error := os.write_entire_file(target.output_path, output); error != nil {
			fmt.eprintfln("css: cannot write %s: %v", target.output_path, error)
			os.exit(1)
		}
		fmt.printfln(
			"css: %s <- %s (%d bytes, %d imports, %d skipped)",
			target.output_path,
			target.entry_path,
			len(output),
			bundle.import_count,
			bundle.skipped_count,
		)
	}
}
