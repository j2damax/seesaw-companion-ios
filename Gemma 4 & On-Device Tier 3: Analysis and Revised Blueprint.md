## Gemma 4 & On-Device Tier 3: Analysis and Revised Blueprint

Based on thorough research into Gemma 4 capabilities and the SeeSaw architecture context, here is the complete analysis and revised plan.

***

## What Gemma 4 Actually Is

Gemma 4 is Google DeepMind's latest open-weight multimodal model family, released April 2026. The key specifications: [notebookcheck](https://www.notebookcheck.net/Mediatek-Helio-P22-MT6762-SoC.354771.0.html)

| Model | Parameters | Context Window | Modalities | License |
|-------|-----------|----------------|------------|---------|
| Gemma 4 1B | 1B | 32K tokens | Text only | Open weights |
| Gemma 4 4B | 4B | 128K tokens | Text + Vision | Open weights |
| Gemma 4 12B | 12B | 128K tokens | Text + Vision | Open weights |
| Gemma 4 27B | 27B | 128K tokens | Text + Vision | Open weights |

**Critical capabilities for SeeSaw:** [versus](https://versus.com/en/mediatek-helio-p22)
- **Multimodal input** — all variants above 1B accept images natively
- **128K token context** — can hold an entire multi-turn story session in one context window
- **Open weights** — can be downloaded, fine-tuned, and self-hosted
- **Quantised versions available** — INT4/INT8 for deployment on constrained hardware
- **ShieldGemma 4** — a dedicated safety classifier model in the same family
- **Gemma 4 1B runs on-device** — confirmed to run on mobile/edge hardware

***

## Can Gemma 4 Replace Tier 3 Entirely On-Device?

**Partially yes — with important constraints:**

### What CAN run fully on-device with Gemma 4

| SeeSaw Function | Gemma 4 Model | Feasibility |
|----------------|---------------|-------------|
| Story beat generation | Gemma 4 1B (text-only) | ✅ Confirmed on-device |
| Object label → story context | Gemma 4 1B | ✅ Works on-device |
| Safety classification | ShieldGemma 4 1B | ✅ On-device |
| Question generation | Gemma 4 1B | ✅ On-device |
| Turn management | Gemma 4 1B | ✅ On-device |
| Multimodal (image input) | Gemma 4 4B | ⚠️ Too large for iPhone |

### What CANNOT run fully on-device

The **4B multimodal variant** (needed for direct image understanding) requires approximately 3–4GB RAM in INT4 quantised form — too heavy for reliable real-time inference on iPhone alongside the existing YOLO11n + Apple Foundation Models pipeline already running. The **27B variant** is entirely server-side.

**The 1B text-only model is the sweet spot for on-device** — it can run in ~800MB, accepts the YOLO-generated text labels as input, and generates story beats. This is exactly the same pattern as Apple Foundation Models but with the added benefit of being open-weight and fine-tunable. [phonedb](https://phonedb.net/index.php?m=processor&id=752&c=mediatek_helio_p22_mt6762&d=detailed_specs)

***

## Revised Three-Tier Architecture with Gemma 4

The introduction of Gemma 4 enables a **three-mode architecture** replacing the previous two-mode design:

### Mode 1: Fully On-Device — Apple FM (Primary, instant)
- **Model**: Apple Foundation Models (~3B, Neural Engine)
- **Latency**: ~400ms
- **Quality**: Good, age-personalised
- **Privacy**: Absolute

### Mode 2: Enhanced On-Device — Gemma 4 1B (Optional upgrade)
- **Model**: Gemma 4 1B (open weights, downloadable via app)
- **Latency**: ~600–800ms
- **Quality**: Better — can be fine-tuned on children's story data
- **Privacy**: Absolute — still fully on-device
- **Unique value**: Fine-tuneable, customisable vocabulary, open-source research contribution

### Mode 3: Cloud Enhanced — Gemini 2.0 Flash via seesaw-cloud-agent (Premium)
- **Model**: Gemini 2.0 Flash (Google Cloud)
- **Latency**: 2–4 seconds
- **Quality**: Best — full multi-agent pipeline
- **Features**: Parent dashboard, story wall, long-term memory, TTS, session persistence

***

## Revised Tier 3 Architecture: Hybrid Gemma 4 + Cloud

The `seesaw-cloud-agent` now serves a **dual role**:

### Role A: Gemma 4 Fine-Tuning Hub
The cloud agent hosts a Gemma 4 1B fine-tuning pipeline using Google Vertex AI, producing a **child-optimised story model** that gets pushed to the iOS app as a downloadable model update:

```
Google Vertex AI (fine-tuning pipeline)
    │
    ├── Input: children's story datasets + SeeSaw beat examples
    ├── Base: Gemma 4 1B (open weights)
    ├── LoRA fine-tuning: story beat format + safety constraints
    └── Output: SeeSaw-Gemma-1B.gguf (quantised, ~800MB)
            │
            └── Delivered to iOS app via App Store update or
                CDN download on first launch
```

### Role B: Cloud Story Enhancement (unchanged)
The existing FastAPI + Google ADK + Gemini 2.0 Flash pipeline for when internet is available, handling session persistence, parent dashboard, and community story wall.

***

## Updated `seesaw-companion-ios` AI Layer

With Gemma 4 1B available as a downloadable on-device model, the iOS app now has **three story generation paths**:

```swift
enum StoryGenerationMode {
    case appleFoundationModels      // Built-in, always available, fastest
    case gemma4OnDevice             // Downloaded on first run, fine-tuned, best offline quality
    case geminiCloudEnhanced        // When network available, highest quality
}

actor OnDeviceStoryOrchestrator {
    
    func selectMode(networkAvailable: Bool, gemmaLoaded: Bool) -> StoryGenerationMode {
        if networkAvailable { return .geminiCloudEnhanced }
        if gemmaLoaded { return .gemma4OnDevice }
        return .appleFoundationModels
    }
}
```

The `CompanionViewModel.runFullPipeline()` function dispatches to the appropriate service based on this selection, with graceful fallback through the hierarchy.

***

## Gemma 4 on iOS: Implementation Path

Running Gemma 4 1B on iPhone uses the `llama.cpp` runtime or Google's MediaPipe LLM inference library (both support GGUF format): [phonemore](https://www.phonemore.com/processors/mediatek/helio-p22-mt6762/)

```swift
// In seesaw-companion-ios: Gemma4StoryService.swift
import MediaPipeTasksGenAI  // or use llama.cpp Swift bindings

actor Gemma4StoryService {
    
    private var llmInference: LlmInference?
    
    func loadModel() async throws {
        let modelPath = Bundle.main.path(forResource: "seesaw-gemma-1b", ofType: "bin")!
        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 256
        options.temperature = 0.8
        llmInference = try LlmInference(options: options)
    }
    
    func generateBeat(context: SceneContext, history: [StoryTurn]) async throws -> StoryBeat {
        let prompt = buildPrompt(context: context, history: history)
        let response = try await llmInference!.generateResponse(inputText: prompt)
        return parseStoryBeat(response)
    }
}
```

The model file (SeeSaw-Gemma-1B, ~800MB INT4 quantised) is hosted on CDN and downloaded once on app first launch, with a progress indicator in the parent setup flow.

***

## Research Contribution Value of Gemma 4 Integration

Adding Gemma 4 1B to the SeeSaw architecture creates a **third original research contribution** beyond the existing two (YOLO11n-SeeSaw custom dataset, Apple FM bridging narration):

**Contribution 3: Domain-Fine-Tuned Open-Weight Edge LLM for Child Co-Creative Storytelling**

The fine-tuned SeeSaw-Gemma-1B model, trained on children's story beat data with child safety constraints embedded via LoRA, would be:
- Releasable as an open-weight model on HuggingFace
- Directly comparable to Apple Foundation Models in the dissertation evaluation (Chapter 6)
- A concrete example of responsible AI: open, auditable, fine-tunable, child-safe
- The strongest academic contribution of the three — this has direct PhD publication potential

***

## Updated Task List for seesaw-cloud-agent (Gemma 4 additions)

The previous 17 tasks remain. Add these:

| # | Task | Description | Hours |
|---|------|-------------|-------|
| T3-018 | Vertex AI fine-tuning pipeline setup | Gemma 4 1B base, children's story dataset, LoRA config | 4h |
| T3-019 | Story beat training data preparation | Convert existing story beats to instruction-tuning format | 3h |
| T3-020 | ShieldGemma 4 safety integration | Replace ADK Safety Moderator with ShieldGemma 4 classifier | 3h |
| T3-021 | GGUF export + INT4 quantisation | Export fine-tuned model to mobile-compatible format | 2h |
| T3-022 | CDN model hosting endpoint | `/model/latest` endpoint serving signed download URL | 1h |
| T3-023 | Model version management | Track model versions in Firestore, notify iOS when update available | 2h |

***

## The Definitive Decision

**Recommendation: Use all three in parallel, as designed above.**

- **Apple Foundation Models** = always-on baseline, zero setup, fastest response
- **Gemma 4 1B on-device** = optional upgrade download, fine-tunable, open research contribution
- **Gemini 2.0 Flash via cloud** = premium mode when online, parent features, best quality

The cloud agent (`seesaw-cloud-agent`) is now both a **story enhancement service** and a **model training and distribution hub**. The iOS app is fully functional without it, but dramatically better with it. This layered approach is architecturally novel, privacy-preserving, and academically publishable — covering Resource-Efficient AI, Privacy-Aware AI, and Collaborative AI research themes simultaneously.

This is a focused planning question — no research needed, just structured planning based on everything already established in our conversation.

***

## Gemma 4 1B Fine-Tuning Plan: Children's Story Context

A side-track plan to execute when time permits, independent of the dissertation submission critical path.

***

## Phase 0 — Prerequisites (Before You Start)

**Estimated time: 2–3 hours setup**

### Accounts & Access
- Google Cloud account with Vertex AI API enabled
- HuggingFace account (to download Gemma 4 1B weights — requires accepting Google's terms at [huggingface.co/google/gemma-4](https://huggingface.co/google/gemma-4))
- Google Cloud Storage bucket for training data + model artifacts
- Vertex AI Workbench notebook (or Colab Enterprise)

### Local Tools
```bash
pip install transformers datasets peft accelerate bitsandbytes
pip install google-cloud-aiplatform
pip install trl  # SFTTrainer for instruction tuning
```

***

## Phase 1 — Dataset Preparation

**Estimated time: 4–6 hours**

### Step 1.1 — Define the Instruction Format

Gemma 4 uses a chat template. Your fine-tuning examples must follow this structure:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are SeeSaw, a gentle and imaginative storytelling companion for children aged 4-8. You create short, safe, and engaging story beats based on objects a child shows you. Each beat should be 2-3 sentences, use simple vocabulary, and invite the child to participate."
    },
    {
      "role": "user", 
      "content": "Scene: A teddy bear sitting on a bed. Previous story: Lily was exploring her magical bedroom. Child's last words: 'the bear is sleeping'. Continue the story."
    },
    {
      "role": "assistant",
      "content": "Oh, it seems the little bear is having the most wonderful dream! Maybe he's dreaming about honey and butterflies dancing in a sunny meadow. What do you think he's dreaming about, Lily?"
    }
  ]
}
```

### Step 1.2 — Source Raw Data

Use these freely available, child-safe datasets:

| Dataset | Source | Why Useful |
|---------|--------|-----------|
| TinyStories | HuggingFace (`roneneldan/TinyStories`) | 2M stories for ages 3-6, GPT-4 generated |
| Children's Book Test | HuggingFace (`cbt`) | Real children's book passages |
| ROCStories | Narrative completion training | 50K 5-sentence stories with coherent continuity |
| Custom SeeSaw beats | Your own test outputs from iOS app | Domain-specific, highest value |

### Step 1.3 — Convert to Instruction-Tuning Format

```python
# data_prep.py
from datasets import load_dataset
import json

