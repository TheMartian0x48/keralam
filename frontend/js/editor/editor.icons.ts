/**
 * Keralam Editor Icons — Quill toolbar override.
 *
 * Quill's Snow theme calls `BaseTheme.buildButtons()` during
 * `extendToolbar()`, which rewrites every `class="ql-X"` button's
 * `innerHTML` from the formatters' registry (Quill's `ui/icons`
 * module). Without intervention, the buttons get Quill's stock 18×18
 * Snow glyphs and the templates in `editor.templ` get clobbered.
 *
 * We override the icons map here with Keralam-styled HTML strings
 * (24×24 viewBox, fill="none", stroke="currentColor", stroke-width 2,
 * round caps/joins). Path geometry mirrors `components/icon.templ`'s
 * Tabler-Icons set so the library and the editor share one source of
 * truth.
 *
 * Registered once at boot in src/js/editor/quill-setup.ts, before any
 * `new Quill()` instantiation.
 */

export interface KeralamIconMap {
    bold: string;
    italic: string;
    underline: string;
    strike: string;
    blockquote: string;
    code: string;
    "code-block": string;
    subscript: string;
    superscript: string;
    link: string;
    "attach-file": string;
    image: string;
    table: string;
    header: Record<"false" | "1" | "2" | "3", string>;
    list: Record<"ordered" | "bullet" | "check", string>;
    indent: Record<"-1" | "+1", string>;
    script: Record<"sub" | "super", string>;
}

const stroke =
    'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';

function svg(content: string): string {
    return `<svg viewBox="0 0 24 24" ${stroke}>${content}</svg>`;
}

