import { Controller } from '@hotwired/stimulus';

// "system" removes data-theme, so the OS preference decides (light or dark). The rest are
// the built-in light and dark and the named themes in keralam-themes.css. A stored value that
// is not in this list is ignored, so a stale or hand-edited localStorage entry can not put
// an arbitrary string in the attribute.
const themes = [
    'system',
    'light',
    'dark',
    'gruvbox-dark',
    'gruvbox-light',
    'nord',
    'solarized-dark',
    'dracula',
];
const storageKey = 'theme';

function apply(theme: string): void {
    if (theme === 'system') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', theme);
}

function stored(): string {
    const value = localStorage.getItem(storageKey) ?? 'system';
    return themes.includes(value) ? value : 'system';
}

/**
 * Applies the saved theme and changes it.
 *
 * Attach it to the element that holds the picker: a <select> whose option values are the
 * theme names, or a checkbox that means "dark". Without a saved choice the OS preference
 * decides. A page that wants no flash of the wrong theme before this runs can set
 * data-theme on <html> from the server.
 */
export default class ThemeController extends Controller {
    connect(): void {
        const theme = stored();
        apply(theme);
        const select = this.element.querySelector('select');
        if (select) select.value = theme;
    }

    choose(e: Event): void {
        const value = (e.target as HTMLSelectElement).value;
        if (!themes.includes(value)) return;
        localStorage.setItem(storageKey, value);
        apply(value);
    }

    toggle(e: Event): void {
        const dark = (e.target as HTMLInputElement).checked;
        localStorage.setItem(storageKey, dark ? 'dark' : 'light');
        apply(dark ? 'dark' : 'light');
    }
}