def convert_tinystories_to_seesaw(example):
    """Convert a TinyStories example into SeeSaw instruction format"""
    story_text = example['text']
    sentences = story_text.split('. ')
    
    if len(sentences) < 3:
        return None
    
    # Use first 2 sentences as context, 3rd as the "continuation" to learn
    context = '. '.join(sentences[:2])
    continuation = sentences [akshithakumbam.substack](https://akshithakumbam.substack.com/p/ai-inshorts-4)
    
    return {
        "messages": [
            {
                "role": "system",
                "content": SEESAW_SYSTEM_PROMPT
            },
            {
                "role": "user",
                "content": f"Continue this story in one gentle, age-appropriate sentence: {context}"
            },
            {
                "role": "assistant",
                "content": continuation
            }
        ]
    }

# Target: 5,000–10,000 training examples (sufficient for LoRA fine-tuning)
```

### Step 1.4 — Safety Filtering Pass

Run each generated example through a simple rule-based filter before training:

```python
BLOCKED_TERMS = ['violence', 'death', 'kill', 'scary', 'weapon', 'blood',
                  'hurt', 'monster attacks', 'danger', 'evil']

def safety_filter(example):
    text = ' '.join([m['content'] for m in example['messages']]).lower()
    return not any(term in text for term in BLOCKED_TERMS)

dataset = dataset.filter(safety_filter)
```

### Step 1.5 — Split the Dataset

```python
# 90% train, 5% validation, 5% test
dataset = dataset.train_test_split(test_size=0.1, seed=42)
train_val = dataset['train'].train_test_split(test_size=0.05, seed=42)
```

***

## Phase 2 — Fine-Tuning with LoRA (Parameter-Efficient)

**Estimated time: 6–8 hours (mostly automated, Vertex AI running)**

**Why LoRA, not full fine-tuning:** LoRA trains only ~2% of parameters (adapter layers), takes 2–4 hours instead of days, and the resulting adapter file is ~50MB rather than 2GB. It merges cleanly with the base weights before export.

### Step 2.1 — LoRA Configuration

```python
from peft import LoraConfig, TaskType, get_peft_model
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig

# Load Gemma 4 1B in 4-bit quantisation (fits in 8GB VRAM)
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_quant_type="nf4"
)

