# Lectrodryer BAC-50 Configurator

A single-page web application for configuring the Lectrodryer BAC-50 dual-tower
automatic continuous hydrogen gas dryer used in power plant turbine generator
cooling systems.

## Features

- **Part configurator** — build a full BAC-50 model number string from voltage,
  pressure vessel standard, hazardous area rating, controller, dewpoint
  instrumentation, and piping material options, with a live technical summary
  and copy-to-clipboard.
- **P&ID visualizer** — animated SVG process flow diagram of the closed-circuit
  dual-tower cycle, with a toggle between Tower A/Tower B adsorption and
  reactivation phases and simulated operating telemetry.
- **Gemini AI suite** — optional AI-assisted tools: part string / nameplate tag
  decoding (with photo OCR), search-grounded Q&A, CMMS asset JSON generation,
  schematic image generation, and a live voice assistant. Each tool falls back
  to built-in offline content when no API key is configured.
- **Analytics charts** — hydrogen purity vs. windage loss (Chart.js) and the
  4-hour bed reactivation thermal cycle (Plotly).
- **MRO reference** — recommended preventative maintenance intervals.

## Running

The app is a single static HTML file with no build step. Open it directly:

```sh
open index.html
```

or serve it locally:

```sh
python3 -m http.server 8000
# then visit http://localhost:8000/lectrodryer-bac50-configurator/
```

An internet connection is required at load time — Tailwind CSS, Chart.js,
Plotly, and Google Fonts are loaded from CDNs.

## Gemini API features

The AI features call the Google Gemini API from the browser. They ship with the
`apiKey` constants set to an empty string, in which case each feature shows
built-in offline fallback content instead of calling the API. To enable live AI
responses, set the `apiKey` values inside the `<script>` block in `index.html`.
Do not commit a real API key to the repository.