const keralamIcons: KeralamIconMap = {
    bold: svg(
        `<path d="M7 5h6a3.5 3.5 0 0 1 0 7h-6l0 -7"/><path d="M13 12h1a3.5 3.5 0 0 1 0 7h-7v-7"/>`,
    ),
    italic: svg(
        `<path d="M11 5l6 0"/><path d="M7 19l6 0"/><path d="M14 5l-4 14"/>`,
    ),
    underline: svg(
        `<path d="M7 5v5a5 5 0 0 0 10 0v-5"/><path d="M5 19h14"/>`,
    ),
    strike: svg(
        `<path d="M5 12l14 0"/><path d="M16 6.5a4 2 0 0 0 -4 -1.5h-1a3.5 3.5 0 0 0 0 7h2a3.5 3.5 0 0 1 0 7h-1.5a4 2 0 0 1 -4 -1.5"/>`,
    ),
    blockquote: svg(
        `<path d="M6 15h15"/><path d="M21 19h-15"/><path d="M15 11h6"/><path d="M21 7h-6"/><path d="M9 9h1a1 1 0 1 1 -1 1v-2.5a2 2 0 0 1 2 -2"/><path d="M3 9h1a1 1 0 1 1 -1 1v-2.5a2 2 0 0 1 2 -2"/>`,
    ),
    code: svg(
        `<path d="M7 8l-4 4l4 4"/><path d="M17 8l4 4l-4 4"/><path d="M14 4l-4 16"/>`,
    ),
    "code-block": svg(
        `<path d="M5 4l-2 2l2 2"/><path d="M12 4l2 2l-2 2"/><path d="M8 8l1 -4"/><path d="M17 6a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-7"/>`,
    ),
    subscript: svg(
        `<path d="M5 7l8 10m-8 0l8 -10"/><path d="M21 20h-4l3.5 -4a1.73 1.73 0 0 0 -3.5 -2"/>`,
    ),
    superscript: svg(
        `<path d="M5 7l8 10m-8 0l8 -10"/><path d="M21 11h-4l3.5 -4a1.73 1.73 0 0 0 -3.5 -2"/>`,
    ),
    link: svg(
        `<path d="M9 15l6 -6"/><path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464"/><path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463"/>`,
    ),
    "attach-file": svg(
        `<path d="M15 7l-6.5 6.5a1.5 1.5 0 0 0 3 3l6.5 -6.5a3 3 0 0 0 -6 -6l-6.5 6.5a4.5 4.5 0 0 0 9 9l6.5 -6.5"/>`,
    ),
    image: svg(
        `<path d="M4 6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2l0 -12"/><path d="M4 16l16 0"/><path d="M4 12l3 -3c.928 -.893 2.072 -.893 3 0l4 4"/><path d="M13 12l2 -2c.928 -.893 2.072 -.893 3 0l2 2"/><path d="M14 7l.01 0"/>`,
    ),
    table: svg(
        `<rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="3" y1="15" x2="21" y2="15"/><line x1="12" y1="3" x2="12" y2="21"/>`,
    ),
    // Header / heading — Quill's `buildButtons` looks up
    // `icons['header'][value]` to fill the four ql-header buttons
    // (Paragraph + H1/H2/H3). Path data mirrors
    // components/icon.templ's IconText/IconHeading1/2/3.
    header: {
        "false": svg(
            `<path d="M13 4v16"/><path d="M17 4v16"/><path d="M19 4h-9.5a4.5 4.5 0 0 0 0 9h3.5"/>`,
        ),
        "1": svg(
            `<path d="M19 18v-8l-2 2"/><path d="M4 6v12"/><path d="M12 6v12"/><path d="M11 18h2"/><path d="M3 18h2"/><path d="M4 12h8"/><path d="M3 6h2"/><path d="M11 6h2"/>`,
        ),
        "2": svg(
            `<path d="M17 12a2 2 0 1 1 4 0c0 .591 -.417 1.318 -.816 1.858l-3.184 4.143l4 0"/><path d="M4 6v12"/><path d="M12 6v12"/><path d="M11 18h2"/><path d="M3 18h2"/><path d="M4 12h8"/><path d="M3 6h2"/><path d="M11 6h2"/>`,
        ),
        "3": svg(
            `<path d="M19 14a2 2 0 1 0 -2 -2"/><path d="M17 16a2 2 0 1 0 2 -2"/><path d="M4 6v12"/><path d="M12 6v12"/><path d="M11 18h2"/><path d="M3 18h2"/><path d="M4 12h8"/><path d="M3 6h2"/><path d="M11 6h2"/>`,
        ),
    },
    list: {
        ordered: svg(
            `<path d="M11 6h9"/><path d="M11 12h9"/><path d="M12 18h8"/><path d="M4 16a2 2 0 1 1 4 0c0 .591 -.5 1 -1 1.5l-3 2.5h4"/><path d="M6 10v-6l-2 2"/>`,
        ),
        bullet: svg(
            `<path d="M9 6l11 0"/><path d="M9 12l11 0"/><path d="M9 18l11 0"/><path d="M5 6l0 .01"/><path d="M5 12l0 .01"/><path d="M5 18l0 .01"/>`,
        ),
        check: svg(
            `<path d="M3.5 5.5l1.5 1.5l2.5 -2.5"/><path d="M3.5 11.5l1.5 1.5l2.5 -2.5"/><path d="M3.5 17.5l1.5 1.5l2.5 -2.5"/><path d="M11 6l9 0"/><path d="M11 12l9 0"/><path d="M11 18l9 0"/>`,
        ),
    },
    indent: {
        "-1": svg(
            `<path d="M21 6H3M15 12H3M11 18H3M21 12l-6-3v6l6-3z"/>`,
        ),
        "+1": svg(
            `<path d="M21 6H3M15 12H3M11 18H3M15 9l6 3-6 3V9z"/>`,
        ),
    },
    script: {
        sub: svg(
            `<path d="M5 7l8 10m-8 0l8 -10"/><path d="M21 20h-4l3.5 -4a1.73 1.73 0 0 0 -3.5 -2"/>`,
        ),
        super: svg(
            `<path d="M5 7l8 10m-8 0l8 -10"/><path d="M21 11h-4l3.5 -4a1.73 1.73 0 0 0 -3.5 -2"/>`,
        ),
    },
};

export default keralamIcons;
