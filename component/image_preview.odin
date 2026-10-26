package component

import k "kashmir:."

// ---------- constants ----------

IMAGE_PREVIEW_EXTRAS_MAX :: 2 // role, aria-label
IMAGE_PREVIEW_RATIO_MAX :: u32(10_000)
IMAGE_PREVIEW_PLACEHOLDER_DEFAULT :: "No image selected"

// How the image sits in the box. Cover is first so the zero value is the stock look.
Image_Preview_Fit :: enum u8 {
	cover, // fills the box and crops what overflows
	contain, // all of it shows, with bars at the sides if the shapes differ
	fill, // stretched to the box, which distorts it
	none, // natural size, kept inside the box
}

@(private)
image_preview_fit_names := [Image_Preview_Fit]string {
	.cover   = "",
	.contain = "contain",
	.fill    = "fill",
	.none    = "none",
}

// ---------- props ----------

// Width over height as two whole numbers, so 16:9 is {16, 9} and there is no string to sanitise.
Image_Ratio :: struct {
	width:  u32,
	height: u32,
}

// A box with a fixed aspect ratio that holds an image, or a camera placeholder when src is empty.
//
//   image_preview(doc, {src = "/photo.jpg", alt = "A lighthouse at dusk", ratio = c.Image_Ratio{16, 9}})
//   image_preview(doc, {ratio = c.Image_Ratio{1, 1}})   // placeholder
//
// With no ratio the box is 16:9. The image loads lazily; set eager for one at the top of the page.
// The placeholder uses the camera icon, so the icon font must be provided (see readme.md).
//
// Asserts: a ratio side is 1 to IMAGE_PREVIEW_RATIO_MAX; src needs an alt, or decorative = true
// (which writes alt="" and refuses an alt); a placeholder cannot be decorative or eager.
Image_Preview_Props :: struct {
	using base:       k.Base, // id, class, style (appended after the ratio), attributes
	src:              string, // empty = the placeholder
	alt:              string, // what the image shows; names the placeholder too
	ratio:            Maybe(Image_Ratio), // nil = 16:9
	fit:              Image_Preview_Fit,
	radius:           Radius, // see component.odin
	decorative:       bool, // the image adds nothing a screen reader needs
	eager:            bool, // load now instead of when scrolled near
	placeholder_text: string, // empty = IMAGE_PREVIEW_PLACEHOLDER_DEFAULT
}

// ---------- procs ----------

// Composition order: image-preview [image-preview--{radius}] [class]
image_preview :: proc(doc: ^k.Doc, props: Image_Preview_Props) -> k.Node_Id {
	has_image := props.src != ""
	if has_image {
		assert(
			props.alt != "" || props.decorative,
			"image_preview with a src needs an alt, or decorative = true",
		)
		assert(
			!(props.decorative && props.alt != ""),
			"image_preview cannot be decorative and have an alt",
		)
	} else {
		assert(!props.decorative, "image_preview placeholder cannot be decorative")
		assert(!props.eager, "image_preview placeholder has nothing to load")
	}

	style := props.style
	if ratio, found := props.ratio.?; found {
		assert(
			ratio.width >= 1 &&
			ratio.width <= IMAGE_PREVIEW_RATIO_MAX &&
			ratio.height >= 1 &&
			ratio.height <= IMAGE_PREVIEW_RATIO_MAX,
			"image_preview ratio sides must be 1 to IMAGE_PREVIEW_RATIO_MAX",
		)
		separator := style != "" ? "; " : ""
		style = k.doc_format(
			doc,
			"aspect-ratio: %d / %d%s%s",
			ratio.width,
			ratio.height,
			separator,
			style,
		)
	}

	// k.div copies the slice into the Doc, so a bounded stack buffer is enough.
	attributes: [ATTRIBUTES_MAX]k.Attribute
	attributes_count := len(props.attributes)
	assert(
		attributes_count + IMAGE_PREVIEW_EXTRAS_MAX <= ATTRIBUTES_MAX,
		"image_preview attributes exceeds ATTRIBUTES_MAX",
	)
	copy(attributes[:], props.attributes)

	placeholder_text :=
		props.placeholder_text != "" ? props.placeholder_text : IMAGE_PREVIEW_PLACEHOLDER_DEFAULT

	content: k.Node_Id
	if has_image {
		content = k.img(
		doc,
		{
			class      = image_preview_image_class(doc, props.fit),
			src        = props.src,
			alt        = props.alt,
			loading    = props.eager ? .eager : .lazy,
			// An empty alt is skipped unless forced, and a missing alt is not the same as none.
			attributes = props.decorative ? []k.Attribute{k.always("alt", "")} : nil,
		},
		)
	} else {
		attributes[attributes_count] = k.role("img")
		attributes[attributes_count + 1] = k.attribute(
			"aria-label",
			props.alt != "" ? props.alt : placeholder_text,
		)
		attributes_count += 2
		content = k.div(
			doc,
			{
				class = "image-preview__placeholder",
				attributes = {k.attribute("aria-hidden", "true")},
			},
			icon(doc, {name = .camera, size = .large}),
			k.span(doc, {}, k.text(doc, placeholder_text)),
		)
	}

	base := props.base
	base.style = style
	base.class = image_preview_class(doc, props)
	base.attributes = attributes[:attributes_count]
	return k.div(doc, base, content)
}

@(private)
image_preview_class :: proc(doc: ^k.Doc, props: Image_Preview_Props) -> string {
	radius_class :=
		props.radius == .default ? "" : k.doc_format(doc, " image-preview--%s", radius_names[props.radius])
	separator := props.class != "" ? " " : ""
	return k.doc_format(doc, "image-preview%s%s%s", radius_class, separator, props.class)
}

@(private)
image_preview_image_class :: proc(doc: ^k.Doc, fit: Image_Preview_Fit) -> string {
	if fit == .cover do return "image-preview__img"
	return k.doc_format(
		doc,
		"image-preview__img image-preview__img--%s",
		image_preview_fit_names[fit],
	)
}