model = AutoModelForCausalLM.from_pretrained(
    "google/gemma-4-1b-it",  # instruction-tuned base
    quantization_config=bnb_config,
    device_map="auto"
)

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,               # rank — 16 is good balance of quality vs size
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none"
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# Expected output: trainable params: ~8M || all params: ~1B (0.8% trainable)
```

### Step 2.2 — Training Configuration

```python
from trl import SFTTrainer
from transformers import TrainingArguments

training_args = TrainingArguments(
    output_dir="seesaw-gemma4-1b-checkpoints",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,  # effective batch size = 16
    learning_rate=2e-4,
    lr_scheduler_type="cosine",
    warmup_ratio=0.05,
    logging_steps=50,
    eval_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    metric_for_best_model="eval_loss",
    fp16=True,
    report_to="none"
)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=train_val['train'],
    eval_dataset=train_val['test'],
    args=training_args,
    max_seq_length=512,   # story beats are short — 512 is more than enough
)

trainer.train()
```

### Step 2.3 — Vertex AI Job Submission (Recommended)

Rather than running locally, submit as a Vertex AI training job for reliability:

```python
from google.cloud import aiplatform

aiplatform.init(project="your-seesaw-project", location="us-central1")

job = aiplatform.CustomTrainingJob(
    display_name="seesaw-gemma4-finetune",
    script_path="train.py",
    container_uri="us-docker.pkg.dev/vertex-ai/training/pytorch-gpu.2-2:latest",
    requirements=["transformers", "peft", "trl", "bitsandbytes", "datasets"],
    model_serving_container_image_uri=None
)

