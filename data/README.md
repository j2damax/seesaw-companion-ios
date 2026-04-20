# data/

Collected thesis evaluation data for SeeSaw Companion MSc research.  
Each step folder maps directly to the step numbering in `results_collection_plan.md`.

## Folder index

| Folder | Step | Contents |
|--------|------|----------|
| `step2/` | 2 — Privacy Pipeline Baseline | `privacy_pipeline_raw.csv` (21 rows, debug path), `pipeline_console_filtered.txt` |
| `step3/` | 3 — PII Scrubber Tests | `pii-tests-output.txt` (541 KB, 130 automated tests) |
| `step4/` | 4 — YOLO Scene Detection | `scenes/` (5 controlled scene photos), `logs.md` (detection output) |
| `step5/` | 5 — Cloud Mode Sessions | story_metrics, privacy_pipeline, Proxyman CSV, console logs, Instruments screenshots |
| `step6/` | 6 — Apple FM Sessions | story_metrics, privacy_pipeline, Proxyman CSV, console logs, Instruments screenshots |
| `step7/` | 7 — Gemma 3 1B Sessions | story_metrics, privacy_pipeline, console logs, Instruments screenshots |
| `step8/` | 8 — Hybrid Mode Sessions | story_metrics, privacy_pipeline, Proxyman CSV, console logs, Instruments screenshots |
| `step9/` | 9 — VAD Analysis | `vad_console_logs.txt` — compiled VAD layer decisions from Steps 5–8 |
| `step10/` | 10 — Privacy Verification | Network/privacy screenshots live in `step5–8/screenshots/` per mode |
| `step11/` | 11 — Round-Trip Latency | Analysis documented in `results_template.md` §11; derived from Steps 5–8 metrics |
| `step12/` | 12 — Statistical Comparison | Input CSVs (`story_metrics_*.csv`) + output charts (`charts/*.png`) |
| `step13/` | 13 — Manual Story Scoring | `story_scoring_sheet.md` — extracted story texts + rubric for external raters |
| `step14/` | 14 — Data File Audit | `data_file_audit.md` — expected vs actual file checklist; 13 ✅, 7 ⚠️, 4 ❌ missing (low impact) |

## Root-level files

| File | Description |
|------|-------------|
| `results_template.md` | Primary dissertation results document (filled throughout Steps 2–13) |
| `README.md` | This file |

## Running the analysis

```bash
# From repo root — generates 9 charts into data/step12/charts/
python scripts/analysis_step12.py
```

Requires: `pip install pandas matplotlib scipy numpy`  
Or use the venv: `/tmp/seesaw-analysis-venv/bin/python scripts/analysis_step12.py`
