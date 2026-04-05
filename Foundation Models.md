PART 3: DETAILED IMPLEMENTATION PLAN
Phase 0: Pre-requisites & Model Layer (1-2 days)
0.1 — Define StoryBeat model
File: SeeSaw/Model/StoryBeat.swift
Import FoundationModels
Define @Generable struct StoryBeat with @Guide annotations on every field:
storyText: String — @Guide("3-5 sentences, age-appropriate story segment")
question: String — @Guide("One open-ended imaginative question")
isEnding: Bool — @Guide("True when the story should conclude")
theme: String — @Guide("Current story theme")
suggestedContinuation: String — @Guide("Brief context hint for next turn, not spoken")
0.2 — Define StoryGenerationMode enum
File: SeeSaw/Model/StoryGenerationMode.swift
Cases: .onDevice, .cloud, .hybrid
Persisted in UserDefaults with a default of .onDevice
0.3 — Define StoryError enum
File: SeeSaw/Model/StoryError.swift
Cases: noActiveSession, modelUnavailable, contextWindowExceeded, guardrailViolation, generationFailed(String)
0.4 — Define SceneContext struct
File: SeeSaw/Model/SceneContext.swift
Bridge between PipelineResult and the story service
Fields: labels: [String], sceneCategories: [String], transcript: String?, childAge: Int
Factory method: init(from payload: ScenePayload)
Phase 1: Core On-Device Story Service (2-3 days)
1.1 — Create OnDeviceStoryService
File: SeeSaw/Services/AI/OnDeviceStoryService.swift
Declare as actor OnDeviceStoryService
Key implementation details:
Availability check: Check SystemLanguageModel.default.availability before every session start. Handle .available, .downloading, .unavailable states
Session management: Hold private var session: LanguageModelSession?
Context window monitoring: Track approximate token usage, implement estimateTokenUsage() -> Int using session.tokenCount(for:) API
Sliding window: When approaching 3,500 tokens (safety margin under 4,096), summarize the oldest 2 turns into a single sentence and start a new session with the summary as context
Correct API usage: Use session.respond(to: prompt, generating: StoryBeat.self) for initial implementation, upgrade to session.streamResponse(to:, generating:) in Phase 3
1.2 — Public API design
Code
func checkAvailability() async -> Bool
func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat
func continueTurn(childAnswer: String) async throws -> StoryBeat
func endSession()
var isSessionActive: Bool { get }
var currentTurnCount: Int { get }
1.3 — System prompt builder
Private method buildSystemPrompt(context: SceneContext, profile: ChildProfile) -> String
Keep under 300 tokens (monitor with tokenCount(for:))
Include: persona (Whisper), child age vocabulary matching, detected objects, content safety rules, theme preferences
Do NOT include the full rules list from the document — too many tokens wasted
1.4 — Error recovery
.guardrailViolation → Retry with softened prompt, log the violation
.exceededContextWindowSize → Summarize history, start new session, retry
.unavailable → Fall back to cloud mode if network available, else show "Story generation unavailable" in UI
Phase 2: ViewModel & Pipeline Integration (1-2 days)
2.1 — Register OnDeviceStoryService in AppDependencyContainer
Add let onDeviceStoryService = OnDeviceStoryService()
Pass to CompanionViewModel via init
2.2 — Add StoryGenerationMode to CompanionViewModel
New property: var storyMode: StoryGenerationMode (backed by UserDefaults)
Expose in SettingsView for user control
2.3 — Update SessionState enum
Add new case: .generatingStory (for on-device generation)
Add: .listeningForAnswer (waiting for child's spoken response)
2.4 — New pipeline method: runOnDevicePipeline(jpegData:)
Steps:
Run privacy pipeline (unchanged): privacyPipeline.process(jpegData:, childAge:) → PipelineResult
Build SceneContext from result.payload
Call onDeviceStoryService.startStory(context:, profile:) → StoryBeat
Synthesize beat.storyText via audioService.generateAndEncodeAudio(from:) → PCM Data
Send audio via accessoryManager.activeAccessory.sendAudio(data)
Synthesize and send beat.question
Listen for child's answer via speechRecognitionService
Call onDeviceStoryService.continueTurn(childAnswer:) → next StoryBeat
Loop until beat.isEnding == true or maxTurns reached
2.5 — Update runFullPipeline() routing
Check storyMode:
.onDevice → runOnDevicePipeline()
.cloud → existing runFullPipeline() (unchanged)
.hybrid → Start on-device immediately, dispatch cloud request in parallel, replace with cloud response if it arrives before turn 2
Phase 3: Streaming & Audio Optimization (1-2 days)
3.1 — Implement streaming story generation
Use session.streamResponse(to:, generating: StoryBeat.self)
As soon as storyText field is partially populated, begin TTS on the available text
This achieves the "< 1 second to first word" latency target
3.2 — Sentence-level audio streaming
Split streamed storyText by sentence boundaries
Synthesize and send each sentence to BLE as soon as it's complete
Queue sentences to avoid gaps
Phase 4: UI Updates (1 day)
4.1 — Add story mode picker to SettingsView/SettingsTabView
Segmented control: "On-Device" / "Cloud" / "Hybrid"
Show model availability status indicator
4.2 — Add story generation status to CameraTabView
Show current turn number, session state
Show "Generating story..." indicator during on-device generation
Show guardrail violation warnings if they occur
4.3 — Update StatusView
Display model download progress if availability == .downloading
Show "Apple Intelligence required" if model unavailable
Phase 5: Testing (1-2 days)
5.1 — Unit tests for OnDeviceStoryService
Test session lifecycle: start → continue → end
Test context window overflow handling
Test error recovery paths (guardrail, unavailable model)
Test turn counting and max turns enforcement
Test SceneContext construction from ScenePayload
5.2 — Unit tests for StoryBeat model
Test @Generable conformance
Test field presence and types
5.3 — Integration test
Mock LanguageModelSession (or use protocol abstraction)
Test full pipeline flow: image → privacy → story → TTS → audio send
Phase 6: Documentation & Cleanup (0.5 day)
6.1 — Update Apple Foundation Models.md
Fix all API method names
Add context window management section
Fix iOS version references
Add error handling section
Add availability checking section
6.2 — Update PROJECT_STATUS.md
Add new tickets for Foundation Models integration
Update architecture diagram
PART 4: KEY ARCHITECTURAL DECISIONS
Decision 1: Protocol abstraction for story generation
Create a StoryGenerating protocol that both OnDeviceStoryService and CloudAgentService can conform to. This enables clean mode switching and testability:

Code
protocol StoryGenerating {
    func generateStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat
    func continueTurn(childAnswer: String) async throws -> StoryBeat
}
Decision 2: Context window management strategy
Use a "sliding summary" approach:

After every turn, check remaining token budget
When budget drops below 800 tokens, summarize all turns except the latest into a 1-2 sentence recap
Create a new session with the recap as system prompt context
This is invisible to the child — the story continues seamlessly
Decision 3: Graceful degradation chain
Code
On-Device (preferred) → Cloud (fallback) → Error (last resort)
If Foundation Models is unavailable (wrong device, model downloading, Apple Intelligence disabled), automatically fall back to the existing cloud pipeline. If cloud is also unavailable, show a clear error message.

Decision 4: No @Tool usage initially
While Apple supports tool calling, using it would consume precious context window tokens (tool schemas count toward the 4,096 limit). For the PoC, pass scene context directly in the prompt. Tool calling can be added later if the context budget allows.

PART 5: RISK REGISTER
Risk	Impact	Likelihood	Mitigation
4,096 token limit causes sessions to terminate mid-story	High	High	Sliding window summarization, reduce max turns to 5
Guardrail blocks children's story content ("monster", "scary")	Medium	Medium	Retry with softened prompt, fallback to cloud
Model unavailable on test devices (requires iPhone 15 Pro+)	High	Medium	Cloud fallback, test on simulator with mocks
3B model produces low-quality stories for younger children (ages 3-4)	Medium	Medium	Extensive prompt engineering, @Guide constraints
Apple changes Foundation Models API in future iOS updates	Low	Low	Protocol abstraction insulates app from API changes
Latency exceeds targets when Neural Engine is under load	Medium	Low	Streaming mitigates perceived latency
PART 6: ESTIMATED FILE CHANGES
File	Action	Reason
SeeSaw/Model/StoryBeat.swift	Create	New @Generable struct
SeeSaw/Model/StoryGenerationMode.swift	Create	Mode enum (onDevice/cloud/hybrid)
SeeSaw/Model/StoryError.swift	Create	Error types for story generation
SeeSaw/Model/SceneContext.swift	Create	Bridge struct from PipelineResult to story service
SeeSaw/Services/AI/OnDeviceStoryService.swift	Create	Core actor — session management, generation, context window
SeeSaw/App/AppDependencyContainer.swift	Modify	Register OnDeviceStoryService
SeeSaw/ViewModel/CompanionViewModel.swift	Modify	Add storyMode, on-device pipeline routing, turn loop
SeeSaw/Model/SessionState.swift	Modify	Add .generatingStory, .listeningForAnswer
SeeSaw/View/Home/SettingsTabView.swift	Modify	Add story mode picker
SeeSaw/View/Home/CameraTabView.swift	Modify	Add story generation status
SeeSaw/Extensions/UserDefaults+Settings.swift	Modify	Add storyMode persistence
SeeSawTests/OnDeviceStoryServiceTests.swift	Create	Unit tests
SeeSawTests/StoryBeatTests.swift	Create	Model tests
Total: 8 new files, 5 modified files