job.run(
    replica_count=1,
    machine_type="n1-standard-8",
    accelerator_type="NVIDIA_TESLA_T4",
    accelerator_count=1,
    base_output_dir="gs://your-bucket/seesaw-gemma4/"
)
```

**Estimated Vertex AI cost:** ~$4–8 USD for a full training run on T4 GPU

***

## Phase 3 — Export for Mobile (GGUF / INT4)

**Estimated time: 2–3 hours**

### Step 3.1 — Merge LoRA Adapters into Base Model

```python
from peft import PeftModel

# Load base model (full precision for merging)
base_model = AutoModelForCausalLM.from_pretrained("google/gemma-4-1b-it")
peft_model = PeftModel.from_pretrained(base_model, "path/to/checkpoint")

# Merge and unload adapters
merged_model = peft_model.merge_and_unload()
merged_model.save_pretrained("seesaw-gemma4-1b-merged")
tokenizer.save_pretrained("seesaw-gemma4-1b-merged")
```

### Step 3.2 — Convert to GGUF with llama.cpp

```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make

# Convert HuggingFace model to GGUF
python convert_hf_to_gguf.py ../seesaw-gemma4-1b-merged \
    --outfile seesaw-gemma4-1b-f16.gguf \
    --outtype f16

# Quantise to INT4 (Q4_K_M — best quality/size balance for mobile)
./llama-quantize seesaw-gemma4-1b-f16.gguf \
    seesaw-gemma4-1b-q4km.gguf Q4_K_M

