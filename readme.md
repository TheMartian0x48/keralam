# keralam

UI components for [kashmir](https://github.com/TheMartian0x48/kashmir), the Odin HTML builder. Each component is a
proc that takes a `^k.Doc` and returns a `Node_Id`, and has a matching stylesheet.

```odin
import k "kashmir:."
import c "keralam:component"

c.button(doc, {variant = .danger, shape = .outline}, k.text(doc, "Delete"))
```

## Make targets

| Target | What it does |
|---|---|
| `make deps` | fetch or repair kashmir in `vendor/`, then `npm install` |
| `make css` | bundle `frontend/css` into `assets/keralam.css` and the named themes into `assets/keralam-themes.css` |
| `make js` | bundle `frontend/js` into `assets/keralam.js` |
| `make icons` | regenerate the icon table and icon CSS from `node_modules` |
| `make fonts` | copy the Phosphor `.woff2` files into `assets/` |
| `make build` | check the library and build the demo |
| `make run` | build everything and serve the demo on `127.0.0.1:8080` |

`make deps` clones [kashmir](https://github.com/TheMartian0x48/kashmir) at a pinned commit into `vendor/kashmir` (re-run it to repair a broken or edited checkout; bump `KASHMIR_COMMIT` in `tools/deps.py` to upgrade). It is passed as a collection (`-collection:kashmir=vendor/kashmir`), so imports read
`import k "kashmir:."`.

## Inputs

One proc per kind of field, named `input_<type>`, each with its own props. The type is in
the name, so a `pattern` on a number, a string where a date belongs, or a `value` on a
password does not compile: the field does not exist.

```odin
c.input_email(doc, {name = "email", placeholder = "you@example.com", required = true})
c.input_number(doc, {name = "age", min = 0.0, max = 120.0, step = 1.0})
c.input_date(doc, {name = "due", min = c.Input_Date{2026, 1, 1}})
c.input_password(doc, {name = "pw", autocomplete = .new, min_length = 8})
c.input_color(doc, {name = "accent", value = c.Input_Color{37, 99, 235}})
```

What a type cannot say asserts when the page is built: `min` above `max`, a date that is not
a date (30 February), a week that does not exist (2027 has no week 53), `step` of zero,
`read_only` or `required` together with `disabled`.

### Which proc for which HTML input type

The names follow `input_<type>`. The one exception is `datetime_local`, which is
`input_datetime`.

| HTML `type` | Proc | Value type |
|---|---|---|
| `text` | `input_text` | `string` |
| `email` | `input_email` | `string` |
| `tel` | `input_tel` | `string` |
| `url` | `input_url` | `string` |
| `search` | `input_search` | `string` |
| `<textarea>` | `input_textarea` | `string` |
| `<select>` | `input_select` | `string` (a chosen option's value) |
| `password` | `input_password` | none: a password never goes in the page |
| `number` | `input_number` | `f64` |
| `range` | `input_range` | `f64` |
| `date` | `input_date` | `Input_Date` |
| `datetime-local` | `input_datetime` | `Input_Datetime` |
| `time` | `input_time` | `Input_Time` |
| `month` | `input_month` | `Input_Month` |
| `week` | `input_week` | `Input_Week` |
| `color` | `input_color` | `Input_Color` |
| `file` | `input_file` | none: a browser never lets a page set one |
| `hidden` | `input_hidden` | `string` |

Two extras are not HTML input types. `input_username` is a text field with the username
autocomplete hint, and with auto-capitalising and spell-checking turned off. `input_toggle`
is an on/off switch: a checkbox with `role="switch"`, for a single setting that takes
effect straight away (use the checkbox component for agreeing or picking).

### What has no `input_*` proc

| HTML `type` | Why | Use instead |
|---|---|---|
| `checkbox` | its own component | `checkbox` |
| `radio` | its own component | `radio` |
| `button`, `submit`, `reset` | covered by the button component | `button` with `type = .button`, `.submit` or `.reset` |
| `image` | a legacy image button, not needed | `button` |

### Calling it through the `input` group

`input` is a proc group over all twenty procs. Name the props type to use it:

```odin
c.input(doc, c.Input_Email_Props{name = "email"})   // fine
c.input(doc, {name = "email"})                      // does not compile: ambiguous
```

Odin cannot tell a bare `{...}` apart across twenty props structs, so the plain
`input_email(...)` form is the one to reach for.

### Which fields a kind has

Fields follow the HTML spec, so a field a browser would ignore is not there to write.
`placeholder` exists on the text-like kinds and `input_number` only. `read_only` is not on
`input_range`, `input_color` or `input_file`. `required` is not on `input_range` or
`input_color`, because a slider and a colour picker always have a value.

## Form fields

`form_field` puts a control under a label, with helper text or an error message, and wires
the three together so they cannot disagree: the label's `for`, the control's `id`, and the
control's `aria-describedby`.

```odin
email_control :: proc(doc: ^k.Doc, w: c.Form_Field_Wiring) -> k.Node_Id {
	return c.input_email(doc, {id = w.id, name = "email", error = w.error, aria_described_by = w.aria_described_by})
}

c.form_field(doc, {label = "Email", required = true, help = "We never share it", control = email_control})
c.form_field(doc, {label = "Email", error = "Enter a valid email address", control = email_control})
```

The control is a proc, not a node, because the wiring has to exist before the control is
built: a node's children are built before the node, so a finished control could not be given
the label's id afterwards. `form_field` makes the ids, calls your proc with them, and checks
that the control really used the id it was given. A proc cannot capture variables, so a
control that needs data reads it from somewhere the proc can reach.

When there is an `error`, the control is built with `error = true`, so it carries its own
`aria-invalid` and red styling, and the message is `role="alert"`. An `error` and a `help`
together assert: the field shows one message.

Use it for the controls that sit under a label: the text-like inputs, textarea, select,
file, color, range, and the date and time kinds. Checkbox, radio, radio group and toggle
carry their own label, so use them directly. For `autocomplete`, give the field's id to
`input_id`, not `id`: a label can only name a form control, and its root is a `<div>`.

`example/form.odin` is a whole sign-up form built this way, using every input control. Run
`make run` and open `/form`, or `/form?errors` for the same form after a failed submit.

## Icons

Icons are drawn from the [Phosphor](https://phosphoricons.com) font, so one cached file
serves every icon on every page.

```odin
c.icon(doc, {name = .check_circle, weight = .fill, size = .large})
// <i class="icon icon--lg ph-fill ph-check-circle" aria-hidden="true"></i>
```

`Icon_Name` has all 1,530 icons, so a misspelled name is a compile error. `Icon_Weight`
has `regular`, `thin`, `light`, `bold`, `fill` and `duotone`. 18 icons have no duotone
form; asking for one asserts.

### You provide the fonts

The library does not choose where the fonts are served from, and it ships no URLs. It
emits the class names and the CSS rules that pick a font family. **Your page must declare
the `@font-face` rules and serve the files.** Without them icons render as empty boxes.

1. Get the fonts. `make fonts` copies them from the npm package into `assets/`, or take
   them from `node_modules/@phosphor-icons/web/src/<weight>/`. Each weight is its own
   file, and `icon_font_files` lists the file name for every weight:

   | Weight | File | Size |
   |---|---|---|
   | Regular | `Phosphor.woff2` | 147 KB |
   | Thin | `Phosphor-Thin.woff2` | 154 KB |
   | Light | `Phosphor-Light.woff2` | 155 KB |
   | Bold | `Phosphor-Bold.woff2` | 150 KB |
   | Fill | `Phosphor-Fill.woff2` | 132 KB |
   | Duotone | `Phosphor-Duotone.woff2` | 164 KB |

2. Declare `@font-face` for **each weight you use**, with exactly these family names,
   because `keralam.css` selects them by name. Point `src` wherever you serve the file:

   ```css
   @font-face {
       font-family: "Phosphor";            /* Regular */
       src: url("/static/fonts/Phosphor.woff2?v=2.1.2") format("woff2");
       font-weight: normal;
       font-style: normal;
       font-display: block;
   }
   ```

   | Weight | `font-family` |
   |---|---|
   | Regular | `Phosphor` |
   | Thin | `Phosphor-Thin` |
   | Light | `Phosphor-Light` |
   | Bold | `Phosphor-Bold` |
   | Fill | `Phosphor-Fill` |
   | Duotone | `Phosphor-Duotone` |

   A browser downloads a font only when the page draws with it, so declaring a weight you
   never use costs nothing.

3. Serve the files with the right type and cache them. The fonts never change for a given
   Phosphor version, so they can be cached for a year if the URL changes on upgrade:

   ```
   Content-Type: font/woff2
   Cache-Control: public, max-age=31536000, immutable
   ```

   Put the version in the URL (`?v=2.1.2`, or in the path). `icon_font_version` holds the
   version the table was generated from.

4. Optional: preload the weight every page uses, so icons do not flash blank while the font
   loads. The `href` must match the `@font-face` URL exactly or the browser fetches it twice:

   ```html
   <link rel="preload" href="/static/fonts/Phosphor.woff2?v=2.1.2"
         as="font" type="font/woff2" crossorigin>
   ```

The demo in `example/` does all four; see `example/css/example.css` and `example/main.odin`.

### Upgrading Phosphor

Change the version in `package.json`, then run `make deps icons fonts`. The generator
rewrites `component/icon_names.odin` and `frontend/css/base/phosphor.css`, and fails if a
release breaks an assumption it relies on (all weights share codepoints, names stay
distinct). Bump the `?v=` in your `@font-face` URLs.

## Themes

Every colour a component uses is one of 37 `--color-*` tokens (plus the shadows and focus
rings), so a theme is a block of overrides and no component CSS changes.

`keralam.css` has light and dark. Each colour is written once, as `light-dark(light, dark)`,
and the `color-scheme` on the page picks one: the OS preference by default, or
`data-theme="light"` / `data-theme="dark"` to force it. `color-scheme` also makes form
controls, scrollbars and the page canvas match.

The named themes are opt-in, in a separate file so a page that does not want them does not
download them. Link `keralam-themes.css` after `keralam.css` and set `data-theme` on `<html>`:

```html
<link rel="stylesheet" href="/assets/keralam.css">
<link rel="stylesheet" href="/assets/keralam-themes.css">
<html data-theme="gruvbox-dark">
```

| `data-theme` | Scheme |
|---|---|
| (none) | the OS preference |
| `light`, `dark` | light, dark (in `keralam.css`) |
| `gruvbox-dark`, `gruvbox-light` | dark, light |
| `nord`, `solarized-dark`, `dracula` | dark |

The `keralam-theme` controller saves a choice in `localStorage` and sets the attribute. It only
accepts the names above, so a stale or edited stored value is ignored. To avoid a flash of
the wrong theme before the script runs, set `data-theme` on `<html>` from the server.

To add a theme, copy a file in `frontend/css/themes/`, change the 44 values, add it to
`frontend/css/themes.css` and to the list in `keralam_theme_controller.ts`, and run `make css js`.
Check the text pairs: the five themes here were each checked so that body text, muted text,
text on a solid accent, and each `*-subtle-text` on its `*-subtle-bg` reach 4.5:1 (WCAG AA).
`/theme` in the demo shows every token as a swatch.

## Demo

`make run` serves one page per component at `/component/<name>`.

- `assets/` is searched first, then `example/css/`.
- Fonts get `Cache-Control: immutable`; CSS and JS get `no-cache`.

## About the name

Keralam is named after Keralam, a coastal state on the southwestern Malabar Coast of India,
traditionally interpreted as “land of coconut palms” (kera + alam).

Some things worth knowing about the place:

- **God's Own Country.** That is the state's famous nickname. It is earned by its stunning
  tropical landscapes, its unique social development model, and its rich cultural heritage.
- **A lot of scenery in a narrow strip.** The Western Ghats hills rise on one side, the
  Arabian Sea coast runs along the other, and inland backwaters and palm groves fill the
  space between.
- **Culture you can see.** Kathakali dance-drama, the martial art Kalaripayattu and the
  harvest festival Onam all come from Kerala.
- **A spice coast.** Pepper and other spices from the region drew traders from across the
  world for centuries.

