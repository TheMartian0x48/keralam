/**
 * Global Window interface extensions for Keralam components.
 */

import type { Application } from '@hotwired/stimulus';
import type * as Stimulus from '@hotwired/stimulus';
import type Quill from 'quill';
import type * as QuillNS from 'quill';

export interface AutocompleteOption {
    label: string;
    value: unknown;
}

export type ToastPositionValue =
    | 'top-left'
    | 'top-center'
    | 'top-right'
    | 'bottom-left'
    | 'bottom-center'
    | 'bottom-right';

export type ToastTypeValue = 'info' | 'success' | 'warning' | 'danger';

export interface ShowToastOptions {
    duration?: number;
}

declare module '*.css';

declare global {
    interface Window {
        keralamUtils: {
            prefersReducedMotion: boolean;
            escapeHtml(text: string): string;
        };

        showToast(
            message: string,
            type?: ToastTypeValue,
            title?: string,
            position?: ToastPositionValue,
            options?: ShowToastOptions,
        ): void;

        keralam: {
            app: Application;
            Stimulus: typeof Stimulus;
            Quill: typeof Quill & typeof QuillNS;
        };
    }
}