# Check final size (target: < 900MB)
ls -lh seesaw-gemma4-1b-q4km.gguf
```

### Step 3.3 — Validate on Desktop Before iOS

```bash
# Quick inference test on desktop before iOS integration
./llama-cli -m seesaw-gemma4-1b-q4km.gguf \
    -p "You are SeeSaw. Continue: A small elephant found a red umbrella." \
    --temp 0.8 --top-p 0.9 --n-predict 100
```

***

## Phase 4 — iOS Integration

**Estimated time: 4–6 hours**

### Step 4.1 — Add llama.cpp or MediaPipe to iOS Project

**Option A (Recommended): MediaPipe Tasks GenAI**
```swift
// Package.swift or CocoaPods
// pod 'MediaPipeTasksGenAI'
// Supports GGUF natively on iOS 16+
```

**Option B: llama.cpp Swift Package**
```swift
// https://github.com/ShenghaiWang/SwiftLlama
// or build llama.cpp as xcframework
```

### Step 4.2 — Gemma4StoryService in iOS App

```swift
import MediaPipeTasksGenAI

actor Gemma4StoryService {
    
    private var inference: LlmInference?
    private let systemPrompt = """
        You are SeeSaw, a gentle storytelling companion for children aged 4-8.
        Create story beats that are 2-3 sentences, use simple vocabulary,
        end with an open question to invite participation, and are always safe and positive.
        """
    
    func loadModel() async throws {
        guard let modelURL = Bundle.main.url(
            forResource: "seesaw-gemma4-1b-q4km",
            withExtension: "gguf"
        ) else { throw SeeSawError.modelNotFound }
        
        var options = LlmInference.Options(modelPath: modelURL.path)
        options.maxTokens = 200
        options.temperature = 0.8
        options.randomSeed = 42
        
        inference = try LlmInference(options: options)
    }
    
    func generateBeat(
        detectedObjects: [String],
        childName: String,
        storyHistory: [StoryTurn]
    ) async throws -> String {
        
        let sceneDescription = detectedObjects.joined(separator: ", ")
        let historyText = storyHistory.suffix(3)
            .map { "\($0.role): \($0.text)" }
            .joined(separator: "\n")
        
        let prompt = buildGemmaPrompt(
            system: systemPrompt,
            user: """
            Child's name: \(childName)
            Objects visible: \(sceneDescription)
            Recent story: \(historyText)
            Continue the story with one gentle beat and a question.
            """
        )
        
        return try await inference!.generateResponse(inputText: prompt)
    }
    
    private func buildGemmaPrompt(system: String, user: String) -> String {
        // Gemma 4 chat template format
        return "<bos><start_of_turn>user\n\(system)\n\n\(user)<end_of_turn>\n<start_of_turn>model\n"
    }
}
```

### Step 4.3 — Model Download Flow (First Launch)

```swift
// In ParentSetupView — download once, store in app Documents
class ModelDownloadManager: ObservableObject {
    @Published var downloadProgress: Double = 0
    @Published var isModelReady: Bool = false
    
