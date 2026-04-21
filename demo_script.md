# SeeSaw — App Demo Script

> **Data folder:** All CSV files, screenshots and exports are on [Google Drive](https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing) — see `DATA_LOCATION.md`.
## Screen Recording Walkthrough

**Total runtime:** ~4–5 minutes  
**Device:** iPhone 15 Pro (physical device, not simulator — shows Neural Engine in action)  
**Setup before recording:**
- Child age set to 6 in Settings
- Story Mode set to On-Device (Apple AI)
- Apple Intelligence enabled
- A few objects visible in the room (e.g., toy, book, lamp)
- Portrait orientation locked
- Do Not Disturb on
- Battery ≥ 50%

---

## Shot 1 — App Icon & Launch (0:00–0:15)

**What to show:** Home screen → tap SeeSaw icon → launch screen  
**Narration script:**
> "SeeSaw is a privacy-first AI storytelling app for children aged 3 to 8.
> It runs entirely on the iPhone — no account needed, no photos sent anywhere."

**Tips:** Film from slightly above to show the phone clearly. Hold steady for 3 seconds on launch screen.

---

## Shot 2 — Onboarding / Terms (0:15–0:30)

**What to show:** Swipe through welcome screens, accept terms  
**Narration script:**
> "On first launch, parents see a brief welcome explaining the privacy guarantee.
> The app is clear: it processes everything on-device and only anonymous object labels ever leave the phone."

**Tips:** Tap through quickly — don't linger on legal text. Show the "I understand" accept button.

---

## Shot 3 — Settings (0:30–0:50)

**What to show:** Tap gear icon → Settings → show child age stepper → show Story Mode picker  
**Narration script:**
> "In Settings, a parent sets their child's age — this tunes the vocabulary and story complexity.
> Story Mode can be On-Device using Apple Intelligence, fully offline with Gemma 3, or Cloud mode when WiFi is available."

**Tips:** Slowly scroll through the Story Mode picker so all four options are visible: On-Device (Apple AI), On-Device (Gemma 3), Cloud, Hybrid.

---

## Shot 4 — Camera Tab (0:50–1:20)

**What to show:** Tap Camera tab → point camera at objects in room → show live preview  
**Narration script:**
> "The camera tab is where a story begins.
> Point the iPhone at anything in your child's room — a toy, a book, anything on the shelf.
> The app sees the scene, but never saves or transmits the photo."

**Tips:** Pan slowly across the room. Make sure 2–3 recognisable objects are in frame (teddy bear, book, lamp work well). Hold steady for 3–4 seconds before tapping Capture.

---

## Shot 5 — Capture & Privacy Pipeline (1:20–1:45)

**What to show:** Tap "Capture Scene" → show the blurred preview image → show detected objects list  
**Narration script:**
> "When you tap Capture, the six-stage privacy pipeline runs entirely on-device in under 200 milliseconds.
> Faces are blurred first. Then the YOLO neural network identifies objects.
> What you see here are just labels — teddy bear, book, lamp — not the photo itself."

**Tips:** The blurred preview is a key visual. Pause on it for 2 seconds. Then show the object labels clearly.

---

## Shot 6 — Generate Story (1:45–2:15)

**What to show:** Tap "Generate Story" → "Generating story…" spinner → first story beat appears (streaming text)  
**Narration script:**
> "Apple Intelligence generates the opening story beat directly on the Neural Engine — no internet request.
> The story always features the objects the camera saw, making it feel personal and grounded in the child's real world."

**Tips:** If streaming text is visible, let it run in real-time — don't skip. This is a key differentiator to show.

---

## Shot 7 — Story Playback & Child Interaction (2:15–3:00)

**What to show:** Audio plays → story text is highlighted → question appears → tap the answer button or speak  
**Narration script:**
> "The story is read aloud using on-device text-to-speech.
> At the end of each story beat, the AI asks your child a question.
> The child's spoken answer shapes where the story goes next — making them the co-author."

**Tips:** If possible, have a child (or use your own voice as the child) answer the question naturally. Show 2 complete beats (question → answer → next beat) to demonstrate the interactive loop.

---

## Shot 8 — Story Continues (3:00–3:20)

**What to show:** Second and third beats generating, each building on the child's answers  
**Narration script:**
> "Each turn, the model incorporates the child's answer into the narrative.
> The story remembers where it's been — it's not just random generation, it's coherent collaborative storytelling."

