# Dissertation Data — Google Drive

All measurement data, screenshots, exports, and evidence files have been moved off-repo to Google Drive.

**Google Drive folder:** https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing

## Folder Structure (mirrors former `data/` directory)

```
Google Drive/
  step2/    privacy_pipeline_raw.csv
  step3/    pii-tests-output.txt
  step5/    privacy_pipeline_cloud.csv · story_metrics_cloud.csv · network_cloud_sessions_proxyman.csv
  step6/    privacy_pipeline_ondevice.csv · story_metrics_ondevice.csv · network_proxyman_ondevice.csv
  step7/    privacy_pipeline_gemma4.csv · story_metrics_gemma4.csv
  step8/    hybrid_metrics.csv · privacy_pipeline_hybrid.csv · story_metrics_hybrid.csv · network_hybrid_proxyman.csv
  step9/    vad_console_logs.txt
  step12/   story_metrics_cloud/ondevice/gemma4/hybrid.csv · charts/*.png
  step13/   story_scoring_sheet.md
  step14/   data_file_audit.md
  step15/   story_ratings.csv
  step16/   evidence_collection_guide.md · yolo_evidence.md · cloud_agent_evidence.md
            github_evidence.md · model_card.md · api_cost_analysis.md · dataset_licences.md
            demo_script.md
            exports/  roboflow_layer2/3_class_balance.csv · privacy_pipeline_final.csv · story_metrics_final.csv
            screenshots/  app_settings_export.png · github_*.png · roboflow_*.png
            google_cloud/  gcp_*.png · aistudio_*.png · gcp_billing_report.pdf/.csv
  results_template.md
```

## Key Files for Dissertation Chapters

| Chapter | File | Step |
|---------|------|------|
| Ch.4 Privacy Pipeline | `step2/privacy_pipeline_raw.csv` | Step 2 |
| Ch.5 Story Generation | `step12/story_metrics_*.csv` | Step 12 |
| Ch.5 Hybrid Routing | `step8/hybrid_metrics.csv` | Step 8 |
| Ch.5 Parent Ratings | `step15/story_ratings.csv` | Step 15 |
| Ch.5 VAD Analysis | `step9/vad_console_logs.txt` | Step 9 |
| Ch.5 PII Tests | `step3/pii-tests-output.txt` | Step 3 |
| Ch.6 YOLO Evidence | `step16/yolo_evidence.md` | Step 16 |
| Ch.6 Gemma Evidence | `step16/cloud_agent_evidence.md` | Step 16 |
| Appendix Charts | `step12/charts/*.png` | Step 12 |