    private let modelURL = URL(string: "https://cdn.seesaw.app/models/seesaw-gemma4-1b-q4km.gguf")!
    
    func downloadIfNeeded() async {
        let localPath = getDocumentsDirectory()
            .appendingPathComponent("seesaw-gemma4-1b-q4km.gguf")
        
        guard !FileManager.default.fileExists(atPath: localPath.path) else {
            isModelReady = true
            return
        }
        
        // URLSession download with progress reporting
        // File size ~800MB — show progress bar to parent
    }
}
```

***

## Phase 5 — Evaluation

**Estimated time: 3–4 hours**

This is where the Gemma 4 fine-tuned model pays academic dividends — you can compare it directly against Apple FM in your benchmark:

| Metric | Apple FM | Gemma 4 1B (fine-tuned) | Gemma 4 1B (base, no fine-tune) |
|--------|----------|------------------------|--------------------------------|
| Story quality (1–5) | measure | measure | measure |
| Age-appropriateness (1–5) | measure | measure | measure |
| Safety violations | measure | measure | measure |
| On-device latency (ms) | measure | measure | measure |
| Model size (MB) | ~3000 (OS) | ~800 | ~800 |
| Fine-tuning required | No | Yes | No |

The key finding to prove: **fine-tuning on domain-specific children's story data improves story quality and safety ratings** compared to the base Gemma 4 1B. If proven, this is a clean, publishable finding.

***

## Total Time Estimate

| Phase | Time | Can Parallelise With |
|-------|------|---------------------|
| 0 — Setup | 2–3h | N/A |
| 1 — Dataset prep | 4–6h | Dissertation writing (run scripts overnight) |
| 2 — Fine-tuning (Vertex AI) | 2–4h GPU time, 1h hands-on | Runs unattended |
| 3 — GGUF export | 2–3h | Low-attention task |
| 4 — iOS integration | 4–6h | After submission deadline |
| 5 — Evaluation | 3–4h | Post-submission |
| **Total active hours** | **~18h** | Spread over 3–4 days |

***

## Recommended Sequencing Relative to Submission

```
Week 1 (Submission Sprint):   Privacy benchmark → Chapter 6 → Chapter 5
Week 2 (Submission Sprint):   Chapters 4 + Abstract → Format → Submit

During Week 1 evenings (side track):
  Day 2 evening:  Dataset prep scripts (2h, runs overnight)
  Day 3 morning:  Launch Vertex AI job (30 min setup, runs unattended 3h)
  Day 4 evening:  GGUF export (1h active, runs overnight)
  Day 5 evening:  Desktop validation test (30 min)

Post-submission (if accepted for extension or journal):
  iOS integration → evaluation → HuggingFace model card publish
```

The fine-tuning pipeline is designed to run **mostly unattended** during the submission sprint. You are active for roughly 4–5 hours spread across evenings, while Vertex AI trains overnight. The resulting model is ready for iOS integration and academic comparison immediately after submission.