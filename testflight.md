# SeeSaw — TestFlight Release Document

**Version:** 1.0 (testflight-release branch)  
**Build date:** 2026-04-20  
**Bundle ID:** `com.seesaw.companion.ios`  
**Minimum iOS:** 26.0  
**Devices:** iPhone 12 or later (Neural Engine required)  

---

## Part 1 — App Store Connect Page Details

Use these details when creating the app record in App Store Connect under the TestFlight tab.

---

### App Name

```
SeeSaw — AI Story Companion
```

### Subtitle (max 30 chars)

```
Private storytelling for kids
```

### Category

- **Primary:** Kids
- **Secondary:** Education

### Age Rating

**4+** — No objectionable content. All story generation is age-filtered. The app does not connect children to the internet; no user-generated content is shared.

> During App Store Connect age-rating questionnaire: select **No** for all violence, adult content, gambling, social networking, and location-sharing categories. Select **Unrestricted Web Access: No**.

---

### App Description (App Store listing)

```
SeeSaw turns your child's world into a personalised bedtime story — using only what the iPhone camera sees, not who your child is.

Point the camera at a toy, book, or corner of the bedroom. SeeSaw identifies the objects, listens to your child's first answer, and co-creates an interactive story together — one question at a time.

COMPLETELY PRIVATE BY DESIGN
• Raw photos and audio never leave your device
• No account needed for the child
• No biometric data stored or transmitted
• Only anonymous object labels ("teddy bear", "book") reach the story engine
• Independently verifiable — no trust required

INTERACTIVE STORYTELLING
• Child answers questions that shape where the story goes
• Stories adapt to the child's age (3–8 years old)
• Natural conversation pace with on-device voice narration
• Sessions saved to a private Story Timeline on your device only

FOUR STORY MODES
• On-Device (Apple AI) — zero internet, fastest response
• On-Device (Gemma 3) — open-weight model, also zero internet
• Cloud (Gemini) — richer narrative when WiFi available
• Hybrid — best of both worlds

PARENT DASHBOARD
• Export your child's story sessions as CSV for research
• Rate each story for quality feedback
• Full privacy audit trail for every session

SeeSaw is a research prototype developed as part of an MSc dissertation at [University]. By participating, you are contributing to academic research on privacy-preserving AI for children.
```

### Keywords (max 100 chars)

```
kids,stories,AI,privacy,storytelling,bedtime,interactive,children,safe,on-device
```

### Support URL

```
https://github.com/jayampathy/seesaw-companion-ios/issues
```

### Marketing URL (optional)

Leave blank for TestFlight distribution.

### Privacy Policy URL

For TestFlight you must provide a privacy policy URL. Use your GitHub repo's privacy notice or a simple one hosted on GitHub Pages:

```
https://github.com/jayampathy/seesaw-companion-ios/blob/main/PRIVACY.md
```

Minimum privacy policy content required:
> SeeSaw does not collect, store, or transmit personal information. All story generation occurs on-device. The only data transmitted is anonymous object labels when Cloud or Hybrid mode is selected. No account is required. No analytics or crash reporting includes personally identifiable information.

---

### Screenshots Required (App Store Connect)

For TestFlight external testing you need at least one screenshot per device class:

| Device class | Size |
|-------------|------|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320 × 2868 px |
| iPhone 6.5" (iPhone 14 Plus) | 1242 × 2688 px |

Suggested screenshots to capture:
1. Camera tab — connected state with capture button visible
2. Story in progress — "Generating story…" with streaming text
3. Story Timeline — timeline list showing 2–3 sessions
4. Settings — showing Story Ratings section with star averages
5. Rating sheet — the 3-star rating criteria sheet

---

## Part 2 — TestFlight Tester Information

Fill in App Store Connect → TestFlight → Test Information before inviting external testers.

---

### Beta App Description

```
SeeSaw is a privacy-first AI storytelling app for children aged 3–8, developed as part of an MSc research project. This TestFlight build lets your child co-create a story with AI using only what the camera sees — no personal data is ever transmitted.

You are participating in academic research. Your child's participation is entirely voluntary and you can stop at any time. The app does not record audio, store images, or send any personally identifiable information anywhere.

After each story, you (the parent) will be asked to give a quick 3-question star rating. These ratings are kept entirely on your device and can be exported as a CSV file from Settings if you choose to share them with the researcher.

Requirements:
• iPhone 12 or later
• iOS 26.0 or later
• Apple Intelligence enabled (Settings → Apple Intelligence & Siri)
• Optional: allow the app to use the microphone for your child's answers

Thank you for participating!
```

### Feedback Email

```
j2damax@gmail.com
```

### What to Test

```
1. Complete at least 2 full story sessions using the On-Device (Apple AI) mode
2. Try asking your child a question back and see if the story incorporates their answer
3. After each story ends, complete the parent rating sheet (3 stars)
4. Visit Settings and check that "Sessions Rated" shows your ratings
5. Use "Export All Data" in Settings to send the CSV files to the researcher's email
6. Optional: try Cloud or Hybrid mode if your iPhone is on WiFi
```

---

## Part 3 — Parent Invitation Message

Send this message to participating families when their TestFlight invitation is ready.

---

**Subject:** You're invited to test SeeSaw — AI storytelling for your child (MSc research)

---

Hi [Name],

Thank you for agreeing to participate in my MSc research project! I'm developing an AI storytelling app for children that keeps privacy as its top priority — and I need real families to test it before I submit my dissertation.

