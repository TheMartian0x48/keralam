package component

import k "kashmir:."

// Corner rounding shared by every component that has corners.
//
// default leaves the component's own radius alone, so the zero value of a props
// struct keeps the stock look. none forces square corners.
Radius :: enum u8 {
	default,
	rounded,
	pilled,
	none,
}

// Modifier name for a class such as btn--{name}. Empty for default.
@(private)
radius_names := [Radius]string {
	.default = "",
	.rounded = "rounded",
	.pilled  = "pilled",
	.none    = "square",
}

// Vertical scale shared by every component that comes in sizes.
//
// medium is first so the zero value of a props struct is the stock size.
Size :: enum u8 {
	medium,
	small,
	large,
}

// Modifier name for a class such as btn--{name}.
@(private)
size_names := [Size]string {
	.medium = "md",
	.small  = "sm",
	.large  = "lg",
}

// Color family shared by every component that has a palette.
//
// primary is first so the zero value of a props struct is the stock color.
Variant :: enum u8 {
	primary,
	secondary,
	danger,
	success,
	warning,
	info,
}

// Modifier name for a class such as btn--{name}.
@(private)
variant_names := [Variant]string {
	.primary   = "primary",
	.secondary = "secondary",
	.danger    = "danger",
	.success   = "success",
	.warning   = "warning",
	.info      = "info",
}

// Fill style shared by every component that can be filled or outlined.
//
// solid is first so the zero value of a props struct is the stock fill.
Shape :: enum u8 {
	solid,
	soft,
	outline,
	text,
}

// Modifier name for a class such as btn--{name}.
@(private)
shape_names := [Shape]string {
	.solid   = "solid",
	.soft    = "soft",
	.outline = "outline",
	.text    = "text",
}

// Builds "{block} {block}--{variant} {block}--{shape} {block}--{size}", then the
// radius modifier unless it is default, then modifiers (each with a leading
// space, e.g. " btn--loading"), then the caller's class.
@(private)
appearance_class :: proc(
	doc: ^k.Doc,
	block: string,
	variant: Variant,
	shape: Shape,
	size: Size,
	radius: Radius,
	modifiers: string,
	class: string,
) -> string {
	radius_class :=
		radius == .default ? "" : k.doc_format(doc, " %s--%s", block, radius_names[radius])
	separator := class != "" ? " " : ""

	return k.doc_format(
		doc,
		"%s %s--%s %s--%s %s--%s%s%s%s%s",
		block,
		block,
		variant_names[variant],
		block,
		shape_names[shape],
		block,
		size_names[size],
		radius_class,
		modifiers,
		separator,
		class,
	)
}