**Tips:** Swipe or scroll if the story text is long. Show the beat counter if visible in the UI.

---

## Shot 9 — Story Ends & Rating Sheet (3:20–3:45)

**What to show:** Story reaches natural ending → StoryRatingView sheet slides up → parent taps 3 star ratings → Submit  
**Narration script:**
> "When the story reaches its natural ending, a quick rating sheet appears for the parent.
> Three questions — did your child enjoy it, was it age-appropriate, did the story match what the camera saw?
> These ratings are stored only on your device until you choose to share them."

**Tips:** Tap the stars slowly and deliberately so they're clearly visible. Show the Submit button. Don't rush.

---

## Shot 10 — Story Timeline (3:45–4:05)

**What to show:** Tap Timeline tab → show list of saved story sessions → tap one to expand  
**Narration script:**
> "The Story Timeline saves every session privately on your device.
> You can revisit what the AI created, see the objects that inspired each story, and review your ratings."

**Tips:** Ideally have 3–4 sessions already saved. Tap one to show the full story text if the UI supports it.

---

## Shot 11 — Settings: Metrics & Export (4:05–4:30)

**What to show:** Settings → scroll to Privacy Metrics → show Pipeline Runs count, Sanitisation Rate 100% → scroll to Story Ratings → show avg scores → tap Export All Data → share sheet appears  
**Narration script:**
> "For research purposes, parents can see a full privacy audit — every pipeline run confirmed no raw data transmitted.
> One tap exports all research data as CSV files — privacy metrics, story metrics, and parent ratings —
> ready to email to the researcher."

**Tips:** Zoom in slightly on "Sanitisation Rate: 100%" — this is a key dissertation finding. Show the share sheet opening with the four CSV files.

---

## Shot 12 — Closing (4:30–4:45)

**What to show:** Return to camera tab → hold camera up steady → fade out  
**Narration script:**
> "SeeSaw — where your child's world becomes their story.
> Privately, on-device, with no data left behind."

**Tips:** End on a clean shot of the camera tab ready for the next story. Fade to black.

---

## Post-Recording Checklist

- [ ] Export as MP4, H.264, 1080p minimum
- [ ] Trim dead air at start and end
- [ ] Add chapter markers if hosting on YouTube (use shot timestamps above)
- [ ] Upload to YouTube (unlisted) or Vimeo for dissertation appendix link
- [ ] Save raw `.mov` to `[Google Drive]/step16/exports/seesaw_demo_raw.mov`
- [ ] Save final edit to `[Google Drive]/step16/exports/seesaw_demo_final.mp4`

---

## Key Screenshots to Extract from Recording

While recording or separately, capture these static screenshots:

| Filename | Shot # | What it shows |
|----------|--------|--------------|
| `app_camera_tab.png` | 4 | Camera live preview with objects in scene |
| `app_capture_blurred.png` | 5 | Blurred preview + object labels list |
| `app_story_generating.png` | 6 | "Generating story…" loading state |
| `app_story_beat1.png` | 7 | First story beat text with question |
| `app_story_beat2.png` | 8 | Second beat showing narrative continuity |
| `app_rating_sheet.png` | 9 | Rating sheet with 3 star criteria |
| `app_story_timeline.png` | 10 | Timeline tab with multiple sessions |
| `app_settings_privacy.png` | 11 | Privacy Metrics: 100% sanitisation rate |
| `app_settings_export.png` | 11 | Export All Data share sheet |
| `app_settings_modes.png` | 3 | Story Mode picker showing all 4 modes |

Save all screenshots to `[Google Drive]/step16/screenshots/app_*.png`

---

## Hosting & Sharing

**Options for hosting the demo video:**

| Platform | Link format | Notes |
|----------|-------------|-------|
| YouTube (unlisted) | `https://youtu.be/xxxxx` | Best for dissertation appendix — stable URL |
| Vimeo | `https://vimeo.com/xxxxx` | Cleaner player, good for academic submissions |
| GitHub Releases | Upload as asset to `v1.0-msc-submission` tag | Keeps everything in one place |

**Recommended:** Upload to YouTube (unlisted) + attach to the GitHub `v1.0-msc-submission` release as a linked asset.

Once uploaded, add the URL to `submission.md` §11 (Appendix — Digital Artefacts).
