# ClipAI Privacy Policy

Last updated: March 16, 2026

## Overview

ClipAI is a macOS utility that sends clipboard content to the Anthropic Claude API for AI-powered analysis. Your privacy matters to us, and this policy explains how your data is handled.

## Data Collection

**ClipAI does not collect, store, or transmit any personal data to its developers.**

### What ClipAI accesses

- **Clipboard content**: Only when you explicitly trigger the app via the keyboard shortcut (⌘⌥I). ClipAI never reads your clipboard in the background.
- **API key**: Your Anthropic API key is stored locally on your Mac using UserDefaults and is never shared with anyone other than Anthropic's API servers.

### What is sent externally

- When you trigger ClipAI, the current clipboard text is sent to **Anthropic's API** (`api.anthropic.com`) to generate a response.
- This communication is governed by [Anthropic's Privacy Policy](https://www.anthropic.com/privacy) and [Terms of Service](https://www.anthropic.com/terms).
- Anthropic's API does not use your inputs for model training by default.

### What is NOT collected

- No analytics or telemetry
- No crash reports sent externally
- No user accounts or registration
- No browsing history or app usage tracking
- No clipboard monitoring in the background

## Data Storage

All data stays on your Mac:
- API key: stored in local app preferences
- No conversation history is saved
- No logs are written to disk

## Third-Party Services

ClipAI communicates only with:
- **Anthropic API** (`api.anthropic.com`) — to process your queries

## Changes to This Policy

We may update this policy from time to time. Changes will be posted in the app's GitHub repository.

## Contact

If you have questions about this privacy policy, please open an issue on our GitHub repository.