**What is SeeSaw?**

SeeSaw turns the room around your child into a personalised story. You point the iPhone camera at a toy or book, your child answers a question, and the AI co-creates the next part of the story — one turn at a time. Think of it as an interactive bedtime story where your child is the main character.

**Why is it private?**

Most AI apps for children send photos and audio to cloud servers. SeeSaw is different: it only sends anonymous labels like "teddy bear" or "book" — never photos, never audio, never your child's name or voice. This is the core of my research: proving that AI can be both smart and genuinely private for children.

**What I need from you:**

1. Install the TestFlight app on your iPhone (free from the App Store)
2. Accept the invitation link below
3. Run 2–3 story sessions with your child (ages 3–8 work best)
4. After each story, complete the quick parent rating (3 star questions — takes 10 seconds)
5. When you're done, go to Settings → Export All Data and email the files to j2damax@gmail.com

The whole thing should take 20–30 minutes total across a few days.

**TestFlight invitation link:**  
`[PASTE TESTFLIGHT LINK HERE]`

**Step-by-step instructions:**

1. On your iPhone, open the App Store and install **TestFlight** (it's free, made by Apple)
2. Open this email on your iPhone and tap the invitation link above
3. Tap **Accept** → **Install** in TestFlight
4. Open SeeSaw and tap through the welcome screens
5. Tap the gear icon (⚙) → set your child's age using the stepper
6. Make sure **Story Mode** is set to **On-Device (Apple AI)** for the first story
7. Go to the **Camera** tab, point at something in your child's room, and tap **Capture Scene**
8. Tap **Generate Story** on the preview screen
9. Listen to the story with your child, and help them answer the question when it asks
10. When the story finishes, the **Rate This Story** sheet will appear — fill in the 3 stars
11. After 2–3 sessions, go to Settings → **Export All Data** and email to j2damax@gmail.com

**What data does the app collect?**

- Nothing that identifies your child or family
- Object labels only (e.g. "book", "sofa") — no photos
- Your star ratings (stored only on your device until you choose to share)
- Story session count and timing (for my latency research)

The data stays entirely on your iPhone until you tap Export. You are in complete control of what gets shared.

**Ethics & consent:**

This research has been conducted as part of an MSc degree. Participation is voluntary. You can stop at any time by simply deleting the app. Any data you choose to share will be anonymised before use in the dissertation and will not include any information that could identify you or your child.

Thank you so much for helping me with this — it means a lot to have real families involved!

Best regards,  
Jayampathy Balasuriya  
MSc Computer Science  
j2damax@gmail.com

---

## Part 4 — Eligibility & Inclusion Criteria

For your records when selecting and screening testers.

| Criterion | Requirement |
|-----------|-------------|
| Parent age | 18+ |
| Child age | 3–8 years old |
| Device | iPhone 12, 13, 14, 15, or 16 (any model) |
| iOS version | 26.0 or later (check: Settings → General → Software Update) |
| Apple Intelligence | Must be enabled (Settings → Apple Intelligence & Siri → toggle on) |
| Language | English (app is English-only) |
| Network | WiFi recommended; not required for On-Device mode |
| Exclusion | Children with hearing impairments may find the audio-narrated stories less engaging (not a safety exclusion) |

**Target sample:** 8–12 families  
**Modes to test:** Encourage On-Device first; Cloud/Hybrid optional for WiFi users  
**Duration:** 1–2 weeks of casual testing  

---

## Part 5 — What to Do With the Exported Data

When testers send you the exported CSV files via email:

| File | What it contains | Where to save |
|------|-----------------|---------------|
| `privacy_metrics` | Per-session pipeline latency, face counts, PII tokens | `data/step15/tester_privacy_metrics_[name].csv` |
| `story_metrics` | Per-beat generation time, mode, text length | `data/step15/tester_story_metrics_[name].csv` |
| `hybrid_metrics` | Per-beat routing (localGemma4 vs cloud) | `data/step15/tester_hybrid_metrics_[name].csv` |
| `story_ratings` | Parent star ratings (enjoyment, age-appropriate, scene) | `data/step15/tester_ratings_[name].csv` |

Aggregate the `story_ratings` CSVs to supplement the dissertation story quality analysis (Step 13). Story generation latency data supplements Steps 5–8. Treat each tester's data as an independent replication session.

---

## Part 6 — Build & Archive Checklist (Xcode → TestFlight)

Before archiving, verify:

- [ ] Build scheme: **SeeSaw** (not SeeSawTests)
- [ ] Destination: **Any iOS Device (arm64)**
- [ ] Configuration: **Release**
- [ ] Version: `1.0` (CFBundleShortVersionString)
- [ ] Build number: increment (CFBundleVersion) — e.g. `2` for first TestFlight build
- [ ] Signing: **Automatically manage signing** → your Apple ID team
- [ ] Entitlements: Speech Recognition, Microphone, Camera usage descriptions present in Info.plist
- [ ] GoogleService-Info.plist: present (Firebase Crashlytics needs it even in beta)

Archive steps:
1. Product → Archive
2. Distribute App → TestFlight & App Store → Upload
3. Wait for processing (~10 min)
4. App Store Connect → TestFlight → [build] → Add External Testers group
5. Submit for Beta App Review (usually approved within 24h for first-time)
6. Once approved, share invitation link with families

---

*Document version: 1.0 · Created: 2026-04-20 · Branch: testflight-release*
