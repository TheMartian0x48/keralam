import { Controller } from '@hotwired/stimulus';

type TimeFormatValue = 'date' | 'date-time' | 'time';

/**
 * Rewrites a <time> element's text in the reader's locale and timezone (or UTC).
 *
 * The datetime attribute, the machine-readable instant, is never touched. A Stimulus
 * controller runs when the element connects, so a <time> added to the page later is
 * formatted too. A date also gets the full date, time and zone as its title, so the exact
 * moment is one hover away.
 */
export default class TimeController extends Controller<HTMLTimeElement> {
    static values = {
        format: { type: String, default: 'date' },
        utc: { type: Boolean, default: false },
    };

    declare formatValue: TimeFormatValue;
    declare utcValue: boolean;

    connect(): void {
        const instant = new Date(this.element.dateTime);
        if (Number.isNaN(instant.getTime())) return;

        const zone: Intl.DateTimeFormatOptions = this.utcValue ? { timeZone: 'UTC' } : {};
        const date: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short', year: 'numeric' };
        const clock: Intl.DateTimeFormatOptions = { hour: '2-digit', minute: '2-digit', timeZoneName: 'short' };

        let options: Intl.DateTimeFormatOptions;
        switch (this.formatValue) {
            case 'time': options = clock; break;
            case 'date-time': options = { ...date, ...clock }; break;
            default: options = date;
        }
        this.element.textContent = new Intl.DateTimeFormat([], { ...options, ...zone }).format(instant);

        if (this.formatValue === 'date' && !this.element.title) {
            this.element.title = new Intl.DateTimeFormat([], { ...date, ...clock, ...zone }).format(instant);
        }
    }
}
